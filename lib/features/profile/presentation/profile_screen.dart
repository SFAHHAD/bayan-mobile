import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/founder_glow_badge.dart';
import 'package:bayan/core/widgets/shimmer_skeleton.dart';
import 'package:bayan/core/widgets/audio_waveform_painter.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/voice_card.dart';
import 'package:bayan/core/widgets/elite_avatar_badge.dart';
import 'package:bayan/core/widgets/insights_charts.dart';
import 'package:bayan/core/widgets/wallet_tab.dart';
import 'package:bayan/features/referral/presentation/referral_hub_screen.dart';
import 'package:bayan/features/verification/presentation/verification_screen.dart';
import 'package:bayan/core/widgets/premium_ticket.dart';
import 'package:bayan/features/creator/presentation/creator_studio_screen.dart';
import 'package:bayan/core/widgets/live_event_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late final TabController _tabController;

  static const _voiceGallery = [
    VoiceCardData(
      id: 'my-v1',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'عن فلسفة الإبداع',
      duration: '٢:١٥',
      likeCount: 42,
      waveform: [
        0.4,
        0.7,
        0.5,
        0.9,
        0.3,
        0.6,
        0.8,
        0.5,
        0.7,
        0.4,
        0.6,
        0.3,
        0.8,
        0.5,
        0.9,
        0.4,
        0.7,
        0.3,
        0.6,
        0.8,
      ],
    ),
    VoiceCardData(
      id: 'my-v2',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'الشعر والموسيقى',
      duration: '٣:٤٠',
      likeCount: 78,
      waveform: [
        0.5,
        0.3,
        0.8,
        0.6,
        0.4,
        0.7,
        0.9,
        0.5,
        0.3,
        0.6,
        0.8,
        0.4,
        0.7,
        0.5,
        0.3,
        0.9,
        0.6,
        0.8,
        0.4,
        0.7,
      ],
    ),
    VoiceCardData(
      id: 'my-v3',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'التصميم والتجربة',
      duration: '١:٥٥',
      likeCount: 31,
      waveform: [
        0.6,
        0.4,
        0.7,
        0.5,
        0.8,
        0.3,
        0.6,
        0.9,
        0.4,
        0.7,
        0.5,
        0.8,
        0.3,
        0.6,
        0.4,
        0.9,
        0.7,
        0.5,
        0.8,
        0.3,
      ],
    ),
    VoiceCardData(
      id: 'my-v4',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'مجلس الأدب',
      duration: '٤:٣٠',
      likeCount: 95,
      waveform: [
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
        0.9,
        0.4,
        0.7,
        0.5,
      ],
    ),
    VoiceCardData(
      id: 'my-v5',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'القيادة والإلهام',
      duration: '٢:٥٠',
      likeCount: 56,
      waveform: [
        0.7,
        0.4,
        0.6,
        0.8,
        0.3,
        0.5,
        0.7,
        0.9,
        0.4,
        0.6,
        0.3,
        0.8,
        0.5,
        0.7,
        0.4,
        0.6,
        0.9,
        0.3,
        0.8,
        0.5,
      ],
    ),
    VoiceCardData(
      id: 'my-v6',
      speakerName: 'عبدالله الكندري',
      speakerInitial: 'ع',
      title: 'نقاش عن المستقبل',
      duration: '٥:١٠',
      likeCount: 114,
      waveform: [
        0.5,
        0.8,
        0.3,
        0.7,
        0.6,
        0.4,
        0.9,
        0.5,
        0.7,
        0.3,
        0.6,
        0.8,
        0.4,
        0.5,
        0.7,
        0.3,
        0.9,
        0.6,
        0.4,
        0.8,
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BayanColors.background,
        body: SafeArea(child: ProfileSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildProfileHeader(context)),
            SliverToBoxAdapter(child: _buildInfoSection()),
            SliverToBoxAdapter(child: _buildSocialStats()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildTabBar(),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildVoiceGalleryTab(),
              const InsightsTab(),
              const WalletTab(),
              _buildAboutTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BayanColors.accent.withValues(alpha: 0.15),
                BayanColors.background,
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الملف الشخصي',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
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
                    Icons.edit_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          child: EliteAvatarBadge(
            voiceCount: 47,
            size: 96,
            child: _buildAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: BayanColors.background, width: 4),
        boxShadow: [
          BoxShadow(
            color: BayanColors.accent.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BayanColors.accent.withValues(alpha: 0.3),
                  BayanColors.surface,
                ],
              ),
              border: Border.all(color: BayanColors.glassBorder, width: 1.5),
            ),
            child: Center(
              child: Text(
                'ع',
                style: GoogleFonts.cairo(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Column(
        children: [
          Text(
            'عبدالله الكندري',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@abdullahk',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: BayanColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const FounderGlowBadge(),
        ],
      ),
    );
  }

  Widget _buildSocialStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SocialStatButton(value: '٢٤٨', label: 'متابع'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SocialStatButton(value: '١٣٦', label: 'متابَع'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              value: '٤٧',
              label: 'مقطع صوتي',
              icon: Icons.graphic_eq_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: BayanColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BayanColors.glassBorder),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
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
            Tab(text: 'الأصوات'),
            Tab(text: 'الإحصائيات'),
            Tab(text: 'المحفظة'),
            Tab(text: 'الإعدادات'),
          ],
          onTap: (_) => HapticFeedback.selectionClick(),
        ),
      ),
    );
  }

  Widget _buildVoiceGalleryTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: _voiceGallery.length,
      itemBuilder: (context, index) {
        return _VoiceGalleryCard(data: _voiceGallery[index]);
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassmorphicContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'مركز المبدعين',
                  iconColor: const Color(0xFFD4AF37),
                  showDivider: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, a, b) =>
                            const CreatorStudioScreen(),
                        transitionDuration: const Duration(milliseconds: 400),
                        transitionsBuilder: (context, animation, _, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'تعديل الملف الشخصي',
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'الإشعارات',
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.history_rounded,
                  label: 'سجل النشاط',
                  showDivider: true,
                  onTap: () => showActivityHistory(context),
                ),
                _SettingsTile(
                  icon: Icons.verified_rounded,
                  label: 'طلب التوثيق',
                  iconColor: const Color(0xFF2A6F97),
                  showDivider: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, a, b) =>
                            const VerificationScreen(),
                        transitionDuration: const Duration(milliseconds: 400),
                        transitionsBuilder: (context, animation, _, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.confirmation_num_rounded,
                  label: 'تذاكري',
                  iconColor: BayanColors.accent,
                  showDivider: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _TicketWalletSheet(),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'الخصوصية والأمان',
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'ادعُ النخبة',
                  iconColor: const Color(0xFFD4AF37),
                  showDivider: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, a, b) =>
                            const ReferralHubScreen(),
                        transitionDuration: const Duration(milliseconds: 400),
                        transitionsBuilder: (context, animation, _, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  label: 'اللغة',
                  trailing: Text(
                    'العربية',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: BayanColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'عن بَيَان',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialStatButton extends StatelessWidget {
  final String value;
  final String label;

  const _SocialStatButton({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () => HapticFeedback.selectionClick(),
      child: GlassmorphicContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: BayanColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: BayanColors.accent, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: BayanColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceGalleryCard extends StatefulWidget {
  final VoiceCardData data;

  const _VoiceGalleryCard({required this.data});

  @override
  State<_VoiceGalleryCard> createState() => _VoiceGalleryCardState();
}

class _VoiceGalleryCardState extends State<_VoiceGalleryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() => _isPlaying = false);
              _playController.reset();
            }
          });
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (_isPlaying) {
      _playController.stop();
    } else {
      _playController.forward();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: _toggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BayanColors.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _playController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: AudioWaveformPainter(
                          amplitudes: widget.data.waveform,
                          progress: _playController.value,
                          activeColor: BayanColors.accent,
                          inactiveColor: BayanColors.textSecondary.withValues(
                            alpha: 0.2,
                          ),
                          barWidth: 2.5,
                          gap: 2.0,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        key: ValueKey(_isPlaying),
                        color: BayanColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.data.duration,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: BayanColors.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.data.likeCount}',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BayanColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
}

class _TicketWalletSheet extends StatelessWidget {
  final _tickets = const [
    TicketData(
      diwanName: 'ملتقى الشعر الخليجي',
      hostName: 'عبدالله المطيري',
      date: '١٥ أبريل',
      time: '٩:٠٠ م',
      price: 100,
      ticketId: 'BYN-TK-7842',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
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
                      Icons.confirmation_num_rounded,
                      color: BayanColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تذاكري',
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
                child: _tickets.isEmpty
                    ? const TicketWalletEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _tickets.length,
                        itemBuilder: (context, i) =>
                            PremiumTicketCard(ticket: _tickets[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showDivider;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.showDivider,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? BayanColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: BayanColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: BayanColors.textSecondary,
                      size: 22,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              color: BayanColors.glassBorder.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
