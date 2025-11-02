import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/talhao_model.dart';
import '../services/advanced_talhao_export_service.dart';

/// Widget avançado para exportação de talhões com seleção de fabricante
class AdvancedTalhaoExportWidget extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final String? titulo;

  const AdvancedTalhaoExportWidget({
    Key? key,
    required this.talhoes,
    this.titulo,
  }) : super(key: key);

  @override
  State<AdvancedTalhaoExportWidget> createState() => _AdvancedTalhaoExportWidgetState();
}

class _AdvancedTalhaoExportWidgetState extends State<AdvancedTalhaoExportWidget> {
  final AdvancedTalhaoExportService _exportService = AdvancedTalhaoExportService();
  bool _isExporting = false;
  String? _statusMessage;
  double _progress = 0.0;
  MonitorManufacturer _selectedManufacturer = MonitorManufacturer.generic;
  ISOXMLVersion _selectedISOXMLVersion = ISOXMLVersion.v4;

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
                  widget.titulo ?? 'Exportação Avançada para Máquinas Agrícolas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Exportar ${widget.talhoes.length} talhão(ões) para formato específico do fabricante:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Seletor de fabricante
            _buildManufacturerSelector(),
            const SizedBox(height: 16),
            
            // Seletor de versão ISOXML (se aplicável)
            if (_selectedManufacturer != MonitorManufacturer.agLeader &&
                _selectedManufacturer != MonitorManufacturer.topcon)
              _buildISOXMLVersionSelector(),
            
            if (_selectedManufacturer != MonitorManufacturer.agLeader &&
                _selectedManufacturer != MonitorManufacturer.topcon)
              const SizedBox(height: 16),
            
            // Botão de exportação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportForManufacturer,
                icon: Icon(_getManufacturerIcon(_selectedManufacturer), size: 20),
                label: Text('Exportar para ${_getManufacturerName(_selectedManufacturer)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getManufacturerColor(_selectedManufacturer),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
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
            
            // Informações sobre compatibilidade
            const SizedBox(height: 16),
            _buildCompatibilityInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildManufacturerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fabricante do Monitor:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MonitorManufacturer>(
          value: _selectedManufacturer,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: MonitorManufacturer.values.map((manufacturer) {
            return DropdownMenuItem(
              value: manufacturer,
              child: Row(
                children: [
                  Icon(
                    _getManufacturerIcon(manufacturer),
                    size: 20,
                    color: _getManufacturerColor(manufacturer),
                  ),
                  const SizedBox(width: 8),
                  Text(_getManufacturerName(manufacturer)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedManufacturer = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildISOXMLVersionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Versão ISOXML:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ISOXMLVersion>(
          value: _selectedISOXMLVersion,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ISOXMLVersion.values.map((version) {
            return DropdownMenuItem(
              value: version,
              child: Text(_getISOXMLVersionName(version)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedISOXMLVersion = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompatibilityInfo() {
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
            'Compatibilidade:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCompatibilityItem(
            _getManufacturerName(_selectedManufacturer),
            _getManufacturerDescription(_selectedManufacturer),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityItem(String manufacturer, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _getManufacturerIcon(_selectedManufacturer),
          size: 16,
          color: _getManufacturerColor(_selectedManufacturer),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manufacturer,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportForManufacturer() async {
    final exportDir = await _getExportDirectory();
    await _exportWithProgress(
      'Exportando para ${_getManufacturerName(_selectedManufacturer)}...',
      () => _exportService.exportForManufacturer(
        widget.talhoes,
        _selectedManufacturer,
        exportDir,
        nomeArquivo: '${_getManufacturerName(_selectedManufacturer).toLowerCase().replaceAll(' ', '_')}_export_${DateTime.now().millisecondsSinceEpoch}',
        isoxmlVersion: _selectedISOXMLVersion,
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
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory != null) {
        return directory;
      }
    } catch (e) {
      // Ignorar erro e usar diretório temporário
    }
    
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
        text: 'Talhões exportados do FortSmart Agro para ${_getManufacturerName(_selectedManufacturer)}',
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

  String _getManufacturerName(MonitorManufacturer manufacturer) {
    switch (manufacturer) {
      case MonitorManufacturer.johnDeere:
        return 'John Deere';
      case MonitorManufacturer.trimble:
        return 'Trimble';
      case MonitorManufacturer.agLeader:
        return 'AG Leader';
      case MonitorManufacturer.topcon:
        return 'Topcon';
      case MonitorManufacturer.stara:
        return 'Stara';
      case MonitorManufacturer.horsch:
        return 'Horsch';
      case MonitorManufacturer.caseIH:
        return 'Case IH';
      case MonitorManufacturer.amazone:
        return 'Amazone';
      case MonitorManufacturer.generic:
        return 'Genérico (Shapefile + ISOXML)';
    }
  }

  String _getManufacturerDescription(MonitorManufacturer manufacturer) {
    switch (manufacturer) {
      case MonitorManufacturer.johnDeere:
        return 'Gen4/Gen5: ISOXML v4 com GUIDs obrigatórios + Shapefile';
      case MonitorManufacturer.trimble:
        return 'GFX/TMX: ISOXML v3/v4 + Shapefile UTM';
      case MonitorManufacturer.agLeader:
        return 'SMS Software/InCommand: Shapefile com EPSG específico';
      case MonitorManufacturer.topcon:
        return 'FC-500/X30: Shapefile UTM otimizado';
      case MonitorManufacturer.stara:
        return 'ISOBUS: ISOXML v4 com metadados completos';
      case MonitorManufacturer.horsch:
        return 'ISOBUS: ISOXML v4 com metadados completos';
      case MonitorManufacturer.caseIH:
        return 'ISOBUS: ISOXML v4 com metadados completos';
      case MonitorManufacturer.amazone:
        return 'ISOBUS: ISOXML v4 com metadados completos';
      case MonitorManufacturer.generic:
        return 'Compatível com todos: Shapefile + ISOXML v4';
    }
  }

  IconData _getManufacturerIcon(MonitorManufacturer manufacturer) {
    switch (manufacturer) {
      case MonitorManufacturer.johnDeere:
        return Icons.agriculture;
      case MonitorManufacturer.trimble:
        return Icons.gps_fixed;
      case MonitorManufacturer.agLeader:
        return Icons.settings;
      case MonitorManufacturer.topcon:
        return Icons.precision_manufacturing;
      case MonitorManufacturer.stara:
        return Icons.agriculture;
      case MonitorManufacturer.horsch:
        return Icons.agriculture;
      case MonitorManufacturer.caseIH:
        return Icons.agriculture;
      case MonitorManufacturer.amazone:
        return Icons.agriculture;
      case MonitorManufacturer.generic:
        return Icons.file_download;
    }
  }

  Color _getManufacturerColor(MonitorManufacturer manufacturer) {
    switch (manufacturer) {
      case MonitorManufacturer.johnDeere:
        return Colors.green;
      case MonitorManufacturer.trimble:
        return Colors.blue;
      case MonitorManufacturer.agLeader:
        return Colors.orange;
      case MonitorManufacturer.topcon:
        return Colors.purple;
      case MonitorManufacturer.stara:
        return Colors.red;
      case MonitorManufacturer.horsch:
        return Colors.teal;
      case MonitorManufacturer.caseIH:
        return Colors.indigo;
      case MonitorManufacturer.amazone:
        return Colors.brown;
      case MonitorManufacturer.generic:
        return Colors.grey;
    }
  }

  String _getISOXMLVersionName(ISOXMLVersion version) {
    switch (version) {
      case ISOXMLVersion.v3:
        return 'ISOXML v3.0 (Compatibilidade)';
      case ISOXMLVersion.v4:
        return 'ISOXML v4.3 (Recomendado)';
      case ISOXMLVersion.v5:
        return 'ISOXML v5.0 (Futuro)';
    }
  }
}

/// Widget compacto para exportação rápida com fabricante
class AdvancedTalhaoExportCompactWidget extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final VoidCallback? onExportComplete;

  const AdvancedTalhaoExportCompactWidget({
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
          icon: const Icon(Icons.agriculture),
          tooltip: 'Exportar para máquinas agrícolas',
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
        title: const Text('Exportação Avançada'),
        content: SizedBox(
          width: double.maxFinite,
          child: AdvancedTalhaoExportWidget(talhoes: talhoes),
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
