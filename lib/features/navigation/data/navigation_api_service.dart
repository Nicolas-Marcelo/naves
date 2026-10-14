import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class NavigationApiService {
  const NavigationApiService();

  Future<Map<String, dynamic>>
      carregarConfiguracao({
    int? environmentId,
  }) async {
    final uri =
        environmentId == null
        ? Uri.parse(
            ApiConfig.navigationConfig,
          )
        : Uri.parse(
            '${ApiConfig.navigationConfig}?environmentId=$environmentId',
          );

    final response =
        await http
            .get(uri)
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro HTTP ${response.statusCode} ao carregar a configuração.',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (
      decoded
          is! Map<String, dynamic>
    ) {
      throw Exception(
        'Configuração de navegação inválida.',
      );
    }

    return decoded;
  }
}