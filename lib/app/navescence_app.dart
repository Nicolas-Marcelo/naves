import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_controller.dart';

import '../features/history/data/navigation_history_service.dart';
import '../features/history/presentation/navigation_history_tracker.dart';

import '../presentation/tela_navegacao.dart';

import 'navescence_runtime.dart';

class NavescenceApp extends StatefulWidget {
  const NavescenceApp({
    super.key,
    required this.runtime,
    required this.auth,
    required this.historyService,
  });

  final NavescenceRuntime runtime;
  final AuthController auth;
  final NavigationHistoryService historyService;

  @override
  State<NavescenceApp> createState() =>
      _NavescenceAppState();
}

class _NavescenceAppState
    extends State<NavescenceApp> {
  NavigationHistoryTracker?
      _historyTracker;

  @override
  void initState() {
    super.initState();

    widget.auth.addListener(
      _authMudou,
    );

    _sincronizarHistoryTracker();
  }

  void _authMudou() {
    _sincronizarHistoryTracker();
  }

  void _sincronizarHistoryTracker() {
    if (widget.auth.autenticado) {
      _historyTracker ??=
          NavigationHistoryTracker(
        localizacao:
            widget.runtime.localizacao,
        navegacao:
            widget.runtime.navegacao,
        service:
            widget.historyService,
      );

      return;
    }

    _historyTracker?.dispose();
    _historyTracker = null;
  }

  @override
  void dispose() {
    widget.auth.removeListener(
      _authMudou,
    );

    _historyTracker?.dispose();
    _historyTracker = null;

    unawaited(
      widget.runtime.dispose(),
    );

    widget.auth.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TelaNavegacao(
        localizacao:
            widget.runtime.localizacao,
        navegacao:
            widget.runtime.navegacao,
        controleVoz:
            widget.runtime.controleVoz,
        historyService:
            widget.historyService,
        auth:
            widget.auth,
      ),
    );
  }
}

class NavescenceStartupErrorApp
    extends StatelessWidget {
  const NavescenceStartupErrorApp({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title: 'NAVESCENCE',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'Não foi possível iniciar o NAVESCENCE.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      '$error',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}