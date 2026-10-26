import '../core/config/beacon_config.dart';

import '../features/accessibility/data/servico_feedback_tatil.dart';

import '../features/auth/data/auth_api_service.dart';
import '../features/auth/data/auth_storage.dart';
import '../features/auth/presentation/auth_controller.dart';

import '../features/history/data/navigation_history_service.dart';

import '../features/localization/data/ble_scanner_service.dart';
import '../features/localization/domain/services/localization_engine.dart';
import '../features/localization/presentation/localization_controller.dart';

import '../features/navigation/data/navigation_config_repository.dart';
import '../features/navigation/data/navigation_socket_service.dart';
import '../features/navigation/domain/services/calculador_estrela.dart';
import '../features/navigation/presentation/controle_navegacao.dart';

import '../features/voice/data/servico_wake_word.dart';
import '../features/voice/presentation/controle_voz.dart';

import 'navescence_runtime.dart';

class NavescenceBootstrapResult {
  final NavescenceRuntime runtime;
  final AuthController auth;
  final NavigationHistoryService historyService;

  const NavescenceBootstrapResult({
    required this.runtime,
    required this.auth,
    required this.historyService,
  });
}

class NavescenceBootstrap {
  static Future<NavescenceBootstrapResult> criar() async {
    const apiBaseUrl = String.fromEnvironment(
      'NAVESCENCE_API_URL',
      defaultValue: 'http://10.0.2.2:3000',
    );

    final repository = NavigationConfigRepository();

    final config = await repository.carregar();

    BeaconConfig.configurar(config.beacons);

    final wakeWord = ServicoWakeWord();
    final feedbackTatil = ServicoFeedbackTatil();

    final localizacao = LocalizationController(
      bleService: BleScannerService(),
      engine: LocalizationEngine(config.grafo),
    );

    late final ControleVoz controleVoz;

    final navegacao = ControleNavegacao(
      localizacao: localizacao,
      grafo: config.grafo,
      calculador: CalculadorEstrela(),
      locais: config.locais,
      feedbackTatil: feedbackTatil,
      antesDeFalar: () async {
        await wakeWord.desligar();
      },
      depoisDeFalar: () async {
        await controleVoz.retomarModoAutomatico();
      },
    );

    controleVoz = ControleVoz(
      navegacao: navegacao,
      wakeWord: wakeWord,
      feedbackTatil: feedbackTatil,
    );

    final socket = NavigationSocketService();

    final runtime = NavescenceRuntime(
      repository: repository,
      socket: socket,
      wakeWord: wakeWord,
      localizacao: localizacao,
      navegacao: navegacao,
      controleVoz: controleVoz,
    );

    await runtime.iniciar();

    final authApi = AuthApiService(baseUrl: apiBaseUrl);

    const authStorage = AuthStorage();

    final auth = AuthController(api: authApi, storage: authStorage);

    await auth.iniciar();

    final historyService = NavigationHistoryService(
      tokenProvider: () => auth.token,
    );

    return NavescenceBootstrapResult(
      runtime: runtime,
      auth: auth,
      historyService: historyService,
    );
  }
}
