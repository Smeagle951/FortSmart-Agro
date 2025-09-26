import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'utils/geo_math.dart';

/// Extensões para o MapController para adicionar funcionalidades extras
extension MapControllerExtensions on MapController {
  /// Move o mapa para uma nova posição com animação
  void animatedMove(
    LatLng destLocation,
    double destZoom, {
    Curve curve = Curves.fastOutSlowIn,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    final latTween = Tween<double>(
      begin: center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: duration,
      vsync: const _NullTickerProvider(),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );

    controller.addListener(() {
      move(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
  
  /// Centraliza o mapa em um polígono, ajustando o zoom para que todo o polígono seja visível
  void fitPolygon(
    List<LatLng> pontos, {
    double padding = 50.0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (pontos.isEmpty) return;
    
    // Se tiver apenas um ponto, centraliza nele
    if (pontos.length == 1) {
      animatedMove(pontos.first, 15, duration: duration);
      return;
    }
    
    // Encontrar os limites do polígono
    double minLat = pontos.first.latitude;
    double maxLat = pontos.first.latitude;
    double minLng = pontos.first.longitude;
    double maxLng = pontos.first.longitude;
    
    for (final ponto in pontos) {
      if (ponto.latitude < minLat) minLat = ponto.latitude;
      if (ponto.latitude > maxLat) maxLat = ponto.latitude;
      if (ponto.longitude < minLng) minLng = ponto.longitude;
      if (ponto.longitude > maxLng) maxLng = ponto.longitude;
    }
    
    // Calcular o centro do polígono
    final centroLat = (minLat + maxLat) / 2;
    final centroLng = (minLng + maxLng) / 2;
    final centro = LatLng(centroLat, centroLng);
    
    // Calcular o zoom necessário
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    
    // Fator de conversão aproximado de graus para pixels no equador
    const pixelsPorGrau = 111319.9; // metros por grau no equador
    final metrosPorPixel = 156543.03392 * Math.cos(centroLat * Math.pi / 180) / Math.pow(2, zoom);
    
    // Calcular o zoom necessário para mostrar todo o polígono
    final latZoom = _calcularZoomPorDimensao(latDiff, padding, metrosPorPixel, pixelsPorGrau);
    final lngZoom = _calcularZoomPorDimensao(lngDiff, padding, metrosPorPixel, pixelsPorGrau);
    
    // Usar o menor zoom para garantir que todo o polígono seja visível
    final novoZoom = Math.min(latZoom, lngZoom);
    
    // Limitar o zoom para valores razoáveis
    final zoomFinal = novoZoom.clamp(3.0, 18.0);
    
    // Mover o mapa
    animatedMove(centro, zoomFinal, duration: duration);
  }
  
  /// Calcula o zoom necessário para mostrar uma dimensão específica
  double _calcularZoomPorDimensao(
    double diferencaGraus,
    double padding,
    double metrosPorPixel,
    double pixelsPorGrau,
  ) {
    // Converter a diferença em graus para metros
    final distanciaMetros = diferencaGraus * pixelsPorGrau;
    
    // Calcular o número de pixels necessários
    final pixelsNecessarios = distanciaMetros / metrosPorPixel + (padding * 2);
    
    // Calcular o zoom necessário
    return Math.log(256 * 2 / pixelsNecessarios) / Math.ln2;
  }
  
  /// Centraliza o mapa em um ponto com animação
  void centralizarEm(
    LatLng ponto, {
    double zoom = 15.0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    animatedMove(ponto, zoom, duration: duration);
  }
  
  /// Centraliza o mapa na posição atual do usuário
  void centralizarEmPosicaoAtual(
    LatLng? posicaoAtual, {
    double zoom = 18.0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (posicaoAtual != null) {
      animatedMove(posicaoAtual, zoom, duration: duration);
    }
  }
}

/// Implementação simples de TickerProvider para uso com animações
class _NullTickerProvider extends TickerProvider {
  const _NullTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick, debugLabel: 'MapControllerExtensions');
  }
}

/// Classe utilitária para operações matemáticas
class Math {
  static double min(double a, double b) => a < b ? a : b;
  static double max(double a, double b) => a > b ? a : b;
  static double pow(double x, double exponent) => x * x; // Simplificado para expoente 2
  static double cos(double x) => GeoMath.cos(x);
  static double log(double x) => _logBase10(x);
  static const double ln2 = 0.693147180559945;
  static const double pi = 3.14159265359;
  
  /// Implementação simples de logaritmo base 10
  static double _logBase10(double x) {
    // Implementação simples usando logaritmo natural
    return _ln(x) / _ln(10);
  }
  
  /// Implementação simples de logaritmo natural
  static double _ln(double x) {
    // Implementação aproximada para valores positivos
    if (x <= 0) return 0;
    
    // Série de Taylor simplificada para ln(x)
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double termPower = term;
    
    for (int i = 0; i < 10; i++) {
      result += termPower / (2 * i + 1);
      termPower *= termSquared;
    }
    
    return 2 * result;
  }
}
