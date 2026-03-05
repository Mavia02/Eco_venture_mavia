import 'package:eco_venture/models/user_model.dart';
import 'package:eco_venture/navigation/bottom_nav_teacher.dart';
import 'package:eco_venture/views/teacher_section/add_student_screen.dart';
import 'package:eco_venture/views/teacher_section/notification/teacher_notification_screen.dart';
import 'package:eco_venture/views/teacher_section/report_safety/teacher_report_detail_screen.dart';
import 'package:eco_venture/views/teacher_section/report_safety/teacher_safety_dashboard.dart';
import 'package:eco_venture/views/teacher_section/report_safety/teacher_send_report_screen.dart';
import 'package:eco_venture/views/teacher_section/teacher_class_report_screen.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_add_story_screen.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_add_video_screen.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_edit_story_screen.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_edit_video_screen.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_multimedia_dashboard.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_story_dashboard.dart';
import 'package:eco_venture/views/teacher_section/multi_media_content_Module/teacher_video_dahboard.dart';
import 'package:eco_venture/views/teacher_section/profile/teacher_edit_profile_screen.dart';
import 'package:eco_venture/views/teacher_section/profile/teacher_profile_screen.dart';
import 'package:eco_venture/views/teacher_section/quiz_module/teacher_add_quiz_screen.dart';
import 'package:eco_venture/views/teacher_section/quiz_module/teacher_quiz_dashboard.dart';
import 'package:eco_venture/views/teacher_section/settings/teacher_settings.dart';
import 'package:eco_venture/views/teacher_section/stem_challenges_module/teacher_edit_stem_challenge_screen.dart';
import 'package:eco_venture/views/teacher_section/stem_challenges_module/teacher_stem_dashboard.dart';
import 'package:eco_venture/views/teacher_section/teacher_home_screen.dart';
import 'package:eco_venture/views/teacher_section/teacher_stem_approved_screen.dart';
import 'package:eco_venture/views/teacher_section/teacher_treasure_hunt/teacher_add_treasure_hunt_screen.dart';
import 'package:eco_venture/views/teacher_section/teacher_treasure_hunt/teacher_edit_treasure_hunt_screen.dart';
import 'package:eco_venture/views/teacher_section/teacher_treasure_hunt/teacher_treasure_hunt_dashboard.dart';
import 'package:eco_venture/views/teacher_section/view_student_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/teacher_report_model.dart';
import '../../views/child_section/rewards_screen.dart';
import '../../views/teacher_section/quiz_module/teacher_edit_quiz_screen.dart';
import '../../views/teacher_section/stem_challenges_module/teacher_add_stem_challenge_Screen.dart';
import '../constants/route_names.dart';

class TeacherRouter {
  static GoRoute routes = GoRoute(
    path: RouteNames.bottomNavTeacher,
    name: 'bottomNavTeacher',
    builder: (context, state) => const BottomNavTeacher(),
    routes: [
      // --- TEACHER PROFILE & SETTINGS ---
      GoRoute(
        path: RouteNames.teacherSettings,
        name: 'teacherSettings',
        builder: (context, state) => const TeacherSettings(),
        routes: [
          GoRoute(
            path: RouteNames.teacherProfile,
            name: 'teacherProfile',
            builder: (context, state) => const TeacherProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.teacherEditProfile,
            name: 'teacherEditProfile',
            builder: (context, state) => const TeacherEditProfileScreen(),
          ),
        ],
      ),

      // --- TEACHER REWARDS ---
      GoRoute(
        path: 'rewards-screen',
        name: 'teacherRewardsScreen',
        builder: (context, state) => RewardsScreen(),
      ),

      // --- TEACHER SAFETY DASHBOARD ---
      GoRoute(
        path: RouteNames.teacherSafetyDashboard,
        name: "teacherSafetyDashboard",
        builder: (context, state) => const TeacherSafetyDashboard(),
        routes: [
          GoRoute(
            path: RouteNames.teacherReportDetailScreen,
            name: "teacherReportDetailScreen",
            builder: (context, state) {
              final reportData = state.extra as TeacherReportModel;
              return TeacherReportDetailScreen(reportData: reportData);
            },
          ),
          // Generic report route (e.g., Contact Admin from Safety Center)
          GoRoute(
            path: RouteNames.teacherSendReportScreen,
            name: "teacherSendReportScreen",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TeacherSendReportScreen(extra: extra);
            },
          ),
        ],
      ),

      // --- TEACHER HOME & EXPLORER MANAGEMENT ---
      GoRoute(
        path: RouteNames.teacherHome,
        name: 'teacherHome',
        builder: (context, state) => const TeacherHomeScreen(),
        routes: [
          GoRoute(
            path: RouteNames.teacherNotificationScreen,
            name: 'teacherNotificationScreen',
            builder: (context, state) => const TeacherNotificationScreen(),
          ),
          GoRoute(
            path: RouteNames.addStudentScreen,
            name: 'addStudentScreen',
            builder: (context, state) => const AddStudentScreen(),
          ),

          // --- STUDENT DETAIL FLOW ---
          GoRoute(
            path: RouteNames.studentDetailScreen,
            name: 'studentDetailScreen',
            builder: (context, state) {
              final studentMap = state.extra as Map<String, dynamic>;
              return ViewStudentDetailScreen(studentData: studentMap);
            },
            routes: [
              // FIXED: Parent Communication Route
              // Path is 'send-report' (Relative to /teacherHome/studentDetail)
              // Name is 'teacherContactParentScreen' (Called by button in ViewStudentDetailScreen)
              GoRoute(
                path: 'send-report',
                name: 'teacherContactParentScreen',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return TeacherSendReportScreen(extra: extra);
                },
              ),

              GoRoute(
                path: RouteNames.teacherStemApprovedScreen,
                name: 'teacherStemApprovedScreen',
                builder: (context, state) {
                  final approvedData = state.extra;
                  if (approvedData is Map<String, dynamic>) {
                    return TeacherStemApprovedScreen(data: approvedData);
                  } else {
                    return const Scaffold(
                      body: Center(child: Text("Error: Missing submission data!")),
                    );
                  }
                },
              ),
            ],
          ),

          // --- DASHBOARD MODULES ---
          GoRoute(
            path: RouteNames.classReportScreen,
            name: 'classReportScreen',
            builder: (context, state) => const TeacherClassReportScreen(),
          ),

          // Quiz Module
          GoRoute(
            path: RouteNames.teacherQuizDashboard,
            name: 'teacherQuizDashBoard',
            builder: (context, state) => const TeacherQuizDashboard(),
            routes: [
              GoRoute(
                path: RouteNames.teacherAddQuizScreen,
                name: 'teacherAddQuizScreen',
                builder: (context, state) => const TeacherAddQuizScreen(),
              ),
              GoRoute(
                path: RouteNames.teacherEditQuizScreen,
                name: 'teacherEditQuizScreen',
                builder: (context, state) {
                  final dynamic quizData = state.extra;
                  return TeacherEditQuizScreen(quizData: quizData);
                },
              ),
            ],
          ),

          // STEM Module
          GoRoute(
            path: RouteNames.teacherStemChallengeDashboard,
            name: 'teacherStemChallengeDashboard',
            builder: (context, state) => TeacherStemDashboard(),
            routes: [
              GoRoute(
                path: RouteNames.teacherAddStemChallengeScreen,
                name: 'teacherAddStemChallengeScreen',
                builder: (context, state) => const TeacherAddStemChallengeScreen(),
              ),
              GoRoute(
                path: RouteNames.teacherEditStemChallengeScreen,
                name: 'teacherEditStemChallengeScreen',
                builder: (context, state) {
                  final dynamic challengeData = state.extra;
                  return TeacherEditStemChallengeScreen(challengeData: challengeData);
                },
              ),
            ],
          ),

          // Multimedia Module
          GoRoute(
            path: RouteNames.teacherMultimediaDashboard,
            name: 'teacherMultimediaDashboard',
            builder: (context, state) => const TeacherMultimediaDashboard(),
            routes: [
              // Videos
              GoRoute(
                path: RouteNames.teacherVideoDashboard,
                name: 'teacherVideoDashboard',
                builder: (context, state) => const TeacherVideoDashboard(),
                routes: [
                  GoRoute(
                    path: RouteNames.teacherAddVideoScreen,
                    name: 'teacherAddVideoScreen',
                    builder: (context, state) => const TeacherAddVideoScreen(),
                  ),
                  GoRoute(
                    path: RouteNames.teacherEditVideoScreen,
                    name: 'teacherEditVideoScreen',
                    builder: (context, state) {
                      final dynamic videoData = state.extra;
                      return TeacherEditVideoScreen(videoData: videoData);
                    },
                  ),
                ],
              ),
              // Stories
              GoRoute(
                path: RouteNames.teacherStoryDashboard,
                name: 'teacherStoryDashboard',
                builder: (context, state) => TeacherStoryDashboard(),
                routes: [
                  GoRoute(
                    path: RouteNames.teacherAddStoryScreen,
                    name: 'teacherAddStoryScreen',
                    builder: (context, state) => const TeacherAddStoryScreen(),
                  ),
                  GoRoute(
                    path: RouteNames.teacherEditStoryScreen,
                    name: 'teacherEditStoryScreen',
                    builder: (context, state) {
                      final dynamic storyData = state.extra;
                      return TeacherEditStoryScreen(storyData: storyData);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Treasure Hunt Module
          GoRoute(
            path: RouteNames.teacherTreasureHuntDashboard,
            name: 'teacherTreasureHuntDashboard',
            builder: (context, state) => const TeacherTreasureHuntDashboard(),
            routes: [
              GoRoute(
                path: RouteNames.teacherAddTreasureHuntScreen,
                name: 'teacherAddTreasureHuntScreen',
                builder: (context, state) => const TeacherAddTreasureHuntScreen(),
              ),
              GoRoute(
                path: RouteNames.teacherEditTreasureHuntScreen,
                name: 'teacherEditTreasureHuntScreen',
                builder: (context, state) {
                  final dynamic huntData = state.extra;
                  return TeacherEditTreasureHuntScreen(huntData: huntData);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
