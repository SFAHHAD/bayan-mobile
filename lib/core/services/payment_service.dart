import 'package:bayan/core/models/purchase_receipt.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/repositories/subscription_repository.dart';

/// Result returned by [PaymentService.processReceipt].
class PaymentResult {
  final bool success;
  final String? error;
  final ReceiptStatus receiptStatus;
  final String? activatedTierName;
  final DateTime? expiresAt;

  const PaymentResult({
    required this.success,
    this.error,
    required this.receiptStatus,
    this.activatedTierName,
    this.expiresAt,
  });

  bool get isValid => receiptStatus == ReceiptStatus.valid;

  @override
  String toString() =>
      'PaymentResult(success: $success, status: ${PurchaseReceipt.statusToString(receiptStatus)})';
}

/// Validates IAP receipts from Apple / Google / Stripe and activates the
/// corresponding Sovereign Club subscription.
///
/// External HTTP calls are mocked — replace [_validateApple], [_validateGoogle],
/// and [_validateStripe] bodies with real HTTP calls when ready.
class PaymentService {
  final SubscriptionRepository _subscriptionRepo;

  PaymentService(this._subscriptionRepo);

  // -------------------------------------------------------------------------
  // Main entry point
  // -------------------------------------------------------------------------

  /// Full lifecycle:
  /// 1. Persist raw receipt (status=pending)
  /// 2. Validate with store
  /// 3. Update receipt status
  /// 4. If valid → activate subscription
  Future<PaymentResult> processReceipt({
    required ReceiptPlatform platform,
    required String productId,
    required String receiptData,
    required TierType tier,
    String? transactionId,
    DateTime? expiresAt,
  }) async {
    // Step 1 — persist
    PurchaseReceipt receipt;
    try {
      receipt = await _subscriptionRepo.createReceipt(
        platform: platform,
        productId: productId,
        receiptData: receiptData,
        transactionId: transactionId,
        tierType: tier,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'receipt_persist_failed',
        receiptStatus: ReceiptStatus.invalid,
      );
    }

    // Step 2 — validate
    final ValidationResult validation;
    try {
      validation = await _validate(platform, receiptData, productId);
    } catch (e) {
      await _subscriptionRepo.updateReceiptStatus(
        receipt.id,
        ReceiptStatus.invalid,
        rawResponse: {'error': e.toString()},
      );
      return PaymentResult(
        success: false,
        error: 'validation_error',
        receiptStatus: ReceiptStatus.invalid,
      );
    }

    // Step 3 — update receipt status
    await _subscriptionRepo.updateReceiptStatus(
      receipt.id,
      validation.status,
      rawResponse: validation.rawResponse,
    );

    if (validation.status != ReceiptStatus.valid) {
      return PaymentResult(
        success: false,
        error: 'receipt_${PurchaseReceipt.statusToString(validation.status)}',
        receiptStatus: validation.status,
      );
    }

    // Step 4 — activate subscription
    try {
      final result = await _subscriptionRepo.activateViaReceipt(
        receiptId: receipt.id,
        tier: tier,
        expiresAt: expiresAt ?? validation.expiresAt,
      );
      final ok = (result['success'] as bool?) ?? false;
      return PaymentResult(
        success: ok,
        error: ok ? null : (result['error'] as String?),
        receiptStatus: ReceiptStatus.valid,
        activatedTierName: result['tier'] as String?,
        expiresAt: ok && result['expires_at'] != null
            ? DateTime.tryParse(result['expires_at'] as String)
            : null,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'activation_failed',
        receiptStatus: ReceiptStatus.valid,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Platform dispatch
  // -------------------------------------------------------------------------

  Future<ValidationResult> _validate(
    ReceiptPlatform platform,
    String receiptData,
    String productId,
  ) {
    switch (platform) {
      case ReceiptPlatform.apple:
        return _validateApple(receiptData, productId);
      case ReceiptPlatform.google:
        return _validateGoogle(receiptData, productId);
      case ReceiptPlatform.stripe:
        return _validateStripe(receiptData, productId);
    }
  }

  // -------------------------------------------------------------------------
  // Apple StoreKit 2 — mock
  // Replace with: POST https://api.storekit.itunes.apple.com/inApps/v1/transactions/{transactionId}
  // -------------------------------------------------------------------------
  Future<ValidationResult> _validateApple(
    String receiptData,
    String productId,
  ) async {
    // MOCK: parse the base64 receipt data to extract status
    // In production: call Apple's StoreKit 2 API with JWT auth
    if (receiptData.isEmpty) {
      return ValidationResult(
        status: ReceiptStatus.invalid,
        rawResponse: {'mock': true, 'error': 'empty_receipt'},
      );
    }
    // Simulate valid receipt for non-empty data
    return ValidationResult(
      status: ReceiptStatus.valid,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      rawResponse: {
        'mock': true,
        'environment': 'Sandbox',
        'product_id': productId,
        'status': 0,
      },
    );
  }

  // -------------------------------------------------------------------------
  // Google Play Billing — mock
  // Replace with: GET https://androidpublisher.googleapis.com/androidpublisher/v3/...
  // -------------------------------------------------------------------------
  Future<ValidationResult> _validateGoogle(
    String receiptData,
    String productId,
  ) async {
    if (receiptData.isEmpty) {
      return ValidationResult(
        status: ReceiptStatus.invalid,
        rawResponse: {'mock': true, 'error': 'empty_receipt'},
      );
    }
    return ValidationResult(
      status: ReceiptStatus.valid,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      rawResponse: {
        'mock': true,
        'kind': 'androidpublisher#subscriptionPurchase',
        'productId': productId,
        'paymentState': 1,
      },
    );
  }

  // -------------------------------------------------------------------------
  // Stripe — mock
  // Replace with: GET https://api.stripe.com/v1/subscriptions/{id}
  // -------------------------------------------------------------------------
  Future<ValidationResult> _validateStripe(
    String receiptData,
    String productId,
  ) async {
    if (receiptData.isEmpty) {
      return ValidationResult(
        status: ReceiptStatus.invalid,
        rawResponse: {'mock': true, 'error': 'empty_receipt'},
      );
    }
    return ValidationResult(
      status: ReceiptStatus.valid,
      rawResponse: {
        'mock': true,
        'object': 'subscription',
        'status': 'active',
        'product': productId,
      },
    );
  }
}

/// Internal result from a store validation call.
class ValidationResult {
  final ReceiptStatus status;
  final DateTime? expiresAt;
  final Map<String, dynamic> rawResponse;

  const ValidationResult({
    required this.status,
    this.expiresAt,
    this.rawResponse = const {},
  });
}
