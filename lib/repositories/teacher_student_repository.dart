import '../services/teacher_student_service.dart';
import '../models/teacher_student_detail_model.dart';

class TeacherStudentRepository {
  final TeacherStudentService _service;

  TeacherStudentRepository(this._service);

  Stream<TeacherStudentDetailModel> getStudentDetail(String studentId) {
    return _service.getStudentDetailStream(studentId).map((data) {
      // Helper to safely convert dynamic values to int
      int toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        return int.tryParse(value.toString()) ?? 0;
      }

      return TeacherStudentDetailModel(
        studentId: studentId,
        name: data['name'] ?? data['displayName'] ?? "Unknown Explorer",
        email: data['email'] ?? "",

        // --- FIXED: Robust ageGroup extraction ---
        // This ensures the detail screen matches the home screen sorting
        ageGroup: data['ageGroup'] ?? data['age_group'] ?? "6 - 8",

        // --- SAFETY: Using toInt helper to prevent type crashes ---
        totalXP: toInt(data['totalXP'] ?? data['xp']),
        currentLevel: toInt(data['currentLevel'] ?? data['level'] ?? 1),
        quizzesPassed: toInt(data['quizCount'] ?? data['quizzesPassed']),
        stemSubmitted: toInt(data['stemSub'] ?? data['stemSubmitted']),
        stemApproved: toInt(data['stemApp'] ?? data['stemApproved']),
        qrHuntsCompleted: toInt(data['qrCount'] ?? data['qrHuntsCompleted']),

        recentActivity: List<Map<String, dynamic>>.from(data['activity'] ?? []),
      );
    });
  }

  // --- Action to Review STEM ---
  Future<void> reviewSubmission({
    required String studentId,
    required String challengeId,
    required String status,
    required int points,
    required String feedback,
  }) async {
    await _service.reviewStemSubmission(
      studentId: studentId,
      challengeId: challengeId,
      status: status,
      points: points,
      feedback: feedback,
    );
  }
}