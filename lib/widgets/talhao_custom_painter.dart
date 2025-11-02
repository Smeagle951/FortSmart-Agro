import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'dart:math';

/// CustomPainter avançado para renderização de talhões com efeitos visuais
class TalhaoCustomPainter extends CustomPainter {
  final List<LatLng> pontos;
  final Color cor;
  final bool isCompleto;
  final bool mostrarPontosControle;
  final bool mostrarPontoSelecionado;
  final int? pontoSelecionadoIndex;
  final double espessuraBorda;
  final double tamanhoPontoControle;
  final double opacidadePreenchimento;
  
  TalhaoCustomPainter({
    required this.pontos,
    required this.cor,
    this.isCompleto = true,
    this.mostrarPontosControle = false,
    this.mostrarPontoSelecionado = false,
    this.pontoSelecionadoIndex,
    this.espessuraBorda = 2.0,
    this.tamanhoPontoControle = 8.0,
    this.opacidadePreenchimento = 0.5,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.isEmpty) return;
    
    final paint = Paint()
      ..color = cor.withOpacity(opacidadePreenchimento)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessuraBorda
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Converter coordenadas geográficas para pixels na tela
    final points = _convertToScreenPoints(pontos, size);
    
    if (points.isEmpty) return;
    
    // Desenhar polígono usando um caminho personalizado
    final path = ui.Path(); // Usando ui.Path explicitamente para evitar conflitos de tipo
    
    // Iniciar o caminho no primeiro ponto
    path.moveTo(points[0].dx, points[0].dy);
    
    // Adicionar linhas para os pontos restantes
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    // Fechar o polígono se estiver completo
    if (isCompleto) {
      path.close();
      canvas.drawPath(path, paint);
    }
    
    // Desenhar o contorno
    canvas.drawPath(path, borderPaint);
    
    // Desenhar pontos de controle
    if (mostrarPontosControle) {
      final pontoPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final pontoInternoPaint = Paint()
        ..color = cor
        ..style = PaintingStyle.fill;
      
      // Desenhar todos os pontos de controle
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        final isSelected = mostrarPontoSelecionado && pontoSelecionadoIndex == i;
        
        // Tamanho maior para o ponto selecionado
        final tamanhoExterno = isSelected ? tamanhoPontoControle * 1.5 : tamanhoPontoControle;
        final tamanhoInterno = isSelected ? tamanhoPontoControle * 1.0 : tamanhoPontoControle * 0.7;
        
        // Cor diferente para o ponto selecionado
        final corInterna = isSelected ? Colors.amber : cor;
        
        // Desenhar círculo externo (branco)
        canvas.drawCircle(point, tamanhoExterno, pontoPaint);
        
        // Desenhar círculo interno (cor do talhão ou âmbar se selecionado)
        canvas.drawCircle(point, tamanhoInterno, pontoInternoPaint..color = corInterna);
      }
    }
  }
  
  /// Converte coordenadas geográficas para pontos na tela com suporte a projeção mercator
  List<Offset> _convertToScreenPoints(List<LatLng> coordenadas, Size size) {
    if (coordenadas.isEmpty) return [];
    
    // Encontrar limites
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final ponto in coordenadas) {
      minLat = minLat > ponto.latitude ? ponto.latitude : minLat;
      maxLat = maxLat < ponto.latitude ? ponto.latitude : maxLat;
      minLng = minLng > ponto.longitude ? ponto.longitude : minLng;
      maxLng = maxLng < ponto.longitude ? ponto.longitude : maxLng;
    }
    
    // Calcular fator de escala
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    // Evitar divisão por zero
    if (latRange <= 0 || lngRange <= 0) {
      // Se não houver variação, centralizar o ponto
      if (coordenadas.length == 1) {
        return [Offset(size.width / 2, size.height / 2)];
      }
      return [];
    }
    
    // Adicionar margem para melhor visualização
    final marginFactor = 0.1;
    final latMargin = latRange * marginFactor;
    final lngMargin = lngRange * marginFactor;
    
    // Ajustar limites com margem
    minLat -= latMargin;
    maxLat += latMargin;
    minLng -= lngMargin;
    maxLng += lngMargin;
    
    // Recalcular ranges com margem
    final adjustedLatRange = maxLat - minLat;
    final adjustedLngRange = maxLng - minLng;
    
    // Calcular proporção do canvas
    final canvasRatio = size.width / size.height;
    
    // Calcular proporção da área geográfica
    // Usar projeção mercator para ajustar latitude
    final mercatorMinLat = _latToMercator(minLat);
    final mercatorMaxLat = _latToMercator(maxLat);
    final mercatorLatRange = mercatorMaxLat - mercatorMinLat;
    final geoRatio = adjustedLngRange / mercatorLatRange;
    
    // Ajustar para manter proporção
    double adjustedMinLng = minLng;
    double adjustedMaxLng = maxLng;
    double adjustedMinLat = minLat;
    double adjustedMaxLat = maxLat;
    
    if (geoRatio > canvasRatio) {
      // Mais largo que alto, ajustar latitude
      final targetLatRange = adjustedLngRange / canvasRatio;
      final latDiff = targetLatRange - mercatorLatRange;
      adjustedMinLat = _mercatorToLat(mercatorMinLat - latDiff / 2);
      adjustedMaxLat = _mercatorToLat(mercatorMaxLat + latDiff / 2);
    } else {
      // Mais alto que largo, ajustar longitude
      final targetLngRange = mercatorLatRange * canvasRatio;
      final lngDiff = targetLngRange - adjustedLngRange;
      adjustedMinLng = minLng - lngDiff / 2;
      adjustedMaxLng = maxLng + lngDiff / 2;
    }
    
    // Recalcular ranges finais
    final finalLngRange = adjustedMaxLng - adjustedMinLng;
    
    // Converter para pontos na tela usando projeção mercator
    return coordenadas.map((ponto) {
      final mercatorLat = _latToMercator(ponto.latitude);
      final mercatorMinLat = _latToMercator(adjustedMinLat);
      final mercatorMaxLat = _latToMercator(adjustedMaxLat);
      final mercatorLatRange = mercatorMaxLat - mercatorMinLat;
      
      final x = (ponto.longitude - adjustedMinLng) / finalLngRange * size.width;
      final y = (1 - (mercatorLat - mercatorMinLat) / mercatorLatRange) * size.height;
      return Offset(x, y);
    }).toList();
  }
  
  /// Converte latitude para coordenada Y na projeção mercator
  double _latToMercator(double lat) {
    final latRad = lat * pi / 180;
    return log(tan(pi / 4 + latRad / 2));
  }
  
  /// Converte coordenada Y mercator de volta para latitude
  double _mercatorToLat(double mercatorY) {
    return (2 * atan(exp(mercatorY)) - pi / 2) * 180 / pi;
  }
  
  @override
  bool shouldRepaint(covariant TalhaoCustomPainter oldDelegate) {
    return oldDelegate.pontos != pontos ||
           oldDelegate.cor != cor ||
           oldDelegate.isCompleto != isCompleto ||
           oldDelegate.mostrarPontosControle != mostrarPontosControle ||
           oldDelegate.mostrarPontoSelecionado != mostrarPontoSelecionado ||
           oldDelegate.pontoSelecionadoIndex != pontoSelecionadoIndex ||
           oldDelegate.espessuraBorda != espessuraBorda ||
           oldDelegate.tamanhoPontoControle != tamanhoPontoControle ||
           oldDelegate.opacidadePreenchimento != opacidadePreenchimento;
  }
}

/// Widget para renderizar um talhão no mapa usando CustomPainter
class TalhaoPolygonWidget extends StatelessWidget {
  final List<LatLng> pontos;
  final Color cor;
  final bool isCompleto;
  final bool mostrarPontosControle;
  final bool mostrarPontoSelecionado;
  final int? pontoSelecionadoIndex;
  final double espessuraBorda;
  final double tamanhoPontoControle;
  final double opacidadePreenchimento;
  
  const TalhaoPolygonWidget({
    Key? key,
    required this.pontos,
    required this.cor,
    this.isCompleto = true,
    this.mostrarPontosControle = false,
    this.mostrarPontoSelecionado = false,
    this.pontoSelecionadoIndex,
    this.espessuraBorda = 2.0,
    this.tamanhoPontoControle = 8.0,
    this.opacidadePreenchimento = 0.3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TalhaoCustomPainter(
        pontos: pontos,
        cor: cor,
        isCompleto: isCompleto,
        mostrarPontosControle: mostrarPontosControle,
        mostrarPontoSelecionado: mostrarPontoSelecionado,
        pontoSelecionadoIndex: pontoSelecionadoIndex,
        espessuraBorda: espessuraBorda,
        tamanhoPontoControle: tamanhoPontoControle,
        opacidadePreenchimento: opacidadePreenchimento,
      ),
      child: Container(),
    );
  }
}
