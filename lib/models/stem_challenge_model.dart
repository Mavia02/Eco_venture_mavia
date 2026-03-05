class StemChallengeModel {
  String? id;
  String? adminId; // Track creator (Teacher UID)
  final String title;
  final String category; // Science, Technology, Engineering, Mathematics
  final String difficulty; // Easy, Medium, Hard
  final int points;
  final String? imageUrl;
  final List<String> materials;
  final List<String> steps;
  final bool isSensitive;
  final List<String> tags;
  final String ageGroup; // NEW: Added for classification logic

  StemChallengeModel({
    this.id,
    this.adminId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.points,
    this.imageUrl,
    required this.materials,
    this.isSensitive = false,
    this.tags = const [],
    required this.steps,
    required this.ageGroup, // Now required in constructor
  });

  // Convert to Map for Firebase Realtime Database (Writing)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'points': points,
      'imageUrl': imageUrl,
      'materials': materials,
      'steps': steps,
      'tags': tags,
      'isSensitive': isSensitive,
      'ageGroup': ageGroup, // Save classification
    };
  }

  // Create from Firebase Map (Reading for Edit)
  factory StemChallengeModel.fromMap(String id, Map<String, dynamic> map) {
    return StemChallengeModel(
      id: id,
      adminId: map['adminId'],
      title: map['title'] ?? '',
      category: map['category'] ?? 'Science',
      difficulty: map['difficulty'] ?? 'Easy',
      points: map['points'] is int ? map['points'] : int.tryParse(map['points'].toString()) ?? 0,
      imageUrl: map['imageUrl'],
      materials: List<String>.from(map['materials'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      isSensitive: map['isSensitive'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      // Load ageGroup, defaulting to '6 - 8' for existing data
      ageGroup: map['ageGroup'] ?? '6 - 8',
    );
  }

  // CopyWith for immutable updates
  StemChallengeModel copyWith({
    String? id,
    String? adminId,
    String? title,
    String? category,
    String? difficulty,
    int? points,
    String? imageUrl,
    List<String>? materials,
    List<String>? tags,
    bool? isSensitive,
    List<String>? steps,
    String? ageGroup,
  }) {
    return StemChallengeModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      materials: materials ?? this.materials,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
      isSensitive: isSensitive ?? this.isSensitive,
      ageGroup: ageGroup ?? this.ageGroup,
    );
  }
}