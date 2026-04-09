import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bayan/core/models/diwan.dart';

class CacheService {
  static const _boxName = 'bayan_cache';
  static const _diwansKey = 'diwans';
  static const _ttlKey = 'diwans_ttl';

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // -------------------------------------------------------------------------
  // Diwans
  // -------------------------------------------------------------------------

  static Future<void> cacheDiwans(List<Diwan> diwans) async {
    final maps = diwans
        .map(
          (d) => {
            ...d.toMap(),
            'id': d.id,
            'created_at': d.createdAt.toIso8601String(),
            'updated_at': d.updatedAt.toIso8601String(),
            if (d.lastActivityAt != null)
              'last_activity_at': d.lastActivityAt!.toIso8601String(),
          },
        )
        .toList();
    await _box.put(_diwansKey, jsonEncode(maps));
    await _box.put(_ttlKey, DateTime.now().millisecondsSinceEpoch);
  }

  static List<Diwan>? getCachedDiwans({
    Duration maxAge = const Duration(hours: 1),
  }) {
    final raw = _box.get(_diwansKey) as String?;
    if (raw == null) return null;

    final ttlMs = _box.get(_ttlKey) as int?;
    if (ttlMs != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ttlMs),
      );
      if (age > maxAge) return null;
    }

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((m) => Diwan.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static bool hasCachedDiwans() {
    return _box.containsKey(_diwansKey);
  }

  static Future<void> clearDiwans() async {
    await _box.delete(_diwansKey);
    await _box.delete(_ttlKey);
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
