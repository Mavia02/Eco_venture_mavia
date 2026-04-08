import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/parent_section/report_safety/parent_safety_provider.dart';

class ParentScreenTimeScreen extends ConsumerStatefulWidget {
  const ParentScreenTimeScreen({super.key});

  @override
  ConsumerState<ParentScreenTimeScreen> createState() => _ParentScreenTimeScreenState();
}

class _ParentScreenTimeScreenState extends ConsumerState<ParentScreenTimeScreen> {
  final Color _primary = const Color(0xFF2196F3);
  final Color _bg = const Color(0xFFF5F7FA);
  final Color _textDark = const Color(0xFF263238);
  final Color _textGrey = const Color(0xFF78909C);

  late double _dailyLimit;
  late TimeOfDay _bedtimeStart;
  late TimeOfDay _bedtimeEnd;
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(parentSafetyViewModelProvider).settings;
    _dailyLimit = settings.dailyLimitHours;
    _bedtimeStart = _parseTime(settings.bedtimeStart);
    _bedtimeEnd = _parseTime(settings.bedtimeEnd);
    _reminders = settings.enableBreakReminders;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 21, minute: 0);
    }
  }

  String _timeToString(TimeOfDay time) => "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _bedtimeStart : _bedtimeEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _bedtimeStart = picked;
        else _bedtimeEnd = picked;
      });
    }
  }

  void _saveSettings() {
    ref.read(parentSafetyViewModelProvider.notifier).updateTimeSettings(
        limit: _dailyLimit,
        start: _timeToString(_bedtimeStart),
        end: _timeToString(_bedtimeEnd),
        reminders: _reminders
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved!"), backgroundColor: Colors.green));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(parentSafetyViewModelProvider).settings;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          "Screen Time Control",
          style: GoogleFonts.poppins(color: _textDark, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Limit", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textDark)),
            SizedBox(height: 1.h),
            Text("Set the maximum playtime per day.", style: GoogleFonts.poppins(fontSize: 14.sp, color: _textGrey)),
            SizedBox(height: 2.h),

            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Daily Limit", style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _textDark)),
                      Text(_formatHours(_dailyLimit), style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _primary)),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _primary,
                      inactiveTrackColor: _primary.withOpacity(0.2),
                      thumbColor: Colors.white,
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                      overlayColor: _primary.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: _dailyLimit,
                      min: 0,
                      max: 6,
                      divisions: 12,
                      onChanged: (val) => setState(() => _dailyLimit = val),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("0h", style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey)),
                        Text("6h", style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 4.h),

            Text("Watching time", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textDark)),
            SizedBox(height: 1.h),
            Text("The app will be unavailable during these hours.", style: GoogleFonts.poppins(fontSize: 14.sp, color: _textGrey)),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("From", style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey)),
                            SizedBox(height: 1.h),
                            _buildTimeSelector(_formatTime(_bedtimeStart), () => _selectTime(true)),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("To", style: GoogleFonts.poppins(fontSize: 12.sp, color: _textGrey)),
                            SizedBox(height: 1.h),
                            _buildTimeSelector(_formatTime(_bedtimeEnd), () => _selectTime(false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(right: 0, top: 0, child: Icon(Icons.nights_stay_rounded, color: Colors.indigo.shade100, size: 26.sp)),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            _buildPauseButton(
                isPaused: settings.isAppPaused,
                onTap: (currentValue) {
                  ref.read(parentSafetyViewModelProvider.notifier).toggleAppPause(!currentValue);
                }
            ),

            SizedBox(height: 4.h),

            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: _primary.withOpacity(0.4),
                ),
                child: Text(
                  "Save Changes",
                  style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }

  String _formatHours(double value) {
    int hours = value.floor();
    int minutes = ((value - hours) * 60).round();
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  Widget _buildTimeSelector(String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEF0F2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _textDark)),
            Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey, size: 18.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseButton({required bool isPaused, required Function(bool) onTap}) {
    return GestureDetector(
      onTap: () => onTap(isPaused),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isPaused ? Colors.red.shade50 : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPaused ? Colors.red : const Color(0xFFFFC107), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPaused ? Icons.play_circle_filled_rounded : Icons.pause_circle_filled_rounded, color: isPaused ? Colors.red : const Color(0xFFFFA000), size: 20.sp),
            SizedBox(width: 2.w),
            Text(
              isPaused ? "Resume App Access" : "Pause App for Today",
              style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isPaused ? Colors.red : const Color(0xFFFFA000)),
            ),
          ],
        ),
      ),
    );
  }
}