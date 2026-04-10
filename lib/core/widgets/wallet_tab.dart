import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _Transaction {
  final String title;
  final String date;
  final int amount;
  final bool isIncoming;
  final IconData icon;
  final Color color;

  const _Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncoming,
    required this.icon,
    required this.color,
  });
}

class _Contributor {
  final String name;
  final String initial;
  final int tokens;
  final int rank;

  const _Contributor({
    required this.name,
    required this.initial,
    required this.tokens,
    required this.rank,
  });
}

const _transactions = [
  _Transaction(
    title: 'إرسال الريشة الذهبية',
    date: 'اليوم ٨:٣٠ م',
    amount: 50,
    isIncoming: false,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFD4AF37),
  ),
  _Transaction(
    title: 'استلام دلة بلورية',
    date: 'أمس ١٠:١٥ م',
    amount: 100,
    isIncoming: true,
    icon: Icons.coffee_rounded,
    color: Color(0xFF7DD4C4),
  ),
  _Transaction(
    title: 'شراء توكنات',
    date: 'أمس ٦:٠٠ م',
    amount: 500,
    isIncoming: true,
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF2A6F97),
  ),
  _Transaction(
    title: 'إرسال صقر ملكي',
    date: '٧ أبريل',
    amount: 250,
    isIncoming: false,
    icon: Icons.flutter_dash_rounded,
    color: Color(0xFF6C3FA0),
  ),
  _Transaction(
    title: 'مكافأة أسبوعية',
    date: '٦ أبريل',
    amount: 75,
    isIncoming: true,
    icon: Icons.card_giftcard_rounded,
    color: BayanColors.accent,
  ),
];

const _topContributors = [
  _Contributor(name: 'خالد العتيبي', initial: 'خ', tokens: 4250, rank: 1),
  _Contributor(name: 'سارة الفهد', initial: 'س', tokens: 3100, rank: 2),
  _Contributor(name: 'محمد الراشد', initial: 'م', tokens: 2750, rank: 3),
];

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildTopContributors(),
          const SizedBox(height: 24),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
            ),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.toll_rounded,
                      color: Color(0xFFD4AF37),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'رصيد بَيَان',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '١,٢٥٠',
                    style: GoogleFonts.cairo(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'توكن',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: BayanColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: BayanColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+١٢٥ هذا الأسبوع',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BayanColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_rounded,
            label: 'شراء توكنات',
            color: BayanColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.card_giftcard_rounded,
            label: 'إرسال هدية',
            color: const Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history_rounded,
            label: 'السجل',
            color: const Color(0xFF6C3FA0),
          ),
        ),
      ],
    );
  }

  Widget _buildTopContributors() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'كبار الداعمين',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: _topContributors.map((c) {
                  return Expanded(child: _ContributorPodium(contributor: c));
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل المعاملات',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BayanColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GlassmorphicContainer(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            children: _transactions.asMap().entries.map((entry) {
              return _TransactionTile(
                transaction: entry.value,
                showDivider: entry.key < _transactions.length - 1,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: () => HapticFeedback.mediumImpact(),
      child: GlassmorphicContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BayanColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributorPodium extends StatelessWidget {
  final _Contributor contributor;
  const _ContributorPodium({required this.contributor});

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      const Color(0xFFD4AF37),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = rankColors[contributor.rank - 1];
    final sizes = [52.0, 44.0, 44.0];
    final sz = sizes[contributor.rank - 1];

    return Column(
      children: [
        if (contributor.rank == 1)
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFD4AF37),
            size: 20,
          )
        else
          const SizedBox(height: 20),
        const SizedBox(height: 4),
        Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.35), BayanColors.surface],
            ),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: Text(
              contributor.initial,
              style: GoogleFonts.cairo(
                fontSize: sz * 0.38,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contributor.name.split(' ').first,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BayanColors.textPrimary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.toll_rounded, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              '${contributor.tokens}',
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final _Transaction transaction;
  final bool showDivider;

  const _TransactionTile({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: transaction.color.withValues(alpha: 0.1),
                ),
                child: Icon(
                  transaction.icon,
                  color: transaction.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    Text(
                      transaction.date,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${transaction.isIncoming ? '+' : '-'}${transaction.amount}',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: transaction.isIncoming
                      ? BayanColors.accent
                      : Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
            ],
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
