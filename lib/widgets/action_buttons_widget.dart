import 'package:flutter/material.dart';

/// Widget com botões de ação para o talhão
class ActionButtonsWidget extends StatelessWidget {
  final bool showActionButtons;
  final bool isGpsTracking;
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

  const ActionButtonsWidget({
    Key? key,
    required this.showActionButtons,
    required this.isGpsTracking,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão principal (desenho manual)
          FloatingActionButton(
            onPressed: onStartDrawing,
            heroTag: "drawing",
            child: const Icon(Icons.edit),
          ),
          
          const SizedBox(height: 8),
          
          // Botão GPS
          FloatingActionButton(
            onPressed: isGpsTracking ? onFinishGps : onStartGps,
            heroTag: "gps",
            backgroundColor: isGpsTracking ? Colors.red : Colors.green,
            child: Icon(isGpsTracking ? Icons.stop : Icons.gps_fixed),
          ),
          
          if (isGpsTracking) ...[
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: onPauseGps,
              heroTag: "pause",
              backgroundColor: Colors.orange,
              child: const Icon(Icons.pause),
            ),
          ],
          
          if (showActionButtons) ...[
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: onSaveTalhao,
              heroTag: "save",
              backgroundColor: Colors.blue,
              child: const Icon(Icons.save),
            ),
            
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: onClearDrawing,
              heroTag: "clear",
              backgroundColor: Colors.grey,
              child: const Icon(Icons.clear),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Menu de opções
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'import':
                  onImportPolygons();
                  break;
                case 'export':
                  onExportPolygons();
                  break;
                case 'help':
                  onShowHelp();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Importar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exportar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Ajuda'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
