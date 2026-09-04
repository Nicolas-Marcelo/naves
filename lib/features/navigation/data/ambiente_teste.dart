import '../domain/entities/conexao.dart';
import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/ponto.dart';

class AmbienteTeste {
  static const pontos = [
    Ponto(
      id: 'S1',
      x: 0,
      y: 0,
    ),
    Ponto(
      id: 'S2',
      x: 5,
      y: 0,
    ),
    Ponto(
      id: 'S3',
      x: 10,
      y: 0,
    ),
  ];

  static const conexoes = [
    Conexao(
      origem: 'S1',
      destino: 'S2',
      distancia: 5,
    ),
    Conexao(
      origem: 'S2',
      destino: 'S3',
      distancia: 5,
    ),
  ];

  static const locais = [
    Local(
      nome: 'Ponto 1',
      pontoId: 'S1',
    ),
    Local(
      nome: 'Ponto 2',
      pontoId: 'S2',
    ),
    Local(
      nome: 'Ponto 3',
      pontoId: 'S3',
    ),
  ];

  static Grafo criarGrafo() {
    return const Grafo(
      pontos: pontos,
      conexoes: conexoes,
    );
  }
}