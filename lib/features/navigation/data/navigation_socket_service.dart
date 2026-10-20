import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/config/api_config.dart';

class NavigationSocketService {
  io.Socket? _socket;

  bool get conectado => _socket?.connected ?? false;

  void conectar({required Future<void> Function() onNavigationConfigUpdated}) {
    if (_socket != null) return;

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      debugPrint('[SOCKET] Conectado ao backend.');
    });

    socket.onDisconnect((_) {
      debugPrint('[SOCKET] Desconectado do backend.');
    });

    socket.onConnectError((error) {
      debugPrint('[SOCKET] Erro de conexão: $error');
    });

    socket.onError((error) {
      debugPrint('[SOCKET] Erro: $error');
    });

    socket.on('navigation_config_updated', (_) async {
      debugPrint('[SOCKET] Configuração de navegação alterada.');

      try {
        await onNavigationConfigUpdated();
      } catch (error) {
        debugPrint('[SOCKET] Falha ao atualizar configuração: $error');
      }
    });

    socket.connect();
  }

  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
