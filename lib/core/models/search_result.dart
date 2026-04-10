enum SearchEntityType { profile, diwan, voice, unknown }

class SearchResult {
  final SearchEntityType entityType;
  final String id;
  final String title;
  final String subtitle;
  final String? avatarUrl;

  const SearchResult({
    required this.entityType,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.avatarUrl,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      entityType: _typeFromString(map['entity_type'] as String? ?? ''),
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  static SearchEntityType _typeFromString(String s) {
    switch (s) {
      case 'profile':
        return SearchEntityType.profile;
      case 'diwan':
        return SearchEntityType.diwan;
      case 'voice':
        return SearchEntityType.voice;
      default:
        return SearchEntityType.unknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchResult &&
          other.entityType == entityType &&
          other.id == id);

  @override
  int get hashCode => Object.hash(entityType, id);
}
