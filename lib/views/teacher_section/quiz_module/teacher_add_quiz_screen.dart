import 'dart:convert';
import 'dart:io';
import 'package:eco_venture/core/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../models/quiz_topic_model.dart';
import '../../../../services/shared_preferences_helper.dart';
import '../../../viewmodels/teacher_quiz/teacher_quiz_provider.dart';

class TeacherAddQuizScreen extends ConsumerStatefulWidget {
  const TeacherAddQuizScreen({super.key});

  @override
  ConsumerState<TeacherAddQuizScreen> createState() =>
      _TeacherAddQuizScreenState();
}

class _TeacherAddQuizScreenState extends ConsumerState<TeacherAddQuizScreen> {
  // --- COLORS ---
  final Color _primary = const Color(0xFF1565C0);
  final Color _bg = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _textLabel = const Color(0xFF333333);
  final Color _border = const Color(0xFFE0E0E0);

  // --- TOPIC STATE ---
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'Science';
  final List<String> _categories = ['Science', 'Maths', 'Animals', 'Ecosystem'];

  // --- NEW: Age Selection State ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  final List<QuizLevelModel> _levels = [];
  bool _isSensitive = false;

  @override
  void dispose() {
    _topicController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

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

  // --- NOTIFICATION LOGIC ---
  Future<void> _sendClassNotification(
      String teacherId,
      String topicName,
      String ageGroup,
      ) async {
    const String backendUrl = ApiConstants.notifyChildClassEndPoints;

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": teacherId,
          "type": "Quiz",
          "title": "New Quiz: $topicName 🧠",
          "body": "A new quiz for Group $ageGroup is ready!",
          "ageGroup": ageGroup, // Pass ageGroup so backend knows who to notify
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Class Notification sent successfully");
      } else {
        print("❌ Notification failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error calling backend: $e");
    }
  }

  // --- SAVE LOGIC ---
  Future<void> _saveQuiz() async {
    if (_topicController.text.trim().isEmpty || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a Topic Name and select Target Age"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one Level"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Process Age Mapping
    String mappedAgeGroup = _mapYearToClass(_selectedYear!);

    // Process tags
    List<String> tagsList = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Sensitivity logic
    if (_isSensitive && !tagsList.contains('scary')) {
      tagsList.add('scary');
    }
    if (!_isSensitive) {
      tagsList.remove('scary');
    }

    final newTopic = QuizTopicModel(
      category: _selectedCategory,
      topicName: _topicController.text.trim(),
      createdBy: 'teacher',
      creatorId: teacherId,
      levels: _levels,
      tags: tagsList,
      isSensitive: _isSensitive,
      ageGroup: mappedAgeGroup, // Successfully passed to model
    );

    // 1. Add to Firebase via Provider
    await ref.read(teacherQuizViewModelProvider.notifier).addQuiz(newTopic);

    // 2. Trigger Notification (Only if not sensitive)
    if (!_isSensitive) {
      _sendClassNotification(teacherId, newTopic.topicName, mappedAgeGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(teacherQuizViewModelProvider);

    ref.listen(teacherQuizViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Quiz Published & Class Notified!"),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(teacherQuizViewModelProvider.notifier).resetSuccess();
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

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create New Quiz",
          style: GoogleFonts.poppins(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Topic Information"),
                SizedBox(height: 2.h),

                _buildLabel("Category"),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primary,
                        size: 22.sp,
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                  ),
                ),
                SizedBox(height: 2.5.h),

                _buildLabel("Quiz Topic Name"),
                _buildTextField(
                  controller: _topicController,
                  hint: "e.g. Solar System",
                ),

                // --- NEW: Target Age Dropdown ---
                SizedBox(height: 2.5.h),
                _buildLabel("Target Age (Years)"),
                _buildAgeDropdown(),

                // --- Tags Field ---
                SizedBox(height: 2.5.h),
                _buildLabel("Tags (comma-separated)"),
                _buildTextField(
                  controller: _tagsController,
                  hint: "e.g. history, fun",
                ),

                // --- Sensitivity Switch ---
                SizedBox(height: 2.5.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: Colors.red,
                    title: Text(
                      "Mark as Sensitive Content",
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                    subtitle: Text(
                      "If enabled, this quiz will be blocked for younger children.",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                    value: _isSensitive,
                    onChanged: (v) => setState(() => _isSensitive = v),
                  ),
                ),

                SizedBox(height: 4.h),

                // Levels Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("Levels (${_levels.length})"),
                    InkWell(
                      onTap: () => _showLevelEditor(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: _primary, size: 18.sp),
                            SizedBox(width: 2.w),
                            Text(
                              "Add Level",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Levels List
                if (_levels.isEmpty)
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Center(
                      child: Text(
                        "No levels added yet.\nClick 'Add Level' to start.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _levels.length,
                    separatorBuilder: (c, i) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) =>
                        _buildLevelCard(index, _levels[index]),
                  ),

                SizedBox(height: 5.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 7.h,
                  child: ElevatedButton(
                    onPressed: quizState.isLoading ? null : _saveQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: quizState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "PUBLISH QUIZ",
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          hint: Text(
            "Select Age",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14.sp),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
          items: _individualYears
              .map(
                (y) => DropdownMenuItem(
              value: y,
              child: Text(
                "$y Years Old",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
              .toList(),
          onChanged: (val) => setState(() => _selectedYear = val),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: _primary,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h, left: 1.w),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: _textLabel,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        color: _textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 2.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildLevelCard(int index, QuizLevelModel level) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Level ${level.order}: ${level.title}",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue, size: 18.sp),
                    onPressed: () =>
                        _showLevelEditor(existingLevel: level, index: index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 18.sp),
                    onPressed: () => setState(() => _levels.removeAt(index)),
                  ),
                ],
              ),
            ],
          ),
          Divider(color: Colors.grey.shade200),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoBadge(Icons.star, "${level.points} Pts", Colors.amber),
              _buildInfoBadge(
                Icons.percent,
                "${level.passingPercentage}% Pass",
                Colors.blue,
              ),
              _buildInfoBadge(
                Icons.help_outline,
                "${level.questions.length} Qs",
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 1.5.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _showLevelEditor({QuizLevelModel? existingLevel, int? index}) {
    final titleCtrl = TextEditingController(text: existingLevel?.title ?? "");
    final orderCtrl = TextEditingController(
      text: existingLevel?.order.toString() ?? "${_levels.length + 1}",
    );
    final pointsCtrl = TextEditingController(
      text: existingLevel?.points.toString() ?? "10",
    );
    final passCtrl = TextEditingController(
      text: existingLevel?.passingPercentage.toString() ?? "60",
    );

    List<QuestionModel> tempQuestions = existingLevel != null
        ? List.from(existingLevel.questions)
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 90.h,
            padding: EdgeInsets.fromLTRB(
              5.w,
              2.h,
              5.w,
              MediaQuery.of(context).viewInsets.bottom + 2.h,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 15.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  existingLevel == null ? "Add Level" : "Edit Level",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Level Title"),
                        _buildTextField(
                          controller: titleCtrl,
                          hint: "e.g. Basics",
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Order"),
                                  _buildTextField(
                                    controller: orderCtrl,
                                    hint: "1",
                                    isNumber: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Points"),
                                  _buildTextField(
                                    controller: pointsCtrl,
                                    hint: "10",
                                    isNumber: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Pass %"),
                                  _buildTextField(
                                    controller: passCtrl,
                                    hint: "60",
                                    isNumber: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Questions (${tempQuestions.length})",
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _showQuestionEditor(context, (newQ) {
                                  setModalState(() => tempQuestions.add(newQ));
                                });
                              },
                              icon: const Icon(Icons.add_circle),
                              label: Text(
                                "Add Question",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: _primary,
                              ),
                            ),
                          ],
                        ),
                        if (tempQuestions.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(2.h),
                              child: Text(
                                "Add at least one question",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tempQuestions.length,
                            itemBuilder: (c, i) {
                              final q = tempQuestions[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  "Q${i + 1}: ${q.question}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setModalState(
                                        () => tempQuestions.removeAt(i),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  height: 6.5.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty || tempQuestions.isEmpty) {
                        return;
                      }
                      final newLevel = QuizLevelModel(
                        title: titleCtrl.text,
                        order: int.tryParse(orderCtrl.text) ?? 1,
                        passingPercentage: int.tryParse(passCtrl.text) ?? 60,
                        points: int.tryParse(pointsCtrl.text) ?? 10,
                        questions: tempQuestions,
                      );
                      setState(() {
                        if (index != null) {
                          _levels[index] = newLevel;
                        } else {
                          _levels.add(newLevel);
                        }
                        _levels.sort((a, b) => a.order.compareTo(b.order));
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _textDark),
                    child: Text(
                      index == null ? "ADD LEVEL" : "UPDATE LEVEL",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQuestionEditor(BuildContext ctx, Function(QuestionModel) onSave) {
    String qText = "";
    File? qImage;
    final op1Ctrl = TextEditingController();
    final op2Ctrl = TextEditingController();
    final op3Ctrl = TextEditingController();
    final op4Ctrl = TextEditingController();
    int selectedOptionIndex = -1;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 85.h,
          padding: EdgeInsets.fromLTRB(
            5.w,
            2.h,
            5.w,
            MediaQuery.of(context).viewInsets.bottom + 2.h,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "New Question",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                TextField(
                  onChanged: (v) => qText = v,
                  maxLines: 2,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: "Enter question...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                InkWell(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? img = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (img != null) {
                      setModalState(() => qImage = File(img.path));
                    }
                  },
                  child: Container(
                    height: 10.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: _primary),
                      borderRadius: BorderRadius.circular(8),
                      image: qImage != null
                          ? DecorationImage(
                        image: FileImage(qImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: qImage == null
                        ? Center(
                      child: Text(
                        "Tap to add Image (Optional)",
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: _primary,
                        ),
                      ),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: 2.h),
                ...List.generate(4, (i) {
                  final ctrl = [op1Ctrl, op2Ctrl, op3Ctrl, op4Ctrl][i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            style: TextStyle(fontSize: 13.sp),
                            decoration: InputDecoration(
                              hintText: "Option ${i + 1}",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        InkWell(
                          onTap: () =>
                              setModalState(() => selectedOptionIndex = i),
                          child: Icon(
                            selectedOptionIndex == i
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selectedOptionIndex == i
                                ? Colors.green
                                : Colors.grey,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (qText.isEmpty || selectedOptionIndex == -1) return;
                      final newQ = QuestionModel(
                        question: qText,
                        options: [
                          op1Ctrl.text,
                          op2Ctrl.text,
                          op3Ctrl.text,
                          op4Ctrl.text,
                        ],
                        answer: [
                          op1Ctrl.text,
                          op2Ctrl.text,
                          op3Ctrl.text,
                          op4Ctrl.text,
                        ][selectedOptionIndex],
                        imageUrl: qImage?.path,
                      );
                      onSave(newQ);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _primary),
                    child: Text(
                      "SAVE QUESTION",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
