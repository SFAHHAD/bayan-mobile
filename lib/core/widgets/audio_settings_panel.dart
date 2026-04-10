import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

void showAudioSettingsPanel(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AudioSettingsSheet(),
  );
}

class _AudioSettingsSheet extends StatefulWidget {
  const _AudioSettingsSheet();

  @override
  State<_AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<_AudioSettingsSheet> {
  bool _highFidelity = true;
  bool _noiseSuppression = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: BayanColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'إعدادات الصوت',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildToggle(
                icon: Icons.high_quality_rounded,
                label: 'جودة صوت عالية',
                subtitle: 'High Fidelity Audio',
                value: _highFidelity,
                color: BayanColors.accent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _highFidelity = v);
                },
              ),
              const SizedBox(height: 14),
              _buildToggle(
                icon: Icons.noise_aware_rounded,
                label: 'كتم الضوضاء',
                subtitle: 'Noise Suppression',
                value: _noiseSuppression,
                color: const Color(0xFF6C3FA0),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _noiseSuppression = v);
                },
              ),
              const SizedBox(height: 14),
              _buildEncryptionStatus(),
              const SizedBox(height: 20),
              _buildVolumeSlider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: BayanColors.glassBackground,
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color.withValues(alpha: 0.3),
            activeThumbColor: color,
            inactiveTrackColor: BayanColors.glassBorder,
            inactiveThumbColor: BayanColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: BayanColors.glassBackground,
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  const Color(0xFFD4AF37).withValues(alpha: 0.06),
                ],
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFD4AF37),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التشفير الشامل',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'E2E Encryption',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFD4AF37),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'مفعّل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: BayanColors.glassBackground,
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: BayanColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مستوى الصوت',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: BayanColors.accent,
              inactiveTrackColor: BayanColors.glassBorder,
              thumbColor: BayanColors.accent,
              overlayColor: BayanColors.accent.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: 0.75,
              onChanged: (_) => HapticFeedback.selectionClick(),
            ),
          ),
        ],
      ),
    );
  }
}
