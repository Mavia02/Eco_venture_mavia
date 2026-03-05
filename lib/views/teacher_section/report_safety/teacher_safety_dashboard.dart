import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/teacher_report_model.dart';
import '../../../viewmodels/teacher_safety_report/teacher_safety_provider.dart';
import '../../../viewmodels/teacher_safety_report/teacher_safety_state.dart';

class TeacherSafetyDashboard extends ConsumerStatefulWidget {
  const TeacherSafetyDashboard({super.key});

  @override
  ConsumerState<TeacherSafetyDashboard> createState() => _TeacherSafetyDashboardState();
}

class _TeacherSafetyDashboardState extends ConsumerState<TeacherSafetyDashboard> {
  // --- PREMIUM UI THEME ---
  final Color _primaryBlue = const Color(0xFF4E54C8);
  final Color _bg = const Color(0xFFF8FAFF);
  final Color _textDark = const Color(0xFF1B2559);
  final Color _textGrey = const Color(0xFFA3AED0);
  final Color _accentGreen = const Color(0xFF11998e);
  final Color _accentOrange = const Color(0xFFF2994A);

  @override
  void initState() {
    super.initState();
    // Logic: Controlled single-point fetch.
    // ViewModel no longer auto-fetches in constructor, preventing the double-call error.
    Future.microtask(() {
      if (FirebaseAuth.instance.currentUser != null) {
        ref.read(teacherSafetyViewModelProvider.notifier).fetchReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // WATCH: State automatically updates because the ViewModel listens to a Stream
    final state = ref.watch(teacherSafetyViewModelProvider);
    final List<TeacherReportModel> alerts = state.alerts;

    // Logic: Robust status counting for the UI cards (Handles case variations)
    final pendingCount = alerts.where((a) => a.status.toLowerCase().contains('pending')).length;
    final resolvedCount = alerts.where((a) => a.status.toLowerCase().contains('resolved')).length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(state, alerts, pendingCount, resolvedCount),
          ),
        ],
      ),
    );
  }

  /// FIXED: Added explicit type 'TeacherSafetyState state' to resolve compilation error
  Widget _buildContent(TeacherSafetyState state, List<TeacherReportModel> alerts, int pending, int resolved) {
    // 1. Initial Loading State (Show spinner only when list is empty)
    if (state.isLoading && alerts.isEmpty) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    }

    // 2. Error Display with Retry Logic (Helps debug why fetch failed)
    if (state.errorMessage != null && alerts.isEmpty) {
      return _buildErrorView(state.errorMessage!);
    }

    // 3. Main Communication List with Pull-to-Refresh
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(teacherSafetyViewModelProvider.notifier).fetchReports();
        } catch (e) {
          debugPrint("Refresh Error: $e");
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Communication Status", Icons.analytics_outlined),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "$pending",
                    "Pending",
                    [const Color(0xFFFF9D6C), const Color(0xFFBB4E75)],
                    Icons.hourglass_empty_rounded,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildStatCard(
                    "$resolved",
                    "Resolved",
                    [_accentGreen, const Color(0xFF00CDAC)],
                    Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("Incoming Messages", Icons.mail_outline_rounded),
                if (pending > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$pending New",
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            if (alerts.isEmpty)
              _buildEmptyState()
            else
              _buildList(alerts),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red, size: 30.sp),
          SizedBox(height: 1.h),
          Text("Connection Failed", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          SizedBox(height: 2.h),
          TextButton.icon(
            onPressed: () => ref.read(teacherSafetyViewModelProvider.notifier).fetchReports(),
            icon: const Icon(Icons.refresh),
            label: const Text("Retry Connection"),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TeacherReportModel> alerts) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      separatorBuilder: (c, i) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) => _buildInboxTile(alerts[index]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: 100.w,
      padding: EdgeInsets.fromLTRB(5.w, 7.h, 5.w, 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, const Color(0xFF8F94FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Communication Hub",
                  style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "Inbox for student alerts and parent reports",
                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18.sp, color: _primaryBlue),
        ),
        SizedBox(width: 3.w),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 17.sp, fontWeight: FontWeight.bold, color: _textDark),
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, List<Color> colors, IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 2.h),
          Text(
            count,
            style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTile(TeacherReportModel alert) {
    final bool isPending = alert.status.toLowerCase().contains('pending');

    return GestureDetector(
      onTap: () => context.pushNamed('teacherReportDetailScreen', extra: alert),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (isPending ? _accentOrange : _accentGreen).withOpacity(0.12),
              child: Icon(
                isPending ? Icons.notification_important_rounded : Icons.verified_rounded,
                color: isPending ? _accentOrange : _accentGreen,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15.sp, color: _textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    "${alert.fromName} • ${timeago.format(alert.timestamp)}",
                    style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          children: [
            Icon(Icons.mail_outline_rounded, size: 40.sp, color: Colors.grey[300]),
            SizedBox(height: 2.h),
            Text(
              "Your inbox is clear!",
              style: GoogleFonts.poppins(color: _textGrey, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              "No new alerts or parent messages.",
              style: GoogleFonts.poppins(color: _textGrey.withOpacity(0.7), fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}