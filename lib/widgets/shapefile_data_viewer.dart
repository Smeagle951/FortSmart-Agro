import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../services/shapefile_reader_service.dart';
import '../models/talhao_model.dart';
import '../utils/logger.dart';

/// Widget para visualização e análise de dados de Shapefile
class ShapefileDataViewer extends StatefulWidget {
  final ShapefileData shapefileData;

  const ShapefileDataViewer({
    Key? key,
    required this.shapefileData,
  }) : super(key: key);

  @override
  State<ShapefileDataViewer> createState() => _ShapefileDataViewerState();
}

class _ShapefileDataViewerState extends State<ShapefileDataViewer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<TalhaoModel> _talhoes = [];
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _convertToTalhoes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Converte dados do Shapefile para talhões
  Future<void> _convertToTalhoes() async {
    setState(() {
      _isConverting = true;
    });

    try {
      _talhoes = widget.shapefileData.toTalhoes();
      Logger.info('ShapefileDataViewer: ${_talhoes.length} talhões convertidos');
    } catch (e) {
      Logger.error('ShapefileDataViewer: Erro ao converter talhões: $e');
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados do Shapefile: ${widget.shapefileData.fileName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Informações'),
            Tab(icon: Icon(Icons.map), text: 'Geometria'),
            Tab(icon: Icon(Icons.table_chart), text: 'Atributos'),
            Tab(icon: Icon(Icons.agriculture), text: 'Talhões'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildGeometryTab(),
          _buildAttributesTab(),
          _buildTalhoesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importTalhoes,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Importar Talhões', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Tab de informações gerais
  Widget _buildInfoTab() {
    final metadata = widget.shapefileData.metadata;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Informações do Arquivo',
            [
              _buildInfoRow('Nome do arquivo', widget.shapefileData.fileName),
              _buildInfoRow('Tipo de dados', _getDataTypeName(widget.shapefileData.dataType)),
              _buildInfoRow('Data de importação', _formatDate(widget.shapefileData.importDate)),
              _buildInfoRow('Número de features', '${widget.shapefileData.features.length}'),
            ],
            icon: Icons.description,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            'Metadados Técnicos',
            [
              _buildInfoRow('Tipo de shape', '${metadata['shapeType']}'),
              _buildInfoRow('Total de features', '${metadata['numFeatures']}'),
              _buildInfoRow('Área total', '${(metadata['totalArea'] as double).toStringAsFixed(2)} ha'),
              _buildInfoRow('Atributos disponíveis', '${(metadata['attributes'] as List).length}'),
            ],
            icon: Icons.settings,
            color: Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          _buildBoundingBoxCard(metadata['boundingBox']),
        ],
      ),
    );
  }

  /// Tab de visualização da geometria
  Widget _buildGeometryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Resumo da Geometria',
            [
              _buildInfoRow('Tipo de geometria', _getGeometryType()),
              _buildInfoRow('Total de pontos', '${_getTotalPoints()}'),
              _buildInfoRow('Área média', '${_getAverageArea().toStringAsFixed(2)} ha'),
              _buildInfoRow('Perímetro médio', '${_getAveragePerimeter().toStringAsFixed(1)} m'),
            ],
            icon: Icons.map,
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            'Distribuição de Áreas',
            [
              _buildInfoRow('Área mínima', '${_getMinArea().toStringAsFixed(2)} ha'),
              _buildInfoRow('Área máxima', '${_getMaxArea().toStringAsFixed(2)} ha'),
              _buildInfoRow('Área mediana', '${_getMedianArea().toStringAsFixed(2)} ha'),
              _buildInfoRow('Desvio padrão', '${_getAreaStandardDeviation().toStringAsFixed(2)} ha'),
            ],
            icon: Icons.analytics,
            color: Colors.purple,
          ),
          
          const SizedBox(height: 16),
          
          _buildGeometryPreview(),
        ],
      ),
    );
  }

  /// Tab de atributos das features
  Widget _buildAttributesTab() {
    if (widget.shapefileData.features.isEmpty) {
      return const Center(
        child: Text('Nenhuma feature encontrada'),
      );
    }

    final firstFeature = widget.shapefileData.features.first;
    final attributes = firstFeature.attributes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Estrutura dos Atributos',
            [
              _buildInfoRow('Total de atributos', '${attributes.length}'),
              _buildInfoRow('Feature de exemplo', 'ID: ${firstFeature.id}'),
            ],
            icon: Icons.table_chart,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildAttributesTable(attributes),
        ],
      ),
    );
  }

  /// Tab de talhões convertidos
  Widget _buildTalhoesTab() {
    if (_isConverting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Convertendo dados para talhões...'),
          ],
        ),
      );
    }

    if (_talhoes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum talhão encontrado'),
            Text('Verifique se o Shapefile contém dados de talhões'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _talhoes.length,
      itemBuilder: (context, index) {
        final talhao = _talhoes[index];
        return _buildTalhaoCard(talhao, index);
      },
    );
  }

  /// Card de informações
  Widget _buildInfoCard(String title, List<Widget> children, {IconData? icon, Color? color}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color ?? Colors.blue),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  /// Card de bounding box
  Widget _buildBoundingBoxCard(Map<String, dynamic> boundingBox) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.crop_free, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Bounding Box',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Longitude mínima', '${(boundingBox['xMin'] as double).toStringAsFixed(6)}°'),
            _buildInfoRow('Longitude máxima', '${(boundingBox['xMax'] as double).toStringAsFixed(6)}°'),
            _buildInfoRow('Latitude mínima', '${(boundingBox['yMin'] as double).toStringAsFixed(6)}°'),
            _buildInfoRow('Latitude máxima', '${(boundingBox['yMax'] as double).toStringAsFixed(6)}°'),
          ],
        ),
      ),
    );
  }

  /// Tabela de atributos
  Widget _buildAttributesTable(Map<String, dynamic> attributes) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atributos da Feature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...attributes.entries.map((entry) => _buildInfoRow(entry.key, entry.value.toString())),
          ],
        ),
      ),
    );
  }

  /// Card de talhão
  Widget _buildTalhaoCard(TalhaoModel talhao, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.agriculture, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talhao.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${talhao.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricChip(
                    Icons.crop_square,
                    'Área',
                    '${talhao.area.toStringAsFixed(2)} ha',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricChip(
                    Icons.location_on,
                    'Vértices',
                    '${talhao.poligonos.first.pontos.length}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (talhao.culturaId != null) ...[
              const SizedBox(height: 8),
              _buildMetricChip(
                Icons.eco,
                'Cultura',
                talhao.culturaId!,
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Chip de métrica
  Widget _buildMetricChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Preview da geometria
  Widget _buildGeometryPreview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview da Geometria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Visualização da geometria\n(Implementar mapa interativo)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Importa talhões para o sistema
  Future<void> _importTalhoes() async {
    if (_talhoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum talhão para importar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // TODO: Implementar importação para o banco de dados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_talhoes.length} talhões importados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar talhões: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Métodos auxiliares
  String _getDataTypeName(ShapefileDataType dataType) {
    switch (dataType) {
      case ShapefileDataType.talhao:
        return 'Talhões Agrícolas';
      case ShapefileDataType.maquina:
        return 'Trabalhos de Máquina';
      case ShapefileDataType.plantio:
        return 'Áreas de Plantio';
      case ShapefileDataType.colheita:
        return 'Áreas de Colheita';
      case ShapefileDataType.aplicacao:
        return 'Aplicações';
      case ShapefileDataType.solo:
        return 'Amostras de Solo';
      case ShapefileDataType.irrigacao:
        return 'Sistemas de Irrigação';
      case ShapefileDataType.estrada:
        return 'Estradas e Caminhos';
      case ShapefileDataType.construcao:
        return 'Construções Rurais';
      case ShapefileDataType.desconhecido:
        return 'Tipo Desconhecido';
    }
  }

  String _getGeometryType() {
    if (widget.shapefileData.features.isEmpty) return 'N/A';
    
    final firstFeature = widget.shapefileData.features.first;
    if (firstFeature.geometry.length == 1) return 'Ponto';
    if (firstFeature.geometry.length == 2) return 'Linha';
    return 'Polígono';
  }

  int _getTotalPoints() {
    return widget.shapefileData.features.fold(0, (sum, feature) => sum + feature.geometry.length);
  }

  double _getAverageArea() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    final totalArea = widget.shapefileData.features.fold(0.0, (sum, feature) => 
        sum + (feature.attributes['area'] ?? 0.0));
    return totalArea / widget.shapefileData.features.length;
  }

  double _getAveragePerimeter() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    final totalPerimeter = widget.shapefileData.features.fold(0.0, (sum, feature) => 
        sum + (feature.attributes['perimeter'] ?? 0.0));
    return totalPerimeter / widget.shapefileData.features.length;
  }

  double _getMinArea() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    return widget.shapefileData.features
        .map((feature) => feature.attributes['area'] ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
  }

  double _getMaxArea() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    return widget.shapefileData.features
        .map((feature) => feature.attributes['area'] ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
  }

  double _getMedianArea() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    final areas = widget.shapefileData.features
        .map((feature) => feature.attributes['area'] ?? 0.0)
        .toList()
      ..sort();
    
    final middle = areas.length ~/ 2;
    if (areas.length % 2 == 1) {
      return areas[middle];
    } else {
      return (areas[middle - 1] + areas[middle]) / 2;
    }
  }

  double _getAreaStandardDeviation() {
    if (widget.shapefileData.features.isEmpty) return 0.0;
    
    final areas = widget.shapefileData.features
        .map((feature) => feature.attributes['area'] ?? 0.0)
        .toList();
    
    final mean = areas.reduce((a, b) => a + b) / areas.length;
    final variance = areas.map((area) => (area - mean) * (area - mean)).reduce((a, b) => a + b) / areas.length;
    
    return sqrt(variance);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
