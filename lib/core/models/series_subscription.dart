class SeriesSubscription {
  final String id;
  final String userId;
  final String seriesId;
  final bool notifyNew;
  final DateTime createdAt;

  const SeriesSubscription({
    required this.id,
    required this.userId,
    required this.seriesId,
    this.notifyNew = true,
    required this.createdAt,
  });

  factory SeriesSubscription.fromMap(Map<String, dynamic> map) {
    return SeriesSubscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      seriesId: map['series_id'] as String,
      notifyNew: (map['notify_new'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'series_id': seriesId,
    'notify_new': notifyNew,
  };

  SeriesSubscription copyWith({bool? notifyNew}) {
    return SeriesSubscription(
      id: id,
      userId: userId,
      seriesId: seriesId,
      notifyNew: notifyNew ?? this.notifyNew,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesSubscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
