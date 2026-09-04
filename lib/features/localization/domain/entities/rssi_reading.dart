class RssiReading {
  const RssiReading({
    required this.nodeId,
    required this.rssi,
    required this.timestamp,
  });

  final String nodeId;
  final int rssi;
  final DateTime timestamp;
}
