import 'package:flutter/material.dart';

import 'app/navescence_app.dart';
import 'app/navescence_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final bootstrap = await NavescenceBootstrap.criar();

    runApp(
      NavescenceApp(
        runtime: bootstrap.runtime,
        auth: bootstrap.auth,
        historyService: bootstrap.historyService,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('[NAVESCENCE] Erro durante inicialização: $error');

    debugPrint('$stackTrace');

    runApp(NavescenceStartupErrorApp(error: error));
  }
}
