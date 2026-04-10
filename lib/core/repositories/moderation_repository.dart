import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/block.dart';
import 'package:bayan/core/models/report.dart';

class ModerationRepository {
  final SupabaseClient _client;

  const ModerationRepository(this._client);

  static const _blocksTable = 'blocks';
  static const _reportsTable = 'reports';

  // -------------------------------------------------------------------------
  // Blocking
  // -------------------------------------------------------------------------

  Future<void> blockUser(String blockerId, String blockedId) async {
    await _client.from(_blocksTable).upsert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    await _client
        .from(_blocksTable)
        .delete()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId);
  }

  Future<bool> isBlocked({
    required String blockerId,
    required String blockedId,
  }) async {
    final data = await _client
        .from(_blocksTable)
        .select('blocker_id')
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId)
        .maybeSingle();
    return data != null;
  }

  /// Returns the list of user IDs that [blockerId] has blocked.
  Future<List<String>> getBlockedIds(String blockerId) async {
    final data = await _client
        .from(_blocksTable)
        .select('blocked_id')
        .eq('blocker_id', blockerId);
    return (data as List).map((r) => r['blocked_id'] as String).toList();
  }

  /// Returns the full Block records for [blockerId].
  Future<List<Block>> getBlocks(String blockerId) async {
    final data = await _client
        .from(_blocksTable)
        .select()
        .eq('blocker_id', blockerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => Block.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns true if [userId] has been blocked by [viewerId] OR has blocked
  /// [viewerId]. Used for mutual-block checks.
  Future<bool> isEitherBlocked({
    required String viewerId,
    required String userId,
  }) async {
    final results = await Future.wait([
      isBlocked(blockerId: viewerId, blockedId: userId),
      isBlocked(blockerId: userId, blockedId: viewerId),
    ]);
    return results[0] || results[1];
  }

  // -------------------------------------------------------------------------
  // Reporting
  // -------------------------------------------------------------------------

  /// Creates a content report. Returns the new [Report] record.
  Future<Report> reportContent({
    required String reporterId,
    required ReportContentType contentType,
    required String contentId,
    required String reason,
    String? description,
  }) async {
    final response = await _client
        .from(_reportsTable)
        .upsert({
          'reporter_id': reporterId,
          'content_type': contentType.name,
          'content_id': contentId,
          'reason': reason,
          'description': description,
        })
        .select()
        .single();
    return Report.fromMap(response);
  }

  Future<List<Report>> getMyReports(String reporterId) async {
    final data = await _client
        .from(_reportsTable)
        .select()
        .eq('reporter_id', reporterId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => Report.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
