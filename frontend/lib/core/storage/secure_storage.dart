import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _newUserKey = 'is_new_user';
  static const _userIdKey = 'user_id';

  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  const SecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> setNewUser() async {
    await _storage.write(key: _newUserKey, value: 'true');
  }

  Future<bool> isNewUser() async {
    return await _storage.read(key: _newUserKey) == 'true';
  }

  Future<void> clearNewUser() async {
    await _storage.delete(key: _newUserKey);
  }

  Future<void> saveUserId(int id) async {
    await _storage.write(key: _userIdKey, value: id.toString());
  }

  Future<int?> getUserId() async {
    final v = await _storage.read(key: _userIdKey);
    return v != null ? int.tryParse(v) : null;
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }
}
