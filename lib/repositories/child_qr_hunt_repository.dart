import '../models/qr_hunt_read_model.dart';
import '../services/child_qr_hunt_service.dart';

class ChildQrHuntRepository {
  final ChildQrHuntService _service;

  ChildQrHuntRepository(this._service);

  /// Fetches hunts filtered by the student's age group
  Stream<List<QrHuntReadModel>> getHunts(String studentAgeGroup) {
    return _service.getHuntsStream(studentAgeGroup);
  }

  Stream<Map<String, QrHuntProgressModel>> getProgress() {
    return _service.getProgressStream();
  }

  Future<void> updateProgress(QrHuntProgressModel progress) async {
    await _service.saveProgress(progress);
  }
}