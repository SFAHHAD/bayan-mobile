import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

Future<void> showShareDiwanSheet(
  BuildContext context, {
  required String diwanName,
  required String hostName,
  required int listenerCount,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(
      diwanName: diwanName,
      hostName: hostName,
      listenerCount: listenerCount,
    ),
  );
}

class _ShareSheet extends StatelessWidget {
  final String diwanName;
  final String hostName;
  final int listenerCount;

  const _ShareSheet({
    required this.diwanName,
    required this.hostName,
    required this.listenerCount,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BayanColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'مشاركة الديوانيّة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildInviteCard(),
              const SizedBox(height: 24),
              _buildShareActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            BayanColors.accent.withValues(alpha: 0.2),
            const Color(0xFF6C3FA0).withValues(alpha: 0.15),
            BayanColors.surface,
          ],
        ),
        border: Border.all(color: BayanColors.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: BayanColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بَيَان',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diwanName,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يستضيفها $hostName',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 14,
                          color: BayanColors.accent.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$listenerCount مستمع',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: BayanColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildQrPlaceholder(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrPlaceholder() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: BayanColors.textPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(painter: _QrCodePainter(), size: const Size(88, 88)),
      ),
    );
  }

  Widget _buildShareActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(
                ClipboardData(text: 'bayan.app/diwan/$diwanName'),
              );
              Navigator.of(context).pop();
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: BayanColors.glassBackground,
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نسخ الرابط',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: BayanColors.accent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.share_rounded,
                    color: BayanColors.background,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مشاركة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final cellSize = size.width / 11;
    final paint = Paint()..color = const Color(0xFF241231);
    final bgPaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, bgPaint);

    for (var r = 0; r < 11; r++) {
      for (var c = 0; c < 11; c++) {
        final inCorner =
            (r < 3 && c < 3) || (r < 3 && c > 7) || (r > 7 && c < 3);
        final filled = inCorner || rng.nextDouble() > 0.55;
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }

    void drawFinder(double x, double y) {
      final outer = Rect.fromLTWH(x, y, cellSize * 3, cellSize * 3);
      canvas.drawRect(outer, paint);
      final inner = Rect.fromLTWH(
        x + cellSize * 0.5,
        y + cellSize * 0.5,
        cellSize * 2,
        cellSize * 2,
      );
      canvas.drawRect(inner, bgPaint);
      final center = Rect.fromLTWH(
        x + cellSize,
        y + cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(center, paint);
    }

    drawFinder(0, 0);
    drawFinder(cellSize * 8, 0);
    drawFinder(0, cellSize * 8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
