import 'package:flutter/material.dart';

import '../domain/entities/grafo.dart';
import '../domain/entities/ponto.dart';

class MapaAmbiente extends StatelessWidget {
  const MapaAmbiente({
    super.key,
    required this.grafo,
    required this.pontoAtual,
    required this.rota,
    required this.destino,
  });

  final Grafo grafo;
  final String pontoAtual;
  final List<String>? rota;
  final String? destino;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: Color(0xFF183B56),
              ),
              SizedBox(width: 8),
              Text(
                'Mapa do ambiente',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF183B56),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Acompanhe sua localização e o caminho até o destino.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 330,
            width: double.infinity,
            child: CustomPaint(
              painter: _MapaPainter(
                grafo: grafo,
                pontoAtual: pontoAtual,
                rota: rota,
                destino: destino,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Legenda(
                cor: Color(0xFF14866D),
                texto: 'Você',
              ),
              _Legenda(
                cor: Color(0xFFF59E0B),
                texto: 'Destino',
              ),
              _Legenda(
                cor: Color(0xFF2563EB),
                texto: 'Rota',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({
    required this.cor,
    required this.texto,
  });

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MapaPainter extends CustomPainter {
  const _MapaPainter({
    required this.grafo,
    required this.pontoAtual,
    required this.rota,
    required this.destino,
  });

  final Grafo grafo;
  final String pontoAtual;
  final List<String>? rota;
  final String? destino;

  static const _azul = Color(0xFF2563EB);
  static const _verde = Color(0xFF14866D);
  static const _laranja = Color(0xFFF59E0B);
  static const _cinza = Color(0xFFD5DCE2);
  static const _parede = Color(0xFFE8ECEF);

  @override
  void paint(Canvas canvas, Size size) {
    if (grafo.pontos.isEmpty) return;

    _desenharParede(canvas, size);
    _desenharConexoes(canvas, size);
    _desenharPontos(canvas, size);
  }

  Offset _posicao(Ponto ponto, Size size) {
    final xs = grafo.pontos.map((p) => p.x).toList();
    final ys = grafo.pontos.map((p) => p.y).toList();

    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);

    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);

    final largura = maxX - minX;
    final altura = maxY - minY;

    const margem = 42.0;

    final areaLargura = size.width - margem * 2;
    final areaAltura = size.height - margem * 2;

    final x = largura == 0
        ? size.width / 2
        : margem + ((ponto.x - minX) / largura) * areaLargura;

    final y = altura == 0
        ? size.height / 2
        : margem + ((maxY - ponto.y) / altura) * areaAltura;

    return Offset(x, y);
  }

  void _desenharParede(Canvas canvas, Size size) {
    final s2 = grafo.buscarPonto('S2');
    final s3 = grafo.buscarPonto('S3');
    final s4 = grafo.buscarPonto('S4');
    final s5 = grafo.buscarPonto('S5');

    if (s2 == null || s3 == null || s4 == null || s5 == null) return;

    final pS2 = _posicao(s2, size);
    final pS3 = _posicao(s3, size);
    final pS4 = _posicao(s4, size);
    final pS5 = _posicao(s5, size);

    final esquerda = pS3.dx + 55;
    final direita = pS4.dx - 55;
    final topo = pS3.dy + 45;
    final baixo = pS2.dy - 30;

    if (direita <= esquerda || baixo <= topo) return;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        esquerda,
        topo,
        direita,
        baixo,
      ),
      const Radius.circular(12),
    );

    final paint = Paint()
      ..color = _parede
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, paint);

    final borda = Paint()
      ..color = const Color(0xFFCDD5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rect, borda);

    final texto = TextPainter(
      text: const TextSpan(
        text: 'PAREDE',
        style: TextStyle(
          color: Color(0xFF7A8790),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    texto.paint(
      canvas,
      Offset(
        rect.center.dx - texto.width / 2,
        rect.center.dy - texto.height / 2,
      ),
    );
  }

  void _desenharConexoes(Canvas canvas, Size size) {
    for (final conexao in grafo.conexoes) {
      final origem = grafo.buscarPonto(conexao.origem);
      final destino = grafo.buscarPonto(conexao.destino);

      if (origem == null || destino == null) continue;

      final inicio = _posicao(origem, size);
      final fim = _posicao(destino, size);

      final fazParteDaRota = _conexaoNaRota(
        conexao.origem,
        conexao.destino,
      );

      final paint = Paint()
        ..color = fazParteDaRota ? _azul : _cinza
        ..strokeWidth = fazParteDaRota ? 7 : 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        inicio,
        fim,
        paint,
      );
    }
  }

  bool _conexaoNaRota(String a, String b) {
    if (rota == null || rota!.length < 2) return false;

    for (var i = 0; i < rota!.length - 1; i++) {
      final primeiro = rota![i];
      final segundo = rota![i + 1];

      final normal = primeiro == a && segundo == b;
      final inverso = primeiro == b && segundo == a;

      if (normal || inverso) return true;
    }

    return false;
  }

  void _desenharPontos(Canvas canvas, Size size) {
    for (final ponto in grafo.pontos) {
      final posicao = _posicao(ponto, size);

      var cor = const Color(0xFF667681);
      var raio = 13.0;

      if (ponto.id == destino) {
        cor = _laranja;
        raio = 15;
      }

      if (ponto.id == pontoAtual) {
        cor = _verde;
        raio = 17;
      }

      if (ponto.id == pontoAtual && ponto.id == destino) {
        cor = _verde;
        raio = 18;
      }

      final sombra = Paint()
        ..color = Colors.black.withValues(alpha: 0.12);

      canvas.drawCircle(
        posicao.translate(0, 3),
        raio + 3,
        sombra,
      );

      final circulo = Paint()
        ..color = cor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        posicao,
        raio,
        circulo,
      );

      final borda = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle(
        posicao,
        raio,
        borda,
      );

      _desenharNomePonto(
        canvas,
        ponto,
        posicao,
      );
    }
  }

  void _desenharNomePonto(
    Canvas canvas,
    Ponto ponto,
    Offset posicao,
  ) {
    final texto = TextPainter(
      text: TextSpan(
        text: ponto.id,
        style: const TextStyle(
          color: Color(0xFF263238),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    var x = posicao.dx - texto.width / 2;
    var y = posicao.dy - 38;

    if (ponto.id == 'S1') {
      y = posicao.dy + 22;
    }

    texto.paint(
      canvas,
      Offset(x, y),
    );
  }

  @override
  bool shouldRepaint(covariant _MapaPainter oldDelegate) {
    return oldDelegate.pontoAtual != pontoAtual ||
        oldDelegate.destino != destino ||
        oldDelegate.rota != rota;
  }
}