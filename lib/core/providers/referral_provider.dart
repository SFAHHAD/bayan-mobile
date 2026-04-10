import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/referral_code.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class ReferralState {
  final String? code;
  final List<ReferralRecord> referralsMade;
  final int totalTokensEarned;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? shareCard;

  const ReferralState({
    this.code,
    this.referralsMade = const [],
    this.totalTokensEarned = 0,
    this.isLoading = false,
    this.error,
    this.shareCard,
  });

  ReferralState copyWith({
    String? code,
    List<ReferralRecord>? referralsMade,
    int? totalTokensEarned,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? shareCard,
    bool clearError = false,
  }) => ReferralState(
    code: code ?? this.code,
    referralsMade: referralsMade ?? this.referralsMade,
    totalTokensEarned: totalTokensEarned ?? this.totalTokensEarned,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    shareCard: shareCard ?? this.shareCard,
  );
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class ReferralNotifier extends StateNotifier<ReferralState> {
  final Ref _ref;

  ReferralNotifier(this._ref) : super(const ReferralState()) {
    _init();
  }

  Future<void> _init() async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final code = await _ref
          .read(referralRepositoryProvider)
          .getOrCreateCode();
      final records = await _ref
          .read(referralRepositoryProvider)
          .getReferralsMade(userId);
      final tokens = await _ref
          .read(referralRepositoryProvider)
          .totalTokensEarned(userId);
      state = state.copyWith(
        isLoading: false,
        code: code,
        referralsMade: records,
        totalTokensEarned: tokens,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الإحالات');
    }
  }

  /// Processes an incoming referral code after signup.
  Future<bool> processReferral(String code) async {
    return _ref.read(referralRepositoryProvider).processReferral(code);
  }

  /// Generates the share card (calls Edge Function).
  Future<void> generateShareCard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final card = await _ref
          .read(referralRepositoryProvider)
          .generateShareCard();
      state = state.copyWith(isLoading: false, shareCard: card);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر إنشاء بطاقة المشاركة',
      );
    }
  }
}

final referralProvider = StateNotifierProvider<ReferralNotifier, ReferralState>(
  (ref) => ReferralNotifier(ref),
);

/// Quick lookup of a referral code by user ID (for profile screens).
final referralCodeProvider = FutureProvider.autoDispose
    .family<ReferralCode?, String>(
      (ref, userId) => ref.read(referralRepositoryProvider).getCode(userId),
    );
