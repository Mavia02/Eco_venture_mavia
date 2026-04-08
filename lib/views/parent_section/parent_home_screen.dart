import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../viewmodels/parent_section/parent_home/parent_home_provider.dart';
import '../../viewmodels/parent_section/report_safety/parent_safety_provider.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen>
    with SingleTickerProviderStateMixin {

  // --- DESIGN TOKENS ---
  final Color _primaryDark = const Color(0xFF1E293B);
  final Color _accentBlue = const Color(0xFF3B82F6);
  final Color _bgSubtle = const Color(0xFFF8FAFC);
  final Color _cardBorder = const Color(0xFFE2E8F0);
  final Color _textMain = const Color(0xFF0F172A);
  final Color _textMuted = const Color(0xFF64748B);
  final Color _purple = const Color(0xFF7B1FA2);
  final Color _green = const Color(0xFF00C853);

  final List<Color> _skillColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    NotificationService().initNotifications();

    Future.microtask(() =>
        ref.read(parentSafetyViewModelProvider.notifier).fetchLinkedChildren()
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // --- LOGIC: REQUEST TEACHER REPORT ---
  Future<void> _requestTeacherReport(BuildContext context, WidgetRef ref) async {
    final childId = ref.read(parentSafetyViewModelProvider).selectedChildId;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select a child first!"), backgroundColor: Colors.red)
      );
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request sent to Teacher!"), backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send request"), backgroundColor: Colors.red)
      );
    }
  }

  // --- LOGIC: BATCH LINKING DIALOG ---
  void _showLinkChildDialog() {
    List<Map<String, TextEditingController>> entries = [
      {'name': TextEditingController(), 'email': TextEditingController()}
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Link New Child",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18.sp, color: _textMain)),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 50.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Enter child details to link accounts.",
                        style: GoogleFonts.poppins(fontSize: 13.sp, color: _textMuted)),
                    SizedBox(height: 2.h),
                    ...entries.asMap().entries.map((entry) {
                      int index = entry.key;
                      var controllers = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                            color: _bgSubtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder)
                        ),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text("Child ${index + 1}",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _accentBlue)),
                              if (entries.length > 1)
                                InkWell(
                                    onTap: () => setDialogState(() => entries.removeAt(index)),
                                    child: Icon(Icons.close, color: Colors.red, size: 18.sp)
                                )
                            ]),
                            SizedBox(height: 1.h),
                            TextField(
                                controller: controllers['name'],
                                decoration: InputDecoration(
                                    hintText: "Name", filled: true, fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                                )
                            ),
                            SizedBox(height: 1.h),
                            TextField(
                                controller: controllers['email'],
                                decoration: InputDecoration(
                                    hintText: "Email", filled: true, fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                                )
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                        onPressed: () => setDialogState(() => entries.add({'name': TextEditingController(), 'email': TextEditingController()})),
                        icon: const Icon(Icons.add_circle_outline), label: Text("Add Another Profile", style: GoogleFonts.poppins())
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: _textMuted))),
              ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); _processBatchLinking(entries); },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h)
                  ),
                  child: Text("Link Now", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _processBatchLinking(List<Map<String, TextEditingController>> entries) async {
    int success = 0;
    for (var entry in entries) {
      String name = entry['name']!.text.trim();
      String email = entry['email']!.text.trim();
      if (name.isNotEmpty && email.isNotEmpty) {
        try {
          await ref.read(parentSafetyViewModelProvider.notifier).linkChildByEmail(email, name);
          success++;
        } catch (e) { /* Error handled in provider */ }
      }
    }
    if (success > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Linked $success children!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(parentDashboardStreamProvider);
    final safetyState = ref.watch(parentSafetyViewModelProvider);
    final children = safetyState.linkedChildren;

    if (children.isNotEmpty && safetyState.selectedChildId == null) {
      Future.microtask(() {
        ref.read(parentSafetyViewModelProvider.notifier).selectChild(children.first['uid']);
      });
    }

    return Scaffold(
      backgroundColor: _bgSubtle,
      body: dashboardAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _primaryDark)),
        error: (err, stack) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(children, safetyState.selectedChildId),
            const Spacer(),
            Text("Select a child to view progress", style: GoogleFonts.poppins(color: _textMuted)),
            const Spacer(),
          ],
        )),
        data: (data) {
          final int usageMinutes = data['usageMinutes'] ?? 0;
          final List activityList = data['recentActivity'] ?? [];
          final Map<String, double> skills = data['skills'] != null
              ? Map<String, double>.from(data['skills'])
              : {'Science': 0.1, 'Math': 0.1, 'Creativity': 0.1, 'Logic': 0.1};

          final Map<String, dynamic> performance = data['performance'] ??
              {'quizAvg': 0, 'stemCount': 0, 'qrCount': 0};

          return Stack(
            children: [
              Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryDark.withOpacity(0.03)))),
              Positioned(top: 100, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: _purple.withOpacity(0.03)))),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildHeader(children, safetyState.selectedChildId),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Skill Growth",
                                  style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textMain)),
                              SizedBox(height: 1.5.h),
                              _buildSkillGrowthCard(skills),
                              SizedBox(height: 3.h),

                              Text("Performance Breakdown",
                                  style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textMain)),
                              SizedBox(height: 1.5.h),
                              Row(
                                children: [
                                  Expanded(child: _buildPerformanceCard("Quiz", "${performance['quizAvg']}%", "Avg. Score", Icons.quiz, [const Color(0xFF6366F1), const Color(0xFF8B5CF6)])),
                                  SizedBox(width: 3.w),
                                  Expanded(child: _buildPerformanceCard("STEM", "${performance['stemCount']}", "Projects", Icons.science, [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)])),
                                  SizedBox(width: 3.w),
                                  Expanded(child: _buildPerformanceCard("QR Hunt", "${performance['qrCount']}", "Solved", Icons.qr_code_scanner, [const Color(0xFF10B981), const Color(0xFF059669)])),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              _buildScreenTimeCard(usageMinutes),
                              SizedBox(height: 3.h),

                              // --- UPDATED PARENT CONTROLS SECTION ---
                              Text("Parent Controls",
                                  style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textMain)),
                              SizedBox(height: 1.5.h),
                              _buildUnifiedControls(context),

                              SizedBox(height: 3.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Recent Activity",
                                      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _textMain)),
                                  Text("View All",
                                      style: GoogleFonts.poppins(fontSize: 12.sp, color: _accentBlue, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              if (activityList.isEmpty) _buildEmptyState()
                              else Column(children: activityList.map((item) => _buildActivityTile(item)).toList()),
                              SizedBox(height: 5.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UPDATED HEADER WITH ENLARGED HEADING AND ADD CHILD BUTTON ---
  Widget _buildHeader(List children, String? selectedId) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Parent\nDashboard",
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: _textMain,
                    letterSpacing: -0.5,
                  )
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showLinkChildDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: _primaryDark,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.white, size: 16.sp),
                          SizedBox(width: 1.5.w),
                          Text(
                              "Add Child",
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  _buildNotificationIcon(),
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (children.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(color: _bgSubtle, borderRadius: BorderRadius.circular(15), border: Border.all(color: _cardBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  hint: Text("Select Child Profile", style: GoogleFonts.poppins()),
                  icon: Icon(Icons.unfold_more_rounded, color: _textMuted),
                  items: children.map((child) {
                    return DropdownMenuItem<String>(
                      value: child['uid'],
                      child: Text(child['name'] ?? "Child", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _textMain)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) ref.read(parentSafetyViewModelProvider.notifier).selectChild(val);
                  },
                ),
              ),
            )
          else
            Text("No children linked. Tap (+) to start.", style: TextStyle(color: Colors.redAccent, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return InkWell(
      onTap: () => context.pushNamed('parentNotificationsScreen'),
      child: Stack(
        children: [
          Container(padding: EdgeInsets.all(2.5.w), decoration: BoxDecoration(color: _bgSubtle, shape: BoxShape.circle), child: Icon(Icons.notifications_none_rounded, color: _textMain, size: 20.sp)),
          Positioned(right: 0, top: 0, child: Container(width: 3.w, height: 3.w, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, String subtitle, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: EdgeInsets.all(2.w), decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 16.sp)),
          SizedBox(height: 1.5.h),
          Text(value, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.white70, fontWeight: FontWeight.w500)),
          Text(title, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(int minutes) {
    double hours = minutes / 60;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryDark, _accentBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Screen Time Today", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.sp)),
              Text("${hours.toStringAsFixed(1)} hrs", style: GoogleFonts.poppins(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Container(
                margin: EdgeInsets.only(top: 1.h),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: Text("Healthy Limits ✅", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.sp)),
              ),
            ],
          ),
          Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 24.sp),
        ],
      ),
    );
  }

  // --- UPDATED: TWO ELONGATED BEAUTIFUL BUTTONS (SCREEN TIME & CONTENT FILTERS) ---
  Widget _buildUnifiedControls(BuildContext context) {
    return Column(
      children: [
        _buildElongatedActionCard(
            "Screen Time Control",
            "Manage playtime limits & bedtime",
            Icons.timer_outlined,
            [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
                () => context.pushNamed('parentScreenTimeScreen')
        ),
        SizedBox(height: 2.h),
        _buildElongatedActionCard(
            "Content Filters",
            "Restrict apps & core module access",
            Icons.security_rounded,
            [const Color(0xFF10B981), const Color(0xFF065F46)],
                () => context.pushNamed('parentContentFiltersScreen')
        ),
      ],
    );
  }

  // NEW UI HELPER FOR ELONGATED BUTTONS
  Widget _buildElongatedActionCard(String title, String subtitle, IconData icon, List<Color> gradientColors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradientColors),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGrowthCard(Map<String, double> skills) {
    return Container(
      height: 38.h,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _cardBorder)),
      child: Row(
        children: [
          Expanded(flex: 3, child: CustomPaint(size: Size.infinite, painter: SkillPieChartPainter(skills: skills, colors: _skillColors))),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: skills.keys.toList().asMap().entries.map((entry) {
                int index = entry.key;
                String key = entry.value;
                double value = skills[key] ?? 0.0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: _skillColors[index % _skillColors.length], shape: BoxShape.circle)), SizedBox(width: 2.w), Text(key, style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _textMain))]),
                      Padding(padding: EdgeInsets.only(left: 12 + 2.w), child: Text("${(value * 100).toInt()}%", style: GoogleFonts.poppins(fontSize: 10.sp, color: _textMuted))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> item) {
    bool isVideo = item['type'] == 'Video';
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder)),
      child: Row(
        children: [
          Container(padding: EdgeInsets.all(2.5.w), decoration: BoxDecoration(color: (isVideo ? Colors.red : _accentBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isVideo ? Icons.play_arrow_rounded : Icons.book_rounded, color: isVideo ? Colors.red : _accentBlue, size: 16.sp)),
          SizedBox(width: 3.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: _textMain)),
            Text(timeago.format(DateTime.parse(item['timestamp'])), style: GoogleFonts.poppins(fontSize: 10.sp, color: _textMuted)),
          ])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: EdgeInsets.all(2.h), child: Text("No recent activity.", style: GoogleFonts.poppins(color: _textMuted))));
  }
}

class SkillPieChartPainter extends CustomPainter {
  final Map<String, double> skills;
  final List<Color> colors;
  SkillPieChartPainter({required this.skills, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) * 0.9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double total = skills.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;
    double startAngle = -math.pi / 2;
    int i = 0;
    skills.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      final paint = Paint()..color = colors[i % colors.length]..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle + 0.02, sweepAngle - 0.04, true, paint);
      startAngle += sweepAngle;
      i++;
    });
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, holePaint);
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.5, shadowPaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
