import 'dart:async';
import 'package:state_notifier/state_notifier.dart';
import '../../../models/story_model.dart';
import '../../../repositories/video_StoryRepo.dart';
import '../../../services/shared_preferences_helper.dart';
import 'story_state.dart';

class StoryViewModel extends StateNotifier<StoryState> {
  final VideoStoryRepository _repo;
  StreamSubscription? _sub;

  StoryViewModel(this._repo) : super(StoryState());

  /// Logic: Fetches age-appropriate Stories by retrieving ageGroup from SharedPreferences.
  /// This implements the new "Hall Pass" requirement for age classification.
  Future<void> fetchStories() async {
    state = state.copyWith(isLoading: true);
    _sub?.cancel();

    // 1. Retrieve the student's age classification
    final String ageGroup = await SharedPreferencesHelper.instance.getUserAgeGroup() ?? "6 - 8";

    // 2. Initiate the filtered stream from the repository
    _sub = _repo.getStories(ageGroup).listen(
          (data) => state = state.copyWith(isLoading: false, stories: data),
      onError: (e) {
        print("Story Stream Error: $e");
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  /// Logic: Increments the view count for a story and logs the activity.
  /// Preserves your original interaction logic exactly.
  Future<void> incrementView(StoryModel story) async {
    try {
      final newViews = story.views + 1;

      // Update DB using the interaction method
      await _repo.updateStoryInteraction(
        story.id,
        story.adminId,
        story.createdBy,
        {'views': newViews},
      );

      // Log to User History for tracking
      await _repo.logActivity(
        id: story.id,
        title: story.title,
        type: "Story",
        category: story.category,
      );
    } catch (e) {
      print("Error incrementing story view: $e");
    }
  }

  /// Logic: Handles the like/dislike map toggling logic for stories.
  /// Preserves your original map-based calculation logic.
  Future<void> toggleLikeDislike({
    required StoryModel story,
    required String userId,
    required bool isLiking,
  }) async {
    try {
      final userLikes = Map<String, bool>.from(story.userLikes);

      if (userLikes[userId] == isLiking) {
        userLikes.remove(userId); // Toggle off if the same action is performed
      } else {
        userLikes[userId] = isLiking; // Set new status (like or dislike)
      }

      int likesCount = userLikes.values.where((v) => v == true).length;
      int dislikesCount = userLikes.values.where((v) => v == false).length;

      // Update DB with totals and the updated map
      await _repo.updateStoryInteraction(
        story.id,
        story.adminId,
        story.createdBy,
        {
          'likes': likesCount,
          'dislikes': dislikesCount,
          'userLikes': userLikes
        },
      );
    } catch (e) {
      print("Error toggling story interaction: $e");
    }
  }

  /// Logic: Explicitly logs a story interaction event.
  Future<void> logStoryInteraction({required StoryModel story}) async {
    await _repo.logActivity(
      id: story.id,
      title: story.title,
      type: "Story",
      category: story.category,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
