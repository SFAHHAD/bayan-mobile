import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';

class _DiwanData {
  final String name;
  final String host;
  final int voiceCount;
  final int listenerCount;
  final bool isLive;
  final List<Color> gradientColors;

  const _DiwanData({
    required this.name,
    required this.host,
    required this.voiceCount,
    required this.listenerCount,
    required this.isLive,
    required this.gradientColors,
  });
}

final _placeholderDiwans = [
  _DiwanData(
    name: 'ديوان الشعر الحديث',
    host: 'عبدالله المطيري',
    voiceCount: 14,
    listenerCount: 87,
    isLive: true,
    gradientColors: [
      BayanColors.accent.withValues(alpha: 0.3),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    name: 'نقاشات تقنية',
    host: 'سارة الفهد',
    voiceCount: 8,
    listenerCount: 124,
    isLive: true,
    gradientColors: [
      const Color(0xFF6C3FA0).withValues(alpha: 0.4),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    name: 'ديوان الأدب الكويتي',
    host: 'فهد العنزي',
    voiceCount: 22,
    listenerCount: 203,
    isLive: true,
    gradientColors: [
      const Color(0xFF2A6F97).withValues(alpha: 0.4),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    name: 'صالون الفكر العربي',
    host: 'نورة الصباح',
    voiceCount: 6,
    listenerCount: 56,
    isLive: false,
    gradientColors: [
      const Color(0xFF8B5E3C).withValues(alpha: 0.3),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    name: 'ديوان ريادة الأعمال',
    host: 'محمد الراشد',
    voiceCount: 11,
    listenerCount: 142,
    isLive: false,
    gradientColors: [
      BayanColors.accent.withValues(alpha: 0.2),
      const Color(0xFF6C3FA0).withValues(alpha: 0.2),
    ],
  ),
];

class DiwanFeedScreen extends StatefulWidget {
  const DiwanFeedScreen({super.key});

  @override
  State<DiwanFeedScreen> createState() => _DiwanFeedScreenState();
}

class _DiwanFeedScreenState extends State<DiwanFeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + _placeholderDiwans.length * 150),
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildLiveIndicator()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final interval = _staggerInterval(index);
                  return AnimatedBuilder(
                    animation: _staggerController,
                    builder: (context, child) {
                      final value = interval.transform(
                        _staggerController.value.clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DiwanCard(diwan: _placeholderDiwans[index]),
                    ),
                  );
                }, childCount: _placeholderDiwans.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  CurveTween _staggerInterval(int index) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الديوانيّات',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اكتشف المجالس الحيّة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GlassmorphicContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            blur: 10,
            child: const Icon(
              Icons.tune_rounded,
              color: BayanColors.accent,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    final liveCount = _placeholderDiwans.where((d) => d.isLive).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BayanColors.accent,
              boxShadow: [
                BoxShadow(
                  color: BayanColors.accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$liveCount ديوانيّات مباشرة الآن',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BayanColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiwanCard extends StatelessWidget {
  final _DiwanData diwan;

  const _DiwanCard({required this.diwan});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: diwan.gradientColors,
            ),
            border: Border.all(color: BayanColors.glassBorder, width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (diwan.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BayanColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: BayanColors.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: BayanColors.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'مباشر',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      diwan.name,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'المضيف: ${diwan.host}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: BayanColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.mic_rounded,
                    label: '${diwan.voiceCount} صوت',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.headphones_rounded,
                    label: '${diwan.listenerCount} مستمع',
                  ),
                  const Spacer(),
                  _EnterButton(isLive: diwan.isLive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: BayanColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EnterButton extends StatelessWidget {
  final bool isLive;

  const _EnterButton({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLive
          ? BayanColors.accent
          : BayanColors.textSecondary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            isLive ? 'ادخل' : 'تذكير',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLive
                  ? BayanColors.background
                  : BayanColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
