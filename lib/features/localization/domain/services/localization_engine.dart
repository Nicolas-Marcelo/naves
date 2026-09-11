import '../../../../core/config/beacon_config.dart';
import '../../../../core/config/localization_config.dart';
import '../../../navigation/domain/entities/grafo.dart';
import '../entities/rssi_reading.dart';
import '../entities/sensor_state.dart';

/* Recebe os valores de M15 e determina a localização do usuário no sistema, além de controlar o handoff */

class LocalizationEngine {
  LocalizationEngine(this.grafo)
      : sensores = {
          for (final beacon in BeaconConfig.beacons)
            beacon.nodeId: SensorState(
              id: beacon.nodeId,
              nome: beacon.nome,
              mac: beacon.mac,
            ),
        };

  final Grafo grafo;
  final Map<String, SensorState> sensores;

  final List<_AmostraNavegacao> _amostras = [];

  // Ponto onde o usuário esta agora
  String noAtual = '';

  String? candidatoInicial;
  DateTime? inicioCandidatoInicial;

  String? preCandidato;
  DateTime? inicioPreCandidato;

  String? candidato;
  DateTime? inicioCandidato;

  bool handoffArmado = false;
  DateTime? ultimoHandoffEm;

  String estado = 'PROCURANDO';

  void registrarLeitura(RssiReading leitura) {
    sensores[leitura.nodeId]?.adicionarLeitura(
      leitura.rssi,
      leitura.timestamp,
    );
  }

  void avaliar() {
    final agora = DateTime.now();
    final disponiveis = <String, double>{};

    for (final sensor in sensores.values) {
      if (sensor.detectado && sensor.m15 != null) {
        disponiveis[sensor.id] = sensor.m15!;
      }
    }

    if (disponiveis.length < 2) return;

    _amostras.add(
      _AmostraNavegacao(
        horario: agora,
        valores: Map<String, double>.from(disponiveis),
      ),
    );

    final limite = agora.subtract(
      LocalizationConfig.tempoTendencia + const Duration(seconds: 3),
    );

    _amostras.removeWhere((amostra) => amostra.horario.isBefore(limite));

    if (noAtual.isEmpty) {
      _avaliarAssociacaoInicial(agora, disponiveis);
      return;
    }

    _avaliarHandoff(agora, disponiveis);
  }

  void _avaliarAssociacaoInicial(
    DateTime agora,
    Map<String, double> disponiveis,
  ) {
    final ordenados = disponiveis.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maisForte = ordenados[0];
    final segundo = ordenados[1];
    final diferenca = maisForte.value - segundo.value;

    if (diferenca < LocalizationConfig.margemAssociacaoInicial) {
      candidatoInicial = null;
      inicioCandidatoInicial = null;
      estado = 'PROCURANDO';
      return;
    }

    if (candidatoInicial != maisForte.key) {
      candidatoInicial = maisForte.key;
      inicioCandidatoInicial = agora;
    }

    if (inicioCandidatoInicial != null &&
        agora.difference(inicioCandidatoInicial!) >=
            LocalizationConfig.tempoAssociacaoInicial) {
      noAtual = maisForte.key;
      candidatoInicial = null;
      inicioCandidatoInicial = null;

      _limparPreCandidato();
      _cancelarCandidato();

      estado = 'ASSOCIADO';
      return;
    }

    estado = 'CONFIRMANDO_INICIAL';
  }

  void _avaliarHandoff(
    DateTime agora,
    Map<String, double> disponiveis,
  ) {
    if (_cooldownAtivo(agora)) {
      _limparPreCandidato();
      _cancelarCandidato();
      estado = 'COOLDOWN';
      return;
    }

    final sinalAtual = disponiveis[noAtual];
    if (sinalAtual == null) return;

    // Analisa o grafo do ambiente antes de tentar confirmar o handoff
    final vizinhos = grafo.vizinhos(noAtual);

    if (handoffArmado && candidato != null) {
      _avaliarCandidatoArmado(
        agora,
        disponiveis,
        sinalAtual,
        vizinhos,
      );

      return;
    }

    if (preCandidato != null) {
      final sensor = preCandidato!;
      final inicio = inicioPreCandidato;

      if (inicio == null ||
          agora.difference(inicio) >
              LocalizationConfig.janelaPreCandidato ||
          !vizinhos.contains(sensor) ||
          disponiveis[sensor] == null) {
        _limparPreCandidato();
      } else {
        final sinalCandidato = disponiveis[sensor]!;
        final margem = sinalCandidato - sinalAtual;

        estado = 'PRE_CANDIDATO';

        if (margem >= LocalizationConfig.margemEntradaHandoff) {
          candidato = sensor;
          inicioCandidato = agora;
          handoffArmado = true;

          estado = 'CONFIRMANDO_HANDOFF';

          _limparPreCandidato();
          return;
        }

        final novoCandidato = _buscarPorTendencia(
          vizinhos,
          disponiveis,
          sinalAtual,
        );

        if (novoCandidato != null && novoCandidato != sensor) {
          final novoSinal = disponiveis[novoCandidato]!;

          if (novoSinal > sinalCandidato) {
            preCandidato = novoCandidato;
            inicioPreCandidato = agora;
          }
        }

        return;
      }
    }

    final novoPreCandidato = _buscarPorTendencia(
      vizinhos,
      disponiveis,
      sinalAtual,
    );

    if (novoPreCandidato != null) {
      preCandidato = novoPreCandidato;
      inicioPreCandidato = agora;
      estado = 'PRE_CANDIDATO';
    } else {
      estado = 'ASSOCIADO';
    }
  }

  void _avaliarCandidatoArmado(
    DateTime agora,
    Map<String, double> disponiveis,
    double sinalAtual,
    List<String> vizinhos,
  ) {
    final sensor = candidato!;

    if (!vizinhos.contains(sensor) || disponiveis[sensor] == null) {
      _cancelarCandidato();
      estado = 'ASSOCIADO';
      return;
    }

    final sinalCandidato = disponiveis[sensor]!;
    final margem = sinalCandidato - sinalAtual;

    if (margem < LocalizationConfig.margemManutencaoHandoff) {
      _cancelarCandidato();
      estado = 'ASSOCIADO';
      return;
    }

    estado = 'CONFIRMANDO_HANDOFF';

    if (inicioCandidato != null &&
        agora.difference(inicioCandidato!) >=
            LocalizationConfig.tempoConfirmacaoHandoff) {
      noAtual = sensor;
      ultimoHandoffEm = agora;

      _limparPreCandidato();
      _cancelarCandidato();

      estado = 'ASSOCIADO';
    }
  }

  String? _buscarPorTendencia(
    List<String> vizinhos,
    Map<String, double> disponiveis,
    double sinalAtual,
  ) {
    final tendenciaAtual = tendencia(noAtual);

    if (tendenciaAtual == null ||
        tendenciaAtual > -LocalizationConfig.variacaoMinimaTendencia) {
      return null;
    }

    String? melhorSensor;
    double melhorPontuacao = double.negativeInfinity;

    for (final vizinho in vizinhos) {
      final sinalVizinho = disponiveis[vizinho];
      if (sinalVizinho == null) continue;

      final tendenciaVizinho = tendencia(vizinho);

      if (tendenciaVizinho == null ||
          tendenciaVizinho <
              LocalizationConfig.variacaoMinimaTendencia) {
        continue;
      }

      final margem = sinalVizinho - sinalAtual;
      final pontuacao = (tendenciaVizinho * 2) + margem;

      if (pontuacao > melhorPontuacao) {
        melhorPontuacao = pontuacao;
        melhorSensor = vizinho;
      }
    }

    return melhorSensor;
  }

  double? tendencia(String pontoId) {
    if (_amostras.length < 2) return null;

    final atual = _amostras.last;
    final valorAtual = atual.valores[pontoId];

    if (valorAtual == null) return null;

    final alvo = atual.horario.subtract(
      LocalizationConfig.tempoTendencia,
    );

    _AmostraNavegacao? referencia;

    for (final amostra in _amostras) {
      if (!amostra.horario.isAfter(alvo) &&
          amostra.valores[pontoId] != null) {
        referencia = amostra;
      } else if (amostra.horario.isAfter(alvo)) {
        break;
      }
    }

    referencia ??= _amostras.firstWhere(
      (amostra) => amostra.valores[pontoId] != null,
      orElse: () => atual,
    );

    final valorReferencia = referencia.valores[pontoId];

    if (valorReferencia == null) return null;

    return valorAtual - valorReferencia;
  }

  bool _cooldownAtivo(DateTime agora) {
    if (ultimoHandoffEm == null) return false;

    return agora.difference(ultimoHandoffEm!) <
        LocalizationConfig.tempoCooldown;
  }

  void _limparPreCandidato() {
    preCandidato = null;
    inicioPreCandidato = null;
  }

  void _cancelarCandidato() {
    candidato = null;
    inicioCandidato = null;
    handoffArmado = false;
  }

  void limpar() {
    for (final sensor in sensores.values) {
      sensor.limpar();
    }

    noAtual = '';

    candidatoInicial = null;
    inicioCandidatoInicial = null;

    _limparPreCandidato();
    _cancelarCandidato();

    ultimoHandoffEm = null;
    estado = 'PROCURANDO';

    _amostras.clear();
  }
}

class _AmostraNavegacao {
  const _AmostraNavegacao({
    required this.horario,
    required this.valores,
  });

  final DateTime horario;
  final Map<String, double> valores;
}