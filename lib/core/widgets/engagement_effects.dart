import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

class NewQuestionToast extends StatefulWidget {
  final String authorName;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const NewQuestionToast({
    super.key,
    required this.authorName,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<NewQuestionToast> createState() => _NewQuestionToastState();
}

class _NewQuestionToastState extends State<NewQuestionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    HapticFeedback.selectionClick();
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              20,
              0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: BayanColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          color: Color(0xFFD4AF37),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سؤال جديد',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            Text(
                              'من ${widget.authorName}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: BayanColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: BayanColors.textSecondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConfettiOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const ConfettiOverlay({super.key, required this.onComplete});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3000),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onComplete();
        });

    final colors = [
      BayanColors.accent,
      const Color(0xFFD4AF37),
      const Color(0xFF6C3FA0),
      const Color(0xFF7DD4C4),
      const Color(0xFF2A6F97),
      BayanColors.accentLight,
    ];

    _pieces = List.generate(
      60,
      (_) => _ConfettiPiece(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.3,
        speed: _random.nextDouble() * 2 + 1,
        drift: (_random.nextDouble() - 0.5) * 2,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        size: _random.nextDouble() * 6 + 3,
        color: colors[_random.nextInt(colors.length)],
        isCircle: _random.nextBool(),
      ),
    );

    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double y;
  final double speed;
  final double drift;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = progress;
      final x = (p.x + p.drift * t * 0.3) * size.width;
      final y = (p.y + p.speed * t) * size.height;
      final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
      if (y > size.height || opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class SparkleOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const SparkleOverlay({super.key, required this.onComplete});

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Sparkle> _sparkles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2000),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onComplete();
        });

    _sparkles = List.generate(
      40,
      (_) => _Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        delay: _random.nextDouble() * 0.5,
        maxSize: _random.nextDouble() * 8 + 4,
        color: [
          BayanColors.accent,
          const Color(0xFFD4AF37),
          BayanColors.accentLight,
        ][_random.nextInt(3)],
      ),
    );

    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SparklePainter(
              sparkles: _sparkles,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Sparkle {
  final double x;
  final double y;
  final double delay;
  final double maxSize;
  final Color color;

  _Sparkle({
    required this.x,
    required this.y,
    required this.delay,
    required this.maxSize,
    required this.color,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final localT = ((progress - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final scale = localT < 0.5 ? localT * 2 : (1.0 - localT) * 2;
      final currentSize = s.maxSize * scale;
      if (currentSize <= 0) continue;

      final center = Offset(s.x * size.width, s.y * size.height);
      final paint = Paint()
        ..color = s.color.withValues(alpha: scale.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 0.3);

      canvas.drawCircle(center, currentSize, paint);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: scale * 0.7);
      canvas.drawCircle(center, currentSize * 0.3, corePaint);

      final crossPaint = Paint()
        ..color = s.color.withValues(alpha: scale * 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(center.dx - currentSize, center.dy),
        Offset(center.dx + currentSize, center.dy),
        crossPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - currentSize),
        Offset(center.dx, center.dy + currentSize),
        crossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
