import 'package:flutter/material.dart';

import '../features/localization/domain/entities/sensor_state.dart';
import '../features/localization/presentation/localization_controller.dart';

class TelaLocalizacao extends StatefulWidget {
  const TelaLocalizacao({
    super.key,
    required this.controller,
  });

  final LocalizationController controller;

  @override
  State<TelaLocalizacao> createState() => _TelaLocalizacaoState();
}

class _TelaLocalizacaoState extends State<TelaLocalizacao> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_atualizar);
    widget.controller.iniciar();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  String _m15(SensorState sensor) {
    if (sensor.m15 == null) return '--';
    return '${sensor.m15!.toStringAsFixed(1)} dBm';
  }

  String _estado(String estado) {
    switch (estado) {
      case 'PROCURANDO':
        return 'Procurando localização';
      case 'CONFIRMANDO_INICIAL':
        return 'Confirmando localização';
      case 'PRE_CANDIDATO':
      case 'CONFIRMANDO_HANDOFF':
        return 'Detectando mudança de posição';
      case 'COOLDOWN':
      case 'ASSOCIADO':
        return 'Localização identificada';
      default:
        return estado;
    }
  }

  Widget _sensor(SensorState sensor) {
    final atual = widget.controller.noAtual == sensor.id;

    return Card(
      child: ListTile(
        leading: Icon(
          atual ? Icons.location_on : Icons.bluetooth,
        ),
        title: Text('${sensor.id} - ${sensor.nome}'),
        subtitle: Text(sensor.detectado ? 'Sinal detectado' : 'Sem sinal'),
        trailing: Text(
          _m15(sensor),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAVESCENCE'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Localização atual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.noAtual.isEmpty
                        ? 'Aguardando...'
                        : controller.noAtual,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_estado(controller.estado)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...controller.sensores.values.map(_sensor),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.reiniciarBle,
                  child: const Text('REINICIAR BLE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.limpar,
                  child: const Text('LIMPAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
