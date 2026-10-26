import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_user.dart';

class AuthApiException implements Exception {
  final String code;
  final int? statusCode;

  const AuthApiException(this.code, {this.statusCode});

  @override
  String toString() => code;
}

class AuthLoginResult {
  final String token;
  final AuthUser user;

  const AuthLoginResult({required this.token, required this.user});
}

class AuthApiService {
  final String baseUrl;
  final http.Client _client;

  AuthApiService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$normalizedBase$path');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final body = _decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw AuthApiException(_errorCode(body), statusCode: response.statusCode);
  }

  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final body = _decode(response.body);

    if (response.statusCode != 200) {
      throw AuthApiException(_errorCode(body), statusCode: response.statusCode);
    }

    final token = body['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const AuthApiException('INVALID_AUTH_RESPONSE');
    }

    final userJson = body['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const AuthApiException('INVALID_AUTH_RESPONSE');
    }

    return AuthLoginResult(token: token, user: AuthUser.fromJson(userJson));
  }

  Future<AuthUser> me(String token) async {
    final response = await _client.get(
      _uri('/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = _decode(response.body);

    if (response.statusCode != 200) {
      throw AuthApiException(_errorCode(body), statusCode: response.statusCode);
    }

    final userJson = body['user'] ?? body;

    if (userJson is! Map<String, dynamic>) {
      throw const AuthApiException('INVALID_AUTH_RESPONSE');
    }

    return AuthUser.fromJson(userJson);
  }

  Future<void> reenviarVerificacao(String email) async {
    final response = await _client.post(
      _uri('/api/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;

    final body = _decode(response.body);

    throw AuthApiException(_errorCode(body), statusCode: response.statusCode);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) return decoded;

      return {};
    } catch (_) {
      return {};
    }
  }

  String _errorCode(Map<String, dynamic> body) {
    return body['error']?.toString() ??
        body['code']?.toString() ??
        body['message']?.toString() ??
        'UNKNOWN_ERROR';
  }

  void dispose() {
    _client.close();
  }
}
