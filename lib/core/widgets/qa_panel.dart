import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class StageQuestion {
  final String id;
  final String author;
  final String authorInitial;
  final String text;
  int upvotes;
  bool isAnswered;

  StageQuestion({
    required this.id,
    required this.author,
    required this.authorInitial,
    required this.text,
    this.upvotes = 0,
    this.isAnswered = false,
  });
}

void showQaPanel(BuildContext context, {required bool isHost}) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QaPanelSheet(isHost: isHost),
  );
}

class _QaPanelSheet extends StatefulWidget {
  final bool isHost;
  const _QaPanelSheet({required this.isHost});

  @override
  State<_QaPanelSheet> createState() => _QaPanelSheetState();
}

class _QaPanelSheetState extends State<_QaPanelSheet> {
  final _inputController = TextEditingController();
  final _questions = <StageQuestion>[
    StageQuestion(
      id: 'q1',
      author: 'محمد الراشد',
      authorInitial: 'م',
      text: 'ما رأيك في مستقبل الشعر النبطي في العصر الرقمي؟',
      upvotes: 24,
    ),
    StageQuestion(
      id: 'q2',
      author: 'هند الشمري',
      authorInitial: 'ه',
      text: 'هل يمكن المقارنة بين الشعر الفصيح والنبطي من حيث الأثر العاطفي؟',
      upvotes: 18,
    ),
    StageQuestion(
      id: 'q3',
      author: 'خالد العتيبي',
      authorInitial: 'خ',
      text: 'كيف يمكن للشباب الحفاظ على الموروث الأدبي؟',
      upvotes: 15,
    ),
    StageQuestion(
      id: 'q4',
      author: 'لطيفة المطر',
      authorInitial: 'ل',
      text: 'ما أبرز الشعراء المعاصرين في رأيك؟',
      upvotes: 9,
    ),
    StageQuestion(
      id: 'q5',
      author: 'بدر السالم',
      authorInitial: 'ب',
      text: 'هل يؤثر الذكاء الاصطناعي على الإبداع الأدبي؟',
      upvotes: 6,
    ),
  ];

  final Set<String> _upvotedIds = {};

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    if (_inputController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _questions.insert(
        0,
        StageQuestion(
          id: 'q-new-${DateTime.now().millisecondsSinceEpoch}',
          author: 'أنت',
          authorInitial: 'أ',
          text: _inputController.text.trim(),
        ),
      );
    });
    _inputController.clear();
  }

  void _upvote(StageQuestion q) {
    if (_upvotedIds.contains(q.id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      q.upvotes++;
      _upvotedIds.add(q.id);
      _questions.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    });
  }

  void _markAnswered(StageQuestion q) {
    HapticFeedback.mediumImpact();
    setState(() => q.isAnswered = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _questions.remove(q));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
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
                      Icons.quiz_rounded,
                      color: Color(0xFFD4AF37),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'جدار الأسئلة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BayanColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_questions.where((q) => !q.isAnswered).length}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
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
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return _QuestionTile(
                      question: q,
                      isHost: widget.isHost,
                      isUpvoted: _upvotedIds.contains(q.id),
                      onUpvote: () => _upvote(q),
                      onMarkAnswered: () => _markAnswered(q),
                    );
                  },
                ),
              ),
              _buildInput(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: BayanColors.glassBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: TextField(
                controller: _inputController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'اطرح سؤالاً...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13,
                    color: BayanColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _submitQuestion(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: _submitQuestion,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: BayanColors.accent,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: BayanColors.background,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final StageQuestion question;
  final bool isHost;
  final bool isUpvoted;
  final VoidCallback onUpvote;
  final VoidCallback onMarkAnswered;

  const _QuestionTile({
    required this.question,
    required this.isHost,
    required this.isUpvoted,
    required this.onUpvote,
    required this.onMarkAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final isPrestige = question.upvotes >= 15;

    return AnimatedOpacity(
      opacity: question.isAnswered ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 600),
      child: AnimatedSlide(
        offset: question.isAnswered ? const Offset(0.3, 0) : Offset.zero,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: BayanColors.glassBackground,
              border: Border.all(
                color: isPrestige
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                    : BayanColors.glassBorder,
              ),
              boxShadow: isPrestige
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    HapticButton(
                      hapticType: HapticFeedbackType.selection,
                      onTap: onUpvote,
                      child: Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 28,
                        color: isUpvoted
                            ? BayanColors.accent
                            : BayanColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${question.upvotes}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPrestige
                            ? const Color(0xFFD4AF37)
                            : BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            question.author,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                          if (isPrestige) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 14,
                              color: const Color(0xFFD4AF37),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.text,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHost && !question.isAnswered)
                  HapticButton(
                    hapticType: HapticFeedbackType.medium,
                    onTap: onMarkAnswered,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BayanColors.accent.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: BayanColors.accent,
                        size: 18,
                      ),
                    ),
                  ),
                if (question.isAnswered)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: BayanColors.accent,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
