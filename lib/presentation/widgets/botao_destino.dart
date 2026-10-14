import 'package:flutter/material.dart';

import '../../features/navigation/domain/entities/local.dart';

class BotaoDestino extends StatelessWidget {
  const BotaoDestino({
    super.key,
    required this.locais,
    required this.onDestinoSelecionado,
  });

  static const _azul = Color(0xFF102F46);
  static const _cinza = Color(0xFF6B7A83);

  final List<Local> locais;

  final Future<void> Function(Local local)
      onDestinoSelecionado;

  Future<void> _abrirDestinos(
    BuildContext context,
  ) async {
    final destino =
        await showModalBottomSheet<Local>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.40,
          maxChildSize: 0.92,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DDE1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      24,
                      22,
                      6,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Onde você quer ir?',
                        style: TextStyle(
                          color: _azul,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      16,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selecione um dos locais disponíveis.',
                        style: TextStyle(
                          color: _cinza,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        28,
                      ),
                      itemCount: locais.length,
                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 9,
                      ),
                      itemBuilder:
                          (context, index) {
                        final local =
                            locais[index];

                        return Semantics(
                          button: true,
                          label:
                              'Ir para ${local.nome}',
                          child: Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  local,
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration:
                                          BoxDecoration(
                                        color: _azul
                                            .withValues(
                                          alpha: 0.07,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                      child:
                                          const Icon(
                                        Icons
                                            .place_rounded,
                                        color: _azul,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    Expanded(
                                      child: Text(
                                        local.nome,
                                        style:
                                            const TextStyle(
                                          color: _azul,
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons
                                          .arrow_forward_ios_rounded,
                                      size: 17,
                                      color: _cinza,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (destino == null) return;

    await onDestinoSelecionado(
      destino,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escolher destino manualmente',
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: OutlinedButton.icon(
          onPressed: locais.isEmpty
              ? null
              : () =>
                  _abrirDestinos(context),
          icon: const Icon(
            Icons.map_outlined,
          ),
          label: const Text(
            'Escolher destino',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _azul,
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: Color(0xFFDDE5E9),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(17),
            ),
          ),
        ),
      ),
    );
  }
}