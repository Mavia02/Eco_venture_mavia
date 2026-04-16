import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/stem_challenge_read_model.dart';
import '../models/stem_submission_model.dart';
import '../models/parent_safety_settings_model.dart';
import '../services/shared_preferences_helper.dart';

class ChildStemChallengesService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- HELPER: FIND TEACHER ID (Using SharedPrefs UID) ---
  Future<String?> _getTeacherId() async {
    try {
      // 1. Get Current User
      final user = await SharedPreferencesHelper.instance.getUserId();

      if (user == null) {
        print("DEBUG: No User Logged In (Prefs). Cannot fetch Teacher ID.");
        return null;
      }

      // 2. Fetch Document directly from Firestore
      final doc = await _firestore.collection('users').doc(user).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 3. Check for 'teacher_id'
        if (data.containsKey('teacher_id') && data['teacher_id'] != null) {
          final String teacherId = data['teacher_id'];
          // Cache it locally for faster future access
          await SharedPreferencesHelper.instance.saveChildTeacherId(teacherId);
          return teacherId;
        }
      }
    } catch (e) {
      print("ERROR fetching teacher ID from Firestore: $e");
    }
    return null;
  }

  // ==================================================
  //  PARENT SAFETY SETTINGS STREAM (EXACTLY SAME AS YOUR QUIZ SERVICE)
  // ==================================================

  Stream<ParentSafetySettingsModel> _getSafetySettings() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) {
        yield ParentSafetySettingsModel(); // Default: No restrictions
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
  //  1. FETCH ADMIN CHALLENGES (With Age & Parent Filters)
  // ==================================================

  Stream<List<StemChallengeReadModel>> getAdminChallengesStream(String category, String studentAgeGroup) {
    final dataStream = _database.ref('Public/StemChallenges/$category').onValue.map((event) {
      return _parseChallenges(event.snapshot.value);
    }).handleError((e) {
      print("Admin Stream Error: $e");
      return <StemChallengeReadModel>[];
    });

    // Pattern: Combine challenges with safety settings and apply filters (including age)
    return Rx.combineLatest2(dataStream, _getSafetySettings(),
            (List<StemChallengeReadModel> challenges, ParentSafetySettingsModel settings) {
          return _applyStemFilters(challenges, settings, category, studentAgeGroup);
        }
    );
  }

  // ==================================================
  //  2. FETCH TEACHER CHALLENGES (With Age & Parent Filters)
  // ==================================================

  Stream<List<StemChallengeReadModel>> getTeacherChallengesStream(String category, String studentAgeGroup) {
    return Stream.fromFuture(_getTeacherId()).asyncExpand((teacherId) {
      Stream<List<StemChallengeReadModel>> teacherDataStream;

      if (teacherId != null && teacherId.isNotEmpty) {
        print("DEBUG: Fetching Teacher STEM from: Teacher_Content/$teacherId/StemChallenges/$category");
        teacherDataStream = _database.ref('Teacher_Content/$teacherId/StemChallenges/$category')
            .onValue.map((event) {
          return _parseChallenges(event.snapshot.value);
        }).handleError((e) {
          print("Teacher Stream Error: $e");
          return <StemChallengeReadModel>[];
        });
      } else {
        teacherDataStream = Stream.value([]);
      }

      final settingsStream = _getSafetySettings();

      // Pattern: Combine teacher challenges with safety settings and apply filters (including age)
      return Rx.combineLatest2(teacherDataStream, settingsStream,
              (List<StemChallengeReadModel> challenges, ParentSafetySettingsModel settings) {
            return _applyStemFilters(challenges, settings, category, studentAgeGroup);
          }
      );
    });
  }

  // ==================================================
  //  STEM-SPECIFIC FILTER LOGIC (Age + Safety)
  // ==================================================

  List<StemChallengeReadModel> _applyStemFilters(
      List<StemChallengeReadModel> challenges,
      ParentSafetySettingsModel settings,
      String category,
      String studentAgeGroup) {

    return challenges.where((challenge) {
      // 1. AGE BRACKET FILTER (PRIMARY CHECK)
      // Filters tasks based on the student's classification (e.g., 6-8, 8-10, 10-12)
      if (challenge.ageGroup.trim() != studentAgeGroup.trim()) {
        return false;
      }

      // 2. Block Dangerous/Inappropriate STEM Content
      if (settings.blockScaryContent) {
        if (_isDangerousOrInappropriateStem(challenge, category)) {
          print("🚫 Parent blocked inappropriate STEM content: ${challenge.title}");
          return false;
        }
      }

      // 3. Educational Only Mode - STEM Specific
      if (settings.educationalOnlyMode) {
        if (!_isEducationalStem(challenge, category)) {
          print("📚 Educational mode - blocked non-educational STEM: ${challenge.title}");
          return false;
        }
      }

      // 4. Block Social Interaction for STEM
      if (settings.blockSocialInteraction) {
        if (_isSocialStemChallenge(challenge)) {
          print("👥 Social interaction blocked for STEM: ${challenge.title}");
          return false;
        }
      }

      return true;
    }).toList();
  }

  // STEM-SPECIFIC HELPERS (Restored full detailed logic)
  bool _isDangerousOrInappropriateStem(StemChallengeReadModel challenge, String category) {
    // 1. Check if challenge is marked as sensitive
    if (challenge.isSensitive == true) {
      return true;
    }

    // 2. Check tags for dangerous STEM content
    if (challenge.tags.isNotEmpty) {
      const dangerousStemTags = [
        'dangerous', 'hazardous', 'chemicals', 'explosive', 'fire',
        'electricity', 'high-voltage', 'radiation', 'toxic', 'sharp',
        'adult-supervision', 'mature', 'complex', 'advanced'
      ];

      if (challenge.tags.any((tag) => dangerousStemTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    // 3. Check title for dangerous STEM keywords
    const dangerousStemKeywords = [
      'dangerous', 'hazard', 'explosive', 'chemical', 'acid',
      'fire', 'flame', 'burn', 'electric', 'shock', 'voltage',
      'radiation', 'toxic', 'poison', 'sharp', 'blade', 'cut',
      'advanced', 'complex', 'professional', 'expert'
    ];

    final titleLower = challenge.title.toLowerCase();
    if (dangerousStemKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    // 4. Check category for potentially dangerous STEM areas
    const potentiallyDangerousCategories = [
      'Chemistry', 'Physics', 'Electronics', 'Engineering',
      'Robotics', 'Tools', 'Experiments'
    ];

    final categoryLower = category.toLowerCase();
    if (potentiallyDangerousCategories.any((cat) => categoryLower.contains(cat.toLowerCase()))) {
      return false; // Don't auto-block, just flag for review
    }

    return false;
  }

  bool _isEducationalStem(StemChallengeReadModel challenge, String category) {
    // 1. Check tags for entertainment vs educational
    if (challenge.tags.isNotEmpty) {
      const educationalStemTags = ['educational', 'learning', 'academic', 'science', 'math'];
      const entertainmentTags = ['game', 'fun', 'entertainment', 'play', 'toy'];

      if (educationalStemTags.any((tag) => challenge.tags.contains(tag))) return true;
      if (entertainmentTags.any((tag) => challenge.tags.contains(tag))) return false;
    }

    // 2. STEM Educational categories
    const educationalStemCategories = [
      'Science', 'Technology', 'Engineering', 'Math', 'Mathematics',
      'Physics', 'Chemistry', 'Biology', 'Coding', 'Programming',
      'Robotics', 'Electronics', 'Astronomy', 'Geology', 'Ecology',
      'Environmental Science', 'Computer Science', 'Data Science'
    ];

    // 3. Non-educational/entertainment categories
    const nonEducationalCategories = [
      'Games', 'Entertainment', 'Fun', 'Toys', 'Hobbies',
      'Just for Fun', 'Recreation', 'Leisure'
    ];

    final isEducationalCategory = educationalStemCategories.any(
            (eduCat) => category.toLowerCase().contains(eduCat.toLowerCase())
    );

    final isNonEducationalCategory = nonEducationalCategories.any(
            (nonEduCat) => category.toLowerCase().contains(nonEduCat.toLowerCase())
    );

    if (isEducationalCategory) return true;
    if (isNonEducationalCategory) return false;

    return true;
  }

  bool _isSocialStemChallenge(StemChallengeReadModel challenge) {
    const socialStemKeywords = [
      'collaborate', 'teamwork', 'group project', 'pair programming',
      'discuss', 'share results', 'presentation', 'debate',
      'competition', 'contest', 'challenge others', 'multiplayer'
    ];

    final titleLower = challenge.title.toLowerCase();
    if (socialStemKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    if (challenge.tags.isNotEmpty) {
      const socialStemTags = ['collaborative', 'team', 'group', 'social', 'multiplayer', 'competitive'];
      if (challenge.tags.any((tag) => socialStemTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    return false;
  }

  // ==================================================
  //  HELPER PARSER
  // ==================================================

  List<StemChallengeReadModel> _parseChallenges(dynamic data) {
    if (data == null) return [];
    try {
      final List<StemChallengeReadModel> challenges = [];
      if (data is Map) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          challenges.add(StemChallengeReadModel.fromMap(key.toString(), map));
        });
      }
      return challenges;
    } catch (e) {
      print("Error parsing STEM challenges: $e");
      return [];
    }
  }

  // ==================================================
  //  SUBMISSION METHODS (UNCHANGED)
  // ==================================================

  Future<void> submitChallenge(StemSubmissionModel submission) async {
    try {
      String? studentId = await SharedPreferencesHelper.instance.getUserId() ?? _auth.currentUser?.uid;
      if (studentId == null) throw Exception("Student not logged in");

      final path = 'student_stem_submissions/$studentId/${submission.challengeId}';
      final submissionData = submission.copyWith(
        studentId: studentId,
        status: 'pending',
        teacherFeedback: null,
        pointsAwarded: 0,
      ).toMap();

      await _database.ref(path).set(submissionData);
    } catch (e) {
      throw Exception("Failed to submit challenge: $e");
    }
  }

  Stream<Map<String, StemSubmissionModel>> getStudentSubmissionsStream() async* {
    String? studentId = await SharedPreferencesHelper.instance.getUserId() ?? _auth.currentUser?.uid;
    if (studentId == null) {
      yield {};
      return;
    }

    final path = 'student_stem_submissions/$studentId';
    yield* _database.ref(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};

      try {
        final Map<String, StemSubmissionModel> submissions = {};
        final Map<dynamic, dynamic> mapData = data as Map<dynamic, dynamic>;

        mapData.forEach((challengeId, value) {
          final submissionMap = Map<String, dynamic>.from(value as Map);
          submissions[challengeId.toString()] = StemSubmissionModel.fromMap(challengeId.toString(), submissionMap);
        });

        return submissions;
      } catch (e) {
        print("Error parsing student submissions: $e");
        return {};
      }
    });
  }
}