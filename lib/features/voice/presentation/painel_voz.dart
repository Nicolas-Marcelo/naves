import 'dart:async';

import 'package:flutter/material.dart';

import 'controle_voz.dart';

class PainelVoz extends StatefulWidget {
  const PainelVoz({
    super.key,
    required this.controle,
  });

  final ControleVoz controle;

  @override
  State<PainelVoz> createState() =>
      _PainelVozState();
}

class _PainelVozState
    extends State<PainelVoz>
    with WidgetsBindingObserver {
  static const _azul =
      Color(0xFF183B56);

  ControleVoz get controle =>
      widget.controle;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(
      this,
    );

    controle.addListener(
      _atualizar,
    );

    unawaited(
      controle.inicializar(),
    );
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    final primeiroPlano =
        state ==
        AppLifecycleState.resumed;

    controle
        .definirAppEmPrimeiroPlano(
      primeiroPlano,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(
      this,
    );

    controle.removeListener(
      _atualizar,
    );

    super.dispose();
  }

  void _atualizar() {
    if (mounted) {
      setState(() {});
    }
  }

  Color get _cor {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return Colors.red.shade600;

      case EstadoVoz.processando:
        return Colors.orange.shade700;

      case EstadoVoz.respondendo:
        return Colors.green.shade700;

      case EstadoVoz.erro:
        return Colors.red.shade700;

      case EstadoVoz.pronto:
        return _azul;
    }
  }

  IconData get _icone {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return Icons.mic_rounded;

      case EstadoVoz.processando:
        return Icons.psychology_alt_rounded;

      case EstadoVoz.respondendo:
        return Icons.volume_up_rounded;

      case EstadoVoz.erro:
        return Icons.mic_off_rounded;

      case EstadoVoz.pronto:
        return Icons.mic_rounded;
    }
  }

  String get _titulo {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return 'Estou ouvindo';

      case EstadoVoz.processando:
        return 'Entendendo';

      case EstadoVoz.respondendo:
        return 'Respondendo';

      case EstadoVoz.erro:
        return 'Não consegui ouvir';

      case EstadoVoz.pronto:
        return 'Para onde você quer ir?';
    }
  }

  bool get _podeTocar =>
      controle.estado ==
          EstadoVoz.pronto ||
      controle.estado ==
          EstadoVoz.ouvindo ||
      controle.estado ==
          EstadoVoz.erro;

  @override
  Widget build(
    BuildContext context,
  ) {
    final cor =
        _cor;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        children: [
          Text(
            _titulo,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w700,
              color: _azul,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            controle.mensagem,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          Semantics(
            button: true,
            label:
                'Falar com o NAVESCENCE',
            hint:
                'Toque duas vezes para falar um comando',
            child: GestureDetector(
              onTap: _podeTocar
                  ? controle
                      .alternarEscuta
                  : null,
              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 250,
                ),
                width: controle.ouvindo
                    ? 118
                    : 108,
                height: controle.ouvindo
                    ? 118
                    : 108,
                decoration:
                    BoxDecoration(
                  color: cor,
                  shape:
                      BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          cor.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius:
                          controle.ouvindo
                              ? 24
                              : 14,
                      spreadRadius:
                          controle.ouvindo
                              ? 6
                              : 2,
                    ),
                  ],
                ),
                child: Icon(
                  _icone,
                  size: 52,
                  color:
                      Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            controle.ouvindo
                ? 'FALE AGORA'
                : 'TOQUE PARA FALAR',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
              color: cor,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          if (controle.estado ==
              EstadoVoz.pronto)
            Text(
              'Com o aplicativo ativo, você também pode dizer “Nave”',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}