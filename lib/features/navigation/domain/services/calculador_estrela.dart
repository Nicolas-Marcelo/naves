import 'dart:math';
import '../entities/grafo.dart';
import '../entities/ponto.dart';
import '../entities/rota.dart';
import 'calculador_rota.dart';

/* Implementa o algoritmo A* auxiliando na navegação do usuário pelo ambiente, calculando o custo das conexões */

class CalculadorEstrela implements CalculadorRota {
  const CalculadorEstrela();

  @override
  Rota? calcular({
    required Grafo grafo,
    required String origem,
    required String destino,
  }) {
    if (origem == destino) {
      return Rota(
        pontos: [origem],
        distancia: 0,
      );
    }

    final abertos = <String>{origem};
    final veioDe = <String, String>{};

    final custos = <String, double>{
      origem: 0,
    };

    final estimativas = <String, double>{
      origem: _calcularHeuristica(grafo, origem, destino),
    };

    while (abertos.isNotEmpty) {
      final atual = abertos.reduce((a, b) {
        final valorA = estimativas[a] ?? double.infinity;
        final valorB = estimativas[b] ?? double.infinity;

        return valorA <= valorB ? a : b;
      });

      if (atual == destino) {
        return _montarRota(
          grafo: grafo,
          veioDe: veioDe,
          destino: destino,
        );
      }

      abertos.remove(atual);

      for (final vizinho in grafo.vizinhos(atual)) {
        final distancia = grafo.distancia(atual, vizinho);
        if (distancia == null) continue;

        final novoCusto =
            (custos[atual] ?? double.infinity) + distancia;

        if (novoCusto < (custos[vizinho] ?? double.infinity)) {
          veioDe[vizinho] = atual;
          custos[vizinho] = novoCusto;

          estimativas[vizinho] =
              novoCusto + _calcularHeuristica(grafo, vizinho, destino);

          abertos.add(vizinho);
        }
      }
    }

    return null;
  }

  double _calcularHeuristica(
    Grafo grafo,
    String origem,
    String destino,
  ) {
    final pontoOrigem = grafo.buscarPonto(origem);
    final pontoDestino = grafo.buscarPonto(destino);

    if (pontoOrigem == null || pontoDestino == null) return 0;

    return _distanciaEntre(pontoOrigem, pontoDestino);
  }

  double _distanciaEntre(Ponto a, Ponto b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;

    return sqrt((dx * dx) + (dy * dy));
  }

  Rota _montarRota({
    required Grafo grafo,
    required Map<String, String> veioDe,
    required String destino,
  }) {
    final pontos = <String>[destino];
    var atual = destino;

    while (veioDe.containsKey(atual)) {
      atual = veioDe[atual]!;
      pontos.insert(0, atual);
    }

    var distanciaTotal = 0.0;

    for (var i = 0; i < pontos.length - 1; i++) {
      distanciaTotal +=
          grafo.distancia(pontos[i], pontos[i + 1]) ?? 0;
    }

    return Rota(
      pontos: pontos,
      distancia: distanciaTotal,
    );
  }
}