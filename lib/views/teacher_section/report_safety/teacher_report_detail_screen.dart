import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/teacher_report_model.dart';
import '../../../viewmodels/teacher_safety_report/teacher_safety_provider.dart';

class TeacherReportDetailScreen extends ConsumerWidget {
  final TeacherReportModel reportData;
  const TeacherReportDetailScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color _bg = const Color(0xFFF4F7FE);
    final Color _textDark = const Color(0xFF1B2559);
    final Color _primaryBlue = const Color(0xFF4E54C8);

    // Logic: Determine if this is a content-related alert or a generic one
    final bool isContentReport = reportData.contentId != null && reportData.contentId!.isNotEmpty;
    final bool isPending = reportData.status.toLowerCase().contains('pending');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
            "Report Details",
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp)
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
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
              ),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 22.sp,
                      backgroundColor: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
                      child: Icon(
                          isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                          color: isPending ? Colors.orange : Colors.green
                      )
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reportData.title, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textDark)),
                        Text("From: ${reportData.fromName}", style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // --- CONTEXT SECTION ---
            if (isContentReport) ...[
              _buildSectionLabel("Reported Item"),
              Container(
                margin: EdgeInsets.only(top: 1.h, bottom: 3.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.1))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.red),
                    SizedBox(width: 3.w),
                    Text("Content ID: ${reportData.contentId}", style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            // --- DESCRIPTION ---
            _buildSectionLabel("Message Content"),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100)
              ),
              child: Text(
                reportData.description.isEmpty ? "No additional details provided." : reportData.description,
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[800], height: 1.6),
              ),
            ),

            SizedBox(height: 6.h),

            // --- RESOLUTION ACTION ---
            if (isPending)
              SizedBox(
                width: double.infinity,
                height: 7.5.h,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                  label: Text(
                      "MARK AS RESOLVED",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)
                  ),
                  onPressed: () async {
                    // Logic: Now correctly calling the newly added ViewModel method
                    await ref.read(teacherSafetyViewModelProvider.notifier).markResolved(reportData.id, reportData.childId);
                    if (context.mounted) context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFFA3AED0))
    );
  }
}