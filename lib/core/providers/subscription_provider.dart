import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/models/user_subscription.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Available tiers
// -------------------------------------------------------------------------
final subscriptionTiersProvider =
    FutureProvider.autoDispose<List<SubscriptionTier>>((ref) {
      return ref.read(subscriptionRepositoryProvider).fetchTiers();
    });

// -------------------------------------------------------------------------
// My active subscriptions (realtime)
// -------------------------------------------------------------------------
final mySubscriptionsStreamProvider =
    StreamProvider.autoDispose<List<UserSubscription>>((ref) {
      return ref.read(subscriptionRepositoryProvider).watchMySubscriptions();
    });

// -------------------------------------------------------------------------
// Convenience: highest active tier
// -------------------------------------------------------------------------
final activeTierProvider = Provider.autoDispose<TierType?>((ref) {
  final stream = ref.watch(mySubscriptionsStreamProvider);
  return stream.whenOrNull(
    data: (subs) {
      final active = subs.where((s) => s.isActive).toList();
      if (active.isEmpty) return null;
      return active.fold<TierType?>(null, (best, s) {
        if (s.tierType == null) return best;
        if (best == null) return s.tierType;
        return SubscriptionTier.tierRank(s.tierType!) >
                SubscriptionTier.tierRank(best)
            ? s.tierType
            : best;
      });
    },
  );
});

// -------------------------------------------------------------------------
// Subscription guard helpers
// -------------------------------------------------------------------------
final hasGoldAccessProvider = Provider.autoDispose<bool>((ref) {
  final tier = ref.watch(activeTierProvider);
  if (tier == null) return false;
  return SubscriptionTier.tierRank(tier) >=
      SubscriptionTier.tierRank(TierType.gold);
});

final hasPlatinumAccessProvider = Provider.autoDispose<bool>((ref) {
  final tier = ref.watch(activeTierProvider);
  if (tier == null) return false;
  return SubscriptionTier.tierRank(tier) >=
      SubscriptionTier.tierRank(TierType.platinum);
});

final hasFounderAccessProvider = Provider.autoDispose<bool>((ref) {
  final tier = ref.watch(activeTierProvider);
  if (tier == null) return false;
  return tier == TierType.founder;
});

// -------------------------------------------------------------------------
// Subscribe / Cancel state
// -------------------------------------------------------------------------
class SubscribeState {
  final bool isLoading;
  final bool? success;
  final String? error;
  final String? confirmedTierName;

  const SubscribeState({
    this.isLoading = false,
    this.success,
    this.error,
    this.confirmedTierName,
  });

  SubscribeState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
    String? confirmedTierName,
    bool clearError = false,
  }) => SubscribeState(
    isLoading: isLoading ?? this.isLoading,
    success: success ?? this.success,
    error: clearError ? null : (error ?? this.error),
    confirmedTierName: confirmedTierName ?? this.confirmedTierName,
  );
}

class SubscribeNotifier extends AutoDisposeNotifier<SubscribeState> {
  @override
  SubscribeState build() => const SubscribeState();

  Future<void> subscribe(TierType tier) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(subscriptionRepositoryProvider)
          .subscribeTo(tier);
      final ok = (result['success'] as bool?) ?? false;
      if (ok) {
        state = state.copyWith(
          isLoading: false,
          success: true,
          confirmedTierName: result['tier'] as String?,
        );
      } else {
        final errCode = result['error'] as String? ?? 'unknown';
        state = state.copyWith(
          isLoading: false,
          success: false,
          error: errCode == 'insufficient_balance'
              ? 'رصيدك غير كافٍ للاشتراك'
              : 'تعذّر الاشتراك',
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر الاشتراك');
    }
  }

  Future<void> cancel(TierType tier) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await ref.read(subscriptionRepositoryProvider).cancel(tier);
      state = state.copyWith(isLoading: false, success: ok);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر إلغاء الاشتراك');
    }
  }
}

final subscribeProvider =
    NotifierProvider.autoDispose<SubscribeNotifier, SubscribeState>(
      SubscribeNotifier.new,
    );
