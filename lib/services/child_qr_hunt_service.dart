import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_safety_settings_model.dart';
import '../models/qr_hunt_read_model.dart';
import '../services/shared_preferences_helper.dart';

class ChildQrHuntService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================================================
  //  GET TEACHER ID (UNCHANGED)
  // ==================================================
  Future<String?> _getTeacherId() async {
    try {
      final userId = await SharedPreferencesHelper.instance.getUserId();
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      if (data['teacher_id'] != null) {
        return data['teacher_id'];
      }
    } catch (e) {
      print('TeacherId Error: $e');
    }
    return null;
  }

  // ==================================================
  //  PARENT SAFETY SETTINGS
  // ==================================================
  Stream<ParentSafetySettingsModel> _getSafetySettings() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();

      if (uid == null) {
        yield ParentSafetySettingsModel();
      } else {
        yield* _database.ref('parent_settings/$uid').onValue.map((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            return ParentSafetySettingsModel.fromMap(
              Map<String, dynamic>.from(data),
            );
          }
          return ParentSafetySettingsModel();
        });
      }
    });
  }

  // ==================================================
  //  FETCH QR HUNTS (Now with Age Filter)
  // ==================================================
  Stream<List<QrHuntReadModel>> getHuntsStream(String studentAgeGroup) {
    final adminStream = _database
        .ref('Public/QrHunts')
        .onValue
        .map((event) {
      return _parseHunts(event.snapshot.value, isTeacher: false);
    })
        .startWith([]);

    final settingsStream = _getSafetySettings();

    return Stream.fromFuture(_getTeacherId()).asyncExpand((teacherId) {
      Stream<List<QrHuntReadModel>> teacherStream;

      if (teacherId != null && teacherId.isNotEmpty) {
        teacherStream = _database
            .ref('Teacher_Content/$teacherId/QrHunts')
            .onValue
            .map((event) {
          return _parseHunts(event.snapshot.value, isTeacher: true);
        })
            .startWith([]);
      } else {
        teacherStream = Stream.value([]);
      }

      return Rx.combineLatest3(
        adminStream,
        teacherStream,
        settingsStream,
            (List<QrHuntReadModel> admin,
            List<QrHuntReadModel> teacher,
            ParentSafetySettingsModel settings) {
          final combined = [...admin, ...teacher];
          return _applyFilters(combined, settings, studentAgeGroup);
        },
      );
    });
  }

  // ==================================================
  //  APPLY FILTERS (Age + Parent Safety)
  // ==================================================
  List<QrHuntReadModel> _applyFilters(
      List<QrHuntReadModel> hunts,
      ParentSafetySettingsModel settings,
      String studentAgeGroup, // Added parameter
      ) {

    const blockedKeywords = [
      'railway', 'train', 'bridge', 'road', 'highway', 'river',
      'gun', 'knife', 'blood', 'bomb', 'steal', 'rob',
      'meet', 'alone', 'midnight'
    ];

    String norm(String s) => s.toLowerCase();

    return hunts.where((hunt) {
      // 1. AGE BRACKET FILTER (PRIMARY)
      if (hunt.ageGroup.trim() != studentAgeGroup.trim()) {
        return false;
      }

      // 2. PARENT SAFETY FILTERS
      final title = norm(hunt.title);
      final cluesText = norm(hunt.clues.join(' '));

      if (settings.blockScaryContent) {
        for (final kw in blockedKeywords) {
          if (title.contains(kw) || cluesText.contains(kw)) {
            return false;
          }
        }
      }

      if (settings.educationalOnlyMode) {
        final isEducational =
            title.contains('learn') ||
                title.contains('quiz') ||
                title.contains('puzzle') ||
                cluesText.contains('fact') ||
                cluesText.contains('knowledge');

        if (!isEducational) return false;
      }

      return true;
    }).toList();
  }

  // ==================================================
  //  SAFE PARSER (Now including ageGroup)
  // ==================================================
  List<QrHuntReadModel> _parseHunts(
      dynamic data, {
        required bool isTeacher,
      }) {
    if (data == null || data is! Map) return [];

    final List<QrHuntReadModel> hunts = [];

    data.forEach((key, value) {
      try {
        if (value is! Map) return;

        final map = Map<String, dynamic>.from(value);

        // SAFE DEFAULTS
        map['title'] ??= '';
        map['clues'] ??= [];
        map['points'] ??= 0;
        map['difficulty'] ??= 'Easy';
        map['ageGroup'] ??= '6 - 8'; // Default

        final model = QrHuntReadModel.fromMap(key.toString(), map);

        hunts.add(
          QrHuntReadModel(
            id: model.id,
            title: model.title,
            points: model.points,
            difficulty: model.difficulty,
            clues: model.clues,
            createdBy: isTeacher ? 'teacher' : 'admin',
            creatorId: model.creatorId,
            ageGroup: model.ageGroup, // Correctly passing ageGroup
          ),
        );
      } catch (e) {
        print('❌ Dropped QR Hunt [$key] => $e');
      }
    });

    return hunts;
  }

  // ==================================================
  //  PROGRESS (UNCHANGED)
  // ==================================================
  Stream<Map<String, QrHuntProgressModel>> getProgressStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) {
        yield {};
      } else {
        yield* _database.ref('child_qr_progress/$uid').onValue.map((event) {
          final data = event.snapshot.value;
          if (data is! Map) return {};

          final Map<String, QrHuntProgressModel> progress = {};
          data.forEach((key, value) {
            if (value is Map) {
              progress[key.toString()] =
                  QrHuntProgressModel.fromMap(
                    Map<String, dynamic>.from(value),
                  );
            }
          });
          return progress;
        });
      }
    });
  }

  Future<void> saveProgress(QrHuntProgressModel progress) async {
    String? uid = await SharedPreferencesHelper.instance.getUserId();
    uid ??= _auth.currentUser?.uid;
    if (uid == null) return;

    await _database
        .ref('child_qr_progress/$uid/${progress.huntId}')
        .set(progress.toMap());
  }
}
