enum TierType { gold, platinum, founder }

TierType tierTypeFromString(String? s) {
  switch (s) {
    case 'gold':
      return TierType.gold;
    case 'platinum':
      return TierType.platinum;
    case 'founder':
      return TierType.founder;
    default:
      return TierType.gold;
  }
}

class SubscriptionTier {
  final String id;
  final String name;
  final TierType type;
  final int priceTokens;
  final int? durationDays;
  final Map<String, dynamic> features;
  final bool isActive;
  final DateTime createdAt;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.type,
    required this.priceTokens,
    this.durationDays,
    this.features = const {},
    this.isActive = true,
    required this.createdAt,
  });

  static String typeToString(TierType t) {
    switch (t) {
      case TierType.gold:
        return 'gold';
      case TierType.platinum:
        return 'platinum';
      case TierType.founder:
        return 'founder';
    }
  }

  static int tierRank(TierType t) {
    switch (t) {
      case TierType.gold:
        return 1;
      case TierType.platinum:
        return 2;
      case TierType.founder:
        return 3;
    }
  }

  factory SubscriptionTier.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['features'];
    final Map<String, dynamic> features;
    if (rawFeatures is Map<String, dynamic>) {
      features = rawFeatures;
    } else if (rawFeatures is Map) {
      features = Map<String, dynamic>.from(rawFeatures);
    } else {
      features = {};
    }

    return SubscriptionTier(
      id: map['id'] as String,
      name: map['name'] as String,
      type: tierTypeFromString(map['type'] as String?),
      priceTokens: (map['price_tokens'] as int?) ?? 0,
      durationDays: map['duration_days'] as int?,
      features: features,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isLifetime => durationDays == null;
  String get typeString => typeToString(type);
  int get rank => tierRank(type);

  bool get hasPrivateRooms => (features['private_rooms'] as bool?) ?? false;
  bool get hasAdvancedAnalytics =>
      (features['advanced_analytics'] as bool?) ?? false;
  bool get hasPrioritySupport =>
      (features['priority_support'] as bool?) ?? false;
  String get badgeColor => (features['badge_color'] as String?) ?? '#D4AF37';

  /// Whether this tier grants access to [required].
  bool grantsAccessTo(TierType required) => rank >= tierRank(required);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
