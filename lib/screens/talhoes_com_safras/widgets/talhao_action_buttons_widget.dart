import 'package:flutter/material.dart';

/// Widget personalizado para os botões de ação da tela de talhões
class TalhaoActionButtonsWidget extends StatelessWidget {
  final bool isDrawing;
  final bool showActionButtons;
  final VoidCallback onStartManualDrawing;
  final VoidCallback onFinishManualDrawing;
  final VoidCallback onShowPremiumGps;
  final VoidCallback onStartGpsRecording;
  final VoidCallback onPauseGpsRecording;
  final VoidCallback onResumeGpsRecording;
  final VoidCallback onFinishGpsRecording;
  final VoidCallback onShowTalhaoCard;
  final VoidCallback onClearDrawing;
  final VoidCallback onImportFile;
  final VoidCallback onExportFile;
  final VoidCallback onShowHelp;

  const TalhaoActionButtonsWidget({
    Key? key,
    required this.isDrawing,
    required this.showActionButtons,
    required this.onStartManualDrawing,
    required this.onFinishManualDrawing,
    required this.onShowPremiumGps,
    required this.onStartGpsRecording,
    required this.onPauseGpsRecording,
    required this.onResumeGpsRecording,
    required this.onFinishGpsRecording,
    required this.onShowTalhaoCard,
    required this.onClearDrawing,
    required this.onImportFile,
    required this.onExportFile,
    required this.onShowHelp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão principal de desenho
          FloatingActionButton(
            onPressed: isDrawing ? onFinishManualDrawing : onStartManualDrawing,
            backgroundColor: isDrawing ? Colors.red : const Color(0xFF3BAA57),
            child: Icon(
              isDrawing ? Icons.stop : Icons.edit,
              color: Colors.white,
            ),
            tooltip: isDrawing ? 'Finalizar desenho' : 'Iniciar desenho manual',
          ),
          
          const SizedBox(height: 10),
          
          // Botões secundários (visíveis quando showActionButtons é true)
          if (showActionButtons) ...[
            FloatingActionButton(
              onPressed: onShowPremiumGps,
              backgroundColor: Colors.blue,
              mini: true,
              child: const Icon(Icons.gps_fixed, color: Colors.white),
              tooltip: 'GPS Premium',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onStartGpsRecording,
              backgroundColor: Colors.green,
              mini: true,
              child: const Icon(Icons.play_arrow, color: Colors.white),
              tooltip: 'Iniciar gravação GPS',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onPauseGpsRecording,
              backgroundColor: Colors.orange,
              mini: true,
              child: const Icon(Icons.pause, color: Colors.white),
              tooltip: 'Pausar gravação GPS',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onResumeGpsRecording,
              backgroundColor: Colors.green,
              mini: true,
              child: const Icon(Icons.play_arrow, color: Colors.white),
              tooltip: 'Retomar gravação GPS',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onFinishGpsRecording,
              backgroundColor: Colors.red,
              mini: true,
              child: const Icon(Icons.stop, color: Colors.white),
              tooltip: 'Finalizar gravação GPS',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onShowTalhaoCard,
              backgroundColor: Colors.purple,
              mini: true,
              child: const Icon(Icons.info, color: Colors.white),
              tooltip: 'Mostrar informações do talhão',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onClearDrawing,
              backgroundColor: Colors.grey,
              mini: true,
              child: const Icon(Icons.clear, color: Colors.white),
              tooltip: 'Limpar desenho',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onImportFile,
              backgroundColor: Colors.indigo,
              mini: true,
              child: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'Importar arquivo',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onExportFile,
              backgroundColor: Colors.teal,
              mini: true,
              child: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Exportar arquivo',
            ),
            
            const SizedBox(height: 8),
            
            FloatingActionButton(
              onPressed: onShowHelp,
              backgroundColor: Colors.brown,
              mini: true,
              child: const Icon(Icons.help, color: Colors.white),
              tooltip: 'Ajuda',
            ),
          ],
        ],
      ),
    );
  }
}
