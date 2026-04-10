import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _TopicCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TopicCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const _topics = [
  _TopicCard(
    title: 'الحساب والأمان',
    subtitle: 'تسجيل الدخول، كلمة المرور، التحقق',
    icon: Icons.shield_rounded,
    color: BayanColors.accent,
  ),
  _TopicCard(
    title: 'المحفظة والتوكنات',
    subtitle: 'الشراء، السحب، المعاملات',
    icon: Icons.toll_rounded,
    color: Color(0xFFD4AF37),
  ),
  _TopicCard(
    title: 'البث والديوانيّات',
    subtitle: 'الاستضافة، الجدولة، مشاكل الصوت',
    icon: Icons.mic_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _TopicCard(
    title: 'التوثيق والشارات',
    subtitle: 'طلب التوثيق، ريشة التميز',
    icon: Icons.verified_rounded,
    color: Color(0xFF2A6F97),
  ),
  _TopicCard(
    title: 'الخصوصية والإبلاغ',
    subtitle: 'الحظر، الإبلاغ، إعدادات الخصوصية',
    icon: Icons.privacy_tip_rounded,
    color: Color(0xFF8B5E3C),
  ),
  _TopicCard(
    title: 'الاشتراك والدعوات',
    subtitle: 'دعوة الأصدقاء، العضوية المميزة',
    icon: Icons.workspace_premium_rounded,
    color: BayanColors.accent,
  ),
];

class ConciergeScreen extends StatelessWidget {
  const ConciergeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildWelcomeCard()),
            SliverToBoxAdapter(child: _buildTopicsTitle()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TopicTile(topic: _topics[i]),
                  childCount: _topics.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildDirectSupport(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كونسيرج بَيَان',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'المساعدة والدعم',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFFD4AF37),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: BayanColors.accent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً عبدالله 👋',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'كيف يمكننا مساعدتك اليوم؟ اختر موضوعاً أو تواصل مع فريق الدعم مباشرة.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: BayanColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BayanColors.accent.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.headset_mic_rounded,
                    color: BayanColors.accent,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicsTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Text(
        'اختر موضوع المساعدة',
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: BayanColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDirectSupport(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'لم تجد إجابتك؟',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          HapticButton(
            hapticType: HapticFeedbackType.heavy,
            onTap: () => HapticFeedback.heavyImpact(),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BayanColors.accent, Color(0xFF2A6F97)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: BayanColors.background,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'تحدث مع فريق الدعم',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    color: BayanColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أرسل رسالة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final _TopicCard topic;
  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () => HapticFeedback.selectionClick(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: BayanColors.glassBackground,
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: topic.color.withValues(alpha: 0.12),
                  ),
                  child: Icon(topic.icon, color: topic.color, size: 20),
                ),
                const Spacer(),
                Text(
                  topic.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: BayanColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
