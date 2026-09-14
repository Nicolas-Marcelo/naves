import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../navigation/domain/entities/local.dart';
import '../../navigation/presentation/controle_navegacao.dart';

/* Responsável por reconhecer a fala do usuário e interpretar
os comandos relacionados à navegação. */

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
  String mensagem = 'Toque no microfone e fale.';

  EstadoVoz estado = EstadoVoz.pronto;

  String? _localePtBr;
  bool _processando = false;

  bool get ouvindo =>
      estado == EstadoVoz.ouvindo;

  Future<void> inicializar() async {
    disponivel = await _speech.initialize(
      onStatus: _mudouStatusSpeech,
      onError: (_) {
        if (_processando) return;

        estado = EstadoVoz.erro;
        mensagem =
            'Não entendi. Tente novamente.';

        notifyListeners();
      },
    );

    if (!disponivel) {
      estado = EstadoVoz.erro;
      mensagem =
          'Reconhecimento de voz indisponível.';

      notifyListeners();
      return;
    }

    final locales =
        await _speech.locales();

    for (final locale in locales) {
      final id = locale.localeId
          .toLowerCase()
          .replaceAll('-', '_');

      if (id == 'pt_br') {
        _localePtBr =
            locale.localeId;

        break;
      }
    }

    estado = EstadoVoz.pronto;
    mensagem =
        'Toque no microfone e fale.';

    notifyListeners();
  }

  void _mudouStatusSpeech(
    String status,
  ) {
    if (status == 'listening') {
      estado = EstadoVoz.ouvindo;
      notifyListeners();
    }
  }

  Future<void> alternarEscuta() async {
    if (!disponivel) {
      await inicializar();

      if (!disponivel) return;
    }

    if (_speech.isListening) {
      await _speech.stop();

      estado = EstadoVoz.pronto;
      mensagem =
          'Toque no microfone e fale.';

      notifyListeners();
      return;
    }

    await navegacao.pararVoz();

    textoReconhecido = '';
    mensagem = 'Ouvindo...';
    estado = EstadoVoz.ouvindo;

    notifyListeners();

    await _speech.listen(
      listenOptions:
          SpeechListenOptions(
        localeId: _localePtBr,
        listenFor:
            const Duration(
          seconds: 6,
        ),
        pauseFor:
            const Duration(
          milliseconds: 800,
        ),
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: false,
        enableHapticFeedback: true,
        listenMode:
            ListenMode.confirmation,
      ),
      onResult: (resultado) {
        if (_processando) return;

        textoReconhecido =
            resultado.recognizedWords.trim();

        if (
            textoReconhecido
                .isNotEmpty) {
          mensagem =
              textoReconhecido;

          notifyListeners();
        }

        if (
            resultado.finalResult &&
            textoReconhecido
                .isNotEmpty) {
          _processarComando(
            textoReconhecido,
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

    await _speech.stop();

    final comando =
        _normalizar(texto);

    estado = EstadoVoz.processando;
    mensagem = 'Entendendo...';

    notifyListeners();

    if (_comandoRepetir(comando)) {
      await _responder(
        'Repetindo.',
        navegacao.repetirOrientacao,
      );

      return;
    }

    if (_comandoCancelar(comando)) {
      navegacao.cancelarRota();

      await _finalizar(
        'Navegação cancelada.',
      );

      return;
    }

    if (_perguntaLocalizacao(comando)) {
      final resposta =
          navegacao
              .descricaoLocalizacaoAtual();

      await _responder(
        resposta,
        () =>
            navegacao.falarMensagem(
          resposta,
        ),
      );

      return;
    }

    if (
        _perguntaLocaisProximos(
      comando,
    )) {
      final resposta =
          navegacao
              .descricaoLocaisProximos();

      await _responder(
        resposta,
        () =>
            navegacao.falarMensagem(
          resposta,
        ),
      );

      return;
    }

    if (
        _comandoVoltarEntrada(
      comando,
    )) {
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
          'Indo para a entrada.',
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
        'Destino: ${destino.nome}.',
      );

      return;
    }

    if (_comandoIniciar(comando)) {
      navegacao.iniciarRota();

      await _finalizar(
        'Iniciando navegação.',
      );

      return;
    }

    await _responder(
      'Não entendi. Tente falar apenas o destino.',
      () =>
          navegacao.falarMensagem(
        'Não entendi. Fale o nome do destino.',
      ),
    );
  }

  Future<void> _responder(
    String texto,
    Future<void> Function() acao,
  ) async {
    estado = EstadoVoz.respondendo;
    mensagem = texto;

    notifyListeners();

    await acao();

    await _voltarAoPronto();
  }

  Future<void> _finalizar(
    String texto,
  ) async {
    estado = EstadoVoz.respondendo;
    mensagem = texto;

    notifyListeners();

    await Future.delayed(
      const Duration(
        milliseconds: 250,
      ),
    );

    await _voltarAoPronto();
  }

  Future<void> _voltarAoPronto() async {
    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem =
        'Toque no microfone e fale.';

    notifyListeners();
  }

  bool _comandoRepetir(
    String comando,
  ) {
    return comando == 'repete' ||
        comando == 'repita' ||
        comando == 'repetir' ||
        comando == 'de novo' ||
        comando == 'novamente' ||
        comando.contains(
          'fala de novo',
        ) ||
        comando.contains(
          'fale de novo',
        ) ||
        comando.contains(
          'repete pra mim',
        ) ||
        comando.contains(
          'repita pra mim',
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
        comando.contains(
          'cancelar navegacao',
        ) ||
        comando.contains(
          'parar navegacao',
        ) ||
        comando.contains(
          'cancelar rota',
        );
  }

  bool _perguntaLocalizacao(
    String comando,
  ) {
    return comando ==
            'onde estou' ||
        comando ==
            'onde eu estou' ||
        comando ==
            'onde eu to' ||
        comando ==
            'onde to' ||
        comando ==
            'localizacao' ||
        comando ==
            'minha localizacao' ||
        comando.contains(
          'qual minha localizacao',
        ) ||
        comando.contains(
          'qual e minha localizacao',
        );
  }

  bool _perguntaLocaisProximos(
    String comando,
  ) {
    return comando == 'perto' ||
        comando == 'proximo' ||
        comando == 'proximos' ||
        comando.contains(
          'o que tem perto',
        ) ||
        comando.contains(
          'oque tem perto',
        ) ||
        comando.contains(
          'o que tem aqui',
        ) ||
        comando.contains(
          'lugares proximos',
        ) ||
        comando.contains(
          'locais proximos',
        );
  }

  bool _comandoVoltarEntrada(
    String comando,
  ) {
    return comando == 'voltar' ||
        comando ==
            'voltar entrada' ||
        comando ==
            'voltar para entrada' ||
        comando ==
            'voltar pra entrada';
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

  Local? _encontrarDestino(
    String comando,
  ) {
    Local? melhorDestino;
    var melhorPontuacao = 0;

    for (
      final local
      in navegacao.locais
    ) {
      final aliases =
          _aliasesDoLocal(local);

      for (
        final alias
        in aliases
      ) {
        if (alias.length < 3) {
          continue;
        }

        if (
            comando == alias ||
            comando.contains(alias)) {
          final pontuacao =
              alias.length;

          if (
              pontuacao >
              melhorPontuacao) {
            melhorPontuacao =
                pontuacao;

            melhorDestino =
                local;
          }
        }
      }
    }

    return melhorDestino;
  }

  Local? _buscarLocalPorNome(
    String nome,
  ) {
    final busca =
        _normalizar(nome);

    for (
      final local
      in navegacao.locais
    ) {
      if (
          _normalizar(
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
        _normalizar(local.nome);

    final aliases = <String>{
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
      if (
          simplificado
              .startsWith(
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
          'computadores',
          'computador',
          'laboratorio',
        ]);
        break;

      case 'sala da coordenacao':
        aliases.addAll([
          'coordenacao',
          'coordenadora',
        ]);
        break;

      case 'sala de musica':
        aliases.add(
          'musica',
        );
        break;

      case 'sala de artes':
        aliases.add(
          'artes',
        );
        break;

      case 'sala de esportes':
        aliases.add(
          'esportes',
        );
        break;

      case 'banheiros':
        aliases.addAll([
          'banheiro',
          'banheiros',
        ]);
        break;

      case 'recepcao':
        aliases.add(
          'recepcao',
        );
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
    _speech.cancel();

    super.dispose();
  }
}