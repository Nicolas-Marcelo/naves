import 'package:flutter_test/flutter_test.dart';

import 'package:navescence_flutter/features/navigation/data/ambiente_teste.dart';
import 'package:navescence_flutter/features/';

void main() {
  const calculador = CalculadorEstrela();
  final grafo = AmbienteTeste.criarGrafo();

  test('calcula rota de S1 até S3', () {
    final rota = calculador.calcular(
      grafo: grafo,
      origem: 'S1',
      destino: 'S3',
    );

    expect(rota, isNotNull);
    expect(rota!.pontos, ['S1', 'S2', 'S3']);
    expect(rota.distancia, 10);
  });

  test('calcula rota de S3 até S1', () {
    final rota = calculador.calcular(
      grafo: grafo,
      origem: 'S3',
      destino: 'S1',
    );

    expect(rota, isNotNull);
    expect(rota!.pontos, ['S3', 'S2', 'S1']);
    expect(rota.distancia, 10);
  });

  test('origem e destino iguais', () {
    final rota = calculador.calcular(
      grafo: grafo,
      origem: 'S2',
      destino: 'S2',
    );

    expect(rota, isNotNull);
    expect(rota!.pontos, ['S2']);
    expect(rota.distancia, 0);
  });
}