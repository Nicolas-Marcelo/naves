import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FeedbackTatil {
  ativacao,
  ouvindo,
  sucesso,
  erro,
  frente,
  esquerda,
  direita,
  recalculo,
  chegada,
  sinalPerdido,
  cancelado,
}

class ServicoFeedbackTatil {
  static const MethodChannel _channel = MethodChannel(
    'navescence/feedback_tatil',
  );

  Future<void> executar(FeedbackTatil feedback) async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod('executar', feedback.name);
    } on PlatformException catch (erro) {
      debugPrint('[TATIL] Erro ao executar ${feedback.name}: ${erro.message}');
    }
  }
}
