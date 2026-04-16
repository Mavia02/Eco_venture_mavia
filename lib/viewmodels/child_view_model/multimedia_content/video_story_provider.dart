import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/video_story_service.dart';
import '../../../repositories/video_StoryRepo.dart';
import 'video_view_model.dart';
import 'video_state.dart';
import 'story_view_model.dart';
import 'story_state.dart';

// 1. Service Provider
final videoStoryServiceProvider = Provider<VideoStoryService>((ref) {
  return VideoStoryService();
});

// 2. Repository Provider
// Logic: Corrected to use video_story_repository.dart and watch the service
final videoStoryRepositoryProvider = Provider<VideoStoryRepository>((ref) {
  final service = ref.watch(videoStoryServiceProvider);
  return VideoStoryRepository(service);
});

// 3. Video ViewModel Provider
// Logic: Points to the standalone VideoViewModel and VideoState
final videoViewModelProvider = StateNotifierProvider<VideoViewModel, VideoState>((ref) {
  final repository = ref.watch(videoStoryRepositoryProvider);
  return VideoViewModel(repository);
});

// 4. Story ViewModel Provider
// Logic: Points to the standalone StoryViewModel and StoryState
final storyViewModelProvider = StateNotifierProvider<StoryViewModel, StoryState>((ref) {
  final repository = ref.watch(videoStoryRepositoryProvider);
  return StoryViewModel(repository);
});