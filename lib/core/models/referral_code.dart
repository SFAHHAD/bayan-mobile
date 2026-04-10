class ReferralCode {
  final String id;
  final String userId;
  final String code;
  final DateTime createdAt;

  const ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.createdAt,
  });

  factory ReferralCode.fromMap(Map<String, dynamic> map) {
    return ReferralCode(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      code: map['code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Deep-link URL that can be embedded in a QR code or share sheet.
  String get shareUrl => 'bayan://referral/$code';

  /// HTTPS fallback for web / open-graph previews.
  String get shareUrlHttps => 'https://bayan.app/join?ref=$code';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralCode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ReferralRecord {
  final String id;
  final String referrerId;
  final String referredId;
  final bool rewarded;
  final int rewardAmount;
  final DateTime createdAt;

  const ReferralRecord({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.rewarded,
    required this.rewardAmount,
    required this.createdAt,
  });

  factory ReferralRecord.fromMap(Map<String, dynamic> map) {
    return ReferralRecord(
      id: map['id'] as String,
      referrerId: map['referrer_id'] as String,
      referredId: map['referred_id'] as String,
      rewarded: (map['rewarded'] as bool?) ?? false,
      rewardAmount: (map['reward_amount'] as int?) ?? 50,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
