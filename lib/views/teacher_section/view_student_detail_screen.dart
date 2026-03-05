import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../viewmodels/teacher_student_detail/teacher_student_detail_provider.dart';

class ViewStudentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> studentData;
  const ViewStudentDetailScreen({super.key, required this.studentData});
  @override
  ConsumerState<ViewStudentDetailScreen> createState() =>
      _ViewStudentDetailScreenState();
}

class _ViewStudentDetailScreenState
    extends ConsumerState<ViewStudentDetailScreen> {
  final Color _bg = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _primaryBlue = const Color(0xFF1565C0);

  // --- COLORS FOR STATUS & TYPES ---
  final Color _green = const Color(0xFF00C853);
  final Color _red = const Color(0xFFE53935);
  final Color _blue = const Color(0xFF2979FF);
  final Color _amber = const Color(0xFFFFAB00);
  final Color _purple = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    final String uid = widget.studentData['uid'];
    Future.microtask(
          () => ref
          .read(teacherStudentDetailViewModelProvider.notifier)
          .loadStudent(uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherStudentDetailViewModelProvider);
    final student = state.student;

    if (state.isLoading || student == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          "Student Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Banner
            _buildProfileBanner(
              student.name,
              student.email,
              student.currentLevel,
            ),
            SizedBox(height: 3.h),

            // 2. Stats Grid (XP, Quiz, STEM)
            _buildStatsGrid(
              student.totalXP,
              student.quizzesPassed,
              student.stemApproved,
              student.qrHuntsCompleted,
            ),
            SizedBox(height: 4.h),

            // --- SECTION: PARENT COMMUNICATION HUB ---
            // UPDATED: Renamed from Parent Liaison
            _buildSectionHeader("Parent Remarks", Icons.record_voice_over_outlined),
            SizedBox(height: 1.5.h),
            _buildElongatedContactButton(student.name, widget.studentData['uid']),

            SizedBox(height: 3.h),

            // --- REMARKS HISTORY SECTION ---
            _buildSectionHeader("Past Remarks", Icons.history_edu_rounded),
            SizedBox(height: 1.5.h),
            _buildRemarksHistoryList(student.recentActivity),

            SizedBox(height: 4.h),

            // 3. Activity History (Standard Learning Tasks)
            _buildSectionHeader("Learning Activity", Icons.history_rounded),
            SizedBox(height: 2.h),
            _buildLearningActivityList(student.recentActivity),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17.sp, color: _primaryBlue),
        SizedBox(width: 2.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: EdgeInsets.all(5.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13.sp),
        ),
      ),
    );
  }

  Widget _buildRemarksHistoryList(List<dynamic> activities) {
    final remarks = activities.where((a) => a['type'] == 'Remark').toList();

    if (remarks.isEmpty) {
      return _buildEmptyState("No remarks sent to family yet.");
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: remarks.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        final remark = remarks[index];
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      remark['subtitle'] ?? "General",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                    ),
                  ),
                  Text(
                    timeago.format(DateTime.parse(remark['time'])),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                remark['title'] ?? "No Title",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              if (remark['message'] != null) ...[
                SizedBox(height: 0.5.h),
                Text(
                  remark['message'],
                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLearningActivityList(List<dynamic> activities) {
    final learningActivities = activities.where((a) => a['type'] != 'Remark').toList();

    if (learningActivities.isEmpty) {
      return _buildEmptyState("No learning activity recorded yet.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: learningActivities.length,
      itemBuilder: (context, index) {
        return _buildActivityTile(learningActivities[index]);
      },
    );
  }

  Widget _buildElongatedContactButton(String studentName, String uid) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.pushNamed('teacherContactParentScreen', extra: {
            'type': 'Parent',
            'studentId': uid,
            'studentName': studentName,
          });
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(4.5.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryBlue, const Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Message Parent", // UPDATED: From Message Family
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      "Contact parents of $studentName regarding progress.",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(String name, String email, int level) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.sp,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 35.sp),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Level $level",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int xp, int quiz, int stem, int qr) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("XP", "$xp", Icons.star, _amber)),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            "Quiz",
            "$quiz",
            Icons.quiz,
            Colors.purpleAccent,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(child: _buildStatCard("STEM", "$stem", Icons.science, _blue)),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: _textDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final String title = activity['title'].toString();
    final bool isSubmission = activity['type'] == 'STEM';

    final String status = activity['subtitle']?.toString().toLowerCase() ?? '';
    final bool isPendingOrRejected = status.contains('pending') || status.contains('rejected');

    bool isPositive = activity['isPositive'] == true;
    Color statusColor = isPositive ? _green : _red;
    IconData icon = isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded;

    if (isSubmission) {
      if (status.contains('pending')) {
        statusColor = _amber;
        icon = Icons.hourglass_bottom_rounded;
      } else if (status.contains('approved')) {
        statusColor = _green;
        icon = Icons.check_circle_rounded;
      } else {
        statusColor = _blue;
        icon = Icons.assignment_ind_rounded;
      }
    }

    String subtitle = activity['subtitle'] ?? '';
    if (subtitle.isEmpty && activity['score'] != null) {
      subtitle = activity['score'];
    }

    return GestureDetector(
      onTap: (isSubmission && isPendingOrRejected)
          ? () {
        context.goNamed(
          'teacherStemApprovedScreen',
          extra: {
            'studentId': widget.studentData['uid'],
            'activity': activity,
          },
        );
      }
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 18.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          "${timeago.format(DateTime.parse(activity['time']))}"
                              "${subtitle.isNotEmpty ? ' • $subtitle' : ''}",
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSubmission)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}