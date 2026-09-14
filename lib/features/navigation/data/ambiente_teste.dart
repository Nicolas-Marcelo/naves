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
      x: 0,
      y: 5,
    ),
    Ponto(
      id: 'S3',
      x: 0,
      y: 10,
    ),
    Ponto(
      id: 'S4',
      x: 10,
      y: 10,
    ),
    Ponto(
      id: 'S5',
      x: 10,
      y: 5,
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
    Conexao(
      origem: 'S3',
      destino: 'S4',
      distancia: 10,
    ),
    Conexao(
      origem: 'S4',
      destino: 'S5',
      distancia: 5,
    ),
  ];

  static const locais = [
    Local(
      nome: 'Entrada',
      pontoId: 'S1',
    ),
    Local(
      nome: 'Recepção',
      pontoId: 'S1',
    ),
    Local(
      nome: 'Sala de esportes',
      pontoId: 'S2',
    ),
    Local(
      nome: 'Sala de Informática',
      pontoId: 'S2',
    ),
    Local(
      nome: 'Sala da coordenação',
      pontoId: 'S3',
    ),
    Local(
      nome: 'Sala de música',
      pontoId: 'S3',
    ),
    Local(
      nome: 'Banheiros',
      pontoId: 'S4',
    ),
    Local(
      nome: 'Depósito',
      pontoId: 'S4',
    ),
    Local(
      nome: 'Sala de artes',
      pontoId: 'S5',
    ),
    Local(
      nome: 'Sala Maker',
      pontoId: 'S5',
    ),
  ];

  static Grafo criarGrafo() {
    return const Grafo(
      pontos: pontos,
      conexoes: conexoes,
    );
  }
}