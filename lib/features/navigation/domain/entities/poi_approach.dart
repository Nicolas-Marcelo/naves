enum PoiSide { left, right, front, unknown }

class PoiApproach {
  const PoiApproach({
    required this.fromNodeId,
    required this.side,
    this.distanceMeters,
    this.instruction,
    this.exitSide = PoiSide.unknown,
    this.exitInstruction,
  });

  final String fromNodeId;

  final PoiSide side;

  final double? distanceMeters;
  final String? instruction;

  final PoiSide exitSide;
  final String? exitInstruction;

  factory PoiApproach.fromJson(Map<String, dynamic> json) {
    return PoiApproach(
      fromNodeId: '${json['fromNodeId'] ?? ''}',

      side: _sideFromJson('${json['side'] ?? ''}'),

      distanceMeters: _doubleOrNull(json['distanceMeters']),

      instruction: _stringOrNull(json['instruction']),

      exitSide: _sideFromJson('${json['exitSide'] ?? ''}'),

      exitInstruction: _stringOrNull(json['exitInstruction']),
    );
  }

  static PoiSide _sideFromJson(String value) {
    switch (value.trim().toUpperCase()) {
      case 'LEFT':
        return PoiSide.left;

      case 'RIGHT':
        return PoiSide.right;

      case 'FRONT':
        return PoiSide.front;

      default:
        return PoiSide.unknown;
    }
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
