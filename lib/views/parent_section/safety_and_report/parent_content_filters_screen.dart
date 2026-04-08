import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/parent_section/report_safety/parent_safety_provider.dart';

class ParentContentFiltersScreen extends ConsumerStatefulWidget {
  const ParentContentFiltersScreen({super.key});

  @override
  ConsumerState<ParentContentFiltersScreen> createState() => _ParentContentFiltersScreenState();
}

class _ParentContentFiltersScreenState extends ConsumerState<ParentContentFiltersScreen> {
  final Color _primary = const Color(0xFF1E88E5);
  final Color _bg = const Color(0xFFF5F7FA);
  final Color _textDark = const Color(0xFF263238);
  final Color _textGrey = const Color(0xFF78909C);

  late bool _blockScaryContent;
  late bool _blockSocialInteraction;
  late bool _educationalOnlyMode;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(parentSafetyViewModelProvider).settings;
    _blockScaryContent = settings.blockScaryContent;
    _blockSocialInteraction = settings.blockSocialInteraction;
    _educationalOnlyMode = settings.educationalOnlyMode;
  }

  void _saveFilters() {
    ref.read(parentSafetyViewModelProvider.notifier).updateContentFilters(
      scary: _blockScaryContent,
      social: _blockSocialInteraction,
      eduOnly: _educationalOnlyMode,
    );

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Filters Updated!"), backgroundColor: Colors.green)
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20.sp), onPressed: () => context.pop()),
        centerTitle: true,
        title: Text("Content Filters", style: GoogleFonts.poppins(color: _textDark, fontWeight: FontWeight.w700, fontSize: 17.sp)),
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  SizedBox(height: 2.h),
                  _buildFilterTile(
                    title: "Scary Content",
                    subtitle: "Filters out frightening or suspenseful scenes.",
                    icon: Icons.visibility_off_rounded,
                    color: Colors.purple,
                    value: _blockScaryContent,
                    onChanged: (val) => setState(() => _blockScaryContent = val),
                  ),
                  SizedBox(height: 2.5.h),
                  _buildFilterTile(
                    title: "Social Interaction",
                    subtitle: "Restricts chat or friend requests.",
                    icon: Icons.speaker_notes_off_rounded,
                    color: Colors.orange,
                    value: _blockSocialInteraction,
                    onChanged: (val) => setState(() => _blockSocialInteraction = val),
                  ),
                  SizedBox(height: 2.5.h),
                  _buildFilterTile(
                    title: "Educational-Only Mode",
                    subtitle: "Limits gameplay to core learning modules.",
                    icon: Icons.school_rounded,
                    color: Colors.blue,
                    value: _educationalOnlyMode,
                    onChanged: (val) => setState(() => _educationalOnlyMode = val),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity, height: 7.5.h,
              child: ElevatedButton(
                onPressed: _saveFilters,
                style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 5),
                child: Text("Save Filters", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile({required String title, required String subtitle, required IconData icon, required Color color, required bool value, required Function(bool) onChanged}) {
    return Container(padding: EdgeInsets.all(4.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: Colors.white)), child: Row(children: [Container(padding: EdgeInsets.all(3.w), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 22.sp)), SizedBox(width: 4.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w700, color: _textDark)), SizedBox(height: 0.5.h), Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.sp, color: _textGrey, height: 1.4, fontWeight: FontWeight.w500))])), Transform.scale(scale: 0.9, child: Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: _primary, inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.grey.shade200))]));
  }
}