import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/governance_vote.dart';
import 'package:bayan/core/models/proposal.dart';
import 'package:bayan/core/models/purchase_receipt.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/models/trust_score.dart';
import 'package:bayan/core/services/payment_service.dart';
import 'package:bayan/core/services/privacy_service.dart';

void main() {
  final now = DateTime(2026, 4, 10, 15, 0);
  final future = now.add(const Duration(days: 30));
  final past = now.subtract(const Duration(days: 1));

  // =========================================================================
  // Proposal model
  // =========================================================================
  group('Proposal model', () {
    Map<String, dynamic> proposalMap({
      String type = 'feature',
      String status = 'proposed',
      int yes = 0,
      int no = 0,
      int abstain = 0,
      String? votingStartsAt,
      String? votingEndsAt,
    }) => {
      'id': 'prop-001',
      'creator_id': 'user-001',
      'title': 'إضافة غرف المناظرات',
      'body': 'اقتراح لإضافة نمط جديد',
      'type': type,
      'status': status,
      'yes_votes': yes,
      'no_votes': no,
      'abstain_votes': abstain,
      'voting_starts_at': votingStartsAt,
      'voting_ends_at': votingEndsAt,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final p = Proposal.fromMap(proposalMap());
      expect(p.id, 'prop-001');
      expect(p.creatorId, 'user-001');
      expect(p.title, 'إضافة غرف المناظرات');
      expect(p.type, ProposalType.feature);
      expect(p.status, ProposalStatus.proposed);
      expect(p.yesVotes, 0);
      expect(p.createdAt, now);
    });

    test('parses all ProposalType values', () {
      for (final entry in {
        'feature': ProposalType.feature,
        'rule': ProposalType.rule,
        'moderation': ProposalType.moderation,
        'other': ProposalType.other,
        null: ProposalType.other,
      }.entries) {
        final p = Proposal.fromMap({...proposalMap(), 'type': entry.key});
        expect(p.type, entry.value, reason: 'type=${entry.key}');
      }
    });

    test('typeToString round-trips', () {
      for (final entry in {
        ProposalType.feature: 'feature',
        ProposalType.rule: 'rule',
        ProposalType.moderation: 'moderation',
        ProposalType.other: 'other',
      }.entries) {
        expect(Proposal.typeToString(entry.key), entry.value);
      }
    });

    test('parses all ProposalStatus values', () {
      for (final entry in {
        'proposed': ProposalStatus.proposed,
        'voting': ProposalStatus.voting,
        'approved': ProposalStatus.approved,
        'rejected': ProposalStatus.rejected,
        'withdrawn': ProposalStatus.withdrawn,
        null: ProposalStatus.proposed,
      }.entries) {
        final p = Proposal.fromMap({...proposalMap(), 'status': entry.key});
        expect(p.status, entry.value, reason: 'status=${entry.key}');
      }
    });

    test('statusToString round-trips', () {
      for (final entry in {
        ProposalStatus.proposed: 'proposed',
        ProposalStatus.voting: 'voting',
        ProposalStatus.approved: 'approved',
        ProposalStatus.rejected: 'rejected',
        ProposalStatus.withdrawn: 'withdrawn',
      }.entries) {
        expect(Proposal.statusToString(entry.key), entry.value);
      }
    });

    test('totalVotes sums all three choices', () {
      final p = Proposal.fromMap(proposalMap(yes: 10, no: 5, abstain: 2));
      expect(p.totalVotes, 17);
    });

    test('approvalRate: yes/(yes+no)', () {
      final p = Proposal.fromMap(proposalMap(yes: 3, no: 1));
      expect(p.approvalRate, 0.75);
    });

    test('approvalRate: 0 when no decisive votes', () {
      final p = Proposal.fromMap(proposalMap(abstain: 5));
      expect(p.approvalRate, 0.0);
    });

    test('isVotingOpen: false when status is not voting', () {
      final p = Proposal.fromMap(proposalMap(status: 'proposed'));
      expect(p.isVotingOpen, isFalse);
    });

    test('isVotingOpen: true when voting + no time bounds', () {
      final p = Proposal.fromMap(proposalMap(status: 'voting'));
      expect(p.isVotingOpen, isTrue);
    });

    test('isVotingOpen: false when voting_ends_at has passed', () {
      final p = Proposal.fromMap(
        proposalMap(status: 'voting', votingEndsAt: past.toIso8601String()),
      );
      expect(p.isVotingOpen, isFalse);
    });

    test('isVotingOpen: true when within window', () {
      final p = Proposal.fromMap(
        proposalMap(
          status: 'voting',
          votingStartsAt: past.toIso8601String(),
          votingEndsAt: future.toIso8601String(),
        ),
      );
      expect(p.isVotingOpen, isTrue);
    });

    test('isFinalized: true for approved/rejected/withdrawn', () {
      for (final s in ['approved', 'rejected', 'withdrawn']) {
        final p = Proposal.fromMap(proposalMap(status: s));
        expect(p.isFinalized, isTrue, reason: s);
      }
    });

    test('isFinalized: false for proposed/voting', () {
      for (final s in ['proposed', 'voting']) {
        final p = Proposal.fromMap(proposalMap(status: s));
        expect(p.isFinalized, isFalse, reason: s);
      }
    });

    test('isVotingExpired: true when ends_at in past', () {
      final p = Proposal.fromMap(
        proposalMap(status: 'voting', votingEndsAt: past.toIso8601String()),
      );
      expect(p.isVotingExpired, isTrue);
    });

    test('isVotingExpired: false when ends_at in future', () {
      final p = Proposal.fromMap(
        proposalMap(status: 'voting', votingEndsAt: future.toIso8601String()),
      );
      expect(p.isVotingExpired, isFalse);
    });

    test('isVotingExpired: false when no voting_ends_at', () {
      final p = Proposal.fromMap(proposalMap(status: 'voting'));
      expect(p.isVotingExpired, isFalse);
    });

    test('copyWith updates status and votes', () {
      final p = Proposal.fromMap(proposalMap());
      final updated = p.copyWith(status: ProposalStatus.approved, yesVotes: 20);
      expect(updated.status, ProposalStatus.approved);
      expect(updated.yesVotes, 20);
      expect(updated.id, p.id);
    });

    test('equality by id', () {
      final a = Proposal.fromMap(proposalMap(yes: 5));
      final b = Proposal.fromMap(proposalMap(yes: 10));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids not equal', () {
      final a = Proposal.fromMap(proposalMap());
      final b = Proposal.fromMap({...proposalMap(), 'id': 'prop-002'});
      expect(a, isNot(equals(b)));
    });

    test('toString includes id and status', () {
      final p = Proposal.fromMap(proposalMap());
      expect(p.toString(), contains('prop-001'));
      expect(p.toString(), contains('proposed'));
    });
  });

  // =========================================================================
  // GovernanceVote model
  // =========================================================================
  group('GovernanceVote model', () {
    Map<String, dynamic> voteMap({String vote = 'yes'}) => {
      'id': 'vote-001',
      'proposal_id': 'prop-001',
      'user_id': 'user-001',
      'vote': vote,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all VoteChoice values', () {
      for (final entry in {
        'yes': VoteChoice.yes,
        'no': VoteChoice.no,
        'abstain': VoteChoice.abstain,
        null: VoteChoice.abstain,
      }.entries) {
        final v = GovernanceVote.fromMap({...voteMap(), 'vote': entry.key});
        expect(v.vote, entry.value, reason: 'vote=${entry.key}');
      }
    });

    test('voteToString round-trips', () {
      for (final entry in {
        VoteChoice.yes: 'yes',
        VoteChoice.no: 'no',
        VoteChoice.abstain: 'abstain',
      }.entries) {
        expect(GovernanceVote.voteToString(entry.key), entry.value);
      }
    });

    test('fromMap sets all fields correctly', () {
      final v = GovernanceVote.fromMap(voteMap());
      expect(v.id, 'vote-001');
      expect(v.proposalId, 'prop-001');
      expect(v.userId, 'user-001');
      expect(v.vote, VoteChoice.yes);
      expect(v.createdAt, now);
    });

    test('equality by id', () {
      final a = GovernanceVote.fromMap(voteMap(vote: 'yes'));
      final b = GovernanceVote.fromMap(voteMap(vote: 'no'));
      expect(a, equals(b));
    });

    test('different ids not equal', () {
      final a = GovernanceVote.fromMap(voteMap());
      final b = GovernanceVote.fromMap({...voteMap(), 'id': 'vote-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // =========================================================================
  // TrustScore model
  // =========================================================================
  group('TrustScore model', () {
    test('fromMap parses all components', () {
      final ts = TrustScore.fromMap('user-001', {
        'score': 65,
        'xp_component': 30,
        'streak_component': 8,
        'governance_component': 17,
        'subscription_component': 10,
      });
      expect(ts.score, 65);
      expect(ts.xpComponent, 30);
      expect(ts.streakComponent, 8);
      expect(ts.governanceComponent, 17);
      expect(ts.subscriptionComponent, 10);
    });

    test('fromMap defaults missing fields to 0', () {
      final ts = TrustScore.fromMap('user-001', {});
      expect(ts.score, 0);
      expect(ts.xpComponent, 0);
    });

    test('TrustScore.zero produces all-zero score', () {
      final ts = TrustScore.zero('user-001');
      expect(ts.score, 0);
      expect(ts.tier, TrustTier.newcomer);
    });

    test('normalizedScore clamps 0–1', () {
      final ts = TrustScore.fromMap('u', {'score': 75});
      expect(ts.normalizedScore, 0.75);
      final max = TrustScore.fromMap('u', {'score': 100});
      expect(max.normalizedScore, 1.0);
    });

    test('toString includes score and tier', () {
      final ts = TrustScore.fromMap('u', {'score': 50});
      expect(ts.toString(), contains('50'));
    });

    test('equality by userId + score', () {
      final a = TrustScore.fromMap('user-001', {'score': 50});
      final b = TrustScore.fromMap('user-001', {'score': 50});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different score not equal', () {
      final a = TrustScore.fromMap('user-001', {'score': 50});
      final b = TrustScore.fromMap('user-001', {'score': 60});
      expect(a, isNot(equals(b)));
    });
  });

  // =========================================================================
  // TrustTier enum
  // =========================================================================
  group('TrustTier enum', () {
    test('fromScore maps thresholds correctly', () {
      expect(TrustTier.fromScore(0), TrustTier.newcomer);
      expect(TrustTier.fromScore(19), TrustTier.newcomer);
      expect(TrustTier.fromScore(20), TrustTier.trusted);
      expect(TrustTier.fromScore(39), TrustTier.trusted);
      expect(TrustTier.fromScore(40), TrustTier.respected);
      expect(TrustTier.fromScore(60), TrustTier.pillar);
      expect(TrustTier.fromScore(80), TrustTier.guardian);
      expect(TrustTier.fromScore(100), TrustTier.guardian);
    });

    test('all tiers have non-empty label and badge', () {
      for (final tier in TrustTier.values) {
        expect(tier.label.isNotEmpty, isTrue, reason: tier.name);
        expect(tier.badge.isNotEmpty, isTrue, reason: tier.name);
      }
    });

    test('minScore values are non-decreasing', () {
      final scores = TrustTier.values.map((t) => t.minScore).toList();
      for (int i = 1; i < scores.length; i++) {
        expect(scores[i], greaterThanOrEqualTo(scores[i - 1]));
      }
    });
  });

  // =========================================================================
  // PurchaseReceipt model
  // =========================================================================
  group('PurchaseReceipt model', () {
    Map<String, dynamic> receiptMap({
      String platform = 'apple',
      String status = 'pending',
      String? validatedAt,
      String? tierType,
      Map<String, dynamic>? rawResponse,
    }) => {
      'id': 'receipt-001',
      'user_id': 'user-001',
      'platform': platform,
      'product_id': 'bayan_gold_monthly',
      'transaction_id': 'txn-abc123',
      'receipt_data': 'base64encodeddata==',
      'status': status,
      'validated_at': validatedAt,
      'tier_type': tierType,
      'raw_response': rawResponse,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final r = PurchaseReceipt.fromMap(
        receiptMap(
          status: 'valid',
          validatedAt: now.toIso8601String(),
          tierType: 'gold',
        ),
      );
      expect(r.id, 'receipt-001');
      expect(r.userId, 'user-001');
      expect(r.platform, ReceiptPlatform.apple);
      expect(r.productId, 'bayan_gold_monthly');
      expect(r.transactionId, 'txn-abc123');
      expect(r.status, ReceiptStatus.valid);
      expect(r.validatedAt, isNotNull);
      expect(r.tierType, TierType.gold);
    });

    test('parses all ReceiptPlatform values', () {
      for (final entry in {
        'apple': ReceiptPlatform.apple,
        'google': ReceiptPlatform.google,
        'stripe': ReceiptPlatform.stripe,
        null: ReceiptPlatform.stripe,
      }.entries) {
        final r = PurchaseReceipt.fromMap({
          ...receiptMap(),
          'platform': entry.key,
        });
        expect(r.platform, entry.value, reason: 'platform=${entry.key}');
      }
    });

    test('platformToString round-trips', () {
      for (final entry in {
        ReceiptPlatform.apple: 'apple',
        ReceiptPlatform.google: 'google',
        ReceiptPlatform.stripe: 'stripe',
      }.entries) {
        expect(PurchaseReceipt.platformToString(entry.key), entry.value);
      }
    });

    test('parses all ReceiptStatus values', () {
      for (final entry in {
        'pending': ReceiptStatus.pending,
        'valid': ReceiptStatus.valid,
        'invalid': ReceiptStatus.invalid,
        'expired': ReceiptStatus.expired,
        'refunded': ReceiptStatus.refunded,
        null: ReceiptStatus.pending,
      }.entries) {
        final r = PurchaseReceipt.fromMap({
          ...receiptMap(),
          'status': entry.key,
        });
        expect(r.status, entry.value, reason: 'status=${entry.key}');
      }
    });

    test('statusToString round-trips', () {
      for (final entry in {
        ReceiptStatus.pending: 'pending',
        ReceiptStatus.valid: 'valid',
        ReceiptStatus.invalid: 'invalid',
        ReceiptStatus.expired: 'expired',
        ReceiptStatus.refunded: 'refunded',
      }.entries) {
        expect(PurchaseReceipt.statusToString(entry.key), entry.value);
      }
    });

    test('isValid: true only for valid status', () {
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'valid')).isValid,
        isTrue,
      );
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'pending')).isValid,
        isFalse,
      );
    });

    test('isPending: true only for pending status', () {
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'pending')).isPending,
        isTrue,
      );
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'valid')).isPending,
        isFalse,
      );
    });

    test('isTerminal: true for invalid/refunded/expired', () {
      for (final s in ['invalid', 'refunded', 'expired']) {
        expect(
          PurchaseReceipt.fromMap(receiptMap(status: s)).isTerminal,
          isTrue,
          reason: s,
        );
      }
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'valid')).isTerminal,
        isFalse,
      );
      expect(
        PurchaseReceipt.fromMap(receiptMap(status: 'pending')).isTerminal,
        isFalse,
      );
    });

    test('tierType null when not provided', () {
      final r = PurchaseReceipt.fromMap(receiptMap());
      expect(r.tierType, isNull);
    });

    test('rawResponse parsed from Map', () {
      final r = PurchaseReceipt.fromMap(
        receiptMap(rawResponse: {'status': 0, 'mock': true}),
      );
      expect(r.rawResponse!['status'], 0);
    });

    test('rawResponse null when not provided', () {
      final r = PurchaseReceipt.fromMap(receiptMap());
      expect(r.rawResponse, isNull);
    });

    test('equality by id', () {
      final a = PurchaseReceipt.fromMap(receiptMap(status: 'pending'));
      final b = PurchaseReceipt.fromMap(receiptMap(status: 'valid'));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids not equal', () {
      final a = PurchaseReceipt.fromMap(receiptMap());
      final b = PurchaseReceipt.fromMap({...receiptMap(), 'id': 'receipt-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // =========================================================================
  // PaymentResult model
  // =========================================================================
  group('PaymentResult model', () {
    test('isValid: true when receiptStatus=valid', () {
      const r = PaymentResult(
        success: true,
        receiptStatus: ReceiptStatus.valid,
      );
      expect(r.isValid, isTrue);
    });

    test('isValid: false for non-valid statuses', () {
      for (final s in [
        ReceiptStatus.pending,
        ReceiptStatus.invalid,
        ReceiptStatus.expired,
        ReceiptStatus.refunded,
      ]) {
        expect(
          PaymentResult(success: false, receiptStatus: s).isValid,
          isFalse,
          reason: s.toString(),
        );
      }
    });

    test('toString includes success and status', () {
      const r = PaymentResult(
        success: true,
        receiptStatus: ReceiptStatus.valid,
      );
      expect(r.toString(), contains('true'));
      expect(r.toString(), contains('valid'));
    });
  });

  // =========================================================================
  // ValidationResult model
  // =========================================================================
  group('ValidationResult', () {
    test('constructs with defaults', () {
      const v = ValidationResult(status: ReceiptStatus.valid);
      expect(v.status, ReceiptStatus.valid);
      expect(v.expiresAt, isNull);
      expect(v.rawResponse, isEmpty);
    });

    test('constructs with all fields', () {
      final exp = DateTime(2027, 1, 1);
      final v = ValidationResult(
        status: ReceiptStatus.invalid,
        expiresAt: exp,
        rawResponse: {'mock': true},
      );
      expect(v.status, ReceiptStatus.invalid);
      expect(v.expiresAt, exp);
      expect(v.rawResponse['mock'], isTrue);
    });
  });

  // =========================================================================
  // PrivacyService._timeInWindow (quiet hours logic — pure unit tests)
  // =========================================================================
  group('PrivacyService quiet hours — _timeInWindow', () {
    // Access via public API wrapper
    DateTime mkAt(int hour, int minute) => DateTime(2026, 4, 10, hour, minute);

    bool tw(DateTime t, int sh, int sm, int eh, int em) =>
        PrivacyService.testTimeInWindow(t, sh, sm, eh, em);

    test('same-day window: inside', () {
      expect(tw(mkAt(10, 0), 9, 0, 17, 0), isTrue);
    });

    test('same-day window: on start boundary', () {
      expect(tw(mkAt(9, 0), 9, 0, 17, 0), isTrue);
    });

    test('same-day window: at end boundary (exclusive)', () {
      expect(tw(mkAt(17, 0), 9, 0, 17, 0), isFalse);
    });

    test('same-day window: before start', () {
      expect(tw(mkAt(8, 59), 9, 0, 17, 0), isFalse);
    });

    test('same-day window: after end', () {
      expect(tw(mkAt(18, 0), 9, 0, 17, 0), isFalse);
    });

    test('overnight window: during night', () {
      expect(tw(mkAt(23, 0), 22, 0, 7, 0), isTrue);
    });

    test('overnight window: after midnight', () {
      expect(tw(mkAt(3, 0), 22, 0, 7, 0), isTrue);
    });

    test('overnight window: on end boundary (exclusive)', () {
      expect(tw(mkAt(7, 0), 22, 0, 7, 0), isFalse);
    });

    test('overnight window: before start in evening', () {
      expect(tw(mkAt(21, 59), 22, 0, 7, 0), isFalse);
    });

    test('overnight window: after end in morning', () {
      expect(tw(mkAt(8, 0), 22, 0, 7, 0), isFalse);
    });

    test('overnight window: on start boundary', () {
      expect(tw(mkAt(22, 0), 22, 0, 7, 0), isTrue);
    });

    test('minute precision: 22:30 start — 22:29 not in window', () {
      expect(tw(mkAt(22, 29), 22, 30, 7, 0), isFalse);
    });

    test('minute precision: 22:30 start — 22:30 in window', () {
      expect(tw(mkAt(22, 30), 22, 30, 7, 0), isTrue);
    });
  });
}
