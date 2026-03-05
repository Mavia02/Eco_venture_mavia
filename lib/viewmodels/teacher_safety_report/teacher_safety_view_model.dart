import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/teacher_safety_repository.dart';
import 'teacher_safety_state.dart';

class TeacherSafetyViewModel extends StateNotifier<TeacherSafetyState> {
  final TeacherSafetyRepository _repo;
  StreamSubscription? _subscription;

  TeacherSafetyViewModel(this._repo) : super(TeacherSafetyState());

  /// Logic: Initializes the stream listener.
  /// Called by the UI to start data synchronization.
  Future<void> fetchReports() async {
    // Prevent double-loading UI flickers
    if (state.isLoading && state.alerts.isNotEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    await _subscription?.cancel();
    _subscription = _repo.getInbox().listen(
          (alertsList) {
        state = state.copyWith(
            isLoading: false,
            alerts: alertsList,
            errorMessage: null
        );
      },
      onError: (error) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "Failed to sync inbox: $error"
        );
      },
    );
  }

  /// FIXED: Added missing method required by TeacherReportDetailScreen
  Future<void> markResolved(String reportId, String? childId) async {
    try {
      await _repo.markResolved(reportId, childId);
      // Logic: No need to manually update state here;
      // the Stream listener will automatically push the update to the UI.
    } catch (e) {
      state = state.copyWith(errorMessage: "Could not resolve: $e");
    }
  }

  Future<void> sendParentMessage(String studentId, String title, String msg) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.sendParentRemark(studentId, title, msg);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> sendAdminReport(String title, String msg, String type) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.sendAdminReport(title, msg, type);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void resetSuccess() => state = state.copyWith(isSuccess: false);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
