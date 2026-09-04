import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/ble_scanner_service.dart';
import '../domain/entities/sensor_state.dart';
import '../domain/services/localization_engine.dart';

class LocalizationController extends ChangeNotifier {
  LocalizationController({
    required this.bleService,
    required this.engine,
  });

  final BleScannerService bleService;
  final LocalizationEngine engine;

  StreamSubscription? _leituraSubscription;
  Timer? _timerLocalizacao;

  Map<String, SensorState> get sensores => engine.sensores;
  String get noAtual => engine.noAtual;
  String get estado => engine.estado;

  Future<void> iniciar() async {
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
    await bleService.reiniciar();
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
