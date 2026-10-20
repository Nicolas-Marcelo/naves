import 'package:flutter/material.dart';

import 'features/testing/presentation/tela_teste_percurso.dart';

void main() {
  WidgetsFlutterBinding
      .ensureInitialized();

  runApp(
    const NavescenceTesteApp(),
  );
}

class NavescenceTesteApp
    extends StatelessWidget {
  const NavescenceTesteApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title:
          'NAVESCENCE - Teste BLE',
      theme:
          ThemeData(
        useMaterial3:
            true,
        colorSchemeSeed:
            Colors.indigo,
      ),
      home:
          const TelaTestePercurso(),
    );
  }
}