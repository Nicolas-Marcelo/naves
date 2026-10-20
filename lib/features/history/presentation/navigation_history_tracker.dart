import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../localization/presentation/localization_controller.dart';
import '../../navigation/presentation/controle_navegacao.dart';
import '../data/navigation_history_service.dart';

class NavigationHistoryTracker {
  NavigationHistoryTracker({
    required this.localizacao,
    required this.navegacao,
    required this.service,
  }) {
    localizacao.addListener(
      _mudancaDetectada,
    );

    navegacao.addListener(
      _mudancaDetectada,
    );

    _agendarProcessamento();
  }

  final LocalizationController localizacao;
  final ControleNavegacao navegacao;
  final NavigationHistoryService service;

  int? _historyId;

  String _ultimoNoRegistrado = '';
  String _ultimoEstado = '';

  bool _processando = false;
  bool _processamentoPendente = false;
  bool _disposed = false;

  void _mudancaDetectada() {
    _agendarProcessamento();
  }

  void _agendarProcessamento() {
    if (_disposed) return;

    if (_processando) {
      _processamentoPendente = true;
      return;
    }

    unawaited(
      _processar(),
    );
  }

  Future<void> _processar() async {
    if (_disposed) return;

    _processando = true;

    try {
      do {
        _processamentoPendente =
            false;

        await _processarEstado();
      } while (
          _processamentoPendente &&
              !_disposed);
    } finally {
      _processando = false;
    }
  }

  Future<void>
      _processarEstado() async {
    if (_disposed) return;

    final estado =
        navegacao.estado;

    final noAtual =
        localizacao.noAtual;

    if (estado == 'ROTA_ATIVA') {
      if (_historyId == null) {
        await _iniciarHistorico(
          noAtual,
        );
      }

      await _registrarNo(
        noAtual,
      );
    }

    if (estado ==
        'DESTINO_ALCANCADO') {
      await _registrarNo(
        noAtual,
      );

      await _finalizarHistorico();
    }

    if (_historyId != null &&
        _ultimoEstado ==
            'ROTA_ATIVA' &&
        estado == 'SEM_ROTA') {
      await _cancelarHistorico();
    }

    _ultimoEstado = estado;
  }

  Future<void> _iniciarHistorico(
    String noAtual,
  ) async {
    if (_historyId != null ||
        noAtual.isEmpty) {
      return;
    }

    final destino =
        navegacao.destino;

    if (destino == null) return;

    try {
      final id = await service.iniciar(
        origem: noAtual,
        destino: destino.pontoId,
        destinoNome: destino.nome,
      );

      if (_disposed) return;

      _historyId = id;

      if (id != null) {
        _ultimoNoRegistrado =
            noAtual;

        debugPrint(
          '[HISTÓRICO USUÁRIO] '
          'Navegação iniciada | '
          'ID $id | '
          '$noAtual -> ${destino.pontoId}',
        );
      }
    } catch (error) {
      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Falha ao iniciar: $error',
      );
    }
  }

  Future<void> _registrarNo(
    String noAtual,
  ) async {
    final historyId =
        _historyId;

    if (historyId == null ||
        noAtual.isEmpty ||
        noAtual ==
            _ultimoNoRegistrado) {
      return;
    }

    try {
      await service.registrarNo(
        historyId: historyId,
        nodeCode: noAtual,
      );

      if (_disposed) return;

      _ultimoNoRegistrado =
          noAtual;

      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Ponto registrado: $noAtual',
      );
    } catch (error) {
      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Falha ao registrar ponto: $error',
      );
    }
  }

  Future<void>
      _finalizarHistorico() async {
    final historyId =
        _historyId;

    if (historyId == null) return;

    try {
      await service.finalizar(
        historyId,
      );

      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Navegação $historyId finalizada.',
      );

      _limparSessao();
    } catch (error) {
      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Falha ao finalizar: $error',
      );
    }
  }

  Future<void>
      _cancelarHistorico() async {
    final historyId =
        _historyId;

    if (historyId == null) return;

    try {
      await service.cancelar(
        historyId,
      );

      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Navegação $historyId cancelada.',
      );

      _limparSessao();
    } catch (error) {
      debugPrint(
        '[HISTÓRICO USUÁRIO] '
        'Falha ao cancelar: $error',
      );
    }
  }

  void _limparSessao() {
    _historyId = null;
    _ultimoNoRegistrado = '';
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    localizacao.removeListener(
      _mudancaDetectada,
    );

    navegacao.removeListener(
      _mudancaDetectada,
    );
  }
}