import 'package:flutter/material.dart';
import '../services/hybrid_offline_integration_service.dart';
import '../services/hybrid_gps_service.dart';
import '../services/enhanced_offline_map_service.dart';
import '../widgets/optimized_dashboard_cards.dart';

/// Widget de status do sistema híbrido
class HybridSystemStatusWidget extends StatefulWidget {
  final bool isCompact;
  final Function()? onTap;

  const HybridSystemStatusWidget({
    Key? key,
    this.isCompact = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<HybridSystemStatusWidget> createState() => _HybridSystemStatusWidgetState();
}

class _HybridSystemStatusWidgetState extends State<HybridSystemStatusWidget> {
  final HybridOfflineIntegrationService _integrationService = HybridOfflineIntegrationService();
  final HybridGPSService _gpsService = HybridGPSService();
  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  
  Map<String, dynamic> _sessionStats = {};
  Map<String, dynamic> _gpsStats = {};
  Map<String, dynamic> _mapStats = {};
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  /// Inicializa serviços e carrega dados
  Future<void> _initializeServices() async {
    try {
      await _integrationService.initialize();
      await _gpsService.initialize();
      await _mapService.initialize();
      
      await _loadStats();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
    }
  }
  
  /// Carrega estatísticas dos serviços
  Future<void> _loadStats() async {
    try {
      final sessionStats = _integrationService.getCurrentSessionStats();
      final gpsStats = _gpsService.getTrackingStats();
      final mapStats = await _mapService.getCacheStats();
      
      setState(() {
        _sessionStats = sessionStats;
        _gpsStats = gpsStats;
        _mapStats = mapStats;
      });
    } catch (e) {
      // Erro ao carregar estatísticas
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingWidget();
    }
    
    if (widget.isCompact) {
      return _buildCompactStatus();
    } else {
      return _buildFullStatus();
    }
  }
  
  /// Widget de carregamento
  Widget _buildLoadingWidget() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inicializando sistema híbrido...',
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Status compacto
  Widget _buildCompactStatus() {
    final hasActiveSession = _sessionStats['isActive'] == true;
    final isOfflineMode = _sessionStats['isOfflineMode'] == true;
    final isTracking = _gpsStats['isTracking'] == true;
    final hasOfflineMaps = _mapStats['isWorking'] == true;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (hasActiveSession) {
      if (isOfflineMode) {
        statusColor = Colors.orange;
        statusText = 'Offline Ativo';
        statusIcon = Icons.offline_bolt;
      } else {
        statusColor = Colors.green;
        statusText = 'Online Ativo';
        statusIcon = Icons.wifi;
      }
    } else if (isTracking) {
      statusColor = Colors.blue;
      statusText = 'Rastreando';
      statusIcon = Icons.gps_fixed;
    } else if (hasOfflineMaps) {
      statusColor = Colors.green;
      statusText = 'Mapas OK';
      statusIcon = Icons.map;
    } else {
      statusColor = Colors.grey;
      statusText = 'Inativo';
      statusIcon = Icons.pause;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sistema Híbrido',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasActiveSession) ...[
                const SizedBox(height: 2),
                Text(
                  '${_sessionStats['totalData'] ?? 0} pontos',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Status completo
  Widget _buildFullStatus() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Status do Sistema Híbrido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status da sessão
            _buildSessionStatus(),
            
            const SizedBox(height: 16),
            
            // Status do GPS
            _buildGPSStatus(),
            
            const SizedBox(height: 16),
            
            // Status dos mapas
            _buildMapStatus(),
            
            const SizedBox(height: 16),
            
            // Estatísticas
            _buildStatistics(),
          ],
        ),
      ),
    );
  }
  
  /// Status da sessão
  Widget _buildSessionStatus() {
    final hasActiveSession = _sessionStats['isActive'] == true;
    final isOfflineMode = _sessionStats['isOfflineMode'] == true;
    final totalData = _sessionStats['totalData'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasActiveSession 
            ? (isOfflineMode ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1))
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasActiveSession 
              ? (isOfflineMode ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3))
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActiveSession ? Icons.play_circle : Icons.pause_circle,
                color: hasActiveSession ? Colors.green : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Sessão: ${hasActiveSession ? "Ativa" : "Inativa"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasActiveSession ? Colors.green[800] : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Modo: ${isOfflineMode ? "Offline" : "Online"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Dados coletados: $totalData pontos',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  /// Status do GPS
  Widget _buildGPSStatus() {
    final isTracking = _gpsStats['isTracking'] == true;
    final isPaused = _gpsStats['isPaused'] == true;
    final accuracy = _gpsStats['currentAccuracy'] ?? 0.0;
    final satellites = _gpsStats['satellitesCount'] ?? 0;
    final activeSatellites = _gpsStats['activeSatellites'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTracking ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTracking ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTracking ? Icons.gps_fixed : Icons.gps_off,
                color: isTracking ? Colors.blue : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'GPS: ${isTracking ? (isPaused ? "Pausado" : "Ativo") : "Inativo"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isTracking ? Colors.blue[800] : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Precisão: ${accuracy.toStringAsFixed(1)}m',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Satélites: $activeSatellites/$satellites',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  /// Status dos mapas
  Widget _buildMapStatus() {
    final hasOfflineMaps = _mapStats['isWorking'] == true;
    final totalTiles = _mapStats['totalTiles'] ?? 0;
    final totalSizeMB = _mapStats['totalSizeMB'] ?? 0;
    final usagePercentage = _mapStats['usagePercentage'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasOfflineMaps ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasOfflineMaps ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasOfflineMaps ? Icons.map : Icons.map_outlined,
                color: hasOfflineMaps ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Mapas: ${hasOfflineMaps ? "Disponíveis" : "Não disponíveis"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasOfflineMaps ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tiles: $totalTiles',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Tamanho: ${totalSizeMB}MB ($usagePercentage%)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  /// Estatísticas
  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: OptimizedDashboardCards.buildStatsCard(
                title: 'Sessões',
                value: '${_sessionStats['totalData'] ?? 0}',
                icon: Icons.timeline,
                color: Colors.blue,
                subtitle: 'Pontos coletados',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OptimizedDashboardCards.buildStatsCard(
                title: 'Precisão',
                value: '${(_gpsStats['currentAccuracy'] ?? 0.0).toStringAsFixed(1)}m',
                icon: Icons.gps_fixed,
                color: Colors.green,
                subtitle: 'GPS atual',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
