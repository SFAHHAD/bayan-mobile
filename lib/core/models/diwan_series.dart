class DiwanSeries {
  final String id;
  final String hostId;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? category;
  final int episodeCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiwanSeries({
    required this.id,
    required this.hostId,
    required this.title,
    this.description,
    this.coverUrl,
    this.category,
    this.episodeCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiwanSeries.fromMap(Map<String, dynamic> map) {
    return DiwanSeries(
      id: map['id'] as String,
      hostId: map['host_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      coverUrl: map['cover_url'] as String?,
      category: map['category'] as String?,
      episodeCount: (map['episode_count'] as int?) ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'host_id': hostId,
    'title': title,
    'description': description,
    'cover_url': coverUrl,
    'category': category,
    'is_active': isActive,
  };

  DiwanSeries copyWith({
    String? title,
    String? description,
    String? coverUrl,
    String? category,
    int? episodeCount,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return DiwanSeries(
      id: id,
      hostId: hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      episodeCount: episodeCount ?? this.episodeCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty => episodeCount == 0;
  bool get hasEpisodes => episodeCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiwanSeries &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
