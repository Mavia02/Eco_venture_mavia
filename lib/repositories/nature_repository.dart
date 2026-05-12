import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/nature_fact_{sqllite}.dart';
import '../models/nature_photo_predictiion{ai}.dart';
import '../services/nature_photo_modal_service.dart';
import '../services/cloudinary_service.dart';
import '../services/nature_photo_sqlflite.dart';
import '../models/nature_photo_upload_model.dart';

class NatureRepository {
  final ModalService _modalService = ModalService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final LocalDBService _localDbService = LocalDBService();
  final FirebaseDatabase _firebase = FirebaseDatabase.instance;

  Future<JournalEntry> processAndSaveEntry(
      File imageFile,
      String userId,
      ) async {
    // 1. We keep your optimized parallel logic to save user time
    final results = await Future.wait([
      _modalService.predictImage(imageFile), // Index 0
      _cloudinaryService.uploadChildNaturePhotoImage(imageFile), // Index 1
    ]);

    NaturePrediction prediction = results[0] as NaturePrediction;
    final imageUrl = results[1] as String?;

    if (imageUrl == null) throw Exception("Image upload failed");

    // 2. ANTI-ANNOYANCE GUARD
    // If confidence is low (like the 29% case), we treat the discovery as "Unknown"
    bool isUnsure = prediction.confidence < 0.70 || prediction.label == "Unknown";

    // 3. FETCH DATA: Get facts from SQLite.
    // If unsure, we look for the "unknown" record in your local DB.
    final NatureFact fact = await _localDbService.getFactFor(
        isUnsure ? "unknown" : prediction.label
    );

    // Override the prediction details if we are unsure
    if (isUnsure) {
      prediction = NaturePrediction(
        label: "Unknown",
        confidence: prediction.confidence,
        description: "I'm not quite sure what this is. Try a clearer photo of a plant or animal!",
        category: "Unknown",
      );
    }

    // 4. CREATE ENTRY OBJECT
    final String entryId = const Uuid().v4();
    final entry = JournalEntry(
      id: entryId,
      userId: userId,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      prediction: prediction,
      fact: fact,
    );

    // 5. ATOMIC SAVE: Keep your logic to update Journal and Activity feed at once
    final Map<String, dynamic> updates = {};

    updates['/users/$userId/journal/$entryId'] = entry.toMap();

    // We use a professional title if the AI is unsure
    updates['/activities/$userId/$entryId'] = {
      'title': isUnsure ? "Spotted something mysterious" : "Discovered a ${fact.name}",
      'category': fact.category,
      'timestamp': entry.timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };

    await _firebase.ref().update(updates);

    return entry;
  }

  // 6. DELETE ENTRY: Removes from Journal AND Activity log
  Future<void> deleteEntry(String userId, String entryId) async {
    final Map<String, dynamic> updates = {};
    updates['/users/$userId/journal/$entryId'] = null;
    updates['/activities/$userId/$entryId'] = null;
    await _firebase.ref().update(updates);
  }

  // 7. UPDATE ENTRY: Saves changes to an existing card
  Future<void> updateEntry(String userId, JournalEntry updatedEntry) async {
    final Map<String, dynamic> updates = {};
    updates['/users/$userId/journal/${updatedEntry.id}'] = updatedEntry.toMap();
    updates['/activities/$userId/${updatedEntry.id}/title'] =
    "Discovered a ${updatedEntry.prediction.label}";
    await _firebase.ref().update(updates);
  }
}
