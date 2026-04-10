import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/e2e_service.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// Service provider (singleton for the session)
// -------------------------------------------------------------------------
final e2eServiceProvider = Provider<E2EService>((ref) {
  final service = E2EService(ref.read(supabaseClientProvider));
  ref.onDispose(service.clearSession);
  return service;
});

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class E2EState {
  final bool isInitialised;
  final String? myPublicKeyBase64;
  final String? error;

  const E2EState({
    this.isInitialised = false,
    this.myPublicKeyBase64,
    this.error,
  });

  E2EState copyWith({
    bool? isInitialised,
    String? myPublicKeyBase64,
    String? error,
    bool clearError = false,
  }) => E2EState(
    isInitialised: isInitialised ?? this.isInitialised,
    myPublicKeyBase64: myPublicKeyBase64 ?? this.myPublicKeyBase64,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class E2ENotifier extends StateNotifier<E2EState> {
  final Ref _ref;

  E2ENotifier(this._ref) : super(const E2EState());

  /// Generates a fresh X25519 key pair and publishes the public key.
  /// Called once after login (or whenever keys need rotation).
  Future<void> initialise() async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;
    try {
      final pubKey = await _ref
          .read(e2eServiceProvider)
          .generateAndPublishKeyPair(userId);
      state = state.copyWith(isInitialised: true, myPublicKeyBase64: pubKey);
    } catch (e) {
      state = state.copyWith(error: 'تعذّر تهيئة التشفير: $e');
    }
  }

  void clearSession() {
    _ref.read(e2eServiceProvider).clearSession();
    state = const E2EState();
  }
}

final e2eProvider = StateNotifierProvider<E2ENotifier, E2EState>(
  (ref) => E2ENotifier(ref),
);

/// Fetches the public key for any user — used before initiating an encrypted
/// private Diwan to establish the shared secret.
final e2ePublicKeyProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, userId) => ref.read(e2eServiceProvider).getPublicKey(userId),
);
