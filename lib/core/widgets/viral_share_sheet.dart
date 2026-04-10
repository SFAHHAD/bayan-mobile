import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

void showViralShareSheet(
  BuildContext context, {
  required String userName,
  required String handle,
  required double trustScore,
  bool isFounder = true,
  String diwanName = '',
}) {
  HapticFeedback.heavyImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ViralShareSheet(
      userName: userName,
      handle: handle,
      trustScore: trustScore,
      isFounder: isFounder,
      diwanName: diwanName,
    ),
  );
}

class _ViralShareSheet extends StatefulWidget {
  final String userName;
  final String handle;
  final double trustScore;
  final bool isFounder;
  final String diwanName;

  const _ViralShareSheet({
    required this.userName,
    required this.handle,
    required this.trustScore,
    required this.isFounder,
    required this.diwanName,
  });

  @override
  State<_ViralShareSheet> createState() => _ViralShareSheetState();
}

class _ViralShareSheetState extends State<_ViralShareSheet>
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
                      label: 'دعوة للديوان',
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Color(0xFFD4AF37),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ادعُ للمجلس',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildInviteCard(),
              const SizedBox(height: 16),
              _buildShareActions(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Center(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glow =
                (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
            return Container(
              width: 240,
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1035), Color(0xFF0A1628)],
                ),
                border: Border.all(
                  color: const Color(
                    0xFFD4AF37,
                  ).withValues(alpha: 0.25 + glow * 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFD4AF37,
                    ).withValues(alpha: 0.08 + glow * 0.06),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                _buildAvatar(),
                const SizedBox(height: 14),
                Text(
                  widget.userName,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.handle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.isFounder) _buildFounderBadge(),
                const SizedBox(height: 16),
                _buildMiniTrustMeter(),
                const Spacer(),
                if (widget.diwanName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: BayanColors.accent.withValues(alpha: 0.1),
                      border: Border.all(
                        color: BayanColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      widget.diwanName,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    gradient: const LinearGradient(
                      colors: [BayanColors.accent, Color(0xFFD4AF37)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BayanColors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'انضم لمجلسي',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/Bayan.JPG',
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'بيان',
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

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3FA0), BayanColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: BayanColors.accent.withValues(alpha: 0.2 + glow * 0.15),
                blurRadius: 14 + glow * 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: BayanColors.background,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildFounderBadge() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.5 + _glowController.value * 3, 0),
            end: Alignment(-0.5 + _glowController.value * 3, 0),
            colors: const [
              Color(0xFFD4AF37),
              Color(0xFFF5EDE0),
              Color(0xFFD4AF37),
            ],
          ).createShader(bounds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  const Color(0xFF8B5E3C).withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD4AF37),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'عضو مؤسس',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniTrustMeter() {
    final score = widget.trustScore;
    final scorePercent = (score * 100).round();
    final color = score >= 0.75
        ? BayanColors.accent
        : score >= 0.5
        ? const Color(0xFFD4AF37)
        : Colors.redAccent;
    return Column(
      children: [
        Text(
          'مؤشر الثقة',
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: BayanColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$scorePercent%',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildShareActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ShareBtn(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram',
            color: const Color(0xFFE4405F),
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareBtn(
            icon: Icons.chat_bubble_rounded,
            label: 'Snapchat',
            color: const Color(0xFFFFFC00),
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareBtn(
            icon: Icons.message_rounded,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ShareBtn(
            icon: Icons.link_rounded,
            label: 'نسخ الرابط',
            color: BayanColors.accent,
            onTap: () => HapticFeedback.heavyImpact(),
          ),
        ],
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareBtn({
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
              fontSize: 10,
              color: BayanColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
