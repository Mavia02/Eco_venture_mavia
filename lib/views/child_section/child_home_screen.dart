import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../services/shared_preferences_helper.dart';
import '../child_section/widgets/click_able_info_card.dart';

// Logic: Correct import paths
import '../../viewmodels/child_view_model/profile/user_provider.dart';
import '../../../viewmodels/child_view_model/report_safety/child_safety_provider.dart';

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen>
    with TickerProviderStateMixin {
  String username = "Explorer";

  late final AnimationController _mainController;
  late final AnimationController _bgController;
  late final AnimationController _floatController;
  late final AnimationController _headerPulseController;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredModules = [];

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'QR Treasure',
      'icon': Icons.qr_code_scanner_rounded,
      'color1': const Color(0xFF2E7D32),
      'color2': const Color(0xFF81C784),
      'route': 'treasureHunt',
      'imageUrl': 'https://images.unsplash.com/photo-1620423855978-e5d74a7bef30?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'STEM Tasks',
      'icon': Icons.science_rounded,
      'color1': const Color(0xFF0277BD),
      'color2': const Color(0xFF4FC3F7),
      'route': 'stemChallenges',
      'imageUrl': 'https://images.unsplash.com/photo-1634872583967-6417a8638a59?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Nature Journal',
      'icon': Icons.camera_alt_rounded,
      'color1': const Color(0xFFEF6C00),
      'color2': const Color(0xFFFFB74D),
      'route': 'naturePhotoJournal',
      'imageUrl': 'https://images.unsplash.com/photo-1579535984712-92fffbbaa266?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Eco Quiz',
      'icon': Icons.lightbulb_rounded,
      'color1': const Color(0xFF6A1B9A),
      'color2': const Color(0xFFBA68C8),
      'route': 'interactiveQuiz',
      'imageUrl': 'https://raw.githubusercontent.com/encharm/Font-Awesome-SVG-PNG/master/black/png/256/question.png',
    },
    {
      'title': 'Multimedia',
      'icon': Icons.play_circle_fill_rounded,
      'color1': const Color(0xFFC62828),
      'color2': const Color(0xFFEF9A9A),
      'route': 'multiMediaContent',
      'imageUrl': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _initTeacherLookup();

    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _headerPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _filteredModules = List.from(_modules);
  }

  Future<void> _initTeacherLookup() async {
    final uid = await SharedPreferencesHelper.instance.getUserId();
    if (uid != null) {
      ref.read(userProfileProvider.notifier).fetchUserProfile(uid);
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return "0m";
    int h = minutes ~/ 60;
    int m = minutes % 60;
    return h > 0 ? "${h}h ${m}m" : "${m}m";
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredModules = List.from(_modules);
      } else {
        _filteredModules = _modules.where((module) => module['title'].toString().toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bgController.dispose();
    _floatController.dispose();
    _headerPulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final name = await SharedPreferencesHelper.instance.getUserName();
    if (!mounted) return;
    setState(() => username = name ?? "Explorer");
  }

  // --- UI WRAPPERS ---

  Widget _floatingWrapper({required Widget child, double offsetValue = -12.0}) {
    final offset = Tween<double>(begin: 0, end: offsetValue).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine));
    return AnimatedBuilder(animation: _floatController, builder: (context, _) => Transform.translate(offset: Offset(0, offset.value), child: child));
  }

  Widget _animatedEntry({required int index, required Widget child}) {
    final fade = CurvedAnimation(parent: _mainController, curve: Interval(0.05 * index, 1, curve: Curves.easeInOut));
    final slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _mainController, curve: Interval(0.05 * index, 0.8, curve: Curves.easeOutCubic)));
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  Widget _professionalCard({required Widget child, Color? borderColor, double borderWidth = 2.0}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFDFD), Color(0xFFF1F3F5)], // Pearl-Slate Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor ?? Colors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD1D9E6), offset: const Offset(5, 10), blurRadius: 18),
          const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 12),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(30), child: child),
    );
  }

  Widget _buildAnimatedBackground({required Widget child}) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final color1 = Color.lerp(const Color(0xFFE8F6F3), const Color(0xFFF4F8FB), _bgController.value)!;
        final color2 = Color.lerp(const Color(0xFFFBFCFD), const Color(0xFFFDF7E6), _bgController.value)!;
        return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: child);
      },
    );
  }

  // --- SCREEN TIME CAPSULE (MATCHES HOME UI) ---
  Widget _buildTimeLimitCapsule() {
    final settingsAsync = ref.watch(childSafetySettingsProvider);
    final usageAsync = ref.watch(childUsageProvider);

    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) {
        // If limit is unset (24h), hide capsule
        if (settings.dailyLimitHours >= 24.0) return const SizedBox.shrink();

        return usageAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (usedMinutes) {
            final int totalLimitMinutes = (settings.dailyLimitHours * 60).round();
            int remaining = totalLimitMinutes - usedMinutes;
            if (remaining < 0) remaining = 0;
            final double progress = totalLimitMinutes == 0 ? 0.0 : (remaining / totalLimitMinutes).clamp(0.0, 1.0);

            Color statusColor = const Color(0xFF00E5FF); // Premium Cyan
            if (settings.isAppPaused) statusColor = Colors.redAccent;
            else if (remaining <= 0) statusColor = Colors.orangeAccent;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              child: _floatingWrapper(
                offsetValue: -5,
                child: _professionalCard(
                  borderWidth: 1.5,
                  borderColor: statusColor.withOpacity(0.4),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _headerPulseController,
                          builder: (context, _) => Icon(
                            settings.isAppPaused ? Icons.pause_circle_filled : Icons.timer_rounded,
                            color: statusColor,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    settings.isAppPaused ? "App Paused" : "Play Time Remaining",
                                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, color: const Color(0xFF455A64), fontSize: 14.5.sp),
                                  ),
                                  Text(
                                    settings.isAppPaused ? "Paused" : _formatMinutes(remaining),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14.sp),
                                  ),
                                ],
                              ),
                              SizedBox(height: 0.8.h),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFECEFF1),
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    final profileState = ref.watch(userProfileProvider);
    final String studentDisplayName = profileState.userProfile?['full_name'] ?? profileState.userProfile?['name'] ?? profileState.userProfile?['displayName'] ?? username;
    final String teacherName = profileState.teacherName ?? "Classroom";

    return Container(
      padding: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(38), bottomRight: Radius.circular(38))),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(38), bottomRight: Radius.circular(38)),
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final scale = 1.04 + (_bgController.value * 0.03);
                return Transform.scale(scale: scale, child: Container(height: 30.h, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/child-Back-image.jpeg"), fit: BoxFit.cover))));
              },
            ),
          ),
          Container(height: 30.h, decoration: BoxDecoration(borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(38), bottomRight: Radius.circular(38)), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.78), Colors.black.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedEntry(
                  index: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _headerPulseController,
                            builder: (context, child) => Transform.scale(
                              scale: 1.0 + (_headerPulseController.value * 0.08),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))]),
                                child: Image.asset("assets/images/appLogo.png", height: 44, width: 44),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, $studentDisplayName 👋",
                                style: GoogleFonts.fredoka(color: Colors.white, fontSize: 21.5.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5, shadows: [const Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8)]),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 0.5.h),
                                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.3.h),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24, width: 1)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 1.5.w),
                                    Text("Teacher: $teacherName", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.8.sp, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed('childNotificationsScreen'),
                        child: AnimatedBuilder(
                          animation: _headerPulseController,
                          builder: (context, child) => Transform.rotate(
                            angle: (math.sin(_headerPulseController.value * math.pi * 2) * 0.1),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white30, width: 1.5)),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.5.h),
                _animatedEntry(index: 1, child: Text("Ready for today's\nbig adventure?", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: 0.2))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: _professionalCard(
        borderWidth: 3.0,
        borderColor: const Color(0xFF455A64).withOpacity(0.2),
        child: Container(
          height: 7.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.4)),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF455A64), size: 26),
              SizedBox(width: 3.w),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.poppins(color: const Color(0xFF263238), fontWeight: FontWeight.w500, fontSize: 16.5.sp),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search for activities...",
                    hintStyle: GoogleFonts.poppins(color: Colors.blueGrey.withOpacity(0.5), fontSize: 16.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Row(
        children: [
          Expanded(
            child: _floatingWrapper(
              offsetValue: -10,
              child: GestureDetector(
                onTap: () => context.goNamed("childProgressDashboardScreen"),
                child: _professionalCard(
                  borderColor: const Color(0xFF00BFA5).withOpacity(0.4),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.2.h),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF00BFA5).withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF00BFA5), size: 34),
                        ),
                        SizedBox(height: 1.2.h),
                        Text("Progress", style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, color: const Color(0xFF455A64), fontSize: 17.sp)),
                        Text("Level Up!", style: GoogleFonts.poppins(color: const Color(0xFF78909C), fontSize: 11.5.sp, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.5.w),
          Expanded(
            child: _floatingWrapper(
              offsetValue: -14,
              child: GestureDetector(
                onTap: () => context.goNamed("RewardsScreen"),
                child: _professionalCard(
                  borderColor: const Color(0xFFFFB300).withOpacity(0.4),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.2.h),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFB300).withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 34),
                        ),
                        SizedBox(height: 1.2.h),
                        Text("Rewards", style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, color: const Color(0xFF455A64), fontSize: 17.sp)),
                        Text("My Trove", style: GoogleFonts.poppins(color: const Color(0xFF78909C), fontSize: 11.5.sp, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _filteredModules.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 4.5.w, crossAxisSpacing: 4.5.w, childAspectRatio: 0.8),
        itemBuilder: (context, index) {
          final module = _filteredModules[index];
          return _floatingWrapper(
            offsetValue: (index % 2 == 0) ? -7 : -10,
            child: _animatedEntry(
              index: 4 + index,
              child: EcoModuleCard(
                title: module['title'],
                icon: module['icon'],
                color1: module['color1'],
                color2: module['color2'],
                imageUrl: module['imageUrl'],
                floatingWrapper: _floatingWrapper,
                onTap: () => context.goNamed(module['route']),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: _buildAnimatedBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                SizedBox(height: 3.h),
                _buildSearchBox(),
                SizedBox(height: 1.8.h),
                _buildTimeLimitCapsule(), // Integrated time limit pill
                SizedBox(height: 1.8.h),
                _buildInfoCards(),
                SizedBox(height: 3.h),
                _buildModuleGrid(),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EcoModuleCard extends StatefulWidget {
  final String title; final IconData icon; final Color color1; final Color color2; final String imageUrl; final VoidCallback onTap; final Widget Function({required Widget child, double offsetValue}) floatingWrapper;
  const EcoModuleCard({super.key, required this.title, required this.icon, required this.color1, required this.color2, required this.imageUrl, required this.onTap, required this.floatingWrapper});
  @override
  EcoModuleCardState createState() => EcoModuleCardState();
}
class EcoModuleCardState extends State<EcoModuleCard> with TickerProviderStateMixin {
  late final AnimationController _flipController; late final Animation<double> _flipAnimation; bool _isPressed = false;
  @override
  void initState() { super.initState(); _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack)); }
  @override
  void dispose() { _flipController.dispose(); super.dispose(); }
  void _handleTap() async { await _flipController.forward(); await Future.delayed(const Duration(milliseconds: 150)); if (mounted) widget.onTap(); if (mounted) Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _flipController.reverse(); }); }
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0, duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); _handleTap(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * math.pi; final isFront = _flipAnimation.value < 0.5;
            return Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle), child: isFront ? _buildFrontDesign() : Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _buildBackDesign()));
          },
        ),
      ),
    );
  }
  Widget _buildFrontDesign() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: widget.color1.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(fit: StackFit.expand, children: [
          Image.network(widget.imageUrl, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent, widget.color1.withOpacity(0.45)], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
          Positioned(top: 14, right: 14, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))]), child: Icon(widget.icon, color: widget.color1, size: 22))),
          Positioned(left: 18, bottom: 18, right: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: GoogleFonts.fredoka(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w600, letterSpacing: 0.4)), const SizedBox(height: 6), Container(height: 4, width: 45, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: Colors.white.withOpacity(0.85)))]))
        ]),
      ),
    );
  }
  Widget _buildBackDesign() {
    return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.color1, widget.color2], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(32)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.explore_rounded, color: Colors.white, size: 44), SizedBox(height: 1.5.h), Text("LET'S GO!", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: 1.5))])));
  }
}