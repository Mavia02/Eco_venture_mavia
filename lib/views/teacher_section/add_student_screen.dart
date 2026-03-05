import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../viewmodels/teacher_auth/teacher_auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- UPDATED: Individual Year Selection ---
  String? _selectedYear;
  final List<String> _individualYears = ["6", "7", "8", "9", "10", "11", "12"];

  // --- PRO COLORS ---
  final Color _primary = const Color(0xFF1565C0); // Teacher Blue
  final Color _bg = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _textGrey = const Color(0xFFA3AED0);
  final Color _surface = Colors.white;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _registerStudent() async {
    // 1. Validation including Age selection
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select the student's age"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Perform Mapping: Year -> Class Range
    String mappedAgeGroup = _mapYearToClass(_selectedYear!);

    // 3. Call ViewModel with the Mapped Age Group
    await ref
        .read(teacherAuthViewModelProvider.notifier)
        .addStudent(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      ageGroup: mappedAgeGroup, // Pass the category string to backend
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(teacherAuthViewModelProvider);

    ref.listen(teacherAuthViewModelProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${next.errorMessage}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Student Registered Successfully! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(teacherAuthViewModelProvider.notifier).resetState();
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "New Student",
          style: GoogleFonts.poppins(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, const Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Student Registration",
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          "Select the student's exact age.",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Full Name"),
                  SizedBox(height: 1.5.h),
                  _buildTextField(
                    controller: _nameController,
                    hint: "e.g. Ali Khan",
                    icon: Icons.badge_outlined,
                  ),
                  SizedBox(height: 3.h),

                  _buildLabel("Age (Years)"),
                  SizedBox(height: 1.5.h),
                  _buildAgeDropdown(),
                  SizedBox(height: 3.h),

                  _buildLabel("Email Address"),
                  SizedBox(height: 1.5.h),
                  _buildTextField(
                    controller: _emailController,
                    hint: "student@school.com",
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: 3.h),

                  _buildLabel("Password"),
                  SizedBox(height: 1.5.h),
                  _buildTextField(
                    controller: _passwordController,
                    hint: "••••••••",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 5.h),

            SizedBox(
              width: double.infinity,
              height: 7.5.h,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _registerStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  elevation: 8,
                  shadowColor: _primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Register Student",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    );
  }

  Widget _buildAgeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedYear,
          hint: Text(
            "Select Age",
            style: GoogleFonts.poppins(color: _textGrey, fontSize: 14.sp),
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          items: _individualYears.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                "$value Years Old",
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedYear = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _textGrey, size: 20.sp),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: _textGrey, fontSize: 14.sp),
        filled: true,
        fillColor: _bg,
        contentPadding: EdgeInsets.symmetric(vertical: 2.2.h),
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
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}
