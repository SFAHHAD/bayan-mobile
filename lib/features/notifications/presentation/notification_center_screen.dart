import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

enum _NotifType { liveNow, newFollower, voiceMention }

class _NotificationData {
  final String id;
  final _NotifType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isUnread;

  const _NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isUnread = false,
  });

  Color get accentColor => switch (type) {
    _NotifType.liveNow => BayanColors.accent,
    _NotifType.newFollower => const Color(0xFF6C3FA0),
    _NotifType.voiceMention => const Color(0xFFD4AF37),
  };

  IconData get icon => switch (type) {
    _NotifType.liveNow => Icons.sensors_rounded,
    _NotifType.newFollower => Icons.person_add_rounded,
    _NotifType.voiceMention => Icons.record_voice_over_rounded,
  };

  String get typeLabel => switch (type) {
    _NotifType.liveNow => 'مباشر الآن',
    _NotifType.newFollower => 'متابع جديد',
    _NotifType.voiceMention => 'إشارة صوتية',
  };
}

const _placeholderNotifications = [
  _NotificationData(
    id: 'n1',
    type: _NotifType.liveNow,
    title: 'ديوان الشعر الحديث',
    subtitle: 'بدأ البث المباشر الآن — عبدالله المطيري يستضيف',
    timeAgo: 'الآن',
    isUnread: true,
  ),
  _NotificationData(
    id: 'n2',
    type: _NotifType.newFollower,
    title: 'سارة الفهد',
    subtitle: 'بدأت بمتابعتك',
    timeAgo: 'منذ ٥ دقائق',
    isUnread: true,
  ),
  _NotificationData(
    id: 'n3',
    type: _NotifType.voiceMention,
    title: 'فهد العنزي أشار إليك',
    subtitle: 'في "ديوان الأدب الكويتي" — مقطع عن الشعر النبطي',
    timeAgo: 'منذ ساعة',
    isUnread: true,
  ),
  _NotificationData(
    id: 'n4',
    type: _NotifType.liveNow,
    title: 'نقاشات تقنية',
    subtitle: 'ديوانيّة مباشرة — انضم الآن',
    timeAgo: 'منذ ساعتين',
  ),
  _NotificationData(
    id: 'n5',
    type: _NotifType.newFollower,
    title: 'نورة الصباح',
    subtitle: 'بدأت بمتابعتك',
    timeAgo: 'أمس',
  ),
  _NotificationData(
    id: 'n6',
    type: _NotifType.voiceMention,
    title: 'محمد الراشد ذكرك',
    subtitle: 'في مقطع "ريادة الأعمال في الخليج"',
    timeAgo: 'أمس',
  ),
  _NotificationData(
    id: 'n7',
    type: _NotifType.newFollower,
    title: 'خالد العتيبي',
    subtitle: 'بدأ بمتابعتك',
    timeAgo: 'منذ يومين',
  ),
];

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _placeholderNotifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = _placeholderNotifications[index];
                      return _buildAnimatedTile(notif, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BayanColors.accent.withValues(alpha: 0.06),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الإشعارات',
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () {},
            child: GlassmorphicContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              blur: 10,
              child: const Icon(
                Icons.done_all_rounded,
                color: BayanColors.accent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          HapticButton(
            onTap: () => Navigator.of(context).pop(),
            child: GlassmorphicContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              blur: 10,
              child: const Icon(
                Icons.close_rounded,
                color: BayanColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTile(_NotificationData notif, int index) {
    final start = (index * 0.08).clamp(0.0, 0.5);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final curve = CurveTween(
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final value = curve.transform(_staggerController.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _NotificationTile(data: notif),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotificationData data;

  const _NotificationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () => HapticFeedback.selectionClick(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.isUnread
                  ? data.accentColor.withValues(alpha: 0.04)
                  : BayanColors.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.isUnread
                    ? data.accentColor.withValues(alpha: 0.2)
                    : BayanColors.glassBorder,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const SizedBox(width: 14),
                Expanded(child: _buildContent()),
                _buildTrailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.accentColor.withValues(alpha: 0.12),
        border: Border.all(color: data.accentColor.withValues(alpha: 0.2)),
      ),
      child: Icon(data.icon, color: data.accentColor, size: 20),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.type == _NotifType.liveNow) ...[
                    PulsingDot(color: data.accentColor, size: 4),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    data.typeLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: data.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          data.title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: data.isUnread ? FontWeight.w700 : FontWeight.w600,
            color: BayanColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          data.subtitle,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textSecondary,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          data.timeAgo,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: BayanColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        if (data.isUnread)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor,
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
