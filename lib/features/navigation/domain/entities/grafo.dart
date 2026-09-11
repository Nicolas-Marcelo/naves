import 'conexao.dart';
import 'ponto.dart';

/* Representa o grafo do ambiente com pontos e conexões, além das funções que são utilizadas pelo sistema referindo-se a grafos */

class Grafo {
  const Grafo({
    required this.pontos,
    required this.conexoes,
  });

  final List<Ponto> pontos;
  final List<Conexao> conexoes;

  Ponto? buscarPonto(String id) {
    for (final ponto in pontos) {
      if (ponto.id == id) return ponto;
    }

    return null;
  }

  List<String> vizinhos(String pontoId) {
    final resultado = <String>[];

    for (final conexao in conexoes) {
      if (conexao.origem == pontoId) {
        resultado.add(conexao.destino);
      }

      if (conexao.destino == pontoId) {
        resultado.add(conexao.origem);
      }
    }

    return resultado;
  }

  double? distancia(String origem, String destino) {
    for (final conexao in conexoes) {
      final sentidoNormal =
          conexao.origem == origem && conexao.destino == destino;

      final sentidoContrario =
          conexao.origem == destino && conexao.destino == origem;

      if (sentidoNormal || sentidoContrario) {
        return conexao.distancia;
      }
    }

    return null;
  }
}