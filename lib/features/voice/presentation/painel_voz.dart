import 'package:flutter/material.dart';

import '../../navigation/presentation/controle_navegacao.dart';
import 'controle_voz.dart';

class PainelVoz extends StatefulWidget {
  const PainelVoz({
    super.key,
    required this.navegacao,
  });

  final ControleNavegacao navegacao;

  @override
  State<PainelVoz> createState() => _PainelVozState();
}

class _PainelVozState extends State<PainelVoz> {
  static const _azul = Color(0xFF183B56);

  late final ControleVoz controle;

  @override
  void initState() {
    super.initState();

    controle = ControleVoz(
      navegacao: widget.navegacao,
    );

    controle.addListener(_atualizar);
    controle.inicializar();
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

  String _tituloEstado() {
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
        return 'Fale com o NAVESCENCE';
    }
  }

  IconData _iconeEstado() {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return Icons.mic_rounded;

      case EstadoVoz.processando:
        return Icons.psychology_alt_outlined;

      case EstadoVoz.respondendo:
        return Icons.volume_up_rounded;

      case EstadoVoz.erro:
        return Icons.mic_off_rounded;

      case EstadoVoz.pronto:
        return Icons.mic_none_rounded;
    }
  }

  Color _corEstado() {
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

  bool get _podeClicar {
    return controle.estado == EstadoVoz.pronto ||
        controle.estado == EstadoVoz.ouvindo ||
        controle.estado == EstadoVoz.erro;
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corEstado();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(controle.estado),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconeEstado(),
                size: 30,
                color: cor,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _tituloEstado(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),

          const SizedBox(height: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              controle.mensagem,
              key: ValueKey(controle.mensagem),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: _podeClicar
                ? controle.alternarEscuta
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: controle.ouvindo ? 92 : 82,
              height: controle.ouvindo ? 92 : 82,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.25),
                    blurRadius: controle.ouvindo ? 18 : 10,
                    spreadRadius: controle.ouvindo ? 5 : 2,
                  ),
                ],
              ),
              child: Icon(
                _iconeEstado(),
                size: 38,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _textoBotao(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),

          if (controle.estado == EstadoVoz.pronto) ...[
            const SizedBox(height: 18),

            Divider(
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 10),

            Text(
              'Você pode dizer:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '“Me leva pra Maker”  •  '
              '“Onde estou?”  •  '
              '“Repete”  •  '
              '“O que tem perto?”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _textoBotao() {
    switch (controle.estado) {
      case EstadoVoz.ouvindo:
        return 'Toque para parar de ouvir';

      case EstadoVoz.processando:
        return 'Processando comando...';

      case EstadoVoz.respondendo:
        return 'NAVESCENCE está respondendo';

      case EstadoVoz.erro:
        return 'Toque para tentar novamente';

      case EstadoVoz.pronto:
        return 'Toque para falar';
    }
  }
}