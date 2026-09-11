import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../localization/presentation/localization_controller.dart';
import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/rota.dart';
import '../domain/services/calculador_rota.dart';

/* Responsável por todas funções com relação a navegação do usuário, acompanhando, recalculando e 
fornecendo as informações ao usuário */

class ControleNavegacao extends ChangeNotifier {
  ControleNavegacao({
    required this.localizacao,
    required this.grafo,
    required this.calculador,
    required this.locais,
  }) {
    localizacao.addListener(_mudouLocalizacao);
    _configurarVoz();
  }

  final LocalizationController localizacao;
  final Grafo grafo;
  final CalculadorRota calculador;
  final List<Local> locais;

  final FlutterTts _voz = FlutterTts();

  Local? destino;
  Rota? rota;
  String? proximoPonto;

  String estado = 'SEM_ROTA';
  String mensagem = 'Escolha um destino.';

  String _ultimoPonto = '';

  String get pontoAtual => localizacao.noAtual;

  Future<void> _configurarVoz() async {
    await _voz.setLanguage('pt-BR');
    await _voz.setSpeechRate(0.5);
    await _voz.setVolume(1.0);
  }

  Future<void> _falarSensor(String ponto) async {
    String? mensagem;

    switch (ponto) {
      case 'S1':
        mensagem = 'Embaixo do sensor 1';
        break;
      case 'S2':
        mensagem = 'Embaixo do sensor 2';
        break;
      case 'S3':
        mensagem = 'Embaixo do sensor 3';
        break;
    }

    if (mensagem == null) return;

    await _voz.stop();
    await _voz.speak(mensagem);
  }

  void selecionarDestino(Local? local) {
    destino = local;
    rota = null;
    proximoPonto = null;

    if (local == null) {
      estado = 'SEM_ROTA';
      mensagem = 'Escolha um destino.';
    } else {
      estado = 'DESTINO_SELECIONADO';
      mensagem = 'Destino selecionado.';
    }

    notifyListeners();
  }

  void iniciarRota() {
    if (destino == null) {
      mensagem = 'Escolha um destino primeiro.';
      notifyListeners();
      return;
    }

    if (pontoAtual.isEmpty) {
      mensagem = 'Aguardando sua localização.';
      notifyListeners();
      return;
    }

    _ultimoPonto = pontoAtual;
    _calcularRota();

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
      return;
    }

    if (rota!.pontos.length == 1) {
      estado = 'DESTINO_ALCANCADO';
      proximoPonto = null;
      mensagem = 'Você chegou ao destino.';
      return;
    }

    proximoPonto = rota!.pontos[1];

    estado = 'ROTA_ATIVA';
    mensagem = 'Siga em direção ao $proximoPonto.';
  }

  void _mudouLocalizacao() {
    final novoPonto = pontoAtual;

    if (novoPonto.isEmpty || novoPonto == _ultimoPonto) return;

    _ultimoPonto = novoPonto;

    _falarSensor(novoPonto);

    if (destino == null || rota == null) return;

    if (novoPonto == destino!.pontoId) {
      estado = 'DESTINO_ALCANCADO';
      proximoPonto = null;
      mensagem = 'Você chegou ao destino.';

      notifyListeners();
      return;
    }

    final pontoEsperado = proximoPonto;

    _calcularRota();

    if (pontoEsperado != null && novoPonto != pontoEsperado) {
      estado = 'ROTA_RECALCULADA';

      if (proximoPonto != null) {
        mensagem =
            'Caminho diferente detectado. Siga para $proximoPonto.';
      }
    } else if (proximoPonto != null) {
      mensagem = 'Continue em direção ao $proximoPonto.';
    }

    notifyListeners();
  }

  void cancelarRota() {
    destino = null;
    rota = null;
    proximoPonto = null;

    estado = 'SEM_ROTA';
    mensagem = 'Escolha um destino.';

    notifyListeners();
  }

  @override
  void dispose() {
    localizacao.removeListener(_mudouLocalizacao);
    _voz.stop();
    super.dispose();
  }
}