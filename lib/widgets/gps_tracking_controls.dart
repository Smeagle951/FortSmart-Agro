import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Widget para controles de rastreamento GPS
/// Mostra status, precisão, distância e controles de pausa/play
class GpsTrackingControls extends StatelessWidget {
  final bool isTracking;
  final bool isPaused;
  final double distance;
  final double accuracy;
  final String status;
  final int pointsCount;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onFinish;

  const GpsTrackingControls({
    Key? key,
    required this.isTracking,
    required this.isPaused,
    required this.distance,
    required this.accuracy,
    required this.status,
    required this.pointsCount,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onFinish,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status e precisão
          _buildStatusRow(),
          const SizedBox(height: 12),
          
          // Métricas
          _buildMetricsRow(),
          const SizedBox(height: 16),
          
          // Controles
          _buildControlsRow(),
        ],
      ),
    );
  }

  /// Constrói linha de status e precisão
  Widget _buildStatusRow() {
    return Row(
      children: [
        // Ícone de status
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Status e precisão
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 12,
                    color: _getAccuracyColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Precisão: ${accuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getAccuracyColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Indicador de precisão
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getAccuracyColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getAccuracyText(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getAccuracyColor(),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói linha de métricas
  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Distância
        Expanded(
          child: _buildMetricCard(
            icon: Icons.straighten,
            title: 'Distância',
            value: '${(distance / 1000).toStringAsFixed(2)} km',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        
        // Pontos
        Expanded(
          child: _buildMetricCard(
            icon: Icons.location_on,
            title: 'Pontos',
            value: pointsCount.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// Constrói linha de controles
  Widget _buildControlsRow() {
    if (!isTracking) {
      // Botão de iniciar
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar Rastreamento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // Controles ativos
    return Row(
      children: [
        // Botão pausar/retomar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(isPaused ? 'Retomar' : 'Pausar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaused ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão parar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Parar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão finalizar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.check),
            label: const Text('Finalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói card de métrica
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém cor do status
  Color _getStatusColor() {
    if (!isTracking) return Colors.grey;
    if (isPaused) return Colors.orange;
    return Colors.green;
  }

  /// Obtém ícone do status
  IconData _getStatusIcon() {
    if (!isTracking) return Icons.gps_off;
    if (isPaused) return Icons.pause_circle;
    return Icons.gps_fixed;
  }

  /// Obtém cor da precisão
  Color _getAccuracyColor() {
    if (accuracy <= 5) return Colors.green;
    if (accuracy <= 10) return Colors.orange;
    return Colors.red;
  }

  /// Obtém texto da precisão
  String _getAccuracyText() {
    if (accuracy <= 5) return 'EXCELENTE';
    if (accuracy <= 10) return 'BOA';
    return 'RUIM';
  }
}
