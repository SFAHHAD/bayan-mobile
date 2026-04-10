import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/wallet.dart';
import 'package:bayan/core/models/wallet_transaction.dart';
import 'package:bayan/core/models/scheduled_diwan.dart';
import 'package:bayan/core/models/diwan_summary.dart';

// ---------------------------------------------------------------------------
// Unit tests: Wallet, WalletTransaction, ScheduledDiwan, DiwanSummary models
// ---------------------------------------------------------------------------
void main() {
  final now = DateTime(2026, 4, 10, 11, 0);

  // -------------------------------------------------------------------------
  // Wallet model
  // -------------------------------------------------------------------------
  group('Wallet model', () {
    Map<String, dynamic> walletMap({int balance = 250}) => {
      'id': 'wallet-001',
      'user_id': 'user-001',
      'balance': balance,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final w = Wallet.fromMap(walletMap());
      expect(w.id, 'wallet-001');
      expect(w.userId, 'user-001');
      expect(w.balance, 250);
    });

    test('fromMap defaults balance to 0 when null', () {
      final map = Map<String, dynamic>.from(walletMap())..['balance'] = null;
      final w = Wallet.fromMap(map);
      expect(w.balance, 0);
    });

    test('copyWith updates balance only', () {
      final original = Wallet.fromMap(walletMap(balance: 100));
      final updated = original.copyWith(balance: 350);
      expect(updated.balance, 350);
      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
    });

    test('equality by id', () {
      final a = Wallet.fromMap(walletMap());
      final b = Wallet.fromMap(walletMap(balance: 999));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids are not equal', () {
      final a = Wallet.fromMap(walletMap());
      final b = Wallet.fromMap({...walletMap(), 'id': 'wallet-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // WalletTransaction model
  // -------------------------------------------------------------------------
  group('WalletTransaction model', () {
    Map<String, dynamic> txnMap({
      String type = 'gift_received',
      int amount = 50,
      int balanceAfter = 300,
      String? giftType,
    }) => {
      'id': 'txn-001',
      'wallet_id': 'wallet-001',
      'user_id': 'user-001',
      'type': type,
      'amount': amount,
      'balance_after': balanceAfter,
      'ref_diwan_id': 'diwan-001',
      'ref_user_id': 'user-002',
      'metadata': giftType != null
          ? {'gift_type': giftType}
          : <String, dynamic>{},
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses gift_received', () {
      final t = WalletTransaction.fromMap(txnMap());
      expect(t.type, WalletTransactionType.giftReceived);
      expect(t.amount, 50);
      expect(t.balanceAfter, 300);
      expect(t.isCredit, isTrue);
    });

    test('fromMap parses gift_sent (negative amount)', () {
      final t = WalletTransaction.fromMap(
        txnMap(type: 'gift_sent', amount: -50),
      );
      expect(t.type, WalletTransactionType.giftSent);
      expect(t.isCredit, isFalse);
    });

    test('fromMap parses all transaction types', () {
      for (final entry in {
        'gift_sent': WalletTransactionType.giftSent,
        'gift_received': WalletTransactionType.giftReceived,
        'purchase': WalletTransactionType.purchase,
        'bonus': WalletTransactionType.bonus,
        'withdrawal': WalletTransactionType.withdrawal,
      }.entries) {
        final t = WalletTransaction.fromMap(txnMap(type: entry.key));
        expect(t.type, entry.value, reason: 'Failed for type: ${entry.key}');
      }
    });

    test('unknown type defaults to bonus', () {
      final t = WalletTransaction.fromMap({...txnMap(), 'type': 'airdrop'});
      expect(t.type, WalletTransactionType.bonus);
    });

    test('giftType accessor reads from metadata', () {
      final t = WalletTransaction.fromMap(txnMap(giftType: 'rose'));
      expect(t.giftType, 'rose');
    });

    test('giftType is null when metadata is empty', () {
      final t = WalletTransaction.fromMap(txnMap());
      expect(t.giftType, isNull);
    });

    test('equality by id', () {
      final a = WalletTransaction.fromMap(txnMap());
      final b = WalletTransaction.fromMap(txnMap());
      expect(a, equals(b));
    });

    test('ref fields are nullable', () {
      final map = Map<String, dynamic>.from(txnMap())
        ..['ref_diwan_id'] = null
        ..['ref_user_id'] = null;
      final t = WalletTransaction.fromMap(map);
      expect(t.refDiwanId, isNull);
      expect(t.refUserId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // ScheduledDiwan model
  // -------------------------------------------------------------------------
  group('ScheduledDiwan model', () {
    final future = DateTime.now().add(const Duration(hours: 2));

    Map<String, dynamic> schedMap({
      bool reminderSent = false,
      bool isCancelled = false,
      int duration = 60,
    }) => {
      'id': 'sched-001',
      'diwan_id': 'diwan-001',
      'host_id': 'user-001',
      'start_time': future.toIso8601String(),
      'estimated_duration_minutes': duration,
      'reminder_sent': reminderSent,
      'is_cancelled': isCancelled,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final s = ScheduledDiwan.fromMap(schedMap());
      expect(s.startTime, future);
      expect(s.estimatedDurationMinutes, 60);
      expect(s.reminderSent, isFalse);
      expect(s.isCancelled, isFalse);
    });

    test('isUpcoming returns true for future non-cancelled schedule', () {
      final s = ScheduledDiwan.fromMap(schedMap());
      expect(s.isUpcoming, isTrue);
    });

    test('isUpcoming returns false for cancelled schedule', () {
      final s = ScheduledDiwan.fromMap(schedMap(isCancelled: true));
      expect(s.isUpcoming, isFalse);
    });

    test('minutesUntilStart is positive for future schedule', () {
      final s = ScheduledDiwan.fromMap(schedMap());
      expect(s.minutesUntilStart, greaterThan(0));
    });

    test('toMap includes required fields only', () {
      final s = ScheduledDiwan.fromMap(schedMap());
      final map = s.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['diwan_id'], 'diwan-001');
      expect(map['host_id'], 'user-001');
      expect(map['estimated_duration_minutes'], 60);
    });

    test('copyWith updates isCancelled', () {
      final s = ScheduledDiwan.fromMap(schedMap());
      final cancelled = s.copyWith(isCancelled: true);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.id, s.id);
    });

    test('equality by id', () {
      final a = ScheduledDiwan.fromMap(schedMap());
      final b = ScheduledDiwan.fromMap(schedMap(duration: 90));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // DiwanSummary model
  // -------------------------------------------------------------------------
  group('DiwanSummary model', () {
    Map<String, dynamic> summaryMap({String status = 'done'}) => {
      'id': 'sum-001',
      'diwan_id': 'diwan-001',
      'transcript': null,
      'summary': 'تناولت الجلسة موضوع الذكاء الاصطناعي.',
      'key_points': ['نقطة أولى', 'نقطة ثانية'],
      'status': status,
      'generated_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final s = DiwanSummary.fromMap(summaryMap());
      expect(s.status, SummaryStatus.done);
      expect(s.summary, isNotNull);
      expect(s.keyPoints, hasLength(2));
    });

    test('fromMap parses all statuses', () {
      for (final entry in {
        'pending': SummaryStatus.pending,
        'processing': SummaryStatus.processing,
        'done': SummaryStatus.done,
        'failed': SummaryStatus.failed,
      }.entries) {
        final s = DiwanSummary.fromMap(summaryMap(status: entry.key));
        expect(s.status, entry.value, reason: 'Failed for: ${entry.key}');
      }
    });

    test('isReady is true only when done and summary is non-null', () {
      expect(DiwanSummary.fromMap(summaryMap(status: 'done')).isReady, isTrue);
      expect(
        DiwanSummary.fromMap(summaryMap(status: 'pending')).isReady,
        isFalse,
      );
      expect(
        DiwanSummary.fromMap(summaryMap(status: 'processing')).isReady,
        isFalse,
      );
      expect(
        DiwanSummary.fromMap(summaryMap(status: 'failed')).isReady,
        isFalse,
      );
    });

    test('empty key_points handled gracefully', () {
      final map = {...summaryMap(), 'key_points': <dynamic>[]};
      final s = DiwanSummary.fromMap(map);
      expect(s.keyPoints, isEmpty);
    });

    test('null key_points field handled gracefully', () {
      final map = Map<String, dynamic>.from(summaryMap())
        ..['key_points'] = null;
      final s = DiwanSummary.fromMap(map);
      expect(s.keyPoints, isEmpty);
    });

    test('equality by id', () {
      final a = DiwanSummary.fromMap(summaryMap());
      final b = DiwanSummary.fromMap(summaryMap(status: 'pending'));
      expect(a, equals(b));
    });
  });
}
