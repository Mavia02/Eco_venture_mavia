import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../models/stem_challenge_model.dart';
import '../../../core/config/api_constants.dart';
import '../../../services/shared_preferences_helper.dart';
import '../../../viewmodels/teacher_stem_challenge/teacher_stem_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../viewmodels/teacher_stem_challenge/teacher_stem_state.dart';

class TeacherAddStemChallengeScreen extends ConsumerStatefulWidget {
  const TeacherAddStemChallengeScreen({super.key});

  @override
  ConsumerState<TeacherAddStemChallengeScreen> createState() =>
      _TeacherAddStemChallengeScreenState();
}

class _TeacherAddStemChallengeScreenState
    extends ConsumerState<TeacherAddStemChallengeScreen> {
  // --- COLORS ---
  final Color _primaryBlue = const Color(0xFF1565C0);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _textGrey = const Color(0xFFA3AED0);
  final Color _borderGrey = const Color(0xFFE0E0E0);
  final Color _dashedBorderColor = const Color(0xFFBDBDBD);

  // --- CONTROLLERS & STATE ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(
    text: "50",
  );
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'Science';
  final List<String> _categories = [
    'Science',
    'Technology',
    'Engineering',
    'Mathematics',
  ];
  String _selectedDifficulty = 'Easy';
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];

  // --- NEW: Age Selection State ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  File? _challengeImage;
  List<String> _materials = ['Baking Soda', 'Vinegar'];
  List<String> _steps = [
    "Mix baking soda and vinegar",
    "Observe the chemical reaction",
  ];

  bool _isSensitive = false;
  bool _shouldPopAfterSave = false;

  // Logic: Map the individual year selection to the broad backend classes
  String _mapYearToClass(String year) {
    int age = int.parse(year);
    if (age >= 6 && age <= 8) {
      return "6 - 8";
    } else if (age >= 9 && age <= 10) {
      return "8 - 10";
    } else if (age >= 11 && age <= 12) {
      return "10 - 12";
    }
    return "6 - 8"; // Default fallback
  }

  // --- NOTIFICATION LOGIC (Updated to include ageGroup) ---
  Future<void> _sendClassNotification(
      String teacherId,
      String challengeTitle,
      String ageGroup,
      ) async {
    const String backendUrl = ApiConstants.notifyChildClassEndPoints;

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": teacherId,
          "type": "STEM Challenge",
          "title": "New STEM Challenge: $challengeTitle 🔬",
          "body": "A new STEM challenge for Group $ageGroup is ready!",
          "ageGroup": ageGroup, // Backend uses this to target correct class
        }),
      );

      if (response.statusCode == 200) {
        print("✅ STEM Challenge Notification sent successfully");
      }
    } catch (e) {
      print("❌ Error calling notification backend: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(teacherStemViewModelProvider);

    ref.listen(teacherStemViewModelProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: TextStyle(fontSize: 15.sp)),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSensitive
                  ? "Challenge Saved! (No notification - marked sensitive)"
                  : "Challenge Saved & Class Notified!",
              style: TextStyle(fontSize: 15.sp),
            ),
            backgroundColor: Colors.green,
          ),
        );

        ref.read(teacherStemViewModelProvider.notifier).resetSuccess();

        if (_shouldPopAfterSave) {
          Navigator.pop(context);
        } else {
          _clearForm();
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CARD 1 ---
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Challenge Basics"),
                            SizedBox(height: 2.5.h),
                            _buildLabel("Challenge Title"),
                            _buildTextField(
                              controller: _titleController,
                              hint: "e.g. Bridge Building",
                            ),
                            SizedBox(height: 2.5.h),

                            // --- NEW: Target Age (Years) Dropdown ---
                            _buildLabel("Target Age (Years)"),
                            _buildAgeDropdown(),
                            SizedBox(height: 2.5.h),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("Category"),
                                      _buildDropdown(
                                        _categories,
                                        _selectedCategory,
                                            (v) => setState(
                                              () => _selectedCategory = v!,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("Difficulty"),
                                      _buildDropdown(
                                        _difficultyLevels,
                                        _selectedDifficulty,
                                            (v) => setState(
                                              () => _selectedDifficulty = v!,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.5.h),
                            _buildLabel("Points Reward"),
                            _buildTextField(
                              controller: _pointsController,
                              hint: "50",
                              isNumber: true,
                            ),

                            SizedBox(height: 2.5.h),
                            _buildLabel("Tags (comma-separated)"),
                            _buildTextField(
                              controller: _tagsController,
                              hint: "e.g. chemicals, outdoor, tools, engineering",
                            ),

                            SizedBox(height: 2.5.h),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Mark as Sensitive Content",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade400,
                                  )),
                              subtitle: Text(
                                "If enabled, this challenge will be blocked for younger children.",
                                style: GoogleFonts.poppins(fontSize: 12.sp),
                              ),
                              value: _isSensitive,
                              onChanged: (v) => setState(() => _isSensitive = v),
                              activeThumbColor: Colors.red,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // --- CARD 2 ---
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Visuals"),
                            SizedBox(height: 2.h),
                            _buildLabel("Cover Image"),
                            _buildImageUpload(),
                          ],
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // --- CARD 3 ---
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader("Materials"),
                                _buildAddButton(
                                  "Add Item",
                                      () => _showAddItemDialog(
                                    "Material",
                                        (val) =>
                                        setState(() => _materials.add(val)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Wrap(
                              spacing: 2.w,
                              runSpacing: 1.h,
                              children: _materials
                                  .map(
                                    (m) => _buildChip(
                                  m,
                                      () =>
                                      setState(() => _materials.remove(m)),
                                ),
                              )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // --- CARD 4 ---
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader("Instructions"),
                                _buildAddButton(
                                  "Add Step",
                                      () => _showAddItemDialog(
                                    "Step Description",
                                        (val) => setState(() => _steps.add(val)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            ..._steps.asMap().entries.map(
                                  (e) => _buildStepItem(e.key + 1, e.value),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 5.h),
                      _buildFooterButtons(viewModelState.isLoading),
                      SizedBox(height: 5.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (viewModelState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // --- SAVE LOGIC ---
  Future<void> _saveChallenge() async {
    if (_titleController.text.trim().isEmpty || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all basics, including Target Age")),
      );
      return;
    }
    if (_pointsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter points")),
      );
      return;
    }

    String? teacherId = await SharedPreferencesHelper.instance.getUserId();
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No Teacher ID. Re-login.")),
      );
      return;
    }

    // Logic: Convert selected year to Class Category
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

    final newChallenge = StemChallengeModel(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      points: int.tryParse(_pointsController.text.trim()) ?? 0,
      imageUrl: _challengeImage?.path,
      materials: _materials,
      steps: _steps,
      tags: tagsList,
      isSensitive: _isSensitive,
      ageGroup: mappedAgeGroup, // Stored for student filtering
    );

    await ref
        .read(teacherStemViewModelProvider.notifier)
        .addChallenge(newChallenge);

    if (!_isSensitive) {
      await _sendClassNotification(teacherId, newChallenge.title, mappedAgeGroup);
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _pointsController.text = "50";
      _materialController.clear();
      _tagsController.clear();
      _selectedCategory = _categories.first;
      _selectedDifficulty = _difficultyLevels.first;
      _selectedYear = null; // Clear year
      _challengeImage = null;
      _materials = [];
      _steps = [];
      _isSensitive = false;
    });
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          hint: Text(
            "Select Age",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15.sp),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: _primaryBlue,
            size: 22.sp,
          ),
          items: _individualYears
              .map(
                (y) => DropdownMenuItem(
              value: y,
              child: Text(
                "$y Years Old",
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
              .toList(),
          onChanged: (v) => setState(() => _selectedYear = v),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 6.h, bottom: 3.h, left: 5.w, right: 5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            "New Challenge",
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 17.sp,
      fontWeight: FontWeight.w800,
      color: _textDark,
    ),
  );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 15.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items,
      String selected,
      Function(String?) onChanged,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: _primaryBlue,
            size: 22.sp,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return CustomPaint(
      painter: DashedRectPainter(
        color: _primaryBlue,
        strokeWidth: 2,
        gap: 6,
        radius: 16,
      ),
      child: InkWell(
        onTap: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? img = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (img != null) setState(() => _challengeImage = File(img.path));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 22.h,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: _challengeImage == null
              ? BoxDecoration(
            color: _primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          )
              : null,
          child: _challengeImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _challengeImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 32.sp,
                color: _primaryBlue,
              ),
              SizedBox(height: 1.h),
              Text(
                "Tap to upload image",
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: _primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 18.sp, color: _primaryBlue),
            SizedBox(width: 1.5.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: _primaryBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _primaryBlue.withOpacity(0.2)),
      ),
      deleteIcon: Icon(Icons.close, size: 18.sp, color: Colors.redAccent),
      onDeleted: onDelete,
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
    );
  }

  Widget _buildStepItem(int index, String text) {
    return Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14.sp,
              backgroundColor: _primaryBlue,
              child: Text(
                "$index",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(fontSize: 15.sp, color: _textDark),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _steps.remove(text)),
              child: Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20.sp,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildFooterButtons(bool isLoading) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 7.5.h,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
              setState(() => _shouldPopAfterSave = true);
              _saveChallenge();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
            ),
            child: Text(
              "Publish Challenge",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: double.infinity,
          height: 7.5.h,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
              setState(() => _shouldPopAfterSave = false);
              _saveChallenge();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _lightBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              "Save & Add Another",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(String title, Function(String) onAdd) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add $title",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: "Enter detail",
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onAdd(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Add",
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;
  final double radius;
  DashedRectPainter({
    this.strokeWidth = 1.0,
    this.color = Colors.red,
    this.gap = 5.0,
    this.radius = 0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + 5),
          dashedPaint,
        );
        distance += 5 + gap;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}