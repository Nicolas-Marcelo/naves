import 'package:flutter/foundation.dart';

import '../../navigation/domain/entities/local.dart';
import '../../navigation/presentation/controle_navegacao.dart';
import '../data/servico_wake_word.dart';

enum EstadoVoz { pronto, ouvindo, processando, respondendo, erro }

enum EtapaVoz { origem, destino, navegando }

class ControleVoz extends ChangeNotifier {
  ControleVoz({
    required this.navegacao,
    required this.wakeWord,
    required Object? feedbackTatil,
  });

  final ControleNavegacao navegacao;
  final ServicoWakeWord wakeWord;

  bool disponivel = true;
  bool _processando = false;
  bool _appEmPrimeiroPlano = true;

  String textoReconhecido = '';
  String mensagem = 'Diga "Nave" para iniciar.';

  EstadoVoz estado = EstadoVoz.pronto;

  bool get ouvindo => estado == EstadoVoz.ouvindo;
  bool get appEmPrimeiroPlano => _appEmPrimeiroPlano;

  EtapaVoz get etapa {
    if (navegacao.origem == null) return EtapaVoz.origem;
    if (navegacao.destino == null) return EtapaVoz.destino;
    return EtapaVoz.navegando;
  }

  Future<void> inicializar() async {
    disponivel = true;
    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem = _mensagemPronto();

    notifyListeners();

    await _ativarWake();
  }

  void definirAppEmPrimeiroPlano(bool primeiroPlano) {
    if (_appEmPrimeiroPlano == primeiroPlano) return;

    _appEmPrimeiroPlano = primeiroPlano;

    if (!_appEmPrimeiroPlano) {
      _processando = false;

      estado = EstadoVoz.pronto;
      mensagem = _mensagemPronto();

      notifyListeners();

      wakeWord.parar();
      return;
    }

    retomarModoAutomatico();
  }

  Future<void> retomarModoAutomatico() async {
    if (!_appEmPrimeiroPlano) return;

    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem = _mensagemPronto();

    notifyListeners();

    await _ativarWake();
  }

  Future<void> _ativarWake() async {
    if (!_appEmPrimeiroPlano) return;

    try {
      debugPrint('[VOZ] Espera: WAKE RESTRITO');

      await wakeWord.ouvir();
    } catch (erro, stackTrace) {
      debugPrint('[VOZ] Erro ao ativar WAKE: $erro');
      debugPrintStack(stackTrace: stackTrace);

      estado = EstadoVoz.erro;
      mensagem = 'Erro ao ativar o controle de voz.';

      notifyListeners();
    }
  }

  Future<void> palavraChaveDetectada() async {
    if (!_appEmPrimeiroPlano) return;
    if (_processando) return;

    await navegacao.pararVoz();

    textoReconhecido = '';

    estado = EstadoVoz.ouvindo;

    switch (etapa) {
      case EtapaVoz.origem:
        mensagem = 'Onde você está?';
        break;

      case EtapaVoz.destino:
        mensagem = 'Para onde você deseja ir?';
        break;

      case EtapaVoz.navegando:
        mensagem = 'Ouvindo comando...';
        break;
    }

    notifyListeners();

    try {
      debugPrint('[VOZ] NAVE detectado.');
      debugPrint('[VOZ] Espera: COMANDO');

      await wakeWord.ouvirComando();
    } catch (erro, stackTrace) {
      debugPrint('[VOZ] Erro ao iniciar COMANDO: $erro');
      debugPrintStack(stackTrace: stackTrace);

      estado = EstadoVoz.erro;
      mensagem = 'Não foi possível ouvir o comando.';

      notifyListeners();

      await retomarModoAutomatico();
    }
  }

  Future<void> processarComandoExterno(String comando) async {
    if (!_appEmPrimeiroPlano) return;

    final texto = comando.trim();

    if (texto.isEmpty) {
      await processarTimeoutExterno();
      return;
    }

    textoReconhecido = texto;

    estado = EstadoVoz.processando;
    mensagem = 'Entendendo...';

    notifyListeners();

    await processarComando(texto);
  }

  Future<void> processarTimeoutExterno() async {
    _processando = false;

    estado = EstadoVoz.pronto;

    switch (etapa) {
      case EtapaVoz.origem:
        mensagem = 'Não ouvi sua localização. Diga "Nave" e tente novamente.';
        break;

      case EtapaVoz.destino:
        mensagem = 'Não ouvi o destino. Diga "Nave" e tente novamente.';
        break;

      case EtapaVoz.navegando:
        mensagem = 'Não ouvi o comando. Diga "Nave" e tente novamente.';
        break;
    }

    notifyListeners();

    await _ativarWake();
  }

  Future<void> alternarEscuta() async {
    if (!_appEmPrimeiroPlano) return;

    if (estado == EstadoVoz.ouvindo) {
      await wakeWord.parar();

      _processando = false;

      estado = EstadoVoz.pronto;
      mensagem = _mensagemPronto();

      notifyListeners();

      await _ativarWake();
      return;
    }

    await palavraChaveDetectada();
  }

  Future<void> iniciarFluxoNavegacao() async {
    navegacao.reiniciarNavegacao();

    estado = EstadoVoz.respondendo;
    mensagem = 'Onde você está agora?';

    notifyListeners();

    await navegacao.falarMensagem('Onde você está agora?');
  }

  Future<void> processarTexto(String texto) async {
    await processarComando(texto);
  }

  Future<void> processarComando(String texto) async {
    if (_processando) return;

    final textoLimpo = texto.trim();

    if (textoLimpo.isEmpty) {
      await processarTimeoutExterno();
      return;
    }

    _processando = true;

    textoReconhecido = textoLimpo;

    estado = EstadoVoz.processando;
    mensagem = 'Entendendo...';

    notifyListeners();

    final comando = _normalizar(textoLimpo);

    debugPrint('');
    debugPrint('========== VOZ NAVESCENCE ==========');
    debugPrint('[VOZ][BRUTO] $textoLimpo');
    debugPrint('[VOZ][NORMALIZADO] $comando');
    debugPrint('[VOZ][ETAPA] ${etapa.name}');

    if (_comandoCancelar(comando)) {
      navegacao.cancelarRota();

      await _finalizarSemFala('Navegação cancelada.');

      _finalizarLog();
      return;
    }

    if (_comandoRepetir(comando)) {
      await _responder('Repetindo orientação.', navegacao.repetirOrientacao);

      _finalizarLog();
      return;
    }

    if (_perguntaLocalizacao(comando)) {
      final resposta = navegacao.descricaoLocalizacaoAtual();

      await _responder(resposta, () => navegacao.falarMensagem(resposta));

      _finalizarLog();
      return;
    }

    if (_perguntaLocaisProximos(comando)) {
      final resposta = navegacao.descricaoLocaisProximos();

      await _responder(resposta, () => navegacao.falarMensagem(resposta));

      _finalizarLog();
      return;
    }

    switch (etapa) {
      case EtapaVoz.origem:
        await _processarOrigem(comando);
        break;

      case EtapaVoz.destino:
        await _processarDestino(comando);
        break;

      case EtapaVoz.navegando:
        await _processarNavegacao(comando);
        break;
    }

    _finalizarLog();
  }

  Future<void> _processarOrigem(String comando) async {
    final local = _encontrarLocal(comando);

    if (local == null) {
      debugPrint('[VOZ][ORIGEM] Local não identificado.');

      await _responder(
        'Local não encontrado.',
        () => navegacao.falarMensagem(
          'Não encontrei esse local. Diga Nave e informe novamente onde você está.',
        ),
      );

      return;
    }

    debugPrint('[VOZ][ORIGEM] ${local.nome}');

    navegacao.selecionarOrigem(local);

    estado = EstadoVoz.respondendo;
    mensagem = 'Você está em ${local.nome}. Para onde deseja ir?';

    notifyListeners();

    await navegacao.falarMensagem(
      'Você está em ${local.nome}. Para onde você deseja ir?',
    );
  }

  Future<void> _processarDestino(String comando) async {
    final local = _encontrarLocal(comando);

    if (local == null) {
      debugPrint('[VOZ][DESTINO] Destino não identificado.');

      await _responder(
        'Destino não encontrado.',
        () => navegacao.falarMensagem(
          'Não encontrei esse destino. Diga Nave e informe novamente para onde deseja ir.',
        ),
      );

      return;
    }

    if (local.nome == navegacao.origem?.nome) {
      await _responder(
        'Esse local já é sua origem.',
        () => navegacao.falarMensagem(
          '${local.nome} já é sua origem. Escolha outro destino.',
        ),
      );

      return;
    }

    debugPrint('[VOZ][DESTINO] ${local.nome}');

    navegacao.selecionarDestino(local);

    estado = EstadoVoz.respondendo;
    mensagem = 'Calculando rota para ${local.nome}.';

    notifyListeners();

    await navegacao.iniciarRotaAguardando();
  }

  Future<void> _processarNavegacao(String comando) async {
    if (_comandoNovaRota(comando)) {
      navegacao.reiniciarNavegacao();

      await _responder(
        'Onde você está agora?',
        () => navegacao.falarMensagem('Onde você está agora?'),
      );

      return;
    }

    if (_comandoVoltarEntrada(comando)) {
      final entrada = _buscarLocalPorNome('entrada');

      if (entrada != null) {
        navegacao.selecionarDestino(entrada);

        await navegacao.iniciarRotaAguardando();
        return;
      }
    }

    if (_comandoIniciar(comando)) {
      await navegacao.iniciarRotaAguardando();
      return;
    }

    final novoDestino = _encontrarLocal(comando);

    if (novoDestino != null && novoDestino.nome != navegacao.origem?.nome) {
      navegacao.selecionarDestino(novoDestino);

      await navegacao.iniciarRotaAguardando();
      return;
    }

    await _responder(
      'Comando não reconhecido.',
      () => navegacao.falarMensagem(
        'Não entendi. Você pode informar outro destino, repetir a orientação ou cancelar a navegação.',
      ),
    );
  }

  Future<void> _responder(String texto, Future<void> Function() acao) async {
    estado = EstadoVoz.respondendo;
    mensagem = texto;

    notifyListeners();

    try {
      await acao();
    } finally {
      _processando = false;

      if (estado != EstadoVoz.erro) {
        estado = EstadoVoz.pronto;
        mensagem = _mensagemPronto();

        notifyListeners();
      }
    }
  }

  Future<void> _finalizarSemFala(String texto) async {
    _processando = false;

    estado = EstadoVoz.pronto;
    mensagem = texto;

    notifyListeners();

    await _ativarWake();
  }

  String _mensagemPronto() {
    switch (etapa) {
      case EtapaVoz.origem:
        return 'Diga "Nave" para informar onde você está.';

      case EtapaVoz.destino:
        return 'Diga "Nave" para informar o destino.';

      case EtapaVoz.navegando:
        return navegacao.rotaAtiva
            ? 'Navegação em andamento. Diga "Nave" para um comando.'
            : 'Diga "Nave" para um novo comando.';
    }
  }

  Local? _encontrarLocal(String comando) {
    Local? melhorLocal;
    var melhorPontuacao = 0.0;

    for (final local in navegacao.locais) {
      final aliases = _aliasesDoLocal(local);

      for (final alias in aliases) {
        final pontuacao = _similaridade(comando, alias);

        if (pontuacao > melhorPontuacao) {
          melhorPontuacao = pontuacao;
          melhorLocal = local;
        }
      }
    }

    if (melhorLocal != null) {
      debugPrint(
        '[VOZ][CANDIDATO] ${melhorLocal.nome} = ${melhorPontuacao.toStringAsFixed(2)}',
      );
    }

    if (melhorPontuacao < 0.55) return null;

    return melhorLocal;
  }

  double _similaridade(String a, String b) {
    if (a == b) return 1.0;
    if (a.contains(b)) return 0.99;

    if (b.contains(a) && a.length >= 4) {
      return 0.90;
    }

    final palavrasA = a
        .split(' ')
        .where((palavra) => palavra.length > 2)
        .toSet();

    final palavrasB = b
        .split(' ')
        .where((palavra) => palavra.length > 2)
        .toSet();

    var porPalavras = 0.0;

    if (palavrasB.isNotEmpty) {
      porPalavras = palavrasA.intersection(palavrasB).length / palavrasB.length;
    }

    final distancia = _levenshtein(a, b);

    final maiorTamanho = a.length > b.length ? a.length : b.length;

    final porCaracteres = maiorTamanho == 0
        ? 1.0
        : 1 - distancia / maiorTamanho;

    return porPalavras > porCaracteres ? porPalavras : porCaracteres;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var anterior = List<int>.generate(b.length + 1, (index) => index);

    for (var i = 1; i <= a.length; i++) {
      final atual = List<int>.filled(b.length + 1, 0);

      atual[0] = i;

      for (var j = 1; j <= b.length; j++) {
        final custo = a[i - 1] == b[j - 1] ? 0 : 1;

        final exclusao = anterior[j] + 1;
        final insercao = atual[j - 1] + 1;
        final substituicao = anterior[j - 1] + custo;

        atual[j] = [
          exclusao,
          insercao,
          substituicao,
        ].reduce((x, y) => x < y ? x : y);
      }

      anterior = atual;
    }

    return anterior[b.length];
  }

  Local? _buscarLocalPorNome(String nome) {
    final busca = _normalizar(nome);

    for (final local in navegacao.locais) {
      if (_normalizar(local.nome).contains(busca)) {
        return local;
      }
    }

    return null;
  }

  List<String> _aliasesDoLocal(Local local) {
    final nome = _normalizar(local.nome);

    final aliases = <String>{nome};

    var simplificado = nome;

    for (final prefixo in [
      'sala de ',
      'sala da ',
      'sala do ',
      'sala dos ',
      'sala das ',
      'sala ',
    ]) {
      if (simplificado.startsWith(prefixo)) {
        simplificado = simplificado.substring(prefixo.length);
        break;
      }
    }

    aliases.add(simplificado);

    switch (nome) {
      case 'sala maker':
        aliases.addAll(['maker', 'espaco maker']);
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
        aliases.addAll(['coordenacao', 'coordenadora']);
        break;

      case 'sala de musica':
        aliases.add('musica');
        break;

      case 'sala de artes':
        aliases.add('artes');
        break;

      case 'sala de esportes':
      case 'sala de esportes teste':
        aliases.addAll(['esportes', 'sala esportes']);
        break;

      case 'banheiros':
        aliases.addAll(['banheiro', 'banheiros']);
        break;

      case 'recepcao':
        aliases.addAll(['recepcao', 'recepcao principal']);
        break;

      case 'sala de deposito':
      case 'deposito':
        aliases.add('deposito');
        break;

      case 'entrada':
        aliases.addAll(['entrada', 'entrada principal']);
        break;
    }

    return aliases.toList();
  }

  bool _comandoRepetir(String comando) {
    return comando == 'repete' ||
        comando == 'repita' ||
        comando == 'repetir' ||
        comando == 'de novo' ||
        comando == 'novamente' ||
        comando.contains('fala de novo') ||
        comando.contains('fale de novo');
  }

  bool _comandoCancelar(String comando) {
    return comando == 'cancelar' ||
        comando == 'cancela' ||
        comando == 'cancele' ||
        comando == 'parar' ||
        comando == 'pare' ||
        comando.contains('cancelar navegacao') ||
        comando.contains('parar navegacao') ||
        comando.contains('cancelar rota');
  }

  bool _comandoNovaRota(String comando) {
    return comando == 'nova rota' ||
        comando == 'novo destino' ||
        comando.contains('outra rota') ||
        comando.contains('mudar destino') ||
        comando.contains('trocar destino');
  }

  bool _perguntaLocalizacao(String comando) {
    return comando == 'onde estou' ||
        comando == 'onde eu estou' ||
        comando == 'onde eu to' ||
        comando == 'onde to' ||
        comando == 'localizacao' ||
        comando == 'minha localizacao' ||
        comando.contains('qual minha localizacao') ||
        comando.contains('qual e minha localizacao');
  }

  bool _perguntaLocaisProximos(String comando) {
    return comando == 'perto' ||
        comando == 'proximo' ||
        comando == 'proximos' ||
        comando.contains('o que tem perto') ||
        comando.contains('oque tem perto') ||
        comando.contains('o que tem aqui') ||
        comando.contains('lugares proximos') ||
        comando.contains('locais proximos');
  }

  bool _comandoVoltarEntrada(String comando) {
    return comando == 'voltar' ||
        comando == 'voltar entrada' ||
        comando == 'voltar para entrada' ||
        comando == 'voltar pra entrada';
  }

  bool _comandoIniciar(String comando) {
    return comando == 'iniciar' ||
        comando == 'comecar' ||
        comando == 'vai' ||
        comando.contains('iniciar navegacao') ||
        comando.contains('comecar navegacao');
  }

  String _normalizar(String texto) {
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
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _finalizarLog() {
    debugPrint('====================================');

    debugPrint('');
  }
}
