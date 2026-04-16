class QrHuntReadModel {
  final String id;
  final String title;
  final int points;
  final String difficulty;
  final List<String> clues;

  // Tracking Origin
  final String createdBy; // 'admin' or 'teacher'
  final String creatorId;

  // AGE CLASSIFICATION FIELD
  final String ageGroup; // <--- ADDED THIS FIELD TO RESOLVE ERROR

  QrHuntReadModel({
    required this.id,
    required this.title,
    required this.points,
    required this.difficulty,
    required this.clues,
    this.createdBy = 'admin',
    this.creatorId = '',
    required this.ageGroup, // <--- ADDED TO CONSTRUCTOR
  });

  factory QrHuntReadModel.fromMap(String id, Map<String, dynamic> map) {
    return QrHuntReadModel(
      id: id,
      title: map['title'] ?? '',
      points: (map['points'] as num? ?? 0).toInt(),
      difficulty: map['difficulty'] ?? 'Easy',
      clues: List<String>.from(map['clues'] ?? []),
      createdBy: map['created_by'] ?? 'admin',
      creatorId: map['adminId'] ?? map['creator_id'] ?? '',
      // MAPPING AGE GROUP (Defaulting to 6 - 8 for existing data)
      ageGroup: map['ageGroup'] ?? '6 - 8',
    );
  }
}

// --- 2. PROGRESS MODEL (The Child's Activity) ---
class QrHuntProgressModel {
  final String huntId;
  final int currentClueIndex; // 0 = Looking for Clue 1
  final int totalClues;
  final bool isCompleted;
  final int scoreEarned;
  final DateTime startTime;
  final DateTime? completedTime;

  QrHuntProgressModel({
    required this.huntId,
    required this.currentClueIndex,
    required this.totalClues,
    required this.isCompleted,
    required this.scoreEarned,
    required this.startTime,
    this.completedTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'hunt_id': huntId,
      'current_clue_index': currentClueIndex,
      'total_clues': totalClues,
      'is_completed': isCompleted,
      'score_earned': scoreEarned,
      'start_time': startTime.toIso8601String(),
      'completed_time': completedTime?.toIso8601String(),
    };
  }

  factory QrHuntProgressModel.fromMap(Map<String, dynamic> map) {
    return QrHuntProgressModel(
      huntId: map['hunt_id'] ?? '',
      currentClueIndex: map['current_clue_index'] ?? 0,
      totalClues: map['total_clues'] ?? 0,
      isCompleted: map['is_completed'] ?? false,
      scoreEarned: map['score_earned'] ?? 0,
      startTime: DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now(),
      completedTime: map['completed_time'] != null ? DateTime.tryParse(map['completed_time']) : null,
    );
  }

  // Helper to advance step
  QrHuntProgressModel advanceStep(int maxClues, int totalPoints) {
    final nextIndex = currentClueIndex + 1;
    final finished = nextIndex >= maxClues;

    return QrHuntProgressModel(
      huntId: huntId,
      currentClueIndex: nextIndex,
      totalClues: totalClues,
      isCompleted: finished,
      scoreEarned: finished ? totalPoints : 0, // Award points only on finish
      startTime: startTime,
      completedTime: finished ? DateTime.now() : null,
    );
  }
}