import 'package:flutter/material.dart';

import '../features/localization/presentation/localization_controller.dart';
import '../features/testing/presentation/painel_teste.dart';

class TelaDiagnostico extends StatefulWidget {
  const TelaDiagnostico({super.key, required this.localizacao});

  final LocalizationController localizacao;

  @override
  State<TelaDiagnostico> createState() => _TelaDiagnosticoState();
}

class _TelaDiagnosticoState extends State<TelaDiagnostico> {
  static const _azul = Color(0xFF183B56);
  static const _cinzaFundo = Color(0xFFF5F7F9);

  @override
  void initState() {
    super.initState();
    widget.localizacao.addListener(_atualizar);
  }

  @override
  void dispose() {
    widget.localizacao.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  String _texto(String? valor) {
    if (valor == null || valor.isEmpty) return '-';
    return valor;
  }

  String _horario(DateTime? horario) {
    if (horario == null) return '-';

    final hora = horario.hour.toString().padLeft(2, '0');
    final minuto = horario.minute.toString().padLeft(2, '0');
    final segundo = horario.second.toString().padLeft(2, '0');

    return '$hora:$minuto:$segundo';
  }

  String _numero(double? valor) {
    if (valor == null) return '-';
    return valor.toStringAsFixed(1);
  }

  Widget _resumoAlgoritmo() {
    final engine = widget.localizacao.engine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.memory_rounded, color: _azul),
              SizedBox(width: 8),
              Text(
                'Estado do algoritmo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _metrica('Ponto atual', _texto(widget.localizacao.noAtual)),
              _metrica('Estado', widget.localizacao.estado),
              _metrica('Candidato inicial', _texto(engine.candidatoInicial)),
              _metrica('Pré-candidato', _texto(engine.preCandidato)),
              _metrica('Candidato', _texto(engine.candidato)),
              _metrica('Handoff armado', engine.handoffArmado ? 'SIM' : 'NÃO'),
              _metrica('Último handoff', _horario(engine.ultimoHandoffEm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metrica(String titulo, String valor) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sensores() {
    final ids = widget.localizacao.sensores.keys.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bluetooth_searching_rounded, color: _azul),
              SizedBox(width: 8),
              Text(
                'Sensores BLE',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          for (var i = 0; i < ids.length; i++) ...[
            _sensorCard(ids[i]),

            if (i < ids.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _sensorCard(String id) {
    final sensor = widget.localizacao.sensores[id];

    if (sensor == null) {
      return const SizedBox.shrink();
    }

    final tendencia = widget.localizacao.engine.tendencia(id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sensor.detectado
              ? Colors.green.shade200
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: sensor.detectado ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                id,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  sensor.nome,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),

              Text(
                sensor.detectado ? 'ATIVO' : 'SEM SINAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: sensor.detectado
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            sensor.mac,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _valorSensor(
                'RSSI recebido',
                sensor.ultimoRssiRecebido == null
                    ? '-'
                    : '${sensor.ultimoRssiRecebido} dBm',
              ),
              _valorSensor(
                'RSSI válido',
                sensor.ultimoRssiValido == null
                    ? '-'
                    : '${sensor.ultimoRssiValido} dBm',
              ),
              _valorSensor('M5', _numero(sensor.m5)),
              _valorSensor('M10', _numero(sensor.m10)),
              _valorSensor('M15', _numero(sensor.m15)),
              _valorSensor('M20', _numero(sensor.m20)),
              _valorSensor('M25', _numero(sensor.m25)),
              _valorSensor('Tendência', _numero(tendencia)),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Recebidas: ${sensor.leiturasRecebidas}   '
            'Válidas: ${sensor.leiturasValidas}   '
            'Descartadas: ${sensor.leiturasDescartadas}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _valorSensor(String titulo, String valor) {
    return SizedBox(
      width: 105,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinzaFundo,
      appBar: AppBar(
        backgroundColor: _cinzaFundo,
        surfaceTintColor: _cinzaFundo,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnóstico',
              style: TextStyle(
                color: _azul,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'NAVESCENCE',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _resumoAlgoritmo(),

            const SizedBox(height: 16),

            _sensores(),

            const SizedBox(height: 16),

            PainelTeste(localizacao: widget.localizacao),
          ],
        ),
      ),
    );
  }
}
