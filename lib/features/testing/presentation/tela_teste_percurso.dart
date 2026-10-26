import 'dart:async';
import 'package:flutter/material.dart';

import '../data/coletor_ble_teste.dart';
import '../data/teste_percurso_logger.dart';
import '../domain/evento_teste_percurso.dart';

class TelaTestePercurso extends StatefulWidget {
  const TelaTestePercurso({super.key});

  @override
  State<TelaTestePercurso> createState() => _TelaTestePercursoState();
}

class _TelaTestePercursoState extends State<TelaTestePercurso> {
  final TestePercursoLogger _logger = TestePercursoLogger();
  final ColetorBleTeste _ble = ColetorBleTeste();

  Timer? _timer;

  StreamSubscription<SnapshotBleTeste>? _bleSubscription;

  String _sentido = 'NAV_S01_PARA_NAV_S03';

  String? _erroBle;

  bool _iniciando = false;

  SnapshotBleTeste? _ultimoBle;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;

      if (_logger.emAndamento) {
        setState(() {});
      }
    });

    _bleSubscription = _ble.snapshots.listen((snapshot) {
      _ultimoBle = snapshot;

      if (_logger.emAndamento) {
        _logger.registrarLeituraBle(snapshot);
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bleSubscription?.cancel();
    _ble.dispose();

    super.dispose();
  }

  Future<void> _iniciar() async {
    if (_iniciando) return;

    setState(() {
      _iniciando = true;
      _erroBle = null;
    });

    try {
      await _ble.iniciar();

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final snapshot = _ble.snapshot();

      _ultimoBle = snapshot;

      _logger.iniciarTeste(sentido: _sentido, ble: snapshot);

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _erroBle = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _iniciando = false;
        });
      }
    }
  }

  void _registrarSensor(String sensor) {
    if (!_logger.emAndamento) return;

    final snapshot = _ble.snapshot();

    _ultimoBle = snapshot;

    _logger.registrarPassagem(sensor: sensor, ble: snapshot);

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 400),
          content: Text('$sensor registrado'),
        ),
      );
  }

  Future<void> _finalizar() async {
    if (!_logger.emAndamento) return;

    final snapshot = _ble.snapshot();

    _logger.finalizarTeste(ble: snapshot);

    await _ble.parar();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _exportar() async {
    await _logger.exportarCsv();
  }

  Future<void> _limpar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar testes?'),
          content: const Text('Todos os dados desta sessão serão apagados.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    _logger.limparTodosOsTestes();

    setState(() {});
  }

  String _formatarTempo(Duration duration) {
    final minutos = duration.inMinutes;

    final segundos = duration.inSeconds % 60;

    final milissegundos = duration.inMilliseconds % 1000;

    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundos.toString().padLeft(2, '0')}.'
        '${milissegundos.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final emAndamento = _logger.emAndamento;

    final snapshot = _ultimoBle ?? _ble.snapshot();

    return Scaffold(
      appBar: AppBar(title: const Text('Teste BLE NAVESCENCE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _formatarTempo(_logger.tempoDecorrido),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              emAndamento ? 'TESTE EM ANDAMENTO' : 'TESTE PARADO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: emAndamento ? Colors.green : Colors.grey,
              ),
            ),

            if (_logger.testeAtual != null)
              Text(_logger.testeAtual!, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _sentido,
              decoration: const InputDecoration(
                labelText: 'Sentido',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'NAV_S01_PARA_NAV_S03',
                  child: Text('NAV_S01 → NAV_S03'),
                ),
                DropdownMenuItem(
                  value: 'NAV_S03_PARA_NAV_S01',
                  child: Text('NAV_S03 → NAV_S01'),
                ),
              ],
              onChanged: emAndamento
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _sentido = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            _PainelBle(snapshot: snapshot),

            if (_erroBle != null) ...[
              const SizedBox(height: 12),
              Text(_erroBle!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 20),

            if (!emAndamento)
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: _iniciando ? null : _iniciar,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    _iniciando ? 'INICIANDO BLE...' : 'INICIAR TESTE',
                  ),
                ),
              ),

            if (emAndamento) ...[
              _SensorButton(
                sensor: 'NAV_S01',
                onPressed: () => _registrarSensor('NAV_S01'),
              ),

              const SizedBox(height: 12),

              _SensorButton(
                sensor: 'NAV_S02',
                onPressed: () => _registrarSensor('NAV_S02'),
              ),

              const SizedBox(height: 12),

              _SensorButton(
                sensor: 'NAV_S03',
                onPressed: () => _registrarSensor('NAV_S03'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _finalizar,
                  icon: const Icon(Icons.stop),
                  label: const Text('FINALIZAR TESTE'),
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_logger.eventos.isNotEmpty && !emAndamento) ...[
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: _exportar,
                  icon: const Icon(Icons.file_download),
                  label: const Text('EXPORTAR CSV'),
                ),
              ),

              TextButton.icon(
                onPressed: _limpar,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpar testes'),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              'Registros CSV: '
              '${_logger.eventos.length}',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            if (_logger.eventosTesteAtual.isNotEmpty)
              ..._logger.eventosTesteAtual
                  .where(
                    (evento) =>
                        evento.evento == 'PASSAGEM_MANUAL' ||
                        evento.evento == 'INICIO' ||
                        evento.evento == 'FIM',
                  )
                  .map((evento) => _EventoTile(evento: evento)),
          ],
        ),
      ),
    );
  }
}

class _PainelBle extends StatelessWidget {
  const _PainelBle({required this.snapshot});

  final SnapshotBleTeste snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sinais BLE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            _linha('NAV_S01', snapshot.rssiS01, snapshot.m15S01),

            _linha('NAV_S02', snapshot.rssiS02, snapshot.m15S02),

            _linha('NAV_S03', snapshot.rssiS03, snapshot.m15S03),

            const Divider(),

            Text(
              'Mais forte M15: '
              '${snapshot.sensorMaisForte ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(String sensor, int? rssi, double? m15) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(sensor)),
          Text('RSSI: ${rssi ?? '-'}'),
          const SizedBox(width: 14),
          SizedBox(
            width: 100,
            child: Text(
              'M15: '
              '${m15?.toStringAsFixed(1) ?? '-'}',
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorButton extends StatelessWidget {
  const _SensorButton({required this.sensor, required this.onPressed});

  final String sensor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Registrar passagem embaixo do $sensor',
      child: SizedBox(
        height: 82,
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          child: Text(
            'PASSEI NO $sensor',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({required this.evento});

  final EventoTestePercurso evento;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(evento.sensorManual ?? evento.evento),
        subtitle: Text(
          '${evento.tempoSegundos.toStringAsFixed(3)} s'
          ' • BLE: ${evento.sensorBle ?? '-'}',
        ),
      ),
    );
  }
}
