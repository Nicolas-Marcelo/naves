import 'package:flutter/material.dart';

import '../../localization/presentation/localization_controller.dart';
import 'controle_teste.dart';

class PainelTeste extends StatefulWidget {
  const PainelTeste({
    super.key,
    required this.localizacao,
  });

  final LocalizationController localizacao;

  @override
  State<PainelTeste> createState() => _PainelTesteState();
}

class _PainelTesteState extends State<PainelTeste> {
  late final ControleTeste controle;

  String? sensorSelecionado;

  @override
  void initState() {
    super.initState();

    controle = ControleTeste(
      localizacao: widget.localizacao,
    );

    controle.addListener(_atualizar);

    final sensores = widget.localizacao.sensores.keys.toList()..sort();

    if (sensores.isNotEmpty) {
      sensorSelecionado = sensores.first;
    }
  }

  @override
  void dispose() {
    controle.removeListener(_atualizar);
    controle.dispose();

    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  String _tempo(Duration duracao) {
    final minutos =
        duracao.inMinutes.remainder(60).toString().padLeft(2, '0');

    final segundos =
        duracao.inSeconds.remainder(60).toString().padLeft(2, '0');

    final decimos =
        (duracao.inMilliseconds.remainder(1000) ~/ 100);

    return '$minutos:$segundos.$decimos';
  }

  String _valor(double? valor) {
    if (valor == null) return '-';

    return valor.toStringAsFixed(1);
  }

  Widget _sensorCard(String id) {
    final sensor = widget.localizacao.sensores[id];

    if (sensor == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 245,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(14),
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
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: sensor.detectado
                      ? Colors.green
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                id,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '${sensor.ultimoRssiRecebido ?? '-'} dBm',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _metrica('M5', _valor(sensor.m5)),
              _metrica('M10', _valor(sensor.m10)),
              _metrica('M15', _valor(sensor.m15)),
              _metrica('M20', _valor(sensor.m20)),
              _metrica('M25', _valor(sensor.m25)),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Válidas: ${sensor.leiturasValidas}  •  '
            'Descartadas: ${sensor.leiturasDescartadas}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrica(String nome, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensores = widget.localizacao.sensores.keys.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8E0E6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Color(0xFF183B56),
              ),

              SizedBox(width: 8),

              Text(
                'Validação do algoritmo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF183B56),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Registra os sinais, médias, handoffs e os pontos reais do percurso.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _informacao(
                'Tempo',
                _tempo(controle.duracao),
              ),
              _informacao(
                'Registros',
                '${controle.quantidadeRegistros}',
              ),
              _informacao(
                'Estimado',
                widget.localizacao.noAtual.isEmpty
                    ? '-'
                    : widget.localizacao.noAtual,
              ),
              _informacao(
                'Estado',
                widget.localizacao.estado,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: controle.executando
                    ? null
                    : controle.iniciar,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('INICIAR TESTE'),
              ),

              OutlinedButton.icon(
                onPressed: controle.executando
                    ? controle.parar
                    : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('PARAR'),
              ),

              OutlinedButton.icon(
                onPressed: controle.quantidadeRegistros > 0
                    ? controle.exportarCsv
                    : null,
                icon: const Icon(Icons.download_rounded),
                label: const Text('EXPORTAR CSV'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Sensor de referência',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Antes de chegar ao sensor, selecione qual será o próximo.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in sensores)
                ChoiceChip(
                  label: Text(id),
                  selected: sensorSelecionado == id,
                  onSelected: (_) {
                    setState(() {
                      sensorSelecionado = id;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton.icon(
              onPressed: controle.executando &&
                      sensorSelecionado != null
                  ? () {
                      controle.marcarSensor(
                        sensorSelecionado!,
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.my_location_rounded,
                size: 27,
              ),
              label: Text(
                sensorSelecionado == null
                    ? 'SELECIONE O SENSOR'
                    : 'ESTOU EMBAIXO DO $sensorSelecionado',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Leituras em tempo real',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final id in sensores)
                _sensorCard(id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _informacao(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}