import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bayan/core/models/app_icon_variant.dart';
import 'package:bayan/core/models/profile.dart';
import 'package:bayan/core/repositories/dynamic_icon_repository.dart';
import 'package:bayan/core/services/dynamic_icon_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockDynamicIconRepository extends Mock
    implements DynamicIconRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Profile _profile({bool sovereign = false, int level = 0}) => Profile(
  id: 'user-001',
  createdAt: DateTime(2026),
  isSovereign: sovereign,
  level: level,
);

void main() {
  setUpAll(() {
    registerFallbackValue(AppIconVariant.defaultIcon);
  });

  // =========================================================================
  // AppIconVariant model
  // =========================================================================
  group('AppIconVariant', () {
    test('defaultIcon.iosIconName is null (resets to primary icon)', () {
      expect(AppIconVariant.defaultIcon.iosIconName, isNull);
    });

    test('gold.iosIconName is "BayanGold"', () {
      expect(AppIconVariant.gold.iosIconName, 'BayanGold');
    });

    test('defaultIcon.androidActivityAlias', () {
      expect(
        AppIconVariant.defaultIcon.androidActivityAlias,
        'MainActivityDefaultIcon',
      );
    });

    test('gold.androidActivityAlias', () {
      expect(AppIconVariant.gold.androidActivityAlias, 'MainActivityGoldIcon');
    });

    test('only gold requiresElite', () {
      expect(AppIconVariant.defaultIcon.requiresElite, isFalse);
      expect(AppIconVariant.gold.requiresElite, isTrue);
    });

    test('displayLabel is non-empty for all variants', () {
      for (final v in AppIconVariant.values) {
        expect(v.displayLabel, isNotEmpty);
      }
    });

    test('values contains exactly 2 variants', () {
      expect(AppIconVariant.values.length, 2);
    });
  });

  // =========================================================================
  // IconSwitchResult
  // =========================================================================
  group('IconSwitchResult', () {
    test('has 4 values', () => expect(IconSwitchResult.values.length, 4));

    test('contains expected members', () {
      expect(
        IconSwitchResult.values,
        containsAll([
          IconSwitchResult.success,
          IconSwitchResult.notEligible,
          IconSwitchResult.notSupported,
          IconSwitchResult.error,
        ]),
      );
    });
  });

  // =========================================================================
  // DynamicIconService — pure static eligibility
  // =========================================================================
  group('DynamicIconService.isProfileEligible (pure, no network)', () {
    test('sovereign user with level 0 is eligible', () {
      expect(
        DynamicIconService.isProfileEligible(_profile(sovereign: true)),
        isTrue,
      );
    });

    test('level 50 user is eligible (boundary)', () {
      expect(DynamicIconService.isProfileEligible(_profile(level: 50)), isTrue);
    });

    test('level 51 user is eligible', () {
      expect(DynamicIconService.isProfileEligible(_profile(level: 51)), isTrue);
    });

    test('level 100 user is eligible', () {
      expect(
        DynamicIconService.isProfileEligible(_profile(level: 100)),
        isTrue,
      );
    });

    test('level 49 non-sovereign is NOT eligible (boundary)', () {
      expect(
        DynamicIconService.isProfileEligible(_profile(level: 49)),
        isFalse,
      );
    });

    test('level 0 non-sovereign is NOT eligible', () {
      expect(DynamicIconService.isProfileEligible(_profile()), isFalse);
    });

    test('sovereign + high level is eligible', () {
      expect(
        DynamicIconService.isProfileEligible(
          _profile(sovereign: true, level: 99),
        ),
        isTrue,
      );
    });
  });

  // =========================================================================
  // DynamicIconService — switchToGold
  // =========================================================================
  group('DynamicIconService.switchToGold', () {
    late _MockDynamicIconRepository repo;
    late DynamicIconService service;

    setUp(() {
      repo = _MockDynamicIconRepository();
      service = DynamicIconService(repo);
    });

    test('returns notSupported when platform does not support icons', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => false);

      final result = await service.switchToGold('user-001');

      expect(result, IconSwitchResult.notSupported);
      verifyNever(() => repo.setVariant(any()));
    });

    test('returns notEligible when checkEligibility returns false', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => true);
      when(
        () => repo.checkEligibility('user-001'),
      ).thenAnswer((_) async => false);

      final result = await service.switchToGold('user-001');

      expect(result, IconSwitchResult.notEligible);
      verifyNever(() => repo.setVariant(any()));
    });

    test('returns success when eligible and switch succeeds', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => true);
      when(
        () => repo.checkEligibility('user-sovereign'),
      ).thenAnswer((_) async => true);
      when(() => repo.setVariant(AppIconVariant.gold)).thenAnswer((_) async {});

      final result = await service.switchToGold('user-sovereign');

      expect(result, IconSwitchResult.success);
      verify(() => repo.setVariant(AppIconVariant.gold)).called(1);
    });

    test('returns error when platform setVariant throws', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => true);
      when(
        () => repo.checkEligibility('user-sovereign'),
      ).thenAnswer((_) async => true);
      when(
        () => repo.setVariant(AppIconVariant.gold),
      ).thenThrow(Exception('platform error'));

      final result = await service.switchToGold('user-sovereign');

      expect(result, IconSwitchResult.error);
    });

    test(
      'returns notEligible when checkEligibility returns false (fail-closed)',
      () async {
        when(() => repo.isSupported()).thenAnswer((_) async => true);
        when(() => repo.checkEligibility('any')).thenAnswer((_) async => false);

        final result = await service.switchToGold('any');

        expect(result, IconSwitchResult.notEligible);
      },
    );
  });

  // =========================================================================
  // DynamicIconService — switchToDefault
  // =========================================================================
  group('DynamicIconService.switchToDefault', () {
    late _MockDynamicIconRepository repo;
    late DynamicIconService service;

    setUp(() {
      repo = _MockDynamicIconRepository();
      service = DynamicIconService(repo);
    });

    test('returns notSupported when platform unsupported', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => false);

      final result = await service.switchToDefault();

      expect(result, IconSwitchResult.notSupported);
    });

    test('succeeds without any eligibility check', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => true);
      when(
        () => repo.setVariant(AppIconVariant.defaultIcon),
      ).thenAnswer((_) async {});

      final result = await service.switchToDefault();

      expect(result, IconSwitchResult.success);
      verify(() => repo.setVariant(AppIconVariant.defaultIcon)).called(1);
    });

    test('returns error when platform throws', () async {
      when(() => repo.isSupported()).thenAnswer((_) async => true);
      when(
        () => repo.setVariant(AppIconVariant.defaultIcon),
      ).thenThrow(Exception('platform error'));

      final result = await service.switchToDefault();

      expect(result, IconSwitchResult.error);
    });
  });

  // =========================================================================
  // DynamicIconService — restoreCorrectIcon
  // =========================================================================
  group('DynamicIconService.restoreCorrectIcon', () {
    late _MockDynamicIconRepository repo;
    late DynamicIconService service;

    setUp(() {
      repo = _MockDynamicIconRepository();
      service = DynamicIconService(repo);
    });

    test('does nothing if active icon is default', () async {
      when(
        () => repo.getActiveVariant(),
      ).thenAnswer((_) async => AppIconVariant.defaultIcon);

      await service.restoreCorrectIcon('user-001');

      verifyNever(() => repo.checkEligibility(any()));
      verifyNever(() => repo.setVariant(any()));
    });

    test('does nothing if active is gold and user is still eligible', () async {
      when(
        () => repo.getActiveVariant(),
      ).thenAnswer((_) async => AppIconVariant.gold);
      when(
        () => repo.checkEligibility('sovereign-user'),
      ).thenAnswer((_) async => true);

      await service.restoreCorrectIcon('sovereign-user');

      verifyNever(() => repo.setVariant(any()));
    });

    test(
      'resets to default if gold is active but user lost eligibility',
      () async {
        when(
          () => repo.getActiveVariant(),
        ).thenAnswer((_) async => AppIconVariant.gold);
        when(
          () => repo.checkEligibility('lapsed-user'),
        ).thenAnswer((_) async => false);
        when(
          () => repo.setVariant(AppIconVariant.defaultIcon),
        ).thenAnswer((_) async {});

        await service.restoreCorrectIcon('lapsed-user');

        verify(() => repo.setVariant(AppIconVariant.defaultIcon)).called(1);
      },
    );

    test('swallows exceptions silently (never crashes app start)', () async {
      when(() => repo.getActiveVariant()).thenThrow(Exception('crash'));

      expect(() => service.restoreCorrectIcon('user-001'), returnsNormally);
    });
  });
}
