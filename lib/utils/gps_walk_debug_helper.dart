import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'gps_walk_calculator.dart';

/// Helper para debug e validação do modo caminhada GPS
class GpsWalkDebugHelper {
  static final List<String> _debugLogs = [];
  static bool _isDebugMode = true;
  
  /// Ativa/desativa modo debug
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
    if (enabled) {
      _debugLogs.clear();
      _log('🔧 Modo debug ativado');
    }
  }
  
  /// Adiciona log de debug
  static void _log(String message) {
    if (_isDebugMode) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      _debugLogs.add('[$timestamp] $message');
      print('🔍 [GPS_WALK_DEBUG] $message');
    }
  }
  
  /// Log de inicialização do GPS
  static void logGpsStart() {
    _log('🚀 GPS Walk Mode iniciado');
    _log('📱 Configurações: accuracy=high, distanceFilter=0m');
    _log('🎯 Precisão máxima: < 10m para agricultura');
  }
  
  /// Log de ponto GPS recebido
  static void logGpsPoint(LatLng point, double accuracy, bool isValid) {
    _log('📍 Ponto GPS: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}');
    _log('📏 Precisão: ${accuracy.toStringAsFixed(1)}m - ${isValid ? "✅ VÁLIDO" : "❌ REJEITADO"}');
  }
  
  /// Log de cálculo de métricas
  static void logMetricsCalculation(List<LatLng> points, double area, double perimeter) {
    _log('📊 Cálculo de métricas:');
    _log('   - Pontos: ${points.length}');
    _log('   - Área: ${area.toStringAsFixed(2)} ha (Shoelace + UTM)');
    _log('   - Perímetro: ${perimeter.toStringAsFixed(1)} m (Haversine)');
  }
  
  /// Log de validação de polígono
  static void logPolygonValidation(List<LatLng> points, bool isValid) {
    _log('🔍 Validação de polígono:');
    _log('   - Pontos: ${points.length}');
    _log('   - Válido: ${isValid ? "✅ SIM" : "❌ NÃO"}');
    if (!isValid && points.length < 3) {
      _log('   - Erro: Mínimo 3 pontos necessários');
    }
  }
  
  /// Log de fechamento de polígono
  static void logPolygonClosure(List<LatLng> originalPoints, List<LatLng> closedPoints) {
    _log('🔗 Fechamento de polígono:');
    _log('   - Pontos originais: ${originalPoints.length}');
    _log('   - Pontos após fechamento: ${closedPoints.length}');
    if (closedPoints.length > originalPoints.length) {
      _log('   - ✅ Polígono fechado automaticamente');
    }
  }
  
  /// Log de erro
  static void logError(String error, [StackTrace? stackTrace]) {
    _log('❌ ERRO: $error');
    if (stackTrace != null) {
      _log('📍 Stack trace: ${stackTrace.toString().split('\n').first}');
    }
  }
  
  /// Log de sucesso
  static void logSuccess(String message) {
    _log('✅ SUCESSO: $message');
  }
  
  /// Log de status do GPS
  static void logGpsStatus(String status) {
    _log('📡 Status GPS: $status');
  }
  
  /// Log de controle (pausar/retomar/parar)
  static void logControl(String action) {
    _log('🎮 Controle: $action');
  }
  
  /// Obtém todos os logs
  static List<String> getLogs() {
    return List.from(_debugLogs);
  }
  
  /// Limpa logs
  static void clearLogs() {
    _debugLogs.clear();
    _log('🧹 Logs limpos');
  }
  
  /// Testa o calculador GPS Walk
  static Map<String, dynamic> testCalculator() {
    _log('🧪 Testando GpsWalkCalculator...');
    
    // Pontos de teste (quadrado de 100m x 100m)
    final testPoints = [
      LatLng(-23.5505, -46.6333), // São Paulo
      LatLng(-23.5505, -46.6323), // +100m leste
      LatLng(-23.5515, -46.6323), // +100m sul
      LatLng(-23.5515, -46.6333), // +100m oeste
    ];
    
    try {
      final area = GpsWalkCalculator.calculatePolygonAreaHectares(testPoints);
      final perimeter = GpsWalkCalculator.calculatePolygonPerimeter(testPoints);
      final isValid = GpsWalkCalculator.isValidPolygon(testPoints);
      final closedPoints = GpsWalkCalculator.closePolygon(testPoints);
      
      _log('✅ Teste do calculador concluído:');
      _log('   - Área: ${area.toStringAsFixed(4)} ha');
      _log('   - Perímetro: ${perimeter.toStringAsFixed(1)} m');
      _log('   - Válido: ${isValid ? "SIM" : "NÃO"}');
      _log('   - Pontos fechados: ${closedPoints.length}');
      
      return {
        'success': true,
        'area': area,
        'perimeter': perimeter,
        'isValid': isValid,
        'closedPoints': closedPoints.length,
        'message': 'Calculador funcionando corretamente'
      };
    } catch (e) {
      _log('❌ Erro no teste do calculador: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erro no calculador'
      };
    }
  }
  
  /// Cria widget de debug para mostrar logs em tempo real
  static Widget createDebugWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'GPS Walk Debug',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: clearLogs,
                icon: const Icon(Icons.clear, color: Colors.red, size: 16),
                tooltip: 'Limpar logs',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _debugLogs.map((log) => Text(
                  log,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: testCalculator,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Testar Calculador', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setDebugMode(!_isDebugMode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDebugMode ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isDebugMode ? 'Desativar' : 'Ativar', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Cria indicador visual de status do GPS
  static Widget createGpsStatusIndicator({
    required bool isTracking,
    required bool isPaused,
    required double accuracy,
    required int pointCount,
    required double area,
    required double perimeter,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTracking ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTracking ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTracking ? Icons.gps_fixed : Icons.gps_off,
                color: isTracking ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isTracking ? 'GPS ATIVO' : 'GPS INATIVO',
                style: TextStyle(
                  color: isTracking ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isPaused) ...[
                const SizedBox(width: 8),
                const Icon(Icons.pause, color: Colors.orange, size: 16),
                const Text('PAUSADO', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Pontos', pointCount.toString(), Icons.location_on),
              ),
              Expanded(
                child: _buildMetricItem('Precisão', '${accuracy.toStringAsFixed(1)}m', Icons.center_focus_strong),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Área', '${area.toStringAsFixed(2)} ha', Icons.straighten),
              ),
              Expanded(
                child: _buildMetricItem('Perímetro', '${perimeter.toStringAsFixed(1)} m', Icons.square_foot),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static Widget _buildMetricItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
