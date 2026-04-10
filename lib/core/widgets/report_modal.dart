import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _ReportReason {
  final String label;
  final IconData icon;
  const _ReportReason({required this.label, required this.icon});
}

const _reasons = [
  _ReportReason(
    label: 'محتوى مسيء أو مخالف',
    icon: Icons.report_gmailerrorred_rounded,
  ),
  _ReportReason(
    label: 'خطاب كراهية أو تمييز',
    icon: Icons.do_not_disturb_alt_rounded,
  ),
  _ReportReason(label: 'معلومات مضللة', icon: Icons.info_outline_rounded),
  _ReportReason(label: 'تحرش أو تنمر', icon: Icons.warning_amber_rounded),
  _ReportReason(label: 'محتوى غير لائق', icon: Icons.visibility_off_rounded),
  _ReportReason(label: 'انتحال شخصية', icon: Icons.person_off_rounded),
  _ReportReason(label: 'أسباب أخرى', icon: Icons.more_horiz_rounded),
];

Future<String?> showReportModal(
  BuildContext context, {
  required String targetName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(targetName: targetName),
  );
}

class _ReportSheet extends StatefulWidget {
  final String targetName;
  const _ReportSheet({required this.targetName});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  int? _selectedIndex;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedIndex == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(_reasons[_selectedIndex!].label);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإبلاغ',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.targetName,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: BayanColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  HapticButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BayanColors.glassBackground,
                        border: Border.all(color: BayanColors.glassBorder),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: BayanColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._reasons.asMap().entries.map((entry) {
                final i = entry.key;
                final reason = entry.value;
                final isSelected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HapticButton(
                    hapticType: HapticFeedbackType.selection,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.redAccent.withValues(alpha: 0.08)
                            : BayanColors.glassBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.redAccent.withValues(alpha: 0.3)
                              : BayanColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            reason.icon,
                            size: 20,
                            color: isSelected
                                ? Colors.redAccent
                                : BayanColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reason.label,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? BayanColors.textPrimary
                                    : BayanColors.textSecondary,
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.redAccent
                                    : BayanColors.glassBorder,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              HapticButton(
                hapticType: HapticFeedbackType.heavy,
                onTap: _selectedIndex != null ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedIndex != null
                        ? Colors.redAccent
                        : Colors.redAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'إرسال البلاغ',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
  }
}

Future<bool?> showBlockConfirmation(
  BuildContext context, {
  required String userName,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _BlockDialog(userName: userName),
  );
}

class _BlockDialog extends StatelessWidget {
  final String userName;
  const _BlockDialog({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: BayanColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BayanColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'حظر $userName؟',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لن يتمكّن من رؤية ملفك الشخصي أو التفاعل معك. يمكنك إلغاء الحظر لاحقاً.',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: BayanColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: HapticButton(
                          hapticType: HapticFeedbackType.selection,
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: BayanColors.glassBackground,
                              border: Border.all(
                                color: BayanColors.glassBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
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
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.redAccent,
                            ),
                            child: Center(
                              child: Text(
                                'حظر',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
}
