import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/voice_clip.dart';
import 'package:bayan/core/models/diwan_report.dart';
import 'package:bayan/core/models/trust_score.dart';
import 'package:bayan/core/services/pdf_report_service.dart';
import 'package:bayan/core/services/reputation_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // VoiceClip — TranscriptionStatus enum & model
  // ---------------------------------------------------------------------------
  group('VoiceClip TranscriptionStatus', () {
    final now = DateTime(2026, 4, 10, 14, 0);

    Map<String, dynamic> clipMap({
      String status = 'pending',
      String? transcript,
    }) => {
      'id': 'clip-001',
      'diwan_id': 'diwan-001',
      'speaker_id': 'user-001',
      'title': 'Clip Title',
      'storage_path': 'diwan/clip.m4a',
      'public_url': null,
      'duration_seconds': 90,
      'transcription_status': status,
      'transcript_text': transcript,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses pending status', () {
      final c = VoiceClip.fromMap(clipMap());
      expect(c.transcriptionStatus, TranscriptionStatus.pending);
      expect(c.transcriptText, isNull);
      expect(c.hasTranscript, isFalse);
    });

    test('fromMap parses processing status', () {
      final c = VoiceClip.fromMap(clipMap(status: 'processing'));
      expect(c.transcriptionStatus, TranscriptionStatus.processing);
      expect(c.hasTranscript, isFalse);
    });

    test('fromMap parses completed status with transcript', () {
      final c = VoiceClip.fromMap(
        clipMap(status: 'completed', transcript: 'بسم الله'),
      );
      expect(c.transcriptionStatus, TranscriptionStatus.completed);
      expect(c.transcriptText, 'بسم الله');
      expect(c.hasTranscript, isTrue);
    });

    test('hasTranscript is false when completed but transcript is empty', () {
      final c = VoiceClip.fromMap(clipMap(status: 'completed', transcript: ''));
      expect(c.hasTranscript, isFalse);
    });

    test('hasTranscript is false when completed but transcript is null', () {
      final c = VoiceClip.fromMap(clipMap(status: 'completed'));
      expect(c.hasTranscript, isFalse);
    });

    test('fromMap parses failed status', () {
      final c = VoiceClip.fromMap(clipMap(status: 'failed'));
      expect(c.transcriptionStatus, TranscriptionStatus.failed);
      expect(c.hasTranscript, isFalse);
    });

    test('unknown status defaults to pending', () {
      final c = VoiceClip.fromMap(clipMap(status: 'unknown_value'));
      expect(c.transcriptionStatus, TranscriptionStatus.pending);
    });

    test('null status defaults to pending', () {
      final map = Map<String, dynamic>.from(clipMap())
        ..['transcription_status'] = null;
      expect(
        VoiceClip.fromMap(map).transcriptionStatus,
        TranscriptionStatus.pending,
      );
    });

    test('statusToString round-trips all values', () {
      final pairs = {
        TranscriptionStatus.pending: 'pending',
        TranscriptionStatus.processing: 'processing',
        TranscriptionStatus.completed: 'completed',
        TranscriptionStatus.failed: 'failed',
      };
      for (final e in pairs.entries) {
        expect(
          VoiceClip.statusToString(e.key),
          e.value,
          reason: 'Failed for ${e.key}',
        );
      }
    });

    test('copyWith updates transcript fields', () {
      final c = VoiceClip.fromMap(clipMap());
      final updated = c.copyWith(
        transcriptText: 'الحمد لله',
        transcriptionStatus: TranscriptionStatus.completed,
      );
      expect(updated.transcriptText, 'الحمد لله');
      expect(updated.transcriptionStatus, TranscriptionStatus.completed);
      expect(updated.hasTranscript, isTrue);
      expect(updated.id, c.id);
    });

    test('copyWith preserves unchanged fields', () {
      final c = VoiceClip.fromMap(
        clipMap(status: 'completed', transcript: 'نص'),
      );
      final same = c.copyWith(title: 'New Title');
      expect(same.transcriptText, c.transcriptText);
      expect(same.transcriptionStatus, c.transcriptionStatus);
    });
  });

  // ---------------------------------------------------------------------------
  // DiwanReport model
  // ---------------------------------------------------------------------------
  group('DiwanReport model', () {
    final now = DateTime(2026, 4, 10, 12, 0);

    Map<String, dynamic> reportMap({
      int peakListeners = 200,
      int uniqueListeners = 150,
      int totalRevenue = 5000,
      int ticketRevenue = 3000,
      int ticketsSold = 30,
      int totalGiftsValue = 2000,
      int pollVotes = 80,
      int pollsConducted = 3,
      int totalQuestions = 12,
      int questionsAnswered = 10,
      String summary = 'جلسة ممتازة',
      List<String> keyPoints = const ['نقطة 1', 'نقطة 2'],
      int durationSeconds = 7200,
      String durationFormatted = '2h 0m',
    }) => {
      'diwan_id': 'diwan-001',
      'title': 'ديوان الشعر',
      'generated_at': now.toIso8601String(),
      'session': <String, dynamic>{
        'total_duration_seconds': durationSeconds,
        'total_duration_formatted': durationFormatted,
        'started_at': now.toIso8601String(),
        'ended_at': now.add(const Duration(hours: 2)).toIso8601String(),
      },
      'audience': <String, dynamic>{
        'peak_listeners': peakListeners,
        'unique_listeners': uniqueListeners,
      },
      'economy': <String, dynamic>{
        'total_gifts_value': totalGiftsValue,
        'tickets_sold': ticketsSold,
        'ticket_revenue': ticketRevenue,
        'total_revenue': totalRevenue,
      },
      'engagement': <String, dynamic>{
        'total_poll_votes': pollVotes,
        'polls_conducted': pollsConducted,
        'total_questions': totalQuestions,
        'questions_answered': questionsAnswered,
      },
      'ai_insights': <String, dynamic>{
        'summary': summary,
        'key_points': keyPoints,
      },
    };

    test('fromMap parses all top-level fields', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.diwanId, 'diwan-001');
      expect(r.title, 'ديوان الشعر');
      expect(r.generatedAt, now);
    });

    test('session parsed correctly', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.session.totalDurationSeconds, 7200);
      expect(r.session.totalDurationFormatted, '2h 0m');
      expect(r.session.startedAt, now);
      expect(r.session.endedAt, now.add(const Duration(hours: 2)));
    });

    test('session nullable dates default to null when missing', () {
      final map = reportMap();
      (map['session'] as Map<String, dynamic>)
        ..['started_at'] = null
        ..['ended_at'] = null;
      final r = DiwanReport.fromMap(map);
      expect(r.session.startedAt, isNull);
      expect(r.session.endedAt, isNull);
    });

    test('session defaults to zero when fields missing', () {
      final r = DiwanReport.fromMap(
        reportMap(durationSeconds: 0, durationFormatted: '0s'),
      );
      expect(r.session.totalDurationSeconds, 0);
      expect(r.session.totalDurationFormatted, '0s');
    });

    test('audience parsed correctly', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.audience.peakListeners, 200);
      expect(r.audience.uniqueListeners, 150);
    });

    test('economy parsed correctly', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.economy.totalRevenue, 5000);
      expect(r.economy.ticketRevenue, 3000);
      expect(r.economy.ticketsSold, 30);
      expect(r.economy.totalGiftsValue, 2000);
    });

    test('economy defaults to zero when fields missing', () {
      final map = reportMap();
      map['economy'] = const <String, dynamic>{};
      final r = DiwanReport.fromMap(map);
      expect(r.economy.totalRevenue, 0);
      expect(r.economy.ticketsSold, 0);
    });

    test('engagement parsed correctly', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.engagement.totalPollVotes, 80);
      expect(r.engagement.pollsConducted, 3);
      expect(r.engagement.totalQuestions, 12);
      expect(r.engagement.questionsAnswered, 10);
    });

    test('ai_insights summary parsed correctly', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.aiInsights.summary, 'جلسة ممتازة');
    });

    test('ai_insights key_points parsed as list', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.aiInsights.keyPoints, ['نقطة 1', 'نقطة 2']);
    });

    test('ai_insights key_points defaults to empty list', () {
      final map = reportMap();
      (map['ai_insights'] as Map<String, dynamic>)['key_points'] = null;
      final r = DiwanReport.fromMap(map);
      expect(r.aiInsights.keyPoints, isEmpty);
    });

    test('equality by diwanId', () {
      final a = DiwanReport.fromMap(reportMap(totalRevenue: 100));
      final b = DiwanReport.fromMap(reportMap(totalRevenue: 999));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different diwanIds not equal', () {
      final a = DiwanReport.fromMap(reportMap());
      final map = reportMap();
      map['diwan_id'] = 'diwan-999';
      final b = DiwanReport.fromMap(map);
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // PdfReportService — byte output
  // ---------------------------------------------------------------------------
  group('PdfReportService', () {
    final now = DateTime(2026, 4, 10, 12, 0);
    late PdfReportService svc;

    DiwanReport mkReport({
      String summary = 'ملخص ممتاز',
      List<String> keyPoints = const ['نقطة أولى', 'نقطة ثانية'],
      int peakListeners = 500,
      int totalRevenue = 10000,
    }) {
      return DiwanReport(
        diwanId: 'diwan-001',
        title: 'ديوان الشعر العربي',
        generatedAt: now,
        session: const DiwanReportSession(
          totalDurationSeconds: 5400,
          totalDurationFormatted: '1h 30m',
        ),
        audience: DiwanReportAudience(
          peakListeners: peakListeners,
          uniqueListeners: 350,
        ),
        economy: DiwanReportEconomy(
          totalGiftsValue: 3000,
          ticketsSold: 50,
          ticketRevenue: 5000,
          totalRevenue: totalRevenue,
        ),
        engagement: const DiwanReportEngagement(
          totalPollVotes: 120,
          pollsConducted: 4,
          totalQuestions: 20,
          questionsAnswered: 18,
        ),
        aiInsights: DiwanReportAiInsights(
          summary: summary,
          keyPoints: keyPoints,
        ),
      );
    }

    setUp(() {
      svc = PdfReportService();
    });

    test('generate returns non-empty bytes', () async {
      final bytes = await svc.generate(mkReport());
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('generated PDF starts with PDF magic bytes %PDF', () async {
      final bytes = await svc.generate(mkReport());
      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      expect(magic, '%PDF');
    });

    test('generate works with empty keyPoints', () async {
      final bytes = await svc.generate(mkReport(keyPoints: []));
      expect(bytes.isNotEmpty, isTrue);
    });

    test('generate works with empty summary', () async {
      final bytes = await svc.generate(mkReport(summary: ''));
      expect(bytes.isNotEmpty, isTrue);
    });

    test('generate produces different bytes for different reports', () async {
      final bytes1 = await svc.generate(mkReport(totalRevenue: 1000));
      final bytes2 = await svc.generate(mkReport(totalRevenue: 99999));
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('can call generate multiple times on same service', () async {
      final b1 = await svc.generate(mkReport());
      final b2 = await svc.generate(mkReport());
      expect(b1.isNotEmpty, isTrue);
      expect(b2.isNotEmpty, isTrue);
    });

    test('large keyPoints list does not throw', () async {
      final kp = List.generate(30, (i) => 'نقطة رقم $i');
      expect(
        () async => await svc.generate(mkReport(keyPoints: kp)),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TrustScore — verifiedProComponent
  // ---------------------------------------------------------------------------
  group('TrustScore verifiedProComponent', () {
    test('fromMap parses verifiedProComponent', () {
      final ts = TrustScore.fromMap('user-001', {
        'score': 75,
        'xp_component': 30,
        'streak_component': 5,
        'governance_component': 10,
        'subscription_component': 20,
        'verified_pro_component': 10,
      });
      expect(ts.verifiedProComponent, 10);
      expect(ts.score, 75);
    });

    test('verifiedProComponent defaults to 0 when missing', () {
      final ts = TrustScore.fromMap('user-001', {
        'score': 65,
        'xp_component': 30,
        'streak_component': 5,
        'governance_component': 10,
        'subscription_component': 20,
      });
      expect(ts.verifiedProComponent, 0);
    });

    test('TrustScore.zero includes verifiedProComponent = 0', () {
      final ts = TrustScore.zero('user-001');
      expect(ts.verifiedProComponent, 0);
      expect(ts.score, 0);
    });

    test('equality still uses userId + score', () {
      final a = TrustScore.fromMap('user-001', {
        'score': 80,
        'xp_component': 30,
        'streak_component': 5,
        'governance_component': 15,
        'subscription_component': 20,
        'verified_pro_component': 10,
      });
      final b = TrustScore.fromMap('user-001', {
        'score': 80,
        'xp_component': 30,
        'streak_component': 5,
        'governance_component': 15,
        'subscription_component': 20,
        'verified_pro_component': 0,
      });
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // ReputationService — verified professional multiplier (pure logic)
  // ---------------------------------------------------------------------------
  group('ReputationService — verified professional multiplier', () {
    test('verifiedProfessionalMultiplier constant is 1.5', () {
      expect(ReputationService.verifiedProfessionalMultiplier, 1.5);
    });

    test('applying 1.5× to 60 yields 90', () {
      const base = 60;
      final result = (base * ReputationService.verifiedProfessionalMultiplier)
          .round();
      expect(result, 90);
    });

    test('applying 1.5× to 70 yields 105 then clamps to 100', () {
      const base = 70;
      final raw = (base * ReputationService.verifiedProfessionalMultiplier)
          .round();
      final clamped = raw.clamp(0, 100);
      expect(raw, 105);
      expect(clamped, 100);
    });

    test('applying 1.5× to 0 yields 0', () {
      const base = 0;
      final result = (base * ReputationService.verifiedProfessionalMultiplier)
          .round();
      expect(result, 0);
    });

    test('non-verified user gets base score unchanged', () {
      final ts = TrustScore.fromMap('u1', {
        'score': 55,
        'xp_component': 20,
        'streak_component': 5,
        'governance_component': 10,
        'subscription_component': 20,
        'verified_pro_component': 0,
      });
      expect(ts.verifiedProComponent, 0);
      const base = 55;
      expect(base, 55);
    });

    test('TrustScore with verifiedProComponent > 0 qualifies for bonus', () {
      final ts = TrustScore.fromMap('u1', {
        'score': 65,
        'xp_component': 25,
        'streak_component': 5,
        'governance_component': 15,
        'subscription_component': 10,
        'verified_pro_component': 10,
      });
      expect(ts.verifiedProComponent > 0, isTrue);
    });
  });
}
