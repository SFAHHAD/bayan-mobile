import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/seo_metadata.dart';
import 'package:bayan/core/models/notification_prediction.dart';
import 'package:bayan/core/models/bug_report.dart';
import 'package:bayan/core/models/rate_limit_result.dart';
import 'package:bayan/core/services/predictive_notification_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SeoMetadata model
  // ---------------------------------------------------------------------------
  group('SeoMetadata', () {
    Map<String, dynamic> diwanMap({
      String id = 'diwan-001',
      String title = 'ديوان الشعر',
      String? description,
      String? coverUrl,
      bool isLive = false,
      int listenerCount = 0,
    }) => <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'is_live': isLive,
      'listener_count': listenerCount,
    };

    test('fromMap parses all fields', () {
      final m = SeoMetadata.fromMap(
        diwanMap(
          coverUrl: 'https://cdn.bayan.app/cover.jpg',
          isLive: true,
          listenerCount: 250,
        ),
      );
      expect(m.diwanId, 'diwan-001');
      expect(m.title, 'ديوان الشعر');
      expect(m.isLive, isTrue);
      expect(m.listenerCount, 250);
      expect(m.imageUrl, 'https://cdn.bayan.app/cover.jpg');
      expect(m.canonicalUrl, 'https://bayan.app/diwan/diwan-001');
    });

    test('resolvedImageUrl uses default when coverUrl is null', () {
      final m = SeoMetadata.fromMap(diwanMap());
      expect(m.resolvedImageUrl, 'https://bayan.app/og-default.png');
    });

    test('resolvedImageUrl uses coverUrl when set', () {
      final m = SeoMetadata.fromMap(
        diwanMap(coverUrl: 'https://cdn.bayan.app/img.png'),
      );
      expect(m.resolvedImageUrl, 'https://cdn.bayan.app/img.png');
    });

    test('ogTitle for live diwan includes 🔴 prefix', () {
      final m = SeoMetadata.fromMap(diwanMap(isLive: true));
      expect(m.ogTitle, startsWith('🔴'));
      expect(m.ogTitle, contains('مباشر الآن'));
    });

    test('ogTitle for non-live diwan has no 🔴 prefix', () {
      final m = SeoMetadata.fromMap(diwanMap());
      expect(m.ogTitle, isNot(contains('🔴')));
      expect(m.ogTitle, contains('بيان'));
    });

    test('ogDescription for live with no description uses listener count', () {
      final m = SeoMetadata.fromMap(diwanMap(isLive: true, listenerCount: 99));
      expect(m.ogDescription, contains('99'));
    });

    test('ogDescription uses provided description when set', () {
      final m = SeoMetadata.fromMap(diwanMap(description: 'وصف مخصص'));
      expect(m.ogDescription, 'وصف مخصص');
    });

    test('ogDescription for non-live with no description uses default', () {
      final m = SeoMetadata.fromMap(diwanMap());
      expect(m.ogDescription, contains('بيان'));
    });

    test('cacheControl for live is short (10s)', () {
      final m = SeoMetadata.fromMap(diwanMap(isLive: true));
      expect(m.cacheControl, contains('max-age=10'));
    });

    test('cacheControl for non-live is longer (300s)', () {
      final m = SeoMetadata.fromMap(diwanMap());
      expect(m.cacheControl, contains('max-age=300'));
    });

    test('defaultMeta returns sensible defaults', () {
      final m = SeoMetadata.defaultMeta();
      expect(m.diwanId, isEmpty);
      expect(m.isLive, isFalse);
      expect(m.canonicalUrl, 'https://bayan.app');
      expect(m.resolvedImageUrl, 'https://bayan.app/og-default.png');
    });

    test('equality by diwanId', () {
      final a = SeoMetadata.fromMap(diwanMap(isLive: true));
      final b = SeoMetadata.fromMap(diwanMap(isLive: false));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different diwanIds are not equal', () {
      final a = SeoMetadata.fromMap(diwanMap(id: 'diwan-001'));
      final b = SeoMetadata.fromMap(diwanMap(id: 'diwan-002'));
      expect(a, isNot(equals(b)));
    });

    test('fromMap handles null optional fields gracefully', () {
      final map = <String, dynamic>{
        'id': 'x',
        'title': null,
        'description': null,
        'cover_url': null,
        'is_live': null,
        'listener_count': null,
      };
      final m = SeoMetadata.fromMap(map);
      expect(m.title, isEmpty);
      expect(m.isLive, isFalse);
      expect(m.listenerCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // NotificationPrediction model
  // ---------------------------------------------------------------------------
  group('NotificationPrediction', () {
    Map<String, dynamic> predMap({
      int bestHour = 18,
      double confidence = 0.45,
      int totalEvents = 30,
      bool isPredicted = true,
      Map<String, dynamic>? hourDist,
    }) => <String, dynamic>{
      'best_hour': bestHour,
      'confidence': confidence,
      'total_events': totalEvents,
      'is_predicted': isPredicted,
      'hour_distribution':
          hourDist ?? <String, dynamic>{'18': 14, '19': 8, '20': 5, '10': 3},
    };

    test('fromMap parses all fields', () {
      final p = NotificationPrediction.fromMap(predMap());
      expect(p.bestHour, 18);
      expect(p.confidence, closeTo(0.45, 0.001));
      expect(p.totalEvents, 30);
      expect(p.isPredicted, isTrue);
      expect(p.hourDistribution[18], 14);
    });

    test('fromMap parses string-keyed hourDistribution', () {
      final p = NotificationPrediction.fromMap(predMap());
      expect(p.hourDistribution.containsKey(18), isTrue);
      expect(p.hourDistribution.containsKey(19), isTrue);
    });

    test('fromMap handles null hourDistribution', () {
      final map = predMap()..['hour_distribution'] = null;
      final p = NotificationPrediction.fromMap(map);
      expect(p.hourDistribution, isEmpty);
    });

    test('defaultPrediction has bestHour=18 and isPredicted=false', () {
      final p = NotificationPrediction.defaultPrediction();
      expect(p.bestHour, 18);
      expect(p.isPredicted, isFalse);
      expect(p.confidence, 0.0);
    });

    test('isHighConfidence true when confidence >= 0.3', () {
      final p = NotificationPrediction.fromMap(predMap(confidence: 0.35));
      expect(p.isHighConfidence, isTrue);
    });

    test('isHighConfidence false when confidence < 0.3', () {
      final p = NotificationPrediction.fromMap(predMap(confidence: 0.1));
      expect(p.isHighConfidence, isFalse);
    });

    test('bestTimeLabel formats 0 as 12:00 AM', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 0));
      expect(p.bestTimeLabel, '12:00 AM');
    });

    test('bestTimeLabel formats 12 as 12:00 PM', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 12));
      expect(p.bestTimeLabel, '12:00 PM');
    });

    test('bestTimeLabel formats 18 as 06:00 PM', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 18));
      expect(p.bestTimeLabel, '06:00 PM');
    });

    test('bestTimeLabel formats 9 as 09:00 AM', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 9));
      expect(p.bestTimeLabel, '09:00 AM');
    });

    test('bestTimeLabel formats 23 as 11:00 PM', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 23));
      expect(p.bestTimeLabel, '11:00 PM');
    });

    test('isWithinOptimalWindow: same hour is true', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 14));
      final at = DateTime(2026, 4, 10, 14, 30);
      expect(p.isWithinOptimalWindow(at: at), isTrue);
    });

    test('isWithinOptimalWindow: 1 hour after is true', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 14));
      final at = DateTime(2026, 4, 10, 15, 0);
      expect(p.isWithinOptimalWindow(at: at), isTrue);
    });

    test('isWithinOptimalWindow: 1 hour before is true', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 14));
      final at = DateTime(2026, 4, 10, 13, 0);
      expect(p.isWithinOptimalWindow(at: at), isTrue);
    });

    test('isWithinOptimalWindow: 2 hours away is false', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 14));
      final at = DateTime(2026, 4, 10, 16, 0);
      expect(p.isWithinOptimalWindow(at: at), isFalse);
    });

    test('isWithinOptimalWindow: midnight wrap-around works (23 bestHour)', () {
      final p = NotificationPrediction.fromMap(predMap(bestHour: 23));
      final at = DateTime(2026, 4, 11, 0, 0);
      expect(p.isWithinOptimalWindow(at: at), isTrue);
    });

    test('equality by bestHour + confidence', () {
      final a = NotificationPrediction.fromMap(
        predMap(bestHour: 18, confidence: 0.5),
      );
      final b = NotificationPrediction.fromMap(
        predMap(bestHour: 18, confidence: 0.5),
      );
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // PredictiveNotificationService — static pure logic
  // ---------------------------------------------------------------------------
  group('PredictiveNotificationService.isTimeInOptimalWindow', () {
    test('exact match returns true', () {
      final at = DateTime(2026, 4, 10, 18, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(18, at),
        isTrue,
      );
    });

    test('+1 hour returns true', () {
      final at = DateTime(2026, 4, 10, 19, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(18, at),
        isTrue,
      );
    });

    test('-1 hour returns true', () {
      final at = DateTime(2026, 4, 10, 17, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(18, at),
        isTrue,
      );
    });

    test('+2 hours returns false', () {
      final at = DateTime(2026, 4, 10, 20, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(18, at),
        isFalse,
      );
    });

    test('midnight wrap: bestHour=23, at=00:00 returns true', () {
      final at = DateTime(2026, 4, 11, 0, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(23, at),
        isTrue,
      );
    });

    test('midnight wrap: bestHour=0, at=23:00 returns true', () {
      final at = DateTime(2026, 4, 10, 23, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(0, at),
        isTrue,
      );
    });

    test('completely out-of-window returns false', () {
      final at = DateTime(2026, 4, 10, 10, 0);
      expect(
        PredictiveNotificationService.isTimeInOptimalWindow(18, at),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // BugReport model
  // ---------------------------------------------------------------------------
  group('BugReport model', () {
    final now = DateTime(2026, 4, 10, 14, 0);

    Map<String, dynamic> bugMap({
      String severity = 'medium',
      String status = 'open',
      String? screenName,
    }) => <String, dynamic>{
      'id': 'bug-001',
      'reporter_id': 'user-001',
      'title': 'App crashed on diwan join',
      'description': 'Tapped join and the app crashed',
      'severity': severity,
      'screen_name': screenName,
      'screen_state': <String, dynamic>{'route': '/diwan/abc'},
      'app_version': '1.9.0',
      'platform': 'android',
      'session_id': 'sess-xyz',
      'device_info': <String, dynamic>{'model': 'Pixel 8'},
      'recent_logs': <dynamic>[],
      'status': status,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final b = BugReport.fromMap(bugMap());
      expect(b.id, 'bug-001');
      expect(b.reporterId, 'user-001');
      expect(b.severity, BugSeverity.medium);
      expect(b.status, BugStatus.open);
      expect(b.isOpen, isTrue);
    });

    test('fromMap parses high severity', () {
      final b = BugReport.fromMap(bugMap(severity: 'high'));
      expect(b.severity, BugSeverity.high);
    });

    test('fromMap parses critical severity', () {
      final b = BugReport.fromMap(bugMap(severity: 'critical'));
      expect(b.severity, BugSeverity.critical);
      expect(b.isCritical, isTrue);
    });

    test('fromMap parses low severity', () {
      final b = BugReport.fromMap(bugMap(severity: 'low'));
      expect(b.severity, BugSeverity.low);
      expect(b.isCritical, isFalse);
    });

    test('unknown severity defaults to medium', () {
      final b = BugReport.fromMap(bugMap(severity: 'xyz'));
      expect(b.severity, BugSeverity.medium);
    });

    test('fromMap parses in_progress status', () {
      final b = BugReport.fromMap(bugMap(status: 'in_progress'));
      expect(b.status, BugStatus.inProgress);
      expect(b.isOpen, isFalse);
    });

    test('fromMap parses resolved status', () {
      final b = BugReport.fromMap(bugMap(status: 'resolved'));
      expect(b.status, BugStatus.resolved);
    });

    test('statusToString round-trips all values', () {
      final pairs = {
        BugStatus.open: 'open',
        BugStatus.inProgress: 'in_progress',
        BugStatus.resolved: 'resolved',
        BugStatus.closed: 'closed',
        BugStatus.duplicate: 'duplicate',
      };
      for (final e in pairs.entries) {
        expect(BugReport.statusToString(e.key), e.value);
      }
    });

    test('severityToString round-trips all values', () {
      final pairs = {
        BugSeverity.low: 'low',
        BugSeverity.medium: 'medium',
        BugSeverity.high: 'high',
        BugSeverity.critical: 'critical',
      };
      for (final e in pairs.entries) {
        expect(BugReport.severityToString(e.key), e.value);
      }
    });

    test('toMap includes required fields', () {
      final b = BugReport.fromMap(bugMap());
      final map = b.toMap();
      expect(map['title'], 'App crashed on diwan join');
      expect(map['severity'], 'medium');
      expect(map['screen_state'], isA<Map>());
    });

    test('equality by id', () {
      final a = BugReport.fromMap(bugMap(severity: 'low'));
      final b = BugReport.fromMap(bugMap(severity: 'critical'));
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // RateLimitResult model
  // ---------------------------------------------------------------------------
  group('RateLimitResult model', () {
    test('fromMap parses allowed=true', () {
      final r = RateLimitResult.fromMap({
        'allowed': true,
        'count': 3,
        'limit': 10,
        'remaining': 7,
        'reset_at': '2026-04-10T15:00:00.000Z',
      });
      expect(r.allowed, isTrue);
      expect(r.count, 3);
      expect(r.remaining, 7);
      expect(r.isThrottled, isFalse);
      expect(r.resetAt, isNotNull);
    });

    test('fromMap parses allowed=false (throttled)', () {
      final r = RateLimitResult.fromMap({
        'allowed': false,
        'count': 11,
        'limit': 10,
        'remaining': 0,
        'reset_at': null,
      });
      expect(r.allowed, isFalse);
      expect(r.isThrottled, isTrue);
      expect(r.remaining, 0);
      expect(r.resetAt, isNull);
    });

    test('open() factory returns safe defaults', () {
      final r = RateLimitResult.open();
      expect(r.allowed, isTrue);
      expect(r.count, 0);
      expect(r.remaining, 10);
    });

    test('equality by allowed + count', () {
      final a = RateLimitResult.fromMap({
        'allowed': true,
        'count': 5,
        'limit': 10,
        'remaining': 5,
      });
      final b = RateLimitResult.fromMap({
        'allowed': true,
        'count': 5,
        'limit': 10,
        'remaining': 5,
      });
      expect(a, equals(b));
    });

    test('fromMap handles all-null gracefully', () {
      final r = RateLimitResult.fromMap({});
      expect(r.allowed, isTrue);
      expect(r.count, 0);
      expect(r.limit, 10);
    });
  });
}
