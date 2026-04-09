abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(Map<String, dynamic> data);
  Future<T> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
