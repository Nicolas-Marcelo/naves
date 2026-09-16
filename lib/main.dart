import 'dart:async';

import 'package:flutter/material.dart';

import 'features/localization/data/ble_scanner_service.dart';
import 'features/localization/domain/services/localization_engine.dart';
import 'features/localization/presentation/localization_controller.dart';

import 'features/navigation/data/ambiente_teste.dart';
import 'features/navigation/domain/services/calculador_estrela.dart';
import 'features/navigation/presentation/controle_navegacao.dart';

import 'features/voice/data/servico_wake_word.dart';
import 'features/voice/presentation/controle_voz.dart';

import 'presentation/tela_navegacao.dart';

void main() {
  WidgetsFlutterBinding
      .ensureInitialized();

  final grafo =
      AmbienteTeste.criarGrafo();

  final wakeWord =
      ServicoWakeWord();

  final localizacao =
      LocalizationController(
    bleService:
        BleScannerService(),
    engine:
        LocalizationEngine(
      grafo,
    ),
  );

  final navegacao =
      ControleNavegacao(
    localizacao:
        localizacao,
    grafo:
        grafo,
    calculador:
        CalculadorEstrela(),
    locais:
        AmbienteTeste.locais,
  );

  final controleVoz =
      ControleVoz(
    navegacao:
        navegacao,
  );

  wakeWord.wakeWords.listen(
    (_) {
      debugPrint(
        '[NAVESCENCE] NAVE detectado.',
      );

      unawaited(
        controleVoz
            .palavraChaveDetectada(),
      );
    },
  );

  wakeWord.comandos.listen(
    (comando) {
      debugPrint(
        '[NAVESCENCE] Comando recebido do Android: $comando',
      );

      unawaited(
        controleVoz
            .processarComandoExterno(
          comando,
        ),
      );
    },
  );

  wakeWord.timeouts.listen(
    (_) {
      debugPrint(
        '[NAVESCENCE] Timeout de comando recebido.',
      );

      unawaited(
        controleVoz
            .processarTimeoutExterno(),
      );
    },
  );

  // Inicia o Vosk depois que todos os
  // listeners já estão prontos.
  unawaited(
    wakeWord.iniciar(),
  );

  runApp(
    NavescenceApp(
      localizacao:
          localizacao,
      navegacao:
          navegacao,
      controleVoz:
          controleVoz,
    ),
  );
}

class NavescenceApp
    extends StatelessWidget {

  const NavescenceApp({
    super.key,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
  });

  final LocalizationController
      localizacao;

  final ControleNavegacao
      navegacao;

  final ControleVoz
      controleVoz;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title:
          'NAVESCENCE',
      theme:
          ThemeData(
        useMaterial3: true,
      ),
      home:
          TelaNavegacao(
        localizacao:
            localizacao,
        navegacao:
            navegacao,
        controleVoz:
            controleVoz,
      ),
    );
  }
}