import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

class _RecommendationChip {
  final String label;
  final IconData icon;
  final Color color;

  const _RecommendationChip({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ForYouItem {
  final String title;
  final String host;
  final String reason;
  final IconData icon;
  final List<Color> gradient;
  final int listeners;
  final bool isLive;

  const _ForYouItem({
    required this.title,
    required this.host,
    required this.reason,
    required this.icon,
    required this.gradient,
    required this.listeners,
    this.isLive = false,
  });
}

const _chips = [
  _RecommendationChip(
    label: 'لأنك تتابع الأدب',
    icon: Icons.auto_stories_rounded,
    color: BayanColors.accent,
  ),
  _RecommendationChip(
    label: 'رائج في منطقتك',
    icon: Icons.trending_up_rounded,
    color: Color(0xFFD4AF37),
  ),
  _RecommendationChip(
    label: 'أصدقاؤك يستمعون',
    icon: Icons.people_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _RecommendationChip(
    label: 'موضوعات جديدة',
    icon: Icons.explore_rounded,
    color: Color(0xFF2A6F97),
  ),
];

const _forYouItems = [
  _ForYouItem(
    title: 'ديوان الشعر المعاصر',
    host: 'عبدالله المطيري',
    reason: 'لأنك تتابع الأدب',
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFF5CBFAD), Color(0xFF2E1A3E)],
    listeners: 94,
    isLive: true,
  ),
  _ForYouItem(
    title: 'مستقبل التقنية في الخليج',
    host: 'سارة الفهد',
    reason: 'رائج في منطقتك',
    icon: Icons.memory_rounded,
    gradient: [Color(0xFF6C3FA0), Color(0xFF2E1A3E)],
    listeners: 156,
    isLive: true,
  ),
  _ForYouItem(
    title: 'صالون الفلسفة العربية',
    host: 'نورة الصباح',
    reason: 'أصدقاؤك يستمعون',
    icon: Icons.psychology_rounded,
    gradient: [Color(0xFF2A6F97), Color(0xFF2E1A3E)],
    listeners: 67,
  ),
  _ForYouItem(
    title: 'ريادة الأعمال للشباب',
    host: 'محمد الراشد',
    reason: 'موضوعات جديدة',
    icon: Icons.rocket_launch_rounded,
    gradient: [Color(0xFFD4AF37), Color(0xFF2E1A3E)],
    listeners: 112,
  ),
  _ForYouItem(
    title: 'ليالي الأنس والطرب',
    host: 'فهد العنزي',
    reason: 'لأنك تتابع الأدب',
    icon: Icons.music_note_rounded,
    gradient: [Color(0xFF8B5E3C), Color(0xFF2E1A3E)],
    listeners: 83,
  ),
];

class ForYouFeed extends StatefulWidget {
  const ForYouFeed({super.key});

  @override
  State<ForYouFeed> createState() => _ForYouFeedState();
}

class _ForYouFeedState extends State<ForYouFeed> {
  int _selectedChip = 0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildChips()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _ForYouCard(item: _forYouItems[index], index: index);
            }, childCount: _forYouItems.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final chip = _chips[index];
            final isSelected = _selectedChip == index;
            return HapticButton(
              hapticType: HapticFeedbackType.selection,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedChip = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? chip.color.withValues(alpha: 0.15)
                      : BayanColors.glassBackground,
                  border: Border.all(
                    color: isSelected
                        ? chip.color.withValues(alpha: 0.4)
                        : BayanColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 14,
                      color: isSelected
                          ? chip.color
                          : BayanColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? chip.color
                            : BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ForYouCard extends StatefulWidget {
  final _ForYouItem item;
  final int index;

  const _ForYouCard({required this.item, required this.index});

  @override
  State<_ForYouCard> createState() => _ForYouCardState();
}

class _ForYouCardState extends State<_ForYouCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100 + widget.index * 80), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: _visible ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: HapticButton(
            onTap: () => HapticFeedback.mediumImpact(),
            borderRadius: BorderRadius.circular(22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        widget.item.gradient[0].withValues(alpha: 0.25),
                        widget.item.gradient[1].withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: BayanColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.gradient[0].withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.item.reason,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.item.gradient[0],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: widget.item.gradient[0].withValues(
                                alpha: 0.2,
                              ),
                            ),
                            child: Icon(
                              widget.item.icon,
                              color: BayanColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: BayanColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.item.host,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: BayanColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.item.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: BayanColors.accent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: BayanColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PulsingDot(
                                    color: BayanColors.accent,
                                    size: 5,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'مباشر',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: BayanColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            size: 14,
                            color: BayanColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.item.listeners} مستمع',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: widget.item.isLive
                                  ? BayanColors.accent
                                  : BayanColors.textSecondary.withValues(
                                      alpha: 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.item.isLive ? 'انضم الآن' : 'تذكير',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.item.isLive
                                    ? BayanColors.background
                                    : BayanColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
