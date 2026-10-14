import 'dart:async';

import 'package:flutter/material.dart';

import 'core/config/beacon_config.dart';

import 'features/accessibility/data/servico_feedback_tatil.dart';

import 'features/localization/data/ble_scanner_service.dart';
import 'features/localization/domain/services/localization_engine.dart';
import 'features/localization/presentation/localization_controller.dart';

import 'features/navigation/data/navigation_config_repository.dart';
import 'features/navigation/data/navigation_socket_service.dart';
import 'features/navigation/domain/services/calculador_estrela.dart';
import 'features/navigation/presentation/controle_navegacao.dart';

import 'features/voice/data/servico_wake_word.dart';
import 'features/voice/presentation/controle_voz.dart';

import 'presentation/tela_navegacao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = NavigationConfigRepository();

  try {
    final config = await repository.carregar();

    debugPrint(
      '[NAVESCENCE] Configuração inicial carregada | '
      '${config.grafo.pontos.length} nós | '
      '${config.grafo.conexoes.length} conexões | '
      '${config.locais.length} locais | '
      '${config.beacons.length} beacons.',
    );

    BeaconConfig.configurar(config.beacons);

    final wakeWord = ServicoWakeWord();
    final feedbackTatil = ServicoFeedbackTatil();

    final localizacao = LocalizationController(
      bleService: BleScannerService(),
      engine: LocalizationEngine(config.grafo),
    );

    late final ControleVoz controleVoz;

    final navegacao = ControleNavegacao(
      localizacao: localizacao,
      grafo: config.grafo,
      calculador: CalculadorEstrela(),
      locais: config.locais,
      feedbackTatil: feedbackTatil,
      antesDeFalar: () async {
        await wakeWord.desligar();
      },
      depoisDeFalar: () async {
        await controleVoz.retomarModoAutomatico();
      },
    );

    controleVoz = ControleVoz(
      navegacao: navegacao,
      wakeWord: wakeWord,
      feedbackTatil: feedbackTatil,
    );

    final socket = NavigationSocketService();

    socket.conectar(
      onNavigationConfigUpdated: () async {
        debugPrint(
          '[NAVESCENCE] Alteração recebida pelo Socket.IO.',
        );

        debugPrint(
          '[NAVESCENCE] Buscando nova configuração...',
        );

        try {
          final novaConfig = await repository.atualizar();

          BeaconConfig.configurar(
            novaConfig.beacons,
          );

          localizacao.atualizarConfiguracao(
            novaConfig.grafo,
          );

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
          debugPrint(
            '[NAVESCENCE] Falha ao atualizar configuração: $error',
          );
        }
      },
    );

    wakeWord.wakeWords.listen((_) {
      debugPrint(
        '[NAVESCENCE] NAVE detectado.',
      );

      unawaited(
        controleVoz.palavraChaveDetectada(),
      );
    });

    wakeWord.comandos.listen((comando) {
      debugPrint(
        '[NAVESCENCE] Comando recebido: $comando',
      );

      unawaited(
        controleVoz.processarComandoExterno(
          comando,
        ),
      );
    });

    wakeWord.timeouts.listen((_) {
      debugPrint(
        '[NAVESCENCE] Timeout de comando.',
      );

      unawaited(
        controleVoz.processarTimeoutExterno(),
      );
    });

    unawaited(
      wakeWord.iniciar(),
    );

    runApp(
      NavescenceApp(
        localizacao: localizacao,
        navegacao: navegacao,
        controleVoz: controleVoz,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint(
      '[NAVESCENCE] Erro durante inicialização: $error',
    );

    debugPrint(
      '$stackTrace',
    );

    runApp(
      NavescenceStartupErrorApp(
        error: error,
      ),
    );
  }
}

class NavescenceApp extends StatelessWidget {
  const NavescenceApp({
    super.key,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
  });

  final LocalizationController localizacao;
  final ControleNavegacao navegacao;
  final ControleVoz controleVoz;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TelaNavegacao(
        localizacao: localizacao,
        navegacao: navegacao,
        controleVoz: controleVoz,
      ),
    );
  }
}

class NavescenceStartupErrorApp extends StatelessWidget {
  const NavescenceStartupErrorApp({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Não foi possível carregar a configuração do NAVESCENCE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}