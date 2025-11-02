import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/smart_monitoring_navigation_service.dart';
import '../../services/hybrid_gps_service.dart';
import '../../models/monitoring_point.dart';
import '../../utils/logger.dart';
import '../../widgets/hybrid_gps_status_widget.dart';

/// Tela de navegação inteligente para monitoramento
/// 
/// Funcionalidades:
/// - Navegação em tempo real com mapa
/// - Indicador de distância até o próximo ponto
/// - Validação de proximidade (5 metros)
/// - Notificações vibratórias
/// - Salvamento em segundo plano
class SmartNavigationScreen extends StatefulWidget {
  final MonitoringPoint currentPoint;
  final MonitoringPoint? nextPoint;
  final String cropName;
  final String fieldName;
  final VoidCallback? onArriveAtPoint;
  final VoidCallback? onNavigateToNextPoint;

  const SmartNavigationScreen({
    Key? key,
    required this.currentPoint,
    this.nextPoint,
    required this.cropName,
    required this.fieldName,
    this.onArriveAtPoint,
    this.onNavigateToNextPoint,
  }) : super(key: key);

  @override
  State<SmartNavigationScreen> createState() => _SmartNavigationScreenState();
}

class _SmartNavigationScreenState extends State<SmartNavigationScreen> {
  final SmartMonitoringNavigationService _navigationService = SmartMonitoringNavigationService();
  final MapController _mapController = MapController();
  
  Position? _currentPosition;
  double _distanceToPoint = 0.0;
  bool _isNearPoint = false;
  bool _isAtPoint = false;
  bool _canCreateOccurrence = false;
  double _gpsAccuracy = 0.0;
  String _directionText = 'N';
  bool _isNavigating = false;
  
  @override
  void initState() {
    super.initState();
    _startSmartNavigation();
  }
  
  @override
  void dispose() {
    _navigationService.stopSmartTracking();
    super.dispose();
  }
  
  /// Inicia a navegação inteligente
  Future<void> _startSmartNavigation() async {
    final targetPoint = LatLng(
      widget.currentPoint.latitude,
      widget.currentPoint.longitude,
    );
    
    await _navigationService.startSmartTracking(
      targetPoint: targetPoint,
      onLocationUpdate: _onLocationUpdate,
      onDistanceUpdate: _onDistanceUpdate,
      onProximityChange: _onProximityChange,
      onArrivalChange: _onArrivalChange,
      onVibrationNotification: _onVibrationNotification,
      onBackgroundSaveComplete: _onBackgroundSaveComplete,
    );
  }
  
  /// Callback de atualização de localização
  void _onLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
      _gpsAccuracy = position.accuracy;
    });
    
    // Atualizar mapa se necessário
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    }
  }
  
  /// Callback de atualização de distância
  void _onDistanceUpdate(double distance) {
    setState(() {
      _distanceToPoint = distance;
    });
  }
  
  /// Callback de mudança de proximidade
  void _onProximityChange(bool isNearPoint) {
    setState(() {
      _isNearPoint = isNearPoint;
    });
    
    if (isNearPoint) {
      _showProximityNotification();
    }
  }
  
  /// Callback de chegada ao ponto
  void _onArrivalChange(bool isAtPoint) {
    setState(() {
      _isAtPoint = isAtPoint;
      _canCreateOccurrence = isAtPoint;
    });
    
    if (isAtPoint) {
      _showArrivalNotification();
      widget.onArriveAtPoint?.call();
    }
  }
  
  /// Callback de notificação vibratória
  void _onVibrationNotification() {
    // Vibração já foi disparada pelo serviço
  }
  
  /// Callback de salvamento em segundo plano
  void _onBackgroundSaveComplete() {
    // Dados salvos em segundo plano
    Logger.info('💾 [SMART_NAV] Dados salvos em segundo plano');
  }
  
  /// Mostra notificação de proximidade
  void _showProximityNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.near_me, color: Colors.white),
            SizedBox(width: 8),
            Text('Aproximando-se do ponto de monitoramento'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Mostra notificação de chegada
  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text('Você chegou ao ponto! Pode registrar ocorrências'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Navegação Inteligente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header com informações do ponto
          _buildPointHeader(),
          
          // Mapa de navegação
          Expanded(
            flex: 3,
            child: _buildNavigationMap(),
          ),
          
          // Painel de informações
          Expanded(
            flex: 2,
            child: _buildInfoPanel(),
          ),
          
          // Botões de ação
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  /// Constrói o cabeçalho com informações do ponto
  Widget _buildPointHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _isAtPoint ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ponto ${widget.currentPoint.id} - ${widget.fieldName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cultura: ${widget.cropName}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói o mapa de navegação
  Widget _buildNavigationMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              widget.currentPoint.latitude,
              widget.currentPoint.longitude,
            ),
            initialZoom: 16.0,
            minZoom: 10.0,
            maxZoom: 20.0,
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Marcador do ponto de destino
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    widget.currentPoint.latitude,
                    widget.currentPoint.longitude,
                  ),
                  width: 40,
                  height: 40,
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: _isAtPoint ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Marcador da posição atual (se disponível)
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 30,
                    height: 30,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
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
  
  /// Constrói o painel de informações
  Widget _buildInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          // Distância até o ponto
          _buildDistanceInfo(),
          
          const SizedBox(height: 20),
          
          // Status de proximidade
          _buildProximityStatus(),
          
          const SizedBox(height: 20),
          
          // Informações de GPS
          _buildGpsInfo(),
          
          const SizedBox(height: 12),
          
          // Status do GPS híbrido
          HybridGPSStatusWidget(
            gpsService: _navigationService._hybridGPSService,
            showDetails: true,
          ),
        ],
      ),
    );
  }
  
  /// Constrói informações de distância
  Widget _buildDistanceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distância até o ponto',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_distanceToPoint.toStringAsFixed(1)} metros',
              style: TextStyle(
                color: _isAtPoint ? Colors.green : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (_directionText.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Direção',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _directionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  /// Constrói status de proximidade
  Widget _buildProximityStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (_isAtPoint) {
      statusColor = Colors.green;
      statusText = 'Você chegou ao ponto!';
      statusIcon = Icons.check_circle;
    } else if (_isNearPoint) {
      statusColor = Colors.orange;
      statusText = 'Aproximando-se do ponto';
      statusIcon = Icons.near_me;
    } else {
      statusColor = Colors.red;
      statusText = 'Continue navegando';
      statusIcon = Icons.directions;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói informações de GPS
  Widget _buildGpsInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precisão GPS',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              '${_gpsAccuracy.toStringAsFixed(1)}m',
              style: TextStyle(
                color: _gpsAccuracy <= 5 ? Colors.green : Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              _canCreateOccurrence ? 'Pronto' : 'Navegando',
              style: TextStyle(
                color: _canCreateOccurrence ? Colors.green : Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Constrói os botões de ação
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Botão de nova ocorrência (só habilitado quando no ponto)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canCreateOccurrence ? _createNewOccurrence : null,
              icon: const Icon(Icons.add),
              label: const Text('Nova Ocorrência'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _canCreateOccurrence ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botão de próximo ponto
          if (widget.nextPoint != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToNextPoint,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próximo Ponto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Cria nova ocorrência
  void _createNewOccurrence() {
    if (!_canCreateOccurrence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar no ponto para criar uma ocorrência'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navegar para tela de criação de ocorrência
    Navigator.of(context).pushNamed(
      '/monitoring/occurrence/create',
      arguments: {
        'pointId': widget.currentPoint.id,
        'latitude': widget.currentPoint.latitude,
        'longitude': widget.currentPoint.longitude,
      },
    );
  }
  
  /// Navega para o próximo ponto
  void _navigateToNextPoint() {
    if (widget.nextPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há próximo ponto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    widget.onNavigateToNextPoint?.call();
  }
}
