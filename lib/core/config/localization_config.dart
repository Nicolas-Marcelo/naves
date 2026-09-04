abstract final class LocalizationConfig {
  static const tamanhoM15 = 15;

  static const rssiMinimo = -105;
  static const rssiMaximo = -20;
  static const janelaMediana = 7;
  static const desvioMaximoOutlier = 25;

  static const margemAssociacaoInicial = 3.0;
  static const margemEntradaHandoff = 3.0;
  static const margemManutencaoHandoff = 1.0;
  static const variacaoMinimaTendencia = 1.0;

  static const janelaPreCandidato = Duration(seconds: 4);
  static const tempoConfirmacaoHandoff = Duration(milliseconds: 1800);
  static const tempoAssociacaoInicial = Duration(milliseconds: 1800);
  static const tempoTendencia = Duration(milliseconds: 2500);
  static const tempoCooldown = Duration(seconds: 4);
  static const tempoSemSinal = Duration(seconds: 4);
}
