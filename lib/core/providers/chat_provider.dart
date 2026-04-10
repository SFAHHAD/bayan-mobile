import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class ChatState {
  final List<Message> messages;
  final bool isLoadingHistory;
  final bool isSending;
  final bool hasMoreHistory;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoadingHistory = false,
    this.isSending = false,
    this.hasMoreHistory = true,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoadingHistory,
    bool? isSending,
    bool? hasMoreHistory,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class ChatNotifier extends AutoDisposeFamilyAsyncNotifier<ChatState, String> {
  StreamSubscription<List<Message>>? _sub;
  static const _pageSize = 30;

  @override
  Future<ChatState> build(String diwanId) async {
    ref.onDispose(() => _sub?.cancel());

    // Load initial page of history
    final history = await ref
        .read(messageRepositoryProvider)
        .getPagedMessages(diwanId, limit: _pageSize);

    // Subscribe to real-time stream
    _sub = ref.read(messageRepositoryProvider).watchMessages(diwanId).listen((
      live,
    ) {
      if (state.hasValue) {
        final existing = state.value!.messages;
        // Merge: keep history + live messages de-duped by id
        final ids = existing.map((m) => m.id).toSet();
        final merged = [...existing, ...live.where((m) => !ids.contains(m.id))];
        state = AsyncData(state.value!.copyWith(messages: merged));
      }
    });

    return ChatState(
      messages: history,
      hasMoreHistory: history.length >= _pageSize,
    );
  }

  // -------------------------------------------------------------------------
  // Public actions
  // -------------------------------------------------------------------------

  Future<void> sendMessage(String content) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final user = ref.read(userProvider).user;
    if (user == null) return;

    final profile = await ref.read(profileRepositoryProvider).getById(user.id);
    final name = profile?.displayName ?? profile?.username ?? 'مستخدم';

    state = AsyncData(current.copyWith(isSending: true, clearError: true));
    try {
      await ref
          .read(messageRepositoryProvider)
          .sendMessage(
            diwanId: arg,
            senderId: user.id,
            senderName: name,
            content: content.trim(),
          );
      state = AsyncData(state.value!.copyWith(isSending: false));
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isSending: false, error: 'تعذّر إرسال الرسالة'),
      );
    }
  }

  Future<void> loadMoreHistory() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMoreHistory ||
        current.isLoadingHistory) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingHistory: true));
    try {
      final oldest = current.messages.isNotEmpty
          ? current.messages.first.createdAt
          : null;
      final older = await ref
          .read(messageRepositoryProvider)
          .getPagedMessages(arg, before: oldest, limit: _pageSize);

      final merged = [...older, ...current.messages];
      state = AsyncData(
        state.value!.copyWith(
          messages: merged,
          isLoadingHistory: false,
          hasMoreHistory: older.length >= _pageSize,
        ),
      );
    } catch (_) {
      state = AsyncData(
        state.value!.copyWith(
          isLoadingHistory: false,
          error: 'تعذّر تحميل السجل',
        ),
      );
    }
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final chatProvider = AsyncNotifierProvider.family
    .autoDispose<ChatNotifier, ChatState, String>(ChatNotifier.new);
