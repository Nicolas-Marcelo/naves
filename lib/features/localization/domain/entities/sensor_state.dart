import '../../../../core/config/localization_config.dart';

/* Responsável por filtrar as leituras de cada sensor, validando
os valores de RSSI e calculando as médias utilizadas pelo sistema. */

class SensorState {
  SensorState({required this.id, required this.nome, required this.mac});

  final String id;
  final String nome;
  final String mac;

  DateTime? ultimaLeitura;

  final List<int> _historico = [];

  int? ultimoRssiRecebido;
  int? ultimoRssiValido;

  int leiturasRecebidas = 0;
  int leiturasValidas = 0;
  int leiturasDescartadas = 0;

  bool get detectado {
    if (ultimaLeitura == null) return false;

    return DateTime.now().difference(ultimaLeitura!) <
        LocalizationConfig.tempoSemSinal;
  }

  double? media(int tamanho) {
    if (_historico.length < tamanho) return null;

    final valores = _historico.sublist(_historico.length - tamanho);

    return valores.reduce((a, b) => a + b) / valores.length;
  }

  double? get m5 => media(5);
  double? get m10 => media(10);
  double? get m15 => media(15);
  double? get m20 => media(20);
  double? get m25 => media(25);

  void adicionarLeitura(int rssi, DateTime horario) {
    leiturasRecebidas++;
    ultimoRssiRecebido = rssi;

    if (rssi < LocalizationConfig.rssiMinimo ||
        rssi > LocalizationConfig.rssiMaximo) {
      leiturasDescartadas++;
      return;
    }

    if (_historico.length >= LocalizationConfig.janelaMediana) {
      final recentes = _historico.sublist(
        _historico.length - LocalizationConfig.janelaMediana,
      );

      final ordenados = [...recentes]..sort();
      final mediana = ordenados[ordenados.length ~/ 2];

      if ((rssi - mediana).abs() > LocalizationConfig.desvioMaximoOutlier) {
        leiturasDescartadas++;
        return;
      }
    }

    leiturasValidas++;
    ultimoRssiValido = rssi;
    ultimaLeitura = horario;

    _historico.add(rssi);

    if (_historico.length > 25) {
      _historico.removeAt(0);
    }
  }

  void limpar() {
    ultimaLeitura = null;

    _historico.clear();

    ultimoRssiRecebido = null;
    ultimoRssiValido = null;

    leiturasRecebidas = 0;
    leiturasValidas = 0;
    leiturasDescartadas = 0;
  }
}
