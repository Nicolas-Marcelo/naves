import 'package:flutter/foundation.dart';

import '../../../../localization/presentation/localization_controller.dart';
import '../../../domain/entities/grafo.dart';
import '../../../domain/entities/local.dart';
import '../../../domain/entities/rota.dart';
import '../../../domain/services/calculador_rota.dart';

class ControleNavegacao extends ChangeNotifier {
  ControleNavegacao({
    required this.localizacao,
    required this.grafo,
    required this.calculador,
    required this.locais,
  }) {
    localizacao.addListener(_mudouLocalizacao);
  }

  final LocalizationController localizacao;
  final Grafo grafo;
  final CalculadorRota calculador;
  final List<Local> locais;

  Local? destino;
  Rota? rota;
  String? proximoPonto;

  String estado = 'SEM_ROTA';
  String mensagem = 'Escolha um destino.';
  String _ultimoPonto = '';

  String get pontoAtual => localizacao.noAtual;

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
        mensagem = 'Caminho diferente detectado. Siga para $proximoPonto.';
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
    super.dispose();
  }
}