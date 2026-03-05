import 'dart:convert';
import 'dart:io';
import 'package:eco_venture/core/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../models/quiz_topic_model.dart';
import '../../../../services/shared_preferences_helper.dart';
import '../../../viewmodels/teacher_quiz/teacher_quiz_provider.dart';

class TeacherEditQuizScreen extends ConsumerStatefulWidget {
  final dynamic quizData;

  const TeacherEditQuizScreen({super.key, required this.quizData});

  @override
  ConsumerState<TeacherEditQuizScreen> createState() => _TeacherEditQuizScreenState();
}

class _TeacherEditQuizScreenState extends ConsumerState<TeacherEditQuizScreen> {
  // --- PRO COLORS ---
  final Color _primary = const Color(0xFF1565C0);
  final Color _bg = const Color(0xFFF4F7FE);
  final Color _surface = Colors.white;
  final Color _textDark = const Color(0xFF1B2559);
  final Color _textGrey = const Color(0xFFA3AED0);
  final Color _border = const Color(0xFFE0E0E0);

  // --- CONTROLLERS ---
  late TextEditingController _topicNameController;
  late TextEditingController _tagsController;

  // --- STATE ---
  late QuizTopicModel _topic;
  late String _selectedCategory;
  final List<String> _categories = ['Science', 'Maths', 'Animals', 'Ecosystem'];
  late List<QuizLevelModel> _levels;
  late bool _isSensitive;

  // --- NEW: Age Selection State ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  @override
  void initState() {
    super.initState();

    if (widget.quizData is QuizTopicModel) {
      _topic = widget.quizData as QuizTopicModel;
    } else {
      final map = Map<String, dynamic>.from(widget.quizData as Map);
      _topic = QuizTopicModel.fromMap(map['id'] ?? '', map['category'] ?? 'Science', map);
    }

    _topicNameController = TextEditingController(text: _topic.topicName);
    _tagsController = TextEditingController(text: _topic.tags.join(', '));
    _selectedCategory = _categories.contains(_topic.category) ? _topic.category : _categories.first;
    _levels = List<QuizLevelModel>.from(_topic.levels);
    _isSensitive = _topic.isSensitive;

    // --- NEW: Initialize selected year from existing range string ---
    if (_topic.ageGroup == "6 - 8") {
      _selectedYear = "6";
    } else if (_topic.ageGroup == "8 - 10") {
      _selectedYear = "9";
    } else if (_topic.ageGroup == "10 - 12") {
      _selectedYear = "11";
    } else {
      _selectedYear = "6";
    }
  }

  @override
  void dispose() {
    _topicNameController.dispose();
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
    return "6 - 8";
  }

  // --- NOTIFICATION LOGIC ---
  Future<void> _sendClassNotification(String teacherId, String topicName, String ageGroup) async {
    const String backendUrl = ApiConstants.notifyChildClassEndPoints;

    try {
      await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": teacherId,
          "type": "Quiz",
          "title": "Quiz Updated: $topicName 📝",
          "body": "The quiz '$topicName' for Group $ageGroup has been updated!",
          "ageGroup": ageGroup,
        }),
      );
    } catch (e) {
      print("❌ Error calling backend: $e");
    }
  }

  // --- UPDATE LOGIC ---
  Future<void> _updateTopic() async {
    if (_topicNameController.text.trim().isEmpty || _selectedYear == null) {
      _showError("Please enter a Topic Name and select Target Age");
      return;
    }
    if (_levels.isEmpty) {
      _showError("Please ensure there is at least one Level");
      return;
    }

    String? teacherId = await SharedPreferencesHelper.instance.getUserId();

    // Mapping year to category
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

    final updatedTopic = _topic.copyWith(
      category: _selectedCategory,
      topicName: _topicNameController.text.trim(),
      levels: _levels,
      tags: tagsList,
      isSensitive: _isSensitive,
      ageGroup: mappedAgeGroup, // Pass updated age group
    );

    await ref.read(teacherQuizViewModelProvider.notifier).updateQuiz(updatedTopic);

    if (!_isSensitive && teacherId != null) {
      _sendClassNotification(teacherId, updatedTopic.topicName, mappedAgeGroup);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 15.sp)), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(teacherQuizViewModelProvider);

    ref.listen(teacherQuizViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz Updated Successfully!", style: TextStyle(fontSize: 15.sp)), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        ref.read(teacherQuizViewModelProvider.notifier).resetSuccess();
        Navigator.pop(context);
      }
      if (next.errorMessage != null) {
        _showError(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Quiz",
          style: GoogleFonts.poppins(color: _textDark, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("General Info", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textGrey)),
                SizedBox(height: 1.5.h),

                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProLabel("Category"),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textDark, size: 24.sp),
                            items: _categories.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: GoogleFonts.poppins(fontSize: 15.sp, color: _textDark, fontWeight: FontWeight.w600))
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),

                      _buildProLabel("Topic Name"),
                      SizedBox(height: 1.h),
                      _buildProTextField(controller: _topicNameController, hint: "e.g. Solar System", icon: Icons.title_rounded),

                      // --- NEW: Target Age Dropdown ---
                      SizedBox(height: 3.h),
                      _buildProLabel("Target Age (Years)"),
                      SizedBox(height: 1.h),
                      _buildAgeDropdown(),

                      SizedBox(height: 3.h),
                      _buildProLabel("Tags (comma-separated)"),
                      SizedBox(height: 1.h),
                      _buildProTextField(controller: _tagsController, hint: "e.g. history, fun", icon: Icons.tag),

                      SizedBox(height: 3.h),
                      Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Mark as Sensitive Content",
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              )),
                          subtitle: Text(
                            "If enabled, this quiz will be blocked for younger children.",
                            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
                          ),
                          value: _isSensitive,
                          onChanged: (v) => setState(() => _isSensitive = v),
                          activeThumbColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Levels Config", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textGrey)),
                    InkWell(
                      onTap: () => _showLevelEditor(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 18.sp, color: _primary),
                            SizedBox(width: 1.5.w),
                            Text("Add Level", style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: _primary)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 2.h),

                if (_levels.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _levels.length,
                    separatorBuilder: (c, i) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) => _buildProLevelCard(index, _levels[index]),
                  ),

                SizedBox(height: 5.h),

                SizedBox(
                  width: double.infinity,
                  height: 7.h,
                  child: ElevatedButton(
                    onPressed: quizState.isLoading ? null : _updateTopic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: quizState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("UPDATE QUIZ", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                SizedBox(height: 5.h),
              ],
            ),
          ),
          if (quizState.isLoading)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  // --- PRO WIDGETS ---

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textDark, size: 24.sp),
          items: _individualYears.map((y) => DropdownMenuItem(
              value: y,
              child: Text("$y Years Old", style: GoogleFonts.poppins(fontSize: 15.sp, color: _textDark, fontWeight: FontWeight.w600))
          )).toList(),
          onChanged: (val) => setState(() => _selectedYear = val!),
        ),
      ),
    );
  }

  Widget _buildProLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _textGrey));
  }

  Widget _buildProTextField({required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 15.sp, color: _textDark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 15.sp),
        prefixIcon: Icon(icon, size: 22.sp, color: _textGrey),
        filled: true,
        fillColor: _bg,
        contentPadding: EdgeInsets.symmetric(vertical: 2.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primary, width: 2)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_clear_outlined, size: 36.sp, color: Colors.grey.shade300),
          SizedBox(height: 1.h),
          Text("No Levels Added", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textGrey)),
          Text("Create a learning path by adding levels.", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey.shade400), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProLevelCard(int index, QuizLevelModel level) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        leading: Container(
          width: 13.w, height: 13.w,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text("${level.order}", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _primary))),
        ),
        title: Text(level.title, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textDark)),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 0.5.h),
          child: Text("${level.questions.length} Questions • ${level.points} Pts • Pass: ${level.passingPercentage}%", style: GoogleFonts.poppins(fontSize: 13.sp, color: _textGrey)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: Colors.blue, size: 20.sp),
              onPressed: () => _showLevelEditor(existingLevel: level, index: index),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20.sp),
              onPressed: () => setState(() => _levels.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelEditor({QuizLevelModel? existingLevel, int? index}) {
    final titleCtrl = TextEditingController(text: existingLevel?.title ?? "");
    final orderCtrl = TextEditingController(text: existingLevel?.order.toString() ?? "${_levels.length + 1}");
    final pointsCtrl = TextEditingController(text: existingLevel?.points.toString() ?? "10");
    final passCtrl = TextEditingController(text: existingLevel?.passingPercentage.toString() ?? "60");

    List<QuestionModel> tempQuestions = existingLevel != null ? List.from(existingLevel.questions) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 90.h,
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, MediaQuery.of(context).viewInsets.bottom + 2.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(width: 15.w, height: 0.6.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                SizedBox(height: 2.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(existingLevel == null ? "Add Level" : "Edit Level", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _textDark)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: _textGrey, size: 22.sp)),
                  ],
                ),
                Divider(height: 1, color: _border),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                    children: [
                      _buildProLabel("Level Title"),
                      SizedBox(height: 1.h),
                      _buildProTextField(controller: titleCtrl, hint: "e.g. Basics", icon: Icons.text_fields_rounded),
                      SizedBox(height: 2.h),

                      Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildProLabel("Order"), SizedBox(height: 1.h), _buildProTextField(controller: orderCtrl, hint: "1", icon: Icons.format_list_numbered_rounded, isNumber: true)])),
                          SizedBox(width: 3.w),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildProLabel("Points"), SizedBox(height: 1.h), _buildProTextField(controller: pointsCtrl, hint: "10", icon: Icons.star_border_rounded, isNumber: true)])),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildProLabel("Passing Percentage"),
                      SizedBox(height: 1.h),
                      _buildProTextField(controller: passCtrl, hint: "60", icon: Icons.percent_rounded, isNumber: true),

                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Questions (${tempQuestions.length})", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textDark)),
                          TextButton.icon(
                            onPressed: () {
                              _showQuestionEditor(context, (newQ) {
                                setModalState(() => tempQuestions.add(newQ));
                              });
                            },
                            icon: Icon(Icons.add_circle, size: 20.sp),
                            label: Text("Add", style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(foregroundColor: _primary),
                          )
                        ],
                      ),
                      SizedBox(height: 1.h),

                      if (tempQuestions.isEmpty)
                        Container(
                          padding: EdgeInsets.all(3.h),
                          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                          child: Center(child: Text("No questions added yet", style: GoogleFonts.poppins(fontSize: 14.sp, color: _textGrey))),
                        )
                      else
                        ...tempQuestions.asMap().entries.map((e) => Container(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          decoration: BoxDecoration(color: _surface, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                            title: Text("Q${e.key+1}: ${e.value.question}", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: _primary, size: 20.sp),
                                  onPressed: () {
                                    _showQuestionEditor(
                                        context,
                                            (updatedQ) => setModalState(() => tempQuestions[e.key] = updatedQ),
                                        existingQuestion: e.value
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20.sp),
                                  onPressed: () => setModalState(() => tempQuestions.removeAt(e.key)),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _border))),
                  child: SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty || tempQuestions.isEmpty) return;
                        final newLevel = QuizLevelModel(
                          title: titleCtrl.text,
                          order: int.tryParse(orderCtrl.text) ?? 1,
                          passingPercentage: int.tryParse(passCtrl.text) ?? 60,
                          points: int.tryParse(pointsCtrl.text) ?? 10,
                          questions: tempQuestions,
                        );
                        setState(() {
                          if (index != null) _levels[index] = newLevel;
                          else _levels.add(newLevel);
                          _levels.sort((a, b) => a.order.compareTo(b.order));
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(index == null ? "ADD LEVEL" : "UPDATE LEVEL", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQuestionEditor(BuildContext ctx, Function(QuestionModel) onSave, {QuestionModel? existingQuestion}) {
    final qTextController = TextEditingController(text: existingQuestion?.question ?? "");
    final op1 = TextEditingController(text: existingQuestion?.options.isNotEmpty == true ? existingQuestion!.options[0] : "");
    final op2 = TextEditingController(text: existingQuestion?.options.length == 4 ? existingQuestion!.options[1] : "");
    final op3 = TextEditingController(text: existingQuestion?.options.length == 4 ? existingQuestion!.options[2] : "");
    final op4 = TextEditingController(text: existingQuestion?.options.length == 4 ? existingQuestion!.options[3] : "");

    File? newImageFile;
    String? existingImageUrl = existingQuestion?.imageUrl;

    int correctIdx = 0;
    if (existingQuestion != null) {
      int foundIdx = existingQuestion.options.indexOf(existingQuestion.answer);
      if (foundIdx != -1) correctIdx = foundIdx;
    }

    showDialog(context: ctx, builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(5.w),
          height: 80.h,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(existingQuestion == null ? "New Question" : "Edit Question", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold, color: _textDark)),
                SizedBox(height: 3.h),

                _buildProTextField(controller: qTextController, hint: "Question Text", icon: Icons.help_outline),
                SizedBox(height: 2.h),

                InkWell(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
                    if(img != null) setState(() { newImageFile = File(img.path); existingImageUrl = null; });
                  },
                  child: Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: _bg,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(12),
                        image: newImageFile != null
                            ? DecorationImage(image: FileImage(newImageFile!), fit: BoxFit.cover)
                            : (existingImageUrl != null ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover) : null)
                    ),
                    child: (newImageFile == null && existingImageUrl == null)
                        ? Center(child: Text("Tap to add Image (Optional)", style: GoogleFonts.poppins(fontSize: 14.sp, color: _primary)))
                        : Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red, size: 20.sp),
                        onPressed: () => setState(() { newImageFile = null; existingImageUrl = null; }),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                ...List.generate(4, (i) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      Radio(value: i, groupValue: correctIdx, onChanged: (v) => setState(() => correctIdx = v!), activeColor: _primary),
                      Expanded(child: TextField(
                          controller: [op1, op2, op3, op4][i],
                          style: TextStyle(fontSize: 15.sp),
                          decoration: InputDecoration(hintText: "Option ${i+1}", filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))
                      )),
                    ],
                  ),
                )),

                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  height: 6.5.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (qTextController.text.isNotEmpty) {
                        onSave(QuestionModel(
                          question: qTextController.text,
                          options: [op1.text, op2.text, op3.text, op4.text],
                          answer: [op1.text, op2.text, op3.text, op4.text][correctIdx],
                          imageUrl: newImageFile?.path ?? existingImageUrl,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text("SAVE QUESTION", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}