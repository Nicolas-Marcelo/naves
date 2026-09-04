import 'package:flutter/material.dart';

import '../features/localization/domain/entities/sensor_state.dart';
import '../features/localization/presentation/localization_controller.dart';
import '../features/navigation/domain/entities/local.dart';
import '../features/navigation/presentation/controle_navegacao.dart';

class TelaNavegacao extends StatefulWidget {
  const TelaNavegacao({
    super.key,
    required this.localizacao,
    required this.navegacao,
  });

  final LocalizationController localizacao;
  final ControleNavegacao navegacao;

  @override
  State<TelaNavegacao> createState() => _TelaNavegacaoState();
}

class _TelaNavegacaoState extends State<TelaNavegacao> {
  @override
  void initState() {
    super.initState();

    widget.localizacao.addListener(_atualizar);
    widget.navegacao.addListener(_atualizar);

    widget.localizacao.iniciar();
  }

  @override
  void dispose() {
    widget.localizacao.removeListener(_atualizar);
    widget.navegacao.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  String _m15(SensorState sensor) {
    if (sensor.m15 == null) return '--';
    return '${sensor.m15!.toStringAsFixed(1)} dBm';
  }

  String _nomeEstado(String estado) {
    switch (estado) {
      case 'DESTINO_SELECIONADO':
        return 'Destino selecionado';
      case 'ROTA_ATIVA':
        return 'Rota ativa';
      case 'ROTA_RECALCULADA':
        return 'Rota recalculada';
      case 'DESTINO_ALCANCADO':
        return 'Destino alcançado';
      case 'SEM_CAMINHO':
        return 'Rota não encontrada';
      default:
        return 'Sem rota';
    }
  }

  Widget _cardSensor(SensorState sensor) {
    final atual = widget.localizacao.noAtual == sensor.id;

    return Card(
      child: ListTile(
        leading: Icon(
          atual ? Icons.location_on : Icons.bluetooth,
        ),
        title: Text('${sensor.id} - ${sensor.nome}'),
        subtitle: Text(
          sensor.detectado ? 'Sinal detectado' : 'Sem sinal',
        ),
        trailing: Text(
          _m15(sensor),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizacao = widget.localizacao;
    final navegacao = widget.navegacao;

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
                    localizacao.noAtual.isEmpty
                        ? 'Aguardando...'
                        : localizacao.noAtual,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<Local>(
            key: ValueKey(navegacao.destino?.pontoId),
            initialValue: navegacao.destino,
            decoration: const InputDecoration(
              labelText: 'Destino',
              border: OutlineInputBorder(),
            ),
            items: navegacao.locais.map((local) {
              return DropdownMenuItem(
                value: local,
                child: Text(local.nome),
              );
            }).toList(),
            onChanged: navegacao.selecionarDestino,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: navegacao.iniciarRota,
              child: const Text('INICIAR ROTA'),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nomeEstado(navegacao.estado),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(navegacao.mensagem),

                  if (navegacao.rota != null) ...[
                    const SizedBox(height: 16),

                    Text(
                      navegacao.rota!.pontos.join(' → '),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Distância aproximada: '
                      '${navegacao.rota!.distancia.toStringAsFixed(1)} m',
                    ),
                  ],

                  if (navegacao.proximoPonto != null) ...[
                    const SizedBox(height: 14),

                    Text(
                      'Próximo ponto: ${navegacao.proximoPonto}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Sensores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          ...localizacao.sensores.values.map(_cardSensor),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: localizacao.reiniciarBle,
                  child: const Text('REINICIAR BLE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: navegacao.cancelarRota,
                  child: const Text('CANCELAR ROTA'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}