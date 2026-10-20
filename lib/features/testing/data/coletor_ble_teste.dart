import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EstadoSensorTeste {
  EstadoSensorTeste({
    required this.codigo,
    required this.mac,
  });

  final String codigo;
  final String mac;

  int? rssiAtual;
  DateTime? ultimaLeitura;

  final List<int> _historico = [];

  List<int> get historico =>
      List.unmodifiable(_historico);

  int get quantidadeAmostras =>
      _historico.length;

  double? get m15 {
    if (_historico.isEmpty) return null;

    final quantidade =
        _historico.length > 15
            ? 15
            : _historico.length;

    final valores =
        _historico.sublist(
      _historico.length - quantidade,
    );

    final soma =
        valores.fold<int>(
      0,
      (total, valor) =>
          total + valor,
    );

    return soma / valores.length;
  }

  void adicionarLeitura(
    int rssi,
  ) {
    rssiAtual = rssi;
    ultimaLeitura =
        DateTime.now();

    _historico.add(
      rssi,
    );

    if (_historico.length > 100) {
      _historico.removeAt(0);
    }
  }

  void limpar() {
    rssiAtual = null;
    ultimaLeitura = null;
    _historico.clear();
  }
}

class SnapshotBleTeste {
  const SnapshotBleTeste({
    required this.timestamp,
    required this.sensorMaisForte,
    required this.rssiS01,
    required this.m15S01,
    required this.rssiS02,
    required this.m15S02,
    required this.rssiS03,
    required this.m15S03,
  });

  final DateTime timestamp;

  final String? sensorMaisForte;

  final int? rssiS01;
  final double? m15S01;

  final int? rssiS02;
  final double? m15S02;

  final int? rssiS03;
  final double? m15S03;
}

class ColetorBleTeste {
  ColetorBleTeste();

  final EstadoSensorTeste s01 =
      EstadoSensorTeste(
    codigo: 'NAV_S01',
    mac: '68:09:47:9E:DC:16',
  );

  final EstadoSensorTeste s02 =
      EstadoSensorTeste(
    codigo: 'NAV_S02',
    mac: '20:9B:A9:69:23:A6',
  );

  final EstadoSensorTeste s03 =
      EstadoSensorTeste(
    codigo: 'NAV_S03',
    mac: '68:09:47:9D:8D:DA',
  );

  final StreamController<
      SnapshotBleTeste> _controller =
      StreamController<
          SnapshotBleTeste>.broadcast();

  StreamSubscription<
      List<ScanResult>>? _scanSubscription;

  bool _executando = false;

  bool get executando =>
      _executando;

  Stream<SnapshotBleTeste>
      get snapshots =>
          _controller.stream;

  Future<void> iniciar() async {
    if (_executando) return;

    _executando = true;

    s01.limpar();
    s02.limpar();
    s03.limpar();

    _scanSubscription =
        FlutterBluePlus
            .scanResults
            .listen(
      _processarResultados,
      onError: (Object error) {
        print(
          '[TESTE BLE] Erro: $error',
        );
      },
    );

    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      await FlutterBluePlus.startScan(
        continuousUpdates: true,
        removeIfGone:
            const Duration(
          seconds: 3,
        ),
      );
    } catch (error) {
      _executando = false;

      await _scanSubscription
          ?.cancel();

      _scanSubscription = null;

      rethrow;
    }
  }

  void _processarResultados(
    List<ScanResult> resultados,
  ) {
    if (!_executando) return;

    bool recebeuSensor = false;

    for (final resultado
        in resultados) {
      final mac =
          resultado
              .device
              .remoteId
              .str
              .toUpperCase();

      final nome =
          resultado
              .advertisementData
              .advName
              .toUpperCase();

      EstadoSensorTeste? sensor;

      if (mac == s01.mac ||
          nome == s01.codigo) {
        sensor = s01;
      } else if (
          mac == s02.mac ||
          nome == s02.codigo) {
        sensor = s02;
      } else if (
          mac == s03.mac ||
          nome == s03.codigo) {
        sensor = s03;
      }

      if (sensor == null) {
        continue;
      }

      sensor.adicionarLeitura(
        resultado.rssi,
      );

      recebeuSensor = true;

      print(
        '[TESTE BLE] '
        '${sensor.codigo} | '
        'RSSI ${resultado.rssi} | '
        'M15 ${sensor.m15?.toStringAsFixed(2)}',
      );
    }

    if (recebeuSensor) {
      _controller.add(
        snapshot(),
      );
    }
  }

  SnapshotBleTeste snapshot() {
    return SnapshotBleTeste(
      timestamp:
          DateTime.now(),
      sensorMaisForte:
          _sensorMaisForte(),
      rssiS01:
          s01.rssiAtual,
      m15S01:
          s01.m15,
      rssiS02:
          s02.rssiAtual,
      m15S02:
          s02.m15,
      rssiS03:
          s03.rssiAtual,
      m15S03:
          s03.m15,
    );
  }

  String? _sensorMaisForte() {
    final sensores = [
      s01,
      s02,
      s03,
    ];

    EstadoSensorTeste? melhor;

    for (final sensor
        in sensores) {
      if (sensor.m15 == null) {
        continue;
      }

      if (melhor == null ||
          sensor.m15! >
              melhor.m15!) {
        melhor = sensor;
      }
    }

    return melhor?.codigo;
  }

  Future<void> parar() async {
    if (!_executando) return;

    _executando = false;

    await FlutterBluePlus.stopScan();

    await _scanSubscription
        ?.cancel();

    _scanSubscription = null;
  }

  Future<void> dispose() async {
    await parar();
    await _controller.close();
  }
}