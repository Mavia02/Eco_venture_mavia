import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/teacher_repoistory.dart';
import '../../services/shared_preferences_helper.dart';
import 'teacher_auth_state.dart';

class TeacherAuthViewModel extends StateNotifier<TeacherAuthState> {
  final TeacherRepository _repository;

  TeacherAuthViewModel(this._repository) : super(TeacherAuthState());

  Future<void> addStudent({
    required String name,
    required String email,
    required String password,
    required String ageGroup,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // FIXED: Added parameter names to match the named parameters in TeacherRepository
      await _repository.addStudent(
        name: name,
        email: email,
        password: password,
        ageGroup: ageGroup,
      );

      // 2. Save Child Info locally
      await SharedPreferencesHelper.instance.saveChildName(name);
      await SharedPreferencesHelper.instance.saveChildEmail(email);

      // Save the teacher's ID as the "Child's Teacher"
      String? currentTeacherId = await SharedPreferencesHelper.instance.getUserId();
      if (currentTeacherId != null) {
        await SharedPreferencesHelper.instance.saveChildTeacherId(currentTeacherId);
        await SharedPreferencesHelper.instance.saveIsTeacherAdded(true);
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void resetState() {
    state = TeacherAuthState();
  }
}