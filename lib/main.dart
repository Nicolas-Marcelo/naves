import 'dart:async';

import 'package:flutter/material.dart';

import 'features/accessibility/data/servico_feedback_tatil.dart';

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

  final feedbackTatil =
      ServicoFeedbackTatil();

  final localizacao =
      LocalizationController(
    bleService:
        BleScannerService(),
    engine:
        LocalizationEngine(
      grafo,
    ),
  );

  late final ControleVoz
      controleVoz;

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
    feedbackTatil:
        feedbackTatil,

    /*
     * Antes do TTS, liberamos completamente
     * o microfone do Vosk.
     */
    antesDeFalar: () async {
      await wakeWord.desligar();
    },

    /*
     * Depois do TTS, o ControleVoz decide:
     *
     * app aberto -> WAKE
     * rota ativa -> WAKE
     * fundo sem rota -> DESLIGADO
     */
    depoisDeFalar: () async {
      await controleVoz
          .retomarModoAutomatico();
    },
  );

  controleVoz =
      ControleVoz(
    navegacao:
        navegacao,
    wakeWord:
        wakeWord,
    feedbackTatil:
        feedbackTatil,
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
        '[NAVESCENCE] Comando recebido: $comando',
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
        '[NAVESCENCE] Timeout de comando.',
      );

      unawaited(
        controleVoz
            .processarTimeoutExterno(),
      );
    },
  );

  /*
   * Aqui apenas carregamos o serviço/modelo.
   * Não significa que o microfone ficará ligado.
   */
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
        useMaterial3:
            true,
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