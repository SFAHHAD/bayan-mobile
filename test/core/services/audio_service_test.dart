import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bayan/core/models/room_participant.dart';
import 'package:bayan/core/models/speak_request.dart';
import 'package:bayan/core/services/audio_service.dart';
import 'package:bayan/features/diwan/domain/models/room_role.dart';

// ---------------------------------------------------------------------------
// Mock AudioService for testing RoomNotifier in isolation
// ---------------------------------------------------------------------------
class MockAudioService extends Mock implements AudioService {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockAudioService mockAudio;
  late StreamController<List<RoomParticipant>> participantsCtrl;
  late StreamController<Set<String>> speakersCtrl;

  setUp(() {
    mockAudio = MockAudioService();
    participantsCtrl = StreamController<List<RoomParticipant>>.broadcast();
    speakersCtrl = StreamController<Set<String>>.broadcast();

    when(
      () => mockAudio.participantsStream,
    ).thenAnswer((_) => participantsCtrl.stream);
    when(
      () => mockAudio.activeSpeakersStream,
    ).thenAnswer((_) => speakersCtrl.stream);
    when(() => mockAudio.isConnected).thenReturn(false);
    when(() => mockAudio.isMicEnabled).thenReturn(false);
    when(mockAudio.dispose).thenReturn(null);
  });

  tearDown(() {
    participantsCtrl.close();
    speakersCtrl.close();
  });

  group('AudioService interface contract', () {
    test('participantsStream emits lists of RoomParticipant', () async {
      final participant = RoomParticipant(
        id: 'user-1',
        name: 'Test User',
        role: RoomRole.speaker,
        isMicEnabled: true,
        isLocal: true,
      );

      expect(mockAudio.participantsStream, emitsThrough(contains(participant)));

      participantsCtrl.add([participant]);
    });

    test('activeSpeakersStream emits Set of speaking IDs', () async {
      expect(
        mockAudio.activeSpeakersStream,
        emitsThrough(containsAll(['user-1', 'user-2'])),
      );

      speakersCtrl.add({'user-1', 'user-2'});
    });

    test('isMicEnabled and isConnected are accessible', () {
      expect(mockAudio.isMicEnabled, isFalse);
      expect(mockAudio.isConnected, isFalse);
    });
  });

  group('RoomRole', () {
    test('host canPublishAudio and canManageParticipants', () {
      expect(RoomRole.host.canPublishAudio, isTrue);
      expect(RoomRole.host.canManageParticipants, isTrue);
    });

    test('speaker canPublishAudio but cannot manage participants', () {
      expect(RoomRole.speaker.canPublishAudio, isTrue);
      expect(RoomRole.speaker.canManageParticipants, isFalse);
    });

    test('listener cannot publish or manage', () {
      expect(RoomRole.listener.canPublishAudio, isFalse);
      expect(RoomRole.listener.canManageParticipants, isFalse);
    });

    test(
      'RoomRoleX.fromString handles all values and defaults to listener',
      () {
        expect(RoomRoleX.fromString('host'), RoomRole.host);
        expect(RoomRoleX.fromString('speaker'), RoomRole.speaker);
        expect(RoomRoleX.fromString('listener'), RoomRole.listener);
        expect(RoomRoleX.fromString('unknown'), RoomRole.listener);
      },
    );

    test('value returns correct string for each role', () {
      expect(RoomRole.host.value, 'host');
      expect(RoomRole.speaker.value, 'speaker');
      expect(RoomRole.listener.value, 'listener');
    });
  });

  group('SpeakRequest model', () {
    test('fromMap correctly parses pending request', () {
      final map = {
        'id': 'req-001',
        'diwan_id': 'diwan-001',
        'user_id': 'user-001',
        'profiles': {'display_name': 'Ahmed'},
        'status': 'pending',
        'requested_at': '2026-04-09T10:00:00.000Z',
      };
      final req = SpeakRequest.fromMap(map);

      expect(req.id, 'req-001');
      expect(req.userName, 'Ahmed');
      expect(req.isPending, isTrue);
      expect(req.status, SpeakRequestStatus.pending);
    });

    test('fromMap defaults to userId when display_name missing', () {
      final map = {
        'id': 'req-002',
        'diwan_id': 'diwan-001',
        'user_id': 'user-002',
        'status': 'pending',
        'requested_at': '2026-04-09T10:00:00.000Z',
      };
      final req = SpeakRequest.fromMap(map);
      expect(req.userName, 'user-002');
    });

    test('copyWith updates status without mutation', () {
      final original = SpeakRequest.fromMap({
        'id': 'req-003',
        'diwan_id': 'd1',
        'user_id': 'u1',
        'status': 'pending',
        'requested_at': '2026-04-09T10:00:00.000Z',
      });
      final approved = original.copyWith(status: SpeakRequestStatus.approved);
      expect(approved.status, SpeakRequestStatus.approved);
      expect(original.status, SpeakRequestStatus.pending);
    });
  });

  group('RoomParticipant model', () {
    test('equality is based on id', () {
      const p1 = RoomParticipant(id: 'u1', name: 'A', role: RoomRole.speaker);
      const p2 = RoomParticipant(id: 'u1', name: 'B', role: RoomRole.listener);
      expect(p1, equals(p2));
    });

    test('copyWith updates fields without mutating original', () {
      const original = RoomParticipant(
        id: 'u1',
        name: 'A',
        role: RoomRole.listener,
      );
      final updated = original.copyWith(role: RoomRole.host, isSpeaking: true);
      expect(updated.role, RoomRole.host);
      expect(updated.isSpeaking, isTrue);
      expect(original.role, RoomRole.listener);
    });
  });
}
