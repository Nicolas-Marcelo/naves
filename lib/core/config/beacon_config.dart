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
  static const List<BeaconInfo> beacons = [
    BeaconInfo(nodeId: 'S1', nome: 'NAV_S01', mac: '68:09:47:9E:DC:16'),
    BeaconInfo(nodeId: 'S2', nome: 'NAV_S02', mac: '20:9B:A9:69:23:A6'),
    BeaconInfo(nodeId: 'S3', nome: 'NAV_S03', mac: '68:09:47:9D:8D:DA'),
    BeaconInfo(nodeId: 'S4', nome: 'NAV_S04', mac: 'B4:BF:E9:C0:7F:4A'),
    BeaconInfo(nodeId: 'S5', nome: 'NAV_S05', mac: 'B4:BF:E9:14:A8:82'),
  ];

  static BeaconInfo? porMac(String mac) {
    final endereco = _normalizarMac(mac);

    for (final beacon in beacons) {
      if (_normalizarMac(beacon.mac) == endereco) {
        return beacon;
      }
    }

    return null;
  }

  static BeaconInfo? porNodeId(String nodeId) {
    final id = nodeId.trim().toUpperCase();

    for (final beacon in beacons) {
      if (beacon.nodeId.toUpperCase() == id) {
        return beacon;
      }
    }

    return null;
  }

  static BeaconInfo? porNome(String nome) {
    final busca = nome.trim().toUpperCase();

    for (final beacon in beacons) {
      if (beacon.nome.toUpperCase() == busca) {
        return beacon;
      }
    }

    return null;
  }

  static String _normalizarMac(String mac) {
    return mac.trim().toUpperCase().replaceAll('-', ':');
  }
}
