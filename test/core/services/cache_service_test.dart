import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/diwan.dart';

void main() {
  final now = DateTime(2026, 4, 9, 12);

  Diwan makeDiwan(String id) => Diwan(
    id: id,
    title: 'Test Diwan $id',
    isLive: true,
    listenerCount: 5,
    voiceCount: 3,
    createdAt: now,
    updatedAt: now,
  );

  group('Diwan model serialisation (used by CacheService)', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final original = makeDiwan('abc-123');
      final map = {
        ...original.toMap(),
        'id': original.id,
        'created_at': original.createdAt.toIso8601String(),
        'updated_at': original.updatedAt.toIso8601String(),
      };
      final restored = Diwan.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.isLive, original.isLive);
      expect(restored.listenerCount, original.listenerCount);
      expect(restored.voiceCount, original.voiceCount);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = {
        'id': 'x',
        'title': 'Minimal',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final d = Diwan.fromMap(map);

      expect(d.isLive, isFalse);
      expect(d.listenerCount, 0);
      expect(d.voiceCount, 0);
      expect(d.isPublic, isTrue);
      expect(d.hostName, isNull);
    });

    test('copyWith produces updated copy without mutating original', () {
      final original = makeDiwan('z');
      final updated = original.copyWith(listenerCount: 99, isLive: false);

      expect(updated.listenerCount, 99);
      expect(updated.isLive, isFalse);
      expect(original.listenerCount, 5);
      expect(original.isLive, isTrue);
    });

    test('multiple diwans round-trip through list serialisation', () {
      final diwans = ['d1', 'd2', 'd3'].map(makeDiwan).toList();
      final maps = diwans
          .map(
            (d) => {
              ...d.toMap(),
              'id': d.id,
              'created_at': d.createdAt.toIso8601String(),
              'updated_at': d.updatedAt.toIso8601String(),
            },
          )
          .toList();

      final restored = maps.map(Diwan.fromMap).toList();
      expect(
        restored.map((d) => d.id).toList(),
        equals(diwans.map((d) => d.id).toList()),
      );
    });
  });
}
