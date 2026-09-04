import 'package:flutter/material.dart';

import 'features/localization/data/ble_scanner_service.dart';
import 'features/localization/domain/services/localization_engine.dart';
import 'features/localization/presentation/localization_controller.dart';

import 'features/navigation/data/ambiente_teste.dart';
import 'features/navigation/domain/services/calculador_estrela.dart';
import 'features/navigation/presentation/controle_navegacao.dart';

import 'presentation/tela_navegacao.dart';

void main() {
  final grafo = AmbienteTeste.criarGrafo();

  final localizacao = LocalizationController(
    bleService: BleScannerService(),
    engine: LocalizationEngine(grafo),
  );

  final navegacao = ControleNavegacao(
    localizacao: localizacao,
    grafo: grafo,
    calculador: const CalculadorEstrela(),
    locais: AmbienteTeste.locais,
  );

  runApp(
    NavescenceApp(
      localizacao: localizacao,
      navegacao: navegacao,
    ),
  );
}

class NavescenceApp extends StatelessWidget {
  const NavescenceApp({
    super.key,
    required this.localizacao,
    required this.navegacao,
  });

  final LocalizationController localizacao;
  final ControleNavegacao navegacao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TelaNavegacao(
        localizacao: localizacao,
        navegacao: navegacao,
      ),
    );
  }
}