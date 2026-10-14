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
  static List<BeaconInfo> _beacons = [];

  static List<BeaconInfo> get beacons =>
      List.unmodifiable(_beacons);

  static void configurar(
    List<BeaconInfo> beacons,
  ) {
    _beacons = List.unmodifiable(
      beacons,
    );
  }

  static BeaconInfo? porMac(String mac) {
    final endereco =
        _normalizarMac(mac);

    for (final beacon in _beacons) {
      if (
        _normalizarMac(
          beacon.mac,
        ) ==
        endereco
      ) {
        return beacon;
      }
    }

    return null;
  }

  static BeaconInfo? porNodeId(
    String nodeId,
  ) {
    final id =
        nodeId.trim().toUpperCase();

    for (final beacon in _beacons) {
      if (
        beacon.nodeId
                .toUpperCase() ==
            id
      ) {
        return beacon;
      }
    }

    return null;
  }

  static BeaconInfo? porNome(
    String nome,
  ) {
    final busca =
        nome.trim().toUpperCase();

    for (final beacon in _beacons) {
      if (
        beacon.nome
                .toUpperCase() ==
            busca
      ) {
        return beacon;
      }
    }

    return null;
  }

  static String _normalizarMac(
    String mac,
  ) {
    return mac
        .trim()
        .toUpperCase()
        .replaceAll('-', ':');
  }
}