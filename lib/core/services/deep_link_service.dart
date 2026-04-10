import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:bayan/core/models/deep_link.dart';

/// Listens for incoming deep links using `app_links` and exposes a stream of
/// parsed [DeepLink] objects.
///
/// Supported URI scheme: `bayan://diwan/{id}` and `bayan://profile/{id}`.
class DeepLinkService {
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  final StreamController<DeepLink> _controller =
      StreamController<DeepLink>.broadcast();

  DeepLinkService() : _appLinks = AppLinks();

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Broadcast stream of parsed deep links.
  Stream<DeepLink> get onLink => _controller.stream;

  /// Starts listening for incoming links. Call once in your app startup.
  Future<void> init() async {
    // Handle the initial link (app opened cold from a deep link).
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _emit(initial);
    }

    // Listen for links while app is in foreground / background.
    _subscription = _appLinks.uriLinkStream.listen(
      _emit,
      onError: (_) {
        /* Silently ignore malformed URIs */
      },
    );
  }

  /// Disposes the underlying stream subscription.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  void _emit(Uri uri) {
    final link = DeepLink.fromUri(uri);
    if (link != null) _controller.add(link);
  }
}
