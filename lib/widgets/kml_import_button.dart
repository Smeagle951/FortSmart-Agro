import 'package:flutter/material.dart';
import 'package:fortsmart_agro/services/unified_geo_import_service.dart';
import 'package:fortsmart_agro/utils/area_calculator.dart';
import 'package:fortsmart_agro/widgets/error_dialog.dart';
import 'package:fortsmart_agro/utils/logger.dart';

/// Widget para importação de arquivos KML
class KmlImportButton extends StatelessWidget {
  final Function(List<dynamic>) onImportSuccess;
  final String? buttonText;
  final IconData? icon;

  const KmlImportButton({
    Key? key,
    required this.onImportSuccess,
    this.buttonText,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _importKml(context),
      icon: Icon(icon ?? Icons.file_upload),
      label: Text(buttonText ?? 'Importar KML'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  /// Importa um arquivo KML
  Future<void> _importKml(BuildContext context) async {
    try {
      final importService = UnifiedGeoImportService();
      
      // Selecionar arquivo
      final file = await importService.pickFile();
      if (file == null) return;
      
      // Importar arquivo
      final result = await importService.importFile(file);
      
      if (!result.success) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Erro na Importação',
            message: 'Erro ao importar arquivo: ${result.error}',
          );
        }
        return;
      }
      
      if (result.polygons.isEmpty) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Nenhum Polígono Encontrado',
            message: 'O arquivo não contém polígonos válidos.',
          );
        }
        return;
      }
      
      // Usar o primeiro polígono encontrado
      final polygon = result.polygons.first;
      final coordinates = polygon.map((point) => [point.longitude, point.latitude]).toList();
      
      // Calcular área
      final area = importService.calculateArea(polygon);
      
      // Mostrar informações sobre o polígono importado
      if (context.mounted) {
        final bool proceed = await _showImportConfirmation(
          context,
          coordinates.length,
          area,
          result.properties,
        );
        
        if (proceed) {
          // Passar dados completos incluindo metadados
          onImportSuccess([
            coordinates,
            {
              'area': area,
              'metadata': result.properties,
              'source': result.sourceFormat,
            }
          ]);
        }
      }
    } catch (e) {
      Logger.error('Erro na importação: $e');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro na Importação',
          message: 'Ocorreu um erro ao importar o arquivo: $e',
        );
      }
    }
  }
  
  /// Mostra um diálogo de confirmação após a importação
  Future<bool> _showImportConfirmation(
    BuildContext context,
    int pointCount,
    double area,
    Map<String, dynamic>? metadata,
  ) async {
    final areaSource = metadata?['originalArea'] != null ? 'original do KML' : 'calculada';
    final areaValue = area.toStringAsFixed(2);
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Importação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Polígono importado com sucesso!'),
              const SizedBox(height: 8),
              Text('• Pontos: $pointCount'),
              Text('• Área: $areaValue ha ($areaSource)'),
              if (metadata?['name'] != null)
                Text('• Nome: ${metadata!['name']}'),
              if (metadata?['description'] != null && metadata!['description'].isNotEmpty)
                Text('• Descrição: ${metadata!['description']}'),
              const SizedBox(height: 8),
              Text('Deseja continuar com a importação?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
