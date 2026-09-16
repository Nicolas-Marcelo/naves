import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../../localization/presentation/localization_controller.dart';

class ControleTeste extends ChangeNotifier {
  ControleTeste({required this.localizacao});

  final LocalizationController localizacao;

  final List<Map<String, dynamic>> _registros = [];

  Timer? _timer;
  DateTime? _inicio;

  String _ultimoNo = '';

  bool executando = false;

  int get quantidadeRegistros => _registros.length;

  Duration get duracao {
    if (_inicio == null) return Duration.zero;

    return DateTime.now().difference(_inicio!);
  }

  void iniciar() {
    _timer?.cancel();

    _registros.clear();

    _inicio = DateTime.now();
    _ultimoNo = localizacao.noAtual;

    executando = true;

    _registrar(evento: 'INICIO_TESTE');

    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _registrarAmostra(),
    );

    notifyListeners();
  }

  void _registrarAmostra() {
    if (!executando) return;

    final noAtual = localizacao.noAtual;

    var evento = 'AMOSTRA';

    if (_ultimoNo.isEmpty && noAtual.isNotEmpty) {
      evento = 'ASSOCIACAO_INICIAL';
    } else if (_ultimoNo.isNotEmpty &&
        noAtual.isNotEmpty &&
        noAtual != _ultimoNo) {
      evento = 'HANDOFF';
    }

    _registrar(evento: evento);

    _ultimoNo = noAtual;

    notifyListeners();
  }

  void marcarSensor(String sensorId) {
    if (!executando) return;

    _registrar(evento: 'SOB_SENSOR', sensorReferencia: sensorId);

    notifyListeners();
  }

  void parar() {
    if (!executando) return;

    _registrar(evento: 'FIM_TESTE');

    executando = false;

    _timer?.cancel();
    _timer = null;

    notifyListeners();
  }

  void _registrar({required String evento, String sensorReferencia = ''}) {
    final agora = DateTime.now();
    final engine = localizacao.engine;

    final registro = <String, dynamic>{
      'timestamp': agora.toIso8601String(),
      'tempo_ms': _inicio == null
          ? 0
          : agora.difference(_inicio!).inMilliseconds,
      'evento': evento,
      'sensor_referencia': sensorReferencia,
      'no_estimado': localizacao.noAtual,
      'estado': localizacao.estado,
      'candidato_inicial': engine.candidatoInicial ?? '',
      'pre_candidato': engine.preCandidato ?? '',
      'candidato': engine.candidato ?? '',
      'handoff_armado': engine.handoffArmado,
      'ultimo_handoff': engine.ultimoHandoffEm?.toIso8601String() ?? '',
    };

    final sensores = localizacao.sensores.keys.toList()..sort();

    for (final id in sensores) {
      final sensor = localizacao.sensores[id];

      if (sensor == null) continue;

      registro['${id}_detectado'] = sensor.detectado;
      registro['${id}_rssi_recebido'] = sensor.ultimoRssiRecebido ?? '';
      registro['${id}_rssi_valido'] = sensor.ultimoRssiValido ?? '';

      registro['${id}_m5'] = _numero(sensor.m5);
      registro['${id}_m10'] = _numero(sensor.m10);
      registro['${id}_m15'] = _numero(sensor.m15);
      registro['${id}_m20'] = _numero(sensor.m20);
      registro['${id}_m25'] = _numero(sensor.m25);

      registro['${id}_tendencia'] = _numero(engine.tendencia(id));

      registro['${id}_recebidas'] = sensor.leiturasRecebidas;

      registro['${id}_validas'] = sensor.leiturasValidas;

      registro['${id}_descartadas'] = sensor.leiturasDescartadas;
    }

    _registros.add(registro);
  }

  String _numero(double? valor) {
    if (valor == null) return '';

    return valor.toStringAsFixed(2);
  }

  String gerarCsv() {
    if (_registros.isEmpty) return '';

    final colunas = <String>{};

    for (final registro in _registros) {
      colunas.addAll(registro.keys);
    }

    final cabecalho = colunas.toList();

    final linhas = <String>[cabecalho.map(_escaparCsv).join(',')];

    for (final registro in _registros) {
      final linha = cabecalho
          .map((coluna) {
            return _escaparCsv('${registro[coluna] ?? ''}');
          })
          .join(',');

      linhas.add(linha);
    }

    return linhas.join('\n');
  }

  String _escaparCsv(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }

    return valor;
  }

  Future<void> exportarCsv() async {
    if (_registros.isEmpty) return;

    final csv = gerarCsv();

    final agora = DateTime.now();

    final nome =
        'navescence_teste_'
        '${agora.year}'
        '${_dois(agora.month)}'
        '${_dois(agora.day)}_'
        '${_dois(agora.hour)}'
        '${_dois(agora.minute)}'
        '${_dois(agora.second)}.csv';

    final arquivo = XFile.fromData(
      Uint8List.fromList(utf8.encode(csv)),
      mimeType: 'text/csv',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [arquivo],
        fileNameOverrides: [nome],
        downloadFallbackEnabled: true,
      ),
    );
  }

  String _dois(int valor) {
    return valor.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
