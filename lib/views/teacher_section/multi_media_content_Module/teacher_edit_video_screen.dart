import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../models/video_model.dart';
import '../../../core/config/api_constants.dart';
import '../../../services/shared_preferences_helper.dart';
import '../../../viewmodels/multimedia_content/teacher_multimedia_provider.dart';

class TeacherEditVideoScreen extends ConsumerStatefulWidget {
  final VideoModel videoData;
  const TeacherEditVideoScreen({super.key, required this.videoData});

  @override
  ConsumerState<TeacherEditVideoScreen> createState() =>
      _TeacherEditVideoScreenState();
}

class _TeacherEditVideoScreenState
    extends ConsumerState<TeacherEditVideoScreen> {
  final Color _textDark = const Color(0xFF1B2559);
  final Color _border = const Color(0xFFE0E0E0);
  final Color _primaryBlue = const Color(0xFF1565C0);
  final Color _primaryRed = const Color(0xFFE53935);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'Science';
  final List<String> _categories = ['Science', 'Maths', 'History', 'Ecosystem'];

  // --- NEW: Age Selection State ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  File? _newVideoFile;
  File? _newThumbnail;
  String? _existingThumbnailUrl;
  String? _existingVideoUrl;
  bool _isSensitive = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.videoData.title;
    _descController.text = widget.videoData.description;
    _durationController.text = widget.videoData.duration;
    _existingThumbnailUrl = widget.videoData.thumbnailUrl;
    _existingVideoUrl = widget.videoData.videoUrl;
    _tagsController.text = widget.videoData.tags.join(", ");
    _isSensitive = widget.videoData.isSensitive;

    if (_categories.contains(widget.videoData.category)) {
      _selectedCategory = widget.videoData.category;
    }

    // --- NEW: Initialize selected year based on existing ageGroup range ---
    if (widget.videoData.ageGroup == "6 - 8") {
      _selectedYear = "6";
    } else if (widget.videoData.ageGroup == "8 - 10") {
      _selectedYear = "9";
    } else if (widget.videoData.ageGroup == "10 - 12") {
      _selectedYear = "11";
    } else {
      _selectedYear = "6";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Logic: Map individual year selection to broad backend ranges
  String _mapYearToClass(String year) {
    int age = int.parse(year);
    if (age >= 6 && age <= 8) return "6 - 8";
    if (age >= 9 && age <= 10) return "8 - 10";
    if (age >= 11 && age <= 12) return "10 - 12";
    return "6 - 8";
  }

  // --- NOTIFICATION LOGIC ---
  Future<void> _sendClassNotification(
      String teacherId,
      String videoTitle,
      String ageGroup,
      ) async {
    const String backendUrl = ApiConstants.notifyChildClassEndPoints;

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": teacherId,
          "type": "Video",
          "title": "Video Updated: $videoTitle ✏️",
          "body": "The video for Group $ageGroup has been updated. Check it out!",
          "ageGroup": ageGroup,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Video Update Notification sent successfully");
      }
    } catch (e) {
      print("❌ Error calling notification backend: $e");
    }
  }

  Future<void> _updateVideo() async {
    if (_titleController.text.isEmpty || _selectedYear == null) return;

    String? teacherId = await SharedPreferencesHelper.instance.getUserId();
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: No Teacher ID. Re-login."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Process Mapping
    String mappedAgeGroup = _mapYearToClass(_selectedYear!);

    List<String> tagsList = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_isSensitive && !tagsList.contains('scary')) {
      tagsList.add('scary');
    }
    if (!_isSensitive) {
      tagsList.remove('scary');
    }

    final updatedVideo = widget.videoData.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      videoUrl: _newVideoFile?.path ?? _existingVideoUrl,
      thumbnailUrl: _newThumbnail?.path ?? _existingThumbnailUrl,
      duration: _durationController.text,
      uploadedAt: widget.videoData.uploadedAt,
      tags: tagsList,
      isSensitive: _isSensitive,
      ageGroup: mappedAgeGroup, // Updated Classification
    );

    await ref
        .read(teacherMultimediaViewModelProvider.notifier)
        .updateVideo(updatedVideo);

    if (!_isSensitive) {
      await _sendClassNotification(teacherId, updatedVideo.title, mappedAgeGroup);
    }
  }

  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _newThumbnail = File(img.path));
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => _newVideoFile = File(video.path));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherMultimediaViewModelProvider);

    ref.listen(teacherMultimediaViewModelProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSensitive
                  ? "Video Updated! (No notification - marked sensitive)"
                  : "Video Updated & Class Notified!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(teacherMultimediaViewModelProvider.notifier).resetSuccess();
        Navigator.pop(context);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${next.errorMessage}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    ImageProvider? thumbnailProvider;
    if (_newThumbnail != null) {
      thumbnailProvider = FileImage(_newThumbnail!);
    } else if (_existingThumbnailUrl != null &&
        _existingThumbnailUrl!.isNotEmpty) {
      thumbnailProvider = NetworkImage(_existingThumbnailUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text(
          "Edit Video",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Video Title"),
                      _buildTextField(_titleController, "Enter title"),
                      SizedBox(height: 2.h),
                      _buildLabel("Description"),
                      _buildTextField(
                        _descController,
                        "Enter description",
                        maxLines: 3,
                      ),
                      SizedBox(height: 2.h),

                      // --- NEW: Age Selection Dropdown ---
                      _buildLabel("Target Age (Years)"),
                      _buildAgeDropdown(),
                      SizedBox(height: 2.h),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Category"),
                                _buildDropdown(),
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Duration"),
                                _buildTextField(
                                    _durationController, "e.g. 05:30"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Content Safety",
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildLabel("Tags (comma separated)"),
                      _buildTextField(
                        _tagsController,
                        "e.g. animals, space, fun",
                      ),
                      SizedBox(height: 2.h),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.red,
                        title: Text(
                          "Contains Sensitive Content?",
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        subtitle: Text(
                          "Marks as 'Scary' for parent filters.",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.black54,
                          ),
                        ),
                        value: _isSensitive,
                        onChanged: (val) => setState(() => _isSensitive = val),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Thumbnail Image"),
                      SizedBox(height: 1.h),
                      InkWell(
                        onTap: _pickThumbnail,
                        child: Container(
                          height: 18.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: thumbnailProvider != null
                                ? DecorationImage(
                              image: thumbnailProvider,
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: thumbnailProvider == null
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image,
                                    color: Colors.orange, size: 30.sp),
                                SizedBox(height: 1.h),
                                Text(
                                  "Tap to change thumbnail",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _newThumbnail = null;
                                    _existingThumbnailUrl = null;
                                  }),
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 16,
                                    child: Icon(Icons.close,
                                        size: 20, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Video File"),
                      SizedBox(height: 1.h),
                      InkWell(
                        onTap: _pickVideo,
                        child: Container(
                          height: 15.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _newVideoFile != null ||
                                      _existingVideoUrl != null
                                      ? Icons.check_circle
                                      : Icons.video_library,
                                  color: _newVideoFile != null ||
                                      _existingVideoUrl != null
                                      ? Colors.green
                                      : _primaryRed,
                                  size: 32.sp,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  _newVideoFile != null ||
                                      _existingVideoUrl != null
                                      ? "Video selected (tap to change)"
                                      : "Tap to change video file",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5.h),

                SizedBox(
                  width: double.infinity,
                  height: 7.h,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _updateVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Update Video",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _primaryBlue, size: 24.sp),
          items: _individualYears
              .map(
                (y) => DropdownMenuItem(
              value: y,
              child: Text(
                "$y Years Old",
                style: GoogleFonts.poppins(fontSize: 15.sp),
              ),
            ),
          )
              .toList(),
          onChanged: (v) => setState(() => _selectedYear = v!),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 1.h),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    ),
  );

  Widget _buildTextField(
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _primaryBlue, size: 22.sp),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
              value: c,
              child: Text(
                c,
                style: GoogleFonts.poppins(fontSize: 15.sp),
              ),
            ),
          )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }
}