import '../models/child_progress_model.dart';
import '../models/quiz_topic_model.dart';
import '../services/child_quiz_service.dart';

class ChildQuizRepository {
  final ChildQuizService _service;

  ChildQuizRepository(this._service);

  // --- ADMIN DATA ---
  // Logic: Fetches admin-created topics filtered by category and age classification
  Stream<List<QuizTopicModel>> getAdminTopics(String category, String studentAgeGroup) {
    return _service.getAdminTopicsStream(category, studentAgeGroup);
  }

  Stream<List<String>> getAdminCategories() {
    return _service.getAdminCategoriesStream();
  }

  // --- TEACHER DATA ---
  // Logic: Fetches teacher-created topics filtered by category and age classification
  Stream<List<QuizTopicModel>> getTeacherTopics(String category, String studentAgeGroup) {
    return _service.getTeacherTopicsStream(category, studentAgeGroup);
  }

  Stream<List<String>> getTeacherCategories() {
    return _service.getTeacherCategoriesStream();
  }

  // --- PROGRESS ---
  // Logic: Corrected method name to match ChildQuizService implementation.
  // Returns a stream of the child's progress across different quiz topics.
  Stream<Map<String, ChildQuizProgressModel>> getProgressStream() {
    return _service.getProgressStream();
  }

  // Logic: Saves the result of a completed quiz level.
  Future<void> saveLevelResult(ChildQuizProgressModel progress) async {
    await _service.saveLevelResult(progress);
  }
}