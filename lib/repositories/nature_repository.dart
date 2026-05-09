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
    // This is great for performance!
    final results = await Future.wait([
      _modalService.predictImage(imageFile), // Index 0
      _cloudinaryService.uploadChildNaturePhotoImage(imageFile), // Index 1
    ]);

    final prediction = results[0] as NaturePrediction;
    final imageUrl = results[1] as String?;

    if (imageUrl == null) throw Exception("Image upload failed");

    // 2. DATA CONSISTENCY:
    // We fetch the full NatureFact object from SQLite using the label from the AI.
    // This object contains the 'category' and 'description' you need.
    final NatureFact fact = await _localDbService.getFactFor(prediction.label);

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

    // Path for the User's Journal
    updates['/users/$userId/journal/$entryId'] = entry.toMap();

    // Path for Admin/Parent Activity Tracking
    updates['/activities/$userId/$entryId'] = {
      'title': "Discovered a ${fact.name}",
      'category': fact.category, // FIX: Access category from 'fact', not 'prediction'
      'timestamp': entry.timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };

    await _firebase.ref().update(updates);

    return entry;
  }

  // 5. DELETE ENTRY: Removes from Journal AND Activity log
  Future<void> deleteEntry(String userId, String entryId) async {
    final Map<String, dynamic> updates = {};

    // Setting a path to 'null' in Firebase deletes it
    updates['/users/$userId/journal/$entryId'] = null;
    updates['/activities/$userId/$entryId'] = null;

    await _firebase.ref().update(updates);
  }

  // 6. UPDATE ENTRY: Saves changes to an existing card
  Future<void> updateEntry(String userId, JournalEntry updatedEntry) async {
    final Map<String, dynamic> updates = {};

    // Overwrite the existing entry with new data
    updates['/users/$userId/journal/${updatedEntry.id}'] = updatedEntry.toMap();

    // We optionally update the activity title too, in case the name changed
    updates['/activities/$userId/${updatedEntry.id}/title'] =
    "Discovered a ${updatedEntry.prediction.label}";

    await _firebase.ref().update(updates);
  }
}
