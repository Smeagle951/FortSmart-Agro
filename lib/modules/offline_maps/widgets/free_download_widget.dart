import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/offline_map_model.dart';
import '../services/offline_map_service.dart';
import '../utils/tile_calculator.dart';

/// Widget para download livre de mapas offline
class FreeDownloadWidget extends StatefulWidget {
  const FreeDownloadWidget({super.key});

  @override
  State<FreeDownloadWidget> createState() => _FreeDownloadWidgetState();
}

class _FreeDownloadWidgetState extends State<FreeDownloadWidget> {
  final OfflineMapService _offlineMapService = OfflineMapService();
  final TextEditingController _nameController = TextEditingController();
  final List<LatLng> _polygonPoints = [];
  String _selectedMapType = 'satellite';
  String _selectedZoomLevel = '13-18';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Download Livre de Mapas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Baixe mapas offline para qualquer área do mundo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Formulário de configuração
          _buildConfigurationForm(),
          
          const SizedBox(height: 24),
          
          // Área de desenho
          _buildDrawingArea(),
          
          const SizedBox(height: 24),
          
          // Botões de ação
          _buildActionButtons(),
          
          if (_isDownloading) ...[
            const SizedBox(height: 24),
            _buildDownloadProgress(),
          ],
        ],
      ),
    );
  }

  /// Formulário de configuração
  Widget _buildConfigurationForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nome do mapa
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Mapa',
                hintText: 'Ex: Mapa da Fazenda São José',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.map),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tipo de mapa
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de Mapa'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMapType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'satellite',
                            child: Text('Satélite'),
                          ),
                          DropdownMenuItem(
                            value: 'streets',
                            child: Text('Ruas'),
                          ),
                          DropdownMenuItem(
                            value: 'outdoors',
                            child: Text('Outdoors'),
                          ),
                          DropdownMenuItem(
                            value: 'hybrid',
                            child: Text('Híbrido'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMapType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nível de Zoom'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedZoomLevel,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '12-16',
                            child: Text('Econômico (12-16)'),
                          ),
                          DropdownMenuItem(
                            value: '13-18',
                            child: Text('Padrão (13-18)'),
                          ),
                          DropdownMenuItem(
                            value: '15-20',
                            child: Text('Alta Qualidade (15-20)'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedZoomLevel = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Área de desenho
  Widget _buildDrawingArea() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Área do Mapa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_polygonPoints.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearPolygon,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Área de desenho
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: _polygonPoints.isEmpty
                  ? _buildEmptyDrawingArea()
                  : _buildPolygonPreview(),
            ),
            
            const SizedBox(height: 16),
            
            // Botões de desenho
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startManualDrawing,
                    icon: const Icon(Icons.edit),
                    label: const Text('Desenho Manual'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startWalkingDrawing,
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Por Caminhada'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_polygonPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPolygonInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// Área de desenho vazia
  Widget _buildEmptyDrawingArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Desenhe a área do mapa',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use desenho manual ou caminhada para definir a área',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Preview do polígono
  Widget _buildPolygonPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '${_polygonPoints.length} pontos definidos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Área: ${_calculateArea().toStringAsFixed(2)} hectares',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Informações do polígono
  Widget _buildPolygonInfo() {
    final area = _calculateArea();
    final zoomRange = _selectedZoomLevel.split('-');
    final minZoom = int.parse(zoomRange[0]);
    final maxZoom = int.parse(zoomRange[1]);
    final totalTiles = TileCalculator.calculateTotalTiles(
      polygon: _polygonPoints,
      zoomMin: minZoom,
      zoomMax: maxZoom,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Download',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Área', '${area.toStringAsFixed(2)} ha'),
              ),
              Expanded(
                child: _buildInfoItem('Zoom', _selectedZoomLevel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Tiles', totalTiles.toString()),
              ),
              Expanded(
                child: _buildInfoItem('Tipo', _getMapTypeName()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de informação
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blue[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }

  /// Botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _polygonPoints.isEmpty ? null : _downloadMap,
            icon: const Icon(Icons.download),
            label: const Text('Baixar Mapa'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _polygonPoints.isEmpty ? null : _saveAsTalhao,
            icon: const Icon(Icons.save),
            label: const Text('Salvar como Talhão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Progresso de download
  Widget _buildDownloadProgress() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download em Progresso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Inicia desenho manual
  void _startManualDrawing() {
    // Implementar desenho manual
    // Por enquanto, adicionar pontos de exemplo
    setState(() {
      _polygonPoints.addAll([
        const LatLng(-23.5505, -46.6333), // São Paulo
        const LatLng(-23.5405, -46.6333),
        const LatLng(-23.5405, -46.6233),
        const LatLng(-23.5505, -46.6233),
      ]);
    });
  }

  /// Inicia desenho por caminhada
  void _startWalkingDrawing() {
    // Implementar desenho por caminhada
    // Por enquanto, adicionar pontos de exemplo
    setState(() {
      _polygonPoints.addAll([
        const LatLng(-23.5505, -46.6333), // São Paulo
        const LatLng(-23.5405, -46.6333),
        const LatLng(-23.5405, -46.6233),
        const LatLng(-23.5505, -46.6233),
      ]);
    });
  }

  /// Limpa o polígono
  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  /// Baixa o mapa
  Future<void> _downloadMap() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o mapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Simular download
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() {
          _downloadProgress = (i + 1) / 100;
        });
      }

      // Criar mapa offline
      final offlineMap = await _offlineMapService.createOfflineMap(
        talhaoId: 'free_${DateTime.now().millisecondsSinceEpoch}',
        talhaoName: _nameController.text,
        polygon: _polygonPoints.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        area: _calculateArea(),
        zoomMin: int.parse(_selectedZoomLevel.split('-')[0]),
        zoomMax: int.parse(_selectedZoomLevel.split('-')[1]),
        metadata: {
          'mapType': _selectedMapType,
          'isFreeDownload': true,
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mapa "${_nameController.text}" baixado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpar formulário
      _nameController.clear();
      _clearPolygon();
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao baixar mapa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Salva como talhão
  void _saveAsTalhao() {
    // Implementar salvamento como talhão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Calcula área do polígono
  double _calculateArea() {
    if (_polygonPoints.length < 3) return 0.0;
    
    // Implementar cálculo de área usando fórmula de Shoelace
    double area = 0.0;
    for (int i = 0; i < _polygonPoints.length; i++) {
      int j = (i + 1) % _polygonPoints.length;
      area += _polygonPoints[i].longitude * _polygonPoints[j].latitude;
      area -= _polygonPoints[j].longitude * _polygonPoints[i].latitude;
    }
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximado)
    return area * 111000 * 111000 / 10000; // Conversão aproximada
  }

  /// Obtém nome do tipo de mapa
  String _getMapTypeName() {
    switch (_selectedMapType) {
      case 'satellite':
        return 'Satélite';
      case 'streets':
        return 'Ruas';
      case 'outdoors':
        return 'Outdoors';
      case 'hybrid':
        return 'Híbrido';
      default:
        return 'Satélite';
    }
  }
}
