import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/purchase_receipt.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// My receipts
// -------------------------------------------------------------------------
final myReceiptsProvider = FutureProvider.autoDispose<List<PurchaseReceipt>>((
  ref,
) {
  return ref.read(subscriptionRepositoryProvider).fetchMyReceipts();
});

// -------------------------------------------------------------------------
// Purchase state
// -------------------------------------------------------------------------
class PurchaseState {
  final bool isLoading;
  final bool? success;
  final String? error;
  final String? activatedTierName;
  final DateTime? expiresAt;

  const PurchaseState({
    this.isLoading = false,
    this.success,
    this.error,
    this.activatedTierName,
    this.expiresAt,
  });

  PurchaseState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
    String? activatedTierName,
    DateTime? expiresAt,
    bool clearError = false,
  }) => PurchaseState(
    isLoading: isLoading ?? this.isLoading,
    success: success ?? this.success,
    error: clearError ? null : (error ?? this.error),
    activatedTierName: activatedTierName ?? this.activatedTierName,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}

class PurchaseNotifier extends AutoDisposeNotifier<PurchaseState> {
  @override
  PurchaseState build() => const PurchaseState();

  Future<void> purchase({
    required ReceiptPlatform platform,
    required String productId,
    required String receiptData,
    required TierType tier,
    String? transactionId,
    DateTime? expiresAt,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(paymentServiceProvider)
          .processReceipt(
            platform: platform,
            productId: productId,
            receiptData: receiptData,
            tier: tier,
            transactionId: transactionId,
            expiresAt: expiresAt,
          );
      state = state.copyWith(
        isLoading: false,
        success: result.success,
        error: result.error,
        activatedTierName: result.activatedTierName,
        expiresAt: result.expiresAt,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'فشلت عملية الشراء');
    }
  }
}

final purchaseProvider =
    NotifierProvider.autoDispose<PurchaseNotifier, PurchaseState>(
      PurchaseNotifier.new,
    );
