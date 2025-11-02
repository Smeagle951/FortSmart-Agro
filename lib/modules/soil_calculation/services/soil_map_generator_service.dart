import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'widget_to_image_service.dart';
import 'package:path_provider/path_provider.dart';

import '../models/soil_compaction_point_model.dart';
import '../constants/app_colors.dart';

/// Serviço para geração de mapas reais como imagens
class SoilMapGeneratorService {
  
  /// Gera mapa de compactação como imagem PNG
  static Future<String> gerarMapaCompactacao({
    required List<SoilCompactionPointModel> pontos,
    required List<LatLng> polygonCoordinates,
    required String nomeTalhao,
    required Map<String, int> distribuicaoNiveis,
    double width = 800,
    double height = 600,
  }) async {
    try {
      // Cria o widget do mapa
      final mapWidget = _buildMapWidget(
        pontos: pontos,
        polygonCoordinates: polygonCoordinates,
        nomeTalhao: nomeTalhao,
        distribuicaoNiveis: distribuicaoNiveis,
      );

      // Converte widget para imagem
      final imageBytes = await _widgetToImage(
        mapWidget,
        width: width,
        height: height,
      );

      // Salva imagem
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'mapa_compactacao_${nomeTalhao}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      throw Exception('Erro ao gerar mapa: $e');
    }
  }

  /// Constrói o widget do mapa
  static Widget _buildMapWidget({
    required List<SoilCompactionPointModel> pontos,
    required List<LatLng> polygonCoordinates,
    required String nomeTalhao,
    required Map<String, int> distribuicaoNiveis,
  }) {
    final centro = _calcularCentroPoligono(polygonCoordinates);
    
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Mapa base
            FlutterMap(
              options: MapOptions(
                center: centro,
                zoom: 15,
                maxZoom: 18,
                minZoom: 10,
              ),
              children: [
                // Mapa satélite
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                  subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                ),
                
                // Polígono do talhão
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonCoordinates,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
                
                // Marcadores de pontos
                MarkerLayer(
                  markers: pontos.map((ponto) => _criarMarkerPonto(ponto)).toList(),
                ),
              ],
            ),
            
            // Título do mapa
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Mapa de Compactação - $nomeTalhao',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Legenda
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildLegenda(distribuicaoNiveis),
            ),
          ],
        ),
      ),
    );
  }

  /// Cria marcador para um ponto
  static Marker _criarMarkerPonto(SoilCompactionPointModel ponto) {
    final nivel = ponto.penetrometria != null
        ? ponto.calcularNivelCompactacao()
        : 'Não Medido';
    final cor = _getCorPorNivel(nivel);

    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            ponto.pointCode.replaceAll('C-', ''),
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

  /// Constrói legenda do mapa
  static Widget _buildLegenda(Map<String, int> distribuicaoNiveis) {
    final cores = {
      'Solo Solto': Colors.green,
      'Moderado': Colors.yellow[700]!,
      'Alto': Colors.orange,
      'Crítico': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...cores.entries.map((entry) {
            final nivel = entry.key;
            final cor = entry.value;
            final quantidade = distribuicaoNiveis[nivel] ?? 0;
            
            if (quantidade == 0) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$nivel ($quantidade)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Converte widget para imagem
  static Future<Uint8List> _widgetToImage(
    Widget widget, {
    required double width,
    required double height,
  }) async {
    final repaintBoundary = RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: widget,
      ),
    );

    // Usa o novo serviço de conversão de widget para imagem
    return await WidgetToImageService.widgetToImageWithSize(
      widget,
      width: width,
      height: height,
      pixelRatio: 2.0, // Alta resolução para mapas
    );
  }

  /// Calcula centro do polígono
  static LatLng _calcularCentroPoligono(List<LatLng> coords) {
    if (coords.isEmpty) return LatLng(0, 0);
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (var coord in coords) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(sumLat / coords.length, sumLng / coords.length);
  }

  /// Retorna cor baseada no nível de compactação
  static Color _getCorPorNivel(String nivel) {
    switch (nivel) {
      case 'Solo Solto':
        return Colors.green;
      case 'Moderado':
        return Colors.yellow[700]!;
      case 'Alto':
        return Colors.orange;
      case 'Crítico':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
