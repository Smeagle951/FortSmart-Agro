import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/logger.dart';

/// Serviço para gerar relatórios de rastreamento GPS
class TrackingReportService {
  
  /// Gera relatório completo de rastreamento
  Future<String> generateTrackingReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final report = _buildReport(
        trackPoints: trackPoints,
        totalDistance: totalDistance,
        averageAccuracy: averageAccuracy,
        startTime: startTime,
        endTime: endTime,
        method: method,
        additionalData: additionalData,
      );
      
      final fileName = 'relatorio_rastreamento_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await _saveReport(fileName, report);
      
      Logger.info('✅ Relatório de rastreamento gerado: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      rethrow;
    }
  }
  
  /// Gera relatório em formato CSV
  Future<String> generateCSVReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final csv = _buildCSVReport(
        trackPoints: trackPoints,
        totalDistance: totalDistance,
        averageAccuracy: averageAccuracy,
        startTime: startTime,
        endTime: endTime,
        method: method,
        additionalData: additionalData,
      );
      
      final fileName = 'relatorio_rastreamento_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = await _saveReport(fileName, csv);
      
      Logger.info('✅ Relatório CSV gerado: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório CSV: $e');
      rethrow;
    }
  }
  
  /// Gera relatório em formato HTML
  Future<String> generateHTMLReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final html = _buildHTMLReport(
        trackPoints: trackPoints,
        totalDistance: totalDistance,
        averageAccuracy: averageAccuracy,
        startTime: startTime,
        endTime: endTime,
        method: method,
        additionalData: additionalData,
      );
      
      final fileName = 'relatorio_rastreamento_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = await _saveReport(fileName, html);
      
      Logger.info('✅ Relatório HTML gerado: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório HTML: $e');
      rethrow;
    }
  }
  
  /// Constrói relatório JSON
  Map<String, dynamic> _buildReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) {
    final duration = endTime.difference(startTime);
    final area = trackPoints.length >= 3 ? _calculatePolygonArea(trackPoints) : 0.0;
    final perimeter = trackPoints.length >= 2 ? _calculatePolygonPerimeter(trackPoints) : 0.0;
    
    return {
      'metadata': {
        'title': 'Relatório de Rastreamento GPS',
        'generated_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'source': 'FortSmart Agro',
      },
      'tracking_info': {
        'method': method,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_seconds': duration.inSeconds,
        'duration_formatted': _formatDuration(duration),
        'total_points': trackPoints.length,
        'total_distance_meters': totalDistance,
        'total_distance_km': totalDistance / 1000,
        'average_accuracy_meters': averageAccuracy,
        'area_hectares': area,
        'perimeter_meters': perimeter,
      },
      'statistics': _calculateStatistics(trackPoints, totalDistance, duration),
      'quality_metrics': _calculateQualityMetrics(trackPoints, averageAccuracy),
      'track_points': trackPoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'index': trackPoints.indexOf(point),
      }).toList(),
      'additional_data': additionalData,
    };
  }
  
  /// Constrói relatório CSV
  String _buildCSVReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) {
    final duration = endTime.difference(startTime);
    final area = trackPoints.length >= 3 ? _calculatePolygonArea(trackPoints) : 0.0;
    final perimeter = trackPoints.length >= 2 ? _calculatePolygonPerimeter(trackPoints) : 0.0;
    
    final csv = StringBuffer();
    
    // Cabeçalho
    csv.writeln('Relatório de Rastreamento GPS - FortSmart Agro');
    csv.writeln('Gerado em: ${DateTime.now().toIso8601String()}');
    csv.writeln('');
    
    // Informações gerais
    csv.writeln('INFORMAÇÕES GERAIS');
    csv.writeln('Método,${method}');
    csv.writeln('Data Início,${startTime.toIso8601String()}');
    csv.writeln('Data Fim,${endTime.toIso8601String()}');
    csv.writeln('Duração,${_formatDuration(duration)}');
    csv.writeln('Total de Pontos,${trackPoints.length}');
    csv.writeln('Distância Total (m),${totalDistance.toStringAsFixed(2)}');
    csv.writeln('Distância Total (km),${(totalDistance / 1000).toStringAsFixed(4)}');
    csv.writeln('Precisão Média (m),${averageAccuracy.toStringAsFixed(2)}');
    csv.writeln('Área (ha),${area.toStringAsFixed(4)}');
    csv.writeln('Perímetro (m),${perimeter.toStringAsFixed(2)}');
    csv.writeln('');
    
    // Estatísticas
    final stats = _calculateStatistics(trackPoints, totalDistance, duration);
    csv.writeln('ESTATÍSTICAS');
    csv.writeln('Velocidade Média (km/h),${stats['average_speed_kmh'].toStringAsFixed(2)}');
    csv.writeln('Velocidade Máxima (km/h),${stats['max_speed_kmh'].toStringAsFixed(2)}');
    csv.writeln('Pontos por Minuto,${stats['points_per_minute'].toStringAsFixed(2)}');
    csv.writeln('Distância entre Pontos (m),${stats['average_distance_between_points'].toStringAsFixed(2)}');
    csv.writeln('');
    
    // Pontos do trajeto
    csv.writeln('PONTOS DO TRAJETO');
    csv.writeln('Índice,Latitude,Longitude');
    for (int i = 0; i < trackPoints.length; i++) {
      final point = trackPoints[i];
      csv.writeln('$i,${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}');
    }
    
    return csv.toString();
  }
  
  /// Constrói relatório HTML
  String _buildHTMLReport({
    required List<LatLng> trackPoints,
    required double totalDistance,
    required double averageAccuracy,
    required DateTime startTime,
    required DateTime endTime,
    required String method,
    required Map<String, dynamic> additionalData,
  }) {
    final duration = endTime.difference(startTime);
    final area = trackPoints.length >= 3 ? _calculatePolygonArea(trackPoints) : 0.0;
    final perimeter = trackPoints.length >= 2 ? _calculatePolygonPerimeter(trackPoints) : 0.0;
    final stats = _calculateStatistics(trackPoints, totalDistance, duration);
    final quality = _calculateQualityMetrics(trackPoints, averageAccuracy);
    
    return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Rastreamento GPS - FortSmart Agro</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }
        .section h2 {
            color: #4CAF50;
            margin-top: 0;
        }
        .metric-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .metric-card {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 6px;
            border-left: 4px solid #4CAF50;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #4CAF50;
        }
        .metric-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
        }
        .quality-indicator {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .quality-excellent { background-color: #4CAF50; color: white; }
        .quality-good { background-color: #FF9800; color: white; }
        .quality-poor { background-color: #F44336; color: white; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Relatório de Rastreamento GPS</h1>
            <p>FortSmart Agro - ${DateTime.now().toString().split('.')[0]}</p>
        </div>
        
        <div class="section">
            <h2>📋 Informações Gerais</h2>
            <div class="metric-grid">
                <div class="metric-card">
                    <div class="metric-value">${method.toUpperCase()}</div>
                    <div class="metric-label">Método</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${_formatDuration(duration)}</div>
                    <div class="metric-label">Duração</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${trackPoints.length}</div>
                    <div class="metric-label">Total de Pontos</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${(totalDistance / 1000).toStringAsFixed(2)} km</div>
                    <div class="metric-label">Distância Total</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>📏 Métricas de Área</h2>
            <div class="metric-grid">
                <div class="metric-card">
                    <div class="metric-value">${area.toStringAsFixed(4)} ha</div>
                    <div class="metric-label">Área</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${perimeter.toStringAsFixed(2)} m</div>
                    <div class="metric-label">Perímetro</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${averageAccuracy.toStringAsFixed(2)} m</div>
                    <div class="metric-label">Precisão Média</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${stats['average_speed_kmh'].toStringAsFixed(2)} km/h</div>
                    <div class="metric-label">Velocidade Média</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>🎯 Qualidade do Rastreamento</h2>
            <div class="metric-grid">
                <div class="metric-card">
                    <div class="metric-value">
                        <span class="quality-indicator quality-${quality['accuracy_quality']}">
                            ${quality['accuracy_quality'].toUpperCase()}
                        </span>
                    </div>
                    <div class="metric-label">Qualidade da Precisão</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${quality['coverage_percentage'].toStringAsFixed(1)}%</div>
                    <div class="metric-label">Cobertura</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${quality['consistency_score'].toStringAsFixed(1)}/10</div>
                    <div class="metric-label">Consistência</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${stats['points_per_minute'].toStringAsFixed(2)}</div>
                    <div class="metric-label">Pontos/Minuto</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>📅 Cronologia</h2>
            <table>
                <tr>
                    <th>Evento</th>
                    <th>Data/Hora</th>
                </tr>
                <tr>
                    <td>Início do Rastreamento</td>
                    <td>${startTime.toString().split('.')[0]}</td>
                </tr>
                <tr>
                    <td>Fim do Rastreamento</td>
                    <td>${endTime.toString().split('.')[0]}</td>
                </tr>
                <tr>
                    <td>Geração do Relatório</td>
                    <td>${DateTime.now().toString().split('.')[0]}</td>
                </tr>
            </table>
        </div>
        
        <div class="section">
            <h2>📍 Pontos do Trajeto (Primeiros 10)</h2>
            <table>
                <tr>
                    <th>#</th>
                    <th>Latitude</th>
                    <th>Longitude</th>
                </tr>
                ${trackPoints.take(10).toList().asMap().entries.map((entry) => '''
                <tr>
                    <td>${entry.key + 1}</td>
                    <td>${entry.value.latitude.toStringAsFixed(6)}</td>
                    <td>${entry.value.longitude.toStringAsFixed(6)}</td>
                </tr>
                ''').join('')}
                ${trackPoints.length > 10 ? '<tr><td colspan="3"><em>... e mais ${trackPoints.length - 10} pontos</em></td></tr>' : ''}
            </table>
        </div>
    </div>
</body>
</html>
    ''';
  }
  
  /// Calcula estatísticas do rastreamento
  Map<String, dynamic> _calculateStatistics(
    List<LatLng> trackPoints,
    double totalDistance,
    Duration duration,
  ) {
    if (trackPoints.isEmpty) {
      return {
        'average_speed_kmh': 0.0,
        'max_speed_kmh': 0.0,
        'points_per_minute': 0.0,
        'average_distance_between_points': 0.0,
      };
    }
    
    // Velocidade média
    final durationHours = duration.inSeconds / 3600;
    final averageSpeedKmh = durationHours > 0 ? (totalDistance / 1000) / durationHours : 0.0;
    
    // Pontos por minuto
    final durationMinutes = duration.inMinutes;
    final pointsPerMinute = durationMinutes > 0 ? trackPoints.length / durationMinutes : 0.0;
    
    // Distância média entre pontos
    final averageDistanceBetweenPoints = trackPoints.length > 1 
        ? totalDistance / (trackPoints.length - 1) 
        : 0.0;
    
    // Velocidade máxima (estimativa baseada na distância entre pontos consecutivos)
    double maxSpeedKmh = 0.0;
    for (int i = 1; i < trackPoints.length; i++) {
      final distance = _calculateDistance(trackPoints[i-1], trackPoints[i]);
      final timeDiff = 1.0; // Assumindo 1 segundo entre pontos
      final speedKmh = (distance / 1000) / (timeDiff / 3600);
      if (speedKmh > maxSpeedKmh) {
        maxSpeedKmh = speedKmh;
      }
    }
    
    return {
      'average_speed_kmh': averageSpeedKmh,
      'max_speed_kmh': maxSpeedKmh,
      'points_per_minute': pointsPerMinute,
      'average_distance_between_points': averageDistanceBetweenPoints,
    };
  }
  
  /// Calcula métricas de qualidade
  Map<String, dynamic> _calculateQualityMetrics(
    List<LatLng> trackPoints,
    double averageAccuracy,
  ) {
    // Qualidade da precisão
    String accuracyQuality;
    if (averageAccuracy <= 5) {
      accuracyQuality = 'excellent';
    } else if (averageAccuracy <= 10) {
      accuracyQuality = 'good';
    } else {
      accuracyQuality = 'poor';
    }
    
    // Cobertura (baseada na densidade de pontos)
    final coveragePercentage = trackPoints.length > 0 ? 100.0 : 0.0;
    
    // Consistência (baseada na variação da distância entre pontos)
    double consistencyScore = 10.0;
    if (trackPoints.length > 2) {
      final distances = <double>[];
      for (int i = 1; i < trackPoints.length; i++) {
        distances.add(_calculateDistance(trackPoints[i-1], trackPoints[i]));
      }
      
      if (distances.isNotEmpty) {
        final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
        final variance = distances.map((d) => (d - avgDistance) * (d - avgDistance))
            .reduce((a, b) => a + b) / distances.length;
        final stdDev = sqrt(variance);
        
        // Penalizar baseado no desvio padrão
        consistencyScore = (10.0 - (stdDev / avgDistance) * 5.0).clamp(0.0, 10.0);
      }
    }
    
    return {
      'accuracy_quality': accuracyQuality,
      'coverage_percentage': coveragePercentage,
      'consistency_score': consistencyScore,
    };
  }
  
  /// Formata duração
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Salva relatório em arquivo
  Future<File> _saveReport(String fileName, dynamic content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      final file = File('${reportsDir.path}/$fileName');
      
      if (content is String) {
        await file.writeAsString(content, encoding: utf8);
      } else {
        await file.writeAsString(jsonEncode(content), encoding: utf8);
      }
      
      return file;
    } catch (e) {
      Logger.error('❌ Erro ao salvar relatório: $e');
      rethrow;
    }
  }
  
  /// Compartilha relatório
  Future<void> shareReport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Relatório de rastreamento GPS - FortSmart Agro');
        Logger.info('✅ Relatório compartilhado: $filePath');
      } else {
        throw Exception('Arquivo não encontrado: $filePath');
      }
    } catch (e) {
      Logger.error('❌ Erro ao compartilhar relatório: $e');
      rethrow;
    }
  }
  
  /// Lista relatórios gerados
  Future<List<File>> listReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      
      if (!await reportsDir.exists()) {
        return [];
      }
      
      final files = await reportsDir.list().where((entity) => entity is File).cast<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      Logger.error('❌ Erro ao listar relatórios: $e');
      return [];
    }
  }
  
  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calcula área do polígono
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    const km2PerDegree2 = 111.32 * 111.32;
    const haPerKm2 = 100.0;
    
    return area * km2PerDegree2 * haPerKm2;
  }
  
  /// Calcula perímetro do polígono
  double _calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    final n = points.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      perimeter += _calculateDistance(points[i], points[j]);
    }
    
    return perimeter;
  }
}
