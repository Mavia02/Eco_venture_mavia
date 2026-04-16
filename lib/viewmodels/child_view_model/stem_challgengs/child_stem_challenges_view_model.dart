import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/stem_submission_model.dart';
import '../../../repositories/child_stem_challenge_repository.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/shared_preferences_helper.dart'; // Added for age group retrieval
import 'child_stem_challenges_state.dart';

class ChildStemChallengesViewModel extends StateNotifier<ChildStemChallengesState> {
  final ChildStemChallengesRepository _repository;
  final CloudinaryService _cloudinaryService;

  StreamSubscription? _adminSub;
  StreamSubscription? _teacherSub;
  StreamSubscription? _submissionsSub;

  ChildStemChallengesViewModel(this._repository, this._cloudinaryService)
      : super(ChildStemChallengesState()) {
    _loadSubmissionHistory();
  }

  /// Logic: Updated to be async to retrieve the student's ageGroup from SharedPreferences
  /// before initiating the filtered repository streams.
  Future<void> loadChallenges(String category) async {
    _adminSub?.cancel();
    _teacherSub?.cancel();

    // 1. Retrieve the age group stored during login or registration
    // Defaulting to "6 - 8" as a safe fallback if no group is found
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Pass both category and ageGroup to the repository for dual-layer filtering
    _adminSub = _repository.getAdminChallenges(category, ageGroup).listen(
          (data) => state = state.copyWith(adminChallenges: data),
      onError: (e) => print("Admin STEM Error: $e"),
    );

    _teacherSub = _repository.getTeacherChallenges(category, ageGroup).listen(
          (data) => state = state.copyWith(teacherChallenges: data),
      onError: (e) => print("Teacher STEM Error: $e"),
    );
  }

  void _loadSubmissionHistory() {
    _submissionsSub = _repository.getSubmissionsStream().listen(
          (historyMap) => state = state.copyWith(submissions: historyMap),
      onError: (e) => print("Error loading history: $e"),
    );
  }

  // --- SUBMISSION LOGIC (UNCHANGED) ---
  Future<void> submitChallengeWithProof({
    required StemSubmissionModel submission,
    required List<File> proofImages,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final List<String> imageUrls = await _cloudinaryService.uploadMultipleTaskImages(proofImages);

      if (imageUrls.isEmpty) {
        throw Exception("Failed to upload proof images. Please try again.");
      }

      final finalSubmission = submission.copyWith(
        proofImageUrls: imageUrls,
        status: 'pending',
      );

      await _repository.submitChallenge(finalSubmission);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void resetSuccess() {
    state = state.copyWith(isSuccess: false);
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    _teacherSub?.cancel();
    _submissionsSub?.cancel();
    super.dispose();
  }
}