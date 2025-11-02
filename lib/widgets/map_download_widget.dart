import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_cache_service.dart';

/// Widget para download de mapas offline
class MapDownloadWidget extends StatefulWidget {
  final LatLng southwest;
  final LatLng northeast;
  final Function()? onDownloadComplete;
  final Function()? onDownloadCancel;

  const MapDownloadWidget({
    Key? key,
    required this.southwest,
    required this.northeast,
    this.onDownloadComplete,
    this.onDownloadCancel,
  }) : super(key: key);

  @override
  State<MapDownloadWidget> createState() => _MapDownloadWidgetState();
}

class _MapDownloadWidgetState extends State<MapDownloadWidget> {
  final MapCacheService _mapCacheService = MapCacheService();
  
  bool _isDownloading = false;
  bool _isDownloaded = false;
  int _currentProgress = 0;
  int _totalTiles = 0;
  String _statusMessage = '';
  
  // Configurações de download
  int _minZoom = 12;
  int _maxZoom = 16;
  
  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }
  
  /// Verifica status do cache
  Future<void> _checkCacheStatus() async {
    try {
      final stats = await _mapCacheService.getCacheStats();
      setState(() {
        _isDownloaded = stats['isUpToDate'] ?? false;
        _statusMessage = _isDownloaded 
            ? '🗺️ Mapa offline disponível'
            : '📥 Mapa offline não disponível';
      });
    } catch (e) {
      print('❌ Erro ao verificar cache: $e');
    }
  }
  
  /// Inicia download do mapa
  Future<void> _startDownload() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _statusMessage = '🔄 Iniciando download...';
    });
    
    try {
      final result = await _mapCacheService.downloadAreaForOffline(
        southwest: widget.southwest,
        northeast: widget.northeast,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onProgress: (current, total) {
          setState(() {
            _currentProgress = current;
            _totalTiles = total;
            _statusMessage = '📥 Baixando tiles: $current/$total';
          });
        },
      );
      
      setState(() {
        _isDownloading = false;
        _isDownloaded = result['success'];
        _statusMessage = result['success']
            ? '✅ Download concluído: ${result['downloaded']} tiles'
            : '❌ Erro no download: ${result['failed']} falhas';
      });
      
      if (result['success']) {
        widget.onDownloadComplete?.call();
      }
      
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = '❌ Erro: $e';
      });
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
  
  /// Calcula tamanho estimado do download
  String _getEstimatedSize() {
    final tiles = _mapCacheService.calculateTilesForArea(
      widget.southwest,
      widget.northeast,
      _minZoom,
      _maxZoom,
    );
    
    // Estimativa: ~15KB por tile
    final sizeKB = tiles.length * 15;
    if (sizeKB > 1024) {
      return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${sizeKB.toStringAsFixed(0)} KB';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  _isDownloaded ? Icons.map : Icons.download,
                  color: _isDownloaded ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mapa Offline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isDownloaded)
                  const Chip(
                    label: Text('✅ Disponível'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Configurações de zoom
            if (!_isDownloaded) ...[
              Text(
                'Configurações de Download',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              
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
            ],
            
            // Progresso do download
            if (_isDownloading && _totalTiles > 0) ...[
              LinearProgressIndicator(
                value: _currentProgress / _totalTiles,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Progresso: $_currentProgress/$_totalTiles tiles',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              children: [
                if (!_isDownloaded && !_isDownloading)
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
                
                if (_isDownloaded)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final stats = await _mapCacheService.getCacheStats();
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Informações do Cache'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tiles em cache: ${stats['tileCount']}'),
                                Text('Tamanho: ${stats['cacheSizeMB']} MB'),
                                if (stats['lastSync'] != null)
                                  Text('Última atualização: ${stats['lastSync']}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Fechar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Informações'),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ajuda - Mapa Offline'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• O mapa offline permite usar o aplicativo sem internet'),
                            SizedBox(height: 8),
                            Text('• Zoom menor = menos detalhes, menor tamanho'),
                            SizedBox(height: 8),
                            Text('• Zoom maior = mais detalhes, maior tamanho'),
                            SizedBox(height: 8),
                            Text('• Recomendado: Zoom 12-16 para uso no campo'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Entendi'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Ajuda',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 