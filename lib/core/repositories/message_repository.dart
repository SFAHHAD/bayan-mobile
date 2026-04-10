import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/repositories/base_repository.dart';

class MessageRepository implements BaseRepository<Message> {
  final SupabaseClient _client;

  const MessageRepository(this._client);

  static const _table = 'messages';
  static const _defaultPageSize = 30;

  @override
  Future<List<Message>> getAll() async {
    final data = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return data.map(Message.fromMap).toList();
  }

  Future<List<Message>> getByDiwan(String diwanId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('diwan_id', diwanId)
        .order('created_at', ascending: true);
    return data.map(Message.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Cursor-based pagination (load history before a given timestamp)
  // -------------------------------------------------------------------------

  Future<List<Message>> getPagedMessages(
    String diwanId, {
    DateTime? before,
    int limit = _defaultPageSize,
  }) async {
    var query = _client.from(_table).select().eq('diwan_id', diwanId);
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((r) => Message.fromMap(r as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  // -------------------------------------------------------------------------
  // Send messages
  // -------------------------------------------------------------------------

  Future<Message> sendMessage({
    required String diwanId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final response = await _client
        .from(_table)
        .insert({
          'diwan_id': diwanId,
          'sender_id': senderId,
          'sender_name': senderName,
          'content': content,
          'type': 'text',
        })
        .select()
        .single();
    return Message.fromMap(response);
  }

  /// Posts a system message (e.g. 'Room is now live').
  /// Uses Supabase service_role via an RPC to bypass RLS.
  Future<void> postSystemMessage(String diwanId, String content) async {
    await _client.rpc(
      '_post_system_message',
      params: {'p_diwan_id': diwanId, 'p_content': content},
    );
  }

  // -------------------------------------------------------------------------
  // Real-time stream
  // -------------------------------------------------------------------------

  /// Emits a new full list whenever a message is inserted / updated / deleted
  /// in [diwanId]'s chat. Uses Supabase Realtime.
  Stream<List<Message>> watchMessages(String diwanId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) => rows
              .where((r) => r['diwan_id'] == diwanId)
              .map(Message.fromMap)
              .toList(),
        );
  }

  Future<List<Message>> getBySender(String senderId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('sender_id', senderId)
        .order('created_at', ascending: false);
    return data.map(Message.fromMap).toList();
  }

  @override
  Future<Message?> getById(String id) async {
    final data = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Message.fromMap(data);
  }

  @override
  Future<Message> create(Map<String, dynamic> data) async {
    final response = await _client.from(_table).insert(data).select().single();
    return Message.fromMap(response);
  }

  @override
  Future<Message> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Message.fromMap(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
