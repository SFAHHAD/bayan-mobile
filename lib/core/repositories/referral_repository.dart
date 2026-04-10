import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/referral_code.dart';

class ReferralRepository {
  final SupabaseClient _client;

  const ReferralRepository(this._client);

  static const _codeTable = 'referral_codes';
  static const _referralTable = 'referrals';

  // -------------------------------------------------------------------------
  // Code management
  // -------------------------------------------------------------------------

  /// Returns the caller's referral code, creating one if it doesn't exist.
  Future<String> getOrCreateCode() async {
    final result = await _client.rpc('get_or_create_referral_code') as String;
    return result;
  }

  /// Fetches the full [ReferralCode] record for [userId].
  Future<ReferralCode?> getCode(String userId) async {
    final data = await _client
        .from(_codeTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ReferralCode.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Process referral
  // -------------------------------------------------------------------------

  /// Processes a referral after a new user signs up with [referrerCode].
  /// Returns `true` on success (first-time referral, code valid).
  Future<bool> processReferral(String referrerCode) async {
    final result =
        await _client.rpc(
              'process_referral',
              params: {'p_referrer_code': referrerCode},
            )
            as Map<String, dynamic>;
    return result['success'] == true;
  }

  // -------------------------------------------------------------------------
  // Stats
  // -------------------------------------------------------------------------

  /// Returns all referral records where [userId] is the referrer.
  Future<List<ReferralRecord>> getReferralsMade(String userId) async {
    final data = await _client
        .from(_referralTable)
        .select()
        .eq('referrer_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => ReferralRecord.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns total tokens earned from referrals for [userId].
  Future<int> totalTokensEarned(String userId) async {
    final data = await _client
        .from(_referralTable)
        .select('reward_amount')
        .eq('referrer_id', userId)
        .eq('rewarded', true);
    return (data as List).fold<int>(
      0,
      (sum, r) => sum + ((r['reward_amount'] as int?) ?? 0),
    );
  }

  // -------------------------------------------------------------------------
  // Edge Function — referral share card
  // -------------------------------------------------------------------------

  /// Calls the `generate-referral-card` Edge Function and returns the JSON
  /// payload (`svg`, `qr_data_url`, `referral_url`, `referral_code`).
  Future<Map<String, dynamic>> generateShareCard() async {
    final result = await _client.functions.invoke('generate-referral-card');
    if (result.status != 200) {
      throw Exception('Failed to generate referral card');
    }
    return result.data as Map<String, dynamic>;
  }
}
