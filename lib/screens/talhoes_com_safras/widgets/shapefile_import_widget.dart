import 'package:flutter/material.dart';
import '../../../services/shapefile_integration_service.dart';
import '../../../models/talhao_model.dart';
import '../../../utils/logger.dart';

/// Widget para importação de talhões via Shapefile
class ShapefileImportWidget extends StatefulWidget {
  final Function(List<TalhaoModel>) onTalhoesImported;
  final List<TalhaoModel> existingTalhoes;

  const ShapefileImportWidget({
    Key? key,
    required this.onTalhoesImported,
    required this.existingTalhoes,
  }) : super(key: key);

  @override
  State<ShapefileImportWidget> createState() => _ShapefileImportWidgetState();
}

class _ShapefileImportWidgetState extends State<ShapefileImportWidget> {
  bool _isImporting = false;
  String? _importStatus;
  int _importedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.file_upload, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Importar Talhões via Shapefile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Importe talhões de arquivos .shp existentes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_importStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isImporting ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isImporting ? Colors.blue : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isImporting) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _importStatus!,
                        style: TextStyle(
                          color: _isImporting ? Colors.blue : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importShapefile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Selecionar Shapefile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isImporting ? null : _showHelp,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Ajuda'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  /// Importa Shapefile
  Future<void> _importShapefile() async {
    setState(() {
      _isImporting = true;
      _importStatus = 'Carregando Shapefile...';
    });

    try {
      Logger.info('ShapefileImportWidget: Iniciando importação...');
      
      // Importar talhões do Shapefile
      final importedTalhoes = await ShapefileIntegrationService.importTalhoesFromShapefile(
        context,
      );
      
      if (importedTalhoes.isNotEmpty) {
        // Verificar duplicatas
        final newTalhoes = _filterDuplicates(importedTalhoes);
        
        // Adicionar aos talhões existentes
        final allTalhoes = [...widget.existingTalhoes, ...newTalhoes];
        
        // Notificar callback
        widget.onTalhoesImported(allTalhoes);
        
        setState(() {
          _importedCount = newTalhoes.length;
          _importStatus = '${newTalhoes.length} talhões importados com sucesso!';
        });
        
        Logger.info('ShapefileImportWidget: ${newTalhoes.length} talhões importados');
        
        // Mostrar sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newTalhoes.length} talhões importados com sucesso!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navegar para lista de talhões
                },
              ),
            ),
          );
        }
      } else {
        setState(() {
          _importStatus = 'Nenhum talhão encontrado no Shapefile';
        });
      }
      
    } catch (e) {
      Logger.error('ShapefileImportWidget: Erro na importação: $e');
      
      setState(() {
        _importStatus = 'Erro na importação: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na importação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// Filtra talhões duplicados
  List<TalhaoModel> _filterDuplicates(List<TalhaoModel> importedTalhoes) {
    final existingIds = widget.existingTalhoes.map((t) => t.id).toSet();
    final existingNames = widget.existingTalhoes.map((t) => t.name.toLowerCase()).toSet();
    
    return importedTalhoes.where((talhao) {
      // Verificar por ID
      if (existingIds.contains(talhao.id)) {
        return false;
      }
      
      // Verificar por nome (case insensitive)
      if (existingNames.contains(talhao.name.toLowerCase())) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Mostra ajuda sobre importação
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Como importar Shapefiles'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Formato suportado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Arquivos .shp (Shapefile)'),
              Text('• Coordenadas geográficas (WGS84)'),
              Text('• Geometrias do tipo polígono'),
              
              SizedBox(height: 16),
              
              Text(
                'Atributos recomendados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• nome/NOME/name - Nome do talhão'),
              Text('• area/AREA/hectares - Área em hectares'),
              Text('• cultura/CULTURA/crop - Tipo de cultura'),
              Text('• safra/SAFRA/season - Safra/ano'),
              
              SizedBox(height: 16),
              
              Text(
                'Dicas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use nomes únicos para cada talhão'),
              Text('• Verifique se as coordenadas estão corretas'),
              Text('• Talhões duplicados serão ignorados'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Seção de informações
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações sobre importação:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Talhões existentes: ${widget.existingTalhoes.length}',
            style: const TextStyle(fontSize: 12),
          ),
          if (_importedCount > 0) ...[
            Text(
              '• Talhões importados: $_importedCount',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const Text(
            '• Formato: Shapefile (.shp)',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Coordenadas: WGS84 (lat/lng)',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
