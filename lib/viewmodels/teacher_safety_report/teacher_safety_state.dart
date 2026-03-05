import '../../models/teacher_report_model.dart';

class TeacherSafetyState {
  final bool isLoading;
  final List<TeacherReportModel> alerts;
  final String? errorMessage;
  final bool isSuccess;

  TeacherSafetyState({
    this.isLoading = false,
    this.alerts = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  TeacherSafetyState copyWith({
    bool? isLoading,
    List<TeacherReportModel>? alerts,
    String? errorMessage, // Logic: Removing '?? this.errorMessage' to allow setting it to null
    bool? isSuccess,
  }) {
    return TeacherSafetyState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      errorMessage: errorMessage, // This now correctly allows the ViewModel to clear errors
      isSuccess: isSuccess ?? false,
    );
  }
}