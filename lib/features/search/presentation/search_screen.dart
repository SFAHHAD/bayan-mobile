import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/shimmer_skeleton.dart';
import 'package:bayan/core/widgets/voice_card.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

class _CategoryItem {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}

const _categories = [
  _CategoryItem(
    label: 'الشعر والأدب',
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFF5CBFAD), Color(0xFF2E1A3E)],
  ),
  _CategoryItem(
    label: 'التقنية',
    icon: Icons.memory_rounded,
    gradient: [Color(0xFF6C3FA0), Color(0xFF2E1A3E)],
  ),
  _CategoryItem(
    label: 'ريادة الأعمال',
    icon: Icons.rocket_launch_rounded,
    gradient: [Color(0xFFD4AF37), Color(0xFF2E1A3E)],
  ),
  _CategoryItem(
    label: 'الفلسفة',
    icon: Icons.psychology_rounded,
    gradient: [Color(0xFF2A6F97), Color(0xFF2E1A3E)],
  ),
  _CategoryItem(
    label: 'الإعلام',
    icon: Icons.podcasts_rounded,
    gradient: [Color(0xFF8B5E3C), Color(0xFF2E1A3E)],
  ),
  _CategoryItem(
    label: 'الثقافة',
    icon: Icons.museum_rounded,
    gradient: [Color(0xFFA855F7), Color(0xFF2E1A3E)],
  ),
];

class _TrendingDiwan {
  final String name;
  final String host;
  final int listeners;
  final bool isLive;
  const _TrendingDiwan({
    required this.name,
    required this.host,
    required this.listeners,
    required this.isLive,
  });
}

const _trendingDiwans = [
  _TrendingDiwan(
    name: 'ديوان الشعر الحديث',
    host: 'عبدالله المطيري',
    listeners: 87,
    isLive: true,
  ),
  _TrendingDiwan(
    name: 'نقاشات تقنية',
    host: 'سارة الفهد',
    listeners: 124,
    isLive: true,
  ),
  _TrendingDiwan(
    name: 'ديوان الأدب الكويتي',
    host: 'فهد العنزي',
    listeners: 203,
    isLive: false,
  ),
];

const _trendingVoices = [
  VoiceCardData(
    id: 'tv1',
    speakerName: 'عبدالله المطيري',
    speakerInitial: 'ع',
    title: 'عن جمال الشعر النبطي',
    duration: '٢:٣٤',
    likeCount: 89,
    waveform: [
      0.3,
      0.5,
      0.7,
      0.4,
      0.8,
      0.6,
      0.9,
      0.5,
      0.7,
      0.3,
      0.6,
      0.8,
      0.4,
      0.7,
      0.5,
      0.9,
      0.3,
      0.6,
      0.8,
      0.4,
      0.7,
      0.5,
      0.3,
      0.8,
      0.6,
      0.4,
      0.7,
      0.9,
      0.5,
      0.3,
    ],
  ),
  VoiceCardData(
    id: 'tv2',
    speakerName: 'سارة الفهد',
    speakerInitial: 'س',
    title: 'مستقبل الذكاء الاصطناعي',
    duration: '٤:١٢',
    likeCount: 156,
    waveform: [
      0.4,
      0.6,
      0.3,
      0.8,
      0.5,
      0.7,
      0.4,
      0.9,
      0.6,
      0.3,
      0.7,
      0.5,
      0.8,
      0.4,
      0.6,
      0.3,
      0.9,
      0.7,
      0.5,
      0.8,
      0.4,
      0.6,
      0.3,
      0.7,
      0.9,
      0.5,
      0.8,
      0.4,
      0.6,
      0.3,
    ],
  ),
  VoiceCardData(
    id: 'tv3',
    speakerName: 'فهد العنزي',
    speakerInitial: 'ف',
    title: 'ريادة الأعمال في الكويت',
    duration: '١:٤٨',
    likeCount: 67,
    waveform: [
      0.5,
      0.3,
      0.7,
      0.6,
      0.4,
      0.8,
      0.5,
      0.3,
      0.9,
      0.7,
      0.4,
      0.6,
      0.8,
      0.3,
      0.5,
      0.7,
      0.4,
      0.9,
      0.6,
      0.3,
      0.8,
      0.5,
      0.7,
      0.4,
      0.6,
      0.3,
      0.9,
      0.5,
      0.7,
      0.8,
    ],
  ),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasQuery = false;
  bool _isLoading = true;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (hasText != _hasQuery) setState(() => _hasQuery = hasText);
    });

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BayanColors.background,
        body: SafeArea(child: SearchSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (!_hasQuery) ...[
              SliverToBoxAdapter(child: _buildSmartSuggestion()),
              SliverToBoxAdapter(child: _buildFeaturedHero()),
              SliverToBoxAdapter(child: _buildCategoriesGrid()),
              SliverToBoxAdapter(child: _buildTrendingDiwans()),
              SliverToBoxAdapter(child: _buildTrendingVoices()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ] else ...[
              SliverToBoxAdapter(child: _buildSearchResults()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      child: Text(
        'استكشف',
        style: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: BayanColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: BayanColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن ديوانيّة، صوت، أو شخص...',
              hintStyle: GoogleFonts.cairo(
                fontSize: 14,
                color: BayanColors.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: BayanColors.accent,
                size: 24,
              ),
              suffixIcon: _hasQuery
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: BayanColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _searchController.clear();
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: BayanColors.glassBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: BayanColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: BayanColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: BayanColors.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: HapticButton(
        hapticType: HapticFeedbackType.selection,
        onTap: () => HapticFeedback.selectionClick(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    BayanColors.accent.withValues(alpha: 0.25),
                    const Color(0xFF6C3FA0).withValues(alpha: 0.15),
                    BayanColors.surface,
                  ],
                ),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BayanColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BayanColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PulsingDot(
                              color: BayanColors.accent,
                              size: 5,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'مباشر الآن',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: BayanColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⭐ مميّز',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ديوان الشعر الحديث',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يستضيفها عبدالله المطيري',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 16,
                        color: BayanColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '٨٧ مستمع',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.mic_rounded,
                        size: 16,
                        color: BayanColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '١٤ متحدث',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: BayanColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'انضم',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.background,
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
    );
  }

  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          child: Text(
            'التصنيفات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: BayanColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () {
                  _searchController.text = cat.label;
                  _focusNode.requestFocus();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: cat.gradient
                              .map((c) => c.withValues(alpha: 0.35))
                              .toList(),
                        ),
                        border: Border.all(color: BayanColors.glassBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon, color: cat.gradient.first, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            cat.label,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingDiwans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: BayanColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'الديوانيّات الرائجة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ..._trendingDiwans.map((diwan) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: HapticButton(
              hapticType: HapticFeedbackType.light,
              onTap: () => HapticFeedback.selectionClick(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BayanColors.glassBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BayanColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: BayanColors.accent.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: BayanColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diwan.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: BayanColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${diwan.host} · ${diwan.listeners} مستمع',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: BayanColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (diwan.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: BayanColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: BayanColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!diwan.isLive)
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: BayanColors.textSecondary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendingVoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Row(
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                color: Color(0xFF6C3FA0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'أصوات رائجة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _trendingVoices.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return VoiceCard(data: _trendingVoices[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSuggestion() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: HapticButton(
        hapticType: HapticFeedbackType.selection,
        onTap: () => HapticFeedback.selectionClick(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xFF6C3FA0).withValues(alpha: 0.12),
                    BayanColors.glassBackground,
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF6C3FA0).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          BayanColors.accent.withValues(alpha: 0.15),
                          const Color(0xFF6C3FA0).withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: BayanColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بناءً على اهتماماتك العميقة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: BayanColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ننصحك بمجلس الشعر الحديث مع عبدالله المطيري',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BayanColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ادخل',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text;
    final allResults = [
      ..._trendingDiwans.where(
        (d) => d.name.contains(query) || d.host.contains(query),
      ),
    ];

    if (allResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: BayanColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد نتائج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'جرّب كلمات بحث مختلفة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final matchPercentages = [92, 87, 74, 68, 55];

    return Column(
      children: [
        ...allResults.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final matchPct = i < matchPercentages.length
              ? matchPercentages[i]
              : 50 + (d.listeners % 40);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: HapticButton(
              hapticType: HapticFeedbackType.light,
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BayanColors.glassBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BayanColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: BayanColors.accent.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: BayanColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: BayanColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${d.host} · ${d.listeners} مستمع',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: BayanColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: _matchColor(matchPct).withValues(alpha: 0.1),
                            border: Border.all(
                              color: _matchColor(
                                matchPct,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: _matchColor(matchPct),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchPct٪',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _matchColor(matchPct),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _matchColor(int pct) {
    if (pct >= 85) return BayanColors.accent;
    if (pct >= 65) return const Color(0xFFD4AF37);
    return BayanColors.textSecondary;
  }
}
