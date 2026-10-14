import 'package:flutter/material.dart';

import '../../features/navigation/domain/entities/local.dart';

class CardLocalizacao extends StatelessWidget {
  const CardLocalizacao({
    super.key,
    required this.pontoAtual,
    required this.locais,
  });

  static const _azul = Color(0xFF102F46);
  static const _verde = Color(0xFF16876D);
  static const _cinza = Color(0xFF687781);

  final String pontoAtual;
  final List<Local> locais;

  bool get localizado => pontoAtual.isNotEmpty;

  List<String> _locaisDoPonto() {
    return locais
        .where((local) => local.pontoId == pontoAtual)
        .map((local) => local.nome)
        .toList();
  }

  String _juntarNomes(List<String> nomes) {
    if (nomes.isEmpty) return '';
    if (nomes.length == 1) return nomes.first;
    if (nomes.length == 2) return '${nomes[0]} e ${nomes[1]}';

    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  String get descricao {
    if (!localizado) return 'Buscando sua posição';

    final nomes = _locaisDoPonto();

    if (nomes.isEmpty) {
      return 'Posição identificada';
    }

    return _juntarNomes(nomes);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: localizado
          ? 'Localização identificada. Você está próximo de $descricao'
          : 'Buscando sua localização',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE5EAED),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: localizado
                    ? _verde.withValues(alpha: 0.12)
                    : _azul.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                localizado
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                size: 26,
                color: localizado ? _verde : _azul,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: localizado
                              ? _verde
                              : Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        localizado
                            ? 'LOCALIZAÇÃO IDENTIFICADA'
                            : 'LOCALIZANDO',
                        style: TextStyle(
                          color: localizado ? _verde : _cinza,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _azul,
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (localizado) ...[
                    const SizedBox(height: 4),
                    Text(
                      pontoAtual,
                      style: const TextStyle(
                        color: _cinza,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}