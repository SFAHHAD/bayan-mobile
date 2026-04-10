class SpeakerQueueEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double prestigeScore;
  final DateTime requestedAt;

  const SpeakerQueueEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.prestigeScore,
    required this.requestedAt,
  });

  factory SpeakerQueueEntry.fromMap(Map<String, dynamic> map) {
    final rawScore = map['prestige_score'];
    final double score;
    if (rawScore is double) {
      score = rawScore;
    } else if (rawScore is int) {
      score = rawScore.toDouble();
    } else if (rawScore is String) {
      score = double.tryParse(rawScore) ?? 0.0;
    } else {
      score = 0.0;
    }

    return SpeakerQueueEntry(
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      prestigeScore: score,
      requestedAt: DateTime.parse(map['requested_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeakerQueueEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
