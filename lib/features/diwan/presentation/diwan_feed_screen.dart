import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/voice_card.dart';
import 'package:bayan/features/diwan/presentation/providers/diwan_provider.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/shimmer_skeleton.dart';
import 'package:bayan/features/diwan/presentation/diwan_detail_screen.dart';
import 'package:bayan/features/profile/presentation/speaker_profile_screen.dart';
import 'package:bayan/features/notifications/presentation/notification_center_screen.dart';
import 'package:bayan/core/widgets/bayan_refresh_indicator.dart';
import 'package:bayan/core/widgets/ai_summary_card.dart';
import 'package:bayan/core/widgets/for_you_feed.dart';
import 'package:bayan/core/widgets/live_event_banner.dart';
import 'package:bayan/core/widgets/predictive_feed.dart';

class _DiwanData {
  final String id;
  final String name;
  final String host;
  final int voiceCount;
  final int listenerCount;
  final bool isLive;
  final IconData icon;
  final List<Color> gradientColors;

  const _DiwanData({
    required this.id,
    required this.name,
    required this.host,
    required this.voiceCount,
    required this.listenerCount,
    required this.isLive,
    required this.icon,
    required this.gradientColors,
  });
}

final _placeholderDiwans = [
  _DiwanData(
    id: 'diwan-1',
    name: 'ديوان الشعر الحديث',
    host: 'عبدالله المطيري',
    voiceCount: 14,
    listenerCount: 87,
    isLive: true,
    icon: Icons.auto_stories_rounded,
    gradientColors: [
      BayanColors.accent.withValues(alpha: 0.3),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    id: 'diwan-2',
    name: 'نقاشات تقنية',
    host: 'سارة الفهد',
    voiceCount: 8,
    listenerCount: 124,
    isLive: true,
    icon: Icons.memory_rounded,
    gradientColors: [
      const Color(0xFF6C3FA0).withValues(alpha: 0.4),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    id: 'diwan-3',
    name: 'ديوان الأدب الكويتي',
    host: 'فهد العنزي',
    voiceCount: 22,
    listenerCount: 203,
    isLive: true,
    icon: Icons.menu_book_rounded,
    gradientColors: [
      const Color(0xFF2A6F97).withValues(alpha: 0.4),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    id: 'diwan-4',
    name: 'صالون الفكر العربي',
    host: 'نورة الصباح',
    voiceCount: 6,
    listenerCount: 56,
    isLive: false,
    icon: Icons.psychology_rounded,
    gradientColors: [
      const Color(0xFF8B5E3C).withValues(alpha: 0.3),
      BayanColors.surface,
    ],
  ),
  _DiwanData(
    id: 'diwan-5',
    name: 'ديوان ريادة الأعمال',
    host: 'محمد الراشد',
    voiceCount: 11,
    listenerCount: 142,
    isLive: false,
    icon: Icons.rocket_launch_rounded,
    gradientColors: [
      BayanColors.accent.withValues(alpha: 0.2),
      const Color(0xFF6C3FA0).withValues(alpha: 0.2),
    ],
  ),
];

_DiwanData _toDiwanData(Diwan d, int index) {
  const palettes = [
    [Color(0xFF5CBFAD), Color(0xFF2E1A3E)],
    [Color(0xFF6C3FA0), Color(0xFF2E1A3E)],
    [Color(0xFF2A6F97), Color(0xFF2E1A3E)],
    [Color(0xFF8B5E3C), Color(0xFF2E1A3E)],
    [Color(0xFF5CBFAD), Color(0xFF6C3FA0)],
  ];
  const icons = [
    Icons.auto_stories_rounded,
    Icons.memory_rounded,
    Icons.menu_book_rounded,
    Icons.psychology_rounded,
    Icons.rocket_launch_rounded,
  ];
  final colors = palettes[index % palettes.length]
      .map((c) => c.withValues(alpha: d.isLive ? 0.35 : 0.2))
      .toList();
  return _DiwanData(
    id: d.id,
    name: d.title,
    host: d.hostName ?? 'المضيف',
    voiceCount: d.voiceCount,
    listenerCount: d.listenerCount,
    isLive: d.isLive,
    icon: icons[index % icons.length],
    gradientColors: colors,
  );
}

class DiwanFeedScreen extends ConsumerStatefulWidget {
  const DiwanFeedScreen({super.key});

  @override
  ConsumerState<DiwanFeedScreen> createState() => _DiwanFeedScreenState();
}

class _DiwanFeedScreenState extends ConsumerState<DiwanFeedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final TabController _feedTabController;
  bool _showLiveBanner = true;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _feedTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _feedTabController.dispose();
    super.dispose();
  }

  void _openNotifications() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NotificationCenterScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideDown =
              Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: slideDown, child: child);
        },
      ),
    );
  }

  void _openDiwan(_DiwanData diwan) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DiwanDetailScreen(
              heroTag: 'diwan-icon-${diwan.id}',
              name: diwan.name,
              host: diwan.host,
              icon: diwan.icon,
              voiceCount: diwan.voiceCount,
              listenerCount: diwan.listenerCount,
              isLive: diwan.isLive,
              gradientColors: diwan.gradientColors,
            ),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(diwanNotifierProvider);

    if (async.isLoading && !async.hasValue) {
      return const Scaffold(
        backgroundColor: BayanColors.background,
        body: SafeArea(child: DiwanFeedSkeleton()),
      );
    }

    final diwans = async.maybeWhen(
      data: (list) => list.isEmpty
          ? _placeholderDiwans
          : list
                .asMap()
                .entries
                .map((e) => _toDiwanData(e.value, e.key))
                .toList(),
      orElse: () => _placeholderDiwans,
    );

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildFeedTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _feedTabController,
                    children: [
                      BayanRefreshIndicator(
                        onRefresh: () async {
                          HapticFeedback.mediumImpact();
                          ref.invalidate(diwanNotifierProvider);
                          await Future.delayed(
                            const Duration(milliseconds: 800),
                          );
                        },
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildLiveIndicator(diwans),
                            ),
                            const SliverToBoxAdapter(
                              child: PredictiveFeedSection(),
                            ),
                            SliverToBoxAdapter(child: _buildAiSummary()),
                            SliverToBoxAdapter(child: _buildTopVoices()),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final interval = _staggerInterval(index);
                                  return AnimatedBuilder(
                                    animation: _staggerController,
                                    builder: (context, child) {
                                      final value = interval.transform(
                                        _staggerController.value.clamp(
                                          0.0,
                                          1.0,
                                        ),
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
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _DiwanCard(
                                        diwan: diwans[index],
                                        onTap: () => _openDiwan(diwans[index]),
                                      ),
                                    ),
                                  );
                                }, childCount: diwans.length),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
                      const ForYouFeed(),
                    ],
                  ),
                ),
              ],
            ),
            if (_showLiveBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LiveEventBanner(
                  diwanName: 'ديوان الشعر الحديث',
                  hostName: 'عبدالله المطيري',
                  onJoin: () {},
                  onDismiss: () => setState(() => _showLiveBanner = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: BayanColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BayanColors.glassBorder),
        ),
        child: TabBar(
          controller: _feedTabController,
          indicator: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.3),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: BayanColors.accent,
          unselectedLabelColor: BayanColors.textSecondary,
          labelStyle: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'الديوانيّات'),
            Tab(text: 'لك'),
          ],
          onTap: (_) => HapticFeedback.selectionClick(),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () => _openNotifications(),
                child: GlassmorphicContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  blur: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: BayanColors.accent,
                        size: 22,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BayanColors.accent,
                            boxShadow: [
                              BoxShadow(
                                color: BayanColors.accent.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () {},
                child: GlassmorphicContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  blur: 10,
                  child: const Icon(
                    Icons.tune_rounded,
                    color: BayanColors.accent,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _topVoices = [
    VoiceCardData(
      id: 'v1',
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
      id: 'v2',
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
      id: 'v3',
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

  Widget _buildAiSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: AiSummaryCard(
        data: AiSummaryData(
          diwanName: 'ديوان الشعر الحديث',
          hostName: 'عبدالله المطيري',
          summary:
              'تناول المجلس أبرز قصائد الشعر النبطي المعاصر، مع تحليل معمّق لأساليب الشعراء الشباب وتأثيرهم على الساحة الأدبية الخليجية. نوقشت العلاقة بين الشعر والهوية الثقافية.',
          topics: [
            'الشعر النبطي',
            'الأدب المعاصر',
            'الهوية الثقافية',
            'الشعراء الشباب',
          ],
          duration: '١ ساعة ٢٠ دقيقة',
          listenerCount: 87,
        ),
      ),
    );
  }

  Widget _buildTopVoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
          child: Row(
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                color: BayanColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'أبرز الأصوات',
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
            itemCount: _topVoices.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final voice = _topVoices[index];
              return VoiceCard(
                data: voice,
                onTapProfile: () => _openSpeakerProfile(voice),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _openSpeakerProfile(VoiceCardData voice) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SpeakerProfileScreen(
              heroTag: 'voice-speaker-${voice.id}',
              name: voice.speakerName,
              initial: voice.speakerInitial,
            ),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildLiveIndicator(List<_DiwanData> diwans) {
    final liveCount = diwans.where((d) => d.isLive).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          const PulsingDot(color: BayanColors.accent, size: 8),
          const SizedBox(width: 8),
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
  final VoidCallback onTap;

  const _DiwanCard({required this.diwan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
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
                    Hero(
                      tag: 'diwan-icon-${diwan.id}',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: diwan.gradientColors.first.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: Icon(
                          diwan.icon,
                          color: BayanColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diwan.name,
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            diwan.host,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (diwan.isLive) _buildLiveBadge(),
                  ],
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
                    _EnterChip(isLive: diwan.isLive),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BayanColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BayanColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(color: BayanColors.accent, size: 6),
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

class _EnterChip extends StatelessWidget {
  final bool isLive;

  const _EnterChip({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isLive
            ? BayanColors.accent
            : BayanColors.textSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isLive ? 'ادخل' : 'تذكير',
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isLive ? BayanColors.background : BayanColors.textSecondary,
        ),
      ),
    );
  }
}
