import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/repositories/diwan_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockSupabaseClient mockClient;
  late DiwanRepository sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    sut = DiwanRepository(mockClient);
  });

  group('DiwanRepository', () {
    test('is instantiated with a SupabaseClient', () {
      expect(sut, isA<DiwanRepository>());
    });

    test('Diwan.fromMap parses all fields correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'uuid-1',
        'title': 'ديوان الشعر',
        'description': 'مجموعة قصائد',
        'owner_id': 'owner-uuid',
        'is_public': true,
        'cover_url': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final diwan = Diwan.fromMap(map);

      expect(diwan.id, 'uuid-1');
      expect(diwan.title, 'ديوان الشعر');
      expect(diwan.description, 'مجموعة قصائد');
      expect(diwan.ownerId, 'owner-uuid');
      expect(diwan.isPublic, isTrue);
      expect(diwan.coverUrl, isNull);
    });

    test('Diwan.toMap excludes id and timestamps', () {
      final diwan = Diwan(
        id: 'uuid-1',
        title: 'ديوان',
        ownerId: 'owner-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = diwan.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['title'], 'ديوان');
      expect(map['owner_id'], 'owner-1');
    });

    test('Diwan.copyWith returns a new instance with updated fields', () {
      final original = Diwan(
        id: 'uuid-1',
        title: 'قديم',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = original.copyWith(title: 'جديد');

      expect(updated.id, original.id);
      expect(updated.title, 'جديد');
      expect(original.title, 'قديم');
    });
  });
}
