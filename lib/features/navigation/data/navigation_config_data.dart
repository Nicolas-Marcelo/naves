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

  factory NavigationConfigData.fromJson(Map<String, dynamic> json) {
    final nodes = (json['nodes'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final edges = (json['edges'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final pois = (json['pois'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final pontos = nodes.map((node) {
      return Ponto(
        id: '${node['id'] ?? ''}',
        x: _numero(node['x']),
        y: _numero(node['y']),
      );
    }).toList();

    final conexoes = edges.map((edge) {
      return Conexao(
        origem: '${edge['origin'] ?? ''}',
        destino: '${edge['destination'] ?? ''}',
        distancia: _numero(edge['distance']),
      );
    }).toList();

    final locais = pois.map((poi) {
      return Local.fromJson(poi);
    }).toList();

    final beacons = nodes
        .where(
          (node) => node['mac'] != null && '${node['mac']}'.trim().isNotEmpty,
        )
        .map((node) {
          final id = '${node['id'] ?? ''}';

          final advertisingName = '${node['advertisingName'] ?? ''}'.trim();

          return BeaconInfo(
            nodeId: id,
            nome: advertisingName.isNotEmpty ? advertisingName : id,
            mac: '${node['mac'] ?? ''}',
          );
        })
        .toList();

    return NavigationConfigData(
      version: _inteiro(json['version']),
      generatedAt: _data(json['generatedAt']),
      environmentId: _inteiroOuNull(json['environmentId']),
      grafo: Grafo(pontos: pontos, conexoes: conexoes),
      locais: locais,
      beacons: beacons,
    );
  }

  static double _numero(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0.0;
  }

  static int _inteiro(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  static int? _inteiroOuNull(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value');
  }

  static DateTime _data(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    return DateTime.tryParse('$value') ?? DateTime.now();
  }
}
