import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

class _SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final _SearchResultType type;

  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
}

enum _SearchResultType { diwan, voice, person }

final _trendingTopics = [
  'الشعر النبطي',
  'ريادة الأعمال',
  'التقنية',
  'الأدب العربي',
  'الفلسفة',
  'الإعلام الجديد',
];

final _curatedResults = [
  _SearchResult(
    title: 'ديوان الشعر الحديث',
    subtitle: '١٤ صوت · مباشر الآن',
    icon: Icons.groups_rounded,
    type: _SearchResultType.diwan,
  ),
  _SearchResult(
    title: 'قصيدة "يا كويت"',
    subtitle: 'عبدالله المطيري · ٣ دقائق',
    icon: Icons.graphic_eq_rounded,
    type: _SearchResultType.voice,
  ),
  _SearchResult(
    title: 'سارة الفهد',
    subtitle: 'مضيفة · ٨ ديوانيّات',
    icon: Icons.person_rounded,
    type: _SearchResultType.person,
  ),
  _SearchResult(
    title: 'نقاشات تقنية',
    subtitle: '٨ أصوات · مباشر الآن',
    icon: Icons.groups_rounded,
    type: _SearchResultType.diwan,
  ),
  _SearchResult(
    title: 'حوار عن الذكاء الاصطناعي',
    subtitle: 'فهد العنزي · ١٢ دقيقة',
    icon: Icons.graphic_eq_rounded,
    type: _SearchResultType.voice,
  ),
  _SearchResult(
    title: 'محمد الراشد',
    subtitle: 'رائد أعمال · ١١ صوت',
    icon: Icons.person_rounded,
    type: _SearchResultType.person,
  ),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (hasText != _hasQuery) setState(() => _hasQuery = hasText);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _hasQuery ? _buildResults() : _buildExploreContent(),
            ),
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

  Widget _buildExploreContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle('الأكثر رواجاً'),
          const SizedBox(height: 12),
          _buildTrendingChips(),
          const SizedBox(height: 32),
          _buildSectionTitle('مختارات لك'),
          const SizedBox(height: 12),
          ..._curatedResults.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: _ResultTile(result: r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BayanColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTrendingChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _trendingTopics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _searchController.text = _trendingTopics[index];
              _focusNode.requestFocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: BayanColors.glassBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Text(
                _trendingTopics[index],
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    final filtered = _curatedResults
        .where(
          (r) =>
              r.title.contains(_searchController.text) ||
              r.subtitle.contains(_searchController.text),
        )
        .toList();

    if (filtered.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ResultTile(result: filtered[index]),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _SearchResult result;

  const _ResultTile({required this.result});

  Color get _typeColor {
    return switch (result.type) {
      _SearchResultType.diwan => BayanColors.accent,
      _SearchResultType.voice => const Color(0xFF6C3FA0),
      _SearchResultType.person => const Color(0xFF2A6F97),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _typeColor.withValues(alpha: 0.15),
                ),
                child: Icon(result.icon, color: _typeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      result.subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: BayanColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: BayanColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
