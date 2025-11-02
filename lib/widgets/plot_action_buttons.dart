import 'package:flutter/material.dart';

class PlotActionButtons extends StatelessWidget {
  final Function() onManualDrawingSelected;
  final Function() onGpsTrackingSelected;
  final Function() onEraseSelected;
  final Function() onImportKmlSelected;
  final Function() onSaveSelected;
  final Function() onCancelSelected;
  final bool isDrawingMode;
  final bool isGpsTrackingMode;
  final bool isEraseMode;
  final bool hasDrawingPoints;

  const PlotActionButtons({
    Key? key,
    required this.onManualDrawingSelected,
    required this.onGpsTrackingSelected,
    required this.onEraseSelected,
    required this.onImportKmlSelected,
    required this.onSaveSelected,
    required this.onCancelSelected,
    required this.isDrawingMode,
    required this.isGpsTrackingMode,
    required this.isEraseMode,
    required this.hasDrawingPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se estiver em modo de desenho ou edição, mostrar botões de salvar e cancelar
    if (isDrawingMode || isGpsTrackingMode || isEraseMode) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Exibir área calculada
              if (hasDrawingPoints)
                Expanded(
                  flex: 2,
                  child: Text(
                    'Área: ${(hasDrawingPoints ? (isDrawingMode ? "Desenho Manual" : "GPS") : "")}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              
              // Botão de cancelar
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: onCancelSelected,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botão de salvar
              if (hasDrawingPoints)
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: onSaveSelected,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Caso contrário, mostrar botão principal com menu expansível
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botão de importar KML/KMZ
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.extended(
              onPressed: onImportKmlSelected,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar KML/KMZ'),
              // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
              heroTag: 'import_button',
            ),
          ),
          
          // Botão de desenho manual
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.extended(
              onPressed: onManualDrawingSelected,
              icon: const Icon(Icons.edit),
              label: const Text('Desenhar Manualmente'),
              // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
              heroTag: 'manual_draw_button',
            ),
          ),
          
          // Botão de rastreamento GPS
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.extended(
              onPressed: onGpsTrackingSelected,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Desenhar com GPS'),
              // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
              heroTag: 'gps_button',
            ),
          ),
          
          // Botão de edição/borracha
          FloatingActionButton.extended(
            onPressed: onEraseSelected,
            icon: const Icon(Icons.edit_attributes),
            label: const Text('Editar Pontos'),
            // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
            heroTag: 'erase_button',
          ),
        ],
      ),
    );
  }
}
