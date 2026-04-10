/// Dynamic SEO/OG metadata for a Diwan shared link.
class SeoMetadata {
  final String diwanId;
  final String title;
  final String description;
  final String? imageUrl;
  final String canonicalUrl;
  final bool isLive;
  final int listenerCount;

  const SeoMetadata({
    required this.diwanId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.canonicalUrl,
    this.isLive = false,
    this.listenerCount = 0,
  });

  static const _defaultImage = 'https://bayan.app/og-default.png';

  String get resolvedImageUrl => imageUrl ?? _defaultImage;

  String get ogTitle =>
      isLive ? '🔴 مباشر الآن — $title | بيان' : '$title | بيان';

  String get ogDescription => description.isNotEmpty
      ? description
      : isLive
      ? '$listenerCount مستمع الآن — انضم للحوار على بيان!'
      : 'اكتشف أفضل المحتوى الصوتي العربي على منصة بيان.';

  String get cacheControl => isLive
      ? 'public, max-age=10, stale-while-revalidate=30'
      : 'public, max-age=300, stale-while-revalidate=600';

  factory SeoMetadata.fromMap(Map<String, dynamic> map) {
    return SeoMetadata(
      diwanId: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      imageUrl: map['cover_url'] as String?,
      canonicalUrl: 'https://bayan.app/diwan/${map['id']}',
      isLive: (map['is_live'] as bool?) ?? false,
      listenerCount: (map['listener_count'] as int?) ?? 0,
    );
  }

  factory SeoMetadata.defaultMeta() => const SeoMetadata(
    diwanId: '',
    title: 'بيان — منصة المحتوى العربي المتميز',
    description: 'انضم إلى أفضل منصة للمحتوى الصوتي العربي. ديوان حي أو مسجل.',
    canonicalUrl: 'https://bayan.app',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeoMetadata &&
          runtimeType == other.runtimeType &&
          diwanId == other.diwanId;

  @override
  int get hashCode => diwanId.hashCode;
}
