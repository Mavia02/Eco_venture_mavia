import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/child_progress_model.dart';
import '../../../repositories/child_quiz_repository.dart';
import '../../../services/shared_preferences_helper.dart'; // Added for Age Group
import 'child_quiz_state.dart';

class ChildQuizViewModel extends StateNotifier<ChildQuizState> {
  final ChildQuizRepository _repository;

  StreamSubscription? _adminTopicSub;
  StreamSubscription? _teacherTopicSub;
  StreamSubscription? _adminCatSub;
  StreamSubscription? _teacherCatSub;
  StreamSubscription? _progressSub;

  ChildQuizViewModel(this._repository) : super(ChildQuizState()) {
    _loadUserProgress();
    _loadCategories();
  }

  void _loadCategories() {
    _adminCatSub = _repository.getAdminCategories().listen((cats) {
      state = state.copyWith(adminCategories: cats);
    });

    _teacherCatSub = _repository.getTeacherCategories().listen((cats) {
      state = state.copyWith(teacherCategories: cats);
    });
  }

  // --- LOAD TOPICS (Updated to fetch studentAgeGroup first) ---

  Future<void> loadAdminTopics(String category) async {
    _adminTopicSub?.cancel();

    // 1. Retrieve age group "Hall Pass"
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Listen for age-filtered topics
    _adminTopicSub = _repository.getAdminTopics(category, ageGroup).listen((topics) {
      state = state.copyWith(adminTopics: topics);
    });
  }

  Future<void> loadTeacherTopics(String category) async {
    _teacherTopicSub?.cancel();

    // 1. Retrieve age group "Hall Pass"
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Listen for age-filtered topics
    _teacherTopicSub = _repository.getTeacherTopics(category, ageGroup).listen((topics) {
      state = state.copyWith(teacherTopics: topics);
    });
  }

  void _loadUserProgress() {
    _progressSub = _repository.getProgressStream().listen((progressMap) {
      state = state.copyWith(progress: progressMap);
    });
  }

  Future<void> saveLevelResult(ChildQuizProgressModel result) async {
    try {
      await _repository.saveLevelResult(result);
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to save: $e");
    }
  }

  @override
  void dispose() {
    _adminTopicSub?.cancel();
    _teacherTopicSub?.cancel();
    _adminCatSub?.cancel();
    _teacherCatSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}