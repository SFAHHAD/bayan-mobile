import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/wallet.dart';
import 'package:bayan/core/models/wallet_transaction.dart';

class WalletRepository {
  final SupabaseClient _client;

  const WalletRepository(this._client);

  static const _walletTable = 'wallets';
  static const _txnTable = 'wallet_transactions';

  // -------------------------------------------------------------------------
  // Wallet
  // -------------------------------------------------------------------------

  Future<Wallet?> getWallet(String userId) async {
    final data = await _client
        .from(_walletTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Wallet.fromMap(data);
  }

  /// Real-time stream of the user's wallet (balance updates instantly).
  Stream<Wallet?> watchWallet(String userId) {
    return _client
        .from(_walletTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.isEmpty ? null : Wallet.fromMap(rows.first));
  }

  // -------------------------------------------------------------------------
  // Gifting
  // -------------------------------------------------------------------------

  /// Sends [amount] tokens from [giverId] to [recipientId] during a live
  /// session in [diwanId]. Runs atomically via the `send_gift` RPC.
  ///
  /// Returns the updated giver balance on success.
  Future<int> sendGift({
    required String giverId,
    required String recipientId,
    required String diwanId,
    required int amount,
    String giftType = 'token',
  }) async {
    final result =
        await _client.rpc(
              'send_gift',
              params: {
                'p_giver_id': giverId,
                'p_recipient_id': recipientId,
                'p_diwan_id': diwanId,
                'p_amount': amount,
                'p_gift_type': giftType,
              },
            )
            as Map<String, dynamic>;

    return (result['giver_balance'] as int?) ?? 0;
  }

  // -------------------------------------------------------------------------
  // Daily bonus
  // -------------------------------------------------------------------------

  /// Claims the daily 10-token bonus (idempotent per day).
  Future<Map<String, dynamic>> claimDailyBonus(String userId) async {
    final result =
        await _client.rpc('claim_daily_bonus', params: {'p_user_id': userId})
            as Map<String, dynamic>;
    return result;
  }

  // -------------------------------------------------------------------------
  // Transaction history (cursor-based pagination)
  // -------------------------------------------------------------------------

  Future<List<WalletTransaction>> getTransactionHistory(
    String userId, {
    DateTime? before,
    int limit = 20,
  }) async {
    var query = _client.from(_txnTable).select().eq('user_id', userId);
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((r) => WalletTransaction.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Real-time stream of the most-recent 50 transactions for [userId].
  /// Used to show live gift events on stage.
  Stream<List<WalletTransaction>> watchRecentGifts(String userId) {
    return _client
        .from(_txnTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .where(
                (r) =>
                    r['user_id'] == userId &&
                    (r['type'] == 'gift_received' || r['type'] == 'gift_sent'),
              )
              .take(50)
              .map(WalletTransaction.fromMap)
              .toList(),
        );
  }
}
