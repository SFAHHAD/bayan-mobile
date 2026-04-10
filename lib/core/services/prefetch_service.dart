import 'package:hive_flutter/hive_flutter.dart';
import 'package:bayan/core/repositories/recommendation_repository.dart';

/// Pre-fetches the personalised feed in background and stores a warm cache
/// of likely-to-be-visited Diwan IDs + metadata in Hive.
///
/// UI layer can call [warmImages] with a BuildContext to pre-load cover images
/// (not done here to keep the service free of Flutter widget dependencies).
class PrefetchService {
  final RecommendationRepository _repo;

  PrefetchService(this._repo);

  static const _boxName = 'prefetch_cache';
  static const _keyIds = 'diwan_ids';
  static const _keyMeta = 'diwan_meta';
  static const _keyTs = 'timestamp';
  static const _ttlMs = 30 * 60 * 1000; // 30 minutes
  static const _fetchCount = 30;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Warms the cache with the top [_fetchCount] personalised feed results.
  /// Silently ignores any errors so it never disrupts app startup.
  Future<void> warmCache() async {
    try {
      final feed = await _repo.getPersonalisedFeed(
        limit: _fetchCount,
        offset: 0,
      );
      final ids = feed.map((f) => f.diwanId).toList();
      final meta = feed
          .map(
            (f) => {
              'id': f.diwanId,
              'score': f.score,
              'series_id': f.seriesId ?? '',
            },
          )
          .toList();
      final box = await _openBox();
      await box.put(_keyIds, ids);
      await box.put(_keyMeta, meta);
      await box.put(_keyTs, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // fire-and-forget — never propagate errors
    }
  }

  /// Returns cached Diwan IDs if the cache is still warm, otherwise [].
  List<String> getCachedDiwanIds() {
    if (!isCacheWarm) return [];
    final box = _openBoxSync();
    if (box == null) return [];
    final raw = box.get(_keyIds);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  /// Returns cached metadata maps (id, score, series_id).
  List<Map<String, dynamic>> getCachedMeta() {
    if (!isCacheWarm) return [];
    final box = _openBoxSync();
    if (box == null) return [];
    final raw = box.get(_keyMeta);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  bool get isCacheWarm {
    final box = _openBoxSync();
    if (box == null) return false;
    final ts = box.get(_keyTs) as int?;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < _ttlMs;
  }

  /// Predicts whether [diwanId] is likely to be visited (is in warm cache).
  bool isPredicted(String diwanId) => getCachedDiwanIds().contains(diwanId);

  Future<void> invalidate() async {
    final box = await _openBox();
    await box.clear();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  Box<dynamic>? _openBoxSync() {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return null;
  }
}
