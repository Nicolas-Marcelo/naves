import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../localization/presentation/localization_controller.dart';
import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/rota.dart';
import '../domain/services/calculador_rota.dart';
import '../domain/services/gerador_orientacao.dart';

/* Responsável pelas funções de navegação, acompanhando a localização,
calculando a rota e fornecendo orientações ao usuário. */

class ControleNavegacao extends ChangeNotifier {
  ControleNavegacao({
    required this.localizacao,
    required this.grafo,
    required this.calculador,
    required this.locais,
    this.geradorOrientacao = const GeradorOrientacao(),
  }) {
    localizacao.addListener(_mudouLocalizacao);
    _vozPronta = _configurarVoz();
  }

  final LocalizationController localizacao;
  final Grafo grafo;
  final CalculadorRota calculador;
  final List<Local> locais;
  final GeradorOrientacao geradorOrientacao;

  final FlutterTts _voz = FlutterTts();
  late final Future<void> _vozPronta;

  Local? destino;
  Rota? rota;
  String? proximoPonto;

  String estado = 'SEM_ROTA';
  String mensagem = 'Escolha um destino.';
  String orientacaoAtual = 'Escolha um destino para iniciar a navegação.';

  String _ultimoPonto = '';
  int _idFala = 0;

  String get pontoAtual => localizacao.noAtual;

  Future<void> _configurarVoz() async {
    await _voz.setLanguage('pt-BR');
    await _voz.setVolume(1.0);
    await _voz.setPitch(1.0);

    await _voz.setSpeechRate(
      kIsWeb ? 0.95 : 0.58,
    );

    await _voz.awaitSpeakCompletion(true);

    try {
      final resultado = await _voz.getVoices;

      if (resultado is! List) return;

      final vozes = resultado
          .whereType<Map>()
          .where((voz) {
            final locale = '${voz['locale'] ?? ''}'
                .toLowerCase()
                .replaceAll('_', '-');

            return locale == 'pt-br' ||
                locale.startsWith('pt-br');
          })
          .toList();

      if (vozes.isEmpty) return;

      vozes.sort(
        (a, b) => _pontuacaoVoz(b).compareTo(
          _pontuacaoVoz(a),
        ),
      );

      final escolhida = vozes.first;

      final nome = '${escolhida['name'] ?? ''}';
      final locale = '${escolhida['locale'] ?? 'pt-BR'}';

      if (nome.isNotEmpty) {
        await _voz.setVoice({
          'name': nome,
          'locale': locale,
        });
      }
    } catch (_) {
      // Mantém a voz padrão pt-BR caso o aparelho
      // não permita consultar as vozes disponíveis.
    }
  }

  int _pontuacaoVoz(Map voz) {
    final nome = '${voz['name'] ?? ''}'.toLowerCase();

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

    final exigeInternet = '${voz['network_required'] ?? ''}'
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

    if (idAtual != _idFala) return;

    await _voz.speak(texto);
  }

  Future<void> falarMensagem(String texto) async {
    await _falar(texto);
  }

  Future<void> pararVoz() async {
    _idFala++;

    await _vozPronta;
    await _voz.stop();
  }

  Future<void> repetirOrientacao() async {
    await _falar(orientacaoAtual);
  }

  String descricaoLocalizacaoAtual() {
    if (pontoAtual.isEmpty) {
      return 'Ainda não consegui identificar sua localização.';
    }

    final nomes = _locaisDoPonto(pontoAtual);

    if (nomes.isEmpty) {
      return 'Sua localização foi identificada no ponto $pontoAtual.';
    }

    return 'Você está próximo de ${_juntarNomes(nomes)}.';
  }

  String descricaoLocaisProximos() {
    if (pontoAtual.isEmpty) {
      return 'Ainda não consegui identificar sua localização.';
    }

    final pontosProximos = <String>{
      pontoAtual,
      ...grafo.vizinhos(pontoAtual),
    };

    final nomes = <String>{};

    for (final local in locais) {
      if (pontosProximos.contains(local.pontoId)) {
        nomes.add(local.nome);
      }
    }

    if (nomes.isEmpty) {
      return 'Não encontrei locais próximos cadastrados.';
    }

    return 'Próximo de você estão ${_juntarNomes(nomes.toList())}.';
  }

  List<String> _locaisDoPonto(String pontoId) {
    return locais
        .where((local) => local.pontoId == pontoId)
        .map((local) => local.nome)
        .toList();
  }

  String _contextoProximoPonto(String pontoId) {
    final nomes = _locaisDoPonto(pontoId);

    if (nomes.isEmpty) return '';

    return 'Siga em direção à área de ${_juntarNomes(nomes)}.';
  }

  String _juntarNomes(List<String> nomes) {
    if (nomes.isEmpty) return '';

    if (nomes.length == 1) {
      return nomes.first;
    }

    if (nomes.length == 2) {
      return '${nomes[0]} e ${nomes[1]}';
    }

    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  void selecionarDestino(Local? local) {
    destino = local;
    rota = null;
    proximoPonto = null;

    if (local == null) {
      estado = 'SEM_ROTA';
      mensagem = 'Escolha um destino.';
      orientacaoAtual =
          'Escolha um destino para iniciar a navegação.';
    } else {
      estado = 'DESTINO_SELECIONADO';
      mensagem = 'Destino selecionado: ${local.nome}.';
      orientacaoAtual = 'Pressione iniciar navegação.';
    }

    notifyListeners();
  }

  void iniciarRota() {
    if (destino == null) {
      mensagem = 'Escolha um destino primeiro.';
      orientacaoAtual = mensagem;

      notifyListeners();
      return;
    }

    if (pontoAtual.isEmpty) {
      mensagem = 'Aguardando sua localização.';
      orientacaoAtual = mensagem;

      notifyListeners();
      return;
    }

    _ultimoPonto = pontoAtual;

    _calcularRota();

    if (estado == 'ROTA_ATIVA') {
      mensagem = 'Navegando para ${destino!.nome}.';

      final contexto = proximoPonto == null
          ? ''
          : _contextoProximoPonto(proximoPonto!);

      orientacaoAtual = contexto.isEmpty
          ? 'Siga pelo corredor até o próximo ponto.'
          : 'Siga pelo corredor. $contexto';

      _falar(
        'Rota iniciada para ${destino!.nome}. $orientacaoAtual',
      );
    } else if (
        estado == 'DESTINO_ALCANCADO' ||
        estado == 'SEM_CAMINHO') {
      _falar(orientacaoAtual);
    }

    notifyListeners();
  }

  void _calcularRota() {
    if (destino == null || pontoAtual.isEmpty) return;

    rota = calculador.calcular(
      grafo: grafo,
      origem: pontoAtual,
      destino: destino!.pontoId,
    );

    if (rota == null) {
      estado = 'SEM_CAMINHO';
      proximoPonto = null;

      mensagem = 'Não foi possível encontrar uma rota.';
      orientacaoAtual = mensagem;

      return;
    }

    if (rota!.pontos.length == 1) {
      estado = 'DESTINO_ALCANCADO';
      proximoPonto = null;

      mensagem = 'Destino alcançado.';
      orientacaoAtual =
          'Você chegou ao destino ${destino!.nome}.';

      return;
    }

    proximoPonto = rota!.pontos[1];
    estado = 'ROTA_ATIVA';
  }

  void _mudouLocalizacao() {
    final novoPonto = pontoAtual;

    if (
        novoPonto.isEmpty ||
        novoPonto == _ultimoPonto) {
      return;
    }

    final pontoAnterior = _ultimoPonto;
    _ultimoPonto = novoPonto;

    if (destino == null || rota == null) return;

    if (novoPonto == destino!.pontoId) {
      estado = 'DESTINO_ALCANCADO';
      proximoPonto = null;

      mensagem = 'Destino alcançado.';
      orientacaoAtual =
          'Você chegou ao destino ${destino!.nome}.';

      _falar(orientacaoAtual);

      notifyListeners();
      return;
    }

    final pontoEsperado = proximoPonto;

    _calcularRota();

    if (rota == null || proximoPonto == null) {
      notifyListeners();
      return;
    }

    final rotaRecalculada =
        pontoEsperado != null &&
        novoPonto != pontoEsperado;

    _gerarOrientacao(
      anterior: pontoAnterior,
      atual: novoPonto,
      proximo: proximoPonto!,
      rotaRecalculada: rotaRecalculada,
    );

    notifyListeners();
  }

  void _gerarOrientacao({
    required String anterior,
    required String atual,
    required String proximo,
    required bool rotaRecalculada,
  }) {
    final pontoAnterior = grafo.buscarPonto(anterior);
    final pontoAtual = grafo.buscarPonto(atual);
    final pontoProximo = grafo.buscarPonto(proximo);

    if (
        pontoAnterior == null ||
        pontoAtual == null ||
        pontoProximo == null) {
      orientacaoAtual =
          'Continue seguindo pelo corredor.';

      mensagem = 'Navegação em andamento.';

      _falar(orientacaoAtual);
      return;
    }

    final orientacao = geradorOrientacao.calcular(
      anterior: pontoAnterior,
      atual: pontoAtual,
      proximo: pontoProximo,
    );

    final instrucao =
        geradorOrientacao.mensagem(orientacao);

    final contexto =
        _contextoProximoPonto(proximo);

    orientacaoAtual = contexto.isEmpty
        ? instrucao
        : '$instrucao $contexto';

    if (rotaRecalculada) {
      estado = 'ROTA_RECALCULADA';
      mensagem = 'Rota recalculada.';

      _falar(
        'Rota recalculada. $orientacaoAtual',
      );

      return;
    }

    estado = 'ROTA_ATIVA';
    mensagem = 'Navegando para ${destino!.nome}.';

    _falar(orientacaoAtual);
  }

  void cancelarRota() {
    destino = null;
    rota = null;
    proximoPonto = null;

    estado = 'SEM_ROTA';
    mensagem = 'Escolha um destino.';
    orientacaoAtual =
        'Navegação cancelada. Escolha um novo destino.';

    _falar(
      'Navegação cancelada.',
    );

    notifyListeners();
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