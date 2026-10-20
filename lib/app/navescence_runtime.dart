import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/beacon_config.dart';

import '../features/localization/presentation/localization_controller.dart';

import '../features/navigation/data/navigation_config_repository.dart';
import '../features/navigation/data/navigation_socket_service.dart';
import '../features/navigation/presentation/controle_navegacao.dart';

import '../features/voice/data/servico_wake_word.dart';
import '../features/voice/presentation/controle_voz.dart';

class NavescenceRuntime {
  NavescenceRuntime({
    required this.repository,
    required this.socket,
    required this.wakeWord,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
  });

  final NavigationConfigRepository repository;
  final NavigationSocketService socket;
  final ServicoWakeWord wakeWord;
  final LocalizationController localizacao;
  final ControleNavegacao navegacao;
  final ControleVoz controleVoz;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _iniciado = false;
  bool _atualizandoConfiguracao = false;

  Future<void> iniciar() async {
    if (_iniciado) return;

    _iniciado = true;

    _configurarSocket();
    _configurarVoz();

    await wakeWord.iniciar();
  }

  void _configurarSocket() {
    socket.conectar(onNavigationConfigUpdated: _atualizarConfiguracao);
  }

  void _configurarVoz() {
    _subscriptions.add(
      wakeWord.wakeWords.listen((_) {
        debugPrint('[NAVESCENCE] NAVE detectado.');

        unawaited(controleVoz.palavraChaveDetectada());
      }),
    );

    _subscriptions.add(
      wakeWord.comandos.listen((comando) {
        debugPrint('[NAVESCENCE] Comando recebido: $comando');

        unawaited(controleVoz.processarComandoExterno(comando));
      }),
    );

    _subscriptions.add(
      wakeWord.timeouts.listen((_) {
        debugPrint('[NAVESCENCE] Timeout de comando.');

        unawaited(controleVoz.processarTimeoutExterno());
      }),
    );
  }

  Future<void> _atualizarConfiguracao() async {
    if (_atualizandoConfiguracao) {
      debugPrint('[NAVESCENCE] Atualização já em andamento. Evento ignorado.');

      return;
    }

    _atualizandoConfiguracao = true;

    try {
      debugPrint('[NAVESCENCE] Alteração recebida pelo Socket.IO.');

      debugPrint('[NAVESCENCE] Buscando nova configuração...');

      final novaConfig = await repository.atualizar();

      BeaconConfig.configurar(novaConfig.beacons);

      localizacao.atualizarConfiguracao(novaConfig.grafo);

      navegacao.atualizarConfiguracao(
        novoGrafo: novaConfig.grafo,
        novosLocais: novaConfig.locais,
      );

      debugPrint(
        '[NAVESCENCE] Configuração atualizada com sucesso | '
        '${novaConfig.grafo.pontos.length} nós | '
        '${novaConfig.grafo.conexoes.length} conexões | '
        '${novaConfig.locais.length} locais | '
        '${novaConfig.beacons.length} beacons.',
      );
    } catch (error) {
      debugPrint('[NAVESCENCE] Falha ao atualizar configuração: $error');
    } finally {
      _atualizandoConfiguracao = false;
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();

    socket.desconectar();

    await wakeWord.dispose();

    navegacao.dispose();
    localizacao.dispose();

    _iniciado = false;
  }
}
