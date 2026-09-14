import 'dart:math';

import '../entities/ponto.dart';

enum TipoOrientacao {
  reto,
  direita,
  esquerda,
  retorno,
}

class GeradorOrientacao {
  const GeradorOrientacao();

  TipoOrientacao calcular({
    required Ponto anterior,
    required Ponto atual,
    required Ponto proximo,
  }) {
    final direcaoEntrada = atan2(
      atual.y - anterior.y,
      atual.x - anterior.x,
    );

    final direcaoSaida = atan2(
      proximo.y - atual.y,
      proximo.x - atual.x,
    );

    var diferenca = direcaoSaida - direcaoEntrada;

    while (diferenca > pi) {
      diferenca -= 2 * pi;
    }

    while (diferenca < -pi) {
      diferenca += 2 * pi;
    }

    final graus = diferenca * 180 / pi;

    if (graus.abs() <= 30) return TipoOrientacao.reto;
    if (graus.abs() >= 150) return TipoOrientacao.retorno;

    if (graus < 0) return TipoOrientacao.direita;

    return TipoOrientacao.esquerda;
  }

  String mensagem(TipoOrientacao orientacao) {
    switch (orientacao) {
      case TipoOrientacao.reto:
        return 'Continue em frente.';
      case TipoOrientacao.direita:
        return 'Vire à direita.';
      case TipoOrientacao.esquerda:
        return 'Vire à esquerda.';
      case TipoOrientacao.retorno:
        return 'Faça o retorno.';
    }
  }
}