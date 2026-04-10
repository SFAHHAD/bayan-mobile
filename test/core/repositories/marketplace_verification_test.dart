import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/ticket.dart';
import 'package:bayan/core/models/verification_request.dart';
import 'package:bayan/core/models/diwan_report.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/models/profile.dart';

void main() {
  final now = DateTime(2026, 4, 10, 12, 0);

  // -------------------------------------------------------------------------
  // Ticket model
  // -------------------------------------------------------------------------
  group('Ticket model', () {
    Map<String, dynamic> ticketMap({int price = 100}) => {
      'id': 'tkt-001',
      'user_id': 'user-001',
      'diwan_id': 'diwan-001',
      'purchase_price': price,
      'purchased_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final t = Ticket.fromMap(ticketMap());
      expect(t.id, 'tkt-001');
      expect(t.userId, 'user-001');
      expect(t.diwanId, 'diwan-001');
      expect(t.purchasePrice, 100);
      expect(t.purchasedAt, now);
    });

    test('isFree is false when price > 0', () {
      expect(Ticket.fromMap(ticketMap(price: 50)).isFree, isFalse);
    });

    test('isFree is true when price = 0', () {
      expect(Ticket.fromMap(ticketMap(price: 0)).isFree, isTrue);
    });

    test('purchase_price defaults to 0 when null', () {
      final map = Map<String, dynamic>.from(ticketMap())
        ..['purchase_price'] = null;
      expect(Ticket.fromMap(map).purchasePrice, 0);
    });

    test('toMap contains required fields', () {
      final t = Ticket.fromMap(ticketMap());
      final m = t.toMap();
      expect(m['user_id'], 'user-001');
      expect(m['diwan_id'], 'diwan-001');
      expect(m['purchase_price'], 100);
    });

    test('equality by id', () {
      final a = Ticket.fromMap(ticketMap(price: 10));
      final b = Ticket.fromMap(ticketMap(price: 200));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids not equal', () {
      final a = Ticket.fromMap(ticketMap());
      final b = Ticket.fromMap({...ticketMap(), 'id': 'tkt-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // VerificationRequest model
  // -------------------------------------------------------------------------
  group('VerificationRequest model', () {
    Map<String, dynamic> reqMap({
      String status = 'pending',
      List<String> docs = const ['https://doc1.pdf'],
      String? notes,
      String? reviewedBy,
      String? reviewedAt,
    }) => {
      'id': 'vr-001',
      'user_id': 'user-001',
      'status': status,
      'documents_urls': docs,
      'professional_title': 'خبير اقتصادي',
      'verified_category': 'finance',
      'reviewer_notes': notes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all statuses correctly', () {
      for (final entry in {
        'pending': VerificationStatus.pending,
        'under_review': VerificationStatus.underReview,
        'approved': VerificationStatus.approved,
        'rejected': VerificationStatus.rejected,
      }.entries) {
        final vr = VerificationRequest.fromMap(reqMap(status: entry.key));
        expect(
          vr.status,
          entry.value,
          reason: 'Failed for status: ${entry.key}',
        );
      }
    });

    test('isPending, isUnderReview, isApproved, isRejected flags', () {
      expect(
        VerificationRequest.fromMap(reqMap(status: 'pending')).isPending,
        isTrue,
      );
      expect(
        VerificationRequest.fromMap(
          reqMap(status: 'under_review'),
        ).isUnderReview,
        isTrue,
      );
      expect(
        VerificationRequest.fromMap(reqMap(status: 'approved')).isApproved,
        isTrue,
      );
      expect(
        VerificationRequest.fromMap(reqMap(status: 'rejected')).isRejected,
        isTrue,
      );
    });

    test('isActive is true for pending and under_review', () {
      expect(
        VerificationRequest.fromMap(reqMap(status: 'pending')).isActive,
        isTrue,
      );
      expect(
        VerificationRequest.fromMap(reqMap(status: 'under_review')).isActive,
        isTrue,
      );
      expect(
        VerificationRequest.fromMap(reqMap(status: 'approved')).isActive,
        isFalse,
      );
      expect(
        VerificationRequest.fromMap(reqMap(status: 'rejected')).isActive,
        isFalse,
      );
    });

    test('statusString round-trips correctly', () {
      for (final s in ['pending', 'under_review', 'approved', 'rejected']) {
        final vr = VerificationRequest.fromMap(reqMap(status: s));
        expect(vr.statusString, s);
      }
    });

    test('documents_urls parsed from list', () {
      final vr = VerificationRequest.fromMap(
        reqMap(docs: ['url1', 'url2', 'url3']),
      );
      expect(vr.documentsUrls, ['url1', 'url2', 'url3']);
    });

    test('documents_urls defaults to empty when field is non-list', () {
      final map = Map<String, dynamic>.from(reqMap())
        ..['documents_urls'] = null;
      final vr = VerificationRequest.fromMap(map);
      expect(vr.documentsUrls, isEmpty);
    });

    test('reviewerNotes and reviewedBy are nullable', () {
      final vr = VerificationRequest.fromMap(reqMap());
      expect(vr.reviewerNotes, isNull);
      expect(vr.reviewedBy, isNull);
    });

    test('reviewedAt parsed when present', () {
      final vr = VerificationRequest.fromMap(
        reqMap(reviewedAt: now.toIso8601String()),
      );
      expect(vr.reviewedAt, now);
    });

    test('copyWith updates status only', () {
      final vr = VerificationRequest.fromMap(reqMap(status: 'pending'));
      final updated = vr.copyWith(status: VerificationStatus.approved);
      expect(updated.status, VerificationStatus.approved);
      expect(updated.id, vr.id);
      expect(updated.professionalTitle, vr.professionalTitle);
    });

    test('copyWith updates documentsUrls independently', () {
      final vr = VerificationRequest.fromMap(reqMap());
      final updated = vr.copyWith(documentsUrls: ['new-doc.pdf']);
      expect(updated.documentsUrls, ['new-doc.pdf']);
      expect(updated.userId, vr.userId);
    });

    test('equality by id', () {
      final a = VerificationRequest.fromMap(reqMap(status: 'pending'));
      final b = VerificationRequest.fromMap(reqMap(status: 'approved'));
      expect(a, equals(b));
    });

    test('different ids not equal', () {
      final a = VerificationRequest.fromMap(reqMap());
      final b = VerificationRequest.fromMap({...reqMap(), 'id': 'vr-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // DiwanReport model
  // -------------------------------------------------------------------------
  group('DiwanReport model', () {
    Map<String, dynamic> reportMap() => {
      'diwan_id': 'diwan-001',
      'title': 'ديوان الاقتصاد العربي',
      'generated_at': now.toIso8601String(),
      'session': {
        'total_duration_seconds': 3720,
        'total_duration_formatted': '1h 2m 0s',
        'started_at': now.toIso8601String(),
        'ended_at': now.add(const Duration(hours: 1)).toIso8601String(),
      },
      'audience': {'peak_listeners': 245, 'unique_listeners': 310},
      'economy': {
        'total_gifts_value': 1500,
        'tickets_sold': 20,
        'ticket_revenue': 2000,
        'total_revenue': 3500,
      },
      'engagement': {
        'total_poll_votes': 180,
        'polls_conducted': 3,
        'total_questions': 45,
        'questions_answered': 12,
      },
      'ai_insights': {
        'summary': 'ناقش الديوان مستقبل الاقتصاد الرقمي',
        'key_points': ['التحول الرقمي', 'العملات المشفرة'],
      },
    };

    test('fromMap parses all fields', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.diwanId, 'diwan-001');
      expect(r.title, 'ديوان الاقتصاد العربي');
      expect(r.session.totalDurationSeconds, 3720);
      expect(r.session.totalDurationFormatted, '1h 2m 0s');
      expect(r.audience.peakListeners, 245);
      expect(r.audience.uniqueListeners, 310);
      expect(r.economy.totalGiftsValue, 1500);
      expect(r.economy.ticketsSold, 20);
      expect(r.economy.ticketRevenue, 2000);
      expect(r.economy.totalRevenue, 3500);
      expect(r.engagement.totalPollVotes, 180);
      expect(r.engagement.pollsConducted, 3);
      expect(r.engagement.totalQuestions, 45);
      expect(r.engagement.questionsAnswered, 12);
      expect(r.aiInsights.summary, isNotEmpty);
      expect(r.aiInsights.keyPoints, hasLength(2));
    });

    test('session startedAt and endedAt parsed', () {
      final r = DiwanReport.fromMap(reportMap());
      expect(r.session.startedAt, now);
      expect(r.session.endedAt, isNotNull);
    });

    test('aiInsights keyPoints defaults to empty on missing', () {
      final base = reportMap();
      final aiInsights = Map<String, dynamic>.from(
        base['ai_insights'] as Map<String, dynamic>,
      )..remove('key_points');
      final map = Map<String, dynamic>.from(base)..['ai_insights'] = aiInsights;
      final r = DiwanReport.fromMap(map);
      expect(r.aiInsights.keyPoints, isEmpty);
    });

    test('equality by diwanId', () {
      final a = DiwanReport.fromMap(reportMap());
      final b = DiwanReport.fromMap(reportMap());
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // Diwan model — new fields
  // -------------------------------------------------------------------------
  group('Diwan model — marketplace fields', () {
    Map<String, dynamic> diwanMap({
      int entryFee = 0,
      bool isPremium = false,
      String moderationStatus = 'approved',
    }) => {
      'id': 'diwan-001',
      'title': 'ديوان الاقتصاد',
      'is_public': true,
      'is_live': false,
      'entry_fee': entryFee,
      'is_premium': isPremium,
      'moderation_status': moderationStatus,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test(
      'defaults: entryFee=0, isPremium=false, moderationStatus=approved',
      () {
        final d = Diwan.fromMap({
          'id': 'x',
          'title': 'y',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        expect(d.entryFee, 0);
        expect(d.isPremium, isFalse);
        expect(d.moderationStatus, 'approved');
      },
    );

    test('fromMap parses premium fields', () {
      final d = Diwan.fromMap(diwanMap(entryFee: 50, isPremium: true));
      expect(d.entryFee, 50);
      expect(d.isPremium, isTrue);
    });

    test('fromMap parses moderation statuses', () {
      for (final s in ['pending', 'approved', 'rejected']) {
        final d = Diwan.fromMap(diwanMap(moderationStatus: s));
        expect(d.moderationStatus, s, reason: 'Failed for: $s');
      }
    });

    test('copyWith updates premium fields', () {
      final d = Diwan.fromMap(diwanMap());
      final premium = d.copyWith(isPremium: true, entryFee: 100);
      expect(premium.isPremium, isTrue);
      expect(premium.entryFee, 100);
      expect(premium.id, d.id);
    });

    test('toMap includes entry_fee and is_premium', () {
      final d = Diwan.fromMap(diwanMap(entryFee: 75, isPremium: true));
      expect(d.toMap()['entry_fee'], 75);
      expect(d.toMap()['is_premium'], isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Profile model — verification fields
  // -------------------------------------------------------------------------
  group('Profile model — verification fields', () {
    Map<String, dynamic> profileMap({
      bool isVerified = false,
      String? professionalTitle,
      String? verifiedCategory,
    }) => {
      'id': 'user-001',
      'is_founder': false,
      'is_verified': isVerified,
      'professional_title': professionalTitle,
      'verified_category': verifiedCategory,
      'follower_count': 0,
      'following_count': 0,
      'voice_count': 0,
      'created_at': now.toIso8601String(),
    };

    test('defaults: isVerified=false, fields=null', () {
      final p = Profile.fromMap(profileMap());
      expect(p.isVerified, isFalse);
      expect(p.professionalTitle, isNull);
      expect(p.verifiedCategory, isNull);
    });

    test('fromMap parses verified profile', () {
      final p = Profile.fromMap(
        profileMap(
          isVerified: true,
          professionalTitle: 'أستاذ جامعي',
          verifiedCategory: 'education',
        ),
      );
      expect(p.isVerified, isTrue);
      expect(p.professionalTitle, 'أستاذ جامعي');
      expect(p.verifiedCategory, 'education');
    });

    test('copyWith updates isVerified', () {
      final p = Profile.fromMap(profileMap());
      final verified = p.copyWith(
        isVerified: true,
        professionalTitle: 'محامٍ',
        verifiedCategory: 'law',
      );
      expect(verified.isVerified, isTrue);
      expect(verified.professionalTitle, 'محامٍ');
      expect(verified.id, p.id);
    });
  });
}
