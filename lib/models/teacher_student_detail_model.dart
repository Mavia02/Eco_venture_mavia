class TeacherStudentDetailModel {
  final String studentId;
  final String name;
  final String email;
  final String ageGroup; // Added for age-based classification
  final int totalXP;
  final int currentLevel;

  // Specific Stats
  final int quizzesPassed;
  final int stemSubmitted;
  final int stemApproved;
  final int qrHuntsCompleted;

  // Recent Activity List (Simplified)
  final List<Map<String, dynamic>> recentActivity;

  TeacherStudentDetailModel({
    required this.studentId,
    required this.name,
    required this.email,
    required this.ageGroup, // Now required in constructor
    this.totalXP = 0,
    this.currentLevel = 1,
    this.quizzesPassed = 0,
    this.stemSubmitted = 0,
    this.stemApproved = 0,
    this.qrHuntsCompleted = 0,
    this.recentActivity = const [],
  });

  TeacherStudentDetailModel copyWith({
    String? studentId,
    String? name,
    String? email,
    String? ageGroup, // Included in copyWith
    int? totalXP,
    int? currentLevel,
    int? quizzesPassed,
    int? stemSubmitted,
    int? stemApproved,
    int? qrHuntsCompleted,
    List<Map<String, dynamic>>? recentActivity,
  }) {
    return TeacherStudentDetailModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      ageGroup: ageGroup ?? this.ageGroup, // Updated logic
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      quizzesPassed: quizzesPassed ?? this.quizzesPassed,
      stemSubmitted: stemSubmitted ?? this.stemSubmitted,
      stemApproved: stemApproved ?? this.stemApproved,
      qrHuntsCompleted: qrHuntsCompleted ?? this.qrHuntsCompleted,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }
}