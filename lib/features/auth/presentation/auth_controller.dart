import 'package:flutter/foundation.dart';

import '../data/auth_api_service.dart';
import '../data/auth_storage.dart';
import '../domain/auth_user.dart';

enum AuthStatus {
  inicializando,
  autenticado,
  naoAutenticado,
}

class AuthController extends ChangeNotifier {
  final AuthApiService api;
  final AuthStorage storage;

  AuthStatus _status = AuthStatus.inicializando;
  AuthUser? _user;
  String? _token;
  String? _erro;
  bool _carregando = false;

  AuthController({
    required this.api,
    required this.storage,
  });

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get erro => _erro;
  bool get carregando => _carregando;

  bool get autenticado {
    return _status == AuthStatus.autenticado &&
        _token != null &&
        _user != null;
  }

  Future<void> iniciar() async {
    _status = AuthStatus.inicializando;
    _erro = null;
    notifyListeners();

    try {
      final token = await storage.obterToken();

      if (token == null || token.isEmpty) {
        _limparSessaoLocal();
        return;
      }

      final user = await api.me(token);

      _token = token;
      _user = user;
      _status = AuthStatus.autenticado;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await storage.removerToken();
      }

      _limparSessaoLocal();
    } catch (_) {
      _limparSessaoLocal();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_carregando) return false;

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final result = await api.login(
        email: email,
        password: password,
      );

      await storage.salvarToken(result.token);

      _token = result.token;
      _user = result.user;
      _status = AuthStatus.autenticado;

      return true;
    } on AuthApiException catch (error) {
      _erro = _mensagemErro(error.code);
      return false;
    } catch (_) {
      _erro = 'Não foi possível conectar ao sistema.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_carregando) return false;

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await api.register(
        name: name,
        email: email,
        password: password,
      );

      return true;
    } on AuthApiException catch (error) {
      _erro = _mensagemErro(error.code);
      return false;
    } catch (_) {
      _erro = 'Não foi possível realizar o cadastro.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> reenviarVerificacao(String email) async {
    if (_carregando) return false;

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await api.reenviarVerificacao(email);
      return true;
    } on AuthApiException catch (error) {
      _erro = _mensagemErro(error.code);
      return false;
    } catch (_) {
      _erro = 'Não foi possível reenviar a verificação.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await storage.removerToken();

    _token = null;
    _user = null;
    _erro = null;
    _status = AuthStatus.naoAutenticado;

    notifyListeners();
  }

  Future<bool> atualizarUsuario() async {
    final token = _token;
    if (token == null) return false;

    try {
      _user = await api.me(token);
      notifyListeners();
      return true;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await logout();
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void limparErro() {
    if (_erro == null) return;

    _erro = null;
    notifyListeners();
  }

  String _mensagemErro(String code) {
    switch (code) {
      case 'EMAIL_IN_USE':
        return 'Este e-mail já está cadastrado.';

      case 'EMAIL_NOT_VERIFIED':
        return 'Confirme seu e-mail antes de entrar.';

      case 'INVALID_CREDENTIALS':
      case 'INVALID_EMAIL_OR_PASSWORD':
        return 'E-mail ou senha incorretos.';

      case 'USER_BLOCKED':
        return 'Esta conta está bloqueada.';

      case 'INVALID_NAME':
        return 'Informe seu nome corretamente.';

      case 'INVALID_EMAIL':
        return 'Informe um endereço de e-mail válido.';

      case 'WEAK_PASSWORD':
        return 'A senha não atende aos requisitos de segurança.';

      case 'UNAUTHORIZED':
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        return 'Sua sessão expirou. Entre novamente.';

      default:
        return 'Não foi possível concluir a operação.';
    }
  }

  void _limparSessaoLocal() {
    _token = null;
    _user = null;
    _status = AuthStatus.naoAutenticado;
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}