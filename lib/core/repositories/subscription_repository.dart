import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/purchase_receipt.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/models/user_subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  const SubscriptionRepository(this._client);

  static const _tiersTable = 'subscription_tiers';
  static const _subsTable = 'user_subscriptions';

  // -------------------------------------------------------------------------
  // Tiers
  // -------------------------------------------------------------------------

  Future<List<SubscriptionTier>> fetchTiers() async {
    final data = await _client
        .from(_tiersTable)
        .select()
        .eq('is_active', true)
        .order('price_tokens');
    return (data as List)
        .map((r) => SubscriptionTier.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionTier?> fetchTierByType(TierType type) async {
    final data = await _client
        .from(_tiersTable)
        .select()
        .eq('type', SubscriptionTier.typeToString(type))
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;
    return SubscriptionTier.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // User subscriptions
  // -------------------------------------------------------------------------

  Future<List<UserSubscription>> fetchMySubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_subsTable)
        .select('''
          *,
          subscription_tiers(type, name)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((r) {
      final row = Map<String, dynamic>.from(r as Map);
      final tier = row['subscription_tiers'];
      if (tier is Map) {
        row['tier_type'] = tier['type'];
        row['tier_name'] = tier['name'];
      }
      return UserSubscription.fromMap(row);
    }).toList();
  }

  Future<UserSubscription?> fetchActiveSubscription() async {
    final subs = await fetchMySubscriptions();
    return subs.where((s) => s.isActive).fold<UserSubscription?>(null, (
      best,
      s,
    ) {
      if (best == null) return s;
      final bestRank = best.tierType == null
          ? 0
          : SubscriptionTier.tierRank(best.tierType!);
      final sRank = s.tierType == null
          ? 0
          : SubscriptionTier.tierRank(s.tierType!);
      return sRank > bestRank ? s : best;
    });
  }

  Stream<List<UserSubscription>> watchMySubscriptions() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from(_subsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(UserSubscription.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // Subscribe / Cancel
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> subscribeTo(TierType tier) async {
    final raw = await _client.rpc(
      'subscribe_to_tier',
      params: {'p_tier_type': SubscriptionTier.typeToString(tier)},
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<bool> cancel(TierType tier) async {
    final raw = await _client.rpc(
      'cancel_subscription',
      params: {'p_tier_type': SubscriptionTier.typeToString(tier)},
    );
    return (raw as bool?) ?? false;
  }

  // -------------------------------------------------------------------------
  // Access guard
  // -------------------------------------------------------------------------

  /// Returns true if the current user's active subscription meets [required].
  Future<bool> checkAccess(TierType required) async {
    final raw = await _client.rpc(
      'check_subscription_access',
      params: {'p_required_tier': SubscriptionTier.typeToString(required)},
    );
    return (raw as bool?) ?? false;
  }

  /// Fast local check — use after loading subscriptions into state.
  bool hasAccessLocally(
    List<UserSubscription> subscriptions,
    TierType required,
  ) {
    return subscriptions.any((s) => s.grantsAccessTo(required));
  }

  // -------------------------------------------------------------------------
  // IAP receipt-based activation (called by PaymentService after validation)
  // -------------------------------------------------------------------------

  /// Activates a subscription only after a server-verified receipt.
  /// [receiptId] must exist in purchase_receipts with status='valid'.
  Future<Map<String, dynamic>> activateViaReceipt({
    required String receiptId,
    required TierType tier,
    DateTime? expiresAt,
  }) async {
    final raw = await _client.rpc(
      'activate_subscription_from_receipt',
      params: {
        'p_receipt_id': receiptId,
        'p_tier_type': SubscriptionTier.typeToString(tier),
        'p_expires_at': expiresAt?.toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  // -------------------------------------------------------------------------
  // Purchase receipt CRUD
  // -------------------------------------------------------------------------

  static const _receiptsTable = 'purchase_receipts';

  Future<PurchaseReceipt> createReceipt({
    required ReceiptPlatform platform,
    required String productId,
    required String receiptData,
    String? transactionId,
    TierType? tierType,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from(_receiptsTable)
        .insert({
          'user_id': userId,
          'platform': PurchaseReceipt.platformToString(platform),
          'product_id': productId,
          'receipt_data': receiptData,
          'transaction_id': transactionId,
          'tier_type': tierType == null
              ? null
              : SubscriptionTier.typeToString(tierType),
        })
        .select()
        .single();
    return PurchaseReceipt.fromMap(data);
  }

  Future<PurchaseReceipt?> fetchReceipt(String receiptId) async {
    final data = await _client
        .from(_receiptsTable)
        .select()
        .eq('id', receiptId)
        .maybeSingle();
    if (data == null) return null;
    return PurchaseReceipt.fromMap(data);
  }

  Future<List<PurchaseReceipt>> fetchMyReceipts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_receiptsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => PurchaseReceipt.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateReceiptStatus(
    String receiptId,
    ReceiptStatus status, {
    Map<String, dynamic>? rawResponse,
  }) async {
    await _client
        .from(_receiptsTable)
        .update({
          'status': PurchaseReceipt.statusToString(status),
          'validated_at': DateTime.now().toIso8601String(),
          'raw_response': rawResponse,
        })
        .eq('id', receiptId);
  }
}
