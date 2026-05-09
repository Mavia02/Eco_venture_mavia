import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/nature_fact_{sqllite}.dart';
import '../models/nature_photo_predictiion{ai}.dart';
import '../services/nature_photo_modal_service.dart'; // Updated to match the new file name
import '../services/cloudinary_service.dart';
import '../services/nature_photo_sqlflite.dart';
import '../models/nature_photo_upload_model.dart';

class NatureRepository {
  // Use the updated ModalService that handles raw bytes and 448px resolution
  final ModalService _modalService = ModalService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final LocalDBService _localDbService = LocalDBService();
  final FirebaseDatabase _firebase = FirebaseDatabase.instance;

  Future<JournalEntry> processAndSaveEntry(
      File imageFile,
      String userId,
      ) async {
    // 1. PARALLEL EXECUTION: Start Prediction & Upload at the same time
    final results = await Future.wait([
      _modalService.predictImage(imageFile), // Index 0
      _cloudinaryService.uploadChildNaturePhotoImage(imageFile), // Index 1
    ]);

    NaturePrediction prediction = results[0] as NaturePrediction;
    final imageUrl = results[1] as String?;

    if (imageUrl == null) throw Exception("Image upload failed");

    // --- ANTI-ANNOYANCE GUARD ---
    // If the model is less than 70% sure, we treat it as "Unknown"

    bool isUnsure = prediction.confidence < 0.70;

    // 2. DATA CONSISTENCY:
    // Fetch the fact. If we are unsure, we fetch the "unknown" fact from your DB.
    final NatureFact fact = await _localDbService.getFactFor(
        isUnsure ? "unknown" : prediction.label
    );

    // If unsure, we override the prediction display label too
    if (isUnsure) {
      prediction = NaturePrediction(
        label: "Unknown",
        confidence: prediction.confidence,
        description: "We couldn't quite identify this one. Try a clearer photo!",
        category: "Unknown",
      );
    }

    // 3. CREATE ENTRY OBJECT
    final String entryId = const Uuid().v4();
    final entry = JournalEntry(
      id: entryId,
      userId: userId,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      prediction: prediction,
      fact: fact,
    );

    // 4. ATOMIC SAVE: Update Journal AND Activity at the exact same time
    final Map<String, dynamic> updates = {};

    updates['/users/$userId/journal/$entryId'] = entry.toMap();

    updates['/activities/$userId/$entryId'] = {
      'title': isUnsure ? "Spotted something mysterious" : "Discovered a ${fact.name}",
      'category': fact.category,
      'timestamp': entry.timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };

    await _firebase.ref().update(updates);

    return entry;
  }

  // 5. DELETE ENTRY: Removes from Journal AND Activity log
  Future<void> deleteEntry(String userId, String entryId) async {
    final Map<String, dynamic> updates = {};

    updates['/users/$userId/journal/$entryId'] = null;
    updates['/activities/$userId/$entryId'] = null;

    await _firebase.ref().update(updates);
  }

  // 6. UPDATE ENTRY: Saves changes to an existing card
  Future<void> updateEntry(String userId, JournalEntry updatedEntry) async {
    final Map<String, dynamic> updates = {};

    updates['/users/$userId/journal/${updatedEntry.id}'] = updatedEntry.toMap();

    updates['/activities/$userId/${updatedEntry.id}/title'] =
    "Discovered a ${updatedEntry.prediction.label}";

    await _firebase.ref().update(updates);
  }
}
