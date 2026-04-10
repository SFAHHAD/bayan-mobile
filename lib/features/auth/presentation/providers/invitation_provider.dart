import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/data/repositories/invitation_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class InvitationState {
  final String? validatedCode;
  final bool isLoading;
  final String? error;

  const InvitationState({
    this.validatedCode,
    this.isLoading = false,
    this.error,
  });

  bool get hasValidCode => validatedCode != null;

  InvitationState copyWith({
    String? validatedCode,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearCode = false,
  }) {
    return InvitationState(
      validatedCode: clearCode ? null : (validatedCode ?? this.validatedCode),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repo;

  InvitationNotifier(this._repo) : super(const InvitationState());

  /// Validate the code against Supabase. Stores it in state on success.
  Future<bool> validateCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.validateCode(code);
      state = state.copyWith(
        validatedCode: code.trim().toUpperCase(),
        isLoading: false,
      );
      return true;
    } on InvalidInvitationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        clearCode: true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع، حاول مرة أخرى',
        clearCode: true,
      );
      return false;
    }
  }

  /// Redeem the stored validated code for the authenticated [userId].
  /// Called after successful OTP verification.
  Future<void> redeemCode(String userId) async {
    final code = state.validatedCode;
    if (code == null) return;
    try {
      await _repo.redeemCode(code, userId);
      state = state.copyWith(clearCode: true);
    } catch (_) {
      // Non-fatal: the user is already logged in; log and continue.
    }
  }

  void reset() => state = const InvitationState();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final invitationRepositoryProvider = Provider<InvitationRepository>(
  (ref) => InvitationRepository(ref.read(supabaseClientProvider)),
);

final invitationProvider =
    StateNotifierProvider<InvitationNotifier, InvitationState>(
      (ref) => InvitationNotifier(ref.read(invitationRepositoryProvider)),
    );
