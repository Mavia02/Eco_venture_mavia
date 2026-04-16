import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/qr_hunt_read_model.dart';
import '../../../repositories/child_qr_hunt_repository.dart';
import '../../../services/shared_preferences_helper.dart'; // Logic: Required for Age Group retrieval
import 'child_qr_hunt_state.dart';

class ChildQrHuntViewModel extends StateNotifier<ChildQrHuntState> {
  final ChildQrHuntRepository _repository;
  StreamSubscription? _huntsSub;
  StreamSubscription? _progressSub;

  ChildQrHuntViewModel(this._repository) : super(ChildQrHuntState()) {
    loadHunts(); // Logic: Trigger age-filtered load on initialization
    _initProgressStream();
  }

  /// Logic: Fetches the child's age group (Hall Pass) from SharedPreferences
  /// and initiates a filtered stream from the repository.
  Future<void> loadHunts() async {
    state = state.copyWith(isLoading: true);
    _huntsSub?.cancel();

    // 1. Get the Age Group stored during login/registration
    // Defaulting to "6 - 8" for existing users or global students
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Listen to the repository stream which now requires the ageGroup parameter
    _huntsSub = _repository.getHunts(ageGroup).listen(
          (data) {
        state = state.copyWith(hunts: data, isLoading: false);
      },
      onError: (e) {
        print("QR Hunt Stream Error: $e");
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      },
    );
  }

  void _initProgressStream() {
    _progressSub = _repository.getProgress().listen(
          (data) {
        state = state.copyWith(progressMap: data);
      },
      onError: (e) => print("Progress Stream Error: $e"),
    );
  }

  // --- CORE: VALIDATE SCAN ---
  // Matches the structure of the QrHuntProgressModel and QrHuntReadModel provided
  Future<void> validateScan(String scannedCode, QrHuntReadModel hunt) async {
    // Get current progress from state (or start new if first time)
    QrHuntProgressModel? currentProgress = state.progressMap[hunt.id];

    currentProgress ??= QrHuntProgressModel(
      huntId: hunt.id,
      currentClueIndex: 0,
      totalClues: hunt.clues.length,
      isCompleted: false,
      scoreEarned: 0,
      startTime: DateTime.now(),
    );

    if (currentProgress.isCompleted) return; // Already finished

    // Expected Code Logic: "HUNTID_INDEX" (e.g. "hunt123_0")
    final String expectedCode = "${hunt.id}_${currentProgress.currentClueIndex}";

    if (scannedCode == expectedCode) {
      // MATCH! Use the advanceStep method from your model
      final newProgress = currentProgress.advanceStep(
        hunt.clues.length,
        hunt.points,
      );

      // Save to repository (Service handles the UID internally)
      await _repository.updateProgress(newProgress);
      state = state.copyWith(scanSuccess: true); // Trigger UI celebration/navigation
    } else {
      state = state.copyWith(errorMessage: "Wrong Code! Keep looking.");
    }
  }

  void resetFlags() {
    state = state.copyWith(scanSuccess: false, errorMessage: null);
  }

  @override
  void dispose() {
    _huntsSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}