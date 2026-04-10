import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/system_log.dart';
import 'package:bayan/core/models/remote_config.dart';
import 'package:bayan/core/services/crash_recovery_service.dart';
import 'package:bayan/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

void main() {
  final now = DateTime(2026, 4, 10, 14, 0);

  // -------------------------------------------------------------------------
  // SystemLog model
  // -------------------------------------------------------------------------
  group('SystemLog model', () {
    Map<String, dynamic> logMap({
      String severity = 'error',
      String? stackTrace,
      String? userId,
      String? appVersion,
      String? platform,
      String? sessionId,
    }) => {
      'id': 'log-001',
      'severity': severity,
      'source': 'test_source',
      'message': 'test error occurred',
      'stack_trace': stackTrace,
      'user_id': userId,
      'metadata': {'key': 'value'},
      'app_version': appVersion,
      'platform': platform,
      'session_id': sessionId,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final log = SystemLog.fromMap(
        logMap(
          stackTrace: '#0 main()',
          userId: 'user-001',
          appVersion: '1.5.0',
          platform: 'android',
          sessionId: 'abc123',
        ),
      );
      expect(log.id, 'log-001');
      expect(log.severity, LogSeverity.error);
      expect(log.source, 'test_source');
      expect(log.message, 'test error occurred');
      expect(log.stackTrace, '#0 main()');
      expect(log.userId, 'user-001');
      expect(log.metadata['key'], 'value');
      expect(log.appVersion, '1.5.0');
      expect(log.platform, 'android');
      expect(log.sessionId, 'abc123');
      expect(log.createdAt, now);
    });

    test('nullable fields default to null', () {
      final log = SystemLog.fromMap(logMap());
      expect(log.stackTrace, isNull);
      expect(log.userId, isNull);
      expect(log.appVersion, isNull);
      expect(log.platform, isNull);
      expect(log.sessionId, isNull);
    });

    test('parses all severity levels', () {
      final severities = {
        'debug': LogSeverity.debug,
        'info': LogSeverity.info,
        'warning': LogSeverity.warning,
        'error': LogSeverity.error,
        'fatal': LogSeverity.fatal,
        null: LogSeverity.info,
      };
      for (final entry in severities.entries) {
        final map = Map<String, dynamic>.from(logMap())
          ..['severity'] = entry.key;
        expect(
          SystemLog.fromMap(map).severity,
          entry.value,
          reason: 'Failed for: ${entry.key}',
        );
      }
    });

    test('severityToString round-trips', () {
      for (final entry in {
        LogSeverity.debug: 'debug',
        LogSeverity.info: 'info',
        LogSeverity.warning: 'warning',
        LogSeverity.error: 'error',
        LogSeverity.fatal: 'fatal',
      }.entries) {
        expect(SystemLog.severityToString(entry.key), entry.value);
        final map = Map<String, dynamic>.from(logMap())
          ..['severity'] = entry.value;
        expect(SystemLog.fromMap(map).severityString, entry.value);
      }
    });

    test('isError is true for error and fatal only', () {
      expect(SystemLog.fromMap(logMap(severity: 'error')).isError, isTrue);
      expect(SystemLog.fromMap(logMap(severity: 'fatal')).isError, isTrue);
      expect(SystemLog.fromMap(logMap(severity: 'warning')).isError, isFalse);
      expect(SystemLog.fromMap(logMap(severity: 'info')).isError, isFalse);
      expect(SystemLog.fromMap(logMap(severity: 'debug')).isError, isFalse);
    });

    test('isFatal is true only for fatal', () {
      expect(SystemLog.fromMap(logMap(severity: 'fatal')).isFatal, isTrue);
      expect(SystemLog.fromMap(logMap(severity: 'error')).isFatal, isFalse);
    });

    test('isWarning is true only for warning', () {
      expect(SystemLog.fromMap(logMap(severity: 'warning')).isWarning, isTrue);
      expect(SystemLog.fromMap(logMap(severity: 'info')).isWarning, isFalse);
    });

    test('metadata defaults to empty map when missing', () {
      final map = Map<String, dynamic>.from(logMap())..['metadata'] = null;
      expect(SystemLog.fromMap(map).metadata, isEmpty);
    });

    test('equality by id', () {
      final a = SystemLog.fromMap(logMap(severity: 'error'));
      final b = SystemLog.fromMap(logMap(severity: 'fatal'));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids not equal', () {
      final a = SystemLog.fromMap(logMap());
      final b = SystemLog.fromMap({...logMap(), 'id': 'log-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // RemoteConfig model
  // -------------------------------------------------------------------------
  group('RemoteConfig model', () {
    Map<String, dynamic> configMap({
      String key = 'enable_gifting',
      String value = 'true',
      String type = 'bool',
      bool isActive = true,
      String? description,
    }) => {
      'id': 'cfg-001',
      'key': key,
      'value': value,
      'type': type,
      'description': description,
      'is_active': isActive,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final c = RemoteConfig.fromMap(
        configMap(key: 'enable_gifting', description: 'Toggle gifting'),
      );
      expect(c.id, 'cfg-001');
      expect(c.key, 'enable_gifting');
      expect(c.value, 'true');
      expect(c.type, ConfigType.bool);
      expect(c.description, 'Toggle gifting');
      expect(c.isActive, isTrue);
    });

    test('isActive defaults to true when null', () {
      final map = Map<String, dynamic>.from(configMap())..['is_active'] = null;
      expect(RemoteConfig.fromMap(map).isActive, isTrue);
    });

    test('parses all ConfigType values', () {
      final typeMap = {
        'bool': ConfigType.bool,
        'int': ConfigType.int,
        'double': ConfigType.double,
        'string': ConfigType.string,
        'json': ConfigType.json,
        null: ConfigType.string,
      };
      for (final entry in typeMap.entries) {
        final map = Map<String, dynamic>.from(configMap())
          ..['type'] = entry.key;
        expect(
          RemoteConfig.fromMap(map).type,
          entry.value,
          reason: 'Failed for type: ${entry.key}',
        );
      }
    });

    test('typeToString round-trips', () {
      for (final entry in {
        ConfigType.bool: 'bool',
        ConfigType.int: 'int',
        ConfigType.double: 'double',
        ConfigType.string: 'string',
        ConfigType.json: 'json',
      }.entries) {
        expect(RemoteConfig.typeToString(entry.key), entry.value);
        final c = RemoteConfig.fromMap(configMap(type: entry.value));
        expect(c.typeString, entry.value);
      }
    });

    // asBool
    test('asBool: true string values', () {
      for (final v in ['true', 'True', 'TRUE', '1', 'yes', 'YES']) {
        expect(
          RemoteConfig.fromMap(configMap(value: v, type: 'bool')).asBool,
          isTrue,
          reason: 'Expected true for value: $v',
        );
      }
    });

    test('asBool: false string values', () {
      for (final v in ['false', 'False', '0', 'no', 'nope', '']) {
        expect(
          RemoteConfig.fromMap(configMap(value: v, type: 'bool')).asBool,
          isFalse,
          reason: 'Expected false for value: $v',
        );
      }
    });

    // asInt
    test('asInt parses integers', () {
      expect(
        RemoteConfig.fromMap(configMap(value: '42', type: 'int')).asInt,
        42,
      );
      expect(RemoteConfig.fromMap(configMap(value: '0', type: 'int')).asInt, 0);
      expect(
        RemoteConfig.fromMap(configMap(value: '-5', type: 'int')).asInt,
        -5,
      );
    });

    test('asInt defaults to 0 on invalid', () {
      expect(
        RemoteConfig.fromMap(configMap(value: 'abc', type: 'int')).asInt,
        0,
      );
    });

    // asDouble
    test('asDouble parses doubles', () {
      expect(
        RemoteConfig.fromMap(configMap(value: '0.75', type: 'double')).asDouble,
        0.75,
      );
      expect(
        RemoteConfig.fromMap(configMap(value: '10', type: 'double')).asDouble,
        10.0,
      );
    });

    test('asDouble defaults to 0.0 on invalid', () {
      expect(
        RemoteConfig.fromMap(configMap(value: 'nan', type: 'double')).asDouble,
        0.0,
      );
    });

    // asString
    test('asString returns value as-is', () {
      expect(
        RemoteConfig.fromMap(
          configMap(value: 'hello', type: 'string'),
        ).asString,
        'hello',
      );
    });

    // asJson
    test('asJson parses valid JSON object', () {
      final c = RemoteConfig.fromMap(
        configMap(value: '{"k":"v","n":1}', type: 'json'),
      );
      expect(c.asJson['k'], 'v');
      expect(c.asJson['n'], 1);
    });

    test('asJson returns empty map on invalid JSON', () {
      expect(
        RemoteConfig.fromMap(configMap(value: 'not-json', type: 'json')).asJson,
        isEmpty,
      );
    });

    test('asJson returns empty map on non-object JSON (array)', () {
      expect(
        RemoteConfig.fromMap(configMap(value: '[1,2,3]', type: 'json')).asJson,
        isEmpty,
      );
    });

    // copyWith
    test('copyWith updates value and isActive', () {
      final c = RemoteConfig.fromMap(configMap());
      final updated = c.copyWith(value: 'false', isActive: false);
      expect(updated.value, 'false');
      expect(updated.isActive, isFalse);
      expect(updated.key, c.key);
      expect(updated.type, c.type);
    });

    test('copyWith preserves unchanged fields', () {
      final c = RemoteConfig.fromMap(configMap());
      final same = c.copyWith();
      expect(same.value, c.value);
      expect(same.isActive, c.isActive);
    });

    // equality
    test('equality by key', () {
      final a = RemoteConfig.fromMap(configMap(value: 'true'));
      final b = RemoteConfig.fromMap(configMap(value: 'false'));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different keys not equal', () {
      final a = RemoteConfig.fromMap(configMap(key: 'enable_gifting'));
      final b = RemoteConfig.fromMap(configMap(key: 'enable_search'));
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // RecoveryResult model
  // -------------------------------------------------------------------------
  group('RecoveryResult', () {
    test('fullyRecovered is true only when both cleared and restored', () {
      expect(
        const RecoveryResult(
          cacheCleared: true,
          sessionRestored: true,
        ).fullyRecovered,
        isTrue,
      );
      expect(
        const RecoveryResult(
          cacheCleared: true,
          sessionRestored: false,
        ).fullyRecovered,
        isFalse,
      );
      expect(
        const RecoveryResult(
          cacheCleared: false,
          sessionRestored: true,
        ).fullyRecovered,
        isFalse,
      );
      expect(
        const RecoveryResult(
          cacheCleared: false,
          sessionRestored: false,
        ).fullyRecovered,
        isFalse,
      );
    });

    test('toString includes both fields', () {
      final r = const RecoveryResult(
        cacheCleared: true,
        sessionRestored: false,
      );
      expect(r.toString(), contains('cacheCleared: true'));
      expect(r.toString(), contains('sessionRestored: false'));
    });
  });

  // -------------------------------------------------------------------------
  // AppLocalizations — dialect switching
  // -------------------------------------------------------------------------
  group('AppLocalizations — dialect switching', () {
    const classical = AppLocalizations(Locale('ar'));
    const kuwaiti = AppLocalizations(Locale('ar', 'KW'));

    test('Classical Arabic strings match expected values', () {
      expect(classical.loading, 'جارٍ التحميل...');
      expect(classical.errorGeneric, 'حدث خطأ غير متوقع');
      expect(classical.errorNetwork, 'تعذّر الاتصال بالشبكة');
      expect(classical.joinDiwan, 'انضمّ للديوان');
      expect(classical.leaveDiwan, 'مغادرة الديوان');
      expect(classical.insufficientBalance, 'رصيدك غير كافٍ لإتمام العملية');
      expect(classical.purchaseSuccess, 'تمّت عملية الشراء بنجاح');
      expect(classical.clearHistory, 'حذف السجل');
      expect(classical.pauseLogging, 'إيقاف تتبع النشاط');
      expect(classical.languageClassical, 'العربية الفصحى');
      expect(classical.languageKuwaiti, 'اللهجة الكويتية');
    });

    test('Kuwaiti dialect strings differ from Classical where specified', () {
      expect(kuwaiti.loading, 'يحمّل...');
      expect(kuwaiti.errorGeneric, 'صار خطأ مو متوقع');
      expect(kuwaiti.errorNetwork, 'ما قدرنا نتصل بالشبكة');
      expect(kuwaiti.joinDiwan, 'ادخل الديوان');
      expect(kuwaiti.leaveDiwan, 'اطلع من الديوان');
      expect(kuwaiti.insufficientBalance, 'ما عندك رصيد يكفي');
      expect(kuwaiti.purchaseSuccess, 'تمّ الشراء');
      expect(kuwaiti.clearHistory, 'احذف السجل');
      expect(kuwaiti.pauseLogging, 'وقّف التتبع');
      expect(kuwaiti.languageClassical, 'الفصحى');
      expect(kuwaiti.languageKuwaiti, 'الكويتي');
    });

    test('Shared strings are identical in both dialects', () {
      expect(classical.appName, equals(kuwaiti.appName));
      expect(classical.cancel, equals(kuwaiti.cancel));
      expect(classical.confirm, equals(kuwaiti.confirm));
      expect(classical.home, equals(kuwaiti.home));
      expect(classical.series, equals(kuwaiti.series));
      expect(classical.wallet, equals(kuwaiti.wallet));
      expect(classical.verificationTitle, equals(kuwaiti.verificationTitle));
      expect(classical.crashRecoveryTitle, equals(kuwaiti.crashRecoveryTitle));
    });

    test('Crash recovery messages differ', () {
      expect(
        classical.crashRecoveryMessage,
        isNot(kuwaiti.crashRecoveryMessage),
      );
      expect(classical.clearCacheRestore, isNot(kuwaiti.clearCacheRestore));
    });

    test('Verification status strings differ', () {
      expect(classical.verificationPending, isNot(kuwaiti.verificationPending));
      expect(
        classical.verificationApproved,
        isNot(kuwaiti.verificationApproved),
      );
      expect(
        classical.verificationRejected,
        isNot(kuwaiti.verificationRejected),
      );
    });

    test('Maintenance/update strings differ', () {
      expect(classical.maintenanceMode, isNot(kuwaiti.maintenanceMode));
      expect(classical.updateRequired, isNot(kuwaiti.updateRequired));
    });

    test('episodeNumber formats correctly', () {
      expect(classical.episodeNumber(5), contains('5'));
      expect(kuwaiti.episodeNumber(5), contains('5'));
    });

    test('newEpisodeNotification includes series title', () {
      expect(classical.newEpisodeNotification('بيان'), contains('بيان'));
      expect(kuwaiti.newEpisodeNotification('بيان'), contains('بيان'));
    });

    test('ticketPrice includes the price', () {
      expect(classical.ticketPrice(100), contains('100'));
      expect(kuwaiti.ticketPrice(100), contains('100'));
    });

    test('listenersCount includes the count', () {
      expect(classical.listenersCount(42), contains('42'));
      expect(kuwaiti.listenersCount(42), contains('42'));
    });

    test('AppLocalizations.delegate is supported for ar', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('ar')), isTrue);
      expect(
        AppLocalizations.delegate.isSupported(const Locale('ar', 'KW')),
        isTrue,
      );
      expect(
        AppLocalizations.delegate.isSupported(const Locale('en')),
        isFalse,
      );
    });

    test('supportedLocales contains ar and ar_KW', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
      expect(
        AppLocalizations.supportedLocales,
        contains(const Locale('ar', 'KW')),
      );
    });
  });
}
