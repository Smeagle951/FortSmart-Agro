import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'map_imports.dart' as maps;
import 'map_types.dart';

/// Classe utilitária para operações com mapas
class MapUtils {
  /// Calcula a área de um polígono em hectares
  static double calcularAreaPoligono(List<maps.LatLng> pontos) {
    if (pontos.length < 3) return 0;

    double area = 0;
    final int numPoints = pontos.length;

    for (int i = 0; i < numPoints; i++) {
      int j = (i + 1) % numPoints;
      area += pontos[i].longitude * pontos[j].latitude;
      area -= pontos[j].longitude * pontos[i].latitude;
    }

    area = area.abs() * 0.5;
    // Converter para hectares (aproximação)
    const double metersPerDegreeAtEquator = 111319.9;
    return area * math.pow(metersPerDegreeAtEquator, 2) / 10000;
  }

  /// Converte uma lista de pontos para formato JSON
  static List<Map<String, double>> pontosParaJson(List<maps.LatLng> pontos) {
    return pontos.map((ponto) => {
      'lat': ponto.latitude,
      'lng': ponto.longitude,
    }).toList();
  }

  /// Converte uma string JSON para lista de pontos
  static List<maps.LatLng> jsonParaPontos(String json) {
    try {
      final List<dynamic> lista = maps.jsonDecode(json);
      return lista.map((item) => maps.LatLng(
        double.parse(item['lat'].toString()),
        double.parse(item['lng'].toString()),
      )).toList();
    } catch (e) {
      print('Erro ao converter JSON para pontos: $e');
      return [];
    }
  }

  /// Calcula o centro de um conjunto de pontos
  static maps.LatLng calcularCentro(List<maps.LatLng> pontos) {
    if (pontos.isEmpty) {
      return const maps.LatLng(0, 0);
    }

    double somaLat = 0;
    double somaLng = 0;

    for (var ponto in pontos) {
      somaLat += ponto.latitude;
      somaLng += ponto.longitude;
    }

    return maps.LatLng(
      somaLat / pontos.length,
      somaLng / pontos.length,
    );
  }

  /// Calcula os limites (bounds) que contêm todos os pontos
  static maps.LatLngBounds calcularLimites(List<maps.LatLng> pontos) {
    if (pontos.isEmpty) {
      // Retornar um bound padrão para o Brasil
      return maps.LatLngBounds(
        southwest: const maps.LatLng(-33.7683, -73.9872), // Extremo sudoeste do Brasil
        northeast: const maps.LatLng(5.2717, -34.7299),   // Extremo nordeste do Brasil
      );
    }

    double minLat = pontos[0].latitude;
    double maxLat = pontos[0].latitude;
    double minLng = pontos[0].longitude;
    double maxLng = pontos[0].longitude;

    for (var ponto in pontos) {
      minLat = math.min(minLat, ponto.latitude);
      maxLat = math.max(maxLat, ponto.latitude);
      minLng = math.min(minLng, ponto.longitude);
      maxLng = math.max(maxLng, ponto.longitude);
    }

    // Adicionar um pequeno padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    return maps.LatLngBounds(
      southwest: maps.LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: maps.LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  /// Converte pontos do adaptador para o formato latlong2
  static List<latlong2.LatLng> pontosParaLatLong2(List<maps.LatLng> pontos) {
    return pontos.map((ponto) => latlong2.LatLng(
      ponto.latitude,
      ponto.longitude,
    )).toList();
  }

  /// Converte pontos do formato latlong2 para o adaptador
  static List<maps.LatLng> latLong2ParaPontos(List<latlong2.LatLng> pontos) {
    return pontos.map((ponto) => maps.LatLng(
      ponto.latitude,
      ponto.longitude,
    )).toList();
  }

  /// Cria um marcador para o mapa
  static maps.Marker criarMarcador({
    required maps.LatLng posicao,
    required Function() onTap,
    required int index,
    required bool selecionado,
  }) {
    return maps.Marker(
      markerId: 'marcador_$index',
      position: posicao,
      onTap: onTap as void Function()?,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: selecionado ? Colors.blue : Colors.red,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
