import 'package:eco_venture/core/config/api_constants.dart';
import 'package:eco_venture/services/api_service.dart';
import 'package:eco_venture/services/shared_preferences_helper.dart';

class TeacherRepository {
  // Singleton pattern to ensure we use the same instance throughout the app
  static final TeacherRepository getInstance = TeacherRepository._internal();
  TeacherRepository._internal();

  final ApiService _apiService = ApiService();

  /// CREATION LOGIC: Matches your backend's createStudent function.
  /// Keys: email, password, name, teacherId, ageGroup.
  Future<void> addStudent({
    required String name,
    required String email,
    required String password,
    required String ageGroup,
  }) async {
    try {
      // 1. Get current teacher's UID from local storage
      String? teacherId = await SharedPreferencesHelper.instance.getUserId();

      if (teacherId == null) {
        throw Exception("Teacher session expired. Please log in again.");
      }

      // 2. Prepare request body exactly as the backend expects it
      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'ageGroup': ageGroup,
        'teacherId': teacherId, // Matches 'const { teacherId } = req.body' in Node.js
      };

      // 3. Call the backend API
      final response = await _apiService.sendUserToken(
        ApiConstants.createStudentEndpoint,
        requestBody,
      );

      // 4. Handle backend errors returned in the JSON response
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
    } catch (e) {
      throw Exception("Failed to register student: $e");
    }
  }

  /// DELETION LOGIC: Matches your backend's deleteStudent function.
  /// Key: studentId.
  /// This performs a permanent deletion from Auth, Firestore, and Realtime DB.
  Future<void> deleteStudent(String studentId) async {
    try {
      // 1. Prepare request body with the student identifier
      final requestBody = {
        'studentId': studentId, // Matches 'const { studentId } = req.body' in Node.js
      };

      // 2. Call the deletion endpoint
      // Note: Ensure ApiConstants.deleteStudentEndpoint is defined in your constants file
      final response = await _apiService.sendUserToken(
        ApiConstants.deleteStudentEndpoint,
        requestBody,
      );

      // 3. Check for specific backend error messages
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // Verification log for debug mode
      print("✅ Student $studentId permanently deleted from backend.");

    } catch (e) {
      throw Exception("Permanent deletion failed: $e");
    }
  }
}
