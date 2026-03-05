import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:eco_venture/core/constants/app_gradients.dart';
import 'package:eco_venture/services/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/utils/utils.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../viewmodels/auth/auth_provider.dart';

class TeacherSettings extends StatefulWidget {
  const TeacherSettings({super.key});

  @override
  State<TeacherSettings> createState() => _TeacherSettingsState();
}

class _TeacherSettingsState extends State<TeacherSettings>
    with TickerProviderStateMixin {
  late AnimationController _profileImageController;
  late Animation<double> _profileImagePulse;
  String username = "Guest";
  String userImageUrl = "";

  Future<void> _loadUsername() async {
    final name = await SharedPreferencesHelper.instance.getUserName();
    final image = await SharedPreferencesHelper.instance.getUserImgUrl();
    if (mounted) {
      setState(() {
        username = name ?? "Guest";
        userImageUrl = image ?? "";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _profileImageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _profileImagePulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _profileImageController, curve: Curves.easeInOut),
    );

    _profileImageController.repeat(reverse: true);
    _loadUsername();
  }

  @override
  void dispose() {
    _profileImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.goNamed('bottomNavTeacher');
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              expandedHeight: 28.h,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.backgroundGradient,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _profileImagePulse,
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: Material(
                                elevation: 10,
                                borderRadius: BorderRadius.circular(10.h),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.h),
                                  child: SizedBox(
                                    height: 15.h,
                                    width: 15.h,
                                    child: userImageUrl.isNotEmpty
                                        ? Image.network(
                                      userImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                        : Center(
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.blueAccent,
                                        size: 20.w,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            "Settings",
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            username,
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 2.h),

                  // 1. Profile Tile
                  GestureDetector(
                    onTap: () => context.goNamed('teacherProfile'),
                    child: SettingsTile(
                      title: "Profile",
                      subtitle: "Manage your personal \ninformation",
                      circleColor: Colors.blue,
                      leadingIcon: Icons.person_outline,
                      trailing: _buildArrow(Colors.blue),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // 2. App Theme Tile
                  SettingsTile(
                    title: "App Theme",
                    subtitle: "Light mode",
                    circleColor: Colors.blue,
                    leadingIcon: Icons.dark_mode,
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: Colors.blue,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // 3. Contact Us Tile
                  SettingsTile(
                    title: "Contact us",
                    subtitle: "Get help and support",
                    circleColor: Colors.orangeAccent,
                    leadingIcon: Icons.support_agent,
                    trailing: _buildArrow(Colors.orangeAccent),
                  ),

                  SizedBox(height: 2.h),

                  // --- NEW: CONTACT ADMIN TILE ---
                  GestureDetector(
                    onTap: () {
                      // Navigates to report screen with Admin type pre-selected
                      context.pushNamed('teacherSendReportScreen', extra: {'type': 'Admin'});
                    },
                    child: SettingsTile(
                      title: "Contact Admin",
                      subtitle: "Report bugs or request features",
                      circleColor: Colors.indigoAccent,
                      leadingIcon: Icons.admin_panel_settings_outlined,
                      trailing: _buildArrow(Colors.indigoAccent),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // 4. Logout Tile
                  Consumer(
                    builder: (context, ref, child) {
                      final authVM = ref.read(authViewModelProvider.notifier);

                      return SettingsTile(
                        title: "Logout",
                        subtitle: "Sign out of your account",
                        circleColor: Colors.redAccent,
                        leadingIcon: Icons.exit_to_app,
                        trailing: _buildArrow(Colors.redAccent),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirm Logout"),
                              content: const Text(
                                "Do you really want to log out?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Logout"),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await authVM.signOut();
                            if (context.mounted) {
                              Utils.showDelightToast(
                                context,
                                "User successfully logged out",
                                duration: const Duration(seconds: 3),
                                textColor: Colors.white,
                                bgColor: Colors.green,
                                position: DelightSnackbarPosition.bottom,
                                icon: Icons.check,
                                iconColor: Colors.white,
                              );
                              context.goNamed('login');
                            }
                          }
                        },
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to maintain consistent arrow UI
  Widget _buildArrow(Color color) {
    return Container(
      height: 5.h,
      width: 10.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        color: color,
        size: 16.sp,
      ),
    );
  }
}
