import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/models/deep_link.dart';
import 'package:bayan/core/models/user_stats.dart';

// ---------------------------------------------------------------------------
// Unit tests: Message, UserStats, DeepLink models
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 10, 0);

  // -------------------------------------------------------------------------
  // Message model
  // -------------------------------------------------------------------------
  group('Message model', () {
    Map<String, dynamic> msgMap({String type = 'text', String? senderName}) => {
      'id': 'msg-001',
      'diwan_id': 'diwan-001',
      'sender_id': 'user-001',
      'content': 'مرحباً بالجميع',
      'type': type,
      'sender_name': senderName,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses text message', () {
      final m = Message.fromMap(msgMap());
      expect(m.type, MessageType.text);
      expect(m.content, 'مرحباً بالجميع');
      expect(m.senderName, isNull);
    });

    test('fromMap parses system message', () {
      final m = Message.fromMap(msgMap(type: 'system', senderName: 'النظام'));
      expect(m.type, MessageType.system);
      expect(m.senderName, 'النظام');
    });

    test('unknown type defaults to text', () {
      final m = Message.fromMap({...msgMap(), 'type': 'broadcast'});
      expect(m.type, MessageType.text);
    });

    test('null type defaults to text', () {
      final map = Map<String, dynamic>.from(msgMap())..remove('type');
      final m = Message.fromMap(map);
      expect(m.type, MessageType.text);
    });

    test('toMap includes type and sender_name', () {
      final m = Message.fromMap(msgMap(type: 'system', senderName: 'النظام'));
      final map = m.toMap();
      expect(map['type'], 'system');
      expect(map['sender_name'], 'النظام');
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
    });

    test('copyWith updates type without mutation', () {
      final original = Message.fromMap(msgMap());
      final updated = original.copyWith(type: MessageType.system);
      expect(updated.type, MessageType.system);
      expect(original.type, MessageType.text);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Message.fromMap(msgMap());
      final updated = original.copyWith(content: 'محتوى جديد');
      expect(updated.content, 'محتوى جديد');
      expect(updated.id, original.id);
      expect(updated.diwanId, original.diwanId);
    });

    test('sender_id is nullable (system messages)', () {
      final map = Map<String, dynamic>.from(msgMap(type: 'system'))
        ..['sender_id'] = null;
      final m = Message.fromMap(map);
      expect(m.senderId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // UserStats model
  // -------------------------------------------------------------------------
  group('UserStats model', () {
    Map<String, dynamic> statsMap({
      int liveMinutes = 180,
      double hours = 3.0,
      int diwans = 5,
      int peakListeners = 120,
      int followers = 200,
      int voices = 15,
      int score = 300,
    }) => {
      'user_id': 'user-001',
      'total_live_minutes': liveMinutes,
      'total_hours_hosted': hours,
      'total_diwans_hosted': diwans,
      'peak_listeners_ever': peakListeners,
      'follower_count': followers,
      'voice_count': voices,
      'influence_score': score,
    };

    test('fromMap parses all fields', () {
      final s = UserStats.fromMap(statsMap());
      expect(s.userId, 'user-001');
      expect(s.totalLiveMinutes, 180);
      expect(s.totalHoursHosted, 3.0);
      expect(s.totalDiwansHosted, 5);
      expect(s.peakListenersEver, 120);
      expect(s.followerCount, 200);
      expect(s.voiceCount, 15);
      expect(s.influenceScore, 300);
    });

    test('fromMap handles string total_hours_hosted (Supabase NUMERIC)', () {
      final map = {...statsMap(), 'total_hours_hosted': '2.5'};
      final s = UserStats.fromMap(map);
      expect(s.totalHoursHosted, 2.5);
    });

    test('fromMap defaults all fields to 0 when null', () {
      final s = UserStats.fromMap({'user_id': 'user-002'});
      expect(s.totalLiveMinutes, 0);
      expect(s.influenceScore, 0);
    });

    test('UserStats.empty factory creates zero stats', () {
      final s = UserStats.empty('user-003');
      expect(s.userId, 'user-003');
      expect(s.influenceScore, 0);
      expect(s.peakListenersEver, 0);
    });

    test('copyWith preserves userId and updates only specified fields', () {
      final original = UserStats.fromMap(statsMap());
      final updated = original.copyWith(influenceScore: 999, voiceCount: 50);
      expect(updated.influenceScore, 999);
      expect(updated.voiceCount, 50);
      expect(updated.userId, 'user-001');
      expect(updated.totalLiveMinutes, 180);
    });
  });

  // -------------------------------------------------------------------------
  // DeepLink model
  // -------------------------------------------------------------------------
  group('DeepLink model', () {
    test('fromUri parses bayan://diwan/{id}', () {
      final uri = Uri.parse('bayan://diwan/abc-123');
      final link = DeepLink.fromUri(uri);
      expect(link, isNotNull);
      expect(link!.target, DeepLinkTarget.diwan);
      expect(link.id, 'abc-123');
    });

    test('fromUri parses bayan://profile/{id}', () {
      final uri = Uri.parse('bayan://profile/user-456');
      final link = DeepLink.fromUri(uri);
      expect(link, isNotNull);
      expect(link!.target, DeepLinkTarget.profile);
      expect(link.id, 'user-456');
    });

    test('fromUri returns unknown target for unrecognised path', () {
      final uri = Uri.parse('bayan://settings/notifications');
      final link = DeepLink.fromUri(uri);
      expect(link, isNotNull);
      expect(link!.target, DeepLinkTarget.unknown);
    });

    test('fromUri returns null for non-bayan scheme', () {
      final uri = Uri.parse('https://bayan.app/diwan/abc-123');
      final link = DeepLink.fromUri(uri);
      expect(link, isNull);
    });

    test('fromUri returns null when id segment is missing', () {
      final uri = Uri.parse('bayan://diwan');
      final link = DeepLink.fromUri(uri);
      expect(link, isNull);
    });

    test('query params are captured', () {
      final uri = Uri.parse('bayan://diwan/abc-123?ref=share');
      final link = DeepLink.fromUri(uri);
      expect(link, isNotNull);
      expect(link!.params['ref'], 'share');
    });
  });
}
