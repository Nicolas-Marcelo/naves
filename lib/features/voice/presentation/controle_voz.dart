import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../accessibility/data/servico_feedback_tatil.dart';
import '../../navigation/domain/entities/local.dart';
import '../../navigation/presentation/controle_navegacao.dart';
import '../data/servico_wake_word.dart';

enum EstadoVoz {
  pronto,
  ouvindo,
  processando,
  respondendo,
  erro,
}

class ControleVoz extends ChangeNotifier {
  ControleVoz({
    required this.navegacao,
    required this.wakeWord,
    required this.feedbackTatil,
  });

  final ControleNavegacao navegacao;
  final ServicoWakeWord wakeWord;
  final ServicoFeedbackTatil feedbackTatil;

  EstadoVoz estado = EstadoVoz.pronto;

  String textoReconhecido = '';
  String mensagem = 'Diga "Nave" ou toque no microfone.';

  bool _inicializado = false;
  bool _processando = false;
  bool _interacaoAtiva = false;
  bool _appEmPrimeiroPlano = true;

  int _tentativas = 0;

  Local? _destinoPendente;

  DateTime? _ultimoWakeRecebido;

  static const int _maxTentativas = 2;

  /*
   * >= 0.97
   * Correspondência praticamente direta.
   */
  static const double _confiancaDireta = 0.97;

  /*
   * >= 0.82 + diferença segura para o segundo.
   * Pode executar sem confirmação.
   */
  static const double _confiancaAlta = 0.82;

  /*
   * Entre 0.60 e 0.81.
   * Pergunta ao usuário.
   */
  static const double _confiancaConfirmacao = 0.60;

  /*
   * Evita aceitar dois locais muito parecidos.
   */
  static const double _margemEntreCandidatos = 0.12;

  bool get ouvindo =>
      estado == EstadoVoz.ouvindo;

  bool get _rotaAtiva {
    return navegacao.estado == 'ROTA_ATIVA' ||
        navegacao.estado == 'ROTA_RECALCULADA';
  }

  Future<void> inicializar() async {
    if (!_inicializado) {
      _inicializado = true;

      navegacao.addListener(
        _navegacaoMudou,
      );
    }

    estado = EstadoVoz.pronto;
    mensagem = 'Diga "Nave" ou toque no microfone.';

    notifyListeners();

    await retomarModoAutomatico();
  }

  void definirAppEmPrimeiroPlano(
    bool ativo,
  ) {
    if (_appEmPrimeiroPlano == ativo) {
      return;
    }

    _appEmPrimeiroPlano = ativo;

    debugPrint(
      '[VOZ] App em primeiro plano: $ativo',
    );

    unawaited(
      retomarModoAutomatico(),
    );
  }

  void _navegacaoMudou() {
    if (_interacaoAtiva) return;

    unawaited(
      retomarModoAutomatico(),
    );
  }

  Future<void> retomarModoAutomatico() async {
    if (_interacaoAtiva ||
        _processando ||
        estado == EstadoVoz.ouvindo ||
        estado == EstadoVoz.processando ||
        estado == EstadoVoz.respondendo) {
      return;
    }

    if (_appEmPrimeiroPlano ||
        _rotaAtiva) {
      await wakeWord.ouvir();

      debugPrint(
        '[VOZ] Espera: WAKE RESTRITO',
      );
    } else {
      await wakeWord.desligar();

      debugPrint(
        '[VOZ] Espera: DESLIGADO',
      );
    }
  }

  Future<void> palavraChaveDetectada() async {
    final agora = DateTime.now();

    if (_ultimoWakeRecebido != null &&
        agora.difference(
              _ultimoWakeRecebido!,
            ) <
            const Duration(
              milliseconds: 1200,
            )) {
      return;
    }

    if (_interacaoAtiva ||
        _processando) {
      return;
    }

    _ultimoWakeRecebido = agora;

    _interacaoAtiva = true;
    _tentativas = 0;
    _destinoPendente = null;

    textoReconhecido = '';

    await navegacao.pararVoz();

    estado = EstadoVoz.ouvindo;
    mensagem = 'Estou ouvindo...';

    notifyListeners();

    await wakeWord.ouvirComando();
  }

  Future<void> alternarEscuta() async {
    if (_processando) return;

    if (estado == EstadoVoz.ouvindo) {
      _interacaoAtiva = false;
      _destinoPendente = null;
      _tentativas = 0;

      estado = EstadoVoz.pronto;
      mensagem = 'Diga "Nave" ou toque no microfone.';

      notifyListeners();

      await retomarModoAutomatico();

      return;
    }

    _interacaoAtiva = true;

    await wakeWord.desligar();
    await navegacao.pararVoz();

    _destinoPendente = null;
    _tentativas = 0;

    textoReconhecido = '';

    await feedbackTatil.executar(
      FeedbackTatil.ativacao,
    );

    estado = EstadoVoz.ouvindo;
    mensagem = 'Estou ouvindo...';

    notifyListeners();

    await wakeWord.ouvirComando();
  }

  Future<void> processarComandoExterno(
    String texto,
  ) async {
    if (_processando) return;

    _interacaoAtiva = true;

    final bruto = texto.trim();

    if (bruto.isEmpty) {
      await processarTimeoutExterno();
      return;
    }

    textoReconhecido = bruto;
    mensagem = bruto;

    _logInicioTeste(
      bruto,
    );

    notifyListeners();

    await _processarComando(
      bruto,
    );
  }

  Future<void> processarTimeoutExterno() async {
    if (_processando) return;

    _interacaoAtiva = true;
    _processando = true;

    debugPrint('');
    debugPrint('========== TESTE DE VOZ ==========');
    debugPrint('[VOZ][BRUTO] <silêncio>');
    debugPrint('[VOZ][DECISAO] TIMEOUT');
    debugPrint('===================================');
    debugPrint('');

    estado = EstadoVoz.processando;
    mensagem = 'Não ouvi nenhuma fala.';

    notifyListeners();

    await _tratarFalha(
      semAudio: true,
    );
  }

  void _logInicioTeste(
    String bruto,
  ) {
    debugPrint('');
    debugPrint('========== TESTE DE VOZ ==========');

    debugPrint(
      '[VOZ][BRUTO] $bruto',
    );

    debugPrint(
      '[VOZ][NORMALIZADO] ${_normalizar(bruto)}',
    );
  }

  void _logFimTeste() {
    debugPrint(
      '===================================',
    );

    debugPrint('');
  }

  Future<void> _processarComando(
    String texto,
  ) async {
    if (_processando) return;

    _processando = true;

    final comando = _normalizar(
      texto,
    );

    estado = EstadoVoz.processando;
    mensagem = 'Entendendo...';

    notifyListeners();

    if (_destinoPendente != null) {
      debugPrint(
        '[VOZ][CONTEXTO] confirmação de destino',
      );

      await _processarConfirmacao(
        comando,
      );

      return;
    }

    if (_comandoAjuda(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] AJUDA',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      await _responder(
        'Você pode pedir um destino, perguntar onde está, '
        'perguntar o que há por perto, perguntar para onde está indo, '
        'repetir a orientação ou cancelar a navegação.',
      );

      return;
    }

    if (_comandoEstouPerdido(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] ESTOU_PERDIDO',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      await _responder(
        navegacao.descricaoSituacaoAtual(),
      );

      return;
    }

    if (_comandoRepetir(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] REPETIR',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      estado = EstadoVoz.respondendo;
      mensagem = 'Repetindo orientação.';

      notifyListeners();

      await navegacao.repetirOrientacao();

      await _voltarAoPronto();

      return;
    }

    if (_comandoCancelar(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] CANCELAR',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      estado = EstadoVoz.respondendo;
      mensagem = 'Cancelando navegação...';

      notifyListeners();

      await navegacao.cancelarRota();

      await _voltarAoPronto();

      return;
    }

    if (_perguntaLocalizacao(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] LOCALIZACAO_ATUAL',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      await _responder(
        navegacao.descricaoLocalizacaoAtual(),
      );

      return;
    }

    if (_perguntaDestinoAtual(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] DESTINO_ATUAL',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      await _responder(
        navegacao.descricaoDestinoAtual(),
      );

      return;
    }

    if (_perguntaLocaisProximos(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] LOCAIS_PROXIMOS',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      await _responder(
        navegacao.descricaoLocaisProximos(),
      );

      return;
    }

    if (_comandoVoltarEntrada(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] VOLTAR_ENTRADA',
      );

      final entrada = _buscarLocalPorNome(
        'entrada',
      );

      if (entrada != null) {
        debugPrint(
          '[VOZ][DECISAO] DIRETO -> ${entrada.nome}',
        );

        _logFimTeste();

        await _iniciarDestino(
          entrada,
        );

        return;
      }
    }

    if (_comandoIniciar(comando)) {
      debugPrint(
        '[VOZ][INTENCAO] INICIAR',
      );

      debugPrint(
        '[VOZ][DECISAO] COMANDO GERAL',
      );

      _logFimTeste();

      final iniciou =
          await navegacao.iniciarRota();

      mensagem = navegacao.mensagem;

      notifyListeners();

      if (!iniciou) {
        await feedbackTatil.executar(
          FeedbackTatil.erro,
        );
      }

      await _voltarAoPronto();

      return;
    }

    final analise = _analisarDestino(
      comando,
    );

    _logAnaliseDestino(
      analise,
    );

    if (analise == null) {
      debugPrint(
        '[VOZ][DECISAO] REPETIR -> nenhum candidato',
      );

      _logFimTeste();

      await _tratarFalha(
        semAudio: false,
      );

      return;
    }

    final melhor = analise.melhor;

    /*
     * Correspondência praticamente exata.
     */
    if (melhor.confianca >=
        _confiancaDireta) {
      debugPrint(
        '[VOZ][DECISAO] DIRETO -> ${melhor.local.nome}',
      );

      _logFimTeste();

      await _iniciarDestino(
        melhor.local,
      );

      return;
    }

    /*
     * Boa confiança, mas também verificamos
     * se o segundo colocado não está muito perto.
     */
    if (melhor.confianca >=
            _confiancaAlta &&
        analise.diferencaParaSegundo >=
            _margemEntreCandidatos) {
      debugPrint(
        '[VOZ][DECISAO] DIRETO -> ${melhor.local.nome}',
      );

      _logFimTeste();

      await _iniciarDestino(
        melhor.local,
      );

      return;
    }

    /*
     * Resultado plausível, mas não seguro.
     */
    if (melhor.confianca >=
        _confiancaConfirmacao) {
      debugPrint(
        '[VOZ][DECISAO] CONFIRMAR -> ${melhor.local.nome}',
      );

      _logFimTeste();

      await _pedirConfirmacao(
        melhor.local,
      );

      return;
    }

    debugPrint(
      '[VOZ][DECISAO] REPETIR -> confiança ${melhor.confianca.toStringAsFixed(2)}',
    );

    _logFimTeste();

    await _tratarFalha(
      semAudio: false,
    );
  }

  void _logAnaliseDestino(
    _AnaliseDestino? analise,
  ) {
    if (analise == null) {
      debugPrint(
        '[VOZ][CANDIDATOS] nenhum',
      );

      return;
    }

    final limite = min(
      3,
      analise.candidatos.length,
    );

    for (var i = 0; i < limite; i++) {
      final candidato =
          analise.candidatos[i];

      debugPrint(
        '[VOZ][CANDIDATO ${i + 1}] '
        '${candidato.local.nome} = '
        '${candidato.confianca.toStringAsFixed(2)}',
      );
    }

    debugPrint(
      '[VOZ][DIFERENCA] '
      '${analise.diferencaParaSegundo.toStringAsFixed(2)}',
    );
  }

  Future<void> _processarConfirmacao(
    String comando,
  ) async {
    final destino =
        _destinoPendente;

    if (destino == null) {
      _processando = false;

      await _processarComando(
        comando,
      );

      return;
    }

    if (_respostaSim(comando)) {
      debugPrint(
        '[VOZ][CONFIRMACAO] SIM -> ${destino.nome}',
      );

      _logFimTeste();

      _destinoPendente = null;

      await _iniciarDestino(
        destino,
      );

      return;
    }

    if (_respostaNao(comando)) {
      debugPrint(
        '[VOZ][CONFIRMACAO] NÃO',
      );

      _logFimTeste();

      _destinoPendente = null;
      _processando = false;

      estado = EstadoVoz.respondendo;
      mensagem =
          'Tudo bem. Diga o destino novamente.';

      notifyListeners();

      await navegacao.falarMensagem(
        'Tudo bem. Diga o destino novamente.',
        retomarEscuta: false,
      );

      estado = EstadoVoz.ouvindo;
      mensagem = 'Estou ouvindo...';

      notifyListeners();

      await wakeWord.ouvirComando();

      return;
    }

    /*
     * O usuário pode responder outro destino
     * em vez de "não".
     */
    final analise =
        _analisarDestino(
      comando,
    );

    _logAnaliseDestino(
      analise,
    );

    if (analise != null &&
        analise.melhor.confianca >=
            _confiancaAlta &&
        analise.diferencaParaSegundo >=
            _margemEntreCandidatos) {
      final novoDestino =
          analise.melhor.local;

      debugPrint(
        '[VOZ][CONFIRMACAO] NOVO DESTINO -> ${novoDestino.nome}',
      );

      _logFimTeste();

      _destinoPendente = null;

      await _iniciarDestino(
        novoDestino,
      );

      return;
    }

    debugPrint(
      '[VOZ][CONFIRMACAO] RESPOSTA NÃO IDENTIFICADA',
    );

    _logFimTeste();

    _processando = false;

    estado = EstadoVoz.respondendo;
    mensagem = 'Responda sim ou não.';

    notifyListeners();

    await navegacao.falarMensagem(
      'Responda sim ou não.',
      retomarEscuta: false,
    );

    estado = EstadoVoz.ouvindo;
    mensagem = 'Aguardando confirmação...';

    notifyListeners();

    await wakeWord.ouvirComando();
  }

  Future<void> _pedirConfirmacao(
    Local destino,
  ) async {
    _destinoPendente = destino;
    _processando = false;

    final resposta =
        'Você quis dizer ${destino.nome}?';

    estado = EstadoVoz.respondendo;
    mensagem = resposta;

    notifyListeners();

    await navegacao.falarMensagem(
      resposta,
      retomarEscuta: false,
    );

    estado = EstadoVoz.ouvindo;
    mensagem = 'Diga sim ou não.';

    notifyListeners();

    await wakeWord.ouvirComando();
  }

  Future<void> _iniciarDestino(
    Local destino,
  ) async {
    _destinoPendente = null;

    navegacao.selecionarDestino(
      destino,
    );

    estado = EstadoVoz.respondendo;
    mensagem = 'Destino: ${destino.nome}.';

    notifyListeners();

    final iniciou =
        await navegacao.iniciarRota();

    if (!iniciou) {
      await feedbackTatil.executar(
        FeedbackTatil.erro,
      );
    }

    await _voltarAoPronto();
  }

  Future<void> _responder(
    String resposta,
  ) async {
    estado = EstadoVoz.respondendo;
    mensagem = resposta;

    notifyListeners();

    await feedbackTatil.executar(
      FeedbackTatil.sucesso,
    );

    await navegacao.falarMensagem(
      resposta,
      retomarEscuta: false,
    );

    await _voltarAoPronto();
  }

  Future<void> _tratarFalha({
    required bool semAudio,
  }) async {
    _tentativas++;

    await feedbackTatil.executar(
      FeedbackTatil.erro,
    );

    if (_tentativas <=
        _maxTentativas) {
      final String resposta;

      if (_tentativas == 1) {
        resposta = semAudio
            ? 'Não ouvi nada. Pode repetir?'
            : 'Não consegui identificar o destino. Pode repetir?';
      } else {
        resposta =
            'Tente falar somente o nome do destino.';
      }

      estado = EstadoVoz.respondendo;
      mensagem = resposta;

      notifyListeners();

      await navegacao.falarMensagem(
        resposta,
        retomarEscuta: false,
      );

      _processando = false;

      estado = EstadoVoz.ouvindo;
      mensagem = 'Estou ouvindo novamente...';

      notifyListeners();

      await wakeWord.ouvirComando();

      return;
    }

    const resposta =
        'Não consegui entender. '
        'Use o botão de voz ou diga Nave quando o assistente estiver disponível.';

    estado = EstadoVoz.respondendo;
    mensagem = resposta;

    notifyListeners();

    await navegacao.falarMensagem(
      resposta,
      retomarEscuta: false,
    );

    await _voltarAoPronto();
  }

  Future<void> _voltarAoPronto() async {
    _processando = false;
    _interacaoAtiva = false;
    _tentativas = 0;
    _destinoPendente = null;

    estado = EstadoVoz.pronto;
    mensagem = 'Diga "Nave" ou toque no microfone.';

    notifyListeners();

    await retomarModoAutomatico();
  }

  bool _comandoAjuda(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'ajuda',
        'me ajude',
        'me ajuda',
        'o que posso falar',
        'o que eu posso falar',
        'quais sao os comandos',
        'quais comandos',
        'como usar',
      ],
    );
  }

  bool _comandoEstouPerdido(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'estou perdido',
        'eu estou perdido',
        'to perdido',
        'me perdi',
        'acho que me perdi',
        'nao sei onde estou',
      ],
    );
  }

  bool _comandoRepetir(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'repete',
        'repita',
        'repetir',
        'de novo',
        'novamente',
        'fala de novo',
        'fale de novo',
        'repete a orientacao',
        'repita a orientacao',
        'qual foi a orientacao',
        'qual era a orientacao',
      ],
    );
  }

  bool _comandoCancelar(
    String comando,
  ) {
    return comando == 'cancelar' ||
        comando == 'cancela' ||
        comando == 'cancele' ||
        comando == 'parar' ||
        comando == 'pare' ||
        _contemAlguma(
          comando,
          [
            'cancelar navegacao',
            'cancela navegacao',
            'parar navegacao',
            'pare a navegacao',
            'cancelar rota',
            'cancela a rota',
            'parar a rota',
            'encerrar navegacao',
            'encerrar rota',
          ],
        );
  }

  bool _perguntaLocalizacao(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'onde estou',
        'onde eu estou',
        'onde eu to',
        'onde to',
        'onde estou agora',
        'onde eu estou agora',
        'que lugar e esse',
        'qual minha localizacao',
        'qual e minha localizacao',
        'minha localizacao',
        'localizacao atual',
        'qual minha posicao',
        'minha posicao',
      ],
    );
  }

  bool _perguntaDestinoAtual(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'para onde estou indo',
        'pra onde estou indo',
        'onde estou indo',
        'qual meu destino',
        'qual e meu destino',
        'meu destino',
        'para onde estamos indo',
      ],
    );
  }

  bool _perguntaLocaisProximos(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'o que tem perto',
        'oque tem perto',
        'o que tem aqui',
        'oque tem aqui',
        'o que tem ao meu redor',
        'oque tem ao meu redor',
        'o que esta perto de mim',
        'lugares proximos',
        'locais proximos',
        'o que tem por perto',
        'quais salas estao perto',
        'o que existe perto de mim',
      ],
    );
  }

  bool _comandoVoltarEntrada(
    String comando,
  ) {
    return _contemAlguma(
      comando,
      [
        'quero voltar',
        'voltar para entrada',
        'voltar pra entrada',
        'me leva para entrada',
        'me leve para entrada',
        'quero ir para entrada',
        'ir para entrada',
      ],
    );
  }

  bool _comandoIniciar(
    String comando,
  ) {
    return comando == 'iniciar' ||
        comando == 'comecar' ||
        comando == 'vai' ||
        _contemAlguma(
          comando,
          [
            'iniciar navegacao',
            'comecar navegacao',
            'iniciar rota',
            'comecar rota',
          ],
        );
  }

  bool _respostaSim(
    String comando,
  ) {
    return comando == 'sim' ||
        comando == 'isso' ||
        comando == 'correto' ||
        comando == 'certo' ||
        comando == 'confirmo' ||
        _contemAlguma(
          comando,
          [
            'isso mesmo',
            'pode ser',
            'exatamente',
          ],
        );
  }

  bool _respostaNao(
    String comando,
  ) {
    return comando == 'nao' ||
        comando == 'negativo' ||
        comando == 'errado' ||
        _contemAlguma(
          comando,
          [
            'nao e',
            'nao quero',
            'outro destino',
            'outra sala',
          ],
        );
  }

  bool _contemAlguma(
    String comando,
    List<String> expressoes,
  ) {
    for (final expressao
        in expressoes) {
      if (comando == expressao ||
          comando.contains(
            expressao,
          )) {
        return true;
      }
    }

    return false;
  }

  _AnaliseDestino? _analisarDestino(
    String comando,
  ) {
    final candidatos =
        <_CandidatoDestino>[];

    for (final local
        in navegacao.locais) {
      var melhorPontuacao =
          0.0;

      for (final alias
          in _aliasesDoLocal(
        local,
      )) {
        final pontuacao =
            _pontuarAlias(
          comando,
          alias,
        );

        if (pontuacao >
            melhorPontuacao) {
          melhorPontuacao =
              pontuacao;
        }
      }

      candidatos.add(
        _CandidatoDestino(
          local: local,
          confianca:
              melhorPontuacao,
        ),
      );
    }

    if (candidatos.isEmpty) {
      return null;
    }

    candidatos.sort(
      (a, b) =>
          b.confianca.compareTo(
        a.confianca,
      ),
    );

    final melhor =
        candidatos.first;

    final segunda =
        candidatos.length > 1
            ? candidatos[1]
            : null;

    final diferenca =
        segunda == null
            ? melhor.confianca
            : melhor.confianca -
                segunda.confianca;

    return _AnaliseDestino(
      candidatos:
          candidatos,
      melhor:
          melhor,
      diferencaParaSegundo:
          diferenca,
    );
  }

  double _pontuarAlias(
    String comando,
    String alias,
  ) {
    final aliasNormalizado =
        _normalizar(
      alias,
    );

    if (comando ==
        aliasNormalizado) {
      return 1.0;
    }

    /*
     * Exemplo:
     * "quero ir para informatica"
     * contém "informatica".
     */
    if (aliasNormalizado.length >=
            3 &&
        _contemPalavraOuExpressao(
          comando,
          aliasNormalizado,
        )) {
      return 0.99;
    }

    final comandoLimpo =
        _limparComandoDestino(
      comando,
    );

    final aliasLimpo =
        _limparComandoDestino(
      aliasNormalizado,
    );

    if (comandoLimpo.isEmpty ||
        aliasLimpo.isEmpty) {
      return 0.0;
    }

    if (comandoLimpo ==
        aliasLimpo) {
      return 1.0;
    }

    if (_contemPalavraOuExpressao(
      comandoLimpo,
      aliasLimpo,
    )) {
      return 0.97;
    }

    /*
     * Compara a expressão completa.
     */
    var pontuacao =
        _similaridade(
      comandoLimpo.replaceAll(
        ' ',
        '',
      ),
      aliasLimpo.replaceAll(
        ' ',
        '',
      ),
    );

    /*
     * Também compara palavra por palavra.
     *
     * Isso ajuda em erros como:
     * "sala de informática"
     * -> "sala de forma tica"
     */
    final palavrasComando =
        _tokensRelevantes(
      comandoLimpo,
    );

    final palavrasAlias =
        _tokensRelevantes(
      aliasLimpo,
    );

    if (palavrasComando.isNotEmpty &&
        palavrasAlias.isNotEmpty) {
      var soma =
          0.0;

      for (final palavraAlias
          in palavrasAlias) {
        var melhor =
            0.0;

        for (final palavraComando
            in palavrasComando) {
          final atual =
              _similaridade(
            palavraComando,
            palavraAlias,
          );

          if (atual > melhor) {
            melhor = atual;
          }
        }

        soma += melhor;
      }

      final media =
          soma /
          palavrasAlias.length;

      pontuacao = max(
        pontuacao,
        media * 0.97,
      );
    }

    return pontuacao.clamp(
      0.0,
      1.0,
    );
  }

  bool _contemPalavraOuExpressao(
    String texto,
    String expressao,
  ) {
    final textoCompleto =
        ' $texto ';

    final expressaoCompleta =
        ' $expressao ';

    return textoCompleto.contains(
      expressaoCompleta,
    );
  }

  String _limparComandoDestino(
    String texto,
  ) {
    var resultado =
        _normalizar(
      texto,
    );

    const expressoes = [
      'eu quero ir para',
      'eu quero ir pra',
      'eu queria ir para',
      'eu queria ir pra',
      'quero ir para',
      'quero ir pra',
      'quero ir pro',
      'quero ir ao',
      'quero ir a',
      'gostaria de ir para',
      'gostaria de ir pra',
      'me leva para',
      'me leva pra',
      'me leve para',
      'me leve pra',
      'pode me levar para',
      'pode me levar pra',
      'onde fica',
      'como chegar na',
      'como chegar no',
      'como chego na',
      'como chego no',
      'ir para',
      'ir pra',
      'ir pro',
      'ir ao',
    ];

    for (final expressao
        in expressoes) {
      resultado =
          resultado.replaceAll(
        expressao,
        ' ',
      );
    }

    const ignorar = {
      'nave',
      'naves',
      'eu',
      'quero',
      'queria',
      'gostaria',
      'ir',
      'para',
      'pra',
      'pro',
      'ate',
      'a',
      'o',
      'ao',
      'na',
      'no',
      'da',
      'de',
      'do',
      'dos',
      'das',
      'me',
      'leve',
      'leva',
      'levar',
      'sala',
      'local',
      'lugar',
      'por',
      'favor',
    };

    return resultado
        .split(' ')
        .where(
          (palavra) =>
              palavra.isNotEmpty &&
              !ignorar.contains(
                palavra,
              ),
        )
        .join(' ');
  }

  List<String> _tokensRelevantes(
    String texto,
  ) {
    const ignorar = {
      'sala',
      'de',
      'da',
      'do',
      'dos',
      'das',
      'a',
      'o',
      'os',
      'as',
    };

    return texto
        .split(' ')
        .where(
          (palavra) =>
              palavra.length >= 2 &&
              !ignorar.contains(
                palavra,
              ),
        )
        .toList();
  }

  double _similaridade(
    String a,
    String b,
  ) {
    if (a.isEmpty ||
        b.isEmpty) {
      return 0;
    }

    if (a == b) {
      return 1;
    }

    final distancia =
        _distanciaLevenshtein(
      a,
      b,
    );

    final maior =
        max(
      a.length,
      b.length,
    );

    return 1 -
        distancia /
            maior;
  }

  int _distanciaLevenshtein(
    String a,
    String b,
  ) {
    if (a.isEmpty) {
      return b.length;
    }

    if (b.isEmpty) {
      return a.length;
    }

    var anterior =
        List<int>.generate(
      b.length + 1,
      (i) => i,
    );

    for (var i = 1;
        i <= a.length;
        i++) {
      final atual =
          List<int>.filled(
        b.length + 1,
        0,
      );

      atual[0] = i;

      for (var j = 1;
          j <= b.length;
          j++) {
        final custo =
            a[i - 1] ==
                    b[j - 1]
                ? 0
                : 1;

        atual[j] = min(
          min(
            atual[j - 1] + 1,
            anterior[j] + 1,
          ),
          anterior[j - 1] +
              custo,
        );
      }

      anterior = atual;
    }

    return anterior[
        b.length];
  }

  Local? _buscarLocalPorNome(
    String nome,
  ) {
    final busca =
        _normalizar(
      nome,
    );

    for (final local
        in navegacao.locais) {
      if (_normalizar(
        local.nome,
      ).contains(
        busca,
      )) {
        return local;
      }
    }

    return null;
  }

  /*
   * IMPORTANTE:
   *
   * Aqui ficam apenas aliases semanticamente
   * corretos.
   *
   * Não estamos mais inventando erros possíveis
   * do Vosk.
   *
   * Depois do teste real adicionaremos as
   * variações que realmente acontecerem.
   */
  List<String> _aliasesDoLocal(
    Local local,
  ) {
    final nome =
        _normalizar(
      local.nome,
    );

    final aliases =
        <String>{
      nome,
    };

    var simplificado =
        nome;

    for (final prefixo in [
      'sala de ',
      'sala da ',
      'sala do ',
      'sala dos ',
      'sala das ',
      'sala ',
    ]) {
      if (simplificado.startsWith(
        prefixo,
      )) {
        simplificado =
            simplificado.substring(
          prefixo.length,
        );

        break;
      }
    }

    aliases.add(
      simplificado,
    );

    switch (nome) {
      case 'sala maker':
        aliases.addAll([
          'maker',
          'espaco maker',
        ]);
        break;

      case 'sala de informatica':
        aliases.addAll([
          'informatica',
          'laboratorio de informatica',
          'laboratorio',
        ]);
        break;

      case 'sala da coordenacao':
        aliases.addAll([
          'coordenacao',
        ]);
        break;

      case 'sala de musica':
        aliases.addAll([
          'musica',
        ]);
        break;

      case 'sala de artes':
        aliases.addAll([
          'arte',
          'artes',
        ]);
        break;

      case 'sala de esportes':
        aliases.addAll([
          'esporte',
          'esportes',
        ]);
        break;

      case 'banheiros':
        aliases.addAll([
          'banheiro',
          'banheiros',
        ]);
        break;

      case 'recepcao':
        aliases.addAll([
          'recepcao',
        ]);
        break;

      case 'deposito':
        aliases.addAll([
          'deposito',
          'almoxarifado',
        ]);
        break;

      case 'entrada':
        aliases.addAll([
          'entrada',
          'entrada principal',
        ]);
        break;
    }

    return aliases.toList();
  }

  String _normalizar(
    String texto,
  ) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(
          RegExp(
            r'[^a-z0-9\s]',
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();
  }

  @override
  void dispose() {
    if (_inicializado) {
      navegacao.removeListener(
        _navegacaoMudou,
      );
    }

    super.dispose();
  }
}

class _CandidatoDestino {
  const _CandidatoDestino({
    required this.local,
    required this.confianca,
  });

  final Local local;
  final double confianca;
}

class _AnaliseDestino {
  const _AnaliseDestino({
    required this.candidatos,
    required this.melhor,
    required this.diferencaParaSegundo,
  });

  final List<_CandidatoDestino> candidatos;
  final _CandidatoDestino melhor;
  final double diferencaParaSegundo;
}