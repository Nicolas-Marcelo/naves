import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../localization/presentation/localization_controller.dart';
import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/rota.dart';
import '../domain/services/calculador_rota.dart';
import '../domain/services/gerador_orientacao.dart';

class ControleNavegacao extends ChangeNotifier {
  ControleNavegacao({
    required this.localizacao,
    required this.grafo,
    required this.calculador,
    required this.locais,
    required Object? feedbackTatil,
    Future<void> Function()? antesDeFalar,
    Future<void> Function()? depoisDeFalar,
    this.geradorOrientacao = const GeradorOrientacao(),
  })  : _antesDeFalar = antesDeFalar,
        _depoisDeFalar = depoisDeFalar {
    localizacao.addListener(_mudouLocalizacao);
    _vozPronta = _configurarVoz();
  }

  final LocalizationController localizacao;
  final CalculadorRota calculador;
  final GeradorOrientacao geradorOrientacao;

  final Future<void> Function()? _antesDeFalar;
  final Future<void> Function()? _depoisDeFalar;

  Grafo grafo;
  List<Local> locais;

  final FlutterTts _voz = FlutterTts();
  late final Future<void> _vozPronta;

  Local? origem;
  Local? destino;

  Rota? rota;
  String? proximoPonto;

  String estado = 'AGUARDANDO_ORIGEM';
  String mensagem = 'Informe onde você está.';
  String orientacaoAtual = 'Onde você está agora?';

  int _idFala = 0;

  bool get temOrigem => origem != null;
  bool get temDestino => destino != null;
  bool get rotaAtiva => estado == 'ROTA_ATIVA';

  String get pontoAtual => localizacao.noAtual;
  String get pontoOrigem => origem?.pontoId ?? '';

  Future<void> _configurarVoz() async {
    await _voz.setLanguage('pt-BR');
    await _voz.setVolume(1.0);
    await _voz.setPitch(1.0);
    await _voz.setSpeechRate(kIsWeb ? 0.95 : 0.58);
    await _voz.awaitSpeakCompletion(true);

    try {
      final resultado = await _voz.getVoices;

      if (resultado is! List) return;

      final vozes = resultado.whereType<Map>().where((voz) {
        final locale = '${voz['locale'] ?? ''}'
            .toLowerCase()
            .replaceAll('_', '-');

        return locale == 'pt-br' ||
            locale.startsWith('pt-br');
      }).toList();

      if (vozes.isEmpty) return;

      vozes.sort(
        (a, b) =>
            _pontuacaoVoz(b).compareTo(_pontuacaoVoz(a)),
      );

      final escolhida = vozes.first;

      final nome = '${escolhida['name'] ?? ''}';
      final locale =
          '${escolhida['locale'] ?? 'pt-BR'}';

      if (nome.isNotEmpty) {
        await _voz.setVoice({
          'name': nome,
          'locale': locale,
        });
      }
    } catch (_) {}
  }

  int _pontuacaoVoz(Map voz) {
    final nome =
        '${voz['name'] ?? ''}'.toLowerCase();

    var pontos = 0;

    if (nome.contains('natural')) pontos += 100;
    if (nome.contains('google')) pontos += 60;
    if (nome.contains('brasil')) pontos += 40;
    if (nome.contains('brazil')) pontos += 40;
    if (nome.contains('portuguese')) pontos += 20;

    final qualidade = voz['quality'];

    if (qualidade is num) {
      pontos += qualidade.toInt();
    }

    final exigeInternet =
        '${voz['network_required'] ?? ''}'
            .toLowerCase();

    if (exigeInternet == 'false') {
      pontos += 10;
    }

    return pontos;
  }

  Future<void> _falar(String texto) async {
    if (texto.trim().isEmpty) return;

    await _vozPronta;

    final idAtual = ++_idFala;

    await _voz.stop();

    if (_antesDeFalar != null) {
      await _antesDeFalar!();
    }

    if (idAtual != _idFala) return;

    try {
      await _voz.speak(texto);
    } finally {
      if (_depoisDeFalar != null) {
        await _depoisDeFalar!();
      }
    }
  }

  Future<void> falarMensagem(String texto) async {
    await _falar(texto);
  }

  Future<void> pararVoz() async {
    _idFala++;
    await _voz.stop();
  }

  Future<void> repetirOrientacao() async {
    await _falar(orientacaoAtual);
  }

  void selecionarOrigem(Local? local) {
    origem = local;

    destino = null;
    rota = null;
    proximoPonto = null;

    if (local == null) {
      estado = 'AGUARDANDO_ORIGEM';
      mensagem = 'Informe onde você está.';
      orientacaoAtual = 'Onde você está agora?';
    } else {
      estado = 'AGUARDANDO_DESTINO';
      mensagem = 'Origem: ${local.nome}.';
      orientacaoAtual =
          'Para onde você deseja ir?';
    }

    notifyListeners();
  }

  void selecionarDestino(Local? local) {
    if (origem == null) {
      destino = null;

      estado = 'AGUARDANDO_ORIGEM';
      mensagem =
          'Informe primeiro onde você está.';
      orientacaoAtual =
          'Onde você está agora?';

      notifyListeners();
      return;
    }

    destino = local;

    rota = null;
    proximoPonto = null;

    if (local == null) {
      estado = 'AGUARDANDO_DESTINO';
      mensagem = 'Escolha um destino.';
      orientacaoAtual =
          'Para onde você deseja ir?';
    } else {
      estado = 'DESTINO_SELECIONADO';
      mensagem = 'Destino: ${local.nome}.';
      orientacaoAtual =
          'Pronto para iniciar a navegação.';
    }

    notifyListeners();
  }

  void reiniciarNavegacao() {
    origem = null;
    destino = null;

    rota = null;
    proximoPonto = null;

    estado = 'AGUARDANDO_ORIGEM';
    mensagem = 'Informe onde você está.';
    orientacaoAtual = 'Onde você está agora?';

    notifyListeners();
  }

  Future<void> perguntarOrigem() async {
    estado = 'AGUARDANDO_ORIGEM';
    mensagem = 'Onde você está agora?';
    orientacaoAtual = mensagem;

    notifyListeners();

    await _falar(mensagem);
  }

  Future<void> perguntarDestino() async {
    if (origem == null) {
      await perguntarOrigem();
      return;
    }

    estado = 'AGUARDANDO_DESTINO';
    mensagem = 'Para onde você deseja ir?';
    orientacaoAtual = mensagem;

    notifyListeners();

    await _falar(mensagem);
  }

  void iniciarRota() {
    _iniciarRota();
  }

  Future<void> iniciarRotaAguardando() async {
    await _iniciarRota();
  }

  Future<void> _iniciarRota() async {
    if (origem == null) {
      estado = 'AGUARDANDO_ORIGEM';

      mensagem =
          'Informe primeiro onde você está.';

      orientacaoAtual =
          'Onde você está agora?';

      notifyListeners();

      await _falar(orientacaoAtual);
      return;
    }

    if (destino == null) {
      estado = 'AGUARDANDO_DESTINO';

      mensagem = 'Escolha um destino.';

      orientacaoAtual =
          'Para onde você deseja ir?';

      notifyListeners();

      await _falar(orientacaoAtual);
      return;
    }

    _calcularRota();

    if (rota == null) {
      notifyListeners();

      await _falar(orientacaoAtual);
      return;
    }

    if (rota!.pontos.length == 1) {
      estado = 'DESTINO_ALCANCADO';

      proximoPonto = null;

      mensagem =
          'Origem e destino utilizam o mesmo ponto de acesso.';

      orientacaoAtual =
          'Saia da sua sala e encontre o chão tátil.';

      notifyListeners();

      await _falar(orientacaoAtual);
      return;
    }

    estado = 'ROTA_ATIVA';

    proximoPonto =
        rota!.pontos[1];

    mensagem =
        'Navegando para ${destino!.nome}.';

    orientacaoAtual =
        _gerarInstrucaoSaida();

    notifyListeners();

    await _falar(
      orientacaoAtual,
    );
  }

  void _calcularRota() {
    if (origem == null ||
        destino == null) {
      return;
    }

    rota = calculador.calcular(
      grafo: grafo,
      origem: origem!.pontoId,
      destino: destino!.pontoId,
    );

    if (rota == null) {
      estado = 'SEM_CAMINHO';

      proximoPonto = null;

      mensagem =
          'Não foi possível encontrar uma rota.';

      orientacaoAtual =
          'Não encontrei um caminho até o destino.';

      return;
    }

    if (rota!.pontos.length > 1) {
      proximoPonto =
          rota!.pontos[1];
    }
  }

  String _gerarInstrucaoSaida() {
    final origemAtual = origem;
    final rotaAtual = rota;

    if (origemAtual == null ||
        rotaAtual == null ||
        rotaAtual.pontos.length < 2) {
      return 'Saia da sua sala e encontre o chão tátil.';
    }

    final sensorAcesso =
        grafo.buscarPonto(
      origemAtual.pontoId,
    );

    final proximoSensor =
        grafo.buscarPonto(
      rotaAtual.pontos[1],
    );

    if (sensorAcesso == null ||
        proximoSensor == null) {
      return 'Saia da sua sala e encontre o chão tátil.';
    }

    final poiX = origemAtual.x;
    final poiY = origemAtual.y;

    final sensorX = sensorAcesso.x;
    final sensorY = sensorAcesso.y;

    final proximoX = proximoSensor.x;
    final proximoY = proximoSensor.y;

    if (poiX == null ||
        poiY == null ||
        sensorX == null ||
        sensorY == null ||
        proximoX == null ||
        proximoY == null) {
      return 'Saia da sua sala e encontre o chão tátil.';
    }

    /*
     * Vetor 1:
     * posição da sala/POI -> sensor de acesso.
     *
     * Representa a direção em que o usuário chega
     * ao chão tátil.
     */
    final entradaX =
        sensorX - poiX;

    final entradaY =
        sensorY - poiY;

    /*
     * Vetor 2:
     * sensor de acesso -> próximo sensor da rota.
     *
     * Representa a direção que o usuário deverá
     * seguir ao entrar no corredor.
     */
    final saidaX =
        proximoX - sensorX;

    final saidaY =
        proximoY - sensorY;

    /*
     * Produto vetorial em 2D.
     *
     * Considerando o plano cartesiano utilizado
     * na topologia:
     *
     * positivo = esquerda
     * negativo = direita
     * próximo de zero = em frente
     */
    final produtoVetorial =
        entradaX * saidaY -
            entradaY * saidaX;

    const tolerancia = 0.0001;

    debugPrint('');
    debugPrint(
      '========== SAÍDA DO AMBIENTE ==========',
    );

    debugPrint(
      '[NAVEGAÇÃO] POI: ${origemAtual.nome} '
      '(${poiX.toStringAsFixed(2)}, ${poiY.toStringAsFixed(2)})',
    );

    debugPrint(
      '[NAVEGAÇÃO] Sensor: ${origemAtual.pontoId} '
      '(${sensorX.toStringAsFixed(2)}, ${sensorY.toStringAsFixed(2)})',
    );

    debugPrint(
      '[NAVEGAÇÃO] Próximo: ${rotaAtual.pontos[1]} '
      '(${proximoX.toStringAsFixed(2)}, ${proximoY.toStringAsFixed(2)})',
    );

    debugPrint(
      '[NAVEGAÇÃO] Vetor entrada: '
      '(${entradaX.toStringAsFixed(2)}, ${entradaY.toStringAsFixed(2)})',
    );

    debugPrint(
      '[NAVEGAÇÃO] Vetor saída: '
      '(${saidaX.toStringAsFixed(2)}, ${saidaY.toStringAsFixed(2)})',
    );

    debugPrint(
      '[NAVEGAÇÃO] Produto vetorial: '
      '${produtoVetorial.toStringAsFixed(2)}',
    );

    if (produtoVetorial >
        tolerancia) {
      debugPrint(
        '[NAVEGAÇÃO] Direção: ESQUERDA',
      );

      debugPrint(
        '========================================',
      );

      debugPrint('');

      return 'Saia da sua sala, encontre o chão tátil e vire à esquerda.';
    }

    if (produtoVetorial <
        -tolerancia) {
      debugPrint(
        '[NAVEGAÇÃO] Direção: DIREITA',
      );

      debugPrint(
        '========================================',
      );

      debugPrint('');

      return 'Saia da sua sala, encontre o chão tátil e vire à direita.';
    }

    debugPrint(
      '[NAVEGAÇÃO] Direção: EM FRENTE',
    );

    debugPrint(
      '========================================',
    );

    debugPrint('');

    return 'Saia da sua sala, encontre o chão tátil e siga em frente.';
  }

  String descricaoLocalizacaoAtual() {
    if (origem != null) {
      return 'Você informou que está em ${origem!.nome}.';
    }

    if (pontoAtual.isEmpty) {
      return 'Sua localização ainda não foi informada.';
    }

    final nomes =
        _locaisDoPonto(
      pontoAtual,
    );

    if (nomes.isEmpty) {
      return 'O sensor mais próximo é $pontoAtual.';
    }

    return 'Pelo sinal Bluetooth, você está próximo de ${_juntarNomes(nomes)}.';
  }

  String descricaoLocaisProximos() {
    final pontoReferencia =
        origem?.pontoId ??
            pontoAtual;

    if (pontoReferencia.isEmpty) {
      return 'Informe primeiro onde você está.';
    }

    final pontosProximos = <String>{
      pontoReferencia,
      ...grafo.vizinhos(
        pontoReferencia,
      ),
    };

    final nomes = <String>{};

    for (final local in locais) {
      if (pontosProximos.contains(
        local.pontoId,
      )) {
        nomes.add(
          local.nome,
        );
      }
    }

    if (origem != null) {
      nomes.remove(
        origem!.nome,
      );
    }

    if (nomes.isEmpty) {
      return 'Não encontrei locais próximos cadastrados.';
    }

    return 'Próximo de você estão ${_juntarNomes(nomes.toList())}.';
  }

  List<String> _locaisDoPonto(
    String pontoId,
  ) {
    return locais
        .where(
          (local) =>
              local.pontoId ==
              pontoId,
        )
        .map(
          (local) =>
              local.nome,
        )
        .toList();
  }

  String _juntarNomes(
    List<String> nomes,
  ) {
    if (nomes.isEmpty) {
      return '';
    }

    if (nomes.length == 1) {
      return nomes.first;
    }

    if (nomes.length == 2) {
      return '${nomes[0]} e ${nomes[1]}';
    }

    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  void atualizarConfiguracao({
    required Grafo novoGrafo,
    required List<Local> novosLocais,
  }) {
    final nomeOrigem =
        origem?.nome;

    final nomeDestino =
        destino?.nome;

    grafo = novoGrafo;
    locais = novosLocais;

    origem = nomeOrigem == null
        ? null
        : _buscarLocalPorNomeExato(
            nomeOrigem,
          );

    destino = nomeDestino == null
        ? null
        : _buscarLocalPorNomeExato(
            nomeDestino,
          );

    rota = null;
    proximoPonto = null;

    if (origem == null) {
      estado = 'AGUARDANDO_ORIGEM';

      mensagem =
          'Informe onde você está.';

      orientacaoAtual =
          'Onde você está agora?';
    } else if (destino == null) {
      estado = 'AGUARDANDO_DESTINO';

      mensagem =
          'Origem: ${origem!.nome}.';

      orientacaoAtual =
          'Para onde você deseja ir?';
    } else {
      estado = 'DESTINO_SELECIONADO';

      mensagem =
          'Origem e destino definidos.';

      orientacaoAtual =
          'Pronto para iniciar a navegação.';
    }

    notifyListeners();
  }

  Local? _buscarLocalPorNomeExato(
    String nome,
  ) {
    for (final local in locais) {
      if (local.nome == nome) {
        return local;
      }
    }

    return null;
  }

  void cancelarRota() {
    reiniciarNavegacao();

    _falar(
      'Navegação cancelada.',
    );
  }

  void _mudouLocalizacao() {
    /*
     * Por enquanto não vamos orientar o usuário
     * durante o corredor.
     *
     * O BLE continua funcionando normalmente,
     * mas a próxima etapa será tratar:
     *
     * sensor atual -> próximo sensor -> orientação
     *
     * depois que validarmos a saída dos ambientes.
     */
  }

  @override
  void dispose() {
    localizacao.removeListener(
      _mudouLocalizacao,
    );

    _idFala++;

    _voz.stop();

    super.dispose();
  }
}