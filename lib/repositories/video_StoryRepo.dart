import '../models/video_model.dart';
import '../models/story_model.dart';
import '../services/video_story_service.dart';

class VideoStoryRepository {
  final VideoStoryService _service;

  VideoStoryRepository(this._service);

  // Logic: Both streams now correctly require the age group for classification
  Stream<List<VideoModel>> getVideos(String studentAgeGroup) =>
      _service.getVideosStream(studentAgeGroup);

  Stream<List<StoryModel>> getStories(String studentAgeGroup) =>
      _service.getStoriesStream(studentAgeGroup);

  Future<void> updateVideoInteraction(
      String videoId,
      String creatorId,
      String createdBy,
      Map<String, dynamic> updates,
      ) async {
    await _service.updateVideoInteraction(videoId, creatorId, createdBy, updates);
  }

  Future<void> updateStoryInteraction(
      String storyId,
      String creatorId,
      String createdBy,
      Map<String, dynamic> updates,
      ) async {
    await _service.updateStoryInteraction(storyId, creatorId, createdBy, updates);
  }

  Future<void> logActivity({
    required String id,
    required String title,
    required String type,
    required String category,
  }) async {
    await _service.logMultimediaActivity(
      contentId: id,
      title: title,
      type: type,
      category: category,
    );
  }
}
