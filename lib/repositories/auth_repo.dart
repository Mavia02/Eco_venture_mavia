import 'package:eco_venture/core/config/api_constants.dart';
import 'package:eco_venture/models/user_model.dart';
import 'package:eco_venture/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class AuthRepo {
  AuthRepo._();
  static final AuthRepo getInstance = AuthRepo._();
  final ApiService _apiService = ApiService();

  /// 1. SIGN IN (Email/Password)
  /// Logic: Sanitizes input, verifies via backend status checks, then syncs local Firebase session.
  Future<UserModel?> loginUser(String email, String password) async {
    // Force lowercase and trim to prevent casing/spacing mismatches between apps
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      // Step A: Verify credentials and status (Pending/Suspended) via Render Backend.
      final userData = await _apiService.sendUserToken(
        ApiConstants.signInEndpoint,
        {'email': cleanEmail, 'password': cleanPassword},
      );

      // Step B: Synchronize the local Firebase Client SDK session.
      // Essential for Firestore rules to recognize the user as authenticated.
      // Note: We use credentials directly because the backend /signIn returns an ID Token, not a Custom Token.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      // Step C: Build the user model using the verified data from the backend.
      return UserModel(
        uid: userData['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        displayName: userData['name'] ?? userData['displayName'] ?? '',
        email: userData['email'] ?? cleanEmail,
        role: userData['role'] ?? 'unknown',
        ageGroup: userData['ageGroup'] ?? '6 - 8',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      // Logic: Map technical codes to friendly messages for the UI.
      String errorMsg = e.toString().replaceAll("Exception: ", "");

      if (errorMsg.contains("wrong-password") || errorMsg.contains("invalid-credential")) {
        errorMsg = "Incorrect password. Please check and try again.";
      } else if (errorMsg.contains("user-not-found")) {
        errorMsg = "No account found with this email.";
      } else if (errorMsg.contains("401")) {
        errorMsg = "Invalid credentials. Please verify your email and password.";
      }

      throw Exception(errorMsg);
    }
  }

  /// 2. SIGN UP (Email/Password)
  /// Logic: Standard registration via backend which returns a legitimate Custom Token.
  Future<UserModel?> signUpUser(
      String email,
      String password,
      String role,
      String name,
      String ageGroup,
      ) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      var requestBody = {
        'email': cleanEmail,
        'password': password.trim(),
        'role': role,
        'name': name.trim(),
        'ageGroup': ageGroup,
      };

      final userData = await _apiService.sendUserToken(
        ApiConstants.signUpEndpoint,
        requestBody,
      );

      // SIGN IN HANDSHAKE: Backend returns a CUSTOM TOKEN for signup.
      if (userData.containsKey("token")) {
        await FirebaseAuth.instance.signInWithCustomToken(userData["token"]);
      }

      return UserModel(
        uid: userData['uid'] ?? '',
        displayName: name,
        email: cleanEmail,
        role: role,
        ageGroup: ageGroup,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  /// 3. GOOGLE SIGN IN
  /// Logic: Performs Google Auth then exchanges the result for a Custom Token from the backend.
  Future<UserModel?> sendTokenOfGoogle(String role) async {
    final googleUser = await AuthService.authInstance.continueWithGoogle();
    String safeName = googleUser.displayName ?? googleUser.email.split('@')[0];

    final requestBody = {
      'idToken': googleUser.idToken,
      'email': googleUser.email.toLowerCase(),
      'name': safeName,
      'role': role.isNotEmpty ? role : "child",
    };

    final response = await _apiService.sendUserToken(
      ApiConstants.googleEndpoint,
      requestBody,
    );

    // SIGN IN HANDSHAKE: Google backend returns a CUSTOM TOKEN.
    if (response.containsKey("token")) {
      await FirebaseAuth.instance.signInWithCustomToken(response["token"]);
    }

    // Parse user data from nested or flat response structure
    final userMap = response['user'] as Map<String, dynamic>?;
    if (userMap != null) return UserModel.fromMap(userMap);
    return UserModel.fromMap(response);
  }

  /// Logic: Requests password reset email for the trimmed identifier.
  Future<void> forgotUser(String email) async {
    await AuthService.authInstance.forgot(email.trim().toLowerCase());
  }

  /// Logic: Completely signs out from Firebase Auth.
  Future<void> logout() async {
    await AuthService.authInstance.logout();
  }
}
