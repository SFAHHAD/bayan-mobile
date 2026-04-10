enum DeepLinkTarget { diwan, profile, series, joinDiwan, referral, unknown }

class DeepLink {
  final DeepLinkTarget target;
  final String id;
  final Map<String, String> params;

  const DeepLink({
    required this.target,
    required this.id,
    this.params = const {},
  });

  /// Parses a URI of the form `bayan://diwan/{id}` or `bayan://profile/{id}`.
  static DeepLink? fromUri(Uri uri) {
    if (uri.scheme != 'bayan') return null;
    final segments = uri.pathSegments;
    final host = uri.host;

    final type = host.isNotEmpty
        ? host
        : (segments.isNotEmpty ? segments[0] : '');
    final id = segments.isNotEmpty
        ? (host.isNotEmpty
              ? segments[0]
              : (segments.length > 1 ? segments[1] : ''))
        : '';

    if (id.isEmpty) return null;

    switch (type) {
      case 'diwan':
        return DeepLink(
          target: DeepLinkTarget.diwan,
          id: id,
          params: Map.fromEntries(uri.queryParameters.entries),
        );
      case 'profile':
        return DeepLink(
          target: DeepLinkTarget.profile,
          id: id,
          params: Map.fromEntries(uri.queryParameters.entries),
        );
      case 'series':
        return DeepLink(
          target: DeepLinkTarget.series,
          id: id,
          params: Map.fromEntries(uri.queryParameters.entries),
        );
      case 'join':
        return DeepLink(
          target: DeepLinkTarget.joinDiwan,
          id: id,
          params: Map.fromEntries(uri.queryParameters.entries),
        );
      case 'referral':
        return DeepLink(
          target: DeepLinkTarget.referral,
          id: id,
          params: Map.fromEntries(uri.queryParameters.entries),
        );
      default:
        return DeepLink(target: DeepLinkTarget.unknown, id: id);
    }
  }

  @override
  String toString() => 'DeepLink(target: $target, id: $id)';
}
