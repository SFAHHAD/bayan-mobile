import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/cache_service.dart';

// ---------------------------------------------------------------------------
// Realtime stream: auto-refreshes on any DB change via Supabase Realtime
// ---------------------------------------------------------------------------
final diwanListProvider = StreamProvider.autoDispose<List<Diwan>>((ref) {
  return ref.read(diwanRepositoryProvider).watchPublicDiwans();
});

// ---------------------------------------------------------------------------
// Offline-aware notifier: serves cache when connectivity is lost
// ---------------------------------------------------------------------------
class DiwanListNotifier extends AutoDisposeAsyncNotifier<List<Diwan>> {
  StreamSubscription<List<Diwan>>? _realtimeSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _online = true;

  @override
  Future<List<Diwan>> build() async {
    ref.onDispose(() {
      _realtimeSub?.cancel();
      _connectivitySub?.cancel();
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) => _onConnectivityChanged(results),
    );

    final initial = await _tryLoad();
    _subscribeRealtime();
    return initial;
  }

  Future<List<Diwan>> _tryLoad() async {
    final connectivity = await Connectivity().checkConnectivity();
    _online = !connectivity.contains(ConnectivityResult.none);

    if (_online) {
      try {
        final list = await ref.read(diwanRepositoryProvider).getPublic();
        await CacheService.cacheDiwans(list);
        return list;
      } catch (_) {
        return CacheService.getCachedDiwans() ?? [];
      }
    } else {
      return CacheService.getCachedDiwans() ?? [];
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = ref
        .read(diwanRepositoryProvider)
        .watchPublicDiwans()
        .listen(
          (diwans) async {
            state = AsyncValue.data(diwans);
            await CacheService.cacheDiwans(diwans);
          },
          onError: (Object e) {
            if (state is! AsyncData) {
              final cached = CacheService.getCachedDiwans();
              if (cached != null) state = AsyncValue.data(cached);
            }
          },
        );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final nowOnline = !results.contains(ConnectivityResult.none);
    if (!_online && nowOnline) {
      _online = true;
      _subscribeRealtime();
    } else if (_online && !nowOnline) {
      _online = false;
    }
  }

  Future<void> incrementListener(String diwanId) async {
    try {
      await ref.read(diwanRepositoryProvider).incrementListenerCount(diwanId);
    } catch (_) {}
  }

  Future<void> decrementListener(String diwanId) async {
    try {
      await ref.read(diwanRepositoryProvider).decrementListenerCount(diwanId);
    } catch (_) {}
  }
}

final diwanNotifierProvider =
    AsyncNotifierProvider.autoDispose<DiwanListNotifier, List<Diwan>>(
      DiwanListNotifier.new,
    );
