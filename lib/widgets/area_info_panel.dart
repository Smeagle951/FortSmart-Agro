import 'package:flutter/material.dart';

/// Widget para exibir informações sobre a área durante a edição de talhões
class AreaInfoPanel extends StatelessWidget {
  final double area;
  final int pointCount;
  final String? message;
  final bool isGpsMode;
  final bool isDrawMode;
  final bool isEraseMode;
  
  const AreaInfoPanel({
    Key? key,
    required this.area,
    required this.pointCount,
    this.message,
    this.isGpsMode = false,
    this.isDrawMode = false,
    this.isEraseMode = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modo atual
          if (isGpsMode || isDrawMode || isEraseMode)
            _buildModeIndicator(),
          
          // Área e pontos
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.area_chart,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Área: ${area.toStringAsFixed(2)} ha',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.pin_drop,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pontos: $pointCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Mensagem adicional
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Constrói o indicador de modo atual
  Widget _buildModeIndicator() {
    IconData icon;
    String label;
    Color color;
    
    if (isGpsMode) {
      icon = Icons.gps_fixed;
      label = 'Modo GPS';
      color = Colors.blue;
    } else if (isDrawMode) {
      icon = Icons.edit;
      label = 'Modo Desenho';
      color = Colors.green;
    } else if (isEraseMode) {
      icon = Icons.delete;
      label = 'Modo Borracha';
      color = Colors.red;
    } else {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
