import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class PollOption {
  final String text;
  int votes;
  PollOption({required this.text, this.votes = 0});
}

class LivePollData {
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  LivePollData({required this.question, required this.options})
    : totalVotes = options.fold(0, (sum, o) => sum + o.votes);
}

void showCreatePollSheet(
  BuildContext context, {
  required ValueChanged<LivePollData> onCreated,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreatePollSheet(onCreated: onCreated),
  );
}

class _CreatePollSheet extends StatefulWidget {
  final ValueChanged<LivePollData> onCreated;
  const _CreatePollSheet({required this.onCreated});

  @override
  State<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<_CreatePollSheet> {
  final _questionController = TextEditingController();
  final _optionControllers = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 5) return;
    HapticFeedback.selectionClick();
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _submit() {
    if (_questionController.text.trim().isEmpty) return;
    final validOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => PollOption(text: c.text.trim()))
        .toList();
    if (validOptions.length < 2) return;
    HapticFeedback.heavyImpact();
    widget.onCreated(
      LivePollData(
        question: _questionController.text.trim(),
        options: validOptions,
      ),
    );
    Navigator.pop(context);
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
            color: BayanColors.surface.withValues(alpha: 0.95),
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
                    const Icon(
                      Icons.poll_rounded,
                      color: BayanColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تصويت جديد',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _questionController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: BayanColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب السؤال...',
                    hintStyle: GoogleFonts.cairo(
                      color: BayanColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.help_outline_rounded,
                      color: BayanColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._optionControllers.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: e.value,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: BayanColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'الخيار ${e.key + 1}',
                        hintStyle: GoogleFonts.cairo(
                          color: BayanColors.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_optionControllers.length < 5)
                  Align(
                    alignment: Alignment.centerRight,
                    child: HapticButton(
                      hapticType: HapticFeedbackType.selection,
                      onTap: _addOption,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: BayanColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إضافة خيار',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: BayanColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                HapticButton(
                  hapticType: HapticFeedbackType.heavy,
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BayanColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BayanColors.accent.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'إطلاق التصويت',
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
}

class LivePollOverlay extends StatefulWidget {
  final LivePollData poll;
  final VoidCallback onDismiss;
  const LivePollOverlay({
    super.key,
    required this.poll,
    required this.onDismiss,
  });

  @override
  State<LivePollOverlay> createState() => _LivePollOverlayState();
}

class _LivePollOverlayState extends State<LivePollOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;
  late LivePollData _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _vote(int index) {
    if (_selectedIndex != null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedIndex = index;
      _poll.options[index].votes += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _poll.options.fold(0, (int s, o) => s + o.votes);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _controller.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BayanColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.poll_rounded,
                        color: BayanColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _poll.question,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                      ),
                      HapticButton(
                        hapticType: HapticFeedbackType.selection,
                        onTap: widget.onDismiss,
                        child: const Icon(
                          Icons.close_rounded,
                          color: BayanColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_poll.options.length, (i) {
                    final option = _poll.options[i];
                    final pct = total > 0 ? option.votes / total : 0.0;
                    final isSelected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HapticButton(
                        hapticType: HapticFeedbackType.medium,
                        onTap: () => _vote(i),
                        child: Container(
                          height: 48,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: BayanColors.glassBackground,
                            border: Border.all(
                              color: isSelected
                                  ? BayanColors.accent.withValues(alpha: 0.5)
                                  : BayanColors.glassBorder,
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                widthFactor: _selectedIndex != null ? pct : 0.0,
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13),
                                    color: isSelected
                                        ? BayanColors.accent.withValues(
                                            alpha: 0.2,
                                          )
                                        : BayanColors.accent.withValues(
                                            alpha: 0.08,
                                          ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? BayanColors.accent
                                              : BayanColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (_selectedIndex != null)
                                      Text(
                                        '${(pct * 100).round()}%',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? BayanColors.accent
                                              : BayanColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_selectedIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$total صوت',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.textSecondary,
                        ),
                      ),
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
