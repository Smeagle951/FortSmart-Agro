import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Widget avançado de botões de ação para talhões
class AdvancedActionButtonsWidget extends StatelessWidget {
  final bool showActionButtons;
  final bool isDrawing;
  final bool isGpsTracking;
  final bool isGpsPaused;
  final List<LatLng> currentPoints;
  final VoidCallback onStartDrawing;
  final VoidCallback onStartGps;
  final VoidCallback onPauseGps;
  final VoidCallback onResumeGps;
  final VoidCallback onFinishGps;
  final VoidCallback onClearDrawing;
  final VoidCallback onSaveTalhao;
  final VoidCallback onImportPolygons;
  final VoidCallback onExportPolygons;
  final VoidCallback onShowHelp;
  final VoidCallback onUndoLastPoint;

  const AdvancedActionButtonsWidget({
    Key? key,
    required this.showActionButtons,
    required this.isDrawing,
    required this.isGpsTracking,
    required this.isGpsPaused,
    required this.currentPoints,
    required this.onStartDrawing,
    required this.onStartGps,
    required this.onPauseGps,
    required this.onResumeGps,
    required this.onFinishGps,
    required this.onClearDrawing,
    required this.onSaveTalhao,
    required this.onImportPolygons,
    required this.onExportPolygons,
    required this.onShowHelp,
    required this.onUndoLastPoint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showActionButtons) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botões principais
          _buildMainButtons(),
          const SizedBox(height: 12),
          
          // Botões secundários
          _buildSecondaryButtons(),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    return Row(
      children: [
        // Botão de desenho manual
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'Desenhar',
            color: Colors.blue,
            onPressed: isDrawing ? null : onStartDrawing,
            isActive: isDrawing,
          ),
        ),
        const SizedBox(width: 12),
        
        // Botão de GPS
        Expanded(
          child: _buildGpsButton(),
        ),
        const SizedBox(width: 12),
        
        // Botão de salvar
        Expanded(
          child: _buildActionButton(
            icon: Icons.save,
            label: 'Salvar',
            color: Colors.green,
            onPressed: currentPoints.length >= 3 ? onSaveTalhao : null,
            isActive: false,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsButton() {
    if (!isGpsTracking) {
      return _buildActionButton(
        icon: Icons.gps_fixed,
        label: 'GPS',
        color: Colors.orange,
        onPressed: onStartGps,
        isActive: false,
      );
    } else if (isGpsPaused) {
      return _buildActionButton(
        icon: Icons.play_arrow,
        label: 'Retomar',
        color: Colors.green,
        onPressed: onResumeGps,
        isActive: true,
      );
    } else {
      return _buildActionButton(
        icon: Icons.pause,
        label: 'Pausar',
        color: Colors.orange,
        onPressed: onPauseGps,
        isActive: true,
      );
    }
  }

  Widget _buildSecondaryButtons() {
    return Row(
      children: [
        // Botão de limpar
        Expanded(
          child: _buildActionButton(
            icon: Icons.clear,
            label: 'Limpar',
            color: Colors.red,
            onPressed: currentPoints.isNotEmpty ? onClearDrawing : null,
            isActive: false,
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão de desfazer
        Expanded(
          child: _buildActionButton(
            icon: Icons.undo,
            label: 'Desfazer',
            color: Colors.grey,
            onPressed: currentPoints.isNotEmpty ? onUndoLastPoint : null,
            isActive: false,
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão de importar
        Expanded(
          child: _buildActionButton(
            icon: Icons.upload,
            label: 'Importar',
            color: Colors.purple,
            onPressed: onImportPolygons,
            isActive: false,
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão de exportar
        Expanded(
          child: _buildActionButton(
            icon: Icons.download,
            label: 'Exportar',
            color: Colors.teal,
            onPressed: currentPoints.length >= 3 ? onExportPolygons : null,
            isActive: false,
          ),
        ),
        const SizedBox(width: 8),
        
        // Botão de ajuda
        Expanded(
          child: _buildActionButton(
            icon: Icons.help,
            label: 'Ajuda',
            color: Colors.indigo,
            onPressed: onShowHelp,
            isActive: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isActive,
  }) {
    return Container(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? color : Colors.white,
          foregroundColor: isActive ? Colors.white : color,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: color,
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para botões flutuantes de ação rápida
class FloatingActionButtonsWidget extends StatelessWidget {
  final bool isDrawing;
  final bool isGpsTracking;
  final bool isGpsPaused;
  final List<LatLng> currentPoints;
  final VoidCallback onStartDrawing;
  final VoidCallback onStartGps;
  final VoidCallback onPauseGps;
  final VoidCallback onResumeGps;
  final VoidCallback onFinishGps;
  final VoidCallback onSaveTalhao;

  const FloatingActionButtonsWidget({
    Key? key,
    required this.isDrawing,
    required this.isGpsTracking,
    required this.isGpsPaused,
    required this.currentPoints,
    required this.onStartDrawing,
    required this.onStartGps,
    required this.onPauseGps,
    required this.onResumeGps,
    required this.onFinishGps,
    required this.onSaveTalhao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de salvar (sempre visível se há pontos)
          if (currentPoints.length >= 3)
            _buildFloatingButton(
              icon: Icons.save,
              color: Colors.green,
              onPressed: onSaveTalhao,
            ),
          
          if (currentPoints.length >= 3) const SizedBox(height: 12),
          
          // Botão de GPS
          _buildGpsFloatingButton(),
          
          const SizedBox(height: 12),
          
          // Botão de desenho
          _buildFloatingButton(
            icon: isDrawing ? Icons.stop : Icons.edit,
            color: isDrawing ? Colors.red : Colors.blue,
            onPressed: isDrawing ? () {} : onStartDrawing, // TODO: Implementar stop
          ),
        ],
      ),
    );
  }

  Widget _buildGpsFloatingButton() {
    if (!isGpsTracking) {
      return _buildFloatingButton(
        icon: Icons.gps_fixed,
        color: Colors.orange,
        onPressed: onStartGps,
      );
    } else if (isGpsPaused) {
      return _buildFloatingButton(
        icon: Icons.play_arrow,
        color: Colors.green,
        onPressed: onResumeGps,
      );
    } else {
      return _buildFloatingButton(
        icon: Icons.pause,
        color: Colors.orange,
        onPressed: onPauseGps,
      );
    }
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}
