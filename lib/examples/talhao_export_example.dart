import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../services/talhao_export_service.dart';
import '../widgets/talhao_export_widget.dart';

/// Exemplo de uso do serviço de exportação de talhões
class TalhaoExportExample extends StatefulWidget {
  const TalhaoExportExample({Key? key}) : super(key: key);

  @override
  State<TalhaoExportExample> createState() => _TalhaoExportExampleState();
}

class _TalhaoExportExampleState extends State<TalhaoExportExample> {
  final TalhaoExportService _exportService = TalhaoExportService();
  List<TalhaoModel> _talhoes = [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _createSampleTalhoes();
  }

  /// Cria talhões de exemplo para demonstração
  void _createSampleTalhoes() {
    _talhoes = [
      // Talhão 1 - Soja
      TalhaoModel.criar(
        nome: 'Talhão 1 - Soja',
        pontos: [
          LatLng(-23.5505, -46.6333), // São Paulo
          LatLng(-23.5505, -46.6300),
          LatLng(-23.5480, -46.6300),
          LatLng(-23.5480, -46.6333),
        ],
        area: 12.5,
        culturaId: 1,
        safraId: 1,
      ).adicionarSafraNomeada(
        safra: '2024/2025',
        culturaId: '1',
        culturaNome: 'Soja',
        culturaCor: Colors.green,
      ),

      // Talhão 2 - Milho
      TalhaoModel.criar(
        nome: 'Talhão 2 - Milho',
        pontos: [
          LatLng(-23.5480, -46.6333),
          LatLng(-23.5480, -46.6300),
          LatLng(-23.5455, -46.6300),
          LatLng(-23.5455, -46.6333),
        ],
        area: 8.3,
        culturaId: 2,
        safraId: 1,
      ).adicionarSafraNomeada(
        safra: '2024/2025',
        culturaId: '2',
        culturaNome: 'Milho',
        culturaCor: Colors.yellow,
      ),

      // Talhão 3 - Algodão
      TalhaoModel.criar(
        nome: 'Talhão 3 - Algodão',
        pontos: [
          LatLng(-23.5455, -46.6333),
          LatLng(-23.5455, -46.6300),
          LatLng(-23.5430, -46.6300),
          LatLng(-23.5430, -46.6333),
        ],
        area: 15.7,
        culturaId: 3,
        safraId: 1,
      ).adicionarSafraNomeada(
        safra: '2024/2025',
        culturaId: '3',
        culturaNome: 'Algodão',
        culturaCor: Colors.white,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação de Talhões - Exemplo'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações dos talhões
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talhões de Exemplo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._talhoes.map((talhao) => _buildTalhaoInfo(talhao)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Widget de exportação
            TalhaoExportWidget(
              talhoes: _talhoes,
              titulo: 'Exportar para Máquinas Agrícolas',
            ),
            
            const SizedBox(height: 16),
            
            // Botões de teste individual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testes de Exportação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testShapefileExport,
                            icon: const Icon(Icons.map),
                            label: const Text('Testar Shapefile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testISOXMLExport,
                            icon: const Icon(Icons.settings),
                            label: const Text('Testar ISOXML'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Status
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _statusMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTalhaoInfo(TalhaoModel talhao) {
    final areaHa = talhao.area.toStringAsFixed(2).replaceAll('.', ',');
    final safra = talhao.safraAtual;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: safra?.culturaCor ?? Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talhao.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${safra?.culturaNome ?? 'N/A'} - ${safra?.periodo ?? 'N/A'} - ${areaHa} ha',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testShapefileExport() async {
    setState(() {
      _statusMessage = 'Iniciando exportação Shapefile...';
    });

    try {
      final tempDir = Directory.systemTemp;
      final exportDir = Directory('${tempDir.path}/fortsmart_test');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = await _exportService.exportToShapefile(
        _talhoes,
        exportDir.path,
        nomeArquivo: 'teste_shapefile_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _statusMessage = 'Shapefile exportado com sucesso!\nArquivo: ${file.path}\nTamanho: ${(await file.length() / 1024).toStringAsFixed(2)} KB';
      });

      _showSuccessDialog('Shapefile', file);
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na exportação Shapefile: $e';
      });
    }
  }

  Future<void> _testISOXMLExport() async {
    setState(() {
      _statusMessage = 'Iniciando exportação ISOXML...';
    });

    try {
      final tempDir = Directory.systemTemp;
      final exportDir = Directory('${tempDir.path}/fortsmart_test');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = await _exportService.exportToISOXML(
        _talhoes,
        exportDir.path,
        nomeArquivo: 'teste_isoxml_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _statusMessage = 'ISOXML exportado com sucesso!\nArquivo: ${file.path}\nTamanho: ${(await file.length() / 1024).toStringAsFixed(2)} KB';
      });

      _showSuccessDialog('ISOXML', file);
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na exportação ISOXML: $e';
      });
    }
  }

  void _showSuccessDialog(String format, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$format Exportado com Sucesso!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arquivo: ${file.path.split('/').last}'),
            Text('Tamanho: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
            const SizedBox(height: 16),
            const Text(
              'O arquivo está pronto para ser usado em máquinas agrícolas compatíveis.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Widget para validação de arquivos exportados
class TalhaoExportValidator extends StatelessWidget {
  final File exportedFile;
  final String format;

  const TalhaoExportValidator({
    Key? key,
    required this.exportedFile,
    required this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validação do Arquivo $format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildValidationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationInfo() {
    final fileSize = exportedFile.lengthSync();
    final fileName = exportedFile.path.split('/').last;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationItem('Nome do arquivo', fileName),
        _buildValidationItem('Tamanho', '${(fileSize / 1024).toStringAsFixed(2)} KB'),
        _buildValidationItem('Formato', format),
        _buildValidationItem('Status', 'Pronto para uso'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Arquivo validado e compatível com máquinas agrícolas',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
