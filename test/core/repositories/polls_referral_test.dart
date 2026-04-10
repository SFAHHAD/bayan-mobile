import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/poll.dart';
import 'package:bayan/core/models/poll_option.dart';
import 'package:bayan/core/models/question.dart';
import 'package:bayan/core/models/speaker_queue_entry.dart';
import 'package:bayan/core/models/referral_code.dart';
import 'package:bayan/core/models/message.dart';

// ---------------------------------------------------------------------------
// Unit tests: Poll, PollOption, Question, SpeakerQueueEntry,
//             ReferralCode/ReferralRecord, Message.isEncrypted
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 11, 0);

  // -------------------------------------------------------------------------
  // PollOption model
  // -------------------------------------------------------------------------
  group('PollOption model', () {
    Map<String, dynamic> optMap({int votes = 30}) => {
      'id': 'opt-001',
      'poll_id': 'poll-001',
      'text': 'خيار أول',
      'votes_count': votes,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final o = PollOption.fromMap(optMap());
      expect(o.id, 'opt-001');
      expect(o.pollId, 'poll-001');
      expect(o.text, 'خيار أول');
      expect(o.votesCount, 30);
    });

    test('percentage returns correct value', () {
      final o = PollOption.fromMap(optMap(votes: 25));
      expect(o.percentage(100), closeTo(25.0, 0.001));
    });

    test('percentage returns 50 when half of votes', () {
      final o = PollOption.fromMap(optMap(votes: 1));
      expect(o.percentage(2), closeTo(50.0, 0.001));
    });

    test('percentage returns 0 when totalVotes is 0 (no division by zero)', () {
      final o = PollOption.fromMap(optMap(votes: 0));
      expect(o.percentage(0), 0.0);
    });

    test('percentage returns 0 when option has 0 votes', () {
      final o = PollOption.fromMap(optMap(votes: 0));
      expect(o.percentage(50), 0.0);
    });

    test('percentage returns 100 when option has all votes', () {
      final o = PollOption.fromMap(optMap(votes: 50));
      expect(o.percentage(50), closeTo(100.0, 0.001));
    });

    test('copyWith updates votesCount only', () {
      final o = PollOption.fromMap(optMap());
      final updated = o.copyWith(votesCount: 99);
      expect(updated.votesCount, 99);
      expect(updated.id, o.id);
      expect(updated.text, o.text);
    });

    test('equality by id', () {
      final a = PollOption.fromMap(optMap(votes: 10));
      final b = PollOption.fromMap(optMap(votes: 90));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids are not equal', () {
      final a = PollOption.fromMap(optMap());
      final b = PollOption.fromMap({...optMap(), 'id': 'opt-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // Poll model
  // -------------------------------------------------------------------------
  group('Poll model', () {
    Map<String, dynamic> pollMap({
      String status = 'active',
      int totalVotes = 0,
      List<Map<String, dynamic>>? options,
    }) => {
      'id': 'poll-001',
      'diwan_id': 'diwan-001',
      'host_id': 'user-001',
      'question': 'ما رأيك في الموضوع؟',
      'status': status,
      'total_votes': totalVotes,
      'created_at': now.toIso8601String(),
      'ended_at': null,
      'poll_options': options,
    };

    Map<String, dynamic> optionData(String id, int votes) => {
      'id': id,
      'poll_id': 'poll-001',
      'text': 'خيار $id',
      'votes_count': votes,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all statuses', () {
      for (final entry in {
        'draft': PollStatus.draft,
        'active': PollStatus.active,
        'ended': PollStatus.ended,
      }.entries) {
        final p = Poll.fromMap(pollMap(status: entry.key));
        expect(p.status, entry.value, reason: 'Failed for: ${entry.key}');
      }
    });

    test('isActive returns true only for active status', () {
      expect(Poll.fromMap(pollMap(status: 'active')).isActive, isTrue);
      expect(Poll.fromMap(pollMap(status: 'draft')).isActive, isFalse);
      expect(Poll.fromMap(pollMap(status: 'ended')).isActive, isFalse);
    });

    test('isDraft / isEnded flags', () {
      expect(Poll.fromMap(pollMap(status: 'draft')).isDraft, isTrue);
      expect(Poll.fromMap(pollMap(status: 'ended')).isEnded, isTrue);
    });

    test('winningOption returns null when no votes', () {
      final p = Poll.fromMap(pollMap(totalVotes: 0, options: []));
      expect(p.winningOption, isNull);
    });

    test('winningOption returns option with most votes', () {
      final p = Poll.fromMap(
        pollMap(
          totalVotes: 100,
          options: [
            optionData('opt-a', 20),
            optionData('opt-b', 60),
            optionData('opt-c', 20),
          ],
        ),
      );
      expect(p.winningOption?.id, 'opt-b');
    });

    test('winningOption returns first on tie', () {
      final p = Poll.fromMap(
        pollMap(
          totalVotes: 40,
          options: [optionData('opt-a', 20), optionData('opt-b', 20)],
        ),
      );
      expect(p.winningOption?.id, 'opt-a');
    });

    test('copyWith updates status + totalVotes', () {
      final p = Poll.fromMap(pollMap(status: 'active', totalVotes: 10));
      final ended = p.copyWith(
        status: PollStatus.ended,
        totalVotes: 55,
        endedAt: now,
      );
      expect(ended.status, PollStatus.ended);
      expect(ended.totalVotes, 55);
      expect(ended.endedAt, now);
      expect(ended.id, p.id);
    });

    test('equality by id', () {
      final a = Poll.fromMap(pollMap(status: 'active'));
      final b = Poll.fromMap(pollMap(status: 'ended'));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // Question model
  // -------------------------------------------------------------------------
  group('Question model', () {
    Map<String, dynamic> qMap({
      int upvotes = 5,
      bool isAnswered = false,
      bool isHidden = false,
    }) => {
      'id': 'q-001',
      'diwan_id': 'diwan-001',
      'user_id': 'user-001',
      'text': 'ما هو تعريف الذكاء الاصطناعي؟',
      'upvotes_count': upvotes,
      'is_answered': isAnswered,
      'is_hidden': isHidden,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final q = Question.fromMap(qMap());
      expect(q.upvotesCount, 5);
      expect(q.isAnswered, isFalse);
      expect(q.isHidden, isFalse);
    });

    test('copyWith updates answered status', () {
      final q = Question.fromMap(qMap());
      final answered = q.copyWith(isAnswered: true, upvotesCount: 10);
      expect(answered.isAnswered, isTrue);
      expect(answered.upvotesCount, 10);
      expect(answered.id, q.id);
    });

    test('equality by id', () {
      final a = Question.fromMap(qMap(upvotes: 1));
      final b = Question.fromMap(qMap(upvotes: 999));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // SpeakerQueueEntry model
  // -------------------------------------------------------------------------
  group('SpeakerQueueEntry model', () {
    Map<String, dynamic> qeMap({dynamic score = 42.5}) => {
      'user_id': 'user-001',
      'display_name': 'علي الأحمدي',
      'avatar_url': 'https://example.com/avatar.jpg',
      'prestige_score': score,
      'requested_at': now.toIso8601String(),
    };

    test('fromMap parses double score', () {
      final e = SpeakerQueueEntry.fromMap(qeMap(score: 42.5));
      expect(e.prestigeScore, closeTo(42.5, 0.001));
    });

    test('fromMap parses int score', () {
      final e = SpeakerQueueEntry.fromMap(qeMap(score: 10));
      expect(e.prestigeScore, closeTo(10.0, 0.001));
    });

    test('fromMap parses numeric string score', () {
      final e = SpeakerQueueEntry.fromMap(qeMap(score: '33.7'));
      expect(e.prestigeScore, closeTo(33.7, 0.001));
    });

    test('fromMap defaults to 0.0 for null score', () {
      final e = SpeakerQueueEntry.fromMap(qeMap(score: null));
      expect(e.prestigeScore, 0.0);
    });

    test('avatarUrl is nullable', () {
      final map = Map<String, dynamic>.from(qeMap())..['avatar_url'] = null;
      final e = SpeakerQueueEntry.fromMap(map);
      expect(e.avatarUrl, isNull);
    });

    test('equality by userId', () {
      final a = SpeakerQueueEntry.fromMap(qeMap(score: 10.0));
      final b = SpeakerQueueEntry.fromMap(qeMap(score: 99.0));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // ReferralCode model
  // -------------------------------------------------------------------------
  group('ReferralCode model', () {
    Map<String, dynamic> codeMap() => {
      'id': 'rc-001',
      'user_id': 'user-001',
      'code': 'AB12CD34',
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final rc = ReferralCode.fromMap(codeMap());
      expect(rc.code, 'AB12CD34');
      expect(rc.userId, 'user-001');
    });

    test('shareUrl returns bayan deep-link', () {
      final rc = ReferralCode.fromMap(codeMap());
      expect(rc.shareUrl, 'bayan://referral/AB12CD34');
    });

    test('shareUrlHttps returns HTTPS fallback', () {
      final rc = ReferralCode.fromMap(codeMap());
      expect(rc.shareUrlHttps, 'https://bayan.app/join?ref=AB12CD34');
    });

    test('equality by id', () {
      final a = ReferralCode.fromMap(codeMap());
      final b = ReferralCode.fromMap(codeMap());
      expect(a, equals(b));
    });

    test('different ids not equal', () {
      final a = ReferralCode.fromMap(codeMap());
      final b = ReferralCode.fromMap({...codeMap(), 'id': 'rc-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // ReferralRecord model
  // -------------------------------------------------------------------------
  group('ReferralRecord model', () {
    Map<String, dynamic> recMap({bool rewarded = true, int reward = 50}) => {
      'id': 'rr-001',
      'referrer_id': 'user-001',
      'referred_id': 'user-002',
      'rewarded': rewarded,
      'reward_amount': reward,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final r = ReferralRecord.fromMap(recMap());
      expect(r.rewarded, isTrue);
      expect(r.rewardAmount, 50);
    });

    test('defaults reward_amount to 50 when null', () {
      final map = Map<String, dynamic>.from(recMap())..['reward_amount'] = null;
      final r = ReferralRecord.fromMap(map);
      expect(r.rewardAmount, 50);
    });

    test('equality by id', () {
      final a = ReferralRecord.fromMap(recMap());
      final b = ReferralRecord.fromMap(recMap(reward: 100));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // Message model — isEncrypted (E2E chat)
  // -------------------------------------------------------------------------
  group('Message.isEncrypted field', () {
    Map<String, dynamic> msgMap({bool? isEncrypted}) => {
      'id': 'msg-001',
      'diwan_id': 'diwan-001',
      'sender_id': 'user-001',
      'content': 'مرحباً',
      'type': 'text',
      'sender_name': 'علي',
      'is_encrypted': isEncrypted,
      'created_at': now.toIso8601String(),
    };

    test('defaults to false when is_encrypted absent', () {
      final m = Message.fromMap(msgMap());
      expect(m.isEncrypted, isFalse);
    });

    test('parses is_encrypted = true', () {
      final m = Message.fromMap(msgMap(isEncrypted: true));
      expect(m.isEncrypted, isTrue);
    });

    test('parses is_encrypted = false', () {
      final m = Message.fromMap(msgMap(isEncrypted: false));
      expect(m.isEncrypted, isFalse);
    });

    test('copyWith updates isEncrypted', () {
      final m = Message.fromMap(msgMap(isEncrypted: true));
      final decrypted = m.copyWith(isEncrypted: false, content: 'مرحباً');
      expect(decrypted.isEncrypted, isFalse);
      expect(decrypted.content, 'مرحباً');
    });

    test('toMap includes is_encrypted', () {
      final m = Message.fromMap(msgMap(isEncrypted: true));
      expect(m.toMap()['is_encrypted'], isTrue);
    });
  });
}
