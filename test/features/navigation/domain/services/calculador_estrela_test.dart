import 'package:flutter_test/flutter_test.dart';

import 'package:navescence_flutter/features/navigation/domain/entities/conexao.dart';
import 'package:navescence_flutter/features/navigation/domain/entities/grafo.dart';
import 'package:navescence_flutter/features/navigation/domain/entities/ponto.dart';
import 'package:navescence_flutter/features/navigation/domain/services/calculador_estrela.dart';

void main() {
  late Grafo grafo;
  late CalculadorEstrela calculador;

  setUp(() {
    grafo = const Grafo(
      pontos: [
        Ponto(id: 'NAV_S01', x: 0, y: 0),
        Ponto(id: 'NAV_S02', x: 0, y: 5),
        Ponto(id: 'NAV_S03', x: 0, y: 10),
        Ponto(id: 'NAV_S04', x: 10, y: 10),
        Ponto(id: 'NAV_S05', x: 10, y: 5),
      ],
      conexoes: [
        Conexao(
          origem: 'NAV_S01',
          destino: 'NAV_S02',
          distancia: 5,
        ),
        Conexao(
          origem: 'NAV_S02',
          destino: 'NAV_S03',
          distancia: 5,
        ),
        Conexao(
          origem: 'NAV_S03',
          destino: 'NAV_S04',
          distancia: 10,
        ),
        Conexao(
          origem: 'NAV_S04',
          destino: 'NAV_S05',
          distancia: 5,
        ),
      ],
    );

    calculador = const CalculadorEstrela();
  });

  test(
    'deve calcular rota entre NAV_S01 e NAV_S05',
    () {
      final rota = calculador.calcular(
        grafo: grafo,
        origem: 'NAV_S01',
        destino: 'NAV_S05',
      );

      expect(rota, isNotNull);

      expect(
        rota!.pontos,
        [
          'NAV_S01',
          'NAV_S02',
          'NAV_S03',
          'NAV_S04',
          'NAV_S05',
        ],
      );

      expect(rota.distancia, 25);
    },
  );

  test(
    'deve retornar rota com apenas o ponto quando origem e destino forem iguais',
    () {
      final rota = calculador.calcular(
        grafo: grafo,
        origem: 'NAV_S03',
        destino: 'NAV_S03',
      );

      expect(rota, isNotNull);
      expect(rota!.pontos, ['NAV_S03']);
      expect(rota.distancia, 0);
    },
  );

  test(
    'deve retornar null quando não existir caminho até o destino',
    () {
      const grafoSemCaminho = Grafo(
        pontos: [
          Ponto(id: 'NAV_S01', x: 0, y: 0),
          Ponto(id: 'NAV_S02', x: 0, y: 5),
          Ponto(id: 'NAV_S03', x: 20, y: 20),
        ],
        conexoes: [
          Conexao(
            origem: 'NAV_S01',
            destino: 'NAV_S02',
            distancia: 5,
          ),
        ],
      );

      final rota = calculador.calcular(
        grafo: grafoSemCaminho,
        origem: 'NAV_S01',
        destino: 'NAV_S03',
      );

      expect(rota, isNull);
    },
  );
}