import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class TicketData {
  final String diwanName;
  final String hostName;
  final String date;
  final String time;
  final int price;
  final String ticketId;

  const TicketData({
    required this.diwanName,
    required this.hostName,
    required this.date,
    required this.time,
    required this.price,
    required this.ticketId,
  });
}

void showPurchaseDialog(
  BuildContext context, {
  required TicketData ticket,
  required int userBalance,
  required VoidCallback onConfirm,
}) {
  HapticFeedback.mediumImpact();
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _PurchaseDialog(
      ticket: ticket,
      userBalance: userBalance,
      onConfirm: onConfirm,
    ),
  );
}

class _PurchaseDialog extends StatelessWidget {
  final TicketData ticket;
  final int userBalance;
  final VoidCallback onConfirm;

  const _PurchaseDialog({
    required this.ticket,
    required this.userBalance,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = userBalance >= ticket.price;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: BayanColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.accent.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.confirmation_num_rounded,
                      color: BayanColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'شراء تذكرة',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.diwanName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: BayanColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildRow(
                    'السعر',
                    '${ticket.price} توكن',
                    const Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    'رصيدك',
                    '$userBalance توكن',
                    canAfford ? BayanColors.accent : Colors.redAccent,
                  ),
                  if (!canAfford) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'رصيدك غير كافٍ',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: HapticButton(
                          hapticType: HapticFeedbackType.selection,
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BayanColors.glassBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: BayanColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HapticButton(
                          hapticType: HapticFeedbackType.heavy,
                          onTap: canAfford
                              ? () {
                                  onConfirm();
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? BayanColors.accent
                                  : BayanColors.glassBorder,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: canAfford
                                  ? [
                                      BoxShadow(
                                        color: BayanColors.accent.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'تأكيد الشراء',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: canAfford
                                      ? BayanColors.background
                                      : BayanColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BayanColors.glassBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumTicketCard extends StatefulWidget {
  final TicketData ticket;
  const PremiumTicketCard({super.key, required this.ticket});

  @override
  State<PremiumTicketCard> createState() => _PremiumTicketCardState();
}

class _PremiumTicketCardState extends State<PremiumTicketCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CustomPaint(
        painter: _PerforatedEdgePainter(),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BayanColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.confirmation_num_rounded,
                      color: BayanColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ticket.diwanName,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.ticket.hostName,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: BayanColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${widget.ticket.price} توكن',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: BayanColors.glassBorder.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetail(
                    Icons.calendar_today_rounded,
                    widget.ticket.date,
                  ),
                  const SizedBox(width: 20),
                  _buildDetail(Icons.access_time_rounded, widget.ticket.time),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم التذكرة',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: BayanColors.textSecondary,
                          ),
                        ),
                        Text(
                          widget.ticket.ticketId,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: BayanColors.accent.withValues(
                                alpha:
                                    0.15 +
                                    0.15 *
                                        math.sin(
                                          _glowController.value * math.pi * 2,
                                        ),
                              ),
                              blurRadius: 16,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      painter: _QrGlowPainter(),
                      size: const Size(52, 52),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: BayanColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PerforatedEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 10.0;
    const cornerRadius = 22.0;
    final notchY = size.height * 0.45;

    final path = Path();

    path.moveTo(cornerRadius, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    path.lineTo(size.width, notchY - notchRadius);
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: const Radius.circular(cornerRadius),
    );

    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    path.lineTo(0, notchY + notchRadius);
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );

    path.close();

    final bgPaint = Paint()..color = BayanColors.surface;
    canvas.drawPath(path, bgPaint);

    final borderPaint = Paint()
      ..color = BayanColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);

    final dashPaint = Paint()
      ..color = BayanColors.glassBorder.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashGap = 4.0;
    double x = 20;
    while (x < size.width - 20) {
      canvas.drawLine(
        Offset(x, notchY),
        Offset(x + dashWidth, notchY),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = BayanColors.glassBackground;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(bgRect, bgPaint);

    final borderPaint = Paint()
      ..color = BayanColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bgRect, borderPaint);

    final cellSize = size.width / 8;
    final paint = Paint()..color = BayanColors.accent;
    final pattern = [
      [1, 1, 1, 0, 0, 1, 1, 1],
      [1, 0, 1, 0, 1, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 1, 1],
      [0, 0, 0, 1, 0, 0, 0, 0],
      [0, 1, 1, 0, 1, 0, 1, 0],
      [1, 1, 1, 0, 0, 1, 1, 1],
      [1, 0, 1, 1, 0, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 1, 1],
    ];

    final offset = (size.width - cellSize * 8) / 2;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (pattern[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              offset + c * cellSize + 0.5,
              offset + r * cellSize + 0.5,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TicketWalletEmptyState extends StatelessWidget {
  const TicketWalletEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BayanColors.accent.withValues(alpha: 0.06),
              border: Border.all(
                color: BayanColors.accent.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.confirmation_num_outlined,
              size: 44,
              color: BayanColors.accent.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تذاكر بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تذاكر الديوانيّات المميزة ستظهر هنا',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: BayanColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'استكشف الديوانيّات',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
