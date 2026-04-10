import 'package:bayan/core/models/subscription_tier.dart';

enum SubscriptionStatus { active, expired, cancelled, pending }

class UserSubscription {
  final String id;
  final String userId;
  final String tierId;
  final SubscriptionStatus status;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final String? paymentReference;
  final DateTime createdAt;

  /// Populated when the query joins with subscription_tiers.
  final TierType? tierType;
  final String? tierName;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.tierId,
    required this.status,
    required this.startsAt,
    this.expiresAt,
    this.paymentReference,
    required this.createdAt,
    this.tierType,
    this.tierName,
  });

  static SubscriptionStatus _statusFromString(String? s) {
    switch (s) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'pending':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.pending;
    }
  }

  static String statusToString(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.pending:
        return 'pending';
    }
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tierId: map['tier_id'] as String,
      status: _statusFromString(map['status'] as String?),
      startsAt: DateTime.parse(map['starts_at'] as String),
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.parse(map['expires_at'] as String),
      paymentReference: map['payment_reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      tierType: map['tier_type'] == null
          ? (map['type'] == null
                ? null
                : tierTypeFromString(map['type'] as String?))
          : tierTypeFromString(map['tier_type'] as String?),
      tierName: map['tier_name'] as String? ?? map['name'] as String?,
    );
  }

  // -------------------------------------------------------------------------
  // Derived state
  // -------------------------------------------------------------------------

  bool get isActive =>
      status == SubscriptionStatus.active &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isLifetime => expiresAt == null;

  bool get isExpired =>
      status == SubscriptionStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  String get statusString => statusToString(status);

  /// Remaining days (positive if still active, negative if expired).
  int? get remainingDays {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  /// Whether this subscription grants access to [required] tier features.
  bool grantsAccessTo(TierType required) {
    if (!isActive) return false;
    final rank = tierType == null ? 0 : SubscriptionTier.tierRank(tierType!);
    return rank >= SubscriptionTier.tierRank(required);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
