import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // Required for PathMetrics
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

// Import Backend Model
import '../../../../models/stem_challenge_model.dart';
import '../../../core/config/api_constants.dart';
import '../../../services/shared_preferences_helper.dart';
import '../../../viewmodels/teacher_stem_challenge/teacher_stem_provider.dart';

class TeacherEditStemChallengeScreen extends ConsumerStatefulWidget {
  final dynamic challengeData;

  const TeacherEditStemChallengeScreen({
    super.key,
    required this.challengeData,
  });

  @override
  ConsumerState<TeacherEditStemChallengeScreen> createState() =>
      _TeacherEditStemChallengeScreenState();
}

class _TeacherEditStemChallengeScreenState
    extends ConsumerState<TeacherEditStemChallengeScreen> {
  // --- PRO COLORS ---
  final Color _primaryBlue = const Color(0xFF1565C0);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _borderGrey = const Color(0xFFE0E0E0);
  final Color _dashedBorderColor = const Color(0xFFBDBDBD);

  // --- CONTROLLERS ---
  late TextEditingController _titleController;
  late TextEditingController _pointsController;
  final TextEditingController _materialController = TextEditingController();
  late TextEditingController _tagsController;

  // --- STATE ---
  late StemChallengeModel _challenge;
  late String _fixedCategory;
  late String _selectedDifficulty;
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];

  // --- AGE SELECTION STATE ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  File? _newImageFile;
  String? _existingImageUrl;

  late List<String> _materials;
  late List<String> _steps;
  late bool _isSensitive;

  @override
  void initState() {
    super.initState();

    // 1. Parse Data and FIX the reported error by ensuring ageGroup is parsed
    if (widget.challengeData is StemChallengeModel) {
      _challenge = widget.challengeData;
    } else {
      final map = Map<String, dynamic>.from(widget.challengeData);
      _challenge = StemChallengeModel(
        id: map['id'],
        title: map['title'] ?? '',
        category: map['category'] ?? 'Science',
        difficulty: map['difficulty'] ?? 'Easy',
        points: map['points'] is int
            ? map['points']
            : int.tryParse(map['points'].toString()) ?? 0,
        imageUrl: map['imageUrl'],
        materials: List<String>.from(map['materials'] ?? []),
        steps: List<String>.from(map['steps'] ?? []),
        tags: List<String>.from(map['tags'] ?? []),
        isSensitive: map['isSensitive'] ?? false,
        ageGroup: map['ageGroup'] ?? '6 - 8', // Fixed missing parameter
      );
    }

    // 2. Initialize Controllers with existing data
    _titleController = TextEditingController(text: _challenge.title);
    _pointsController = TextEditingController(text: _challenge.points.toString());
    _tagsController = TextEditingController(text: _challenge.tags.join(', '));

    // 3. Initialize UI State
    _fixedCategory = _challenge.category;
    _selectedDifficulty = _challenge.difficulty;
    _materials = List<String>.from(_challenge.materials);
    _steps = List<String>.from(_challenge.steps);
    _existingImageUrl = _challenge.imageUrl;
    _isSensitive = _challenge.isSensitive;

    // 4. Initialize selected year based on current database ageGroup range
    if (_challenge.ageGroup == "6 - 8") {
      _selectedYear = "6";
    } else if (_challenge.ageGroup == "8 - 10") {
      _selectedYear = "9";
    } else if (_challenge.ageGroup == "10 - 12") {
      _selectedYear = "11";
    } else {
      _selectedYear = "6";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    _materialController.dispose();
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

  Future<void> _sendClassNotification(
      String teacherId,
      String challengeTitle,
      String ageGroup,
      ) async {
    const String backendUrl = ApiConstants.notifyChildClassEndPoints;
    try {
      await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": teacherId,
          "type": "STEM Challenge",
          "title": "STEM Challenge Updated: $challengeTitle ✏️",
          "body": "The STEM challenge for Group $ageGroup has been updated!",
          "ageGroup": ageGroup,
        }),
      );
    } catch (e) {
      debugPrint("❌ Notification Error: $e");
    }
  }

  Future<void> _updateChallenge() async {
    if (_titleController.text.trim().isEmpty || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title and select Target Age")),
      );
      return;
    }

    String mappedAgeGroup = _mapYearToClass(_selectedYear!);

    List<String> tagsList = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_isSensitive && !tagsList.contains('scary')) tagsList.add('scary');
    if (!_isSensitive) tagsList.remove('scary');

    final String? finalImage = _newImageFile?.path ?? _existingImageUrl;

    String? teacherId = await SharedPreferencesHelper.instance.getUserId();
    if (teacherId == null) return;

    final updatedChallenge = _challenge.copyWith(
      title: _titleController.text.trim(),
      category: _fixedCategory,
      difficulty: _selectedDifficulty,
      points: int.tryParse(_pointsController.text.trim()) ?? 0,
      imageUrl: finalImage,
      materials: _materials,
      steps: _steps,
      tags: tagsList,
      isSensitive: _isSensitive,
      ageGroup: mappedAgeGroup,
    );

    await ref.read(teacherStemViewModelProvider.notifier).updateChallenge(updatedChallenge);

    if (!_isSensitive) {
      await _sendClassNotification(teacherId, updatedChallenge.title, mappedAgeGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(teacherStemViewModelProvider);

    ref.listen(teacherStemViewModelProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Challenge Updated Successfully!"), backgroundColor: Colors.green),
        );
        ref.read(teacherStemViewModelProvider.notifier).resetSuccess();
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Challenge Details"),
                SizedBox(height: 2.h),

                _buildLabel("Challenge Title"),
                _buildTextField(controller: _titleController, hint: "Enter challenge title"),
                SizedBox(height: 2.h),

                _buildLabel("Target Age (Years)"),
                _buildAgeDropdown(),
                SizedBox(height: 2.h),

                _buildLabel("Difficulty Level"),
                _buildDifficultySelector(),
                SizedBox(height: 2.h),

                _buildLabel("Points"),
                SizedBox(
                  width: 30.w,
                  child: _buildTextField(controller: _pointsController, hint: "0", isNumber: true, isCenter: true),
                ),
                SizedBox(height: 2.h),

                _buildLabel("Category (Fixed)"),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderGrey),
                  ),
                  child: Text(_fixedCategory, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                ),
                SizedBox(height: 2.h),

                _buildLabel("Tags (comma-separated)"),
                _buildTextField(controller: _tagsController, hint: "e.g. chemicals, outdoor, tools"),
                SizedBox(height: 2.h),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Mark as Sensitive Content", style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                  subtitle: Text("If enabled, this challenge will be blocked for younger children.", style: GoogleFonts.poppins(fontSize: 12.sp)),
                  value: _isSensitive,
                  onChanged: (v) => setState(() => _isSensitive = v),
                  activeThumbColor: Colors.red,
                ),

                _buildLabel("Challenge Image"),
                _buildImageUploadBox(),
                SizedBox(height: 4.h),

                _buildSectionHeader("Materials Required"),
                SizedBox(height: 2.h),
                _buildMaterialsWrap(),
                SizedBox(height: 1.5.h),
                _buildDashedAddButton(label: "Add Material", onTap: _showAddMaterialDialog),
                SizedBox(height: 4.h),

                _buildSectionHeader("Instructions"),
                SizedBox(height: 2.h),
                _buildStepsList(),
                SizedBox(height: 1.5.h),
                _buildDashedAddButton(label: "Add Step", onTap: _showAddStepDialog),

                SizedBox(height: 5.h),
                _buildFooterButtons(viewModelState.isLoading),
                SizedBox(height: 5.h),
              ],
            ),
          ),
          if (viewModelState.isLoading)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _primaryBlue, size: 24.sp),
          items: _individualYears.map((y) => DropdownMenuItem(
              value: y,
              child: Text("$y Years Old", style: GoogleFonts.poppins(fontSize: 15.sp, color: _textDark, fontWeight: FontWeight.w500))
          )).toList(),
          onChanged: (val) => setState(() => _selectedYear = val!),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      centerTitle: true,
      title: Column(
        children: [
          Text("Edit STEM Challenge", style: GoogleFonts.poppins(color: _textDark, fontSize: 18.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_fixedCategory, style: GoogleFonts.poppins(color: _primaryBlue, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: GoogleFonts.poppins(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.black));

  Widget _buildLabel(String text) => Padding(padding: EdgeInsets.only(bottom: 1.h), child: Text(text, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _textDark)));

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isNumber = false, bool isCenter = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 16.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderGrey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _difficultyLevels.map((level) {
          final isSelected = _selectedDifficulty == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = level),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))] : []),
                child: Center(child: Text(level, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isSelected ? (level == 'Easy' ? Colors.green : (level == 'Medium' ? Colors.orange : Colors.red)) : Colors.grey.shade600))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageUploadBox() {
    ImageProvider? imageProvider;
    if (_newImageFile != null) imageProvider = FileImage(_newImageFile!);
    else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) imageProvider = NetworkImage(_existingImageUrl!);

    return CustomPaint(
      painter: DashedRectPainter(color: _dashedBorderColor, strokeWidth: 1.5, gap: 6, radius: 12),
      child: Container(
        height: 20.h,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) setState(() => _newImageFile = File(image.path));
          },
          child: imageProvider != null
              ? Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image(image: imageProvider!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)), Positioned(top: 8, right: 8, child: InkWell(onTap: () => setState(() { _newImageFile = null; _existingImageUrl = null; }), child: const CircleAvatar(backgroundColor: Colors.white, radius: 16, child: Icon(Icons.close, size: 20, color: Colors.red))))])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_rounded, size: 32.sp, color: Colors.grey.shade600), SizedBox(height: 1.h), Text("Tap to change image", style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700))]),
        ),
      ),
    );
  }

  Widget _buildMaterialsWrap() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _materials.map((material) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(color: _lightBlue, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(material, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _primaryBlue)), SizedBox(width: 1.w), InkWell(onTap: () => setState(() => _materials.remove(material)), child: Icon(Icons.close, size: 18.sp, color: _primaryBlue.withOpacity(0.7)))]),
        );
      }).toList(),
    );
  }

  Widget _buildStepsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _steps.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderGrey)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 15.sp, backgroundColor: _primaryBlue, child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              SizedBox(width: 3.w),
              Expanded(child: Text(_steps[index], style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500, color: _textDark))),
              InkWell(onTap: () => setState(() => _steps.removeAt(index)), child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashedAddButton({required String label, required VoidCallback onTap}) {
    return CustomPaint(
      painter: DashedRectPainter(color: _dashedBorderColor, strokeWidth: 1.5, gap: 5, radius: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 1.5.h), alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle, color: _primaryBlue, size: 20.sp), SizedBox(width: 2.w), Text(label, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: _primaryBlue))])),
      ),
    );
  }

  Widget _buildFooterButtons(bool isLoading) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 7.5.h,
          child: ElevatedButton(
            onPressed: isLoading ? null : _updateChallenge,
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
            child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("Update Challenge", style: GoogleFonts.poppins(fontSize: 17.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        SizedBox(height: 2.h),
        TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
      ],
    );
  }

  void _showAddMaterialDialog() {
    _materialController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Material", style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: TextField(controller: _materialController, style: const TextStyle(fontSize: 16), decoration: const InputDecoration(hintText: "e.g. 2 AA Batteries")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { if (_materialController.text.isNotEmpty) { setState(() => _materials.add(_materialController.text)); Navigator.pop(ctx); } }, child: const Text("Add")),
        ],
      ),
    );
  }

  void _showAddStepDialog() {
    TextEditingController stepCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Instruction Step", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: TextField(controller: stepCtrl, maxLines: 3, style: const TextStyle(fontSize: 16), decoration: const InputDecoration(hintText: "Describe the step...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { if (stepCtrl.text.isNotEmpty) { setState(() => _steps.add(stepCtrl.text)); Navigator.pop(ctx); } }, child: const Text("Add")),
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
  DashedRectPainter({this.strokeWidth = 1.0, this.color = Colors.red, this.gap = 5.0, this.radius = 0});
  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + 5), dashedPaint);
        distance += 5 + gap;
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
