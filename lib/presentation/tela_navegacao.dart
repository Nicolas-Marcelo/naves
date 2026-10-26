import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/tela_perfil.dart';

import '../features/history/data/navigation_history_service.dart';
import '../features/history/presentation/tela_historico.dart';

import '../features/localization/presentation/localization_controller.dart';

import '../features/navigation/presentation/controle_navegacao.dart';

import '../features/voice/presentation/controle_voz.dart';

class TelaNavegacao extends StatefulWidget {
  const TelaNavegacao({
    super.key,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
    required this.historyService,
    required this.auth,
  });

  final LocalizationController localizacao;
  final ControleNavegacao navegacao;
  final ControleVoz controleVoz;
  final NavigationHistoryService historyService;
  final AuthController auth;

  @override
  State<TelaNavegacao> createState() => _TelaNavegacaoState();
}

class _TelaNavegacaoState extends State<TelaNavegacao> {
  static const _fundo = Color(0xFFF3F6F9);

  static const _azulEscuro = Color(0xFF0A2F49);
  static const _azulMedio = Color(0xFF145578);
  static const _azulClaro = Color(0xFF2176A5);

  static const _verde = Color(0xFF16876D);
  static const _vermelho = Color(0xFFC83D4D);
  static const _laranja = Color(0xFFD98932);

  @override
  void initState() {
    super.initState();

    widget.localizacao.addListener(_atualizar);
    widget.navegacao.addListener(_atualizar);
    widget.controleVoz.addListener(_atualizar);

    widget.localizacao.iniciar();

    Future.microtask(widget.controleVoz.inicializar);
  }

  @override
  void dispose() {
    widget.localizacao.removeListener(_atualizar);
    widget.navegacao.removeListener(_atualizar);
    widget.controleVoz.removeListener(_atualizar);

    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _acionarVoz() async {
    if (widget.controleVoz.estado == EstadoVoz.processando ||
        widget.controleVoz.estado == EstadoVoz.respondendo) {
      return;
    }

    await widget.controleVoz.alternarEscuta();
  }

  Future<void> _abrirHistorico() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaHistorico(service: widget.historyService),
      ),
    );
  }

  Future<void> _abrirPerfil() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TelaPerfil(auth: widget.auth)));
  }

  String get _destino {
    final destino = widget.navegacao.destino;

    if (destino == null) {
      return 'Nenhuma rota ativa';
    }

    return destino.nome;
  }

  String get _tituloBotao {
    switch (widget.controleVoz.estado) {
      case EstadoVoz.pronto:
        return 'Toque para falar';

      case EstadoVoz.ouvindo:
        return 'Estou ouvindo';

      case EstadoVoz.processando:
        return 'Entendendo';

      case EstadoVoz.respondendo:
        return 'Orientando você';

      case EstadoVoz.erro:
        return 'Tente novamente';
    }
  }

  String get _subtituloBotao {
    switch (widget.controleVoz.estado) {
      case EstadoVoz.pronto:
        return 'Informe para onde deseja ir';

      case EstadoVoz.ouvindo:
        return 'Fale o seu comando';

      case EstadoVoz.processando:
        return 'Aguarde um momento';

      case EstadoVoz.respondendo:
        return widget.controleVoz.mensagem;

      case EstadoVoz.erro:
        return 'Não foi possível compreender';
    }
  }

  IconData get _iconePrincipal {
    switch (widget.controleVoz.estado) {
      case EstadoVoz.pronto:
        return Icons.mic_rounded;

      case EstadoVoz.ouvindo:
        return Icons.graphic_eq_rounded;

      case EstadoVoz.processando:
        return Icons.more_horiz_rounded;

      case EstadoVoz.respondendo:
        return Icons.volume_up_rounded;

      case EstadoVoz.erro:
        return Icons.mic_off_rounded;
    }
  }

  List<Color> get _coresBotao {
    switch (widget.controleVoz.estado) {
      case EstadoVoz.pronto:
        return const [_azulEscuro, _azulMedio];

      case EstadoVoz.ouvindo:
        return const [Color(0xFF8E2534), _vermelho];

      case EstadoVoz.processando:
        return const [Color(0xFF9D571C), _laranja];

      case EstadoVoz.respondendo:
        return const [Color(0xFF0E604D), _verde];

      case EstadoVoz.erro:
        return const [Color(0xFF8E2534), _vermelho];
    }
  }

  Widget _cardDestino() {
    final temDestino = widget.navegacao.destino != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D102F46),
            blurRadius: 22,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_azulEscuro, _azulClaro],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              temDestino
                  ? Icons.navigation_rounded
                  : Icons.location_on_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temDestino ? 'SEU DESTINO' : 'NAVEGAÇÃO',
                  style: const TextStyle(
                    color: Color(0xFF82909A),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _destino,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _azulEscuro,
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circuloMicrofone() {
    final ouvindo = widget.controleVoz.estado == EstadoVoz.ouvindo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: ouvindo ? 150 : 136,
      height: ouvindo ? 150 : 136,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: ouvindo ? 104 : 94,
          height: ouvindo ? 104 : 94,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x24102F46),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Icon(_iconePrincipal, color: _coresBotao.last, size: 48),
        ),
      ),
    );
  }

  Widget _botaoPrincipal() {
    final podeTocar =
        widget.controleVoz.estado != EstadoVoz.processando &&
        widget.controleVoz.estado != EstadoVoz.respondendo;

    return Expanded(
      child: Semantics(
        button: true,
        label: _tituloBotao,
        hint: 'Toque duas vezes para falar com o NAVESCENCE',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: podeTocar
              ? () {
                  _acionarVoz();
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _coresBotao,
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: _coresBotao.last.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -60,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -90,
                  left: -75,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 36,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _circuloMicrofone(),

                        const SizedBox(height: 34),

                        Text(
                          _tituloBotao,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            _subtituloBotao,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.74),
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoRodape({
    required IconData icon,
    required String texto,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE1E8ED)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: _azulEscuro),

                const SizedBox(width: 8),

                Text(
                  texto,
                  style: const TextStyle(
                    color: _azulEscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rodape() {
    return Row(
      children: [
        _botaoRodape(
          icon: Icons.history_rounded,
          texto: 'Histórico',
          onPressed: () {
            _abrirHistorico();
          },
        ),

        const SizedBox(width: 10),

        _botaoRodape(
          icon: Icons.person_outline_rounded,
          texto: 'Minha conta',
          onPressed: () {
            _abrirPerfil();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            children: [
              _cardDestino(),

              const SizedBox(height: 15),

              _botaoPrincipal(),

              const SizedBox(height: 14),

              _rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
