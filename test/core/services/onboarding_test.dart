import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bayan/core/models/onboarding_status.dart';
import 'package:bayan/core/models/prestige_category.dart';
import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/voice_print.dart';
import 'package:bayan/core/repositories/recommendation_repository.dart';
import 'package:bayan/core/repositories/voice_print_repository.dart';
import 'package:bayan/core/services/e2e_service.dart';
import 'package:bayan/core/services/feed_warmup_service.dart';
import 'package:bayan/core/services/prefetch_service.dart';
import 'package:bayan/core/services/voice_print_service.dart';
import 'package:cryptography/cryptography.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockRecommendationRepository extends Mock
    implements RecommendationRepository {}

class _MockPrefetchService extends Mock implements PrefetchService {}

class _MockE2EService extends Mock implements E2EService {}

class _MockVoicePrintRepository extends Mock implements VoicePrintRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FeedItem _feedItem(String id) =>
    FeedItem(diwanId: id, title: 'ديوان $id', createdAt: DateTime(2026));

VoicePrint _voicePrint({String id = 'vp-001'}) => VoicePrint(
  id: id,
  userId: 'user-001',
  encryptedAudio: base64Encode(List.filled(60, 0x42)),
  durationSeconds: 5,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<SecretKey> _fakeSecretKey() async =>
    AesGcm.with256bits().newSecretKeyFromBytes(List.filled(32, 0x01));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(PrestigeCategory.politics);
  });

  // =========================================================================
  // OnboardingStep enum
  // =========================================================================
  group('OnboardingStep', () {
    test('has 4 steps', () => expect(OnboardingStep.values.length, 4));

    test('label is non-empty for all steps', () {
      for (final s in OnboardingStep.values) {
        expect(s.label, isNotEmpty, reason: '${s.name} label is empty');
      }
    });

    test('stepIndex matches values.indexOf', () {
      for (final s in OnboardingStep.values) {
        expect(s.stepIndex, OnboardingStep.values.indexOf(s));
      }
    });

    test('completed has highest stepIndex', () {
      expect(
        OnboardingStep.completed.stepIndex,
        greaterThan(OnboardingStep.voicePrintCreated.stepIndex),
      );
    });
  });

  // =========================================================================
  // OnboardingStatus model
  // =========================================================================
  group('OnboardingStatus', () {
    test('fresh() returns all-false status', () {
      final s = OnboardingStatus.fresh();
      expect(s.welcomeSeen, isFalse);
      expect(s.interestsSelected, isFalse);
      expect(s.voicePrintCreated, isFalse);
      expect(s.completed, isFalse);
      expect(s.selectedCategories, isEmpty);
    });

    test('requiresOnboarding is true when not completed', () {
      expect(OnboardingStatus.fresh().requiresOnboarding, isTrue);
    });

    test('requiresOnboarding is false when completed', () {
      final s = OnboardingStatus.fresh().copyWith(completed: true);
      expect(s.requiresOnboarding, isFalse);
    });

    test('nextStep returns welcomeSeen first', () {
      expect(OnboardingStatus.fresh().nextStep, OnboardingStep.welcomeSeen);
    });

    test('nextStep advances correctly through steps', () {
      var s = OnboardingStatus.fresh();
      expect(s.nextStep, OnboardingStep.welcomeSeen);

      s = s.copyWith(welcomeSeen: true);
      expect(s.nextStep, OnboardingStep.interestsSelected);

      s = s.copyWith(interestsSelected: true);
      expect(s.nextStep, OnboardingStep.voicePrintCreated);

      s = s.copyWith(voicePrintCreated: true);
      expect(s.nextStep, OnboardingStep.completed);

      s = s.copyWith(completed: true);
      expect(s.nextStep, isNull);
    });

    test('progress increases with each step', () {
      var s = OnboardingStatus.fresh();
      expect(s.progress, 0.0);

      s = s.copyWith(welcomeSeen: true);
      expect(s.progress, closeTo(1 / 3, 0.001));

      s = s.copyWith(interestsSelected: true);
      expect(s.progress, closeTo(2 / 3, 0.001));

      s = s.copyWith(voicePrintCreated: true);
      expect(s.progress, 1.0);
    });

    test('fromMap round-trips via toMap', () {
      final original = OnboardingStatus(
        welcomeSeen: true,
        interestsSelected: true,
        voicePrintCreated: false,
        completed: false,
        selectedCategories: ['السياسة', 'الثقافة'],
      );
      final restored = OnboardingStatus.fromMap(original.toMap());
      expect(restored.welcomeSeen, isTrue);
      expect(restored.interestsSelected, isTrue);
      expect(restored.voicePrintCreated, isFalse);
      expect(restored.selectedCategories, ['السياسة', 'الثقافة']);
    });

    test('fromMap handles null/missing fields gracefully', () {
      final s = OnboardingStatus.fromMap({});
      expect(s.welcomeSeen, isFalse);
      expect(s.selectedCategories, isEmpty);
    });

    test('toMap includes completed_at when completedAt is set', () {
      final dt = DateTime(2026, 4, 10);
      final s = OnboardingStatus.fresh().copyWith(
        completed: true,
        completedAt: dt,
      );
      expect(s.toMap()['completed_at'], dt.toIso8601String());
    });

    test('equality based on four boolean flags', () {
      final a = OnboardingStatus.fresh().copyWith(welcomeSeen: true);
      final b = OnboardingStatus.fresh().copyWith(welcomeSeen: true);
      expect(a, equals(b));
    });

    test('hashCode consistent with equality', () {
      final a = OnboardingStatus.fresh().copyWith(welcomeSeen: true);
      final b = OnboardingStatus.fresh().copyWith(welcomeSeen: true);
      expect(a.hashCode, b.hashCode);
    });
  });

  // =========================================================================
  // PrestigeCategory
  // =========================================================================
  group('PrestigeCategory', () {
    test('has 12 categories', () {
      expect(PrestigeCategory.values.length, 12);
    });

    test('arabicLabel is non-empty for all', () {
      for (final c in PrestigeCategory.values) {
        expect(c.arabicLabel, isNotEmpty);
      }
    });

    test('key equals arabicLabel', () {
      for (final c in PrestigeCategory.values) {
        expect(c.key, c.arabicLabel);
      }
    });

    test('fromKey round-trips all values', () {
      for (final c in PrestigeCategory.values) {
        expect(PrestigeCategory.fromKey(c.key), c);
      }
    });

    test('fromKey returns null for unknown key', () {
      expect(PrestigeCategory.fromKey('unknown_xyz'), isNull);
    });

    test('fromKeys filters out unrecognised entries', () {
      final result = PrestigeCategory.fromKeys(['السياسة', 'xyz', 'الثقافة']);
      expect(result.length, 2);
      expect(
        result,
        containsAll([PrestigeCategory.politics, PrestigeCategory.culture]),
      );
    });

    test('minimumSelection is 3', () {
      expect(PrestigeCategory.minimumSelection, 3);
    });

    test('isValidSelection rejects fewer than 3', () {
      expect(
        PrestigeCategory.isValidSelection([PrestigeCategory.arts]),
        isFalse,
      );
    });

    test('isValidSelection accepts exactly 3', () {
      expect(
        PrestigeCategory.isValidSelection([
          PrestigeCategory.arts,
          PrestigeCategory.science,
          PrestigeCategory.history,
        ]),
        isTrue,
      );
    });

    test('isValidSelection accepts more than 3', () {
      expect(
        PrestigeCategory.isValidSelection(
          PrestigeCategory.values.take(5).toList(),
        ),
        isTrue,
      );
    });
  });

  // =========================================================================
  // VoicePrint model
  // =========================================================================
  group('VoicePrint model', () {
    test('fromMap round-trips via toMap', () {
      final vp = _voicePrint();
      final map = {
        ...vp.toMap(),
        'id': vp.id,
        'created_at': vp.createdAt.toIso8601String(),
        'updated_at': vp.updatedAt.toIso8601String(),
      };
      final restored = VoicePrint.fromMap(map);
      expect(restored.id, vp.id);
      expect(restored.encryptedAudio, vp.encryptedAudio);
      expect(restored.durationSeconds, vp.durationSeconds);
    });

    test('isValid passes for 5-second clip', () {
      expect(_voicePrint().isValid, isTrue);
    });

    test('isValid fails for 0-second duration', () {
      final vp = VoicePrint(
        id: 'vp-bad',
        userId: 'u',
        encryptedAudio: 'abc',
        durationSeconds: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(vp.isValid, isFalse);
    });

    test('isValid fails for empty encrypted audio', () {
      final vp = VoicePrint(
        id: 'vp-bad',
        userId: 'u',
        encryptedAudio: '',
        durationSeconds: 5,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(vp.isValid, isFalse);
    });

    test('equality by id', () {
      final a = _voicePrint(id: 'vp-001');
      final b = _voicePrint(id: 'vp-001');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('voicePrintHiveKey generates correct key', () {
      expect(voicePrintHiveKey('abc-123'), 'voice_print_key_abc-123');
    });
  });

  // =========================================================================
  // FeedWarmupService
  // =========================================================================
  group('FeedWarmupService', () {
    late _MockRecommendationRepository repo;
    late _MockPrefetchService prefetch;
    late FeedWarmupService service;

    setUp(() {
      repo = _MockRecommendationRepository();
      prefetch = _MockPrefetchService();
      service = FeedWarmupService(repo, prefetch);
    });

    test('warmWithCategories returns empty list for empty input', () async {
      final result = await service.warmWithCategories([]);
      expect(result, isEmpty);
      verifyNever(() => repo.setExplicitInterest(any()));
    });

    test(
      'warmWithCategories calls setExplicitInterest for each category',
      () async {
        final categories = [
          PrestigeCategory.politics,
          PrestigeCategory.economy,
          PrestigeCategory.culture,
        ];
        when(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).thenAnswer((_) async {});
        when(() => prefetch.warmCache()).thenAnswer((_) async {});
        when(
          () => repo.getPersonalisedFeed(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => [_feedItem('d1')]);

        await service.warmWithCategories(categories);

        verify(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).called(3);
      },
    );

    test(
      'warmWithCategories calls warmCache after setting interests',
      () async {
        when(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).thenAnswer((_) async {});
        when(() => prefetch.warmCache()).thenAnswer((_) async {});
        when(
          () => repo.getPersonalisedFeed(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        await service.warmWithCategories([PrestigeCategory.arts]);

        verify(() => prefetch.warmCache()).called(1);
      },
    );

    test('warmWithCategories returns first-page feed items', () async {
      when(
        () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
      ).thenAnswer((_) async {});
      when(() => prefetch.warmCache()).thenAnswer((_) async {});
      when(
        () => repo.getPersonalisedFeed(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [_feedItem('d1'), _feedItem('d2')]);

      final result = await service.warmWithCategories([PrestigeCategory.arts]);

      expect(result.length, 2);
      expect(result.first.diwanId, 'd1');
    });

    test(
      'warmWithCategories continues if one category setExplicitInterest fails',
      () async {
        var callCount = 0;
        when(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) throw Exception('network error');
        });
        when(() => prefetch.warmCache()).thenAnswer((_) async {});
        when(
          () => repo.getPersonalisedFeed(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        final result = await service.warmWithCategories([
          PrestigeCategory.politics,
          PrestigeCategory.economy,
        ]);

        expect(result, isEmpty);
        verify(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).called(2);
      },
    );

    test(
      'warmWithCategories returns empty list if getPersonalisedFeed throws',
      () async {
        when(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).thenAnswer((_) async {});
        when(() => prefetch.warmCache()).thenAnswer((_) async {});
        when(
          () => repo.getPersonalisedFeed(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenThrow(Exception('no network'));

        final result = await service.warmWithCategories([
          PrestigeCategory.history,
        ]);

        expect(result, isEmpty);
      },
    );

    test(
      'warmWithKeys parses keys and delegates to warmWithCategories',
      () async {
        when(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).thenAnswer((_) async {});
        when(() => prefetch.warmCache()).thenAnswer((_) async {});
        when(
          () => repo.getPersonalisedFeed(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        await service.warmWithKeys(['السياسة', 'الأدب']);

        verify(
          () => repo.setExplicitInterest(any(), weight: any(named: 'weight')),
        ).called(2);
      },
    );

    test('onboardingWeight is 5.0', () {
      expect(FeedWarmupService.onboardingWeight, 5.0);
    });
  });

  // =========================================================================
  // VoicePrintService
  // =========================================================================
  group('VoicePrintService', () {
    late _MockE2EService e2e;
    late _MockVoicePrintRepository repo;
    late VoicePrintService service;

    setUp(() {
      e2e = _MockE2EService();
      repo = _MockVoicePrintRepository();
      service = VoicePrintService(e2e, repo);
    });

    test('createVoicePrint throws for empty audio', () async {
      expect(
        () => service.createVoicePrint(userId: 'u1', audioBytes: Uint8List(0)),
        throwsA(isA<VoicePrintException>()),
      );
    });

    test('createVoicePrint throws for 0-second duration', () async {
      expect(
        () => service.createVoicePrint(
          userId: 'u1',
          audioBytes: Uint8List.fromList([1, 2, 3]),
          durationSeconds: 0,
        ),
        throwsA(isA<VoicePrintException>()),
      );
    });

    test('createVoicePrint throws for duration > 30', () async {
      expect(
        () => service.createVoicePrint(
          userId: 'u1',
          audioBytes: Uint8List.fromList([1, 2, 3]),
          durationSeconds: 31,
        ),
        throwsA(isA<VoicePrintException>()),
      );
    });

    test('createVoicePrint succeeds with valid input', () async {
      final audio = Uint8List.fromList(List.filled(100, 0xAA));
      final keyBytes = List.filled(32, 0x01);
      final secretKey = await _fakeSecretKey();

      when(
        () => e2e.generateRandomKeyBytes(),
      ).thenAnswer((_) async => keyBytes);
      when(
        () => e2e.secretKeyFromBytes(keyBytes),
      ).thenAnswer((_) async => secretKey);
      when(
        () => e2e.encryptBytes(any(), secretKey),
      ).thenAnswer((_) async => 'encrypted-audio-base64');
      when(
        () => repo.store(
          userId: 'u1',
          encryptedAudio: 'encrypted-audio-base64',
          durationSeconds: 5,
          encryptionKeyBytes: keyBytes,
        ),
      ).thenAnswer((_) async => _voicePrint());

      final result = await service.createVoicePrint(
        userId: 'u1',
        audioBytes: audio,
      );

      expect(result.id, 'vp-001');
      verify(() => e2e.generateRandomKeyBytes()).called(1);
      verify(() => e2e.encryptBytes(any(), secretKey)).called(1);
    });

    test('hasVoicePrint returns true when repo returns a print', () async {
      when(() => repo.getMyVoicePrint()).thenAnswer((_) async => _voicePrint());
      expect(await service.hasVoicePrint(), isTrue);
    });

    test('hasVoicePrint returns false when repo returns null', () async {
      when(() => repo.getMyVoicePrint()).thenAnswer((_) async => null);
      expect(await service.hasVoicePrint(), isFalse);
    });

    test('deleteVoicePrint delegates to repository', () async {
      when(() => repo.deleteMyVoicePrint()).thenAnswer((_) async {});
      await service.deleteVoicePrint();
      verify(() => repo.deleteMyVoicePrint()).called(1);
    });

    test(
      'decryptMyVoicePrint returns null when no voice print exists',
      () async {
        when(() => repo.getMyVoicePrint()).thenAnswer((_) async => null);
        expect(await service.decryptMyVoicePrint(), isNull);
      },
    );

    test('decryptMyVoicePrint returns null when key is absent', () async {
      when(() => repo.getMyVoicePrint()).thenAnswer((_) async => _voicePrint());
      when(() => repo.getLocalKey('vp-001')).thenAnswer((_) async => null);
      expect(await service.decryptMyVoicePrint(), isNull);
    });

    test('targetDurationSeconds is 5', () {
      expect(VoicePrintService.targetDurationSeconds, 5);
    });

    test('maxDurationSeconds is 30', () {
      expect(VoicePrintService.maxDurationSeconds, 30);
    });
  });

  // =========================================================================
  // VoicePrintException
  // =========================================================================
  group('VoicePrintException', () {
    test('toString includes message', () {
      const ex = VoicePrintException('test error');
      expect(ex.toString(), contains('test error'));
    });
  });
}
