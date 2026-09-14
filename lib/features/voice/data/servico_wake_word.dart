import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ServicoWakeWord {
  ServicoWakeWord() {
    _canal.setMethodCallHandler(_receberChamadaNativa);
  }

  static const MethodChannel _canal = MethodChannel(
    'navescence/wake_word',
  );

  final StreamController<String> _comandos =
      StreamController<String>.broadcast();

  Stream<String> get comandos => _comandos.stream;

  Future<void> _receberChamadaNativa(MethodCall call) async {
    if (call.method != 'comandoReconhecido') return;

    final comando = call.arguments?.toString().trim();

    if (comando == null || comando.isEmpty) return;

    debugPrint(
      '[WAKE WORD → FLUTTER] $comando',
    );

    _comandos.add(comando);
  }

  Future<void> iniciar() async {
    if (kIsWeb) return;

    await _canal.invokeMethod(
      'iniciar',
    );
  }

  Future<void> ouvir() async {
    if (kIsWeb) return;

    await _canal.invokeMethod(
      'ouvir',
    );
  }

  Future<void> pausar() async {
    if (kIsWeb) return;

    await _canal.invokeMethod(
      'pausar',
    );
  }

  Future<void> parar() async {
    if (kIsWeb) return;

    await _canal.invokeMethod(
      'parar',
    );
  }

  Future<void> dispose() async {
    await _comandos.close();
  }
}