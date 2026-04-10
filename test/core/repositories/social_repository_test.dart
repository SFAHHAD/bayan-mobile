import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/follow.dart';
import 'package:bayan/core/models/profile.dart';

// ---------------------------------------------------------------------------
// Unit tests for Follow model and Profile social-stats model
// (no network — pure model/serialisation tests)
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 6, 0);

  // -------------------------------------------------------------------------
  // Follow model
  // -------------------------------------------------------------------------
  group('Follow model', () {
    Map<String, dynamic> followMap() => {
      'follower_id': 'user-a',
      'following_id': 'user-b',
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final f = Follow.fromMap(followMap());
      expect(f.followerId, 'user-a');
      expect(f.followingId, 'user-b');
      expect(f.createdAt, now);
    });

    test('toMap round-trip preserves fields', () {
      final original = Follow.fromMap(followMap());
      final restored = Follow.fromMap(original.toMap());
      expect(restored.followerId, original.followerId);
      expect(restored.followingId, original.followingId);
    });
  });

  // -------------------------------------------------------------------------
  // Profile social stats
  // -------------------------------------------------------------------------
  group('Profile social stats', () {
    Map<String, dynamic> profileMap({
      int follower = 0,
      int following = 0,
      int voice = 0,
      bool isFounder = false,
    }) => {
      'id': 'u1',
      'username': 'ahmed',
      'display_name': 'Ahmed Al-Mansour',
      'bio': null,
      'avatar_url': null,
      'is_founder': isFounder,
      'follower_count': follower,
      'following_count': following,
      'voice_count': voice,
      'created_at': now.toIso8601String(),
    };

    test('fromMap defaults counters to 0 when absent', () {
      final p = Profile.fromMap({
        'id': 'u2',
        'created_at': now.toIso8601String(),
      });
      expect(p.followerCount, 0);
      expect(p.followingCount, 0);
      expect(p.voiceCount, 0);
      expect(p.isFounder, isFalse);
    });

    test('fromMap parses all social fields', () {
      final p = Profile.fromMap(
        profileMap(follower: 10, following: 5, voice: 3, isFounder: true),
      );
      expect(p.followerCount, 10);
      expect(p.followingCount, 5);
      expect(p.voiceCount, 3);
      expect(p.isFounder, isTrue);
    });

    test('copyWith updates social fields without mutation', () {
      final original = Profile.fromMap(profileMap(follower: 10));
      final updated = original.copyWith(followerCount: 11, voiceCount: 2);
      expect(updated.followerCount, 11);
      expect(updated.voiceCount, 2);
      expect(original.followerCount, 10);
      expect(original.voiceCount, 0);
    });

    test('Founder flag is preserved through copyWith', () {
      final founder = Profile.fromMap(profileMap(isFounder: true));
      final copy = founder.copyWith(displayName: 'New Name');
      expect(copy.isFounder, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // AppNotification model
  // -------------------------------------------------------------------------
  group('AppNotification model', () {
    test('fromMap correctly parses diwan_live type', () {
      final map = <String, dynamic>{
        'id': 'notif-1',
        'user_id': 'user-1',
        'type': 'diwan_live',
        'title': 'ديوانية جديدة',
        'body': 'Ahmed بدأ ديوانية',
        'is_read': false,
        'data': <String, dynamic>{'diwan_id': 'diwan-1'},
        'created_at': now.toIso8601String(),
      };
      expect(map['type'], 'diwan_live');
      expect(map['is_read'], isFalse);
    });
  });
}
