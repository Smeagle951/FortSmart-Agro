import 'package:flutter/material.dart';

/// Widget para controles de desenho GPS
class GpsDrawingControlsWidget extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onStartGps;
  final VoidCallback onPauseGps;
  final VoidCallback onStopGps;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onImport;
  final VoidCallback onFinish;

  const GpsDrawingControlsWidget({
    Key? key,
    required this.isRecording,
    required this.isPaused,
    required this.onStartGps,
    required this.onPauseGps,
    required this.onStopGps,
    required this.onUndo,
    required this.onClear,
    required this.onImport,
    required this.onFinish,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // Título
          const Text(
            'Controles de Desenho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primeira linha - GPS, Desenhar, Salvar
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.gps_fixed,
                  label: 'GPS',
                  onPressed: onStartGps,
                  backgroundColor: isRecording ? Colors.green : Colors.blue,
                  isActive: isRecording,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.edit,
                  label: 'Desenhar',
                  onPressed: () {}, // Implementar se necessário
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.save,
                  label: 'Salvar',
                  onPressed: () {}, // Implementar se necessário
                  backgroundColor: Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda linha - Pausar GPS, Parar GPS
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: isPaused ? Icons.play_arrow : Icons.pause,
                  label: isPaused ? 'Retomar GPS' : 'Pausar GPS',
                  onPressed: onPauseGps,
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.stop,
                  label: 'Parar GPS',
                  onPressed: onStopGps,
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Terceira linha - Desfazer, Limpar
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.undo,
                  label: 'Desfazer',
                  onPressed: onUndo,
                  backgroundColor: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.clear,
                  label: 'Limpar',
                  onPressed: onClear,
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Quarta linha - Importar, Finalizar
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.file_download,
                  label: 'Importar',
                  onPressed: onImport,
                  backgroundColor: Colors.indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.check,
                  label: 'Finalizar',
                  onPressed: onFinish,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isActive = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isActive ? 4 : 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
