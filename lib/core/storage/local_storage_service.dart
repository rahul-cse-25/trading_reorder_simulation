/// [LocalStorageService] provides an abstraction for local data persistence.
/// Following DIP (Dependency Inversion Principle), the business logic depends
/// on this interface rather than a concrete implementation like SharedPreferences.
abstract class LocalStorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);

  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);

  Future<void> saveStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);

  Future<void> remove(String key);
  Future<void> clear();
}
