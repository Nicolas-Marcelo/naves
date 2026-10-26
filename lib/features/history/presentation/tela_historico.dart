import 'package:flutter/material.dart';

import '../data/navigation_history_service.dart';

class TelaHistorico extends StatefulWidget {
  final NavigationHistoryService service;

  const TelaHistorico({super.key, required this.service});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _historicos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await widget.service.carregarHoje();

      final historicos = resposta.whereType<Map<String, dynamic>>().toList();

      if (!mounted) return;

      setState(() {
        _historicos = historicos;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o histórico.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de navegação')),
      body: RefreshIndicator(onRefresh: _carregar, child: _conteudo()),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _erro!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }

    if (_historicos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.route_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Nenhuma navegação registrada hoje.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'As navegações realizadas ao longo do dia aparecerão aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _historicos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _HistoricoCard(historico: _historicos[index]);
      },
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  final Map<String, dynamic> historico;

  const _HistoricoCard({required this.historico});

  @override
  Widget build(BuildContext context) {
    final origem = historico['originNodeCode']?.toString() ?? '-';

    final destino =
        historico['destinationName']?.toString() ??
        historico['destinationNodeCode']?.toString() ??
        '-';

    final status = historico['status']?.toString() ?? '';

    final inicio = _formatarHorario(historico['startedAt']?.toString());

    final fim = _formatarHorario(historico['finishedAt']?.toString());

    final eventosRaw = historico['events'];

    final eventos = eventosRaw is List
        ? eventosRaw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destino,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 14),
            _LinhaInformacao(
              icon: Icons.trip_origin,
              titulo: 'Origem',
              valor: origem,
            ),
            const SizedBox(height: 8),
            _LinhaInformacao(
              icon: Icons.flag_outlined,
              titulo: 'Destino',
              valor: destino,
            ),
            const SizedBox(height: 8),
            _LinhaInformacao(
              icon: Icons.schedule_outlined,
              titulo: 'Início',
              valor: inicio,
            ),
            if (fim.isNotEmpty) ...[
              const SizedBox(height: 8),
              _LinhaInformacao(
                icon: Icons.check_circle_outline,
                titulo: 'Finalização',
                valor: fim,
              ),
            ],
            if (eventos.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Trajeto',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...eventos.map((evento) {
                final node = evento['nodeCode']?.toString() ?? '-';

                final label = evento['label']?.toString();

                final horario = _formatarHorario(
                  evento['occurredAt']?.toString(),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.circle, size: 8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label != null && label.isNotEmpty
                              ? '$label ($node)'
                              : node,
                        ),
                      ),
                      if (horario.isNotEmpty)
                        Text(
                          horario,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatarHorario(String? valor) {
    if (valor == null || valor.isEmpty) {
      return '';
    }

    final data = DateTime.tryParse(valor)?.toLocal();

    if (data == null) return '';

    final hora = data.hour.toString().padLeft(2, '0');

    final minuto = data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }
}

class _LinhaInformacao extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _LinhaInformacao({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: valor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(_descricao(status)),
    );
  }

  String _descricao(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Em andamento';

      case 'COMPLETED':
        return 'Concluída';

      case 'CANCELLED':
        return 'Cancelada';

      default:
        return status.isEmpty ? 'Desconhecido' : status;
    }
  }
}
