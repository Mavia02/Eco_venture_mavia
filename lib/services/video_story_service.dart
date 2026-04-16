import 'dart:async';
import 'package:rxdart/rxdart.dart'; // Make sure this is in pubspec.yaml
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/parent_safety_settings_model.dart';
import '../models/video_model.dart';
import '../models/story_model.dart';
import '../services/shared_preferences_helper.dart';

class VideoStoryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getTeacherId() async {
    try {
      // 1. Get Current User
      final user = await SharedPreferencesHelper.instance.getUserId();

      if (user == null) {
        print("DEBUG: No User Logged In (Prefs). Cannot fetch Teacher ID.");
        return null;
      }

      // 2. Fetch Document directly from Firestore
      final doc = await _firestore.collection('users').doc(user).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 3. Check for 'teacher_id'
        if (data.containsKey('teacher_id') && data['teacher_id'] != null) {
          final String teacherId = data['teacher_id'];
          // Cache it locally for faster future access
          await SharedPreferencesHelper.instance.saveChildTeacherId(teacherId);
          return teacherId;
        }
      }
    } catch (e) {
      print("ERROR fetching teacher ID from Firestore: $e");
    }
    return null;
  }

  // ==================================================
  //  PARENT SAFETY SETTINGS STREAM (YOUR PATTERN)
  // ==================================================

  Stream<ParentSafetySettingsModel> _getSafetySettings() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      String? uid = user?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) {
        yield ParentSafetySettingsModel(); // Default: No restrictions
      } else {
        yield* _database.ref('parent_settings/$uid').onValue.map((event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            return ParentSafetySettingsModel.fromMap(Map<String, dynamic>.from(data));
          }
          return ParentSafetySettingsModel();
        });
      }
    });
  }

  // ================= VIDEOS (DUAL FETCH WITH FILTERING) =================

  Future<void> logMultimediaActivity({
    required String contentId,
    required String title,
    required String type, // "Video" or "Story"
    required String category
  }) async {
    try {
      // 1. Get Child ID
      String? childId = _auth.currentUser?.uid;
      childId ??= await SharedPreferencesHelper.instance.getUserId();
      if (childId == null) return;

      // 2. Create Log Entry
      final newLogKey = _database.ref().push().key!;
      final timestamp = DateTime.now().toIso8601String();

      final logData = {
        'contentId': contentId,
        'title': title,
        'type': type,
        'category': category,
        'timestamp': timestamp,
      };

      // 3. Save to "child_activity_log"
      await _database.ref('child_activity_log/$childId/$newLogKey').set(logData);

      print("DEBUG: Logged $type activity: $title");

    } catch (e) {
      print("Error logging activity: $e");
    }
  }

  Stream<List<VideoModel>> getVideosStream(String studentAgeGroup) {
    final adminStream = _database.ref('Public/Videos').onValue.map((e) => _parseVideos(e.snapshot.value, isTeacher: false));
    final settingsStream = _getSafetySettings();

    return _auth.authStateChanges().asyncExpand((user) async* {
      final teacherId = await _getTeacherId();

      Stream<List<VideoModel>> teacherStream = Stream.value([]);
      if (teacherId != null && teacherId.isNotEmpty) {
        teacherStream = _database.ref('Teacher_Content/$teacherId/Multimedia/Videos').onValue
            .map((e) => _parseVideos(e.snapshot.value, isTeacher: true));
      }

      // YOUR EXACT PATTERN: Combine and apply filters
      yield* Rx.combineLatest3(
          adminStream.startWith([]),
          teacherStream.startWith([]),
          settingsStream,
              (List<VideoModel> admin, List<VideoModel> teacher, ParentSafetySettingsModel settings) {
            final allVideos = [...admin, ...teacher];

            // Apply multimedia-appropriate filters with age classification
            final filteredVideos = _applyVideoFilters(allVideos, settings, studentAgeGroup);

            filteredVideos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return filteredVideos;
          }
      );
    });
  }

  // VIDEO-SPECIFIC FILTERING LOGIC
  List<VideoModel> _applyVideoFilters(List<VideoModel> videos, ParentSafetySettingsModel settings, String studentAgeGroup) {
    return videos.where((video) {
      // 1. AGE BRACKET FILTER (Primary Classification)
      if (video.ageGroup.trim() != studentAgeGroup.trim()) {
        return false;
      }

      // 2. Block Scary/Sensitive Video Content
      if (settings.blockScaryContent) {
        if (_isInappropriateVideo(video)) {
          print("🚫 Parent blocked inappropriate video: ${video.title}");
          return false;
        }
      }

      // 3. Educational Only Mode for Videos
      if (settings.educationalOnlyMode) {
        if (!_isEducationalVideo(video)) {
          print("📚 Educational mode - blocked non-educational video: ${video.title}");
          return false;
        }
      }

      // 4. Block Social Interaction for Videos (if applicable)
      if (settings.blockSocialInteraction) {
        if (_isSocialVideo(video)) {
          print("👥 Social interaction blocked for video: ${video.title}");
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Check if video is inappropriate (multimedia-specific keywords)
  bool _isInappropriateVideo(VideoModel video) {
    // 1. Check if video is marked as sensitive
    if (video.isSensitive == true) {
      return true;
    }

    // 2. Check tags for inappropriate video content
    if (video.tags.isNotEmpty) {
      const inappropriateVideoTags = [
        'scary', 'horror', 'violent', 'mature', 'adult',
        'frightening', 'terror', 'ghost', 'monster',
        'inappropriate', 'unsuitable', 'age-restricted'
      ];

      if (video.tags.any((tag) => inappropriateVideoTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    // 3. Check title for inappropriate keywords
    const inappropriateVideoKeywords = [
      'scary', 'horror', 'ghost', 'monster', 'zombie', 'vampire',
      'violent', 'fight', 'war', 'blood', 'death', 'terror',
      'frightening', 'creepy', 'spooky', 'haunted', 'demon'
    ];

    final titleLower = video.title.toLowerCase();
    if (inappropriateVideoKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    // 4. Check description if available
    if (video.description != null) {
      final descLower = video.description.toLowerCase();
      if (inappropriateVideoKeywords.any((word) => descLower.contains(word))) {
        return true;
      }
    }

    return false;
  }

  // Check if video is educational
  bool _isEducationalVideo(VideoModel video) {
    // 1. Check tags for educational value
    if (video.tags.isNotEmpty) {
      const educationalVideoTags = ['educational', 'learning', 'academic', 'tutorial', 'lesson'];
      const entertainmentVideoTags = ['entertainment', 'fun', 'comedy', 'music', 'movie'];

      if (educationalVideoTags.any((tag) => video.tags.contains(tag))) return true;
      if (entertainmentVideoTags.any((tag) => video.tags.contains(tag))) return false;
    }

    // 2. Educational categories for videos
    const educationalVideoCategories = [
      'Science', 'Math', 'Mathematics', 'History', 'Geography',
      'Language', 'English', 'Grammar', 'Vocabulary',
      'Technology', 'Coding', 'Programming', 'STEM',
      'Nature', 'Animals', 'Environment', 'Documentary'
    ];

    // 3. Entertainment categories
    const entertainmentCategories = [
      'Entertainment', 'Comedy', 'Music', 'Movie', 'Cartoon',
      'Fun', 'Games', 'Sports', 'Celebrity', 'Fashion'
    ];

    // Check if category is educational
    final isEducationalCategory = educationalVideoCategories.any(
            (eduCat) => video.category.toLowerCase().contains(eduCat.toLowerCase())
    );

    // Check if category is entertainment
    final isEntertainmentCategory = entertainmentCategories.any(
            (entCat) => video.category.toLowerCase().contains(entCat.toLowerCase())
    );

    // Educational categories are allowed
    if (isEducationalCategory) return true;

    // Entertainment categories blocked in educational mode
    if (isEntertainmentCategory) return false;

    // Default: Allow if not clearly entertainment
    return !isEntertainmentCategory;
  }

  // Check if video involves social interaction
  bool _isSocialVideo(VideoModel video) {
    // Video social interaction keywords
    const socialVideoKeywords = [
      'chat', 'live stream', 'comment', 'discuss', 'share',
      'react', 'response', 'interview', 'talk show', 'Q&A',
      'interactive', 'audience', 'follow', 'subscribe'
    ];

    // Check title
    final titleLower = video.title.toLowerCase();
    if (socialVideoKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    // Check tags
    if (video.tags.isNotEmpty) {
      const socialVideoTags = ['live', 'interactive', 'chat', 'social', 'community'];
      if (video.tags.any((tag) => socialVideoTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    return false;
  }

  List<VideoModel> _parseVideos(dynamic data, {required bool isTeacher}) {
    if (data == null) return [];
    final List<VideoModel> videos = [];
    try {
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            if (isTeacher) map['created_by'] = 'teacher';

            // Debug: Check for sensitive content
            if (map['isSensitive'] == true) {
              print("🔍 VIDEO Parsing: Found sensitive video: ${map['title'] ?? 'Unknown'}");
            }

            videos.add(VideoModel.fromMap(map));
          }
        });
      }
    } catch (e) {
      print("Video Parse Error: $e");
    }
    return videos;
  }

  // --- UPDATE VIDEO INTERACTIONS ---
  Future<void> updateVideoInteraction(String videoId, String creatorId, String createdBy, Map<String, dynamic> updates) async {
    String path;
    if (createdBy == 'teacher') {
      if (creatorId.isEmpty) return;
      path = 'Teacher_Content/$creatorId/Multimedia/Videos/$videoId';
    } else {
      path = 'Public/Videos/$videoId';
    }
    await _database.ref(path).update(updates);
  }

  // ================= STORIES (DUAL FETCH WITH FILTERING) =================

  Stream<List<StoryModel>> getStoriesStream(String studentAgeGroup) {
    final adminStream = _database.ref('Public/Stories').onValue.map((e) => _parseStories(e.snapshot.value, isTeacher: false));
    final settingsStream = _getSafetySettings();

    return _auth.authStateChanges().asyncExpand((user) async* {
      final teacherId = await _getTeacherId();
      Stream<List<StoryModel>> teacherStream = Stream.value([]);

      if (teacherId != null && teacherId.isNotEmpty) {
        teacherStream = _database.ref('Teacher_Content/$teacherId/Multimedia/Stories').onValue
            .map((e) => _parseStories(e.snapshot.value, isTeacher: true));
      }

      // YOUR EXACT PATTERN: Combine and apply filters
      yield* Rx.combineLatest3(
          adminStream.startWith([]),
          teacherStream.startWith([]),
          settingsStream,
              (List<StoryModel> admin, List<StoryModel> teacher, ParentSafetySettingsModel settings) {
            final allStories = [...admin, ...teacher];

            // Apply story-appropriate filters with age classification
            final filteredStories = _applyStoryFilters(allStories, settings, studentAgeGroup);

            filteredStories.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            return filteredStories;
          }
      );
    });
  }

  // STORY-SPECIFIC FILTERING LOGIC
  List<StoryModel> _applyStoryFilters(List<StoryModel> stories, ParentSafetySettingsModel settings, String studentAgeGroup) {
    return stories.where((story) {
      // 1. AGE BRACKET FILTER (Primary Classification)
      if (story.ageGroup.trim() != studentAgeGroup.trim()) {
        return false;
      }

      // 2. Block Scary/Sensitive Story Content
      if (settings.blockScaryContent) {
        if (_isInappropriateStory(story)) {
          print("🚫 Parent blocked inappropriate story: ${story.title}");
          return false;
        }
      }

      // 3. Educational Only Mode for Stories
      if (settings.educationalOnlyMode) {
        if (!_isEducationalStory(story)) {
          print("📚 Educational mode - blocked non-educational story: ${story.title}");
          return false;
        }
      }

      // 4. Block Social Interaction for Stories (if applicable)
      if (settings.blockSocialInteraction) {
        if (_isSocialStory(story)) {
          print("👥 Social interaction blocked for story: ${story.title}");
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Check if story is inappropriate (story-specific keywords)
  bool _isInappropriateStory(StoryModel story) {
    // 1. Check if story is marked as sensitive
    if (story.isSensitive == true) {
      return true;
    }

    // 2. Check tags for inappropriate story content
    if (story.tags.isNotEmpty) {
      const inappropriateStoryTags = [
        'scary', 'horror', 'violent', 'mature', 'adult',
        'frightening', 'terror', 'ghost', 'monster',
        'witchcraft', 'magic', 'supernatural', 'dark'
      ];

      if (story.tags.any((tag) => inappropriateStoryTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    // 3. Check title for inappropriate keywords
    const inappropriateStoryKeywords = [
      'scary', 'horror', 'ghost', 'monster', 'witch', 'vampire',
      'haunted', 'demon', 'devil', 'hell', 'death', 'murder',
      'terror', 'fear', 'nightmare', 'creepy', 'spooky'
    ];

    final titleLower = story.title.toLowerCase();
    if (inappropriateStoryKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    // 4. Check description
    final descLower = story.description.toLowerCase();
    if (inappropriateStoryKeywords.any((word) => descLower.contains(word))) {
      return true;
    }

    return false;
  }

  // Check if story is educational
  bool _isEducationalStory(StoryModel story) {
    // 1. Check tags for educational value
    if (story.tags.isNotEmpty) {
      const educationalStoryTags = ['educational', 'moral', 'learning', 'values', 'lesson'];
      const entertainmentStoryTags = ['fantasy', 'fairy tale', 'adventure', 'fun', 'fiction'];

      if (educationalStoryTags.any((tag) => story.tags.contains(tag))) return true;
      if (entertainmentStoryTags.any((tag) => story.tags.contains(tag))) return false;
    }

    // 2. Educational categories for stories
    const educationalStoryCategories = [
      'Educational', 'Moral Stories', 'Fables', 'Biography',
      'History', 'Science Fiction', 'Nature', 'Animals',
      'Culture', 'Geography', 'Inspirational'
    ];

    // 3. Entertainment categories
    const entertainmentStoryCategories = [
      'Horror', 'Fantasy', 'Fairy Tale', 'Mystery',
      'Adventure', 'Comedy', 'Romance', 'Thriller'
    ];

    // Check category (if available in story model)
    final storyCategory = story.category?.toLowerCase() ?? '';

    final isEducationalCategory = educationalStoryCategories.any(
            (eduCat) => storyCategory.contains(eduCat.toLowerCase())
    );

    final isEntertainmentCategory = entertainmentStoryCategories.any(
            (entCat) => storyCategory.contains(entCat.toLowerCase())
    );

    // Educational categories are allowed
    if (isEducationalCategory) return true;

    // Horror/Fantasy entertainment blocked in educational mode
    if (isEntertainmentCategory) return false;

    // Default: Allow if not clearly entertainment
    return !isEntertainmentCategory;
  }

  // Check if story involves social interaction
  bool _isSocialStory(StoryModel story) {
    // Story social interaction is less common, but check for:
    const socialStoryKeywords = [
      'interactive', 'choose your own', 'decision', 'branching',
      'audience', 'collaborative', 'group story', 'shared'
    ];

    // Check title
    final titleLower = story.title.toLowerCase();
    if (socialStoryKeywords.any((word) => titleLower.contains(word))) {
      return true;
    }

    // Check tags
    if (story.tags.isNotEmpty) {
      const socialStoryTags = ['interactive', 'choose-your-own', 'collaborative'];
      if (story.tags.any((tag) => socialStoryTags.contains(tag.toLowerCase()))) {
        return true;
      }
    }

    return false;
  }

  List<StoryModel> _parseStories(dynamic data, {required bool isTeacher}) {
    if (data == null) return [];
    final List<StoryModel> stories = [];
    try {
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            if (isTeacher) map['created_by'] = 'teacher';

            // Debug: Check for sensitive content
            if (map['isSensitive'] == true) {
              print("🔍 STORY Parsing: Found sensitive story: ${map['title'] ?? 'Unknown'}");
            }

            stories.add(StoryModel.fromMap(map));
          }
        });
      }
    } catch (e) {
      print("Story Parse Error: $e");
    }
    return stories;
  }

  Future<void> updateStoryInteraction(String storyId, String creatorId, String createdBy, Map<String, dynamic> updates) async {
    String path;
    if (createdBy == 'teacher') {
      if (creatorId.isEmpty) return;
      path = 'Teacher_Content/$creatorId/Multimedia/Stories/$storyId';
    } else {
      path = 'Public/Stories/$storyId';
    }
    await _database.ref(path).update(updates);
  }
}