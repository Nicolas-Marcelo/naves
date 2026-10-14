import '../../../core/config/beacon_config.dart';
import '../domain/entities/conexao.dart';
import '../domain/entities/grafo.dart';
import '../domain/entities/local.dart';
import '../domain/entities/ponto.dart';

class NavigationConfigData {
  const NavigationConfigData({
    required this.version,
    required this.generatedAt,
    required this.environmentId,
    required this.grafo,
    required this.locais,
    required this.beacons,
  });

  final int version;
  final DateTime generatedAt;
  final int? environmentId;

  final Grafo grafo;
  final List<Local> locais;
  final List<BeaconInfo> beacons;

  factory NavigationConfigData.fromJson(
    Map<String, dynamic> json,
  ) {
    final nodes =
        (json['nodes'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

    final edges =
        (json['edges'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

    final pois =
        (json['pois'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

    final pontos = nodes.map((node) {
      return Ponto(
        id: node['id'] as String,
        x: (node['x'] as num).toDouble(),
        y: (node['y'] as num).toDouble(),
      );
    }).toList();

    final conexoes = edges.map((edge) {
      return Conexao(
        origem: edge['origin'] as String,
        destino: edge['destination'] as String,
        distancia:
            (edge['distance'] as num).toDouble(),
      );
    }).toList();

    final locais = pois.map((poi) {
      return Local(
        nome: poi['name'] as String,
        pontoId: poi['nodeId'] as String,
      );
    }).toList();

    final beacons = nodes
        .where(
          (node) =>
              node['mac'] != null &&
              '${node['mac']}'.trim().isNotEmpty,
        )
        .map((node) {
          final id =
              node['id'] as String;

          return BeaconInfo(
            nodeId: id,
            nome:
                (node['advertisingName']
                            as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? node['advertisingName']
                    as String
                : id,
            mac: node['mac'] as String,
          );
        })
        .toList();

    return NavigationConfigData(
      version: json['version'] as int,
      generatedAt: DateTime.parse(
        json['generatedAt'] as String,
      ),
      environmentId:
          json['environmentId'] as int?,
      grafo: Grafo(
        pontos: pontos,
        conexoes: conexoes,
      ),
      locais: locais,
      beacons: beacons,
    );
  }
}