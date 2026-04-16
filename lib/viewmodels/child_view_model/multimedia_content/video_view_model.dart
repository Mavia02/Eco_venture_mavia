import 'dart:async';
import 'package:state_notifier/state_notifier.dart';
import '../../../models/video_model.dart';
import '../../../repositories/video_StoryRepo.dart';
import '../../../services/shared_preferences_helper.dart';
import 'video_state.dart';

class VideoViewModel extends StateNotifier<VideoState> {
  final VideoStoryRepository _repo;
  StreamSubscription? _sub;

  VideoViewModel(this._repo) : super(VideoState());

  // Logic: Fetches age-appropriate Videos.
  // First retrieves the child's age classification from SharedPreferences,
  // then initiates the filtered stream from the repository.
  Future<void> fetchVideos() async {
    state = state.copyWith(isLoading: true);
    _sub?.cancel();

    // 1. Get the student's age group (Hall Pass) stored during registration/login
    // Defaulting to "6 - 8" for safety/existing users
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Listen to the repository stream which now filters by ageGroup in the service
    _sub = _repo.getVideos(ageGroup).listen(
          (data) => state = state.copyWith(isLoading: false, videos: data),
      onError: (e) {
        print("Video Stream Error: $e");
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  // Logic: Increments the view count for a video and logs the activity to history.
  // Kept exactly as your original code.
  Future<void> incrementView(VideoModel video) async {
    try {
      final newViews = video.views + 1;

      // Update the database path (Teacher or Public) based on the model's metadata
      await _repo.updateVideoInteraction(
          video.id,
          video.adminId,
          video.createdBy,
          {'views': newViews}
      );

      // Log History for parent monitoring/dashboard
      await _repo.logActivity(
          id: video.id,
          title: video.title,
          type: "Video",
          category: video.category
      );
    } catch (e) {
      print("Error incrementing view: $e");
    }
  }

  // Logic: Handles the complex map-based like/dislike system.
  // Kept exactly as your original code.
  Future<void> toggleVideoLikeDislike({
    required VideoModel video,
    required String userId,
    required bool isLiking
  }) async {
    try {
      final userLikes = Map<String, bool>.from(video.userLikes);

      if (userLikes[userId] == isLiking) {
        userLikes.remove(userId); // Toggle off (Un-like/Un-dislike)
      } else {
        userLikes[userId] = isLiking; // Update to new status
      }

      int likes = userLikes.values.where((v) => v == true).length;
      int dislikes = userLikes.values.where((v) => v == false).length;

      // Update DB with the new calculated totals and the updated map
      await _repo.updateVideoInteraction(
          video.id,
          video.adminId,
          video.createdBy,
          {
            'likes': likes,
            'dislikes': dislikes,
            'userLikes': userLikes
          }
      );
    } catch (e) {
      print("Error toggling like/dislike: $e");
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}