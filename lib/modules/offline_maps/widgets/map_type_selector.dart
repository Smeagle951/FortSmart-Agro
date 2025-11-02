import 'package:flutter/material.dart';

/// Widget para seleção de tipo de mapa
class MapTypeSelector extends StatefulWidget {
  const MapTypeSelector({super.key});

  @override
  State<MapTypeSelector> createState() => _MapTypeSelectorState();
}

class _MapTypeSelectorState extends State<MapTypeSelector> {
  String _selectedMapType = 'satellite';
  String _selectedZoomLevel = '13-18';
  bool _enableCaching = true;
  bool _enableCompression = true;
  int _maxConcurrentDownloads = 3;

  final List<MapTypeOption> _mapTypes = [
    MapTypeOption(
      id: 'satellite',
      name: 'Satélite',
      description: 'Imagens de satélite de alta qualidade',
      icon: Icons.satellite,
      color: Colors.green,
      estimatedSize: '2.5 MB/ha',
    ),
    MapTypeOption(
      id: 'streets',
      name: 'Ruas',
      description: 'Mapa de ruas e estradas',
      icon: Icons.directions,
      color: Colors.blue,
      estimatedSize: '1.8 MB/ha',
    ),
    MapTypeOption(
      id: 'outdoors',
      name: 'Outdoors',
      description: 'Ideal para atividades ao ar livre',
      icon: Icons.hiking,
      color: Colors.orange,
      estimatedSize: '2.2 MB/ha',
    ),
    MapTypeOption(
      id: 'hybrid',
      name: 'Híbrido',
      description: 'Combinação de satélite e ruas',
      icon: Icons.layers,
      color: Colors.purple,
      estimatedSize: '3.0 MB/ha',
    ),
    MapTypeOption(
      id: 'basic',
      name: 'Básico',
      description: 'Mapa simples e leve',
      icon: Icons.map,
      color: Colors.grey,
      estimatedSize: '1.2 MB/ha',
    ),
  ];

  final List<ZoomLevelOption> _zoomLevels = [
    ZoomLevelOption(
      id: '12-16',
      name: 'Econômico',
      description: 'Menor qualidade, menos dados',
      minZoom: 12,
      maxZoom: 16,
      estimatedTiles: 1000,
      color: Colors.green,
    ),
    ZoomLevelOption(
      id: '13-18',
      name: 'Padrão',
      description: 'Boa qualidade, tamanho moderado',
      minZoom: 13,
      maxZoom: 18,
      estimatedTiles: 5000,
      color: Colors.blue,
    ),
    ZoomLevelOption(
      id: '15-20',
      name: 'Alta Qualidade',
      description: 'Máxima qualidade, mais dados',
      minZoom: 15,
      maxZoom: 20,
      estimatedTiles: 20000,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Text(
                  'Configurações de Mapa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seleção de tipo de mapa
                    _buildMapTypeSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Seleção de nível de zoom
                    _buildZoomLevelSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Configurações avançadas
                    _buildAdvancedSettings(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// Seleção de tipo de mapa
  Widget _buildMapTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Mapa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._mapTypes.map((mapType) => _buildMapTypeCard(mapType)),
      ],
    );
  }

  /// Card de tipo de mapa
  Widget _buildMapTypeCard(MapTypeOption mapType) {
    final isSelected = _selectedMapType == mapType.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? mapType.color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMapType = mapType.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mapType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mapType.icon,
                  color: mapType.color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mapType.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mapType.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mapType.estimatedSize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicador de seleção
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: mapType.color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seleção de nível de zoom
  Widget _buildZoomLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nível de Zoom',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._zoomLevels.map((zoomLevel) => _buildZoomLevelCard(zoomLevel)),
      ],
    );
  }

  /// Card de nível de zoom
  Widget _buildZoomLevelCard(ZoomLevelOption zoomLevel) {
    final isSelected = _selectedZoomLevel == zoomLevel.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? zoomLevel.color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedZoomLevel = zoomLevel.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador de zoom
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: zoomLevel.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.zoom_in,
                  color: zoomLevel.color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoomLevel.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zoomLevel.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.layers,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zoom ${zoomLevel.minZoom}-${zoomLevel.maxZoom}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.grid_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${zoomLevel.estimatedTiles} tiles',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicador de seleção
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: zoomLevel.color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Configurações avançadas
  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações Avançadas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Cache
        SwitchListTile(
          title: const Text('Habilitar Cache'),
          subtitle: const Text('Armazenar tiles localmente para acesso rápido'),
          value: _enableCaching,
          onChanged: (value) {
            setState(() {
              _enableCaching = value;
            });
          },
          secondary: const Icon(Icons.storage),
        ),
        
        // Compressão
        SwitchListTile(
          title: const Text('Compressão'),
          subtitle: const Text('Reduzir tamanho dos arquivos'),
          value: _enableCompression,
          onChanged: (value) {
            setState(() {
              _enableCompression = value;
            });
          },
          secondary: const Icon(Icons.compress),
        ),
        
        // Downloads simultâneos
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Downloads Simultâneos'),
          subtitle: Text('Máximo $_maxConcurrentDownloads downloads por vez'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _maxConcurrentDownloads > 1
                    ? () {
                        setState(() {
                          _maxConcurrentDownloads--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_maxConcurrentDownloads'),
              IconButton(
                onPressed: _maxConcurrentDownloads < 10
                    ? () {
                        setState(() {
                          _maxConcurrentDownloads++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
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
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applySettings,
            child: const Text('Aplicar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Aplica as configurações
  void _applySettings() {
    Navigator.pop(context);
    
    // Mostrar resumo das configurações
    final selectedMapType = _mapTypes.firstWhere((m) => m.id == _selectedMapType);
    final selectedZoomLevel = _zoomLevels.firstWhere((z) => z.id == _selectedZoomLevel);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Configurações aplicadas: ${selectedMapType.name}, '
          'Zoom ${selectedZoomLevel.minZoom}-${selectedZoomLevel.maxZoom}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Opção de tipo de mapa
class MapTypeOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String estimatedSize;

  const MapTypeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.estimatedSize,
  });
}

/// Opção de nível de zoom
class ZoomLevelOption {
  final String id;
  final String name;
  final String description;
  final int minZoom;
  final int maxZoom;
  final int estimatedTiles;
  final Color color;

  const ZoomLevelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.minZoom,
    required this.maxZoom,
    required this.estimatedTiles,
    required this.color,
  });
}
