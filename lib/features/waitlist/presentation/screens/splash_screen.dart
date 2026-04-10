import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';
import 'package:bayan/features/auth/presentation/screens/invitation_screen.dart';
import 'package:bayan/features/onboarding/presentation/onboarding_screen.dart';
import 'package:bayan/features/shell/presentation/main_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _contentController;
  late final AnimationController _exitController;

  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _versionFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _ringScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _ringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
      ),
    );

    _versionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3800), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;

    _exitController.forward().then((_) {
      if (!mounted) return;
      final isAuthenticated = ref.read(userProvider).isAuthenticated;

      if (isAuthenticated) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const MainShell(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => OnboardingScreen(
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, a1, a2) => const InvitationScreen(),
                    transitionDuration: const Duration(milliseconds: 600),
                    transitionsBuilder: (context, animation, _, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
            ),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _contentController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _exitController.value,
            child: Transform.scale(
              scale: 1.0 + _exitController.value * 0.05,
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoSection(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildSubtitle(),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: _buildVersionBadge(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionBadge() {
    return AnimatedBuilder(
      animation: Listenable.merge([_contentController, _exitController]),
      builder: (context, child) {
        final fadeOut = 1.0 - (_exitController.value * 1.5).clamp(0.0, 1.0);
        return Opacity(opacity: _versionFade.value * fadeOut, child: child);
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: BayanColors.accent.withValues(alpha: 0.06),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BayanColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: BayanColors.accent.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'v2.0 Elite Edition',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_contentController, _ringController]),
      builder: (context, child) {
        final glow = (math.sin(_glowPulse.value * 2 * math.pi) + 1) / 2;
        return Opacity(
          opacity: _ringOpacity.value,
          child: Transform.scale(
            scale: _ringScale.value,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _SplashRingPainter(
                      progress: _ringController.value,
                      color: BayanColors.accent,
                      glowIntensity: glow,
                    ),
                    size: const Size(240, 240),
                  ),
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: GlassmorphicContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 32,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/Bayan.JPG',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(
          opacity: _titleFade.value,
          child: SlideTransition(position: _titleSlide, child: child),
        );
      },
      child: Text(
        'بيان',
        style: GoogleFonts.cairo(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: BayanColors.textPrimary,
          letterSpacing: 6,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(opacity: _subtitleFade.value, child: child);
      },
      child: Text(
        'صوتك يُسمع',
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: BayanColors.textSecondary,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

class _SplashRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;

  _SplashRingPainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bgRingPaint = Paint()
      ..color = color.withValues(alpha: 0.06 + glowIntensity * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, bgRingPaint);

    final sweepAngle = progress * 2 * math.pi;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + math.pi * 0.8,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.5 + glowIntensity * 0.3),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + glowIntensity * 3);

    canvas.drawCircle(center, radius, arcPaint);

    final dotAngle = sweepAngle + math.pi * 0.4;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.7 + glowIntensity * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + glowIntensity * 4);
    canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_SplashRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.glowIntensity != glowIntensity;
}
