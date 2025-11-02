import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../services/enhanced_offline_map_service.dart';
import '../utils/api_config.dart';

/// Widget para download livre de mapas - permite ao usuário baixar qualquer área
class FreeMapDownloadWidget extends StatefulWidget {
  final Function()? onDownloadComplete;
  final Function()? onDownloadCancel;

  const FreeMapDownloadWidget({
    Key? key,
    this.onDownloadComplete,
    this.onDownloadCancel,
  }) : super(key: key);

  @override
  State<FreeMapDownloadWidget> createState() => _FreeMapDownloadWidgetState();
}

class _FreeMapDownloadWidgetState extends State<FreeMapDownloadWidget> {
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isDownloading = false;
  double _currentProgress = 0.0;
  String _statusMessage = '';
  String _selectedMapType = 'satellite';
  int _minZoom = 10;
  int _maxZoom = 16;
  
  // Coordenadas da área
  LatLng? _southwest;
  LatLng? _northeast;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  /// Inicializa o serviço
  Future<void> _initializeService() async {
    try {
      await _mapService.initialize();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro ao inicializar: $e';
      });
    }
  }
  
  /// Inicia download do mapa
  Future<void> _startDownload() async {
    if (_isDownloading || _southwest == null || _northeast == null) return;
    
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor, digite um nome para a área');
      return;
    }
    
    setState(() {
      _isDownloading = true;
      _statusMessage = '🔄 Iniciando download...';
    });
    
    try {
      final result = await _mapService.downloadFarmArea(
        farmName: _nameController.text.trim(),
        southwest: _southwest!,
        northeast: _northeast!,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        mapType: _selectedMapType,
        onProgress: (progress) {
          setState(() {
            _currentProgress = progress;
            _statusMessage = '📥 Baixando: ${(progress * 100).toInt()}%';
          });
        },
      );
      
      setState(() {
        _isDownloading = false;
        _statusMessage = result['success']
            ? '✅ Download concluído: ${result['downloadedTiles']} tiles'
            : '❌ Erro no download: ${result['failedTiles']} falhas';
      });
      
      if (result['success']) {
        _showSuccessSnackBar('Mapa baixado com sucesso!');
        widget.onDownloadComplete?.call();
      } else {
        _showErrorSnackBar('Erro no download: ${result['error']}');
      }
      
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = '❌ Erro: $e';
      });
      _showErrorSnackBar('Erro no download: $e');
    }
  }
  
  /// Cancela download
  void _cancelDownload() {
    setState(() {
      _isDownloading = false;
      _statusMessage = '⏹️ Download cancelado';
    });
    widget.onDownloadCancel?.call();
  }
  
  /// Define área por coordenadas
  void _setAreaByCoordinates() {
    showDialog(
      context: context,
      builder: (context) => _CoordinatesDialog(
        onCoordinatesSet: (southwest, northeast) {
          setState(() {
            _southwest = southwest;
            _northeast = northeast;
            _statusMessage = '📍 Área definida: ${_formatCoordinates(southwest)} a ${_formatCoordinates(northeast)}';
          });
        },
      ),
    );
  }
  
  /// Define área por talhões existentes
  void _setAreaByTalhoes() {
    showDialog(
      context: context,
      builder: (context) => _TalhoesDialog(
        onTalhoesSelected: (southwest, northeast) {
          setState(() {
            _southwest = southwest;
            _northeast = northeast;
            _statusMessage = '🌾 Área definida pelos talhões selecionados';
          });
        },
      ),
    );
  }
  
  /// Formata coordenadas para exibição
  String _formatCoordinates(LatLng coord) {
    return '${coord.latitude.toStringAsFixed(4)}, ${coord.longitude.toStringAsFixed(4)}';
  }
  
  /// Calcula tamanho estimado do download
  String _getEstimatedSize() {
    if (_southwest == null || _northeast == null) return 'N/A';
    
    final latDiff = _northeast!.latitude - _southwest!.latitude;
    final lngDiff = _northeast!.longitude - _southwest!.longitude;
    final area = latDiff * lngDiff;
    
    int totalTiles = 0;
    for (int z = _minZoom; z <= _maxZoom; z++) {
      final tilesAtZoom = (area * 4 * pow(4, z - 10)).round();
      totalTiles += tilesAtZoom;
    }
    
    final sizeMB = (totalTiles * 15 / 1024).round();
    return '${sizeMB} MB';
  }
  
  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Livre de Mapas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.download, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Download Livre de Mapas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showHelp(context),
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Ajuda',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nome da área
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Área',
                hintText: 'Ex: Fazenda São João',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Seleção de área
            Text(
              'Definir Área',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setAreaByCoordinates,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Por Coordenadas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setAreaByTalhoes,
                    icon: const Icon(Icons.agriculture),
                    label: const Text('Por Talhões'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Área selecionada
            if (_southwest != null && _northeast != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Área Selecionada:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Sudoeste: ${_formatCoordinates(_southwest!)}'),
                    Text('Nordeste: ${_formatCoordinates(_northeast!)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Configurações
            Text(
              'Configurações de Download',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            // Tipo de mapa
            DropdownButtonFormField<String>(
              value: _selectedMapType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Mapa',
                border: OutlineInputBorder(),
              ),
              items: APIConfig.getAvailableMapTypes().map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMapType = value ?? 'satellite';
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Configurações de zoom
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zoom Mínimo: $_minZoom'),
                      Slider(
                        value: _minZoom.toDouble(),
                        min: 8,
                        max: 14,
                        divisions: 6,
                        onChanged: (value) {
                          setState(() {
                            _minZoom = value.toInt();
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
                      Text('Zoom Máximo: $_maxZoom'),
                      Slider(
                        value: _maxZoom.toDouble(),
                        min: 12,
                        max: 18,
                        divisions: 6,
                        onChanged: (value) {
                          setState(() {
                            _maxZoom = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Tamanho estimado: ${_getEstimatedSize()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            const SizedBox(height: 16),
            
            // Status
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Progresso do download
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _currentProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Progresso: ${(_currentProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              children: [
                if (_southwest != null && _northeast != null && !_isDownloading)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Baixar Mapa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                
                if (_isDownloading)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cancelDownload,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Mostra ajuda
  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Download Livre'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Por Coordenadas: Digite as coordenadas manualmente'),
              SizedBox(height: 8),
              Text('• Por Talhões: Selecione talhões existentes'),
              SizedBox(height: 8),
              Text('• Zoom menor = menos detalhes, menor tamanho'),
              SizedBox(height: 8),
              Text('• Zoom maior = mais detalhes, maior tamanho'),
              SizedBox(height: 8),
              Text('• Recomendado: Zoom 10-16 para uso no campo'),
              SizedBox(height: 8),
              Text('• Satélite: Melhor para identificação de culturas'),
              SizedBox(height: 8),
              Text('• Streets: Melhor para navegação'),
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
}

/// Dialog para definir coordenadas
class _CoordinatesDialog extends StatefulWidget {
  final Function(LatLng southwest, LatLng northeast) onCoordinatesSet;

  const _CoordinatesDialog({required this.onCoordinatesSet});

  @override
  State<_CoordinatesDialog> createState() => _CoordinatesDialogState();
}

class _CoordinatesDialogState extends State<_CoordinatesDialog> {
  final TextEditingController _swLatController = TextEditingController();
  final TextEditingController _swLngController = TextEditingController();
  final TextEditingController _neLatController = TextEditingController();
  final TextEditingController _neLngController = TextEditingController();

  @override
  void dispose() {
    _swLatController.dispose();
    _swLngController.dispose();
    _neLatController.dispose();
    _neLngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Definir Coordenadas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sudoeste (canto inferior esquerdo):'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _swLatController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '-15.1234',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _swLngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '-47.1234',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Nordeste (canto superior direito):'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _neLatController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '-15.1234',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _neLngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '-47.1234',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final swLat = double.parse(_swLatController.text);
              final swLng = double.parse(_swLngController.text);
              final neLat = double.parse(_neLatController.text);
              final neLng = double.parse(_neLngController.text);
              
              widget.onCoordinatesSet(
                LatLng(swLat, swLng),
                LatLng(neLat, neLng),
              );
              Navigator.of(context).pop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao analisar coordenadas: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Definir'),
        ),
      ],
    );
  }
}

/// Dialog para selecionar talhões
class _TalhoesDialog extends StatefulWidget {
  final Function(LatLng southwest, LatLng northeast) onTalhoesSelected;

  const _TalhoesDialog({required this.onTalhoesSelected});

  @override
  State<_TalhoesDialog> createState() => _TalhoesDialogState();
}

class _TalhoesDialogState extends State<_TalhoesDialog> {
  List<Map<String, dynamic>> _talhoes = [];
  List<bool> _selectedTalhoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  Future<void> _loadTalhoes() async {
    try {
      // Carregar talhões reais do banco de dados
      // TODO: Implementar carregamento real de talhões
      setState(() {
        _talhoes = [];
        _selectedTalhoes = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Talhões'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _talhoes.length,
                itemBuilder: (context, index) {
                  final talhao = _talhoes[index];
                  return CheckboxListTile(
                    title: Text(talhao['name']),
                    subtitle: Text(
                      '${talhao['southwest'].latitude.toStringAsFixed(4)}, ${talhao['southwest'].longitude.toStringAsFixed(4)}',
                    ),
                    value: _selectedTalhoes[index],
                    onChanged: (value) {
                      setState(() {
                        _selectedTalhoes[index] = value ?? false;
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedTalhoes = <Map<String, dynamic>>[];
            for (int i = 0; i < _talhoes.length; i++) {
              if (_selectedTalhoes[i]) {
                selectedTalhoes.add(_talhoes[i]);
              }
            }
            
            if (selectedTalhoes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecione pelo menos um talhão'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            // Calcular área total
            double minLat = selectedTalhoes.first['southwest'].latitude;
            double minLng = selectedTalhoes.first['southwest'].longitude;
            double maxLat = selectedTalhoes.first['northeast'].latitude;
            double maxLng = selectedTalhoes.first['northeast'].longitude;
            
            for (final talhao in selectedTalhoes) {
              final sw = talhao['southwest'] as LatLng;
              final ne = talhao['northeast'] as LatLng;
              
              minLat = minLat < sw.latitude ? minLat : sw.latitude;
              minLng = minLng < sw.longitude ? minLng : sw.longitude;
              maxLat = maxLat > ne.latitude ? maxLat : ne.latitude;
              maxLng = maxLng > ne.longitude ? maxLng : ne.longitude;
            }
            
            widget.onTalhoesSelected(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Selecionar'),
        ),
      ],
    );
  }
}
