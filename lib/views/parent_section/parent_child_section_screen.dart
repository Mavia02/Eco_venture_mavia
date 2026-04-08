import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/* GRAPHICAL REMOVAL: This screen's UI is no longer visible.
  LOGICAL RETENTION: It remains in the codebase to prevent route errors,
  but instantly pushes the user to the Home Screen.
*/

class ParentChildSelectionScreen extends ConsumerWidget {
  const ParentChildSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic: Immediately jump to the Bottom Nav / Home Screen (Landing Page)
    Future.microtask(() {
      if (context.mounted) {
        // Redirecting to the primary Dashboard/Home experience
        context.goNamed('bottomNavParent');
      }
    });

    // Show a clean loader for a split second while the app handles the navigation
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E293B),
          strokeWidth: 3,
        ),
      ),
    );
  }
}