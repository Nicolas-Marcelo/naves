import 'package:flutter/material.dart';

import '../../features/navigation/presentation/controle_navegacao.dart';

class CardNavegacao extends StatelessWidget {
  const CardNavegacao({
    super.key,
    required this.navegacao,
  });

  static const _azul = Color(0xFF102F46);
  static const _azulClaro = Color(0xFF1D5478);
  static const _verde = Color(0xFF16876D);
  static const _fundo = Color(0xFFF5F8FA);

  final ControleNavegacao navegacao;

  bool get chegou =>
      navegacao.estado == 'DESTINO_ALCANCADO';

  IconData _iconeOrientacao() {
    final texto = navegacao.orientacaoAtual.toLowerCase();

    if (texto.contains('direita')) {
      return Icons.turn_right_rounded;
    }

    if (texto.contains('esquerda')) {
      return Icons.turn_left_rounded;
    }

    if (chegou) {
      return Icons.flag_rounded;
    }

    return Icons.arrow_upward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (navegacao.destino == null) {
      return const SizedBox.shrink();
    }

    final corPrincipal =
        chegou ? _verde : _azul;

    return Semantics(
      container: true,
      label: chegou
          ? 'Destino alcançado. ${navegacao.destino!.nome}.'
          : 'Navegando para ${navegacao.destino!.nome}. '
              '${navegacao.orientacaoAtual}',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE3E9EC),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                20,
                22,
                18,
              ),
              decoration: BoxDecoration(
                color: corPrincipal,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(27),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chegou
                        ? 'VOCÊ CHEGOU'
                        : 'NAVEGANDO PARA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    navegacao.destino!.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: chegou
                          ? _verde.withValues(alpha: 0.10)
                          : _azulClaro.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconeOrientacao(),
                      size: 68,
                      color: chegou ? _verde : _azul,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    chegou
                        ? 'Destino alcançado'
                        : navegacao.orientacaoAtual,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _azul,
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!chegou &&
                      navegacao.proximoPonto != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _fundo,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Próximo: ${navegacao.proximoPonto}',
                        style: const TextStyle(
                          color: Color(0xFF647580),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton.icon(
                      onPressed:
                          navegacao.repetirOrientacao,
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        size: 24,
                      ),
                      label: const Text(
                        'Repetir orientação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _azul,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed:
                          navegacao.cancelarRota,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                      label: const Text(
                        'Cancelar navegação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
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
}