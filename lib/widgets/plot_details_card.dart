import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortsmart_agro/utils/map_global_adapter.dart';
import 'package:fortsmart_agro/utils/precise_geo_calculator.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import '../models/plot.dart';

/// Widget para exibir os detalhes de um talhão selecionado
class PlotDetailsCard extends StatelessWidget {
  final Plot plot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  
  const PlotDetailsCard({
    Key? key,
    required this.plot,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determinar a cor da cultura ou usar um valor padrão
    final culturaCor = Colors.amber.shade400;
        
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 12,
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color(0xE6232323), // fundo escuro translúcido
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: culturaCor.withOpacity(0.28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map, color: culturaCor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      plot.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      // Adicionar feedback tátil
                      HapticFeedback.lightImpact();
                      onClose();
                    },
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
          
              // Miniatura do polígono
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _PlotPolygonPainter(plot: plot, culturaCor: culturaCor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Informações do talhão
              Row(
                children: [
                  Icon(Icons.grass, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    plot.cropName ?? 'Sem cultura',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.square_foot, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  FutureBuilder<double>(
                    future: _getPlotArea(plot),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '${snapshot.data!.toStringAsFixed(2)} ha',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        );
                      } else {
                        return Text(
                          'Calculando...',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.pin_drop, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${plot.coordinates!.length} vértices',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
                if (plot.description != null && plot.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.description,
                    label: 'Descrição',
                    value: plot.description!,
                  ),
                ],
                
              // Botões de ação
              const SizedBox(height: 18),
              // Botões de desenvolvimento removidos para produção
              const SizedBox(height: 8)
            ],
          ),
        ),
      ),
    );
  }
  
  /// Constrói uma linha de informação com ícone, rótulo e valor
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Obtém área de um plot usando cálculo geodésico preciso
  Future<double> _getPlotArea(Plot plot) async {
    try {
      print('🔄 Calculando área para plot: ${plot.name}');
      
      // 1. Tentar obter área do modelo diretamente (prioridade máxima)
      if (plot.area != null && plot.area! > 0) {
        print('📊 Área do plot ${plot.name}: ${plot.area!.toStringAsFixed(2)} ha (dados salvos)');
        return plot.area!;
      }
      
      // 2. Calcular área das coordenadas usando PolygonMetricsService
      if (plot.coordinates != null && plot.coordinates!.isNotEmpty) {
        final pontos = plot.coordinates!
            .where((coord) => coord['latitude'] != null && coord['longitude'] != null)
            .map((coord) => latlong2.LatLng(coord['latitude']!, coord['longitude']!))
            .toList();
        
        if (pontos.length >= 3) {
          print('🔄 Calculando área para plot ${plot.name} com ${pontos.length} pontos...');
          
          // Usar PreciseGeoCalculator para cálculo preciso
          final area = PreciseGeoCalculator.calculatePolygonAreaHectares(pontos);
          
          // Validar se a área calculada é razoável (entre 0.1 e 10000 ha)
          if (area > 0.1 && area < 10000) {
            print('✅ Área calculada para ${plot.name}: ${area.toStringAsFixed(2)} ha');
            return area;
          } else {
            print('⚠️ Área calculada inválida para ${plot.name}: ${area.toStringAsFixed(2)} ha');
          }
        } else {
          print('⚠️ Plot ${plot.name} tem menos de 3 pontos válidos: ${pontos.length}');
        }
      } else {
        print('⚠️ Plot ${plot.name} não tem coordenadas');
      }
      
      print('⚠️ Não foi possível calcular área para plot ${plot.name}');
      return 0.0;
    } catch (e) {
      print('❌ Erro ao obter área do plot ${plot.name}: $e');
      return 0.0;
    }
  }
}

/// Painter para desenhar o polígono do talhão
class _PlotPolygonPainter extends CustomPainter {
  final Plot plot;
  final Color culturaCor;
  
  _PlotPolygonPainter({required this.plot, this.culturaCor = Colors.amber});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (plot.coordinates == null || plot.coordinates!.isEmpty) return;
    
    final points = _normalizePoints(plot.coordinates!, size);
    
    // Desenha o polígono
    final paint = Paint()
      ..color = culturaCor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, paint);
    
    // Desenha o contorno
    final borderPaint = Paint()
      ..color = culturaCor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    canvas.drawPath(path, borderPaint);
    
    // Desenha os pontos
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pointBorderPaint = Paint()
      ..color = culturaCor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (final point in points) {
      canvas.drawCircle(point, 4.0, pointPaint);
      canvas.drawCircle(point, 4.0, pointBorderPaint);
    }
  }
  
  /// Normaliza as coordenadas geográficas para o tamanho do container
  List<Offset> _normalizePoints(List<Map<String, double>> coordinates, Size size) {
    if (coordinates.isEmpty) return [];
    
    // Converter de Map para LatLng
    final points = coordinates.map((coord) => 
      latlong2.LatLng(coord['latitude'] ?? 0, coord['longitude'] ?? 0)).toList();
      
    if (points.isEmpty) return [];
    
    // Encontrar os limites do polígono
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;
    
    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    // Adicionar margem para evitar que o polígono fique muito próximo das bordas
    final padding = size.width * 0.1;
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2);
    
    // Calcular fatores de escala
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    // Evitar divisão por zero
    final latScale = latRange > 0 ? availableHeight / latRange : 1;
    final lngScale = lngRange > 0 ? availableWidth / lngRange : 1;
    
    // Usar o menor fator de escala para manter a proporção
    final scale = latScale < lngScale ? latScale : lngScale;
    
    // Normalizar pontos
    final List<Offset> normalizedPoints = [];
    
    for (var point in points) {
      // Inverter a latitude (y) porque as coordenadas do canvas aumentam para baixo
      final x = padding + ((point.longitude - minLng) * scale);
      final y = size.height - (padding + ((point.latitude - minLat) * scale));
      
      normalizedPoints.add(Offset(x, y));
    }
    
    return normalizedPoints;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
