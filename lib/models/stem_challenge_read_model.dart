class StemChallengeReadModel {
  final String id;
  final String adminId;
  final String title;
  final String category;
  final String difficulty;
  final int points;
  final String? imageUrl;
  final List<String> materials;
  final List<String> steps;

  // PARENT FILTERING FIELDS
  final bool isSensitive;
  final List<String> tags;

  // NEW FIELDS FOR DUAL FETCH
  final String createdBy; // 'admin' or 'teacher'
  final String creatorId;

  // AGE CLASSIFICATION FIELD
  final String ageGroup; // <--- ADDED THIS FIELD

  StemChallengeReadModel({
    required this.id,
    required this.adminId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.points,
    this.imageUrl,
    required this.materials,
    required this.steps,
    this.isSensitive = false,
    this.tags = const [],
    this.createdBy = 'admin',
    this.creatorId = '',
    required this.ageGroup, // <--- ADDED TO CONSTRUCTOR
  });

  factory StemChallengeReadModel.fromMap(String id, Map<String, dynamic> map) {
    return StemChallengeReadModel(
      id: id,
      adminId: map['adminId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? 'Easy',
      points: map['points']?.toInt() ?? 0,
      imageUrl: map['imageUrl'],
      materials: List<String>.from(map['materials'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      isSensitive: map['isSensitive'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      createdBy: map['created_by'] ?? 'admin',
      creatorId: map['creator_id'] ?? '',
      // MAPPING AGE GROUP (Defaulting to 6 - 8 for safety)
      ageGroup: map['ageGroup'] ?? '6 - 8',
    );
  }

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
      'isSensitive': isSensitive,
      'tags': tags,
      'created_by': createdBy,
      'creator_id': creatorId,
      'ageGroup': ageGroup, // <--- ADDED TO MAP
    };
  }

  StemChallengeReadModel copyWith({
    String? id,
    String? adminId,
    String? title,
    String? category,
    String? difficulty,
    int? points,
    String? imageUrl,
    List<String>? materials,
    List<String>? steps,
    bool? isSensitive,
    List<String>? tags,
    String? createdBy,
    String? creatorId,
    String? ageGroup, // <--- ADDED TO COPYWITH
  }) {
    return StemChallengeReadModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      materials: materials ?? this.materials,
      steps: steps ?? this.steps,
      isSensitive: isSensitive ?? this.isSensitive,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      creatorId: creatorId ?? this.creatorId,
      ageGroup: ageGroup ?? this.ageGroup, // <--- ADDED TO LOGIC
    );
  }
}