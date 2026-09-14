import 'package:flutter/material.dart';

import 'features/localization/data/ble_scanner_service.dart';
import 'features/localization/domain/services/localization_engine.dart';
import 'features/localization/presentation/localization_controller.dart';

import 'features/navigation/data/ambiente_teste.dart';
import 'features/navigation/domain/entities/local.dart';
import 'features/navigation/domain/services/calculador_estrela.dart';
import 'features/navigation/presentation/controle_navegacao.dart';

import 'features/voice/data/servico_wake_word.dart';

import 'presentation/tela_navegacao.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  final wakeWord = ServicoWakeWord();

  wakeWord.comandos.listen((comando) {
    debugPrint(
      '[NAVESCENCE] Comando recebido do Android: $comando',
    );

    _processarComandoWakeWord(
      comando,
      navegacao,
    );
  });

  runApp(
    NavescenceApp(
      localizacao: localizacao,
      navegacao: navegacao,
    ),
  );
}

void _processarComandoWakeWord(
  String comando,
  ControleNavegacao navegacao,
) {
  final texto = _normalizar(comando);

  debugPrint(
    '[NAVESCENCE] Processando comando: $texto',
  );

  if (
      texto.contains('cancelar') ||
      texto.contains('cancela') ||
      texto.contains('parar rota') ||
      texto == 'parar') {
    navegacao.cancelarRota();

    debugPrint(
      '[NAVESCENCE] Rota cancelada.',
    );

    return;
  }

  final destino = _encontrarDestino(
    texto,
    navegacao.locais,
  );

  if (destino == null) {
    debugPrint(
      '[NAVESCENCE] Nenhum destino identificado.',
    );

    return;
  }

  debugPrint(
    '[NAVESCENCE] Destino identificado: ${destino.nome}',
  );

  navegacao.selecionarDestino(
    destino,
  );

  navegacao.iniciarRota();

  debugPrint(
    '[NAVESCENCE] Rota iniciada para ${destino.nome}.',
  );
}

Local? _encontrarDestino(
  String comando,
  List<Local> locais,
) {
  final aliases = <String, List<String>>{
    'maker': [
      'maker',
      'sala maker',
      'espaco maker',
    ],
    'informatica': [
      'informatica',
      'sala de informatica',
      'computador',
      'computadores',
      'laboratorio',
    ],
    'banheiro': [
      'banheiro',
      'banheiros',
    ],
    'coordenacao': [
      'coordenacao',
      'coordenadora',
      'sala da coordenacao',
    ],
    'musica': [
      'musica',
      'sala de musica',
    ],
    'artes': [
      'artes',
      'sala de artes',
    ],
    'esportes': [
      'esportes',
      'sala de esportes',
    ],
    'recepcao': [
      'recepcao',
    ],
    'deposito': [
      'deposito',
    ],
    'entrada': [
      'entrada',
      'entrada principal',
    ],
  };

  String? destinoIdentificado;

  for (final item in aliases.entries) {
    for (final alias in item.value) {
      if (comando.contains(alias)) {
        destinoIdentificado = item.key;
        break;
      }
    }

    if (destinoIdentificado != null) break;
  }

  if (destinoIdentificado == null) return null;

  for (final local in locais) {
    final nome = _normalizar(
      local.nome,
    );

    if (
        nome.contains(destinoIdentificado) ||
        destinoIdentificado.contains(nome)) {
      return local;
    }
  }

  return null;
}

String _normalizar(String texto) {
  return texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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