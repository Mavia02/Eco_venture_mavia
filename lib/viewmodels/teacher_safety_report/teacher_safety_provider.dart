import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/teacher_safety_service.dart';
import '../../repositories/teacher_safety_repository.dart';
import 'teacher_safety_view_model.dart';
import 'teacher_safety_state.dart';

// 1. Service
final teacherSafetyServiceProvider = Provider((ref) => TeacherSafetyService());

// 2. Repository
final teacherSafetyRepositoryProvider = Provider((ref) {
  return TeacherSafetyRepository(ref.watch(teacherSafetyServiceProvider));
});

// 3. ViewModel - Note: Removed autoDispose to prevent state loss during navigation
// This ensures the inbox stays populated when you return from a detail screen.
final teacherSafetyViewModelProvider = StateNotifierProvider<TeacherSafetyViewModel, TeacherSafetyState>((ref) {
  final repo = ref.watch(teacherSafetyRepositoryProvider);
  return TeacherSafetyViewModel(repo);
});