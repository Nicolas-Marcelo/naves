class EventoTestePercurso {
  const EventoTestePercurso({
    required this.teste,
    required this.sentido,
    required this.timestamp,
    required this.timestampEpochMs,
    required this.tempoMs,
    required this.evento,
    this.sensorManual,
    this.sensorBle,
    this.rssiS01,
    this.m15S01,
    this.rssiS02,
    this.m15S02,
    this.rssiS03,
    this.m15S03,
  });

  final String teste;
  final String sentido;

  final DateTime timestamp;
  final int timestampEpochMs;
  final int tempoMs;

  final String evento;

  final String? sensorManual;
  final String? sensorBle;

  final int? rssiS01;
  final double? m15S01;

  final int? rssiS02;
  final double? m15S02;

  final int? rssiS03;
  final double? m15S03;

  double get tempoSegundos => tempoMs / 1000;

  List<String> toCsvValues() {
    return [
      teste,
      sentido,
      timestamp.toIso8601String(),
      timestampEpochMs.toString(),
      tempoMs.toString(),
      tempoSegundos.toStringAsFixed(3),
      evento,
      sensorManual ?? '',
      sensorBle ?? '',
      rssiS01?.toString() ?? '',
      m15S01?.toStringAsFixed(2) ?? '',
      rssiS02?.toString() ?? '',
      m15S02?.toStringAsFixed(2) ?? '',
      rssiS03?.toString() ?? '',
      m15S03?.toStringAsFixed(2) ?? '',
    ];
  }
}
