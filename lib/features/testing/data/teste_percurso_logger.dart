import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../domain/evento_teste_percurso.dart';
import 'coletor_ble_teste.dart';

class TestePercursoLogger {
  final Stopwatch _cronometro = Stopwatch();

  final List<EventoTestePercurso> _eventos = [];

  int _numeroTeste = 0;

  String? _testeAtual;
  String? _sentidoAtual;

  bool _emAndamento = false;

  bool get emAndamento => _emAndamento;

  Duration get tempoDecorrido => _cronometro.elapsed;

  String? get testeAtual => _testeAtual;

  String? get sentidoAtual => _sentidoAtual;

  List<EventoTestePercurso> get eventos => List.unmodifiable(_eventos);

  List<EventoTestePercurso> get eventosTesteAtual {
    if (_testeAtual == null) {
      return [];
    }

    return _eventos.where((evento) => evento.teste == _testeAtual).toList();
  }

  void iniciarTeste({required String sentido, required SnapshotBleTeste ble}) {
    if (_emAndamento) return;

    _numeroTeste++;

    _testeAtual = 'TESTE_${_numeroTeste.toString().padLeft(3, '0')}';

    _sentidoAtual = sentido;

    _emAndamento = true;

    _cronometro
      ..reset()
      ..start();

    registrarSnapshot(evento: 'INICIO', ble: ble);
  }

  void registrarLeituraBle(SnapshotBleTeste ble) {
    if (!_emAndamento) return;

    registrarSnapshot(evento: 'LEITURA_BLE', ble: ble);
  }

  void registrarPassagem({
    required String sensor,
    required SnapshotBleTeste ble,
  }) {
    if (!_emAndamento) return;

    registrarSnapshot(
      evento: 'PASSAGEM_MANUAL',
      sensorManual: sensor,
      ble: ble,
    );
  }

  void finalizarTeste({required SnapshotBleTeste ble}) {
    if (!_emAndamento) return;

    registrarSnapshot(evento: 'FIM', ble: ble);

    _cronometro.stop();

    _emAndamento = false;
  }

  void registrarSnapshot({
    required String evento,
    required SnapshotBleTeste ble,
    String? sensorManual,
  }) {
    if (_testeAtual == null || _sentidoAtual == null) {
      return;
    }

    final agora = DateTime.now();

    _eventos.add(
      EventoTestePercurso(
        teste: _testeAtual!,
        sentido: _sentidoAtual!,
        timestamp: agora,
        timestampEpochMs: agora.millisecondsSinceEpoch,
        tempoMs: _cronometro.elapsedMilliseconds,
        evento: evento,
        sensorManual: sensorManual,
        sensorBle: ble.sensorMaisForte,
        rssiS01: ble.rssiS01,
        m15S01: ble.m15S01,
        rssiS02: ble.rssiS02,
        m15S02: ble.m15S02,
        rssiS03: ble.rssiS03,
        m15S03: ble.m15S03,
      ),
    );
  }

  void limparTodosOsTestes() {
    if (_emAndamento) return;

    _eventos.clear();

    _numeroTeste = 0;
    _testeAtual = null;
    _sentidoAtual = null;

    _cronometro.reset();
  }

  String gerarCsv() {
    final buffer = StringBuffer();

    buffer.writeln(
      'teste,'
      'sentido,'
      'timestamp_iso,'
      'timestamp_epoch_ms,'
      'tempo_ms,'
      'tempo_segundos,'
      'evento,'
      'sensor_manual,'
      'sensor_mais_forte_m15,'
      'rssi_NAV_S01,'
      'm15_NAV_S01,'
      'rssi_NAV_S02,'
      'm15_NAV_S02,'
      'rssi_NAV_S03,'
      'm15_NAV_S03',
    );

    for (final evento in _eventos) {
      buffer.writeln(evento.toCsvValues().map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final precisaAspas =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!precisaAspas) {
      return value;
    }

    return '"${value.replaceAll('"', '""')}"';
  }

  Future<void> exportarCsv() async {
    if (_eventos.isEmpty) {
      return;
    }

    final csv = gerarCsv();

    final agora = DateTime.now();

    final nome =
        'navescence_teste_ble_'
        '${agora.year}'
        '${agora.month.toString().padLeft(2, '0')}'
        '${agora.day.toString().padLeft(2, '0')}_'
        '${agora.hour.toString().padLeft(2, '0')}'
        '${agora.minute.toString().padLeft(2, '0')}'
        '${agora.second.toString().padLeft(2, '0')}.csv';

    final arquivo = File('${Directory.systemTemp.path}/$nome');

    await arquivo.writeAsString(csv, encoding: utf8, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Teste BLE NAVESCENCE',
        files: [XFile(arquivo.path, mimeType: 'text/csv')],
      ),
    );
  }
}
