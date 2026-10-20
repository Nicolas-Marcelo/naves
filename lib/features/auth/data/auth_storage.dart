import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey =
      'navescence_auth_token';

  final FlutterSecureStorage _storage;

  const AuthStorage({
    this._storage =
        const FlutterSecureStorage(),
  });

  Future<void> salvarToken(
    String token,
  ) {
    return _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> obterToken() {
    return _storage.read(
      key: _tokenKey,
    );
  }

  Future<void> removerToken() {
    return _storage.delete(
      key: _tokenKey,
    );
  }

  Future<bool> possuiToken() async {
    final token =
        await obterToken();

    return token != null &&
        token.isNotEmpty;
  }
}