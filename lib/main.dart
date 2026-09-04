import 'package:flutter/material.dart';

import 'features/localization/data/ble_scanner_service.dart';
import 'features/localization/domain/services/localization_engine.dart';
import 'features/localization/presentation/localization_controller.dart';
import 'features/navigation/data/ambiente_teste.dart';
import 'presentation/tela_localizacao.dart';

void main() {
  final grafo = AmbienteTeste.criarGrafo();

  final controller = LocalizationController(
    bleService: BleScannerService(),
    engine: LocalizationEngine(grafo),
  );

  runApp(
    NavescenceApp(controller: controller),
  );
}

class NavescenceApp extends StatelessWidget {
  const NavescenceApp({
    super.key,
    required this.controller,
  });

  final LocalizationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TelaLocalizacao(
        controller: controller,
      ),
    );
  }
}