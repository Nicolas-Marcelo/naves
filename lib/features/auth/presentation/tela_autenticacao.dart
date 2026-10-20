import 'package:flutter/material.dart';

import 'auth_controller.dart';

class TelaAutenticacao extends StatefulWidget {
  const TelaAutenticacao({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<TelaAutenticacao> createState() =>
      _TelaAutenticacaoState();
}

class _TelaAutenticacaoState
    extends State<TelaAutenticacao> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _cadastro = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _cadastroRealizado = false;
  bool _mostrarReenvio = false;
  bool _tentouEnviar = false;

  AuthController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();

    _controller.addListener(
      _atualizarTela,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      _atualizarTela,
    );

    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  void _atualizarTela() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _tentouEnviar = true;
      _mostrarReenvio = false;
    });

    _controller.limparErro();

    final formValido =
        _formKey.currentState?.validate() ?? false;

    if (!formValido) return;

    if (_cadastro) {
      await _realizarCadastro();
      return;
    }

    await _realizarLogin();
  }

  Future<void> _realizarLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final sucesso = await _controller.login(
      email: email,
      password: senha,
    );

    if (!mounted) return;

    if (sucesso) return;

    final erro = _controller.erro;

    if (
      erro ==
      'Confirme seu e-mail antes de entrar.'
    ) {
      setState(() {
        _mostrarReenvio = true;
      });
    }

    if (erro != null) {
      _mostrarMensagem(erro);
    }
  }

  Future<void> _realizarCadastro() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final sucesso = await _controller.register(
      name: nome,
      email: email,
      password: senha,
    );

    if (!mounted) return;

    if (sucesso) {
      setState(() {
        _cadastroRealizado = true;
        _cadastro = false;
        _mostrarReenvio = false;
        _tentouEnviar = false;

        _senhaController.clear();
        _confirmarSenhaController.clear();
      });

      _mostrarMensagem(
        'Conta criada. Confirme seu e-mail antes de entrar.',
      );

      return;
    }

    if (_controller.erro != null) {
      _mostrarMensagem(
        _controller.erro!,
      );
    }
  }

  Future<void> _reenviarVerificacao() async {
    final email = _emailController.text.trim();

    final erroEmail = _validarEmail(email);

    if (erroEmail != null) {
      _mostrarMensagem(
        'Informe um e-mail válido antes de reenviar a verificação.',
      );

      return;
    }

    final sucesso =
        await _controller.reenviarVerificacao(
      email,
    );

    if (!mounted) return;

    if (sucesso) {
      _mostrarMensagem(
        'Se o e-mail estiver cadastrado, uma nova verificação foi enviada.',
      );

      return;
    }

    if (_controller.erro != null) {
      _mostrarMensagem(
        _controller.erro!,
      );
    }
  }

  void _alternarModo() {
    FocusScope.of(context).unfocus();

    _controller.limparErro();

    setState(() {
      _cadastro = !_cadastro;
      _cadastroRealizado = false;
      _mostrarReenvio = false;
      _tentouEnviar = false;

      _senhaController.clear();
      _confirmarSenhaController.clear();
    });

    _formKey.currentState?.reset();
  }

  String? _validarNome(
    String? valor,
  ) {
    final nome = valor?.trim() ?? '';

    if (nome.isEmpty) {
      return 'Informe seu nome.';
    }

    if (nome.length < 2) {
      return 'O nome deve possuir pelo menos 2 caracteres.';
    }

    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(nome)) {
      return 'Informe um nome válido.';
    }

    return null;
  }

  String? _validarEmail(
    String? valor,
  ) {
    final email = valor?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    final regex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Informe um endereço de e-mail válido.';
    }

    return null;
  }

  String? _validarSenha(
    String? valor,
  ) {
    final senha = valor ?? '';

    if (senha.isEmpty) {
      return 'Informe sua senha.';
    }

    if (!_cadastro) {
      return null;
    }

    if (senha.length < 8) {
      return 'A senha deve possuir no mínimo 8 caracteres.';
    }

    if (!RegExp(r'[a-z]').hasMatch(senha)) {
      return 'Inclua pelo menos uma letra minúscula.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(senha)) {
      return 'Inclua pelo menos uma letra maiúscula.';
    }

    if (!RegExp(r'\d').hasMatch(senha)) {
      return 'Inclua pelo menos um número.';
    }

    return null;
  }

  String? _validarConfirmacaoSenha(
    String? valor,
  ) {
    if (!_cadastro) return null;

    final confirmacao = valor ?? '';

    if (confirmacao.isEmpty) {
      return 'Confirme sua senha.';
    }

    if (
      confirmacao !=
      _senhaController.text
    ) {
      return 'As senhas não coincidem.';
    }

    return null;
  }

  void _mostrarMensagem(
    String mensagem,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final carregando =
        _controller.carregando;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 440,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode:
                    _tentouEnviar
                        ? AutovalidateMode
                            .onUserInteraction
                        : AutovalidateMode
                            .disabled,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    const Icon(
                      Icons
                          .navigation_rounded,
                      size: 72,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      'NAVESCENCE',
                      textAlign:
                          TextAlign.center,
                      style:
                          Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      _cadastro
                          ? 'Crie sua conta para utilizar o sistema.'
                          : 'Entre para continuar sua navegação.',
                      textAlign:
                          TextAlign.center,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge,
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    if (_cadastro)
                      TextFormField(
                        controller:
                            _nomeController,
                        textInputAction:
                            TextInputAction
                                .next,
                        textCapitalization:
                            TextCapitalization
                                .words,
                        autofillHints:
                            const [
                          AutofillHints
                              .name,
                        ],
                        enabled:
                            !carregando,
                        validator:
                            _validarNome,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nome',
                          hintText:
                              'Seu nome',
                          prefixIcon:
                              Icon(
                            Icons
                                .person_outline,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                    if (_cadastro)
                      const SizedBox(
                        height: 16,
                      ),

                    TextFormField(
                      controller:
                          _emailController,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      textInputAction:
                          TextInputAction
                              .next,
                      autocorrect:
                          false,
                      enableSuggestions:
                          false,
                      autofillHints:
                          const [
                        AutofillHints
                            .email,
                      ],
                      enabled:
                          !carregando,
                      validator:
                          _validarEmail,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'E-mail',
                        hintText:
                            'nome@exemplo.com',
                        prefixIcon:
                            Icon(
                          Icons
                              .email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      controller:
                          _senhaController,
                      obscureText:
                          !_senhaVisivel,
                      textInputAction:
                          _cadastro
                              ? TextInputAction
                                  .next
                              : TextInputAction
                                  .done,
                      autofillHints:
                          _cadastro
                              ? const [
                                  AutofillHints
                                      .newPassword,
                                ]
                              : const [
                                  AutofillHints
                                      .password,
                                ],
                      enabled:
                          !carregando,
                      validator:
                          _validarSenha,
                      onChanged: (_) {
                        if (
                          _cadastro &&
                          _tentouEnviar
                        ) {
                          _formKey
                              .currentState
                              ?.validate();
                        }
                      },
                      onFieldSubmitted:
                          (_) {
                        if (!_cadastro) {
                          _enviar();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Senha',
                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_outline,
                        ),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon:
                            IconButton(
                          tooltip:
                              _senhaVisivel
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                          onPressed: () {
                            setState(() {
                              _senhaVisivel =
                                  !_senhaVisivel;
                            });
                          },
                          icon: Icon(
                            _senhaVisivel
                                ? Icons
                                    .visibility_off_outlined
                                : Icons
                                    .visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    if (_cadastro) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _confirmarSenhaController,
                        obscureText:
                            !_confirmarSenhaVisivel,
                        textInputAction:
                            TextInputAction
                                .done,
                        autofillHints:
                            const [
                          AutofillHints
                              .newPassword,
                        ],
                        enabled:
                            !carregando,
                        validator:
                            _validarConfirmacaoSenha,
                        onFieldSubmitted:
                            (_) =>
                                _enviar(),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Confirmar senha',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline,
                          ),
                          border:
                              const OutlineInputBorder(),
                          suffixIcon:
                              IconButton(
                            tooltip:
                                _confirmarSenhaVisivel
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                            onPressed:
                                () {
                              setState(() {
                                _confirmarSenhaVisivel =
                                    !_confirmarSenhaVisivel;
                              });
                            },
                            icon:
                                Icon(
                              _confirmarSenhaVisivel
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'A senha deve possuir no mínimo 8 caracteres, '
                        'com pelo menos uma letra maiúscula, uma minúscula e um número.',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodySmall,
                      ),
                    ],

                    if (_cadastroRealizado) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(
                          14,
                        ),
                        decoration:
                            BoxDecoration(
                          border:
                              Border.all(
                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .primary,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child:
                            const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Icon(
                              Icons
                                  .mark_email_read_outlined,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                                  Text(
                                'Cadastro realizado. Confirme o endereço de '
                                'e-mail antes de fazer login.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (
                      _controller.erro !=
                      null
                    ) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      Semantics(
                        liveRegion:
                            true,
                        child: Text(
                          _controller
                              .erro!,
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              TextStyle(
                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .error,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ],

                    if (
                      _mostrarReenvio
                    ) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      TextButton.icon(
                        onPressed:
                            carregando
                                ? null
                                : _reenviarVerificacao,
                        icon:
                            const Icon(
                          Icons
                              .forward_to_inbox_outlined,
                        ),
                        label:
                            const Text(
                          'Reenviar e-mail de verificação',
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ),

                    FilledButton(
                      onPressed:
                          carregando
                              ? null
                              : _enviar,
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical:
                              14,
                        ),
                        child:
                            carregando
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : Text(
                                    _cadastro
                                        ? 'Criar conta'
                                        : 'Entrar',
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextButton(
                      onPressed:
                          carregando
                              ? null
                              : _alternarModo,
                      child: Text(
                        _cadastro
                            ? 'Já possui uma conta? Entrar'
                            : 'Ainda não possui conta? Criar conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}