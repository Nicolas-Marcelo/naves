import 'package:flutter/material.dart';

import '../features/localization/presentation/localization_controller.dart';
import '../features/navigation/domain/entities/local.dart';
import '../features/navigation/presentation/controle_navegacao.dart';
import '../features/voice/presentation/controle_voz.dart';
import '../features/voice/presentation/painel_voz.dart';

import 'widgets/botao_destino.dart';
import 'widgets/card_localizacao.dart';
import 'widgets/card_navegacao.dart';

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
  State<TelaNavegacao> createState() =>
      _TelaNavegacaoState();
}

class _TelaNavegacaoState
    extends State<TelaNavegacao> {
  static const _azul = Color(0xFF102F46);
  static const _fundo = Color(0xFFF3F6F8);

  bool get _navegando =>
      widget.navegacao.destino != null;

  @override
  void initState() {
    super.initState();

    widget.localizacao.addListener(
      _atualizar,
    );

    widget.navegacao.addListener(
      _atualizar,
    );

    widget.localizacao.iniciar();
  }

  @override
  void dispose() {
    widget.localizacao.removeListener(
      _atualizar,
    );

    widget.navegacao.removeListener(
      _atualizar,
    );

    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _selecionarDestino(
    Local local,
  ) async {
    widget.navegacao.selecionarDestino(
      local,
    );

    await widget.navegacao.iniciarRota();
  }

  Widget _cabecalho() {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: _azul,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'NAVESCENCE',
                style: TextStyle(
                  color: _azul,
                  fontSize: 20,
                  height: 1,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Navegação assistiva indoor',
                style: TextStyle(
                  color: Color(0xFF71818A),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: const Color(0xFFE3E9EC),
            ),
          ),
          child: const Icon(
            Icons.accessibility_new_rounded,
            color: _azul,
            size: 21,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: ListView(
          physics:
              const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            32,
          ),
          children: [
            _cabecalho(),

            const SizedBox(height: 24),

            CardLocalizacao(
              pontoAtual:
                  widget.localizacao.noAtual,
              locais:
                  widget.navegacao.locais,
            ),

            const SizedBox(height: 16),

            if (!_navegando)
              PainelVoz(
                controle:
                    widget.controleVoz,
              ),

            if (_navegando)
              CardNavegacao(
                navegacao:
                    widget.navegacao,
              ),

            const SizedBox(height: 16),

            if (!_navegando)
              BotaoDestino(
                locais:
                    widget.navegacao.locais,
                onDestinoSelecionado:
                    _selecionarDestino,
              ),

            if (!_navegando) ...[
              const SizedBox(height: 24),

              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Color(
                        0xFFDDE4E8,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      'DICA',
                      style: TextStyle(
                        color: Color(
                          0xFF87949B,
                        ),
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(
                        0xFFDDE4E8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              const Text(
                'Você pode navegar usando apenas a voz. '
                'Diga “Nave” e informe o local para onde deseja ir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF74838B),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}