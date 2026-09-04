import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/config/beacon_config.dart';
import '../domain/entities/rssi_reading.dart';

class BleScannerService {
  final _leituras = StreamController<RssiReading>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _watchdog;

  DateTime? _ultimaLeitura;
  bool _reiniciando = false;

  Stream<RssiReading> get leituras => _leituras.stream;

  Future<void> iniciar() async {
    _scanSubscription ??=
        FlutterBluePlus.onScanResults.listen(_processarResultados);

    _watchdog ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => _verificarScanner(),
    );

    await _iniciarScan();
  }

  Future<void> _iniciarScan() async {
    if (FlutterBluePlus.isScanningNow) return;

    await FlutterBluePlus.startScan(
      androidUsesFineLocation: true,
      continuousUpdates: true,
      oneByOne: true,
      androidScanMode: AndroidScanMode.lowLatency,
      continuousDivisor: 1,
    );
  }

  void _processarResultados(List<ScanResult> resultados) {
    for (final resultado in resultados) {
      final mac = resultado.device.remoteId.str.toUpperCase();
      final beacon = BeaconConfig.porMac(mac);

      if (beacon == null) continue;

      _ultimaLeitura = DateTime.now();

      _leituras.add(
        RssiReading(
          nodeId: beacon.nodeId,
          rssi: resultado.rssi,
          timestamp: _ultimaLeitura!,
        ),
      );
    }
  }

  Future<void> reiniciar() async {
    if (_reiniciando) return;
    _reiniciando = true;

    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 400));
      await _iniciarScan();
    } finally {
      _reiniciando = false;
    }
  }

  Future<void> _verificarScanner() async {
    if (_reiniciando) return;

    if (!FlutterBluePlus.isScanningNow) {
      await reiniciar();
      return;
    }

    if (_ultimaLeitura == null) return;

    if (DateTime.now().difference(_ultimaLeitura!) >
        const Duration(seconds: 6)) {
      await reiniciar();
    }
  }

  Future<void> parar() async {
    _watchdog?.cancel();
    _watchdog = null;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await FlutterBluePlus.stopScan();
  }

  Future<void> dispose() async {
    await parar();
    await _leituras.close();
  }
}
