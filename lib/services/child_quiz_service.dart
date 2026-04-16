import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/child_progress_model.dart';
import '../models/quiz_topic_model.dart';
import '../models/parent_safety_settings_model.dart';
import '../services/shared_preferences_helper.dart';

class ChildQuizService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- HELPER: FIND TEACHER ID ---
  Future<String?> _getTeacherId() async {
    try {
      final user = await SharedPreferencesHelper.instance.getUserId();
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('teacher_id') && data['teacher_id'] != null) {
          final String teacherId = data['teacher_id'];
          await SharedPreferencesHelper.instance.saveChildTeacherId(teacherId);
          return teacherId;
        }
      }
    } catch (e) {
      print("ERROR fetching teacher ID: $e");
    }
    return null;
  }

  // --- HELPER: GET SAFETY SETTINGS STREAM ---
  Stream<ParentSafetySettingsModel> _getSafetySettings() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) {
        yield ParentSafetySettingsModel();
      } else {
        yield* _database.ref('parent_settings/$uid').onValue.map((event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            return ParentSafetySettingsModel.fromMap(Map<String, dynamic>.from(data));
          }
          return ParentSafetySettingsModel();
        });
      }
    });
  }

  // ==================================================
  //  FETCH TOPICS (Now with Age Classification)
  // ==================================================

  // 1. ADMIN CONTENT
  Stream<List<QuizTopicModel>> getAdminTopicsStream(String category, String studentAgeGroup) {
    final dataStream = _database.ref('Public/Quizzes/$category').onValue.map((event) {
      return _parseTopics(event.snapshot.value, category);
    }).handleError((e) => <QuizTopicModel>[]);

    return Rx.combineLatest2(dataStream, _getSafetySettings(),
            (List<QuizTopicModel> topics, ParentSafetySettingsModel settings) {
          return _applyFilters(topics, settings, category, studentAgeGroup);
        }
    );
  }

  Stream<List<String>> getAdminCategoriesStream() {
    return _database.ref('Public/Quizzes').onValue.map((event) {
      return _extractKeys(event.snapshot.value);
    });
  }

  // 2. TEACHER CONTENT
  Stream<List<QuizTopicModel>> getTeacherTopicsStream(String category, String studentAgeGroup) {
    final settingsStream = _getSafetySettings();

    return Stream.fromFuture(_getTeacherId()).asyncExpand((teacherId) {
      Stream<List<QuizTopicModel>> teacherDataStream;

      if (teacherId != null && teacherId.isNotEmpty) {
        teacherDataStream = _database.ref('Teacher_Content/$teacherId/Quizzes/$category').onValue.map((event) {
          return _parseTopics(event.snapshot.value, category);
        }).handleError((e) => <QuizTopicModel>[]);
      } else {
        teacherDataStream = Stream.value([]);
      }

      return Rx.combineLatest2(teacherDataStream, settingsStream,
              (List<QuizTopicModel> topics, ParentSafetySettingsModel settings) {
            return _applyFilters(topics, settings, category, studentAgeGroup);
          }
      );
    });
  }

  Stream<List<String>> getTeacherCategoriesStream() {
    return Stream.fromFuture(_getTeacherId()).asyncExpand((teacherId) {
      if (teacherId != null && teacherId.isNotEmpty) {
        return _database.ref('Teacher_Content/$teacherId/Quizzes').onValue.map((event) {
          return _extractKeys(event.snapshot.value);
        });
      } else {
        return Stream.value([]);
      }
    });
  }

  // --- FILTER LOGIC (Updated with Age Check) ---
  List<QuizTopicModel> _applyFilters(
      List<QuizTopicModel> topics,
      ParentSafetySettingsModel settings,
      String category,
      String studentAgeGroup) {

    return topics.where((topic) {
      // 1. AGE BRACKET FILTER (PRIMARY)
      // Checks if the quiz matches the child's classification (e.g. 6-8)
      if (topic.ageGroup.trim() != studentAgeGroup.trim()) {
        return false;
      }

      // 2. Block Scary Content (Original Logic)
      if (settings.blockScaryContent) {
        if (topic.isSensitive) return false;
        if (topic.tags.contains('scary') || topic.tags.contains('horror')) return false;
      }

      // 3. Educational Only Mode (Original Logic)
      if (settings.educationalOnlyMode) {
        const allowedCategories = ['Science', 'Math', 'Mathematics', 'Ecosystem', 'History', 'Geography', 'Animals', 'Plants'];
        if (!allowedCategories.contains(category)) return false;
      }

      return true;
    }).toList();
  }

  // --- PARSING HELPERS (Unchanged) ---
  List<QuizTopicModel> _parseTopics(dynamic data, String category) {
    if (data == null) return [];
    try {
      final List<QuizTopicModel> topics = [];
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final topicMap = Map<String, dynamic>.from(value);
            topics.add(QuizTopicModel.fromMap(key.toString(), category, topicMap));
          }
        });
      } else if (data is List) {
        for (var item in data) {
          if (item != null && item is Map) {
            final topicMap = Map<String, dynamic>.from(item);
            topics.add(QuizTopicModel.fromMap(topicMap['id'] ?? 'unknown', category, topicMap));
          }
        }
      }
      return topics;
    } catch (e) { return []; }
  }

  List<String> _extractKeys(dynamic data) {
    if (data is Map) {
      final keys = data.keys.map((k) => k.toString()).toList();
      keys.sort();
      return keys;
    }
    return [];
  }

  // --- PROGRESS LOGIC (Unchanged) ---
  Stream<Map<String, ChildQuizProgressModel>> getProgressStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) { yield {}; } else {
        yield* _database.ref('child_quiz_progress/$uid').onValue.map((event) {
          final data = event.snapshot.value;
          final Map<String, ChildQuizProgressModel> progressMap = {};
          if (data != null) _parseRecursiveProgress(data, progressMap);
          return progressMap;
        });
      }
    });
  }

  void _parseRecursiveProgress(dynamic data, Map<String, ChildQuizProgressModel> progressMap) {
    if (data is Map) {
      if (data.containsKey('level_order') && data.containsKey('topic_id')) {
        _addModelToMap(data, progressMap);
      } else {
        data.forEach((k, v) => _parseRecursiveProgress(v, progressMap));
      }
    } else if (data is List) {
      for (var item in data) {
        if (item != null) _parseRecursiveProgress(item, progressMap);
      }
    }
  }

  void _addModelToMap(dynamic data, Map<String, ChildQuizProgressModel> progressMap) {
    try {
      if (data is! Map) return;
      final safeData = Map<String, dynamic>.from(data);
      final model = ChildQuizProgressModel.fromMap(safeData);
      final key = "${model.topicId}_${model.levelOrder}";
      progressMap[key] = model;
    } catch (e) { }
  }

  Future<void> saveLevelResult(ChildQuizProgressModel progress) async {
    String? childId = await SharedPreferencesHelper.instance.getUserId();
    childId ??= _auth.currentUser?.uid;
    if (childId == null) throw Exception("Child not logged in");

    final path = 'child_quiz_progress/$childId/${progress.category}/${progress.topicId}/${progress.levelOrder}';
    final snapshot = await _database.ref(path).get();
    final bool passedNow = progress.attemptPercentage >= 60;

    if (snapshot.exists && snapshot.value is Map) {
      final existingData = Map<String, dynamic>.from(snapshot.value as Map);
      final existingProgress = ChildQuizProgressModel.fromMap(existingData);
      final bool finalPassedStatus = existingProgress.isPassed || passedNow;
      final updatedMap = progress.toMap();
      updatedMap['is_passed'] = finalPassedStatus;
      updatedMap['attempts'] = existingProgress.attempts + 1;
      await _database.ref(path).update(updatedMap);
    } else {
      final map = progress.toMap();
      map['is_passed'] = passedNow;
      map['attempts'] = 1;
      await _database.ref(path).set(map);
    }
  }
}