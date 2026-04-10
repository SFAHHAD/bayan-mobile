import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';
import 'package:bayan/core/widgets/speaking_avatar.dart';
import 'package:bayan/core/widgets/host_control_panel.dart';
import 'package:bayan/core/widgets/share_diwan_sheet.dart';

enum StageRole { host, speaker, listener }

class _StageMember {
  final String name;
  final String initial;
  final StageRole role;
  final bool isSpeaking;
  final bool isMuted;

  const _StageMember({
    required this.name,
    required this.initial,
    required this.role,
    this.isSpeaking = false,
    this.isMuted = false,
  });
}

const _placeholderSpeakers = [
  _StageMember(
    name: 'عبدالله المطيري',
    initial: 'ع',
    role: StageRole.host,
    isSpeaking: true,
  ),
  _StageMember(
    name: 'سارة الفهد',
    initial: 'س',
    role: StageRole.speaker,
    isSpeaking: false,
    isMuted: true,
  ),
  _StageMember(
    name: 'فهد العنزي',
    initial: 'ف',
    role: StageRole.speaker,
    isSpeaking: true,
  ),
  _StageMember(
    name: 'نورة الصباح',
    initial: 'ن',
    role: StageRole.speaker,
    isSpeaking: false,
  ),
];

const _placeholderListeners = [
  _StageMember(name: 'محمد الراشد', initial: 'م', role: StageRole.listener),
  _StageMember(name: 'خالد العتيبي', initial: 'خ', role: StageRole.listener),
  _StageMember(name: 'هند الشمري', initial: 'ه', role: StageRole.listener),
  _StageMember(name: 'يوسف الكندري', initial: 'ي', role: StageRole.listener),
  _StageMember(name: 'لطيفة المطر', initial: 'ل', role: StageRole.listener),
  _StageMember(name: 'أحمد الحربي', initial: 'أ', role: StageRole.listener),
  _StageMember(name: 'دانة العجمي', initial: 'د', role: StageRole.listener),
  _StageMember(name: 'بدر السالم', initial: 'ب', role: StageRole.listener),
];

class DiwanStageScreen extends StatefulWidget {
  final String diwanName;
  final String hostName;
  final StageRole currentUserRole;
  final bool isWaitingForHost;

  const DiwanStageScreen({
    super.key,
    required this.diwanName,
    required this.hostName,
    this.currentUserRole = StageRole.listener,
    this.isWaitingForHost = false,
  });

  @override
  State<DiwanStageScreen> createState() => _DiwanStageScreenState();
}

class _DiwanStageScreenState extends State<DiwanStageScreen> {
  bool _isMicOn = false;
  bool _isHandRaised = false;
  bool _showEmojis = false;
  bool _isRoomLocked = false;

  final _emojis = ['👏', '🔥', '❤️', '😂', '💡', '✨'];

  void _openHostPanel() {
    HapticFeedback.mediumImpact();
    final participants = [
      ..._placeholderSpeakers.map(
        (m) => ParticipantInfo(
          name: m.name,
          initial: m.initial,
          isSpeaker: true,
          isMuted: m.isMuted,
        ),
      ),
      ..._placeholderListeners.map(
        (m) => ParticipantInfo(name: m.name, initial: m.initial),
      ),
    ];
    showHostControlPanel(
      context,
      participants: participants,
      isRoomLocked: _isRoomLocked,
      onLockChanged: (val) => setState(() => _isRoomLocked = val),
      onMuteAll: () {},
    );
  }

  void _openShareSheet() {
    HapticFeedback.selectionClick();
    showShareDiwanSheet(
      context,
      diwanName: widget.diwanName,
      hostName: widget.hostName,
      listenerCount: _placeholderSpeakers.length + _placeholderListeners.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWaitingForHost) return _buildWaitingState(context);

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildGradientBg(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSpeakersGrid(),
                        const SizedBox(height: 28),
                        _buildListenersSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildControlBar(context),
          if (_showEmojis) _buildEmojiTray(),
        ],
      ),
    );
  }

  Widget _buildGradientBg() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BayanColors.accent.withValues(alpha: 0.08),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BayanColors.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PulsingDot(color: BayanColors.accent, size: 5),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.diwanName,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BayanColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_placeholderSpeakers.length + _placeholderListeners.length} مشارك',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                HapticButton(
                  hapticType: HapticFeedbackType.selection,
                  onTap: _openShareSheet,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.glassBackground,
                      border: Border.all(color: BayanColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: BayanColors.accent,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HapticButton(
                  hapticType: HapticFeedbackType.medium,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'غادر بهدوء',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent.withValues(alpha: 0.9),
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

  Widget _buildSpeakersGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 16),
            child: Text(
              'المتحدثون',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: _placeholderSpeakers.map((member) {
              return SizedBox(
                width: 100,
                child: Column(
                  children: [
                    SpeakingAvatar(
                      initial: member.initial,
                      size: 68,
                      isSpeaking: member.isSpeaking,
                      isMuted: member.isMuted,
                      isHost: member.role == StageRole.host,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      member.name.split(' ').first,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: member.isSpeaking
                            ? BayanColors.textPrimary
                            : BayanColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListenersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'المستمعون',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: BayanColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_placeholderListeners.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: _placeholderListeners.map((member) {
                return SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BayanColors.surface,
                          border: Border.all(color: BayanColors.glassBorder),
                        ),
                        child: Center(
                          child: Text(
                            member.initial,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.name.split(' ').first,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: BayanColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    final isHostOrSpeaker = widget.currentUserRole != StageRole.listener;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: BayanColors.background.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: BayanColors.glassBorder.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isHostOrSpeaker)
                  _ControlButton(
                    icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: _isMicOn ? 'الميكروفون' : 'صامت',
                    isActive: _isMicOn,
                    activeColor: BayanColors.accent,
                    inactiveColor: Colors.redAccent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isMicOn = !_isMicOn);
                    },
                  ),
                if (!isHostOrSpeaker)
                  _ControlButton(
                    icon: _isHandRaised
                        ? Icons.back_hand_rounded
                        : Icons.back_hand_outlined,
                    label: _isHandRaised ? 'مرفوعة' : 'ارفع يدك',
                    isActive: _isHandRaised,
                    activeColor: const Color(0xFFD4AF37),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isHandRaised = !_isHandRaised);
                    },
                  ),
                _ControlButton(
                  icon: Icons.emoji_emotions_rounded,
                  label: 'تفاعل',
                  isActive: _showEmojis,
                  activeColor: const Color(0xFFD4AF37),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showEmojis = !_showEmojis);
                  },
                ),
                if (widget.currentUserRole == StageRole.host)
                  _ControlButton(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'إدارة',
                    isActive: false,
                    activeColor: const Color(0xFFD4AF37),
                    onTap: _openHostPanel,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiTray() {
    return Positioned(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
      left: 40,
      right: 40,
      child: GlassmorphicContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _emojis.map((emoji) {
            return HapticButton(
              hapticType: HapticFeedbackType.light,
              onTap: () {
                setState(() => _showEmojis = false);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  HapticButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: GlassmorphicContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(10),
                      blur: 10,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: BayanColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Shimmer.fromColors(
              baseColor: BayanColors.surface,
              highlightColor: BayanColors.accent.withValues(alpha: 0.15),
              period: const Duration(milliseconds: 2400),
              child: GlassmorphicContainer(
                borderRadius: 36,
                padding: const EdgeInsets.all(28),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 56,
                  color: BayanColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'في انتظار المضيف',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.diwanName,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: BayanColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Shimmer.fromColors(
              baseColor: BayanColors.textSecondary.withValues(alpha: 0.5),
              highlightColor: BayanColors.textSecondary,
              period: const Duration(milliseconds: 2000),
              child: Text(
                'سيبدأ المجلس قريباً...',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: _buildWaitingSkeleton(),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingSkeleton() {
    return Shimmer.fromColors(
      baseColor: BayanColors.surface,
      highlightColor: BayanColors.surface.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BayanColors.surface.withValues(alpha: 0.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color? inactiveColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? activeColor
        : inactiveColor ?? BayanColors.textSecondary;

    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : inactiveColor != null
                  ? inactiveColor!.withValues(alpha: 0.12)
                  : BayanColors.glassBackground,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
