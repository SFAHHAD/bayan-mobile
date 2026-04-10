import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/deep_link.dart';
import 'package:bayan/core/services/deep_link_service.dart';

// -------------------------------------------------------------------------
// Service provider (singleton, initialized at app start)
// -------------------------------------------------------------------------
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(service.dispose);
  return service;
});

// -------------------------------------------------------------------------
// State: the most-recently received deep link
// -------------------------------------------------------------------------
class DeepLinkNotifier extends StateNotifier<DeepLink?> {
  final Ref _ref;
  StreamSubscription<DeepLink>? _sub;

  DeepLinkNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final service = _ref.read(deepLinkServiceProvider);
    await service.init();
    _sub = service.onLink.listen((link) {
      state = link;
    });
  }

  /// Clears the pending deep link after the UI has handled it.
  void consume() => state = null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final deepLinkProvider = StateNotifierProvider<DeepLinkNotifier, DeepLink?>(
  (ref) => DeepLinkNotifier(ref),
);
