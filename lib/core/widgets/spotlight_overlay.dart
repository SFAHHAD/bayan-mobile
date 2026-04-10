import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class SpotlightData {
  final String? pinnedMessage;
  final String? pinnedSpeakerName;
  final String? pinnedSpeakerInitial;

  const SpotlightData({
    this.pinnedMessage,
    this.pinnedSpeakerName,
    this.pinnedSpeakerInitial,
  });

  bool get hasPinnedMessage => pinnedMessage != null;
  bool get hasPinnedSpeaker => pinnedSpeakerName != null;
  bool get isEmpty => !hasPinnedMessage && !hasPinnedSpeaker;
}

class SpotlightOverlay extends StatefulWidget {
  final SpotlightData data;
  final bool isHost;
  final VoidCallback onDismiss;

  const SpotlightOverlay({
    super.key,
    required this.data,
    required this.isHost,
    required this.onDismiss,
  });

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, -12 * (1 - _controller.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    BayanColors.accent.withValues(alpha: 0.08),
                    BayanColors.surface.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.06),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BayanColors.accent.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.push_pin_rounded,
                          color: BayanColors.accent,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تثبيت المضيف',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
                      ),
                      const Spacer(),
                      if (widget.isHost)
                        HapticButton(
                          hapticType: HapticFeedbackType.selection,
                          onTap: widget.onDismiss,
                          child: const Icon(
                            Icons.close_rounded,
                            color: BayanColors.textSecondary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.data.hasPinnedSpeaker) _buildPinnedSpeaker(),
                  if (widget.data.hasPinnedMessage) _buildPinnedMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedSpeaker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: BayanColors.glassBackground,
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  BayanColors.accent.withValues(alpha: 0.3),
                  BayanColors.surface,
                ],
              ),
              border: Border.all(
                color: BayanColors.accent.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.data.pinnedSpeakerInitial ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.pinnedSpeakerName ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'يتحدث الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: BayanColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: BayanColors.glassBackground,
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: BayanColors.accent.withValues(alpha: 0.4),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.data.pinnedMessage ?? '',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: BayanColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSpotlightPicker(
  BuildContext context, {
  required List<String> speakerNames,
  required List<String> speakerInitials,
  required ValueChanged<SpotlightData> onPin,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SpotlightPickerSheet(
      speakerNames: speakerNames,
      speakerInitials: speakerInitials,
      onPin: onPin,
    ),
  );
}

class _SpotlightPickerSheet extends StatefulWidget {
  final List<String> speakerNames;
  final List<String> speakerInitials;
  final ValueChanged<SpotlightData> onPin;

  const _SpotlightPickerSheet({
    required this.speakerNames,
    required this.speakerInitials,
    required this.onPin,
  });

  @override
  State<_SpotlightPickerSheet> createState() => _SpotlightPickerSheetState();
}

class _SpotlightPickerSheetState extends State<_SpotlightPickerSheet> {
  final _messageController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _messageController.dispose();
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
            16,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    color: BayanColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تثبيت في المسرح',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTab(0, 'متحدث', Icons.person_rounded),
                  const SizedBox(width: 10),
                  _buildTab(1, 'رسالة', Icons.message_rounded),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedTab == 0) _buildSpeakerList(),
              if (_selectedTab == 1) _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: HapticButton(
        hapticType: HapticFeedbackType.selection,
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? BayanColors.accent.withValues(alpha: 0.12)
                : BayanColors.glassBackground,
            border: Border.all(
              color: isSelected
                  ? BayanColors.accent.withValues(alpha: 0.3)
                  : BayanColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? BayanColors.accent
                    : BayanColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
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

  Widget _buildSpeakerList() {
    return Column(
      children: List.generate(widget.speakerNames.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {
              widget.onPin(
                SpotlightData(
                  pinnedSpeakerName: widget.speakerNames[i],
                  pinnedSpeakerInitial: widget.speakerInitials[i],
                ),
              );
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: BayanColors.glassBackground,
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.surface,
                      border: Border.all(color: BayanColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(
                        widget.speakerInitials[i],
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.speakerNames[i],
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.push_pin_outlined,
                    color: BayanColors.accent,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      children: [
        TextField(
          controller: _messageController,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: BayanColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'اكتب الرسالة المثبتة...',
            hintStyle: GoogleFonts.cairo(color: BayanColors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        HapticButton(
          hapticType: HapticFeedbackType.medium,
          onTap: () {
            if (_messageController.text.trim().isEmpty) return;
            widget.onPin(
              SpotlightData(pinnedMessage: _messageController.text.trim()),
            );
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: BayanColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'تثبيت الرسالة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.background,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
