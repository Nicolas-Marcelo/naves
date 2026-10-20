import 'poi_approach.dart';

class Local {
  const Local({
    required this.nome,
    required this.pontoId,
    this.id = '',
    this.tipo,
    this.descricao,
    this.approaches = const [],
  });

  final String id;
  final String nome;
  final String pontoId;

  final String? tipo;
  final String? descricao;

  final List<PoiApproach> approaches;

  factory Local.fromJson(
    Map<String, dynamic> json,
  ) {
    final approachesJson =
        json['approaches'];

    final approaches =
        approachesJson is List
            ? approachesJson
                .whereType<Map>()
                .map(
                  (item) =>
                      PoiApproach.fromJson(
                    Map<String, dynamic>.from(
                      item,
                    ),
                  ),
                )
                .toList()
            : <PoiApproach>[];

    return Local(
      id: '${json['id'] ?? json['code'] ?? ''}',
      nome:
          '${json['name'] ?? json['nome'] ?? ''}',
      pontoId:
          '${json['nodeId'] ?? json['nodeCode'] ?? json['pontoId'] ?? ''}',
      tipo: _stringOrNull(
        json['type'] ??
            json['tipo'],
      ),
      descricao: _stringOrNull(
        json['description'] ??
            json['descricao'],
      ),
      approaches: approaches,
    );
  }

  PoiApproach? abordagemVindoDe(
    String fromNodeId,
  ) {
    for (final approach in approaches) {
      if (approach.fromNodeId ==
          fromNodeId) {
        return approach;
      }
    }

    return null;
  }

  static String? _stringOrNull(
    dynamic value,
  ) {
    if (value == null) return null;

    final texto =
        '$value'.trim();

    return texto.isEmpty
        ? null
        : texto;
  }
}