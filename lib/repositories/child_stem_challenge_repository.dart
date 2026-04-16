import '../models/stem_challenge_read_model.dart';
import '../models/stem_submission_model.dart';
import '../services/child_stem_challenges_service.dart';

class ChildStemChallengesRepository {
  final ChildStemChallengesService _service;

  ChildStemChallengesRepository(this._service);

  /// Fetches Admin STEM challenges filtered by category and the child's age group.
  Stream<List<StemChallengeReadModel>> getAdminChallenges(String category, String studentAgeGroup) {
    return _service.getAdminChallengesStream(category, studentAgeGroup);
  }

  /// Fetches Teacher STEM challenges filtered by category and the child's age group.
  Stream<List<StemChallengeReadModel>> getTeacherChallenges(String category, String studentAgeGroup) {
    return _service.getTeacherChallengesStream(category, studentAgeGroup);
  }

  /// Submits a student's challenge attempt to the database.
  Future<void> submitChallenge(StemSubmissionModel submission) async {
    await _service.submitChallenge(submission);
  }

  /// Listens to the history of submissions made by the currently logged-in student.
  Stream<Map<String, StemSubmissionModel>> getSubmissionsStream() {
    return _service.getStudentSubmissionsStream();
  }
}