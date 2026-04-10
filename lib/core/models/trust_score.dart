/// A user's computed Trust Score (0–100) with a breakdown of components.
class TrustScore {
  final String userId;
  final int score;
  final int xpComponent;
  final int streakComponent;
  final int governanceComponent;
  final int subscriptionComponent;

  const TrustScore({
    required this.userId,
    required this.score,
    required this.xpComponent,
    required this.streakComponent,
    required this.governanceComponent,
    required this.subscriptionComponent,
  });

  factory TrustScore.fromMap(String userId, Map<String, dynamic> map) {
    return TrustScore(
      userId: userId,
      score: (map['score'] as int?) ?? 0,
      xpComponent: (map['xp_component'] as int?) ?? 0,
      streakComponent: (map['streak_component'] as int?) ?? 0,
      governanceComponent: (map['governance_component'] as int?) ?? 0,
      subscriptionComponent: (map['subscription_component'] as int?) ?? 0,
    );
  }

  factory TrustScore.zero(String userId) => TrustScore(
    userId: userId,
    score: 0,
    xpComponent: 0,
    streakComponent: 0,
    governanceComponent: 0,
    subscriptionComponent: 0,
  );

  // -------------------------------------------------------------------------
  // Trust tiers
  // -------------------------------------------------------------------------

  TrustTier get tier => TrustTier.fromScore(score);

  double get normalizedScore => (score / 100.0).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustScore &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          score == other.score;

  @override
  int get hashCode => Object.hash(userId, score);

  @override
  String toString() =>
      'TrustScore(userId: $userId, score: $score, tier: ${tier.label})';
}

enum TrustTier {
  newcomer(0, 'قادم جديد', '🌱'),
  trusted(20, 'موثوق', '✅'),
  respected(40, 'محترم', '⭐'),
  pillar(60, 'ركيزة المجتمع', '🏛️'),
  guardian(80, 'حارس البيان', '🛡️');

  const TrustTier(this.minScore, this.label, this.badge);
  final int minScore;
  final String label;
  final String badge;

  static TrustTier fromScore(int score) {
    for (final tier in TrustTier.values.reversed) {
      if (score >= tier.minScore) return tier;
    }
    return TrustTier.newcomer;
  }
}
