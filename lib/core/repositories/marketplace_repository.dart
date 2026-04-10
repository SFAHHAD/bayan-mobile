import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/ticket.dart';
import 'package:bayan/core/models/diwan_report.dart';

enum PurchaseResult {
  success,
  alreadyPurchased,
  insufficientBalance,
  notPremium,
  hostCannotBuy,
  diwanNotFound,
  unknown,
}

class MarketplaceRepository {
  final SupabaseClient _client;

  const MarketplaceRepository(this._client);

  static const _ticketsTable = 'tickets';

  // -------------------------------------------------------------------------
  // Access check
  // -------------------------------------------------------------------------

  /// Returns true if the current user can enter [diwanId]
  /// (free diwan, or owns a ticket, or is the host).
  Future<bool> checkAccess(String diwanId) async {
    final result =
        await _client.rpc('check_diwan_access', params: {'p_diwan_id': diwanId})
            as bool;
    return result;
  }

  // -------------------------------------------------------------------------
  // Purchase
  // -------------------------------------------------------------------------

  /// Atomically purchases a ticket for [diwanId].
  /// Deducts tokens from buyer, credits host (net of 10% fee), issues ticket.
  Future<PurchaseResult> purchaseTicket(String diwanId) async {
    final result =
        await _client.rpc('purchase_ticket', params: {'p_diwan_id': diwanId})
            as Map<String, dynamic>;

    if (result['success'] == true) {
      final reason = result['reason'] as String?;
      if (reason == 'already_purchased') return PurchaseResult.alreadyPurchased;
      return PurchaseResult.success;
    }

    final reason = result['reason'] as String? ?? '';
    switch (reason) {
      case 'insufficient_balance':
        return PurchaseResult.insufficientBalance;
      case 'not_a_premium_diwan':
        return PurchaseResult.notPremium;
      case 'host_cannot_buy_own_ticket':
        return PurchaseResult.hostCannotBuy;
      case 'diwan_not_found':
        return PurchaseResult.diwanNotFound;
      default:
        return PurchaseResult.unknown;
    }
  }

  // -------------------------------------------------------------------------
  // Ticket queries
  // -------------------------------------------------------------------------

  Future<Ticket?> getMyTicket(String diwanId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from(_ticketsTable)
        .select()
        .eq('user_id', userId)
        .eq('diwan_id', diwanId)
        .maybeSingle();
    if (data == null) return null;
    return Ticket.fromMap(data);
  }

  Future<List<Ticket>> getMyTickets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from(_ticketsTable)
        .select()
        .eq('user_id', userId)
        .order('purchased_at', ascending: false);
    return (data as List)
        .map((r) => Ticket.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns all tickets sold for a diwan the caller hosts.
  Future<List<Ticket>> getDiwanTicketsSold(String diwanId) async {
    final data = await _client
        .from(_ticketsTable)
        .select()
        .eq('diwan_id', diwanId)
        .order('purchased_at', ascending: false);
    return (data as List)
        .map((r) => Ticket.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Premium diwan management (host)
  // -------------------------------------------------------------------------

  /// Sets [diwanId] as premium with [entryFee] tokens.
  Future<void> setPremium({
    required String diwanId,
    required int entryFee,
  }) async {
    await _client
        .from('diwans')
        .update({'is_premium': true, 'entry_fee': entryFee})
        .eq('id', diwanId);
  }

  /// Removes premium status from [diwanId].
  Future<void> removePremium(String diwanId) async {
    await _client
        .from('diwans')
        .update({'is_premium': false, 'entry_fee': 0})
        .eq('id', diwanId);
  }

  // -------------------------------------------------------------------------
  // Analytics report (via Edge Function)
  // -------------------------------------------------------------------------

  /// Calls the `generate-diwan-report` Edge Function and returns a typed
  /// [DiwanReport].
  Future<DiwanReport> generateReport(String diwanId) async {
    final result = await _client.functions.invoke(
      'generate-diwan-report',
      body: {'diwan_id': diwanId},
    );
    if (result.status != 200) {
      throw Exception('Failed to generate diwan report: ${result.status}');
    }
    return DiwanReport.fromMap(result.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Content moderation (AI Guard)
  // -------------------------------------------------------------------------

  /// Calls the `content-moderator` Edge Function for the given Diwan.
  /// Returns the moderation verdict map.
  Future<Map<String, dynamic>> moderateContent({
    required String diwanId,
    required String title,
    String? description,
  }) async {
    final result = await _client.functions.invoke(
      'content-moderator',
      body: {'diwan_id': diwanId, 'title': title, 'description': description},
    );
    if (result.status != 200) {
      throw Exception('Content moderation failed: ${result.status}');
    }
    return result.data as Map<String, dynamic>;
  }

  // -------------------------------------------------------------------------
  // Realtime
  // -------------------------------------------------------------------------

  /// Streams tickets sold for [diwanId] (for host dashboard live updates).
  Stream<List<Ticket>> watchDiwanTickets(String diwanId) {
    return _client
        .from(_ticketsTable)
        .stream(primaryKey: ['id'])
        .order('purchased_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) => r['diwan_id'] == diwanId)
              .map(Ticket.fromMap)
              .toList(),
        );
  }
}
