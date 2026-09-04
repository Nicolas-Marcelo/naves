import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/navigation/data/navescence_test_environment.dart';
import '../../../../../lib/navigation/domain/services/a_star_route_planner.dart';

void main() {
  const planner = AStarRoutePlanner();
  final graph = NavescenceTestEnvironment.buildGraph();

  test('calcula rota S1 -> S3 passando por S2', () {
    final route = planner.calculate(
      graph: graph,
      startNodeId: 'S1',
      goalNodeId: 'S3',
    );

    expect(route, isNotNull);
    expect(route!.nodeIds, ['S1', 'S2', 'S3']);
    expect(route.totalCost, 10);
  });

  test('calcula rota inversa S3 -> S1', () {
    final route = planner.calculate(
      graph: graph,
      startNodeId: 'S3',
      goalNodeId: 'S1',
    );

    expect(route, isNotNull);
    expect(route!.nodeIds, ['S3', 'S2', 'S1']);
    expect(route.totalCost, 10);
  });

  test('origem igual ao destino gera rota unitária', () {
    final route = planner.calculate(
      graph: graph,
      startNodeId: 'S2',
      goalNodeId: 'S2',
    );

    expect(route, isNotNull);
    expect(route!.nodeIds, ['S2']);
    expect(route.totalCost, 0);
  });

  test('grafo mantém vizinhança física', () {
    expect(graph.neighbors('S1'), ['S2']);
    expect(graph.neighbors('S2'), ['S1', 'S3']);
    expect(graph.neighbors('S3'), ['S2']);
  });
}
