import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class ParticipantInfo {
  final String name;
  final String initial;
  final bool isSpeaker;
  final bool isMuted;

  const ParticipantInfo({
    required this.name,
    required this.initial,
    this.isSpeaker = false,
    this.isMuted = false,
  });
}

Future<void> showHostControlPanel(
  BuildContext context, {
  required List<ParticipantInfo> participants,
  required bool isRoomLocked,
  required ValueChanged<bool> onLockChanged,
  required VoidCallback onMuteAll,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HostControlSheet(
      participants: participants,
      isRoomLocked: isRoomLocked,
      onLockChanged: onLockChanged,
      onMuteAll: onMuteAll,
    ),
  );
}

class _HostControlSheet extends StatefulWidget {
  final List<ParticipantInfo> participants;
  final bool isRoomLocked;
  final ValueChanged<bool> onLockChanged;
  final VoidCallback onMuteAll;

  const _HostControlSheet({
    required this.participants,
    required this.isRoomLocked,
    required this.onLockChanged,
    required this.onMuteAll,
  });

  @override
  State<_HostControlSheet> createState() => _HostControlSheetState();
}

class _HostControlSheetState extends State<_HostControlSheet> {
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isRoomLocked;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, 16 + bottom),
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
              _buildHeader(),
              const SizedBox(height: 20),
              _buildRoomControls(),
              const SizedBox(height: 20),
              _buildParticipantHeader(),
              const SizedBox(height: 12),
              Flexible(child: _buildParticipantList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [BayanColors.accent, BayanColors.accentLight],
            ),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: BayanColors.background,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة التحكم',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.textPrimary,
                ),
              ),
              Text(
                'إدارة المشاركين والصلاحيات',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: BayanColors.textSecondary,
                ),
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
    );
  }

  Widget _buildRoomControls() {
    return GlassmorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _ControlToggle(
            icon: _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            label: 'قفل الغرفة',
            subtitle: _isLocked
                ? 'الغرفة مقفلة — لا يمكن لأحد الانضمام'
                : 'الغرفة مفتوحة للجميع',
            isActive: _isLocked,
            activeColor: const Color(0xFFD4AF37),
            onToggle: (val) {
              HapticFeedback.mediumImpact();
              setState(() => _isLocked = val);
              widget.onLockChanged(val);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: BayanColors.glassBorder.withValues(alpha: 0.3),
            ),
          ),
          _ControlToggleButton(
            icon: Icons.volume_off_rounded,
            label: 'كتم الكل',
            subtitle: 'كتم جميع المتحدثين مؤقتاً',
            color: Colors.redAccent,
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onMuteAll();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantHeader() {
    return Row(
      children: [
        Text(
          'المشاركون',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BayanColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${widget.participants.length}',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BayanColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantList() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: widget.participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _ParticipantTile(participant: widget.participants[index]);
      },
    );
  }
}

class _ControlToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isActive;
  final Color activeColor;
  final ValueChanged<bool> onToggle;

  const _ControlToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.activeColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? activeColor : BayanColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
            value: isActive,
            onChanged: onToggle,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.3),
            inactiveTrackColor: BayanColors.glassBackground,
            inactiveThumbColor: BayanColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ControlToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ControlToggleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.heavy,
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.chevron_left_rounded,
              color: color.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantInfo participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
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
                    participant.initial,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      participant.isSpeaker ? 'متحدث' : 'مستمع',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: participant.isSpeaker
                            ? BayanColors.accent
                            : BayanColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ActionButton(
                icon: Icons.mic_rounded,
                tooltip: 'ترقية لمتحدث',
                color: BayanColors.accent,
                onTap: () => HapticFeedback.mediumImpact(),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: Icons.person_remove_rounded,
                tooltip: 'إخراج',
                color: Colors.redAccent,
                onTap: () => HapticFeedback.heavyImpact(),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: Icons.block_rounded,
                tooltip: 'حظر',
                color: const Color(0xFF8B0000),
                onTap: () => HapticFeedback.heavyImpact(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
