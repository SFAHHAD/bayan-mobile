/// A single result from the semantic-search Edge Function.
class SemanticResult {
  final String diwanId;
  final double similarity;
  final String? title;
  final String? description;
  final String? ownerIdStr;
  final String? hostName;
  final String? coverUrl;
  final bool isLive;
  final bool isPremium;
  final int entryFee;
  final int listenerCount;
  final String? seriesId;

  const SemanticResult({
    required this.diwanId,
    required this.similarity,
    this.title,
    this.description,
    this.ownerIdStr,
    this.hostName,
    this.coverUrl,
    this.isLive = false,
    this.isPremium = false,
    this.entryFee = 0,
    this.listenerCount = 0,
    this.seriesId,
  });

  factory SemanticResult.fromMap(Map<String, dynamic> map) {
    return SemanticResult(
      diwanId: (map['id'] ?? map['diwan_id']) as String,
      similarity: _toDouble(map['similarity']),
      title: map['title'] as String?,
      description: map['description'] as String?,
      ownerIdStr: map['owner_id'] as String?,
      hostName: map['host_name'] as String?,
      coverUrl: map['cover_url'] as String?,
      isLive: (map['is_live'] as bool?) ?? false,
      isPremium: (map['is_premium'] as bool?) ?? false,
      entryFee: (map['entry_fee'] as int?) ?? 0,
      listenerCount: (map['listener_count'] as int?) ?? 0,
      seriesId: map['series_id'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  bool get isFree => entryFee == 0 && !isPremium;
  bool get isPartOfSeries => seriesId != null;

  /// Human-readable similarity percentage (0–100).
  String get similarityPercent => '${(similarity * 100).round()}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticResult &&
          runtimeType == other.runtimeType &&
          diwanId == other.diwanId;

  @override
  int get hashCode => diwanId.hashCode;
}
