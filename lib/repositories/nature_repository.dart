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
    final results = await Future.wait([
      _modalService.predictImage(imageFile),
      _cloudinaryService.uploadChildNaturePhotoImage(imageFile),
    ]);

    NaturePrediction prediction = results[0] as NaturePrediction;
    final imageUrl = results[1] as String?;

    if (imageUrl == null) throw Exception("Image upload failed");

    // --- ANTI-ANNOYANCE GUARD ---
    // <comment-tag>Ensured this check matches the service threshold of 0.80 for consistency.</comment-tag>
    bool isUnsure = prediction.confidence < 0.80 || prediction.label == "Unknown";

    final NatureFact fact = await _localDbService.getFactFor(
        isUnsure ? "unknown" : _normalizeForSql(prediction.label)
    );

    if (isUnsure) {
      prediction = NaturePrediction(
        label: "Unknown",
        confidence: prediction.confidence,
        description: "I'm not quite sure what this is. Try a clearer photo of a plant or animal!",
        category: "Unknown",
      );
    }

    final String entryId = const Uuid().v4();
    final entry = JournalEntry(
      id: entryId,
      userId: userId,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      prediction: prediction,
      fact: fact,
    );

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

  // <comment-tag>Added a helper to ensure that the label being sent to SQL is lowercase and trimmed, preventing lookup failures.</comment-tag>
  String _normalizeForSql(String label) => label.trim().toLowerCase().replaceAll(' ', '_');

  Future<void> deleteEntry(String userId, String entryId) async {
    final Map<String, dynamic> updates = {};
    updates['/users/$userId/journal/$entryId'] = null;
    updates['/activities/$userId/$entryId'] = null;
    await _firebase.ref().update(updates);
  }

  Future<void> updateEntry(String userId, JournalEntry updatedEntry) async {
    final Map<String, dynamic> updates = {};
    updates['/users/$userId/journal/${updatedEntry.id}'] = updatedEntry.toMap();
    updates['/activities/$userId/${updatedEntry.id}/title'] = "Discovered a ${updatedEntry.prediction.label}";
    await _firebase.ref().update(updates);
  }
}