import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/app_notification.dart';
import 'package:bayan/core/models/voice_clip.dart';

// ---------------------------------------------------------------------------
// Unit tests for VoiceClip model and AppNotification model
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 6, 0);

  // -------------------------------------------------------------------------
  // VoiceClip model
  // -------------------------------------------------------------------------
  group('VoiceClip model', () {
    Map<String, dynamic> clipMap({int duration = 120, String? publicUrl}) => {
      'id': 'clip-001',
      'diwan_id': 'diwan-001',
      'speaker_id': 'user-001',
      'title': 'لقطة صوتية من الجلسة',
      'storage_path': 'diwan-001/user-001/1234567890.m4a',
      'public_url': publicUrl,
      'duration_seconds': duration,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields correctly', () {
      final clip = VoiceClip.fromMap(
        clipMap(
          duration: 95,
          publicUrl: 'https://example.com/voice_clips/clip.m4a',
        ),
      );

      expect(clip.id, 'clip-001');
      expect(clip.diwanId, 'diwan-001');
      expect(clip.speakerId, 'user-001');
      expect(clip.title, 'لقطة صوتية من الجلسة');
      expect(clip.storagePath, 'diwan-001/user-001/1234567890.m4a');
      expect(clip.publicUrl, 'https://example.com/voice_clips/clip.m4a');
      expect(clip.durationSeconds, 95);
      expect(clip.createdAt, now);
    });

    test('duration getter returns correct Duration', () {
      final clip = VoiceClip.fromMap(clipMap(duration: 185));
      expect(clip.duration, const Duration(seconds: 185));
      expect(clip.duration.inMinutes, 3);
    });

    test('fromMap defaults durationSeconds to 0 when absent', () {
      final map = Map<String, dynamic>.from(clipMap())
        ..remove('duration_seconds');
      final clip = VoiceClip.fromMap(map);
      expect(clip.durationSeconds, 0);
    });

    test('publicUrl is nullable', () {
      final clip = VoiceClip.fromMap(clipMap());
      expect(clip.publicUrl, isNull);
    });

    test('toMap serialises correctly for DB insert', () {
      final clip = VoiceClip.fromMap(
        clipMap(duration: 60, publicUrl: 'https://cdn.example.com/test.m4a'),
      );
      final map = clip.toMap();

      expect(map['diwan_id'], 'diwan-001');
      expect(map['speaker_id'], 'user-001');
      expect(map['duration_seconds'], 60);
      expect(map['public_url'], 'https://cdn.example.com/test.m4a');
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = VoiceClip.fromMap(
        clipMap(duration: 30, publicUrl: 'https://old.url/clip.m4a'),
      );
      final updated = original.copyWith(
        title: 'عنوان جديد',
        durationSeconds: 45,
      );

      expect(updated.title, 'عنوان جديد');
      expect(updated.durationSeconds, 45);
      expect(updated.storagePath, original.storagePath);
      expect(updated.publicUrl, original.publicUrl);
      expect(original.title, 'لقطة صوتية من الجلسة');
    });

    test('toMap round-trip preserves storage path', () {
      final original = VoiceClip.fromMap(clipMap());
      final map = {
        ...original.toMap(),
        'id': original.id,
        'created_at': original.createdAt.toIso8601String(),
      };
      final restored = VoiceClip.fromMap(map);
      expect(restored.storagePath, original.storagePath);
      expect(restored.id, original.id);
    });
  });

  // -------------------------------------------------------------------------
  // AppNotification model
  // -------------------------------------------------------------------------
  group('AppNotification model', () {
    Map<String, dynamic> notifMap(String type, {bool isRead = false}) => {
      'id': 'notif-001',
      'user_id': 'user-001',
      'type': type,
      'title': 'عنوان الإشعار',
      'body': 'نص الإشعار',
      'is_read': isRead,
      'data': <String, dynamic>{'ref_id': 'abc'},
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses diwan_live type', () {
      final n = AppNotification.fromMap(notifMap('diwan_live'));
      expect(n.type, NotificationType.diwanLive);
      expect(n.isRead, isFalse);
    });

    test('fromMap parses new_follower type', () {
      final n = AppNotification.fromMap(notifMap('new_follower'));
      expect(n.type, NotificationType.newFollower);
    });

    test('fromMap parses speak_approved type', () {
      final n = AppNotification.fromMap(notifMap('speak_approved'));
      expect(n.type, NotificationType.speakApproved);
    });

    test('fromMap parses speak_rejected type', () {
      final n = AppNotification.fromMap(notifMap('speak_rejected'));
      expect(n.type, NotificationType.speakRejected);
    });

    test('fromMap parses voice_clip_shared type', () {
      final n = AppNotification.fromMap(notifMap('voice_clip_shared'));
      expect(n.type, NotificationType.voiceClipShared);
    });

    test('unknown type defaults to diwanLive', () {
      final n = AppNotification.fromMap(notifMap('unknown_type'));
      expect(n.type, NotificationType.diwanLive);
    });

    test('is_read field is parsed correctly', () {
      final read = AppNotification.fromMap(
        notifMap('new_follower', isRead: true),
      );
      expect(read.isRead, isTrue);
    });

    test('data JSONB field is parsed to Map', () {
      final n = AppNotification.fromMap(notifMap('diwan_live'));
      expect(n.data['ref_id'], 'abc');
    });

    test('copyWith isRead updates read status without mutation', () {
      final original = AppNotification.fromMap(notifMap('diwan_live'));
      final marked = original.copyWith(isRead: true);
      expect(marked.isRead, isTrue);
      expect(original.isRead, isFalse);
      expect(marked.id, original.id);
    });
  });
}
