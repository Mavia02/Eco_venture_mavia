import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherReportModel {
  final String id;
  final String title;
  final String description;
  final String fromName;
  final String type;
  final String status;
  final DateTime timestamp;

  final String? childId;
  final String? parentId;
  final String? contentId;

  TeacherReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fromName,
    required this.type,
    required this.status,
    required this.timestamp,
    this.childId,
    this.parentId,
    this.contentId,
  });

  /// Factory logic redesigned to be "Bulletproof" against database inconsistencies.
  factory TeacherReportModel.fromMap(String id, Map<String, dynamic>? map) {
    if (map == null) {
      return _errorReport(id);
    }

    try {
      // 1. ROBUST TIMESTAMP HANDLING
      DateTime parsedTime;
      var rawTime = map['timestamp'] ?? map['createdAt'];

      if (rawTime is Timestamp) {
        parsedTime = rawTime.toDate();
      } else if (rawTime is String) {
        parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
      } else if (rawTime is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
      } else {
        parsedTime = DateTime.now();
      }

      // 2. SAFE STRING CASTING Helper
      String safeStr(dynamic v, String def) => (v == null) ? def : v.toString();

      return TeacherReportModel(
        id: id,
        title: safeStr(map['title'], 'Alert'),
        description: safeStr(map['description'] ?? map['message'], ''),
        fromName: safeStr(map['fromName'] ?? map['senderName'], 'Unknown Explorer'),
        type: safeStr(map['type'], 'General'),
        status: safeStr(map['status'], 'Pending'),
        timestamp: parsedTime,
        childId: map['childId']?.toString(),
        parentId: map['parentId']?.toString(),
        contentId: map['contentId']?.toString(),
      );
    } catch (e) {
      // Logic: If any field causes a crash, return a safe "corrupted" object
      // instead of breaking the entire app.
      return _errorReport(id);
    }
  }

  static TeacherReportModel _errorReport(String id) {
    return TeacherReportModel(
      id: id,
      title: 'Data Error',
      description: 'This report has a format error in the database.',
      fromName: 'System',
      type: 'Bug',
      status: 'Resolved',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fromName': fromName,
      'type': type,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'childId': childId,
      'parentId': parentId,
      'contentId': contentId,
    };
  }
}