import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

void showShareStory(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String hostName,
  String type = 'diwan',
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareStorySheet(
      title: title,
      subtitle: subtitle,
      hostName: hostName,
      type: type,
    ),
  );
}

class _ShareStorySheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hostName;
  final String type;

  const _ShareStorySheet({
    required this.title,
    required this.subtitle,
    required this.hostName,
    required this.type,
  });

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
                    const Icon(
                      Icons.share_rounded,
                      color: BayanColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'شارك في القصة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPreview(context),
              _buildShareOptions(context),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Center(
        child: Container(
          width: 220,
          height: 390,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
            ),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: BayanColors.accent.withValues(alpha: 0.1),
                blurRadius: 24,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [BayanColors.accent, Color(0xFFD4AF37)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BayanColors.accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    type == 'diwan'
                        ? Icons.auto_stories_rounded
                        : Icons.graphic_eq_rounded,
                    color: BayanColors.background,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: BayanColors.accent.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    hostName,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.accent,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: BayanColors.accent.withValues(alpha: 0.12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: BayanColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'استمع على بَيَان',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [BayanColors.accent, Color(0xFFD4AF37)],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: BayanColors.background,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'بَيَان',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ShareButton(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram',
            color: const Color(0xFFE4405F),
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Snapchat',
            color: const Color(0xFFFFFC00),
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareButton(
            icon: Icons.share_rounded,
            label: 'المزيد',
            color: BayanColors.textSecondary,
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareButton(
            icon: Icons.download_rounded,
            label: 'حفظ',
            color: BayanColors.accent,
            onTap: () => HapticFeedback.mediumImpact(),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: BayanColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
