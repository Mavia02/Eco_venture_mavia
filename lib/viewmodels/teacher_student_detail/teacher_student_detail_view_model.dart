import 'dart:async';
import 'package:eco_venture/viewmodels/teacher_student_detail/teacher_student_detail_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/teacher_student_repository.dart';

class TeacherStudentDetailViewModel
    extends StateNotifier<TeacherStudentDetailState> {
  final TeacherStudentRepository _repository;
  StreamSubscription? _sub;

  TeacherStudentDetailViewModel(this._repository)
      : super(TeacherStudentDetailState());

  void loadStudent(String studentId) {
    state = state.copyWith(isLoading: true);
    _sub?.cancel();
    _sub = _repository
        .getStudentDetail(studentId)
        .listen(
          (data) {
        state = state.copyWith(isLoading: false, student: data);
      },
      onError: (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      },
    );
  }

  // --- FIXED: Using Named Parameters to match Repository ---
  Future<void> markStemSubmission({
    required String studentId,
    required String challengeId,
    required bool approved,
    required int points,
    required String feedback,
  }) async {
    try {
      final status = approved ? 'approved' : 'rejected';

      // Fixed the call by adding the parameter names
      await _repository.reviewSubmission(
        studentId: studentId,
        challengeId: challengeId,
        status: status,
        points: points,
        feedback: feedback,
      );

      // Success: Clearing error message if any existed
      state = state.copyWith(errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to review: $e");
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
