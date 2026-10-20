import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../accessibility/data/servico_feedback_tatil.dart';
import '../../localization/presentation/localization_controller.dart';

import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/poi_approach.dart';
import '../domain/entities/rota.dart';

import '../domain/services/calculador_rota.dart';
import '../domain/services/gerador_orientacao.dart';

class ControleNavegacao extends ChangeNotifier {
  ControleNavegacao({
    required this.localizacao,
    required this.grafo,
    required this.calculador,
    required this.locais,
    required this.feedbackTatil,
    this.antesDeFalar,
    this.depoisDeFalar,
    this.geradorOrientacao = const GeradorOrientacao(),
  }) {
    localizacao.addListener(
      _mudouLocalizacao,
    );

    _vozPronta =
        _configurarVoz();
  }

  final LocalizationController localizacao;

  Grafo grafo;

  final CalculadorRota calculador;

  List<Local> locais;

  final GeradorOrientacao geradorOrientacao;

  final ServicoFeedbackTatil feedbackTatil;

  final Future<void> Function()? antesDeFalar;
  final Future<void> Function()? depoisDeFalar;

  final FlutterTts _voz =
      FlutterTts();

  late final Future<void> _vozPronta;

  Local? destino;
  Rota? rota;

  String? proximoPonto;

  String estado =
      'SEM_ROTA';

  String mensagem =
      'Escolha um destino.';

  String orientacaoAtual =
      'Escolha um destino para iniciar a navegação.';

  String _ultimoPonto =
      '';

  String _pontoAnteriorRota =
      '';

  int _idFala =
      0;

  String get pontoAtual =>
      localizacao.noAtual;

  String get pontoAnterior =>
      _pontoAnteriorRota;

  bool get navegando =>
      destino != null &&
      rota != null &&
      (estado == 'ROTA_ATIVA' ||
          estado ==
              'ROTA_RECALCULADA');

  void atualizarConfiguracao({
    required Grafo novoGrafo,
    required List<Local> novosLocais,
  }) {
    final destinoAnterior =
        destino;

    grafo =
        novoGrafo;

    locais =
        List.unmodifiable(
      novosLocais,
    );

    rota =
        null;

    proximoPonto =
        null;

    if (destinoAnterior != null) {
      Local? destinoAtualizado;

      for (final local in locais) {
        if (local.nome ==
            destinoAnterior.nome) {
          destinoAtualizado =
              local;

          break;
        }
      }

      if (destinoAtualizado !=
          null) {
        destino =
            destinoAtualizado;

        estado =
            'DESTINO_SELECIONADO';

        mensagem =
            'Destino selecionado: ${destinoAtualizado.nome}.';

        orientacaoAtual =
            'Aguardando início da navegação.';
      } else {
        destino =
            null;

        estado =
            'SEM_ROTA';

        mensagem =
            'O destino selecionado não está mais disponível.';

        orientacaoAtual =
            mensagem;
      }
    }

    _ultimoPonto =
        pontoAtual;

    _pontoAnteriorRota =
        '';

    debugPrint(
      '[NAVEGACAO] Configuração atualizada | '
      '${grafo.pontos.length} nós | '
      '${grafo.conexoes.length} conexões | '
      '${locais.length} locais.',
    );

    notifyListeners();
  }

  Future<void> _configurarVoz() async {
    await _voz.setLanguage(
      'pt-BR',
    );

    await _voz.setVolume(
      1.0,
    );

    await _voz.setPitch(
      1.0,
    );

    await _voz.setSpeechRate(
      kIsWeb ? 1.0 : 0.68,
    );

    await _voz.awaitSpeakCompletion(
      true,
    );

    if (!kIsWeb &&
        defaultTargetPlatform ==
            TargetPlatform.android) {
      try {
        await _voz
            .setAudioAttributesForNavigation();
      } catch (_) {}
    }

    try {
      final resultado =
          await _voz.getVoices;

      if (resultado is! List) {
        return;
      }

      final vozes =
          resultado
              .whereType<Map>()
              .where(
        (voz) {
          final locale =
              '${voz['locale'] ?? ''}'
                  .toLowerCase()
                  .replaceAll(
                    '_',
                    '-',
                  );

          return locale ==
                  'pt-br' ||
              locale.startsWith(
                'pt-br',
              );
        },
      ).toList();

      if (vozes.isEmpty) {
        return;
      }

      vozes.sort(
        (a, b) =>
            _pontuacaoVoz(
              b,
            ).compareTo(
              _pontuacaoVoz(
                a,
              ),
            ),
      );

      final escolhida =
          vozes.first;

      final nome =
          '${escolhida['name'] ?? ''}';

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

  int _pontuacaoVoz(
    Map voz,
  ) {
    final nome =
        '${voz['name'] ?? ''}'
            .toLowerCase();

    var pontos =
        0;

    if (nome.contains(
      'natural',
    )) {
      pontos +=
          100;
    }

    if (nome.contains(
      'google',
    )) {
      pontos +=
          60;
    }

    if (nome.contains(
      'brasil',
    )) {
      pontos +=
          40;
    }

    if (nome.contains(
      'brazil',
    )) {
      pontos +=
          40;
    }

    final qualidade =
        voz['quality'];

    if (qualidade is num) {
      pontos +=
          qualidade.toInt();
    }

    return pontos;
  }

  Future<void> _falar(
    String texto, {
    bool retomarEscuta = true,
  }) async {
    if (texto.trim().isEmpty) {
      return;
    }

    final idAtual =
        ++_idFala;

    await _vozPronta;

    if (idAtual !=
        _idFala) {
      return;
    }

    if (antesDeFalar !=
        null) {
      await antesDeFalar!();
    }

    try {
      await _voz.stop();

      if (idAtual !=
          _idFala) {
        return;
      }

      await _voz.speak(
        texto,
        focus: true,
      );
    } finally {
      if (retomarEscuta &&
          idAtual ==
              _idFala &&
          depoisDeFalar !=
              null) {
        await depoisDeFalar!();
      }
    }
  }

  Future<void> falarMensagem(
    String texto, {
    bool retomarEscuta = true,
  }) async {
    await _falar(
      texto,
      retomarEscuta:
          retomarEscuta,
    );
  }

  Future<void> pararVoz() async {
    _idFala++;

    await _vozPronta;

    await _voz.stop();
  }

  Future<void> repetirOrientacao() async {
    await _falar(
      orientacaoAtual,
    );
  }

  String descricaoLocalizacaoAtual() {
    if (pontoAtual.isEmpty) {
      return 'Ainda não consegui identificar sua localização.';
    }

    final nomes =
        _locaisDoPonto(
      pontoAtual,
    );

    if (nomes.isEmpty) {
      return 'Sua localização foi identificada.';
    }

    return 'Você está próximo de ${_juntarNomes(nomes)}.';
  }

  String descricaoDestinoAtual() {
    if (destino == null) {
      return 'Você não possui um destino definido.';
    }

    return 'Seu destino atual é ${destino!.nome}.';
  }

  String descricaoSituacaoAtual() {
    if (pontoAtual.isEmpty) {
      return 'Ainda não consegui identificar sua localização.';
    }

    final localizacaoTexto =
        descricaoLocalizacaoAtual();

    if (destino == null) {
      return '$localizacaoTexto '
          'Você não possui uma rota ativa.';
    }

    return '$localizacaoTexto '
        'Seu destino é ${destino!.nome}. '
        '$orientacaoAtual';
  }

  String descricaoLocaisProximos() {
    if (pontoAtual.isEmpty) {
      return 'Ainda não consegui identificar sua localização.';
    }

    final pontosProximos =
        <String>{
      pontoAtual,
      ...grafo.vizinhos(
        pontoAtual,
      ),
    };

    final nomes =
        <String>{};

    for (final local in locais) {
      if (pontosProximos.contains(
        local.pontoId,
      )) {
        nomes.add(
          local.nome,
        );
      }
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

    if (nomes.length ==
        1) {
      return nomes.first;
    }

    if (nomes.length ==
        2) {
      return '${nomes[0]} e ${nomes[1]}';
    }

    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  void selecionarDestino(
    Local? local,
  ) {
    destino =
        local;

    rota =
        null;

    proximoPonto =
        null;

    _pontoAnteriorRota =
        '';

    if (local == null) {
      estado =
          'SEM_ROTA';

      mensagem =
          'Escolha um destino.';

      orientacaoAtual =
          'Escolha um destino para iniciar a navegação.';
    } else {
      estado =
          'DESTINO_SELECIONADO';

      mensagem =
          'Destino selecionado: ${local.nome}.';

      orientacaoAtual =
          'Aguardando início da navegação.';
    }

    notifyListeners();
  }

  Future<bool> iniciarRota() async {
    if (destino == null) {
      mensagem =
          'Escolha um destino primeiro.';

      orientacaoAtual =
          mensagem;

      notifyListeners();

      await feedbackTatil.executar(
        FeedbackTatil.erro,
      );

      await _falar(
        mensagem,
      );

      return false;
    }

    if (pontoAtual.isEmpty) {
      mensagem =
          'Ainda não consegui identificar sua localização.';

      orientacaoAtual =
          mensagem;

      notifyListeners();

      await feedbackTatil.executar(
        FeedbackTatil.sinalPerdido,
      );

      await _falar(
        mensagem,
      );

      return false;
    }

    _ultimoPonto =
        pontoAtual;

    _pontoAnteriorRota =
        '';

    _calcularRota();

    if (estado ==
        'ROTA_ATIVA') {
      mensagem =
          'Navegando para ${destino!.nome}.';

      orientacaoAtual =
          'Siga em frente.';

      notifyListeners();

      await feedbackTatil.executar(
        FeedbackTatil.frente,
      );

      await _falar(
        'Rota iniciada para ${destino!.nome}. '
        'Siga em frente.',
      );

      return true;
    }

    if (estado ==
        'DESTINO_ALCANCADO') {
      return true;
    }

    if (estado ==
        'SEM_CAMINHO') {
      await feedbackTatil.executar(
        FeedbackTatil.erro,
      );

      await _falar(
        orientacaoAtual,
      );
    }

    return false;
  }

  void _calcularRota() {
    if (destino == null ||
        pontoAtual.isEmpty) {
      return;
    }

    rota =
        calculador.calcular(
      grafo: grafo,
      origem: pontoAtual,
      destino:
          destino!.pontoId,
    );

    if (rota == null) {
      estado =
          'SEM_CAMINHO';

      proximoPonto =
          null;

      mensagem =
          'Não foi possível encontrar uma rota.';

      orientacaoAtual =
          mensagem;

      return;
    }

    if (rota!.pontos.length ==
        1) {
      unawaited(
        _concluirDestino(),
      );

      return;
    }

    proximoPonto =
        rota!.pontos[1];

    estado =
        'ROTA_ATIVA';
  }

  void _mudouLocalizacao() {
    unawaited(
      _processarMudancaLocalizacao(),
    );
  }

  Future<void> _processarMudancaLocalizacao() async {
    final novoPonto =
        pontoAtual;

    if (novoPonto.isEmpty ||
        novoPonto ==
            _ultimoPonto) {
      return;
    }

    final pontoAnterior =
        _ultimoPonto;

    _ultimoPonto =
        novoPonto;

    if (destino == null ||
        rota == null) {
      return;
    }

    if (novoPonto ==
        destino!.pontoId) {
      _pontoAnteriorRota =
          pontoAnterior;

      await _concluirDestino();

      notifyListeners();

      return;
    }

    final pontoEsperado =
        proximoPonto;

    final seguiuRota =
        pontoEsperado != null &&
            novoPonto ==
                pontoEsperado;

    final voltou =
        _pontoAnteriorRota
                .isNotEmpty &&
            novoPonto ==
                _pontoAnteriorRota;

    if (seguiuRota) {
      _pontoAnteriorRota =
          pontoAnterior;

      _calcularRota();

      if (rota == null ||
          proximoPonto == null) {
        notifyListeners();

        return;
      }

      await _gerarOrientacao(
        anterior:
            pontoAnterior,
        atual:
            novoPonto,
        proximo:
            proximoPonto!,
        rotaRecalculada:
            false,
      );

      notifyListeners();

      return;
    }

    _pontoAnteriorRota =
        pontoAnterior;

    await _recalcularPorDesvio(
      pontoAnterior:
          pontoAnterior,
      novoPonto:
          novoPonto,
      voltou:
          voltou,
    );

    notifyListeners();
  }

  Future<void> _recalcularPorDesvio({
    required String pontoAnterior,
    required String novoPonto,
    required bool voltou,
  }) async {
    _calcularRota();

    if (rota == null ||
        proximoPonto == null) {
      if (estado ==
          'SEM_CAMINHO') {
        await _falar(
          orientacaoAtual,
        );
      }

      return;
    }

    estado =
        'ROTA_RECALCULADA';

    mensagem =
        'Rota recalculada.';

    await feedbackTatil.executar(
      FeedbackTatil.recalculo,
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    final prefixo =
        voltou
            ? 'Você retornou pelo caminho anterior. Recalculando rota.'
            : 'Você saiu da rota. Recalculando rota.';

    await _gerarOrientacao(
      anterior:
          pontoAnterior,
      atual:
          novoPonto,
      proximo:
          proximoPonto!,
      rotaRecalculada:
          true,
      mensagemRecalculo:
          prefixo,
    );
  }

  Future<void> _gerarOrientacao({
    required String anterior,
    required String atual,
    required String proximo,
    required bool rotaRecalculada,
    String? mensagemRecalculo,
  }) async {
    final pontoAnterior =
        grafo.buscarPonto(
      anterior,
    );

    final pontoAtual =
        grafo.buscarPonto(
      atual,
    );

    final pontoProximo =
        grafo.buscarPonto(
      proximo,
    );

    if (pontoAnterior == null ||
        pontoAtual == null ||
        pontoProximo == null) {
      orientacaoAtual =
          'Siga em frente.';

      mensagem =
          rotaRecalculada
              ? 'Rota recalculada.'
              : 'Navegação em andamento.';

      await feedbackTatil.executar(
        FeedbackTatil.frente,
      );

      if (rotaRecalculada) {
        await _falar(
          '${mensagemRecalculo ?? 'Rota recalculada.'} '
          '$orientacaoAtual',
        );
      } else {
        await _falar(
          orientacaoAtual,
        );
      }

      return;
    }

    final orientacao =
        geradorOrientacao.calcular(
      anterior:
          pontoAnterior,
      atual:
          pontoAtual,
      proximo:
          pontoProximo,
    );

    final instrucao =
        geradorOrientacao.mensagem(
      orientacao,
    );

    orientacaoAtual =
        _simplificarOrientacao(
      instrucao,
    );

    await _feedbackDaOrientacao(
      orientacaoAtual,
    );

    if (rotaRecalculada) {
      estado =
          'ROTA_RECALCULADA';

      mensagem =
          'Rota recalculada.';

      await _falar(
        '${mensagemRecalculo ?? 'Rota recalculada.'} '
        '$orientacaoAtual',
      );

      return;
    }

    estado =
        'ROTA_ATIVA';

    mensagem =
        'Navegando para ${destino!.nome}.';

    await _falar(
      orientacaoAtual,
    );
  }

  Future<void> _concluirDestino() async {
    final destinoAtual =
        destino;

    if (destinoAtual ==
        null) {
      return;
    }

    final abordagem =
        destinoAtual
            .abordagemVindoDe(
      _pontoAnteriorRota,
    );

    final mensagemChegada =
        _mensagemChegada(
      destino:
          destinoAtual,
      abordagem:
          abordagem,
    );

    estado =
        'DESTINO_ALCANCADO';

    mensagem =
        'Destino alcançado.';

    orientacaoAtual =
        mensagemChegada;

    notifyListeners();

    await feedbackTatil.executar(
      FeedbackTatil.chegada,
    );

    await _falar(
      mensagemChegada,
    );

    destino =
        null;

    rota =
        null;

    proximoPonto =
        null;

    _pontoAnteriorRota =
        '';

    estado =
        'SEM_ROTA';

    mensagem =
        'Escolha um novo destino.';

    orientacaoAtual =
        'Escolha um novo destino para iniciar outra navegação.';

    notifyListeners();
  }

  String _mensagemChegada({
    required Local destino,
    PoiApproach? abordagem,
  }) {
    if (abordagem == null) {
      return 'Você chegou ao ponto de acesso de ${destino.nome}. '
          'Siga o piso tátil até a entrada.';
    }

    final partes =
        <String>[
      'Você chegou ao ponto de acesso de ${destino.nome}.',
    ];

    final lado =
        _descricaoLado(
      abordagem.side,
    );

    if (lado.isNotEmpty) {
      partes.add(
        'Seu destino está $lado.',
      );
    }

    final distancia =
        abordagem.distanceMeters;

    if (distancia != null &&
        distancia > 0) {
      partes.add(
        'Siga o piso tátil por aproximadamente '
        '${_formatarDistancia(distancia)}.',
      );
    }

    final instrucao =
        abordagem.instruction
            ?.trim();

    if (instrucao != null &&
        instrucao.isNotEmpty) {
      partes.add(
        instrucao,
      );
    }

    return partes.join(
      ' ',
    );
  }

  String _descricaoLado(
    PoiSide side,
  ) {
    switch (side) {
      case PoiSide.left:
        return 'à esquerda';

      case PoiSide.right:
        return 'à direita';

      case PoiSide.front:
        return 'à frente';

      case PoiSide.unknown:
        return '';
    }
  }

  String _formatarDistancia(
    double distancia,
  ) {
    if (distancia ==
        distancia.roundToDouble()) {
      final metros =
          distancia.toInt();

      return metros ==
              1
          ? '1 metro'
          : '$metros metros';
    }

    return '${distancia.toStringAsFixed(1).replaceAll('.', ',')} metros';
  }

  Future<void> _feedbackDaOrientacao(
    String orientacao,
  ) async {
    final normalizado =
        _normalizarTexto(
      orientacao,
    );

    if (normalizado.contains(
      'direita',
    )) {
      await feedbackTatil.executar(
        FeedbackTatil.direita,
      );

      return;
    }

    if (normalizado.contains(
      'esquerda',
    )) {
      await feedbackTatil.executar(
        FeedbackTatil.esquerda,
      );

      return;
    }

    await feedbackTatil.executar(
      FeedbackTatil.frente,
    );
  }

  String _simplificarOrientacao(
    String texto,
  ) {
    final normalizado =
        _normalizarTexto(
      texto,
    );

    if (normalizado.contains(
      'direita',
    )) {
      return 'Vire à direita.';
    }

    if (normalizado.contains(
      'esquerda',
    )) {
      return 'Vire à esquerda.';
    }

    return 'Siga em frente.';
  }

  String _normalizarTexto(
    String texto,
  ) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> cancelarRota() async {
    destino =
        null;

    rota =
        null;

    proximoPonto =
        null;

    _pontoAnteriorRota =
        '';

    estado =
        'SEM_ROTA';

    mensagem =
        'Escolha um destino.';

    orientacaoAtual =
        'Navegação cancelada.';

    notifyListeners();

    await feedbackTatil.executar(
      FeedbackTatil.cancelado,
    );

    await _falar(
      'Navegação cancelada.',
    );
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