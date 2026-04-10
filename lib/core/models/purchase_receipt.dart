import 'package:bayan/core/models/subscription_tier.dart';

enum ReceiptPlatform { apple, google, stripe }

enum ReceiptStatus { pending, valid, invalid, expired, refunded }

class PurchaseReceipt {
  final String id;
  final String userId;
  final ReceiptPlatform platform;
  final String productId;
  final String? transactionId;
  final String receiptData;
  final ReceiptStatus status;
  final DateTime? validatedAt;
  final TierType? tierType;
  final Map<String, dynamic>? rawResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseReceipt({
    required this.id,
    required this.userId,
    required this.platform,
    required this.productId,
    this.transactionId,
    required this.receiptData,
    this.status = ReceiptStatus.pending,
    this.validatedAt,
    this.tierType,
    this.rawResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  static ReceiptPlatform _platformFromString(String? s) {
    switch (s) {
      case 'apple':
        return ReceiptPlatform.apple;
      case 'google':
        return ReceiptPlatform.google;
      default:
        return ReceiptPlatform.stripe;
    }
  }

  static String platformToString(ReceiptPlatform p) {
    switch (p) {
      case ReceiptPlatform.apple:
        return 'apple';
      case ReceiptPlatform.google:
        return 'google';
      case ReceiptPlatform.stripe:
        return 'stripe';
    }
  }

  static ReceiptStatus _statusFromString(String? s) {
    switch (s) {
      case 'valid':
        return ReceiptStatus.valid;
      case 'invalid':
        return ReceiptStatus.invalid;
      case 'expired':
        return ReceiptStatus.expired;
      case 'refunded':
        return ReceiptStatus.refunded;
      default:
        return ReceiptStatus.pending;
    }
  }

  static String statusToString(ReceiptStatus s) {
    switch (s) {
      case ReceiptStatus.pending:
        return 'pending';
      case ReceiptStatus.valid:
        return 'valid';
      case ReceiptStatus.invalid:
        return 'invalid';
      case ReceiptStatus.expired:
        return 'expired';
      case ReceiptStatus.refunded:
        return 'refunded';
    }
  }

  factory PurchaseReceipt.fromMap(Map<String, dynamic> map) {
    final rawResponse = map['raw_response'];
    final Map<String, dynamic>? parsedResponse;
    if (rawResponse is Map<String, dynamic>) {
      parsedResponse = rawResponse;
    } else if (rawResponse is Map) {
      parsedResponse = Map<String, dynamic>.from(rawResponse);
    } else {
      parsedResponse = null;
    }

    return PurchaseReceipt(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      platform: _platformFromString(map['platform'] as String?),
      productId: map['product_id'] as String,
      transactionId: map['transaction_id'] as String?,
      receiptData: map['receipt_data'] as String,
      status: _statusFromString(map['status'] as String?),
      validatedAt: map['validated_at'] == null
          ? null
          : DateTime.parse(map['validated_at'] as String),
      tierType: map['tier_type'] == null
          ? null
          : tierTypeFromString(map['tier_type'] as String?),
      rawResponse: parsedResponse,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get isValid => status == ReceiptStatus.valid;
  bool get isPending => status == ReceiptStatus.pending;
  bool get isTerminal =>
      status == ReceiptStatus.invalid ||
      status == ReceiptStatus.refunded ||
      status == ReceiptStatus.expired;

  String get platformString => platformToString(platform);
  String get statusString => statusToString(status);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseReceipt &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
