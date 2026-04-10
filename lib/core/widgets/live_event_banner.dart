import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

class LiveEventBanner extends StatefulWidget {
  final String diwanName;
  final String hostName;
  final VoidCallback onJoin;
  final VoidCallback onDismiss;

  const LiveEventBanner({
    super.key,
    required this.diwanName,
    required this.hostName,
    required this.onJoin,
    required this.onDismiss,
  });

  @override
  State<LiveEventBanner> createState() => _LiveEventBannerState();
}

class _LiveEventBannerState extends State<LiveEventBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 8,
            16,
            0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: BayanColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: BayanColors.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BayanColors.accent.withValues(alpha: 0.12),
                      ),
                      child: const Center(
                        child: PulsingDot(color: BayanColors.accent, size: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.diwanName,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.hostName} · مباشر الآن',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: BayanColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onJoin();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: BayanColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'انضم',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.background,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: dismiss,
                      child: const Icon(
                        Icons.close_rounded,
                        color: BayanColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}

const _activityLog = [
  _ActivityItem(
    title: 'انضممت إلى ديوان الشعر الحديث',
    time: 'منذ ساعة',
    icon: Icons.login_rounded,
    color: BayanColors.accent,
  ),
  _ActivityItem(
    title: 'أرسلت هدية ريشة ذهبية لسارة الفهد',
    time: 'منذ ٣ ساعات',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFFD4AF37),
  ),
  _ActivityItem(
    title: 'تابعت فهد العنزي',
    time: 'منذ ٥ ساعات',
    icon: Icons.person_add_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _ActivityItem(
    title: 'اشتريت تذكرة ملتقى الشعر الخليجي',
    time: 'أمس ٩:٠٠ م',
    icon: Icons.confirmation_num_rounded,
    color: BayanColors.accent,
  ),
  _ActivityItem(
    title: 'رفعت يدك في ديوان الأدب الكويتي',
    time: 'أمس ٨:٣٠ م',
    icon: Icons.back_hand_rounded,
    color: Color(0xFFD4AF37),
  ),
  _ActivityItem(
    title: 'صوّت في استطلاع مستقبل التقنية',
    time: 'أمس ٧:١٥ م',
    icon: Icons.poll_rounded,
    color: Color(0xFF2A6F97),
  ),
  _ActivityItem(
    title: 'غادرت ديوان ريادة الأعمال',
    time: '٧ أبريل',
    icon: Icons.logout_rounded,
    color: BayanColors.textSecondary,
  ),
];

void showActivityHistory(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ActivityHistorySheet(),
  );
}

class _ActivityHistorySheet extends StatelessWidget {
  const _ActivityHistorySheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      Icons.history_rounded,
                      color: BayanColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'سجل النشاط',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: _activityLog.length,
                  itemBuilder: (context, index) {
                    final item = _activityLog[index];
                    final isLast = index == _activityLog.length - 1;
                    return _ActivityTile(item: item, isLast: isLast);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;

  const _ActivityTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.12),
              ),
              child: Icon(item.icon, color: item.color, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: BayanColors.glassBorder.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
