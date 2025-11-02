import 'package:flutter/material.dart';
import '../services/shapefile_integration_service.dart';
import '../widgets/shapefile_data_viewer.dart';
import '../models/talhao_model.dart';

/// Exemplo de uso do sistema de leitura de Shapefiles
class ShapefileUsageExample extends StatefulWidget {
  const ShapefileUsageExample({Key? key}) : super(key: key);

  @override
  State<ShapefileUsageExample> createState() => _ShapefileUsageExampleState();
}

class _ShapefileUsageExampleState extends State<ShapefileUsageExample> {
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo - Shapefile Reader'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildUsageExamples(),
            const SizedBox(height: 24),
            _buildTalhoesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openShapefilePicker,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.file_upload, color: Colors.white),
        label: const Text('Abrir Shapefile', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Sistema de Leitura de Shapefiles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Este sistema permite ler e interpretar arquivos Shapefile (.shp) '
              'para diferentes tipos de dados agrícolas:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Talhões', Colors.green),
                _buildFeatureChip('Máquinas', Colors.blue),
                _buildFeatureChip('Plantio', Colors.orange),
                _buildFeatureChip('Colheita', Colors.red),
                _buildFeatureChip('Aplicações', Colors.purple),
                _buildFeatureChip('Solo', Colors.brown),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUsageExamples() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.code, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Exemplos de Uso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildExampleCard(
              '1. Importar Talhões',
              'Importe talhões de arquivos Shapefile existentes',
              Icons.agriculture,
              Colors.green,
              () => _importTalhoes(),
            ),
            
            const SizedBox(height: 12),
            
            _buildExampleCard(
              '2. Visualizar Dados',
              'Visualize e analise dados do Shapefile',
              Icons.visibility,
              Colors.blue,
              () => _openShapefilePicker(),
            ),
            
            const SizedBox(height: 12),
            
            _buildExampleCard(
              '3. Validar Arquivo',
              'Valide se o Shapefile é adequado para importação',
              Icons.verified,
              Colors.orange,
              () => _validateShapefile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTalhoesList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Talhões Importados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_talhoes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_talhoes.isEmpty) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.agriculture, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum talhão importado',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Use o botão "Abrir Shapefile" para importar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._talhoes.take(5).map((talhao) => _buildTalhaoItem(talhao)),
              if (_talhoes.length > 5) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '... e mais ${_talhoes.length - 5} talhões',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTalhaoItem(TalhaoModel talhao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.agriculture, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talhao.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${talhao.area.toStringAsFixed(2)} ha • ${talhao.poligonos.first.pontos.length} vértices',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Abre seletor de Shapefile
  Future<void> _openShapefilePicker() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ShapefileIntegrationService.showShapefilePicker(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Importa talhões de Shapefile
  Future<void> _importTalhoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final importedTalhoes = await ShapefileIntegrationService.importTalhoesFromShapefile(
        context,
      );

      setState(() {
        _talhoes = [..._talhoes, ...importedTalhoes];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${importedTalhoes.length} talhões importados!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
        _isLoading = false;
      });
    }
  }

  /// Valida Shapefile
  Future<void> _validateShapefile() async {
    // Exemplo de validação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de validação em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
