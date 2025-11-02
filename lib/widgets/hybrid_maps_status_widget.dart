import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/hybrid_maps_integration_service.dart';
import '../utils/logger.dart';

/// Widget de status do sistema híbrido integrado com mapas offline
class HybridMapsStatusWidget extends StatefulWidget {
  final String? talhaoId;
  final LatLng? southwest;
  final LatLng? northeast;
  
  const HybridMapsStatusWidget({
    Key? key,
    this.talhaoId,
    this.southwest,
    this.northeast,
  }) : super(key: key);

  @override
  State<HybridMapsStatusWidget> createState() => _HybridMapsStatusWidgetState();
}

class _HybridMapsStatusWidgetState extends State<HybridMapsStatusWidget> {
  final HybridMapsIntegrationService _integrationService = HybridMapsIntegrationService();
  
  Map<String, dynamic> _currentStatus = {};
  bool _isLoading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa o serviço de integração
  Future<void> _initializeService() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Inicializar serviço
      final initialized = await _integrationService.initialize();
      
      if (initialized) {
        // Configurar callbacks
        _integrationService.onStatusUpdate = (status) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
              _isLoading = false;
            });
          }
        };
        
        _integrationService.onError = (error) {
          if (mounted) {
            setState(() {
              _error = error;
              _isLoading = false;
            });
          }
        };
        
        // Iniciar subscription
        _statusSubscription = _integrationService.statusStream.listen(
          (status) {
            if (mounted) {
              setState(() {
                _currentStatus = status;
              });
            }
          },
        );
        
        // Iniciar rastreamento se talhão fornecido
        if (widget.talhaoId != null && 
            widget.southwest != null && 
            widget.northeast != null) {
          await _startTracking();
        }
        
      } else {
        setState(() {
          _error = 'Falha ao inicializar serviço híbrido';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _error = 'Erro ao inicializar: $e';
        _isLoading = false;
      });
    }
  }

  /// Inicia rastreamento híbrido
  Future<void> _startTracking() async {
    if (widget.talhaoId == null || 
        widget.southwest == null || 
        widget.northeast == null) return;
    
    try {
      await _integrationService.startHybridTracking(
        talhaoId: widget.talhaoId!,
        southwest: widget.southwest!,
        northeast: widget.northeast!,
      );
    } catch (e) {
      Logger.error('❌ [HYBRID_MAPS_STATUS] Erro ao iniciar rastreamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    if (_error != null) {
      return _buildErrorWidget();
    }
    
    return _buildStatusWidget();
  }

  /// Widget de carregamento
  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Inicializando sistema híbrido...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Widget de erro
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: _initializeService,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Widget de status principal
  Widget _buildStatusWidget() {
    final isOnline = _currentStatus['isOnline'] ?? false;
    final gps = _currentStatus['gps'] ?? {};
    final maps = _currentStatus['maps'] ?? {};
    final integration = _currentStatus['integration'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sistema Híbrido ${isOnline ? 'Online' : 'Offline'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildStatusIndicator(isOnline),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status GPS
          _buildStatusRow(
            'GPS',
            gps['isTracking'] == true ? 'Ativo' : 'Inativo',
            gps['isTracking'] == true ? Colors.green : Colors.grey,
            'Precisão: ${gps['currentAccuracy']?.toStringAsFixed(1) ?? 'N/A'}m',
          ),
          
          // Status Mapas
          _buildStatusRow(
            'Mapas Offline',
            maps['isInitialized'] == true ? 'Disponível' : 'Indisponível',
            maps['isInitialized'] == true ? Colors.blue : Colors.grey,
            'Cache: ${maps['cacheSize'] ?? 'N/A'}',
          ),
          
          // Status Integração
          _buildStatusRow(
            'Integração',
            integration['isActive'] == true ? 'Ativa' : 'Inativa',
            integration['isActive'] == true ? Colors.purple : Colors.grey,
            'Sessão: ${integration['sessionId'] ?? 'N/A'}',
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _integrationService.isInitialized 
                      ? () => _integrationService.syncDataWhenOnline()
                      : null,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sincronizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _integrationService.isInitialized
                      ? () => _integrationService.stopHybridTracking()
                      : null,
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Parar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói indicador de status
  Widget _buildStatusIndicator(bool isOnline) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.orange,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Constrói linha de status
  Widget _buildStatusRow(String title, String status, Color color, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$status • $subtitle',
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
}
