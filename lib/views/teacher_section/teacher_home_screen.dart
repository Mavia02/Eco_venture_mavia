import 'dart:ui';
import 'package:eco_venture/models/user_model.dart';
import 'package:eco_venture/repositories/teacher_repoistory.dart';
import 'package:eco_venture/viewmodels/teacher_home/teacher_home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/shared_preferences_helper.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedClassFilter;
  String _teacherStatus = 'loading';
  String _teacherName = "Teacher";
  bool _isDeleting = false;

  final List<Color> _avatarColors = [
    const Color(0xFFFFE0B2),
    const Color(0xFFC8E6C9),
    const Color(0xFFB3E5FC),
    const Color(0xFFF8BBD0),
    const Color(0xFFD1C4E9),
  ];

  @override
  void initState() {
    super.initState();
    _checkTeacherStatus();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _checkTeacherStatus() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid ?? await SharedPreferencesHelper.instance.getUserId();
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _teacherStatus = doc.data()!['status'] ?? 'active';
          _teacherName = doc.data()!['name'] ?? "Teacher";
        });
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
    }
  }

  Future<void> _confirmDeletion(UserModel student) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Permanent Delete?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "This will completely remove ${student.displayName} from the school database, classroom, and progress records. This action cannot be undone.",
          style: GoogleFonts.poppins(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await TeacherRepository.getInstance.deleteStudent(student.uid);
        ref.invalidate(teacherHomeViewModelProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Explorer successfully deleted from database."), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting student: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_teacherStatus == 'loading') {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 3.h),
                          _buildSectionHeader("Active Classes", Icons.class_rounded),
                          SizedBox(height: 2.h),
                          _buildClassCards(),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader("My Students", Icons.face_retouching_natural_rounded),
                              if (_selectedClassFilter != null)
                                TextButton(
                                  onPressed: () => setState(() => _selectedClassFilter = null),
                                  child: Text("Clear Filter", style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13.sp)),
                                )
                            ],
                          ),
                          SizedBox(height: 1.5.h),
                          _buildSearchBar(),
                          SizedBox(height: 2.5.h),
                          _buildStudentList(),
                          SizedBox(height: 1.5.h),
                          _buildAddStudentButton(),
                          SizedBox(height: 4.h),
                          _buildSectionHeader("Activity Center", Icons.auto_graph_rounded),
                          SizedBox(height: 2.h),
                          _buildClassReportCard(),
                          SizedBox(height: 4.h),
                          _buildSectionHeader("Learning Hub", Icons.auto_awesome_mosaic_rounded),
                          SizedBox(height: 2.5.h),
                          _buildContentGrid(),
                          SizedBox(height: 6.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isDeleting)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildClassCards() {
    return Consumer(builder: (context, ref, child) {
      final state = ref.watch(teacherHomeViewModelProvider);
      final students = state.students;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _classSummaryCard("6 - 8", Icons.child_care_rounded, const Color(0xFF4E54C8), students),
          _classSummaryCard("8 - 10", Icons.directions_run_rounded, const Color(0xFF11998e), students),
          _classSummaryCard("10 - 12", Icons.school_rounded, const Color(0xFFF2994A), students),
        ],
      );
    });
  }

  Widget _classSummaryCard(String ageRange, IconData icon, Color color, List<UserModel> students) {
    int count = students.where((s) => s.ageGroup == ageRange).length;
    bool isSelected = _selectedClassFilter == ageRange;

    return GestureDetector(
      onTap: () => setState(() => _selectedClassFilter = isSelected ? null : ageRange),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28.w,
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 22.sp),
            SizedBox(height: 1.h),
            Text(
              ageRange,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            Text(
              "$count Students",
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(teacherHomeViewModelProvider);
        if (state.isLoading) return _buildShimmer();

        var filtered = state.students
            .where((s) => s.displayName.toLowerCase().contains(_searchQuery))
            .toList();

        if (_selectedClassFilter != null) {
          filtered = filtered.where((s) => s.ageGroup == _selectedClassFilter).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                children: [
                  Icon(Icons.sentiment_dissatisfied_rounded, size: 28.sp, color: Colors.blueGrey[200]),
                  SizedBox(height: 1.h),
                  Text(
                    _selectedClassFilter != null
                        ? "No students in Group $_selectedClassFilter"
                        : "No matching explorers found",
                    style: GoogleFonts.poppins(color: Colors.blueGrey[300], fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 22.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(width: 5.w),
            itemBuilder: (context, index) => _buildStudentCard(filtered[index], index),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: 100.w,
      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 4.h),
      decoration: const BoxDecoration(
        color: Color(0xFF4E54C8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 25.sp,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: const Color(0xFF4E54C8), size: 28.sp),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, $_teacherName!",
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Classroom Lead",
                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          _buildCircleAction(
            Icons.notifications_none_rounded,
                () => context.goNamed('teacherNotificationScreen'),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: const Color(0xFF4E54C8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20.sp, color: const Color(0xFF4E54C8)),
        ),
        SizedBox(width: 3.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Find a student...",
          hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blueGrey.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF4E54C8), size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 1.8.h),
        ),
      ),
    );
  }

  Widget _buildStudentCard(UserModel student, int index) {
    final avatarColor = _avatarColors[index % _avatarColors.length];

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.pushNamed('studentDetailScreen', extra: student.toMap()),
          child: Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor, width: 2),
                  ),
                ),
                CircleAvatar(
                  radius: 8.5.w,
                  backgroundColor: avatarColor.withOpacity(0.2),
                  backgroundImage: (student.imgUrl?.isNotEmpty ?? false)
                      ? NetworkImage(student.imgUrl!)
                      : null,
                  child: (student.imgUrl == null || student.imgUrl!.isEmpty)
                      ? Text(
                    student.displayName.isNotEmpty ? student.displayName[0].toUpperCase() : "S",
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4E54C8),
                    ),
                  )
                      : null,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1.2.h),
        Text(
          student.displayName,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 0.5.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallIconBtn(
              Icons.info_outline_rounded,
              const Color(0xFF4E54C8),
                  () => context.pushNamed('studentDetailScreen', extra: student.toMap()),
            ),
            SizedBox(width: 2.w),
            _buildSmallIconBtn(
              Icons.delete_sweep_rounded,
              Colors.redAccent,
                  () => _confirmDeletion(student),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSmallIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }

  Widget _buildAddStudentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed('addStudentScreen'),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4E54C8).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 3.w),
              Text(
                "Register New Explorer",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassReportCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed('classReportScreen'),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.stars_rounded, color: const Color(0xFF11998e), size: 24.sp),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Performance Summary",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    Text(
                      "Track how your class is learning",
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 4.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.1,
      children: [
        _buildActionTile(
          "Quizzes",
          Icons.lightbulb_outline,
          [const Color(0xFFFF9D6C), const Color(0xFFBB4E75)],
              () => context.goNamed('teacherQuizDashBoard'),
        ),
        _buildActionTile(
          "STEM Lab",
          Icons.science_outlined,
          [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
              () => context.goNamed('teacherStemChallengeDashboard'),
        ),
        _buildActionTile(
          "Library",
          Icons.auto_stories_outlined,
          [const Color(0xFFEB3349), const Color(0xFFF45C43)],
              () => context.goNamed('teacherMultimediaDashboard'),
        ),
        _buildActionTile(
          "Hunt",
          Icons.location_searching_rounded,
          [const Color(0xFF02AABD), const Color(0xFF00CDAC)],
              () => context.goNamed('teacherTreasureHuntDashboard'),
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, List<Color> gradientColors, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22.sp),
              ),
              SizedBox(height: 1.2.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 18.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            width: 22.w,
            margin: EdgeInsets.only(right: 4.w),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }
}