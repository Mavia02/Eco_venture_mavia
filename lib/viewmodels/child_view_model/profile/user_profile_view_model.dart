import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_venture/repositories/firestore_repo.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/shared_preferences_helper.dart';
import 'user_profile_state.dart';

class UserProfileViewModel extends StateNotifier<UserProfileState> {
  final FirestoreRepo _repo;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  UserProfileViewModel(this._repo) : super(UserProfileState.initial());

  /// Logic: Internal helper to fetch teacher's full name from Firestore.
  /// This translates the teacher_id into a readable name for the child's dashboard.
  Future<void> _fetchAndSetTeacherName(String? teacherId) async {
    if (teacherId == null || teacherId.isEmpty) return;
    try {
      final teacherData = await _repo.getUserProfile(teacherId);
      if (teacherData != null) {
        // Fallback check for different naming conventions (full_name vs name)
        final String name = teacherData['full_name'] ?? teacherData['name'] ?? "Teacher";
        state = state.copyWith(teacherName: name);
      }
    } catch (e) {
      print("Error fetching teacher name: $e");
    }
  }

  /// Logic: Fetches the child's profile.
  /// If a teacher_id is present, it automatically triggers the name lookup and
  /// updates the local cache for other modules.
  Future<void> fetchUserProfile(String uid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getUserProfile(uid);
      state = state.copyWith(isLoading: false, userProfile: data);

      // --- TEACHER NAME CONCEPT ---
      if (data != null && data.containsKey('teacher_id') && data['teacher_id'] != null) {
        final String tId = data['teacher_id'];

        // 1. Sync the teacher ID to local storage so Quizzes/STEM can find it
        await SharedPreferencesHelper.instance.saveChildTeacherId(tId);

        // 2. Look up the teacher's actual name for the Home Screen display
        await _fetchAndSetTeacherName(tId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logic: Updates profile fields and synchronizes them with local SharedPreferences.
  /// Original logic preserved.
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? dob,
    String? phone,
    String? imgUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateUserProfile(
        uid: uid,
        name: name,
        dob: dob,
        phone: phone,
        imgUrl: imgUrl,
      );

      // Save locally to ensure UI updates immediately
      if (name != null) await SharedPreferencesHelper.instance.saveUserName(name);
      if (phone != null) await SharedPreferencesHelper.instance.saveUserPhoneNumber(phone);
      if (dob != null) await SharedPreferencesHelper.instance.saveUserDOB(dob);
      if (imgUrl != null) await SharedPreferencesHelper.instance.saveUserImgUrl(imgUrl);

      // Refresh data
      await fetchUserProfile(uid);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logic: Handles profile image upload to Cloudinary and saves the URL.
  Future<void> uploadAndSaveProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final imageUrl = await _cloudinaryService.uploadImage(imageFile);
      if (imageUrl != null) {
        await _repo.updateUserProfile(uid: uid, imgUrl: imageUrl);
        await SharedPreferencesHelper.instance.saveUserImgUrl(imageUrl);
        await fetchUserProfile(uid);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: "Image upload failed");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logic: Full account deletion including Cloudinary assets, Firestore, and Firebase Auth.
  Future<void> deleteUserProfile(String uid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getUserProfile(uid);
      final imgUrl = profile?["imgUrl"];

      if (imgUrl != null && imgUrl.isNotEmpty) {
        await _cloudinaryService.deleteImage(imgUrl);
      }

      await _repo.deleteUserProfile(uid);
      await SharedPreferencesHelper.instance.clearAll();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }

      state = UserProfileState.initial();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
