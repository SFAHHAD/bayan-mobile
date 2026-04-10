enum WalletTransactionType {
  giftSent,
  giftReceived,
  purchase,
  bonus,
  withdrawal,
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String userId;
  final WalletTransactionType type;
  final int amount;
  final int balanceAfter;
  final String? refDiwanId;
  final String? refUserId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.refDiwanId,
    this.refUserId,
    this.metadata = const {},
    required this.createdAt,
  });

  static WalletTransactionType _typeFromString(String? s) {
    switch (s) {
      case 'gift_sent':
        return WalletTransactionType.giftSent;
      case 'gift_received':
        return WalletTransactionType.giftReceived;
      case 'purchase':
        return WalletTransactionType.purchase;
      case 'bonus':
        return WalletTransactionType.bonus;
      case 'withdrawal':
        return WalletTransactionType.withdrawal;
      default:
        return WalletTransactionType.bonus;
    }
  }

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      userId: map['user_id'] as String,
      type: _typeFromString(map['type'] as String?),
      amount: (map['amount'] as int?) ?? 0,
      balanceAfter: (map['balance_after'] as int?) ?? 0,
      refDiwanId: map['ref_diwan_id'] as String?,
      refUserId: map['ref_user_id'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Whether this entry represents a credit (positive amount).
  bool get isCredit => amount > 0;

  /// The gift type from metadata (e.g. 'token', 'rose', 'star').
  String? get giftType => metadata['gift_type'] as String?;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
