import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/localization/presentation/localization_controller.dart';
import '../features/navigation/domain/entities/local.dart';
import '../features/navigation/presentation/controle_navegacao.dart';
import '../features/navigation/presentation/mapa_ambiente.dart';
import '../features/voice/presentation/painel_voz.dart';
import 'tela_diagnostico.dart';

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
  static const _azul = Color(0xFF183B56);
  static const _azulClaro = Color(0xFFEAF2F8);
  static const _verde = Color(0xFF14866D);
  static const _cinzaFundo = Color(0xFFF5F7F9);

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

  void _abrirDiagnostico() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaDiagnostico(
          localizacao: widget.localizacao,
        ),
      ),
    );
  }

  String _nomeDoPonto(String pontoId) {
    for (final local in widget.navegacao.locais) {
      if (local.pontoId == pontoId) {
        return local.nome;
      }
    }

    return pontoId;
  }

  String _nomeEstado(String estado) {
    switch (estado) {
      case 'DESTINO_SELECIONADO':
        return 'Destino selecionado';

      case 'ROTA_ATIVA':
        return 'Navegação em andamento';

      case 'ROTA_RECALCULADA':
        return 'Rota recalculada';

      case 'DESTINO_ALCANCADO':
        return 'Destino alcançado';

      case 'SEM_CAMINHO':
        return 'Rota não encontrada';

      default:
        return 'Aguardando navegação';
    }
  }

  IconData _iconeEstado(String estado) {
    switch (estado) {
      case 'ROTA_ATIVA':
        return Icons.navigation_rounded;

      case 'ROTA_RECALCULADA':
        return Icons.alt_route_rounded;

      case 'DESTINO_ALCANCADO':
        return Icons.flag_rounded;

      case 'SEM_CAMINHO':
        return Icons.warning_amber_rounded;

      default:
        return Icons.route_rounded;
    }
  }

  Color _corEstado(String estado) {
    switch (estado) {
      case 'DESTINO_ALCANCADO':
        return _verde;

      case 'SEM_CAMINHO':
        return Colors.red.shade700;

      default:
        return _azul;
    }
  }

  Widget _cabecalho() {
    final ponto = widget.localizacao.noAtual;
    final localizado = ponto.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: localizado
                  ? _verde.withValues(alpha: 0.12)
                  : _azulClaro,
              shape: BoxShape.circle,
            ),
            child: Icon(
              localizado
                  ? Icons.location_on_rounded
                  : Icons.location_searching_rounded,
              size: 34,
              color: localizado ? _verde : _azul,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            localizado
                ? 'Você está em'
                : 'Localizando você...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            localizado
                ? _nomeDoPonto(ponto)
                : 'Aguarde um momento',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _azul,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: localizado
                      ? _verde
                      : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                localizado
                    ? 'Localização identificada'
                    : 'Buscando sinal dos pontos',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _painelSimulacao() {
    if (!kIsWeb || !widget.localizacao.modoSimulacao) {
      return const SizedBox.shrink();
    }

    final atual = widget.localizacao.noAtual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD780),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Color(0xFF9A6700),
              ),
              SizedBox(width: 8),
              Text(
                'Modo de simulação',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A5200),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Selecione o ponto onde o usuário deve estar.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7A6740),
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ponto in [
                'S1',
                'S2',
                'S3',
                'S4',
                'S5',
              ])
                ChoiceChip(
                  label: Text(ponto),
                  selected: atual == ponto,
                  onSelected: (_) {
                    widget.localizacao.simularPonto(ponto);
                  },
                ),
            ],
          ),

          if (atual.isNotEmpty) ...[
            const SizedBox(height: 12),

            Text(
              'Ponto simulado atual: $atual',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A5200),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seletorDestino() {
    final navegacao = widget.navegacao;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Para onde você deseja ir?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _azul,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Você também pode selecionar o destino manualmente.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<Local>(
            key: ValueKey(
              navegacao.destino?.pontoId,
            ),
            initialValue: navegacao.destino,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
            ),
            decoration: InputDecoration(
              labelText: 'Destino',
              prefixIcon: const Icon(
                Icons.place_outlined,
              ),
              filled: true,
              fillColor: _cinzaFundo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _azul,
                  width: 1.5,
                ),
              ),
            ),
            items: navegacao.locais.map((local) {
              return DropdownMenuItem(
                value: local,
                child: Text(local.nome),
              );
            }).toList(),
            onChanged: navegacao.selecionarDestino,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: navegacao.iniciarRota,
              icon: const Icon(
                Icons.navigation_rounded,
              ),
              label: const Text(
                'INICIAR NAVEGAÇÃO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orientacao() {
    final navegacao = widget.navegacao;
    final cor = _corEstado(navegacao.estado);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cor.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _iconeEstado(navegacao.estado),
                  color: cor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeEstado(navegacao.estado),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cor,
                      ),
                    ),

                    if (navegacao.destino != null)
                      Text(
                        'Destino: ${navegacao.destino!.nome}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Orientação atual',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            navegacao.orientacaoAtual,
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),

          if (navegacao.proximoPonto != null) ...[
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: _azul,
                ),

                const SizedBox(width: 7),

                Text(
                  'Próximo ponto: ${navegacao.proximoPonto}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                navegacao.repetirOrientacao();
              },
              icon: const Icon(
                Icons.volume_up_rounded,
              ),
              label: const Text(
                'REPETIR ORIENTAÇÃO',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _azul,
                side: BorderSide(
                  color: _azul.withValues(alpha: 0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rota() {
    final rota = widget.navegacao.rota;

    if (rota == null) {
      return const SizedBox.shrink();
    }

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
              Icon(
                Icons.route_rounded,
                color: _azul,
              ),

              SizedBox(width: 8),

              Text(
                'Sua rota',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            rota.pontos.join(' → '),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _azul,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 20,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 7),

              Text(
                'Distância aproximada: '
                '${rota.distancia.toStringAsFixed(1)} m',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cancelarRota() {
    if (widget.navegacao.destino == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: widget.navegacao.cancelarRota,
        icon: const Icon(
          Icons.close_rounded,
        ),
        label: const Text(
          'CANCELAR NAVEGAÇÃO',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(
            color: Colors.red.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rota = widget.navegacao.rota;

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
              'NAVESCENCE',
              style: TextStyle(
                color: _azul,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Navegação assistiva',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Diagnóstico',
            icon: const Icon(
              Icons.monitor_heart_outlined,
              color: _azul,
            ),
            onPressed: _abrirDiagnostico,
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            28,
          ),
          children: [
            _cabecalho(),

            const SizedBox(height: 16),

            PainelVoz(
              navegacao: widget.navegacao,
            ),

            if (kIsWeb &&
                widget.localizacao.modoSimulacao) ...[
              const SizedBox(height: 16),

              _painelSimulacao(),
            ],

            const SizedBox(height: 16),

            _seletorDestino(),

            const SizedBox(height: 16),

            _orientacao(),

            const SizedBox(height: 16),

            MapaAmbiente(
              grafo: widget.navegacao.grafo,
              pontoAtual: widget.localizacao.noAtual,
              rota: rota?.pontos,
              destino: widget.navegacao.destino?.pontoId,
            ),

            if (rota != null) ...[
              const SizedBox(height: 16),

              _rota(),
            ],

            if (widget.navegacao.destino != null) ...[
              const SizedBox(height: 16),

              _cancelarRota(),
            ],
          ],
        ),
      ),
    );
  }
}