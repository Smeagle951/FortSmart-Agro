import 'package:flutter/material.dart';

/// Widget responsável pela barra de navegação inferior do monitoramento
class MonitoringBottomBar extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final bool canSave;
  final bool isSaving;
  final VoidCallback? onPrevious;
  final VoidCallback? onSaveAndNext;
  final VoidCallback? onSaveOnly;

  const MonitoringBottomBar({
    Key? key,
    this.canGoPrevious = true,
    this.canGoNext = true,
    this.canSave = true,
    this.isSaving = false,
    this.onPrevious,
    this.onSaveAndNext,
    this.onSaveOnly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão Anterior
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoPrevious ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16.0),
            
            // Botão Salvar e Avançar
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (canSave && !isSaving) ? onSaveAndNext : null,
                icon: isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(isSaving ? 'Salvando...' : 'Salvar e Avançar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para barra de ações flutuante
class MonitoringFloatingActions extends StatelessWidget {
  final bool hasOccurrences;
  final bool hasImages;
  final VoidCallback? onAddOccurrence;
  final VoidCallback? onCaptureImage;
  final VoidCallback? onPickImage;
  final VoidCallback? onSaveAll;

  const MonitoringFloatingActions({
    Key? key,
    this.hasOccurrences = false,
    this.hasImages = false,
    this.onAddOccurrence,
    this.onCaptureImage,
    this.onPickImage,
    this.onSaveAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão de salvar todas as ocorrências
        if (hasOccurrences && onSaveAll != null)
          FloatingActionButton.small(
            onPressed: onSaveAll,
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            heroTag: 'save_all',
            child: const Icon(Icons.save),
          ),
        
        const SizedBox(height: 8.0),
        
        // Botão de capturar imagem
        if (onCaptureImage != null)
          FloatingActionButton.small(
            onPressed: onCaptureImage,
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            heroTag: 'capture_image',
            child: const Icon(Icons.camera_alt),
          ),
        
        const SizedBox(height: 8.0),
        
        // Botão de selecionar imagem da galeria
        if (onPickImage != null)
          FloatingActionButton.small(
            onPressed: onPickImage,
            backgroundColor: Colors.purple.shade600,
            foregroundColor: Colors.white,
            heroTag: 'pick_image',
            child: const Icon(Icons.photo_library),
          ),
        
        const SizedBox(height: 8.0),
        
        // Botão principal de adicionar ocorrência
        if (onAddOccurrence != null)
          FloatingActionButton(
            onPressed: onAddOccurrence,
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            heroTag: 'add_occurrence',
            child: const Icon(Icons.add),
          ),
      ],
    );
  }
}
