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
          '[WAKE WORD → FLUTTER] NAVE detectado',
        );

        _wakeWordsController.add(null);
        break;

      case 'comando':
        final comando =
            '${call.arguments ?? ''}'
                .trim();

        if (comando.isEmpty) {
          return;
        }

        debugPrint(
          '[WAKE WORD → FLUTTER] $comando',
        );

        _comandosController.add(
          comando,
        );
        break;

      case 'timeout':
        debugPrint(
          '[WAKE WORD → FLUTTER] Timeout',
        );

        _timeoutsController.add(null);
        break;
    }
  }

  Future<void> iniciar() async {
    try {
      await _channel.invokeMethod(
        'iniciar',
      );
    } on PlatformException catch (error) {
      debugPrint(
        '[WAKE WORD] Erro ao iniciar: '
        '${error.message}',
      );
    }
  }

  Future<void> ouvir() async {
    await _channel.invokeMethod(
      'ouvir',
    );
  }

  Future<void> ouvirComando() async {
    await _channel.invokeMethod(
      'ouvirComando',
    );
  }

  Future<void> pausar() async {
    await _channel.invokeMethod(
      'pausar',
    );
  }

  Future<void> parar() async {
    await _channel.invokeMethod(
      'parar',
    );
  }

  Future<void> dispose() async {
    await _comandosController.close();
    await _timeoutsController.close();
    await _wakeWordsController.close();
  }
}