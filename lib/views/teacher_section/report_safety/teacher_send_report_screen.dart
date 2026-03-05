import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import '../../../viewmodels/teacher_safety_report/teacher_safety_provider.dart';

class TeacherSendReportScreen extends ConsumerStatefulWidget {
  /// Logic: Accepts 'extra' map from context.pushNamed in the Detail Screen
  /// Expected keys: 'studentId', 'studentName', 'type'
  final Map<String, dynamic> extra;
  const TeacherSendReportScreen({super.key, required this.extra});

  @override
  ConsumerState<TeacherSendReportScreen> createState() =>
      _TeacherSendReportScreenState();
}

class _TeacherSendReportScreenState
    extends ConsumerState<TeacherSendReportScreen> {
  String _selectedType = 'Behavior Remark';
  String? _studentId;
  String? _studentName;

  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();

  final List<String> _types = [
    'Behavior Remark',
    'Progress Update',
    'Urgent Issue',
  ];
  final List<String> _bugTypes = [
    'App Crash',
    'Feature Request',
    'Content Error',
  ];

  final Color _primaryBlue = const Color(0xFF1565C0);
  final Color _bg = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1B2559);

  @override
  void initState() {
    super.initState();
    // Logic: Automatically extract specific student details passed from the Profile button
    _studentId = widget.extra['studentId'];
    _studentName = widget.extra['studentName'];

    // Default selection based on route type (Admin support vs Parent Remark)
    if (widget.extra['type'] == 'Admin') {
      _selectedType = 'App Crash';
    } else {
      _selectedType = 'Behavior Remark';
    }
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title and message")),
      );
      return;
    }

    final isAdmin = widget.extra['type'] == 'Admin';

    if (isAdmin) {
      await ref
          .read(teacherSafetyViewModelProvider.notifier)
          .sendAdminReport(_titleCtrl.text, _messageCtrl.text, _selectedType);
    } else {
      if (_studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No recipient identified")),
        );
        return;
      }

      await ref
          .read(teacherSafetyViewModelProvider.notifier)
          .sendParentMessage(
        _studentId!,
        _titleCtrl.text,
        _messageCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherSafetyViewModelProvider);
    bool isAdmin = widget.extra['type'] == 'Admin';
    List<String> options = isAdmin ? _bugTypes : _types;

    ref.listen(teacherSafetyViewModelProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message Sent Successfully!"), backgroundColor: Colors.green),
        );
        ref.read(teacherSafetyViewModelProvider.notifier).resetSuccess();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          isAdmin ? "Contact Admin" : "Message Parent",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- RECIPIENT CARD (DROPDOWN REPLACED) ---
            if (!isAdmin) ...[
              _buildLabel("Selected Explorer"),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.sp,
                      backgroundColor: _primaryBlue.withOpacity(0.1),
                      child: Icon(Icons.person_rounded, color: _primaryBlue, size: 22.sp),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _studentName ?? "Student",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: _textDark,
                            ),
                          ),
                          Text(
                            "Verified Student Account",
                            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.verified_user_rounded, color: Colors.green, size: 18.sp),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
            ],

            _buildLabel("Subject / Type"),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: options.map((type) => _buildChoiceChip(type)).toList(),
            ),

            SizedBox(height: 3.5.h),
            _buildLabel("Title"),
            _buildTextField(_titleCtrl, "Give this report a short title...", 1),

            SizedBox(height: 3.5.h),
            _buildLabel("Message Details"),
            _buildTextField(_messageCtrl, "Write the details of your message here...", 6),

            SizedBox(height: 5.h),

            // --- PREMIUM ACTION BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 7.5.h,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
                  shadowColor: _primaryBlue.withOpacity(0.4),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isAdmin ? "SUBMIT TO ADMIN" : "SEND MESSAGE",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h, left: 1.w),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String type) {
    final bool isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedType = type),
      selectedColor: _primaryBlue.withOpacity(0.15),
      backgroundColor: Colors.white,
      pressElevation: 0,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? _primaryBlue : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13.sp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? _primaryBlue : Colors.grey.shade200, width: 1.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, int lines) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        style: GoogleFonts.poppins(fontSize: 14.5.sp, color: _textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5.sp),
          contentPadding: EdgeInsets.all(4.5.w),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }
}
