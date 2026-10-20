import 'dart:async';

import 'package:flutter/material.dart';

import 'controle_voz.dart';

class PainelVoz extends StatefulWidget {
  const PainelVoz({super.key, required this.controle});

  final ControleVoz controle;

  @override
  State<PainelVoz> createState() => _PainelVozState();
}

class _PainelVozState extends State<PainelVoz> with WidgetsBindingObserver {
  static const _azul = Color(0xFF102F46);
  static const _azulClaro = Color(0xFF1D5478);
  static const _verde = Color(0xFF16876D);

  ControleVoz get controle => widget.controle;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    controle.addListener(_atualizar);

    unawaited(controle.inicializar());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controle.definirAppEmPrimeiroPlano(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    controle.removeListener(_atualizar);

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
        return const Color(0xFFCC3D47);

      case EstadoVoz.processando:
        return const Color(0xFFD9822B);

      case EstadoVoz.respondendo:
        return _verde;

      case EstadoVoz.erro:
        return const Color(0xFFB63842);

      case EstadoVoz.pronto:
        return _azul;
    }
  }

  IconData get _icone {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return Icons.graphic_eq_rounded;

      case EstadoVoz.processando:
        return Icons.more_horiz_rounded;

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
        return 'Um momento';

      case EstadoVoz.respondendo:
        return 'Orientando você';

      case EstadoVoz.erro:
        return 'Não consegui ouvir';

      case EstadoVoz.pronto:
        return 'Para onde você quer ir?';
    }
  }

  String get _acao {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return 'FALE AGORA';

      case EstadoVoz.processando:
        return 'PROCESSANDO';

      case EstadoVoz.respondendo:
        return 'RESPONDENDO';

      case EstadoVoz.erro:
        return 'TOQUE PARA TENTAR NOVAMENTE';

      case EstadoVoz.pronto:
        return 'TOQUE PARA FALAR';
    }
  }

  bool get _podeTocar =>
      controle.estado == EstadoVoz.pronto ||
      controle.estado == EstadoVoz.ouvindo ||
      controle.estado == EstadoVoz.erro;

  @override
  Widget build(BuildContext context) {
    final cor = _cor;

    return Semantics(
      container: true,
      label:
          'Controle por voz. $_titulo. '
          '${controle.mensagem}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_azul, _azulClaro],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24102F46),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controle.mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              button: true,
              label: 'Falar com o NAVESCENCE',
              hint: 'Toque duas vezes para iniciar um comando de voz',
              child: GestureDetector(
                onTap: _podeTocar ? controle.alternarEscuta : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: controle.ouvindo ? 132 : 116,
                  height: controle.ouvindo ? 132 : 116,
                  decoration: BoxDecoration(
                    color: controle.estado == EstadoVoz.pronto
                        ? Colors.white
                        : cor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: controle.ouvindo
                            ? cor.withValues(alpha: 0.50)
                            : Colors.black.withValues(alpha: 0.15),
                        blurRadius: controle.ouvindo ? 30 : 18,
                        spreadRadius: controle.ouvindo ? 7 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _icone,
                    size: 54,
                    color: controle.estado == EstadoVoz.pronto
                        ? _azul
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _acao,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            if (controle.estado == EstadoVoz.pronto) ...[
              const SizedBox(height: 9),
              Text(
                'Ou simplesmente diga “Nave”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
