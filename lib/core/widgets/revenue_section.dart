import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

void showWithdrawSheet(BuildContext context) {
  HapticFeedback.heavyImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WithdrawSheet(),
  );
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'bank';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: BayanColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BayanColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFFD4AF37),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'سحب التوكنات',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: BayanColors.glassBackground,
                    border: Border.all(color: BayanColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'الرصيد المتاح',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '٣,٧٥٠ توكن',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل المبلغ',
                    hintStyle: GoogleFonts.cairo(
                      color: BayanColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.toll_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    suffixText: 'توكن',
                    suffixStyle: GoogleFonts.cairo(
                      fontSize: 13,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMethodOption(
                      'bank',
                      Icons.account_balance_rounded,
                      'تحويل بنكي',
                    ),
                    const SizedBox(width: 10),
                    _buildMethodOption(
                      'wallet',
                      Icons.wallet_rounded,
                      'محفظة رقمية',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                HapticButton(
                  hapticType: HapticFeedbackType.heavy,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8960F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'تأكيد السحب',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String value, IconData icon, String label) {
    final isSelected = _selectedMethod == value;
    return Expanded(
      child: HapticButton(
        hapticType: HapticFeedbackType.selection,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedMethod = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? BayanColors.accent.withValues(alpha: 0.1)
                : BayanColors.glassBackground,
            border: Border.all(
              color: isSelected
                  ? BayanColors.accent.withValues(alpha: 0.4)
                  : BayanColors.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? BayanColors.accent
                    : BayanColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? BayanColors.accent
                      : BayanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RevenueSection extends StatelessWidget {
  const RevenueSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRevenueHeader(context),
        const SizedBox(height: 16),
        _buildRevenueChart(),
        const SizedBox(height: 16),
        _buildRevenueBreakdown(),
      ],
    );
  }

  Widget _buildRevenueHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إجمالي الإيرادات',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: BayanColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: BayanColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+٢٣٪',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '٣,٧٥٠',
                    style: GoogleFonts.cairo(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'توكن',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                  const Spacer(),
                  HapticButton(
                    hapticType: HapticFeedbackType.heavy,
                    onTap: () => showWithdrawSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8960F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: BayanColors.background,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'سحب',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.background,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRevenueChart() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الإيرادات اليومية',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'آخر ٧ أيام',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: _RevenueBarPainter(
                    ticketData: const [120, 85, 200, 160, 90, 250, 180],
                    giftData: const [60, 45, 100, 80, 55, 120, 90],
                    labels: const ['س', 'أ', 'إ', 'ث', 'أ', 'خ', 'ج'],
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend('تذاكر', BayanColors.accent),
                  const SizedBox(width: 20),
                  _buildLegend('هدايا', const Color(0xFFD4AF37)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown() {
    return GlassmorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _breakdownRow(
            'إيرادات التذاكر',
            '٢,١٥٠',
            BayanColors.accent,
            Icons.confirmation_num_rounded,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: BayanColors.glassBorder.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _breakdownRow(
            'إيرادات الهدايا',
            '١,٦٠٠',
            const Color(0xFFD4AF37),
            Icons.card_giftcard_rounded,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textPrimary,
            ),
          ),
        ),
        Text(
          '$value توكن',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RevenueBarPainter extends CustomPainter {
  final List<int> ticketData;
  final List<int> giftData;
  final List<String> labels;

  _RevenueBarPainter({
    required this.ticketData,
    required this.giftData,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - 24;
    final barGroupW = size.width / (ticketData.length * 2 + 1);
    final spacing = barGroupW;
    final singleBarW = barGroupW * 0.45;

    final allValues = [...ticketData, ...giftData];
    final maxVal = allValues.reduce(math.max).toDouble();

    final gridPaint = Paint()
      ..color = BayanColors.glassBorder.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;
    for (var i = 0; i < 4; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < ticketData.length; i++) {
      final x = spacing + i * (barGroupW + spacing);

      final tH = (ticketData[i] / maxVal) * chartH * 0.9;
      final tRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, chartH - tH, singleBarW, tH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      final tPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BayanColors.accent,
            BayanColors.accent.withValues(alpha: 0.4),
          ],
        ).createShader(tRect.outerRect);
      canvas.drawRRect(tRect, tPaint);

      final gH = (giftData[i] / maxVal) * chartH * 0.9;
      final gRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x + singleBarW + 2, chartH - gH, singleBarW, gH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      final gPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD4AF37),
            const Color(0xFFD4AF37).withValues(alpha: 0.4),
          ],
        ).createShader(gRect.outerRect);
      canvas.drawRRect(gRect, gPaint);

      final textStyle = TextStyle(
        color: BayanColors.textSecondary,
        fontSize: 10,
        fontFamily: 'Cairo',
      );
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(x + barGroupW / 2 - tp.width / 2, chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
