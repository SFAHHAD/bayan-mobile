import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/production_health.dart';
import 'package:bayan/core/services/production_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SecretStatus model
  // ---------------------------------------------------------------------------
  group('SecretStatus', () {
    test('fromMap parses is_set=true with masked_hint', () {
      final s = SecretStatus.fromMap({
        'key': 'OPENAI_API_KEY',
        'is_set': true,
        'masked_hint': 'sk-p****',
      });
      expect(s.key, 'OPENAI_API_KEY');
      expect(s.isSet, isTrue);
      expect(s.maskedHint, 'sk-p****');
    });

    test('fromMap parses is_set=false', () {
      final s = SecretStatus.fromMap({
        'key': 'FCM_SERVER_KEY',
        'is_set': false,
        'masked_hint': null,
      });
      expect(s.isSet, isFalse);
      expect(s.maskedHint, isNull);
    });

    test('fromMap supports camelCase key fallback (Edge Fn response)', () {
      final s = SecretStatus.fromMap({
        'key': 'LIVEKIT_API_KEY',
        'isSet': true,
        'maskedHint': 'APId****',
      });
      expect(s.isSet, isTrue);
      expect(s.maskedHint, 'APId****');
    });

    test('equality by key + isSet', () {
      final a = SecretStatus.fromMap({
        'key': 'X',
        'is_set': true,
        'masked_hint': 'abcd****',
      });
      final b = SecretStatus.fromMap({
        'key': 'X',
        'is_set': true,
        'masked_hint': 'zzzz****',
      });
      expect(a, equals(b));
    });

    test('different keys are not equal', () {
      final a = SecretStatus.fromMap({'key': 'A', 'is_set': true});
      final b = SecretStatus.fromMap({'key': 'B', 'is_set': true});
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // ProductionHealth model
  // ---------------------------------------------------------------------------
  group('ProductionHealth', () {
    List<Map<String, dynamic>> allSetSecrets() => [
      {'key': 'OPENAI_API_KEY', 'is_set': true, 'masked_hint': 'sk-p****'},
      {'key': 'LIVEKIT_API_KEY', 'is_set': true, 'masked_hint': 'LK00****'},
      {'key': 'LIVEKIT_API_SECRET', 'is_set': true, 'masked_hint': 'LKse****'},
      {'key': 'FCM_SERVER_KEY', 'is_set': true, 'masked_hint': 'AAAA****'},
      {
        'key': 'SUPABASE_SERVICE_ROLE_KEY',
        'is_set': true,
        'masked_hint': 'eyJh****',
      },
    ];

    test('fromMap parses allSecretsConfigured=true', () {
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': true,
        'secrets': allSetSecrets(),
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'production',
      });
      expect(h.allSecretsConfigured, isTrue);
      expect(h.secrets.length, 5);
      expect(h.environment, 'production');
    });

    test('isProductionReady true when all set and not test env', () {
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': true,
        'secrets': allSetSecrets(),
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'production',
      });
      expect(h.isProductionReady, isTrue);
    });

    test('isProductionReady false when environment=test', () {
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': true,
        'secrets': allSetSecrets(),
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'test',
      });
      expect(h.isProductionReady, isFalse);
    });

    test('isProductionReady false when not all secrets set', () {
      final secrets = allSetSecrets();
      secrets[0]['is_set'] = false;
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': false,
        'secrets': secrets,
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'production',
      });
      expect(h.isProductionReady, isFalse);
    });

    test('missingSecrets returns only unset keys', () {
      final secrets = allSetSecrets();
      secrets[2]['is_set'] = false;
      secrets[4]['is_set'] = false;
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': false,
        'secrets': secrets,
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'production',
      });
      expect(h.missingSecrets.length, 2);
      expect(
        h.missingSecrets.map((s) => s.key),
        containsAll(['LIVEKIT_API_SECRET', 'SUPABASE_SERVICE_ROLE_KEY']),
      );
    });

    test('notReady factory marks all provided keys as unset', () {
      final keys = ['OPENAI_API_KEY', 'FCM_SERVER_KEY'];
      final h = ProductionHealth.notReady(keys);
      expect(h.allSecretsConfigured, isFalse);
      expect(h.missingSecrets.length, 2);
      expect(h.isProductionReady, isFalse);
    });

    test('fromMap handles empty secrets list', () {
      final h = ProductionHealth.fromMap({
        'allSecretsConfigured': false,
        'secrets': <dynamic>[],
        'checkedAt': '2026-04-10T14:00:00.000Z',
        'environment': 'production',
      });
      expect(h.secrets, isEmpty);
      expect(h.missingSecrets, isEmpty);
    });

    test('equality by allSecretsConfigured', () {
      final a = ProductionHealth.fromMap({
        'allSecretsConfigured': true,
        'secrets': allSetSecrets(),
        'checkedAt': '2026-04-10T14:00:00Z',
        'environment': 'production',
      });
      final b = ProductionHealth.fromMap({
        'allSecretsConfigured': true,
        'secrets': <dynamic>[],
        'checkedAt': '2026-04-10T15:00:00Z',
        'environment': 'staging',
      });
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // ProductionService — pure static methods
  // ---------------------------------------------------------------------------
  group('ProductionService static helpers', () {
    test('looksLikeTestKey: "test_key_123" is flagged', () {
      expect(ProductionService.looksLikeTestKey('test_key_123'), isTrue);
    });

    test('looksLikeTestKey: "placeholder_openai" is flagged', () {
      expect(ProductionService.looksLikeTestKey('placeholder_openai'), isTrue);
    });

    test('looksLikeTestKey: "your_api_key_here" is flagged', () {
      expect(ProductionService.looksLikeTestKey('your_api_key_here'), isTrue);
    });

    test('looksLikeTestKey: short value (<10 chars) is flagged', () {
      expect(ProductionService.looksLikeTestKey('abc123'), isTrue);
    });

    test('looksLikeTestKey: real-looking key is not flagged', () {
      expect(
        ProductionService.looksLikeTestKey('sk-projABCDE1234567890XYZ'),
        isFalse,
      );
    });

    test('looksLikeTestKey: FCM key-like string passes', () {
      expect(
        ProductionService.looksLikeTestKey('AAAAabcde:APA91bXYZ123456789'),
        isFalse,
      );
    });

    test('maskKey: short key returns ****', () {
      expect(ProductionService.maskKey('abc'), '****');
    });

    test('maskKey: longer key shows first 4 chars + stars', () {
      final masked = ProductionService.maskKey('sk-projABCDE1234567890');
      expect(masked, startsWith('sk-p'));
      expect(masked, contains('*'));
    });

    test('maskKey: exactly 4 chars shows them all + no stars', () {
      expect(ProductionService.maskKey('abcd'), 'abcd');
    });

    test('requiredSecrets contains all 5 expected keys', () {
      expect(
        ProductionService.requiredSecrets,
        containsAll([
          'OPENAI_API_KEY',
          'LIVEKIT_API_KEY',
          'LIVEKIT_API_SECRET',
          'FCM_SERVER_KEY',
          'SUPABASE_SERVICE_ROLE_KEY',
        ]),
      );
      expect(ProductionService.requiredSecrets.length, 5);
    });
  });
}
