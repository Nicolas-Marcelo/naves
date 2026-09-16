import 'package:flutter/material.dart';

import '../features/localization/presentation/localization_controller.dart';
import '../features/navigation/domain/entities/local.dart';
import '../features/navigation/presentation/controle_navegacao.dart';
import '../features/voice/presentation/controle_voz.dart';
import '../features/voice/presentation/painel_voz.dart';

class TelaNavegacao extends StatefulWidget {
  const TelaNavegacao({
    super.key,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
  });

  final LocalizationController localizacao;

  final ControleNavegacao navegacao;

  final ControleVoz controleVoz;

  @override
  State<TelaNavegacao> createState() => _TelaNavegacaoState();
}

class _TelaNavegacaoState extends State<TelaNavegacao> {
  static const _azul = Color(0xFF183B56);

  static const _verde = Color(0xFF14866D);

  static const _fundo = Color(0xFFF5F7F9);

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
    if (mounted) {
      setState(() {});
    }
  }

  List<String> _locaisDoPonto(String ponto) {
    return widget.navegacao.locais
        .where((local) => local.pontoId == ponto)
        .map((local) => local.nome)
        .toList();
  }

  String _juntarNomes(List<String> nomes) {
    if (nomes.isEmpty) {
      return '';
    }

    if (nomes.length == 1) {
      return nomes.first;
    }

    if (nomes.length == 2) {
      return '${nomes[0]} e ${nomes[1]}';
    }

    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  String _localizacaoAtual() {
    final ponto = widget.localizacao.noAtual;

    if (ponto.isEmpty) {
      return 'Localizando você...';
    }

    final locais = _locaisDoPonto(ponto);

    if (locais.isEmpty) {
      return 'Localização identificada';
    }

    return _juntarNomes(locais);
  }

  Widget _localizacao() {
    final localizado = widget.localizacao.noAtual.isNotEmpty;

    return Semantics(
      label: localizado
          ? 'Você está próximo de ${_localizacaoAtual()}'
          : 'Localizando você',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: localizado
                    ? _verde.withValues(alpha: 0.12)
                    : _azul.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                localizado
                    ? Icons.location_on_rounded
                    : Icons.location_searching_rounded,
                color: localizado ? _verde : _azul,
                size: 31,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizado ? 'Você está próximo de' : 'Sua localização',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _localizacaoAtual(),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _azul,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navegacaoAtual() {
    final navegacao = widget.navegacao;

    if (navegacao.destino == null) {
      return const SizedBox.shrink();
    }

    final chegou = navegacao.estado == 'DESTINO_ALCANCADO';

    final cor = chegou ? _verde : _azul;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                chegou ? Icons.flag_rounded : Icons.navigation_rounded,
                color: cor,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  chegou ? 'Destino alcançado' : 'Indo para',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            navegacao.destino!.nome,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: _azul,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            chegou ? 'Você chegou.' : navegacao.orientacaoAtual,
            style: const TextStyle(
              fontSize: 23,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () {
                navegacao.repetirOrientacao();
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text(
                'REPETIR ORIENTAÇÃO',
                style: TextStyle(fontWeight: FontWeight.w700),
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

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                navegacao.cancelarRota();
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('CANCELAR NAVEGAÇÃO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
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

  Future<void> _abrirDestinos() async {
    final destino = await showModalBottomSheet<Local>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha um destino',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _azul,
                  ),
                ),

                const SizedBox(height: 12),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 430),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.navegacao.locais.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final local = widget.navegacao.locais[index];

                      return ListTile(
                        leading: const Icon(Icons.place_outlined, color: _azul),
                        title: Text(local.nome),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context, local);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (destino == null) {
      return;
    }

    widget.navegacao.selecionarDestino(destino);

    widget.navegacao.iniciarRota();
  }

  Widget _destinoManual() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _abrirDestinos,
        icon: const Icon(Icons.touch_app_rounded),
        label: const Text(
          'ESCOLHER DESTINO MANUALMENTE',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _azul,
          backgroundColor: Colors.white,
          side: BorderSide(color: _azul.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: _fundo,
        elevation: 0,
        centerTitle: false,
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _localizacao(),

            const SizedBox(height: 16),

            PainelVoz(controle: widget.controleVoz),

            if (widget.navegacao.destino != null) ...[
              const SizedBox(height: 16),

              _navegacaoAtual(),
            ],

            const SizedBox(height: 16),

            _destinoManual(),
          ],
        ),
      ),
    );
  }
}
