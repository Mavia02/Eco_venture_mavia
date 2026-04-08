import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../viewmodels/parent_section/report_safety/parent_safety_provider.dart';

// --- LIVE USAGE STREAM LOGIC ---
final childUsageStreamProvider = StreamProvider.autoDispose.family<int, String>((ref, childId) {
  return FirebaseDatabase.instance
      .ref('child_usage_stats/$childId/daily')
      .onValue
      .map((event) {
    return (event.snapshot.value as int?) ?? 0;
  });
});

class ParentReportSafetyScreen extends ConsumerStatefulWidget {
  const ParentReportSafetyScreen({super.key});

  @override
  ConsumerState<ParentReportSafetyScreen> createState() => _ParentReportSafetyScreenState();
}

class _ParentReportSafetyScreenState extends ConsumerState<ParentReportSafetyScreen> {
  // Design Tokens - Matching Home Screen Aesthetic
  final Color _primary = const Color(0xFF1E88E5);
  final Color _bgSubtle = const Color(0xFFF8FAFC);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textGrey = const Color(0xFF64748B);
  final Color _cardBorder = const Color(0xFFE2E8F0);
  final Color _alertRed = const Color(0xFFEF4444);
  final Color _warningAmber = const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    // Watch ViewModel State
    final state = ref.watch(parentSafetyViewModelProvider);
    final settings = state.settings;
    final allAlerts = state.alerts;

    final String childName = _getChildName(state.selectedChildId, state.linkedChildren);
    final String timeLimitStr = _formatHours(settings.dailyLimitHours);

    // Watch Live Firebase Stream
    final AsyncValue<int> usageAsync = state.selectedChildId != null
        ? ref.watch(childUsageStreamProvider(state.selectedChildId!))
        : const AsyncData(0);

    return Scaffold(
      backgroundColor: _bgSubtle,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
            "Safety Console",
            style: GoogleFonts.poppins(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18.sp)
        ),
      ),
      body: Column(
        children: [
          // --- TOP REPORT CARD SECTION ---
          Padding(
            padding: EdgeInsets.all(5.w),
            child: usageAsync.when(
              data: (usedMinutes) {
                double limitMinutes = settings.dailyLimitHours * 60;
                double progress = limitMinutes > 0 ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;
                return _buildPremiumSummaryCard(
                    childName,
                    _formatMinutes(usedMinutes),
                    timeLimitStr,
                    progress,
                    settings.isAppPaused
                );
              },
              loading: () => _buildPremiumSummaryCard(childName, "...", timeLimitStr, 0.0, settings.isAppPaused),
              error: (_,__) => _buildPremiumSummaryCard(childName, "0m", timeLimitStr, 0.0, settings.isAppPaused),
            ),
          ),

          // --- DEDICATED SECURITY FEED SECTION ---
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Reports and Alerts",
                          style: GoogleFonts.poppins(fontSize: 17.sp, fontWeight: FontWeight.w700, color: _textDark)
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.6.h),
                        decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            "${allAlerts.length} Events",
                            style: GoogleFonts.poppins(fontSize: 11.sp, color: _primary, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.5.h),

                  Expanded(
                    child: allAlerts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: allAlerts.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumAlertTile(allAlerts[index]);
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

  // --- LOGIC HELPERS ---

  String _getChildName(String? id, List<Map<String, dynamic>> children) {
    if (id == null) return "Child";
    final child = children.firstWhere((c) => c['uid'] == id, orElse: () => {});
    return child['name'] ?? "Child";
  }

  String _formatHours(double value) {
    int hours = value.floor();
    int minutes = ((value - hours) * 60).round();
    return minutes == 0 ? "${hours}h" : "${hours}h ${minutes}m";
  }

  String _formatMinutes(int totalMinutes) {
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    return h == 0 ? "${m}m" : "${h}h ${m}m";
  }

  // --- UI WIDGETS ---

  Widget _buildPremiumSummaryCard(String name, String used, String limit, double progress, bool isPaused) {
    return Container(
      padding: EdgeInsets.all(5.5.w),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [const Color(0xFF1E293B), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: CircleAvatar(radius: 20.sp, backgroundColor: Colors.white10, child: Icon(Icons.security_rounded, color: Colors.white, size: 22.sp))
            ),
            SizedBox(width: 3.5.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17.sp)),
              Text(isPaused ? "Paused" : "Live Protection", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.w500))
            ])
          ]),
          Icon(Icons.auto_graph_rounded, color: Colors.white.withOpacity(0.5), size: 22.sp)
        ]),
        SizedBox(height: 3.5.h),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Playtime Utilization", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.sp)),
          RichText(text: TextSpan(children: [
            TextSpan(text: used, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.sp)),
            TextSpan(text: " / $limit", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11.sp))
          ]))
        ]),
        SizedBox(height: 1.5.h),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 1.h, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
      ]),
    );
  }

  Widget _buildPremiumAlertTile(dynamic alert) {
    final bool isCritical = alert.severity == 'High' || alert.status == 'Pending';
    final Color statusColor = isCritical ? _alertRed : _warningAmber;

    return Container(
      margin: EdgeInsets.only(bottom: 2.2.h),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(
                isCritical ? Icons.emergency_share_rounded : Icons.info_rounded,
                color: statusColor, size: 20.sp
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        alert.title ?? "System Alert",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15.sp, color: _textDark)
                    ),
                    Text(
                        timeago.format(alert.timestamp),
                        style: GoogleFonts.poppins(fontSize: 10.sp, color: _textGrey, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
                SizedBox(height: 0.6.h),
                Text(
                    alert.description ?? "Safety check complete.",
                    style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey, height: 1.4)
                ),
                // --- INTERACTIVE SECTION REMOVED TO PREVENT COMPILE ERROR ---
                // To restore this, the method 'resolveAlert' must be added to ParentSafetyViewModel
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(color: _bgSubtle, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_rounded, size: 35.sp, color: _textGrey.withOpacity(0.3)),
          ),
          SizedBox(height: 2.h),
          Text(
              "Reports and Alerts Log is Clear",
              style: GoogleFonts.poppins(color: _textDark, fontSize: 15.sp, fontWeight: FontWeight.w600)
          ),
          SizedBox(height: 0.5.h),
          Text(
              "We haven't detected any unusual activity.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _textGrey, fontSize: 11.sp)
          ),
        ],
      ),
    );
  }
}