import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/follow_button.dart';
import 'package:bayan/core/widgets/voice_card.dart';
import 'package:bayan/core/widgets/audio_waveform_painter.dart';

class SpeakerProfileScreen extends StatefulWidget {
  final String heroTag;
  final String name;
  final String initial;

  const SpeakerProfileScreen({
    super.key,
    required this.heroTag,
    required this.name,
    required this.initial,
  });

  @override
  State<SpeakerProfileScreen> createState() => _SpeakerProfileScreenState();
}

class _SpeakerProfileScreenState extends State<SpeakerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  static const _voiceGallery = [
    VoiceCardData(
      id: 'sp-v1',
      speakerName: '',
      speakerInitial: '',
      title: 'تأملات في الأدب',
      duration: '١:٤٥',
      likeCount: 34,
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
      id: 'sp-v2',
      speakerName: '',
      speakerInitial: '',
      title: 'ريادة الأعمال',
      duration: '٣:٢٠',
      likeCount: 52,
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
      id: 'sp-v3',
      speakerName: '',
      speakerInitial: '',
      title: 'حوار عن التقنية',
      duration: '٢:١٠',
      likeCount: 28,
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
      id: 'sp-v4',
      speakerName: '',
      speakerInitial: '',
      title: 'الشعر النبطي',
      duration: '٤:٠٥',
      likeCount: 91,
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
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 20),
                  _buildProfileSection(),
                  const SizedBox(height: 28),
                  _buildVoiceGallery(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BayanColors.accent.withValues(alpha: 0.1),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
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
    );
  }

  Widget _buildProfileSection() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
      child: Column(
        children: [
          Hero(
            tag: widget.heroTag,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BayanColors.accent.withValues(alpha: 0.3),
                    BayanColors.surface,
                  ],
                ),
                border: Border.all(color: BayanColors.glassBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.initial,
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.name,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'متحدث في ٤ ديوانيّات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: BayanColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('١٢٤', 'متابع'),
                Container(width: 1, height: 30, color: BayanColors.glassBorder),
                _buildStat('٨٦', 'متابَع'),
                Container(width: 1, height: 30, color: BayanColors.glassBorder),
                _buildStat('٤٧', 'مقطع'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const FollowButton(),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: BayanColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceGallery() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معرض الأصوات',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
              ),
            ],
          ),
        ),
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
