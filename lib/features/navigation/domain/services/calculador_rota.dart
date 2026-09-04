import '../entities/grafo.dart';
import '../entities/rota.dart';

abstract class CalculadorRota {
  Rota? calcular({
    required Grafo grafo,
    required String origem,
    required String destino,
  });
}