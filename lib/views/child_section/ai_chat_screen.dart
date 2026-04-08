import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../models/chat_message.dart';
import '../../viewmodels/chat_view_model/chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenV2State();
}

class _AiChatScreenV2State extends ConsumerState<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _bgShiftController;
  late final AnimationController _particleController;
  late final AnimationController _sendPulseController;

  @override
  void initState() {
    super.initState();

    _bgShiftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _sendPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _bgShiftController.dispose();
    _particleController.dispose();
    _sendPulseController.dispose();
    super.dispose();
  }

  void _onSend(dynamic chatVM) {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();

    _sendPulseController.forward(from: 0);

    chatVM.sendMessage(text).then((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatVM = ref.read(chatProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.goNamed('bottomNavChild');
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Layered animated gradient background
            AnimatedBuilder(
              animation: _bgShiftController,
              builder: (context, _) {
                final t = _bgShiftController.value;
                return CustomPaint(
                  painter: _ParallaxGradientPainter(t),
                  size: Size.infinite,
                );
              },
            ),

            // Subtle noise / vignette
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.2, -0.6),
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.12),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Particle layer
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main UI content
            SafeArea(
              child: Column(
                children: [
                  _TopHeader(),

                  // Chat messages
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == chatState.messages.length && chatState.isLoading) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 1.2.h),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _TypingIndicator(),
                              ),
                            );
                          }
                          final msg = chatState.messages[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.8.h),
                            child: _ChatBubble(message: msg),
                          );
                        },
                      ),
                    ),
                  ),

                  // Floating input bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 8.h),
                    child: _InputBar(
                      controller: _controller,
                      onSend: () => _onSend(chatVM),
                      sendPulse: _sendPulseController,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top header with title and subtitle
class _TopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Text(
            '🤖 EcoBuddy',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            'Eco Venture Smart Assistant',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}

/// Updated Chat bubble with "Verified Source" badge
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Check 'isUser' from the model to determine layout and style
    final isUser = message.isUser;
    // Specifically check if the sender is 'bot' for the verified badge
    final isBot = message.sender == 'bot';

    final radius = 16.0;

    // Electric blue/cyan for AI side, Purple for User side
    final gradient = isUser
        ? const LinearGradient(colors: [Color(0xFF6A4BFF), Color(0xFF4C1DFF)])
        : const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]);

    final shadowColor = isUser ? Colors.deepPurpleAccent : Colors.cyanAccent;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // If message is from bot, add a small label above
          if (isBot)
            Padding(
              padding: EdgeInsets.only(left: 1.w, bottom: 0.5.h),
              child: Text(
                "EcoBuddy",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 78.w),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                  bottomLeft: Radius.circular(isUser ? radius : 6),
                  bottomRight: Radius.circular(isUser ? 6 : radius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.6.w, vertical: 1.4.h),
                child: Text(
                  message.message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Verified Source Badge for Bot messages
          if (isBot)
            Padding(
              padding: EdgeInsets.only(top: 0.8.h, left: 1.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 13.sp),
                  SizedBox(width: 1.w),
                  Text(
                    "Verified Eco Venture Source",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _a1, _a2, _a3;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();

    _a1 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _a2 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.75, curve: Curves.easeInOut)),
    );
    _a3 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.9, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(Animation<double> a) {
    return ScaleTransition(
      scale: a,
      child: Container(
        width: 3.6.w,
        height: 3.6.w,
        decoration: BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black45.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0,2))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.2.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(_a1),
          SizedBox(width: 2.w),
          _dot(_a2),
          SizedBox(width: 2.w),
          _dot(_a3),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final AnimationController sendPulse;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.sendPulse,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.sp),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Ask EcoBuddy anything...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 15.sp),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 6.w,
          child: AnimatedBuilder(
            animation: widget.sendPulse,
            builder: (context, child) {
              final glow = 6 + (20 * widget.sendPulse.value);
              final scale = 1.0 + (0.06 * widget.sendPulse.value);
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.all(0.6.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF8E6BFF), Color(0xFF5A2DFF)]),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withValues(alpha: 0.24 + widget.sendPulse.value * 0.3),
                        blurRadius: glow,
                        spreadRadius: widget.sendPulse.value * 3,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: widget.onSend,
                    child: Icon(Icons.send_rounded, size: 22.sp, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class _ParallaxGradientPainter extends CustomPainter {
  final double t;
  _ParallaxGradientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paintBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-0.8 + 0.6 * sin(2 * pi * t), -0.6),
        end: Alignment(0.8, 0.6 + 0.6 * cos(2 * pi * t)),
        colors: const [Color(0xFF0F1724), Color(0xFF102A43), Color(0xFF0F2557)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paintBase);

    final center = Offset(size.width * (0.2 + 0.6 * sin(2 * pi * (t * 0.9))), size.height * 0.15);
    final radial = Paint()
      ..shader = RadialGradient(
        colors: [Colors.deepPurple.withValues(alpha: 0.14), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.9));
    canvas.drawRect(rect, radial);

    final path = Path();
    final y = size.height * (0.35 + 0.08 * sin(2 * pi * t));
    path.moveTo(0, y);
    path.quadraticBezierTo(size.width * 0.5, y + 140 * sin(2 * pi * t), size.width, y);
    final shimmer = Paint()
      ..shader = LinearGradient(
        colors: [Colors.purpleAccent.withValues(alpha: 0.06), Colors.transparent],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(path, shimmer);
  }

  @override
  bool shouldRepaint(covariant _ParallaxGradientPainter oldDelegate) => oldDelegate.t != t;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final List<_ParticleSeed> seeds = List.generate(28, (i) {
    final r = Random(i);
    return _ParticleSeed(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.2 + r.nextDouble() * 0.8,
      size: 2 + r.nextDouble() * 8,
      colorIndex: i,
      sway: 8 + r.nextDouble() * 40,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var s in seeds) {
      final dx = (s.x * size.width) + sin(progress * 2 * pi * s.speed + s.sway) * (s.sway / 4);
      final dy = ((s.y * size.height) + (progress * size.height * s.speed)) % size.height;
      final radius = s.size;
      paint.color = _chooseColor(s.colorIndex).withValues(alpha: 0.06 + (s.size / 30));
      canvas.drawCircle(Offset(dx, dy), radius, paint);

      paint.color = Colors.white.withValues(alpha: 0.02 + (s.size / 140));
      canvas.drawCircle(Offset(dx - radius / 2, dy - radius / 2), radius / 2, paint);
    }
  }

  Color _chooseColor(int i) {
    final palette = [
      const Color(0xFF8E6BFF),
      const Color(0xFF00E5FF),
      const Color(0xFFFF8A80),
      const Color(0xFF7C4DFF),
      const Color(0xFF00B0FF),
    ];
    return palette[i % palette.length];
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

class _ParticleSeed {
  final double x, y, speed, size, sway;
  final int colorIndex;
  _ParticleSeed({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.sway,
    required this.colorIndex,
  });
}
