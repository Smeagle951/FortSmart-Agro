import 'package:flutter/material.dart';
import '../../../models/ponto_monitoramento_model.dart';

class PointMonitoringHeader extends StatelessWidget {
  final PontoMonitoramentoModel? currentPoint;
  final PontoMonitoramentoModel? nextPoint;
  final String talhaoNome;
  final String culturaNome;
  final String? gpsStatus;
  final double? distanceToPoint;
  final bool hasArrived;
  final bool isBackgroundModeEnabled;
  final VoidCallback? onToggleBackground;

  const PointMonitoringHeader({
    Key? key,
    this.currentPoint,
    this.nextPoint,
    required this.talhaoNome,
    required this.culturaNome,
    this.gpsStatus,
    this.distanceToPoint,
    this.hasArrived = false,
    this.isBackgroundModeEnabled = false,
    this.onToggleBackground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentOrder = currentPoint?.ordem ?? 0;
    final totalPoints = nextPoint != null ? (currentOrder + 1) : currentOrder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C), // Grafite
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão voltar
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          const SizedBox(width: 8),
          
          // Título principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ponto $currentOrder/$totalPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$talhaoNome • $culturaNome',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Status GPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGpsStatusColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gps_fixed,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  gpsStatus ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botão modo background
          IconButton(
            onPressed: onToggleBackground,
            icon: Icon(
              isBackgroundModeEnabled ? Icons.visibility_off : Icons.visibility,
              color: isBackgroundModeEnabled ? Colors.green : Colors.white70,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isBackgroundModeEnabled ? 'Parar modo background' : 'Iniciar modo background',
          ),
          
          const SizedBox(width: 8),
          
          // Botão ajuda
          IconButton(
            onPressed: _showHelp,
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white70,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          const SizedBox(width: 8),
          
          // Botão mapa completo
          IconButton(
            onPressed: _showFullMap,
            icon: const Icon(
              Icons.map_outlined,
              color: Colors.white70,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Color _getGpsStatusColor() {
    if (gpsStatus == null) return Colors.grey;
    
    if (gpsStatus!.contains('Erro')) return Colors.red;
    
    // Extrair número de metros da string (ex: "5.2m")
    final match = RegExp(r'(\d+\.?\d*)m').firstMatch(gpsStatus!);
    if (match != null) {
      final accuracy = double.tryParse(match.group(1) ?? '') ?? 999;
      if (accuracy <= 5) return Colors.green;
      if (accuracy <= 10) return Colors.orange;
      return Colors.red;
    }
    
    return Colors.grey;
  }

  void _showHelp() {
    // Implementar tela de ajuda
  }

  void _showFullMap() {
    // Implementar visualização do mapa completo
  }
}
