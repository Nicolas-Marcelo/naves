import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ServicoWakeWord {
  ServicoWakeWord() {
    _channel.setMethodCallHandler(
      _receberEventoAndroid,
    );
  }

  static const MethodChannel _channel =
      MethodChannel(
    'navescence/wake_word',
  );

  final StreamController<String>
      _comandosController =
      StreamController<String>.broadcast();

  final StreamController<void>
      _timeoutsController =
      StreamController<void>.broadcast();

  final StreamController<void>
      _wakeWordsController =
      StreamController<void>.broadcast();

  Stream<String> get comandos =>
      _comandosController.stream;

  Stream<void> get timeouts =>
      _timeoutsController.stream;

  Stream<void> get wakeWords =>
      _wakeWordsController.stream;

  Future<dynamic> _receberEventoAndroid(
    MethodCall call,
  ) async {
    switch (call.method) {
      case 'wakeWord':
        debugPrint(
          '[WAKE → FLUTTER] NAVE',
        );

        if (!_wakeWordsController.isClosed) {
          _wakeWordsController.add(
            null,
          );
        }

        break;

      case 'comando':
        final comando =
            '${call.arguments ?? ''}'
                .trim();

        if (comando.isEmpty) {
          return;
        }

        debugPrint(
          '[COMANDO → FLUTTER] $comando',
        );

        if (!_comandosController.isClosed) {
          _comandosController.add(
            comando,
          );
        }

        break;

      case 'timeout':
        debugPrint(
          '[COMANDO → FLUTTER] Timeout',
        );

        if (!_timeoutsController.isClosed) {
          _timeoutsController.add(
            null,
          );
        }

        break;
    }
  }

  Future<void> iniciar() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod(
        'iniciar',
      );
    } on PlatformException catch (erro) {
      debugPrint(
        '[WAKE] Erro ao iniciar serviço: ${erro.message}',
      );
    }
  }

  Future<void> ouvir() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod(
        'ouvir',
      );
    } on PlatformException catch (erro) {
      debugPrint(
        '[WAKE] Erro ao iniciar modo Nave: ${erro.message}',
      );
    }
  }

  Future<void> ouvirComando() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod(
        'ouvirComando',
      );
    } on PlatformException catch (erro) {
      debugPrint(
        '[WAKE] Erro ao iniciar comando: ${erro.message}',
      );
    }
  }

  Future<void> desligar() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod(
        'desligar',
      );
    } on PlatformException catch (erro) {
      debugPrint(
        '[WAKE] Erro ao desligar reconhecimento: ${erro.message}',
      );
    }
  }

  Future<void> pausar() async {
    await desligar();
  }

  Future<void> parar() async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod(
        'parar',
      );
    } on PlatformException catch (erro) {
      debugPrint(
        '[WAKE] Erro ao parar serviço: ${erro.message}',
      );
    }
  }

  Future<void> dispose() async {
    await parar();

    if (!_comandosController.isClosed) {
      await _comandosController.close();
    }

    if (!_timeoutsController.isClosed) {
      await _timeoutsController.close();
    }

    if (!_wakeWordsController.isClosed) {
      await _wakeWordsController.close();
    }
  }
}