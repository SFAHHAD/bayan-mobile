import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class ChatMessage {
  final String senderName;
  final String senderInitial;
  final String text;
  final bool isHost;
  final DateTime timestamp;

  const ChatMessage({
    required this.senderName,
    required this.senderInitial,
    required this.text,
    this.isHost = false,
    required this.timestamp,
  });
}

class StageChatOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onToggle;

  const StageChatOverlay({
    super.key,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  State<StageChatOverlay> createState() => _StageChatOverlayState();
}

class _StageChatOverlayState extends State<StageChatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final _quickPhrases = [
    'أكرمك الله',
    'صحّت لسانك',
    'ما شاء الله',
    'بارك الله فيك',
    'جميل جداً',
    'أحسنت',
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(
      senderName: 'عبدالله المطيري',
      senderInitial: 'ع',
      text: 'أهلاً بالجميع في ديوان الشعر الحديث',
      isHost: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      senderName: 'سارة الفهد',
      senderInitial: 'س',
      text: 'ما شاء الله، موضوع رائع الليلة',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      senderName: 'فهد العنزي',
      senderInitial: 'ف',
      text: 'صحّت لسانك يا عبدالله',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    ChatMessage(
      senderName: 'نورة الصباح',
      senderInitial: 'ن',
      text: 'أكرمك الله، كلام جميل',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    ChatMessage(
      senderName: 'عبدالله المطيري',
      senderInitial: 'ع',
      text: 'شكراً لكم على التفاعل الجميل',
      isHost: true,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    if (widget.isVisible) _slideController.forward();
  }

  @override
  void didUpdateWidget(StageChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _slideController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(
        ChatMessage(
          senderName: 'أنت',
          senderInitial: 'أ',
          text: text.trim(),
          timestamp: DateTime.now(),
        ),
      );
    });
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            widget.onToggle();
          }
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.42,
              decoration: BoxDecoration(
                color: BayanColors.background.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: BayanColors.glassBorder.withValues(alpha: 0.5),
                  ),
                  left: BorderSide(
                    color: BayanColors.glassBorder.withValues(alpha: 0.3),
                  ),
                  right: BorderSide(
                    color: BayanColors.glassBorder.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildHandle(),
                  Expanded(child: _buildMessageList()),
                  _buildQuickReactions(),
                  _buildInput(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: BayanColors.glassBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildQuickReactions() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPhrases.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => _sendMessage(_quickPhrases[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BayanColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _quickPhrases[index],
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.accent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
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
                controller: _textController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
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
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  message.isHost
                      ? BayanColors.accent.withValues(alpha: 0.4)
                      : const Color(0xFF6C3FA0).withValues(alpha: 0.3),
                  BayanColors.surface,
                ],
              ),
              border: Border.all(color: BayanColors.glassBorder, width: 1),
            ),
            child: Center(
              child: Text(
                message.senderInitial,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: message.isHost
                      ? [
                          BayanColors.accent.withValues(alpha: 0.1),
                          BayanColors.glassBackground,
                        ]
                      : [
                          BayanColors.glassBackground,
                          BayanColors.surface.withValues(alpha: 0.3),
                        ],
                ),
                border: Border.all(
                  color: message.isHost
                      ? BayanColors.accent.withValues(alpha: 0.15)
                      : BayanColors.glassBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.senderName,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: message.isHost
                              ? BayanColors.accent
                              : BayanColors.textSecondary,
                        ),
                      ),
                      if (message.isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: BayanColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'المضيف',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.text,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: BayanColors.textPrimary,
                      height: 1.4,
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
