import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/repositories/base_repository.dart';

class MessageRepository implements BaseRepository<Message> {
  final SupabaseClient _client;

  const MessageRepository(this._client);

  static const _table = 'messages';

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
