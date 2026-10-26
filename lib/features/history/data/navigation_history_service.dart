import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class NavigationHistoryService {
  NavigationHistoryService({required this.tokenProvider});

  final String? Function() tokenProvider;

  Map<String, String> _headers() {
    final token = tokenProvider();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  bool get autenticado {
    final token = tokenProvider();

    return token != null && token.isNotEmpty;
  }

  Future<int?> iniciar({
    required String origem,
    required String destino,
    required String destinoNome,
  }) async {
    if (!autenticado) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/navigation-history/start'),
      headers: _headers(),
      body: jsonEncode({
        'originNodeCode': origem,
        'destinationNodeCode': destino,
        'destinationName': destinoNome,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Não foi possível iniciar o histórico '
        'de navegação. HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao iniciar histórico.');
    }

    final id = data['id'];

    if (id is int) return id;

    if (id is num) {
      return id.toInt();
    }

    return null;
  }

  Future<void> registrarNo({
    required int historyId,
    required String nodeCode,
  }) async {
    if (!autenticado) return;

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/navigation-history/'
        '$historyId/event',
      ),
      headers: _headers(),
      body: jsonEncode({'nodeCode': nodeCode}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Não foi possível registrar o ponto '
        'da navegação. HTTP ${response.statusCode}',
      );
    }
  }

  Future<void> finalizar(int historyId) async {
    if (!autenticado) return;

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/navigation-history/'
        '$historyId/finish',
      ),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível finalizar o histórico. '
        'HTTP ${response.statusCode}',
      );
    }
  }

  Future<void> cancelar(int historyId) async {
    if (!autenticado) return;

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/navigation-history/'
        '$historyId/cancel',
      ),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível cancelar o histórico. '
        'HTTP ${response.statusCode}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> carregarHoje() async {
    if (!autenticado) {
      return [];
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/navigation-history/today'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar o histórico. '
        'HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Resposta inválida ao carregar histórico.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
