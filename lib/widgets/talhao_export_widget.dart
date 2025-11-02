import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/talhao_model.dart';
import '../services/talhao_export_service.dart';

/// Widget para exportação de talhões para máquinas agrícolas
class TalhaoExportWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final String? titulo;

  const TalhaoExportWidget({
    Key? key,
    required this.talhoes,
    this.titulo,
  }) : super(key: key);

  @override
  State<TalhaoExportWidget> createState() => _TalhaoExportWidgetState();
}

class _TalhaoExportWidgetState extends State<TalhaoExportWidget> {
  final TalhaoExportService _exportService = TalhaoExportService();
  bool _isExporting = false;
  String? _statusMessage;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.titulo ?? 'Exportação para Máquinas Agrícolas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Exportar ${widget.talhoes.length} talhão(ões) para formatos compatíveis com máquinas agrícolas:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Botões de exportação
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'Shapefile',
                    Icons.map,
                    Colors.blue,
                    _exportToShapefile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'ISOXML',
                    Icons.settings,
                    Colors.green,
                    _exportToISOXML,
                  ),
                ),
              ],
            ),
            
            // Status e progresso
            if (_isExporting || _statusMessage != null) ...[
              const SizedBox(height: 16),
              if (_isExporting) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
              ],
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isExporting ? Colors.blue : Colors.green,
                  ),
                ),
            ],
            
            // Informações sobre formatos
            const SizedBox(height: 16),
            _buildFormatInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildFormatInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formatos Suportados:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFormatItem(
            'Shapefile',
            'Compatível com QGIS, ArcGIS, John Deere, Stara, Trimble',
          ),
          _buildFormatItem(
            'ISOXML',
            'Padrão ISO 11783-10 para monitores agrícolas (AGLeader, Topcon)',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(String format, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $format: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToShapefile() async {
    await _exportWithProgress(
      'Exportando para Shapefile...',
      () async => await _exportService.exportToShapefile(
        widget.talhoes,
        await _getExportDirectory(),
        nomeArquivo: 'talhoes_shapefile_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  Future<void> _exportToISOXML() async {
    await _exportWithProgress(
      'Exportando para ISOXML...',
      () async => await _exportService.exportToISOXML(
        widget.talhoes,
        await _getExportDirectory(),
        nomeArquivo: 'taskdata_isoxml_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  Future<void> _exportWithProgress(
    String statusMessage,
    Future<File> Function() exportFunction,
  ) async {
    setState(() {
      _isExporting = true;
      _statusMessage = statusMessage;
      _progress = 0.0;
    });

    try {
      // Simular progresso
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _progress = (i + 1) / 5;
        });
      }

      final file = await exportFunction();
      
      setState(() {
        _statusMessage = 'Exportação concluída! Arquivo salvo em: ${file.path}';
        _progress = 1.0;
      });

      // Compartilhar arquivo
      await _shareFile(file);
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na exportação: $e';
        _progress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na exportação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<String> _getExportDirectory() async {
    // Tentar obter diretório de downloads
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory != null) {
        return directory;
      }
    } catch (e) {
      // Ignorar erro e usar diretório temporário
    }
    
    // Fallback para diretório temporário
    final tempDir = Directory.systemTemp;
    final exportDir = Directory('${tempDir.path}/fortsmart_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Talhões exportados do FortSmart Agro',
        subject: 'Exportação de Talhões - ${file.path.split('/').last}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo salvo em: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}

/// Widget compacto para exportação rápida
class TalhaoExportCompactWidget extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final VoidCallback? onExportComplete;

  const TalhaoExportCompactWidget({
    Key? key,
    required this.talhoes,
    this.onExportComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showExportDialog(context),
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar talhões',
        ),
        if (talhoes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${talhoes.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Talhões'),
        content: SizedBox(
          width: double.maxFinite,
          child: TalhaoExportWidget(talhoes: talhoes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
