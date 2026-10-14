import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'navigation_api_service.dart';
import 'navigation_config_data.dart';

class NavigationConfigRepository {
  NavigationConfigRepository({
    this.api =
        const NavigationApiService(),
  });

  static const _cacheKey =
      'navescence_navigation_config';

  final NavigationApiService api;

  Future<NavigationConfigData>
      carregar({
    int? environmentId,
  }) async {
    try {
      return await atualizar(
        environmentId:
            environmentId,
      );
    } catch (_) {
      final cache =
          await carregarCache();

      if (cache != null) {
        return cache;
      }

      rethrow;
    }
  }

  Future<NavigationConfigData>
      atualizar({
    int? environmentId,
  }) async {
    final json =
        await api.carregarConfiguracao(
      environmentId:
          environmentId,
    );

    final config =
        NavigationConfigData
            .fromJson(json);

    _validar(config);

    final preferences =
        await SharedPreferences
            .getInstance();

    await preferences.setString(
      _cacheKey,
      jsonEncode(json),
    );

    return config;
  }

  Future<NavigationConfigData?>
      carregarCache() async {
    final preferences =
        await SharedPreferences
            .getInstance();

    final cache =
        preferences.getString(
      _cacheKey,
    );

    if (
      cache == null ||
      cache.trim().isEmpty
    ) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(cache);

      if (
        decoded
            is! Map<String, dynamic>
      ) {
        return null;
      }

      final config =
          NavigationConfigData
              .fromJson(decoded);

      _validar(config);

      return config;
    } catch (_) {
      return null;
    }
  }

  void _validar(
    NavigationConfigData config,
  ) {
    if (
      config.grafo.pontos.isEmpty
    ) {
      throw Exception(
        'A configuração não possui sensores.',
      );
    }

    if (
      config.beacons.isEmpty
    ) {
      throw Exception(
        'A configuração não possui sensores BLE válidos.',
      );
    }

    final nodeIds =
        config.grafo.pontos
            .map(
              (ponto) =>
                  ponto.id,
            )
            .toSet();

    for (
      final conexao
      in config.grafo.conexoes
    ) {
      if (
        !nodeIds.contains(
              conexao.origem,
            ) ||
        !nodeIds.contains(
              conexao.destino,
            )
      ) {
        throw Exception(
          'Existe uma conexão apontando para um sensor inexistente.',
        );
      }
    }

    for (
      final local
      in config.locais
    ) {
      if (
        !nodeIds.contains(
          local.pontoId,
        )
      ) {
        throw Exception(
          'Existe um ponto de interesse ligado a um sensor inexistente.',
        );
      }
    }
  }
}