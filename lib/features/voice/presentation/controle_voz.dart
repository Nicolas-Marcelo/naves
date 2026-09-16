import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../navigation/domain/entities/local.dart';
import '../../navigation/presentation/controle_navegacao.dart';

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
  });

  final ControleNavegacao navegacao;
  final SpeechToText _speech = SpeechToText();

  bool disponivel = false;

  String textoReconhecido = '';
  String mensagem = 'Diga Nave para começar.';

  EstadoVoz estado = EstadoVoz.pronto;

  String? _localePtBr;
  bool _processando = false;
  int _ciclo = 0;

  bool get ouvindo => estado == EstadoVoz.ouvindo;

  Future<void> inicializar() async {
    disponivel = await _speech.initialize(
      onStatus: _mudouStatusSpeech,
      onError: (_) {
        if (_processando) return;

        estado = EstadoVoz.pronto;
        mensagem = 'Diga Nave para começar.';

        notifyListeners();
      },
    );

    if (!disponivel) {
      estado = EstadoVoz.erro;
      mensagem = 'Reconhecimento de voz indisponível.';

      notifyListeners();
      return;
    }

    final locales = await _speech.locales();

    for (final locale in locales) {
      final id = locale.localeId
          .toLowerCase()
          .replaceAll('-', '_');

      if (id == 'pt_br') {
        _localePtBr = locale.localeId;
        break;
      }
    }

    estado = EstadoVoz.pronto;
    mensagem = 'Diga Nave para começar.';

    notifyListeners();
  }

  void _mudouStatusSpeech(String status) {
    if (status == 'listening') {
      estado = EstadoVoz.ouvindo;
      notifyListeners();
    }
  }

  Future<void> palavraChaveDetectada() async {
    _ciclo++;
    _processando = false;

    await navegacao.pararVoz();

    if (_speech.isListening) {
      await _speech.cancel();
    }

    textoReconhecido = '';

    estado = EstadoVoz.ouvindo;
    mensagem = 'Ouvindo...';

    notifyListeners();
  }

  Future<void> processarComandoExterno(
    String texto,
  ) async {
    if (texto.trim().isEmpty) return;

    await navegacao.pararVoz();

    await _processarComando(
      texto,
    );
  }

  Future<void> processarTimeoutExterno() async {
    _ciclo++;

    _processando = false;
    textoReconhecido = '';

    estado = EstadoVoz.pronto;
    mensagem = 'Diga Nave para começar.';

    notifyListeners();

    unawaited(
      navegacao.falarMensagem(
        'Repita.',
      ),
    );
  }

  Future<void> alternarEscuta() async {
    _ciclo++;

    if (!disponivel) {
      await inicializar();

      if (!disponivel) return;
    }

    if (_speech.isListening) {
      await _speech.stop();

      estado = EstadoVoz.pronto;
      mensagem = 'Diga Nave para começar.';

      notifyListeners();
      return;
    }

    await navegacao.pararVoz();

    textoReconhecido = '';

    mensagem = 'Ouvindo...';
    estado = EstadoVoz.ouvindo;

    notifyListeners();

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _localePtBr,
        listenFor: const Duration(
          seconds: 4,
        ),
        pauseFor: const Duration(
          milliseconds: 550,
        ),
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: false,
        enableHapticFeedback: true,
        listenMode: ListenMode.confirmation,
      ),
      onResult: (resultado) {
        if (_processando) return;

        textoReconhecido =
            resultado.recognizedWords.trim();

        if (textoReconhecido.isNotEmpty) {
          mensagem = textoReconhecido;
          notifyListeners();
        }

        if (resultado.finalResult &&
            textoReconhecido.isNotEmpty) {
          unawaited(
            _processarComando(
              textoReconhecido,
            ),
          );
        }
      },
    );
  }

  Future<void> _processarComando(
    String texto,
  ) async {
    if (_processando) return;

    _processando = true;

    final cicloAtual = _ciclo;

    if (_speech.isListening) {
      await _speech.stop();
    }

    final comando = _normalizar(
      texto,
    );

    debugPrint(
      '[NAVESCENCE] Comando normalizado: $comando',
    );

    estado = EstadoVoz.processando;
    mensagem = 'Entendendo...';

    notifyListeners();

    if (_comandoRepetir(comando)) {
      await _responder(
        'Repetindo.',
        navegacao.repetirOrientacao,
        cicloAtual,
      );

      return;
    }

    if (_comandoCancelar(comando)) {
      navegacao.cancelarRota();

      await _finalizar(
        'Navegação cancelada.',
        cicloAtual,
      );

      return;
    }

    if (_perguntaLocalizacao(comando)) {
      final resposta =
          navegacao.descricaoLocalizacaoAtual();

      debugPrint(
        '[NAVESCENCE] Pergunta de localização detectada.',
      );

      await _responder(
        resposta,
        () => navegacao.falarMensagem(
          resposta,
        ),
        cicloAtual,
      );

      return;
    }

    if (_perguntaLocaisProximos(comando)) {
      final resposta =
          navegacao.descricaoLocaisProximos();

      debugPrint(
        '[NAVESCENCE] Pergunta sobre arredores detectada.',
      );

      await _responder(
        resposta,
        () => navegacao.falarMensagem(
          resposta,
        ),
        cicloAtual,
      );

      return;
    }

    if (_comandoVoltarEntrada(comando)) {
      final entrada =
          _buscarLocalPorNome(
        'entrada',
      );

      if (entrada != null) {
        navegacao.selecionarDestino(
          entrada,
        );

        navegacao.iniciarRota();

        await _finalizar(
          'Navegação iniciada.',
          cicloAtual,
        );

        return;
      }
    }

    final destino =
        _encontrarDestino(
      comando,
    );

    if (destino != null) {
      navegacao.selecionarDestino(
        destino,
      );

      navegacao.iniciarRota();

      await _finalizar(
        'Destino reconhecido.',
        cicloAtual,
      );

      return;
    }

    if (_comandoIniciar(comando)) {
      navegacao.iniciarRota();

      await _finalizar(
        'Navegação iniciada.',
        cicloAtual,
      );

      return;
    }

    _falhaRapida(
      cicloAtual,
    );
  }

  void _falhaRapida(
    int ciclo,
  ) {
    if (ciclo != _ciclo) return;

    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem = 'Não entendi.';

    notifyListeners();

    unawaited(
      navegacao.falarMensagem(
        'Não entendi.',
      ),
    );
  }

  Future<void> _responder(
    String texto,
    Future<void> Function() acao,
    int ciclo,
  ) async {
    estado = EstadoVoz.respondendo;
    mensagem = texto;

    notifyListeners();

    await acao();

    if (ciclo != _ciclo) return;

    await _voltarAoPronto(
      ciclo,
    );
  }

  Future<void> _finalizar(
    String texto,
    int ciclo,
  ) async {
    estado = EstadoVoz.respondendo;
    mensagem = texto;

    notifyListeners();

    await Future.delayed(
      const Duration(
        milliseconds: 80,
      ),
    );

    if (ciclo != _ciclo) return;

    await _voltarAoPronto(
      ciclo,
    );
  }

  Future<void> _voltarAoPronto(
    int ciclo,
  ) async {
    if (ciclo != _ciclo) return;

    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem = 'Diga Nave para começar.';

    notifyListeners();
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
        'repete pra mim',
        'repita pra mim',
        'repete para mim',
        'repita para mim',
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
        comando == 'para' ||
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
          ],
        );
  }

  bool _perguntaLocalizacao(
    String comando,
  ) {
    final frasesDiretas = [
      'onde estou',
      'onde eu estou',
      'onde eu to',
      'onde to',
      'onde estou agora',
      'onde eu estou agora',
      'onde eu to agora',
      'onde que eu estou',
      'onde que eu to',
      'onde que estou',
      'onde me encontro',
      'onde eu me encontro',
      'em que lugar estou',
      'em que lugar eu estou',
      'que lugar estou',
      'que lugar eu estou',
      'que lugar e esse',
      'qual lugar estou',
      'qual e o lugar',
      'qual e minha localizacao',
      'qual minha localizacao',
      'qual e a minha localizacao',
      'qual a minha localizacao',
      'minha localizacao',
      'localizacao atual',
      'qual e minha posicao',
      'qual minha posicao',
      'qual e a minha posicao',
      'qual a minha posicao',
      'minha posicao',
      'posicao atual',
      'me diga onde estou',
      'me diga onde eu estou',
      'me fala onde estou',
      'me fala onde eu estou',
      'diga onde estou',
      'diga onde eu estou',
      'fala onde estou',
      'fala onde eu estou',
    ];

    if (_contemAlguma(
      comando,
      frasesDiretas,
    )) {
      return true;
    }

    final possuiOnde =
        comando.contains('onde');

    final possuiReferenciaUsuario =
        comando.contains('eu') ||
            comando.contains('estou') ||
            comando.contains('to') ||
            comando.contains('me encontro');

    if (possuiOnde &&
        possuiReferenciaUsuario) {
      return true;
    }

    final possuiLocalizacao =
        comando.contains('localizacao') ||
            comando.contains('posicao');

    final possuiMinha =
        comando.contains('minha') ||
            comando.contains('atual');

    if (possuiLocalizacao &&
        possuiMinha) {
      return true;
    }

    return false;
  }

  bool _perguntaLocaisProximos(
    String comando,
  ) {
    final frasesDiretas = [
      'o que tem ao meu redor',
      'oque tem ao meu redor',
      'o que tem em meu redor',
      'o que esta ao meu redor',
      'oque esta ao meu redor',
      'o que existe ao meu redor',
      'oque existe ao meu redor',
      'o que tem em volta de mim',
      'oque tem em volta de mim',
      'o que esta em volta de mim',
      'oque esta em volta de mim',
      'o que existe em volta de mim',
      'o que tem perto de mim',
      'oque tem perto de mim',
      'o que esta perto de mim',
      'oque esta perto de mim',
      'o que existe perto de mim',
      'o que tem por perto',
      'oque tem por perto',
      'o que existe por perto',
      'o que tem aqui perto',
      'oque tem aqui perto',
      'o que tem aqui',
      'oque tem aqui',
      'o que existe aqui',
      'o que tem proximo de mim',
      'oque tem proximo de mim',
      'o que esta proximo de mim',
      'oque esta proximo de mim',
      'o que tem proximo',
      'oque tem proximo',
      'o que tem nas proximidades',
      'oque tem nas proximidades',
      'o que existe nas proximidades',
      'o que tem nos arredores',
      'oque tem nos arredores',
      'o que existe nos arredores',
      'quais lugares tem perto',
      'quais lugares tem perto de mim',
      'quais lugares estao perto',
      'quais lugares estao perto de mim',
      'quais lugares estao proximos',
      'quais lugares estao proximos de mim',
      'quais locais estao proximos',
      'quais locais estao proximos de mim',
      'lugares proximos',
      'locais proximos',
      'lugares perto',
      'locais perto',
      'ao meu redor',
      'em volta de mim',
      'perto de mim',
      'por perto',
      'arredores',
      'proximidades',
      'o que ha ao meu redor',
      'oque ha ao meu redor',
      'o que ha em volta de mim',
      'oque ha em volta de mim',
      'o que ha por perto',
      'oque ha por perto',
      'me diga o que tem ao meu redor',
      'me diga o que tem em volta de mim',
      'me diga o que tem perto de mim',
      'me diga o que tem por perto',
      'me fala o que tem ao meu redor',
      'me fala o que tem em volta de mim',
      'me fala o que tem perto de mim',
      'fala o que tem ao meu redor',
      'fala o que tem perto de mim',
    ];

    if (_contemAlguma(
      comando,
      frasesDiretas,
    )) {
      return true;
    }

    final perguntaSobreConteudo =
        comando.contains('o que') ||
            comando.contains('oque') ||
            comando.contains('quais') ||
            comando.contains('que lugar') ||
            comando.contains('que locais') ||
            comando.contains('que lugares');

    final referenciaProximidade =
        comando.contains('perto') ||
            comando.contains('proximo') ||
            comando.contains('proximos') ||
            comando.contains('proxima') ||
            comando.contains('proximas') ||
            comando.contains('redor') ||
            comando.contains('volta de mim') ||
            comando.contains('arredor') ||
            comando.contains('proximidade') ||
            comando.contains('aqui');

    if (perguntaSobreConteudo &&
        referenciaProximidade) {
      return true;
    }

    return false;
  }

  bool _comandoVoltarEntrada(
    String comando,
  ) {
    return comando == 'voltar' ||
        comando == 'voltar entrada' ||
        comando == 'voltar para entrada' ||
        comando == 'voltar pra entrada' ||
        comando == 'me leve para entrada' ||
        comando == 'me leva para entrada' ||
        comando == 'ir para entrada';
  }

  bool _comandoIniciar(
    String comando,
  ) {
    return comando == 'iniciar' ||
        comando == 'comecar' ||
        comando == 'vai' ||
        comando.contains(
          'iniciar navegacao',
        ) ||
        comando.contains(
          'comecar navegacao',
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

  Local? _encontrarDestino(
    String comando,
  ) {
    Local? melhorDestino;

    var melhorPontuacao = 0.0;

    final possivelDestino =
        _extrairPossivelDestino(
      comando,
    );

    for (final local
        in navegacao.locais) {
      final aliases =
          _aliasesDoLocal(local);

      for (final alias in aliases) {
        if (alias.length < 3) {
          continue;
        }

        if (_contemExpressao(
          comando,
          alias,
        )) {
          final pontuacao =
              10.0 + alias.length;

          if (pontuacao >
              melhorPontuacao) {
            melhorPontuacao =
                pontuacao;

            melhorDestino =
                local;
          }

          continue;
        }

        if (possivelDestino.isEmpty) {
          continue;
        }

        final similaridade =
            _similaridade(
          possivelDestino,
          alias,
        );

        if (similaridade >= 0.70 &&
            similaridade >
                melhorPontuacao) {
          melhorPontuacao =
              similaridade;

          melhorDestino =
              local;
        }
      }
    }

    return melhorDestino;
  }

  String _extrairPossivelDestino(
    String comando,
  ) {
    var texto = comando;

    final prefixos = [
      'eu quero ir para a',
      'eu quero ir para o',
      'eu quero ir para',
      'quero ir para a',
      'quero ir para o',
      'quero ir para',
      'quero ir ao',
      'quero ir a',
      'me leve para a',
      'me leve para o',
      'me leve para',
      'me leva para a',
      'me leva para o',
      'me leva para',
      'ir para a',
      'ir para o',
      'ir para',
      'para a',
      'para o',
      'naves',
      'nave',
    ];

    for (final prefixo
        in prefixos) {
      if (texto.startsWith(
        prefixo,
      )) {
        texto = texto
            .substring(
              prefixo.length,
            )
            .trim();

        break;
      }
    }

    return texto;
  }

  bool _contemExpressao(
    String texto,
    String expressao,
  ) {
    return ' $texto '.contains(
      ' $expressao ',
    );
  }

  double _similaridade(
    String a,
    String b,
  ) {
    if (a == b) return 1;

    if (a.isEmpty || b.isEmpty) {
      return 0;
    }

    final distancia =
        _distanciaEdicao(
      a,
      b,
    );

    final maior =
        a.length > b.length
            ? a.length
            : b.length;

    return 1 -
        distancia / maior;
  }

  int _distanciaEdicao(
    String a,
    String b,
  ) {
    final anterior =
        List<int>.generate(
      b.length + 1,
      (index) => index,
    );

    for (var i = 1;
        i <= a.length;
        i++) {
      var diagonal =
          anterior[0];

      anterior[0] = i;

      for (var j = 1;
          j <= b.length;
          j++) {
        final antigo =
            anterior[j];

        final custo =
            a[i - 1] ==
                    b[j - 1]
                ? 0
                : 1;

        final insercao =
            anterior[j - 1] + 1;

        final remocao =
            anterior[j] + 1;

        final substituicao =
            diagonal + custo;

        var menor = insercao;

        if (remocao < menor) {
          menor = remocao;
        }

        if (substituicao <
            menor) {
          menor =
              substituicao;
        }

        anterior[j] = menor;
        diagonal = antigo;
      }
    }

    return anterior[b.length];
  }

  Local? _buscarLocalPorNome(
    String nome,
  ) {
    final busca =
        _normalizar(nome);

    for (final local
        in navegacao.locais) {
      if (_normalizar(
        local.nome,
      ).contains(busca)) {
        return local;
      }
    }

    return null;
  }

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

    var simplificado = nome;

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
          'sala maker',
          'espaco maker',
        ]);
        break;

      case 'sala de informatica':
        aliases.addAll([
          'informatica',
          'sala informatica',
          'computadores',
          'computador',
          'laboratorio',
        ]);
        break;

      case 'sala da coordenacao':
        aliases.addAll([
          'coordenacao',
          'sala coordenacao',
          'coordenadora',
        ]);
        break;

      case 'sala de musica':
        aliases.addAll([
          'musica',
          'sala musica',
        ]);
        break;

      case 'sala de artes':
        aliases.addAll([
          'arte',
          'artes',
          'sala arte',
          'sala artes',
          'sala de arte',
          'sala de artes',
          'sala das artes',
          'sala ti',
        ]);
        break;

      case 'sala de esportes':
        aliases.addAll([
          'esporte',
          'esportes',
          'sala esporte',
          'sala esportes',
          'sala de esporte',
          'sala de esportes',
          'saude esporte',
          'so portes',
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
          'recepcao principal',
        ]);
        break;

      case 'deposito':
        aliases.add(
          'deposito',
        );
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
    _ciclo++;

    _speech.cancel();

    super.dispose();
  }
}