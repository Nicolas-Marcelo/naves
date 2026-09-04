import '../../../../core/config/localization_config.dart';

class SensorState {
  SensorState({
    required this.id,
    required this.nome,
    required this.mac,
  });

  final String id;
  final String nome;
  final String mac;

  DateTime? ultimaLeitura;
  final List<int> _historico = [];

  bool get detectado {
    if (ultimaLeitura == null) return false;

    return DateTime.now().difference(ultimaLeitura!) <
        LocalizationConfig.tempoSemSinal;
  }

  double? get m15 {
    if (_historico.length < LocalizationConfig.tamanhoM15) return null;

    final valores = _historico.sublist(
      _historico.length - LocalizationConfig.tamanhoM15,
    );

    return valores.reduce((a, b) => a + b) / valores.length;
  }

  void adicionarLeitura(int rssi, DateTime horario) {
    if (rssi < LocalizationConfig.rssiMinimo ||
        rssi > LocalizationConfig.rssiMaximo) {
      return;
    }

    if (_historico.length >= LocalizationConfig.janelaMediana) {
      final recentes = _historico.sublist(
        _historico.length - LocalizationConfig.janelaMediana,
      );

      final ordenados = [...recentes]..sort();
      final mediana = ordenados[ordenados.length ~/ 2];

      if ((rssi - mediana).abs() >
          LocalizationConfig.desvioMaximoOutlier) {
        return;
      }
    }

    ultimaLeitura = horario;
    _historico.add(rssi);

    if (_historico.length > LocalizationConfig.tamanhoM15) {
      _historico.removeAt(0);
    }
  }

  void limpar() {
    ultimaLeitura = null;
    _historico.clear();
  }
}
