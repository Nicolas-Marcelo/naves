import 'poi_approach.dart';

class Local {
  const Local({
    required this.nome,
    required this.pontoId,
    this.id = '',
    this.tipo,
    this.descricao,
    this.approaches = const [],
    this.edgeStartNodeId,
    this.edgeEndNodeId,
    this.edgePosition,
    this.tactileDistanceMeters,
    this.exitInstruction,
  });

  final String id;

  final String nome;

  /// Sensor/nó de referência tradicional.
  final String pontoId;

  final String? tipo;
  final String? descricao;

  final List<PoiApproach> approaches;

  /// Caso o POI esteja fisicamente entre dois sensores.
  final String? edgeStartNodeId;
  final String? edgeEndNodeId;

  /// 0.0 = edgeStartNodeId
  /// 1.0 = edgeEndNodeId
  final double? edgePosition;

  /// Distância lateral entre o piso tátil principal
  /// e a porta/local.
  final double? tactileDistanceMeters;

  /// Orientação para sair do local e encontrar
  /// o piso tátil principal.
  final String? exitInstruction;

  bool get possuiPosicaoNoTrecho {
    return edgeStartNodeId != null &&
        edgeStartNodeId!.isNotEmpty &&
        edgeEndNodeId != null &&
        edgeEndNodeId!.isNotEmpty &&
        edgePosition != null;
  }

  factory Local.fromJson(Map<String, dynamic> json) {
    final approachesJson = json['approaches'];

    final approaches = approachesJson is List
        ? approachesJson
              .whereType<Map>()
              .map(
                (item) => PoiApproach.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <PoiApproach>[];

    return Local(
      id: '${json['id'] ?? json['code'] ?? ''}',

      nome: '${json['name'] ?? json['nome'] ?? ''}',

      pontoId: '${json['nodeId'] ?? json['nodeCode'] ?? json['pontoId'] ?? ''}',

      tipo: _stringOrNull(json['type'] ?? json['tipo']),

      descricao: _stringOrNull(json['description'] ?? json['descricao']),

      approaches: approaches,

      edgeStartNodeId: _stringOrNull(json['edgeStartNodeId']),

      edgeEndNodeId: _stringOrNull(json['edgeEndNodeId']),

      edgePosition: _doubleOrNull(json['edgePosition']),

      tactileDistanceMeters: _doubleOrNull(json['tactileDistanceMeters']),

      exitInstruction: _stringOrNull(json['exitInstruction']),
    );
  }

  PoiApproach? abordagemVindoDe(String fromNodeId) {
    for (final approach in approaches) {
      if (approach.fromNodeId == fromNodeId) {
        return approach;
      }
    }

    return null;
  }

  double? distanciaNoTrechoVindoDe({
    required String fromNodeId,
    required double edgeDistance,
  }) {
    if (!possuiPosicaoNoTrecho) {
      return null;
    }

    final position = edgePosition!.clamp(0.0, 1.0);

    if (fromNodeId == edgeStartNodeId) {
      return edgeDistance * position;
    }

    if (fromNodeId == edgeEndNodeId) {
      return edgeDistance * (1.0 - position);
    }

    return null;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value');
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final texto = '$value'.trim();

    return texto.isEmpty ? null : texto;
  }
}
