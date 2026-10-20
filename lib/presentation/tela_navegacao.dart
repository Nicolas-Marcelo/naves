import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/tela_perfil.dart';

import '../features/history/data/navigation_history_service.dart';
import '../features/history/presentation/tela_historico.dart';

import '../features/localization/presentation/localization_controller.dart';

import '../features/navigation/domain/entities/local.dart';
import '../features/navigation/presentation/controle_navegacao.dart';

import '../features/voice/presentation/controle_voz.dart';
import '../features/voice/presentation/painel_voz.dart';

import 'widgets/botao_destino.dart';
import 'widgets/card_localizacao.dart';
import 'widgets/card_navegacao.dart';

class TelaNavegacao
    extends StatefulWidget {
  const TelaNavegacao({
    super.key,
    required this.localizacao,
    required this.navegacao,
    required this.controleVoz,
    required this.historyService,
    required this.auth,
  });

  final LocalizationController
      localizacao;

  final ControleNavegacao
      navegacao;

  final ControleVoz controleVoz;

  final NavigationHistoryService
      historyService;

  final AuthController auth;

  @override
  State<TelaNavegacao> createState() =>
      _TelaNavegacaoState();
}

class _TelaNavegacaoState
    extends State<TelaNavegacao> {
  static const _azul =
      Color(0xFF102F46);

  static const _fundo =
      Color(0xFFF3F6F8);

  bool get _navegando =>
      widget.navegacao.destino !=
      null;

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
    widget.localizacao
        .removeListener(
      _atualizar,
    );

    widget.navegacao
        .removeListener(
      _atualizar,
    );

    super.dispose();
  }

  void _atualizar() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      _selecionarDestino(
    Local local,
  ) async {
    widget.navegacao
        .selecionarDestino(
      local,
    );

    await widget.navegacao
        .iniciarRota();
  }

  Future<void>
      _abrirHistorico() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TelaHistorico(
          service:
              widget.historyService,
        ),
      ),
    );
  }

  Future<void>
      _abrirPerfil() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TelaPerfil(
          auth: widget.auth,
        ),
      ),
    );
  }

  Widget _botaoCabecalho({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color:
                    const Color(
                  0xFFE3E9EC,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: _azul,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final user =
        widget.auth.user;

    final inicial =
        user != null &&
                user.name
                    .trim()
                    .isNotEmpty
            ? user.name
                .trim()
                .substring(
                  0,
                  1,
                )
                .toUpperCase()
            : null;

    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration:
              BoxDecoration(
            color: _azul,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child:
              const Center(
            child: Text(
              'N',
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 25,
                fontWeight:
                    FontWeight
                        .w900,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'NAVESCENCE',
                style:
                    TextStyle(
                  color: _azul,
                  fontSize: 20,
                  height: 1,
                  letterSpacing:
                      0.8,
                  fontWeight:
                      FontWeight
                          .w900,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                'Navegação assistiva indoor',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF71818A,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        _botaoCabecalho(
          icon:
              Icons.history_rounded,
          tooltip:
              'Histórico de navegação',
          onPressed: () {
            _abrirHistorico();
          },
        ),

        const SizedBox(
          width: 8,
        ),

        Tooltip(
          message:
              'Minha conta',
          child: Material(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child: InkWell(
              onTap: () {
                _abrirPerfil();
              },
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE3E9EC,
                    ),
                  ),
                ),
                alignment:
                    Alignment.center,
                child:
                    inicial != null
                        ? Text(
                            inicial,
                            style:
                                const TextStyle(
                              color:
                                  _azul,
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          )
                        : const Icon(
                            Icons
                                .person_outline,
                            color:
                                _azul,
                            size:
                                21,
                          ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: ListView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets
                  .fromLTRB(
            18,
            18,
            18,
            32,
          ),
          children: [
            _cabecalho(),

            const SizedBox(
              height: 24,
            ),

            CardLocalizacao(
              pontoAtual:
                  widget.localizacao
                      .noAtual,
              locais:
                  widget.navegacao
                      .locais,
            ),

            const SizedBox(
              height: 16,
            ),

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

            const SizedBox(
              height: 16,
            ),

            if (!_navegando)
              BotaoDestino(
                locais:
                    widget.navegacao
                        .locais,
                onDestinoSelecionado:
                    _selecionarDestino,
              ),

            if (!_navegando) ...[
              const SizedBox(
                height: 24,
              ),

              const Row(
                children: [
                  Expanded(
                    child:
                        Divider(
                      color:
                          Color(
                        0xFFDDE4E8,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets
                            .symmetric(
                      horizontal:
                          12,
                    ),
                    child:
                        Text(
                      'DICA',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFF87949B,
                        ),
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            1,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        Divider(
                      color:
                          Color(
                        0xFFDDE4E8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 13,
              ),

              const Text(
                'Você pode navegar usando apenas a voz. '
                'Diga “Nave” e informe o local para onde deseja ir.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF74838B,
                  ),
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