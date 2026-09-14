import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/ble_scanner_service.dart';
import '../domain/entities/sensor_state.dart';
import '../domain/services/localization_engine.dart';

class LocalizationController extends ChangeNotifier {
  LocalizationController({
    required this.bleService,
    required this.engine,
    this.modoSimulacao = false,
  });

  final BleScannerService bleService;
  final LocalizationEngine engine;
  final bool modoSimulacao;

  StreamSubscription? _leituraSubscription;
  Timer? _timerLocalizacao;

  Map<String, SensorState> get sensores => engine.sensores;
  String get noAtual => engine.noAtual;
  String get estado => engine.estado;

  Future<void> iniciar() async {
    if (modoSimulacao) return;

    _leituraSubscription ??= bleService.leituras.listen((leitura) {
      engine.registrarLeitura(leitura);
      notifyListeners();
    });

    _timerLocalizacao ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        engine.avaliar();
        notifyListeners();
      },
    );

    await bleService.iniciar();
  }

  Future<void> reiniciarBle() async {
    if (modoSimulacao) return;
    await bleService.reiniciar();
  }

  void simularPonto(String pontoId) {
    if (!modoSimulacao) return;

    engine.noAtual = pontoId;
    engine.estado = 'ASSOCIADO';

    notifyListeners();
  }

  void limpar() {
    engine.limpar();
    notifyListeners();
  }

  @override
  void dispose() {
    _timerLocalizacao?.cancel();
    _leituraSubscription?.cancel();
    bleService.dispose();
    super.dispose();
  }
}