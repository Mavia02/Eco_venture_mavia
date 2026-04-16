import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/child_report_model.dart';
import '../../../viewmodels/child_view_model/report_safety/child_safety_provider.dart';
import '../../../services/shared_preferences_helper.dart';

class ChildSafetyDashboard extends ConsumerStatefulWidget {
  const ChildSafetyDashboard({super.key});

  @override
  ConsumerState<ChildSafetyDashboard> createState() =>
      _ChildSafetyDashboardState();
}

class _ChildSafetyDashboardState extends ConsumerState<ChildSafetyDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Logic: Load reports into state on init
    Future.microtask(
          () => ref.read(childReportViewModelProvider.notifier).loadReports(),
    );

    // Logic: Pulse controller for the Report Button movement
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(childReportViewModelProvider);
    final reports = reportState.reports;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Logic: Professional background glow effects preserved
          Positioned(top: -100, right: -100, child: _buildGlowCircle(Colors.blue, 300)),
          Positioned(bottom: -100, left: -100, child: _buildGlowCircle(Colors.purple, 300)),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- NEW CLEAN HEADER ---
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        "Report Hub", // UPDATED: Renamed for the new purpose
                        style: GoogleFonts.fredoka(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // Logic: Removed the circle and icon to clean up the UI
                  SizedBox(height: 6.h),

                  // --- ENHANCED REPORT BUTTON (Main Focus) ---
                  _buildEnhancedReportButton(context),

                  SizedBox(height: 5.h),

                  Text(
                    "Recent Activity",
                    style: GoogleFonts.fredoka(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // --- REPORTS LIST (Logic Preserved) ---
                  Expanded(
                    child: reportState.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                        : reports.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, color: Colors.white24, size: 30.sp),
                          SizedBox(height: 1.5.h),
                          Text(
                            "No reports yet.\nYou're doing great!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (c, i) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        return _buildReportCard(reports[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedReportButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('childReportIssueScreen'),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDD2476).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                // Internal pulse visual effect
                BoxShadow(
                  color: Colors.white.withOpacity(0.1 * _pulseController.value),
                  blurRadius: 10 * _pulseController.value,
                  spreadRadius: 2 * _pulseController.value,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.12), // Subtle pulse on icon
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report an Issue",
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Is something wrong? Tell us.",
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(ChildReportModel report) {
    bool isResolved = report.status == 'Resolved';
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isResolved ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_rounded,
              color: isResolved ? Colors.greenAccent : Colors.orangeAccent,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.contentTitle ?? report.issueType,
                  style: GoogleFonts.poppins(fontSize: 14.5.sp, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Text(
                  "To: ${report.recipient} • ${timeago.format(report.timestamp)}",
                  style: GoogleFonts.poppins(fontSize: 11.5.sp, color: Colors.white54),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
            decoration: BoxDecoration(
              color: isResolved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              report.status,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: isResolved ? Colors.greenAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 100, spreadRadius: 20),
        ],
      ),
    );
  }
}
