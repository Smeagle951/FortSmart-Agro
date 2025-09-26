import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// CustomPainter para desenhar polígonos de talhão com visual FortSmart premium
class PolygonPainter extends CustomPainter {
  final List<Offset> pontos;
  final Color corPoligono;
  final bool desenharVertices;
  final bool desenhoConcluido;
  final bool modoEdicao;
  final String? nomeCultura;
  final String? area;

  PolygonPainter({
    required this.pontos,
    required this.corPoligono,
    this.desenharVertices = true,
    this.desenhoConcluido = false,
    this.modoEdicao = false,
    this.nomeCultura,
    this.area,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (int i = 1; i < pontos.length; i++) {
      path.lineTo(pontos[i].dx, pontos[i].dy);
    }
    path.close();

    // Calcular o centro do polígono para posicionar o ícone ou texto
    Offset centro = _calcularCentroPoligono();

    // Efeito de sombra premium
    _desenharSombraPremium(canvas, path);

    // Preenchimento com gradiente suave
    final gradientFill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centro.dx - 100, centro.dy - 100),
        Offset(centro.dx + 100, centro.dy + 100),
        [
          corPoligono.withOpacity(0.5),
          corPoligono.withOpacity(0.3),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, gradientFill);

    // Borda com efeito de brilho
    final borderGlow = Paint()
      ..color = corPoligono
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderGlow);

    // Desenhar vértices se estiver no modo de edição
    if (desenharVertices) {
      _desenharVertices(canvas);
    }

    // Desenhar nome da cultura no centro se o desenho estiver concluído
    if (desenhoConcluido && nomeCultura != null && nomeCultura!.isNotEmpty) {
      _desenharTextoCultura(canvas, centro);
    }
    
    // Desenhar área calculada se disponível
    if (desenhoConcluido && area != null && area!.isNotEmpty) {
      _desenharTextoArea(canvas, centro);
    }
  }

  /// Desenha uma sombra premium com múltiplas camadas para efeito de profundidade
  void _desenharSombraPremium(Canvas canvas, Path path) {
    // Primeira camada de sombra - mais ampla e suave
    canvas.drawShadow(path, corPoligono.withAlpha(100), 12, true);
    
    // Segunda camada de sombra - mais definida
    canvas.drawShadow(path, corPoligono.withAlpha(150), 8, true);
    
    // Terceira camada de sombra - mais intensa e próxima
    canvas.drawShadow(path, corPoligono.withAlpha(200), 4, true);
  }

  /// Desenha os vértices do polígono com efeito de círculos concêntricos
  void _desenharVertices(Canvas canvas) {
    for (final p in pontos) {
      // Sombra externa para destacar o vértice
      canvas.drawCircle(
        p, 
        10, 
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
          ..style = PaintingStyle.fill
      );
      
      // Círculo externo branco com borda
      canvas.drawCircle(
        p, 
        8, 
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
      );
      
      // Círculo interno colorido
      canvas.drawCircle(
        p, 
        6, 
        Paint()
          ..color = corPoligono
          ..style = PaintingStyle.fill
      );
      
      // Brilho central
      canvas.drawCircle(
        p, 
        2, 
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill
      );
    }
  }

  /// Desenha o texto da cultura no centro do polígono
  void _desenharTextoCultura(Canvas canvas, Offset centro) {
    if (nomeCultura == null) return;
    
    final textSpan = TextSpan(
      text: nomeCultura,
      style: TextStyle(
        color: _calcularCorTextoContrastante(),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centro.dx - textPainter.width / 2,
        centro.dy - textPainter.height / 2 - 10, // Movido para cima para dar espaço para a área
      ),
    );
  }

  /// Desenha o texto da área calculada abaixo do nome da cultura
  void _desenharTextoArea(Canvas canvas, Offset centro) {
    if (area == null) return;
    
    final textSpan = TextSpan(
      text: area,
      style: TextStyle(
        color: _calcularCorTextoContrastante(),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2.0,
            color: Colors.black.withOpacity(0.4),
          ),
        ],
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centro.dx - textPainter.width / 2,
        centro.dy + 10, // Posicionado abaixo do centro
      ),
    );
  }

  /// Calcula o centro do polígono
  Offset _calcularCentroPoligono() {
    if (pontos.isEmpty) return Offset.zero;
    
    double somaX = 0;
    double somaY = 0;
    
    for (final ponto in pontos) {
      somaX += ponto.dx;
      somaY += ponto.dy;
    }
    
    return Offset(somaX / pontos.length, somaY / pontos.length);
  }

  /// Calcula uma cor contrastante para o texto baseado na cor do polígono
  Color _calcularCorTextoContrastante() {
    // Fórmula YIQ para determinar se a cor de fundo é clara ou escura
    final yiq = ((corPoligono.red * 299) + 
                (corPoligono.green * 587) + 
                (corPoligono.blue * 114)) / 1000;
    
    // Retorna preto para cores claras e branco para cores escuras
    return yiq >= 128 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(covariant PolygonPainter oldDelegate) {
    return oldDelegate.pontos != pontos ||
           oldDelegate.corPoligono != corPoligono ||
           oldDelegate.desenharVertices != desenharVertices ||
           oldDelegate.desenhoConcluido != desenhoConcluido ||
           oldDelegate.modoEdicao != modoEdicao ||
           oldDelegate.nomeCultura != nomeCultura ||
           oldDelegate.area != area;
  }
}
