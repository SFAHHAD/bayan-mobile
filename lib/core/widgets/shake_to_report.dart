import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _FeedbackOption {
  final String label;
  final IconData icon;
  final Color color;

  const _FeedbackOption({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _feedbackOptions = [
  _FeedbackOption(
    label: 'مشكلة تقنية',
    icon: Icons.bug_report_rounded,
    color: Colors.orangeAccent,
  ),
  _FeedbackOption(
    label: 'اقتراح تحسين',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFD4AF37),
  ),
  _FeedbackOption(
    label: 'محتوى مخالف',
    icon: Icons.flag_rounded,
    color: Colors.redAccent,
  ),
  _FeedbackOption(
    label: 'مشكلة في الصوت',
    icon: Icons.volume_off_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _FeedbackOption(
    label: 'أداء بطيء',
    icon: Icons.speed_rounded,
    color: Color(0xFF2A6F97),
  ),
  _FeedbackOption(
    label: 'شيء آخر',
    icon: Icons.more_horiz_rounded,
    color: BayanColors.textSecondary,
  ),
];

void showShakeReport(BuildContext context) {
  HapticFeedback.heavyImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'تقرير هز الجهاز',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => const _ShakeReportOverlay(),
    transitionBuilder: (context, animation, _, child) {
      final scale = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final opacity = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: opacity,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _ShakeReportOverlay extends StatefulWidget {
  const _ShakeReportOverlay();

  @override
  State<_ShakeReportOverlay> createState() => _ShakeReportOverlayState();
}

class _ShakeReportOverlayState extends State<_ShakeReportOverlay> {
  int? _selectedOption;
  final _detailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: BayanColors.surface.withValues(alpha: 0.95),
                border: Border.all(color: BayanColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.08),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: _submitted ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildOptions(),
          if (_selectedOption != null) ...[
            const SizedBox(height: 16),
            _buildDetailInput(),
          ],
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                BayanColors.accent.withValues(alpha: 0.15),
                const Color(0xFF6C3FA0).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: const Icon(
            Icons.vibration_rounded,
            color: BayanColors.accent,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'كيف يمكننا المساعدة؟',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BayanColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'هزّيت الجهاز — نحن هنا لمساعدتك',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _feedbackOptions.asMap().entries.map((e) {
        final i = e.key;
        final opt = e.value;
        final isSelected = _selectedOption == i;
        return HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedOption = isSelected ? null : i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? opt.color.withValues(alpha: 0.12)
                  : BayanColors.glassBackground,
              border: Border.all(
                color: isSelected
                    ? opt.color.withValues(alpha: 0.4)
                    : BayanColors.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.icon,
                  color: isSelected ? opt.color : BayanColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? opt.color : BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailInput() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: BayanColors.glassBackground,
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: TextField(
              controller: _detailController,
              maxLines: 3,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: BayanColors.textPrimary,
              ),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'أخبرنا بالتفاصيل (اختياري)...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  color: BayanColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasSelection = _selectedOption != null;
    return HapticButton(
      hapticType: HapticFeedbackType.heavy,
      onTap: hasSelection
          ? () {
              HapticFeedback.heavyImpact();
              setState(() => _submitted = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.of(context).pop();
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: hasSelection ? BayanColors.accent : BayanColors.glassBorder,
        ),
        child: Center(
          child: Text(
            'إرسال الملاحظة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasSelection
                  ? BayanColors.background
                  : BayanColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BayanColors.accent.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: BayanColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'شكراً لك!',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ملاحظتك تساعدنا في تحسين بيان',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
