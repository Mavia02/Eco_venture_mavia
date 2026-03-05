class QrHuntModel {
  final String? id;
  final String? adminId; // Teacher ID
  final String title;
  final int points;
  final String difficulty; // Easy, Medium, Hard
  final List<String> clues;
  final String? qrCodeUrl; // URL of generated QR image (optional)
  final DateTime createdAt;
  final List<String> tags;
  final int cluesFound; // How many clues the child has scanned
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isSensitive;
  final String ageGroup; // NEW: Added for classification logic

  QrHuntModel({
    this.id,
    this.adminId,
    required this.title,
    required this.points,
    required this.difficulty,
    this.isSensitive = false,
    required this.clues,
    this.qrCodeUrl,
    this.tags = const [],
    required this.createdAt,
    this.cluesFound = 0,
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
    required this.ageGroup, // Now required in constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'title': title,
      'points': points,
      'difficulty': difficulty,
      'clues': clues,
      'qrCodeUrl': qrCodeUrl,
      'createdAt': createdAt.toIso8601String(),
      'cluesFound': cluesFound,
      'isCompleted': isCompleted,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'isSensitive': isSensitive,
      'ageGroup': ageGroup, // Save classification
    };
  }

  factory QrHuntModel.fromMap(String id, Map<String, dynamic> map) {
    return QrHuntModel(
      id: id,
      adminId: map['adminId'],
      title: map['title'] ?? '',
      points: (map['points'] as num? ?? 0).toInt(),
      isSensitive: map['isSensitive'] ?? false,
      difficulty: map['difficulty'] ?? 'Easy',
      clues: List<String>.from(map['clues'] ?? []),
      qrCodeUrl: map['qrCodeUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      cluesFound: (map['cluesFound'] as num? ?? 0).toInt(),
      isCompleted: map['isCompleted'] ?? false,
      startedAt: map['startedAt'] != null ? DateTime.tryParse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      ageGroup: map['ageGroup'] ?? '6 - 8', // Load classification
    );
  }

  QrHuntModel copyWith({
    String? id,
    String? adminId,
    String? title,
    int? points,
    String? difficulty,
    List<String>? clues,
    String? qrCodeUrl,
    DateTime? createdAt,
    int? cluesFound,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? tags,
    bool? isSensitive,
    String? ageGroup,
  }) {
    return QrHuntModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      title: title ?? this.title,
      points: points ?? this.points,
      difficulty: difficulty ?? this.difficulty,
      clues: clues ?? this.clues,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      createdAt: createdAt ?? this.createdAt,
      cluesFound: cluesFound ?? this.cluesFound,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isSensitive: isSensitive ?? this.isSensitive,
      tags: tags ?? this.tags,
      ageGroup: ageGroup ?? this.ageGroup,
    );
  }
}