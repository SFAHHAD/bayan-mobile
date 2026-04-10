import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/models/tag.dart';

class TagRepository {
  final SupabaseClient _client;

  const TagRepository(this._client);

  static const _tagsTable = 'tags';
  static const _diwanTagsTable = 'diwan_tags';

  // -------------------------------------------------------------------------
  // Tags
  // -------------------------------------------------------------------------

  Future<List<Tag>> fetchAll() async {
    final data = await _client
        .from(_tagsTable)
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((r) => Tag.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<Tag?> getBySlug(String slug) async {
    final data = await _client
        .from(_tagsTable)
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (data == null) return null;
    return Tag.fromMap(data);
  }

  Future<List<Tag>> getTagsForDiwan(String diwanId) async {
    final data = await _client
        .from(_diwanTagsTable)
        .select('tags(*)')
        .eq('diwan_id', diwanId);
    return (data as List)
        .map((r) => Tag.fromMap(r['tags'] as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Diwans by tag
  // -------------------------------------------------------------------------

  Future<List<Diwan>> getDiwansByTag(String tagSlug) async {
    final tag = await getBySlug(tagSlug);
    if (tag == null) return [];

    final data = await _client
        .from(_diwanTagsTable)
        .select('diwans(*)')
        .eq('tag_id', tag.id);
    return (data as List)
        .map((r) => Diwan.fromMap(r['diwans'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Diwan>> getDiwansByTagId(String tagId) async {
    final data = await _client
        .from(_diwanTagsTable)
        .select('diwans(*)')
        .eq('tag_id', tagId);
    return (data as List)
        .map((r) => Diwan.fromMap(r['diwans'] as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Tagging
  // -------------------------------------------------------------------------

  Future<void> tagDiwan(String diwanId, String tagId) async {
    await _client.from(_diwanTagsTable).upsert({
      'diwan_id': diwanId,
      'tag_id': tagId,
    });
  }

  Future<void> untagDiwan(String diwanId, String tagId) async {
    await _client
        .from(_diwanTagsTable)
        .delete()
        .eq('diwan_id', diwanId)
        .eq('tag_id', tagId);
  }

  Future<void> setTagsForDiwan(String diwanId, List<String> tagIds) async {
    await _client.from(_diwanTagsTable).delete().eq('diwan_id', diwanId);
    if (tagIds.isEmpty) return;
    await _client
        .from(_diwanTagsTable)
        .insert(
          tagIds.map((tid) => {'diwan_id': diwanId, 'tag_id': tid}).toList(),
        );
  }
}
