import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../services/enhanced_offline_map_service.dart';
import '../services/hybrid_gps_service.dart';
import '../services/hybrid_connectivity_service.dart';
import '../widgets/hybrid_gps_status_widget.dart';
import '../utils/api_config.dart';
import '../utils/logger.dart';

/// Widget otimizado para download de mapas offline com cards menores
class EnhancedMapDownloadWidget extends StatefulWidget {
  final LatLng? southwest;
  final LatLng? northeast;
  final String? farmName;
  final Function()? onDownloadComplete;
  final Function()? onDownloadCancel;
  final bool isCompact;

  const EnhancedMapDownloadWidget({
    Key? key,
    this.southwest,
    this.northeast,
    this.farmName,
    this.onDownloadComplete,
    this.onDownloadCancel,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<EnhancedMapDownloadWidget> createState() => _EnhancedMapDownloadWidgetState();
}

class _EnhancedMapDownloadWidgetState extends State<EnhancedMapDownloadWidget> {
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  final HybridGPSService _hybridGPSService = HybridGPSService();
  final HybridConnectivityService _connectivityService = HybridConnectivityService();
  
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _currentProgress = 0.0;
  String _statusMessage = '';
  String _selectedMapType = 'satellite';
  int _minZoom = 10;
  int _maxZoom = 16;
  Map<String, dynamic> _cacheStats = {};
  List<Map<String, dynamic>> _downloadedAreas = [];
  Map<String, dynamic> _gpsStats = {};
  Map<String, dynamic> _connectivityStats = {};
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  /// Inicializa o serviço e carrega dados
  Future<void> _initializeService() async {
    try {
      await _mapService.initialize();
      await _hybridGPSService.initialize();
      await _connectivityService.initialize();
      await _loadCacheStats();
      await _loadDownloadedAreas();
      await _loadGPSStats();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro ao inicializar: $e';
      });
    }
  }
  
  /// Carrega estatísticas do cache
  Future<void> _loadCacheStats() async {
    try {
      final stats = await _mapService.getCacheStats();
      setState(() {
        _cacheStats = stats;
        _isDownloaded = stats['isWorking'] == true;
        _statusMessage = _isDownloaded 
            ? '🗺️ ${stats['totalTiles']} tiles em cache'
            : '📥 Nenhum mapa offline disponível';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro ao carregar estatísticas';
      });
    }
  }
  
  /// Carrega áreas baixadas
  Future<void> _loadDownloadedAreas() async {
    try {
      final areas = await _mapService.getDownloadedAreas();
      setState(() {
        _downloadedAreas = areas;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar áreas: $e');
    }
  }
  
  /// Carrega estatísticas GPS
  Future<void> _loadGPSStats() async {
    try {
      final gpsStats = _hybridGPSService.getTrackingStats();
      final connectivityStats = _connectivityService.getConnectivityStats();
      setState(() {
        _gpsStats = gpsStats;
        _connectivityStats = connectivityStats;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar estatísticas GPS: $e');
    }
  }
  
  /// Inicia download do mapa
  Future<void> _startDownload() async {
    if (_isDownloading || widget.southwest == null || widget.northeast == null) return;
    
    setState(() {
      _isDownloading = true;
      _statusMessage = '🔄 Iniciando download...';
    });
    
    try {
      final result = await _mapService.downloadFarmArea(
        farmName: widget.farmName ?? 'Área Personalizada',
        southwest: widget.southwest!,
        northeast: widget.northeast!,
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
        _isDownloaded = result['success'];
        _statusMessage = result['success']
            ? '✅ Download concluído: ${result['downloadedTiles']} tiles'
            : '❌ Erro no download: ${result['failedTiles']} falhas';
      });
      
      if (result['success']) {
        await _loadCacheStats();
        await _loadDownloadedAreas();
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
    if (widget.southwest == null || widget.northeast == null) return 'N/A';
    
    // Estimativa baseada na área e zoom
    final latDiff = widget.northeast!.latitude - widget.southwest!.latitude;
    final lngDiff = widget.northeast!.longitude - widget.southwest!.longitude;
    final area = latDiff * lngDiff;
    
    // Estimativa: ~4 tiles por grau² no zoom 10, multiplicado por 4 para cada nível
    int totalTiles = 0;
    for (int z = _minZoom; z <= _maxZoom; z++) {
      final tilesAtZoom = (area * 4 * pow(4, z - 10)).round();
      totalTiles += tilesAtZoom;
    }
    
    final sizeMB = (totalTiles * 15 / 1024).round();
    return '${sizeMB} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactCard();
    } else {
      return _buildFullCard();
    }
  }
  
  /// Card compacto para dashboards
  Widget _buildCompactCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isDownloaded ? Icons.map : Icons.download,
                  color: _isDownloaded ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mapa Offline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (_isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'OK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Status GPS compacto
            Row(
              children: [
                Icon(
                  _connectivityStats['isOnline'] == true ? Icons.wifi : Icons.wifi_off,
                  size: 12,
                  color: _connectivityStats['isOnline'] == true ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  _connectivityStats['isOnline'] == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: _connectivityStats['isOnline'] == true ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.gps_fixed,
                  size: 12,
                  color: _gpsStats['currentAccuracy'] != null && _gpsStats['currentAccuracy'] < 5.0 
                      ? Colors.green 
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_gpsStats['currentAccuracy']?.toStringAsFixed(1) ?? 'N/A'}m',
                  style: TextStyle(
                    fontSize: 10,
                    color: _gpsStats['currentAccuracy'] != null && _gpsStats['currentAccuracy'] < 5.0 
                        ? Colors.green 
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_gpsStats['multiSystemEnabled'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MULTI-GNSS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            if (_isDownloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _currentProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                if (!_isDownloaded && !_isDownloading)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Baixar'),
                    ),
                  ),
                
                if (_isDownloading)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                
                if (_isDownloaded)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCacheInfo(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Info'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Card completo para telas dedicadas
  Widget _buildFullCard() {
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
            
            // Status GPS detalhado
            HybridGPSStatusWidget(
              gpsService: _hybridGPSService,
              showDetails: true,
            ),
            
            const SizedBox(height: 16),
            
            // Configurações de download
            if (!_isDownloaded) ...[
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
                      onPressed: () => _showCacheInfo(context),
                      icon: const Icon(Icons.info),
                      label: const Text('Informações'),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                IconButton(
                  onPressed: () => _showHelp(context),
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
  
  /// Mostra informações do cache
  void _showCacheInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Cache'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiles em cache: ${_cacheStats['totalTiles']}'),
              Text('Tamanho: ${_cacheStats['totalSizeMB']} MB'),
              Text('Uso: ${_cacheStats['usagePercentage']}%'),
              Text('Tipos de mapa: ${_cacheStats['mapTypes']}'),
              Text('Níveis de zoom: ${_cacheStats['zoomLevels']}'),
              Text('Áreas baixadas: ${_cacheStats['completedAreas']}/${_cacheStats['totalAreas']}'),
              if (_cacheStats['lastUpdated'] != null)
                Text('Última atualização: ${_cacheStats['lastUpdated']}'),
            ],
          ),
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
  
  /// Mostra ajuda
  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Mapa Offline'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• O mapa offline permite usar o aplicativo sem internet'),
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
