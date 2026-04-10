/// A single result row returned by the `get_personalized_feed` RPC.
class FeedItem {
  final String diwanId;
  final String title;
  final String? description;
  final String? ownerId;
  final String? hostName;
  final String? coverUrl;
  final bool isLive;
  final bool isPremium;
  final int entryFee;
  final int listenerCount;
  final String? seriesId;
  final String moderationStatus;
  final double score;
  final double scoreInterests;
  final double scoreSocial;
  final double scoreTrending;
  final DateTime createdAt;

  const FeedItem({
    required this.diwanId,
    required this.title,
    this.description,
    this.ownerId,
    this.hostName,
    this.coverUrl,
    this.isLive = false,
    this.isPremium = false,
    this.entryFee = 0,
    this.listenerCount = 0,
    this.seriesId,
    this.moderationStatus = 'approved',
    this.score = 0.0,
    this.scoreInterests = 0.0,
    this.scoreSocial = 0.0,
    this.scoreTrending = 0.0,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory FeedItem.fromMap(Map<String, dynamic> map) {
    return FeedItem(
      diwanId: map['diwan_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      ownerId: map['owner_id'] as String?,
      hostName: map['host_name'] as String?,
      coverUrl: map['cover_url'] as String?,
      isLive: (map['is_live'] as bool?) ?? false,
      isPremium: (map['is_premium'] as bool?) ?? false,
      entryFee: (map['entry_fee'] as int?) ?? 0,
      listenerCount: (map['listener_count'] as int?) ?? 0,
      seriesId: map['series_id'] as String?,
      moderationStatus: (map['moderation_status'] as String?) ?? 'approved',
      score: _toDouble(map['score']),
      scoreInterests: _toDouble(map['score_interests']),
      scoreSocial: _toDouble(map['score_social']),
      scoreTrending: _toDouble(map['score_trending']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isFree => !isPremium || entryFee == 0;
  bool get isPartOfSeries => seriesId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedItem &&
          runtimeType == other.runtimeType &&
          diwanId == other.diwanId;

  @override
  int get hashCode => diwanId.hashCode;
}
