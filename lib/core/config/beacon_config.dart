class BeaconInfo {
  const BeaconInfo({
    required this.nodeId,
    required this.nome,
    required this.mac,
  });

  final String nodeId;
  final String nome;
  final String mac;
}

abstract final class BeaconConfig {
  static const beacons = [
    BeaconInfo(
      nodeId: 'S1',
      nome: 'BEACON_01',
      mac: '68:09:47:9D:8D:DA',
    ),
    BeaconInfo(
      nodeId: 'S2',
      nome: 'BEACON_02',
      mac: '20:9B:A9:69:23:A6',
    ),
    BeaconInfo(
      nodeId: 'S3',
      nome: 'BEACON_03',
      mac: '68:09:47:9E:DC:16',
    ),
    BeaconInfo(
      nodeId: 'S4',
      nome: 'BEACON_04',
      mac: 'B4:BF:E9:14:A8:82',
    ),

    BeaconInfo(
      nodeId: 'S5',
      nome: 'BEACON_05',
      mac: 'B4:BF:E9:C0:7F:4A'
    )
  ];

  static BeaconInfo? porMac(String mac) {
    final endereco = mac.toUpperCase();

    for (final beacon in beacons) {
      if (beacon.mac == endereco) return beacon;
    }

    return null;
  }
}