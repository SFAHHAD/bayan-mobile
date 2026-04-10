import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/block.dart';
import 'package:bayan/core/models/report.dart';
import 'package:bayan/core/models/search_result.dart';
import 'package:bayan/core/models/tag.dart';

// ---------------------------------------------------------------------------
// Unit tests: Block, Report, Tag, SearchResult models
// (pure model / serialisation — no network)
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 9, 0);

  // -------------------------------------------------------------------------
  // Block model
  // -------------------------------------------------------------------------
  group('Block model', () {
    Map<String, dynamic> blockMap() => {
      'blocker_id': 'user-a',
      'blocked_id': 'user-b',
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final b = Block.fromMap(blockMap());
      expect(b.blockerId, 'user-a');
      expect(b.blockedId, 'user-b');
      expect(b.createdAt, now);
    });

    test('toMap round-trip', () {
      final original = Block.fromMap(blockMap());
      final map = original.toMap();
      expect(map['blocker_id'], 'user-a');
      expect(map['blocked_id'], 'user-b');
    });

    test('equality is by blocker+blocked pair', () {
      final a = Block.fromMap(blockMap());
      final b = Block.fromMap(blockMap());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different blocked_id produces different hash', () {
      final a = Block.fromMap(blockMap());
      final c = Block.fromMap({...blockMap(), 'blocked_id': 'user-c'});
      expect(a, isNot(equals(c)));
    });
  });

  // -------------------------------------------------------------------------
  // Report model
  // -------------------------------------------------------------------------
  group('Report model', () {
    Map<String, dynamic> reportMap({
      String type = 'diwan',
      String status = 'pending',
    }) => {
      'id': 'report-001',
      'reporter_id': 'user-a',
      'content_type': type,
      'content_id': 'content-001',
      'reason': 'محتوى مسيء',
      'description': null,
      'status': status,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses diwan content type', () {
      final r = Report.fromMap(reportMap(type: 'diwan'));
      expect(r.contentType, ReportContentType.diwan);
      expect(r.status, ReportStatus.pending);
    });

    test('fromMap parses all content types', () {
      for (final entry in {
        'diwan': ReportContentType.diwan,
        'voice': ReportContentType.voice,
        'user': ReportContentType.user,
        'message': ReportContentType.message,
      }.entries) {
        final r = Report.fromMap(reportMap(type: entry.key));
        expect(
          r.contentType,
          entry.value,
          reason: 'Failed for type: ${entry.key}',
        );
      }
    });

    test('fromMap parses all statuses', () {
      for (final entry in {
        'pending': ReportStatus.pending,
        'reviewed': ReportStatus.reviewed,
        'resolved': ReportStatus.resolved,
        'dismissed': ReportStatus.dismissed,
      }.entries) {
        final r = Report.fromMap(reportMap(status: entry.key));
        expect(
          r.status,
          entry.value,
          reason: 'Failed for status: ${entry.key}',
        );
      }
    });

    test('toMap excludes id and created_at', () {
      final r = Report.fromMap(reportMap());
      final map = r.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['content_type'], 'diwan');
      expect(map['reason'], 'محتوى مسيء');
    });
  });

  // -------------------------------------------------------------------------
  // Tag model
  // -------------------------------------------------------------------------
  group('Tag model', () {
    Map<String, dynamic> tagMap({String color = '#B8973F'}) => {
      'id': 'tag-001',
      'name': '#تقنية',
      'slug': 'tech',
      'color': color,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final t = Tag.fromMap(tagMap(color: '#4A90D9'));
      expect(t.name, '#تقنية');
      expect(t.slug, 'tech');
      expect(t.color, '#4A90D9');
    });

    test('default color fallback', () {
      final map = Map<String, dynamic>.from(tagMap())..remove('color');
      final t = Tag.fromMap(map);
      expect(t.color, '#B8973F');
    });

    test('equality by id', () {
      final a = Tag.fromMap(tagMap());
      final b = Tag.fromMap(tagMap());
      expect(a, equals(b));
    });

    test('toMap excludes id and created_at', () {
      final t = Tag.fromMap(tagMap());
      final map = t.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['name'], '#تقنية');
      expect(map['slug'], 'tech');
    });
  });

  // -------------------------------------------------------------------------
  // SearchResult model
  // -------------------------------------------------------------------------
  group('SearchResult model', () {
    test('fromMap parses profile entity type', () {
      final r = SearchResult.fromMap({
        'entity_type': 'profile',
        'id': 'user-001',
        'title': 'Ahmed Al-Mansour',
        'subtitle': 'مهندس برمجيات',
        'avatar_url': 'https://cdn.example.com/avatar.jpg',
      });
      expect(r.entityType, SearchEntityType.profile);
      expect(r.title, 'Ahmed Al-Mansour');
      expect(r.avatarUrl, isNotNull);
    });

    test('fromMap parses diwan entity type', () {
      final r = SearchResult.fromMap({
        'entity_type': 'diwan',
        'id': 'diwan-001',
        'title': 'ديوان التقنية',
        'subtitle': 'نقاشات تقنية يومية',
        'avatar_url': null,
      });
      expect(r.entityType, SearchEntityType.diwan);
      expect(r.avatarUrl, isNull);
    });

    test('fromMap parses voice entity type', () {
      final r = SearchResult.fromMap({
        'entity_type': 'voice',
        'id': 'voice-001',
        'title': 'مقطع صوتي',
        'subtitle': 'Ahmed',
        'avatar_url': null,
      });
      expect(r.entityType, SearchEntityType.voice);
    });

    test('unknown entity_type defaults to unknown', () {
      final r = SearchResult.fromMap({
        'entity_type': 'something_new',
        'id': 'x-001',
        'title': 'X',
        'subtitle': '',
        'avatar_url': null,
      });
      expect(r.entityType, SearchEntityType.unknown);
    });

    test('equality by entityType + id', () {
      final a = SearchResult.fromMap({
        'entity_type': 'diwan',
        'id': 'diwan-001',
        'title': 'A',
        'subtitle': '',
        'avatar_url': null,
      });
      final b = SearchResult.fromMap({
        'entity_type': 'diwan',
        'id': 'diwan-001',
        'title': 'B',
        'subtitle': 'different',
        'avatar_url': null,
      });
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
