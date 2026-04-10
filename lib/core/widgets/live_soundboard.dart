import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _SoundEffect {
  final String label;
  final IconData icon;
  final Color color;

  const _SoundEffect({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _soundEffects = [
  _SoundEffect(
    label: 'تصفيق',
    icon: Icons.back_hand_rounded,
    color: Color(0xFFD4AF37),
  ),
  _SoundEffect(
    label: 'ترحيب',
    icon: Icons.waving_hand_rounded,
    color: BayanColors.accent,
  ),
  _SoundEffect(
    label: 'مقدمة',
    icon: Icons.music_note_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _SoundEffect(
    label: 'إعجاب',
    icon: Icons.thumb_up_rounded,
    color: Color(0xFF2A6F97),
  ),
  _SoundEffect(
    label: 'جرس',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFFD4AF37),
  ),
  _SoundEffect(
    label: 'ختام',
    icon: Icons.celebration_rounded,
    color: BayanColors.accent,
  ),
  _SoundEffect(
    label: 'صمت',
    icon: Icons.volume_off_rounded,
    color: Color(0xFF8B5E3C),
  ),
  _SoundEffect(
    label: 'درامي',
    icon: Icons.theater_comedy_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _SoundEffect(
    label: 'تنبيه',
    icon: Icons.campaign_rounded,
    color: Color(0xFFD4AF37),
  ),
];

void showSoundboard(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SoundboardSheet(),
  );
}

class _SoundboardSheet extends StatefulWidget {
  const _SoundboardSheet();

  @override
  State<_SoundboardSheet> createState() => _SoundboardSheetState();
}

class _SoundboardSheetState extends State<_SoundboardSheet> {
  int? _activeIndex;

  void _playSfx(int index) {
    HapticFeedback.heavyImpact();
    setState(() => _activeIndex = index);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _activeIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
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
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BayanColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Semantics(
                      label: 'لوحة المؤثرات الصوتية',
                      child: const Icon(
                        Icons.surround_sound_rounded,
                        color: BayanColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'المؤثرات الصوتية',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _soundEffects.length,
                  itemBuilder: (context, i) {
                    final sfx = _soundEffects[i];
                    final isActive = _activeIndex == i;
                    return HapticButton(
                      hapticType: HapticFeedbackType.heavy,
                      onTap: () => _playSfx(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isActive
                              ? sfx.color.withValues(alpha: 0.2)
                              : BayanColors.glassBackground,
                          border: Border.all(
                            color: isActive
                                ? sfx.color.withValues(alpha: 0.5)
                                : BayanColors.glassBorder,
                            width: isActive ? 1.5 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: sfx.color.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isActive ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Semantics(
                                label: sfx.label,
                                child: Icon(
                                  sfx.icon,
                                  color: sfx.color,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sfx.label,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: BayanColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
