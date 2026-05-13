import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  //static const _storage = FlutterSecureStorage();

  static final _storage = FlutterSecureStorage();

  // Keys — define them as constants to avoid typos
  static const _tokenKey = 'auth_token';
  static const _idKey = "id";
  static const _nameKey = 'username';

  // Save after login
  static Future<void> saveSession({
    required String token,
    required int id,
    required String username,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _idKey, value: id.toString());
    // id should be saved as string and when returned , returned parsed into int
    await _storage.write(key: _nameKey, value: username);
  }

  // Read token to attach to requests
  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<int?> getId() async {
    final idAsString = await _storage.read(key: _idKey);
    return idAsString != null ? int.parse(idAsString) : null;
  }

  static Future<String?> getUsername() => _storage.read(key: _nameKey);

  // Call on logout — clears everything
  static Future<void> clearSession() => _storage.deleteAll();
}
