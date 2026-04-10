import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/providers/e2e_provider.dart';
import 'package:bayan/core/repositories/e2e_chat_repository.dart';

// -------------------------------------------------------------------------
// Repository provider (singleton)
// -------------------------------------------------------------------------
final e2eChatRepositoryProvider = Provider<E2EChatRepository>((ref) {
  final repo = E2EChatRepository(
    client: ref.read(supabaseClientProvider),
    e2eService: ref.read(e2eServiceProvider),
    messageRepository: ref.read(messageRepositoryProvider),
  );
  ref.onDispose(repo.clearAll);
  return repo;
});

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class E2EChatState {
  final List<Message> messages;
  final bool keyLoaded;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const E2EChatState({
    this.messages = const [],
    this.keyLoaded = false,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  E2EChatState copyWith({
    List<Message>? messages,
    bool? keyLoaded,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) => E2EChatState(
    messages: messages ?? this.messages,
    keyLoaded: keyLoaded ?? this.keyLoaded,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier (per private-diwan)
// -------------------------------------------------------------------------
class E2EChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Message>, String> {
  bool _keyLoaded = false;

  @override
  Future<List<Message>> build(String diwanId) async {
    ref.onDispose(
      () => ref.read(e2eChatRepositoryProvider).clearDiwanKey(diwanId),
    );
    return [];
  }

  /// Called by the host before the session starts.
  Future<void> distributeKey(List<String> participantIds) async {
    await ref
        .read(e2eChatRepositoryProvider)
        .distributeSessionKey(diwanId: arg, participantIds: participantIds);
    _keyLoaded = true;
  }

  /// Called by participants when joining.
  Future<bool> loadKey({
    required String myUserId,
    required String hostUserId,
  }) async {
    _keyLoaded = await ref
        .read(e2eChatRepositoryProvider)
        .loadSessionKey(
          diwanId: arg,
          myUserId: myUserId,
          hostUserId: hostUserId,
        );
    return _keyLoaded;
  }

  bool get isKeyLoaded => _keyLoaded;

  /// Sends an encrypted message.
  Future<void> send({
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (!_keyLoaded) {
      state = AsyncError('مفتاح التشفير غير متاح', StackTrace.current);
      return;
    }
    await ref
        .read(e2eChatRepositoryProvider)
        .sendEncryptedMessage(
          diwanId: arg,
          senderId: senderId,
          senderName: senderName,
          plaintext: text,
        );
  }

  /// Returns the live decrypted message stream.
  Stream<List<Message>> watchMessages() {
    return ref.read(e2eChatRepositoryProvider).watchDecryptedMessages(arg);
  }
}

final e2eChatProvider = AsyncNotifierProvider.autoDispose
    .family<E2EChatNotifier, List<Message>, String>(E2EChatNotifier.new);

/// Convenience StreamProvider wrapping the decrypted message stream.
final e2eMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, diwanId) {
      return ref
          .read(e2eChatRepositoryProvider)
          .watchDecryptedMessages(diwanId);
    });
