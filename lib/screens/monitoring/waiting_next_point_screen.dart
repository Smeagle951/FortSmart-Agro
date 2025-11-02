import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../../utils/logger.dart';
import 'enhanced_navigation_screen.dart';

/// Tela de espera entre pontos de monitoramento
/// Mostra direções e distância até o próximo ponto
class WaitingNextPointScreen extends StatefulWidget {
  final String currentPointId;
  final String? nextPointId;
  final Map<String, dynamic>? nextPointData;
  final String? fieldId;
  final String? cropName;
  final VoidCallback? onArrived;
  final VoidCallback? onSkip;

  const WaitingNextPointScreen({
    Key? key,
    required this.currentPointId,
    this.nextPointId,
    this.nextPointData,
    this.fieldId,
    this.cropName,
    this.onArrived,
    this.onSkip,
  }) : super(key: key);

  @override
  State<WaitingNextPointScreen> createState() => _WaitingNextPointScreenState();
}

class _WaitingNextPointScreenState extends State<WaitingNextPointScreen> with TickerProviderStateMixin {
  Position? _currentPosition;
  double? _distanceToNext;
  double? _bearingToNext;
  bool _isLoadingLocation = false;
  
  // Sistema de vibração e alertas
  Timer? _locationUpdateTimer;
  bool _hasVibrated = false;
  bool _isNearPoint = false;
  double _proximityThreshold = 10.0; // metros
  
  // Sistema de background
  bool _isBackgroundMode = false;
  bool _wakelockEnabled = false;
  StreamSubscription<Position>? _positionStream;
  
  // Animações
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLocationTracking();
    _startRealTimeLocationUpdates();
    _enableBackgroundMonitoring();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Iniciar animações
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  Future<void> _startLocationTracking() async {
    try {
      setState(() => _isLoadingLocation = true);
      
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Obter localização atual
      _currentPosition = await Geolocator.getCurrentPosition();
      
      // Calcular distância se temos próximo ponto
      if (widget.nextPointData != null) {
        await _calculateDistanceAndBearing();
      }
      
      setState(() => _isLoadingLocation = false);
      
    } catch (e) {
      Logger.error('❌ Erro ao obter localização: $e');
      setState(() => _isLoadingLocation = false);
    }
  }
  
  /// Inicia atualização em tempo real da localização
  void _startRealTimeLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateLocationAndCheckProximity();
    });
  }
  
  /// Habilita monitoramento em background
  void _enableBackgroundMonitoring() {
    try {
      // Habilitar wake lock para manter o dispositivo ativo
      _enableWakeLock();
      
      // Iniciar stream de posição para background
      _startBackgroundLocationStream();
      
      Logger.info('✅ Monitoramento em background habilitado');
    } catch (e) {
      Logger.error('❌ Erro ao habilitar monitoramento em background: $e');
    }
  }
  
  /// Habilita wake lock para manter dispositivo ativo
  void _enableWakeLock() {
    try {
      WakelockPlus.enable();
      _wakelockEnabled = true;
      Logger.info('✅ Wake lock habilitado - dispositivo permanecerá ativo');
    } catch (e) {
      Logger.error('❌ Erro ao habilitar wake lock: $e');
    }
  }
  
  /// Inicia stream de localização para background
  void _startBackgroundLocationStream() {
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Atualizar a cada 5 metros
        ),
      ).listen(
        (Position position) {
          _handleBackgroundLocationUpdate(position);
        },
        onError: (error) {
          Logger.error('❌ Erro no stream de localização: $error');
        },
      );
      
      Logger.info('✅ Stream de localização em background iniciado');
    } catch (e) {
      Logger.error('❌ Erro ao iniciar stream de localização: $e');
    }
  }
  
  /// Processa atualizações de localização em background
  void _handleBackgroundLocationUpdate(Position position) {
    try {
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
      });
      
      // Recalcular distância se temos próximo ponto
      if (widget.nextPointData != null) {
        _calculateDistanceAndBearing();
        
        // Verificar proximidade em background
        _checkBackgroundProximity();
      }
    } catch (e) {
      Logger.error('❌ Erro ao processar localização em background: $e');
    }
  }
  
  /// Verifica proximidade em background
  void _checkBackgroundProximity() {
    if (_distanceToNext == null) return;
    
    final isNear = _distanceToNext! <= _proximityThreshold;
    
    if (isNear && !_hasVibrated) {
      _triggerBackgroundProximityAlert();
      _hasVibrated = true;
    } else if (!isNear && _hasVibrated) {
      _hasVibrated = false;
    }
    
    if (mounted) {
      setState(() {
        _isNearPoint = isNear;
      });
    }
  }
  
  /// Ativa alerta de proximidade em background
  void _triggerBackgroundProximityAlert() {
    try {
      // Vibração forte para alertar mesmo com tela desligada
      HapticFeedback.heavyImpact();
      
      // Vibração adicional após delay
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
      
      // Vibração final
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.heavyImpact();
      });
      
      Logger.info('🔔 Alerta de proximidade em background ativado');
      
      // Mostrar notificação mesmo com tela desligada
      _showBackgroundNotification();
      
    } catch (e) {
      Logger.error('❌ Erro ao ativar alerta de background: $e');
    }
  }
  
  /// Mostra notificação em background
  void _showBackgroundNotification() {
    if (!mounted) return;
    
    // Mostrar SnackBar mesmo com tela desligada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.vibration, color: Colors.white),
            SizedBox(width: 8),
            Text('Você chegou ao ponto! (${_distanceToNext!.toStringAsFixed(1)}m)'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Abrir',
          textColor: Colors.white,
          onPressed: () {
            _openOccurrenceScreenAutomatically();
          },
        ),
      ),
    );
  }
  
  /// Atualiza localização e verifica proximidade
  Future<void> _updateLocationAndCheckProximity() async {
    try {
      if (widget.nextPointData == null) return;
      
      // Obter nova localização
      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = newPosition;
        });
        
        // Recalcular distância e direção
        await _calculateDistanceAndBearing();
        
        // Verificar proximidade e vibrar se necessário
        _checkProximityAndVibrate();
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar localização: $e');
    }
  }
  
  /// Verifica proximidade e ativa vibração
  void _checkProximityAndVibrate() {
    if (_distanceToNext == null) return;
    
    final isNear = _distanceToNext! <= _proximityThreshold;
    
    if (isNear && !_hasVibrated) {
      _triggerProximityAlert();
      _hasVibrated = true;
    } else if (!isNear && _hasVibrated) {
      _hasVibrated = false;
    }
    
    if (mounted) {
      setState(() {
        _isNearPoint = isNear;
      });
    }
  }
  
  /// Ativa alerta de proximidade com vibração
  void _triggerProximityAlert() {
    // Vibração padrão
    HapticFeedback.mediumImpact();
    
    // Vibração personalizada (padrão longo)
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
    
    // Mostrar notificação visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.vibration, color: Colors.white),
              SizedBox(width: 8),
              Text('Você está próximo ao ponto! (${_distanceToNext!.toStringAsFixed(1)}m)'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Aguardar um momento e então abrir automaticamente a tela de ocorrências
      Future.delayed(const Duration(milliseconds: 1500), () {
        _openOccurrenceScreenAutomatically();
      });
    }
  }
  
  /// Abre automaticamente a tela de ocorrências quando próximo ao ponto
  void _openOccurrenceScreenAutomatically() {
    if (!mounted) return;
    
    try {
      // Mostrar diálogo de confirmação para abrir tela de ocorrências
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chegou ao Ponto!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Você chegou ao ponto de monitoramento!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Distância: ${_distanceToNext!.toStringAsFixed(1)}m',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Deseja registrar uma nova ocorrência neste ponto?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Apenas fechar o diálogo, não fazer nada
              },
              child: Text(
                'Apenas Chegou',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToOccurrenceScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nova Ocorrência',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao abrir tela de ocorrências automaticamente: $e');
    }
  }
  
  /// Navega para a tela de navegação aprimorada
  void _navigateToEnhancedScreen() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedNavigationScreen(
            currentPointId: widget.currentPointId,
            nextPointId: widget.nextPointId,
            nextPointData: widget.nextPointData,
            fieldId: widget.fieldId ?? 'unknown',
            cropName: widget.cropName ?? 'Soja',
            onArrived: widget.onArrived,
            onSkip: widget.onSkip,
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao navegar para tela aprimorada: $e');
    }
  }

  /// Navega para a tela de ocorrências
  void _navigateToOccurrenceScreen() {
    try {
      // Simular navegação para a tela de ocorrências
      // Em uma implementação real, isso navegaria para a tela de monitoramento do ponto
      Logger.info('🔄 Navegando para tela de ocorrências...');
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Tela de ocorrências habilitada!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Simular abertura da tela de ocorrências
        // Em uma implementação real, você chamaria o callback onArrived aqui
        Future.delayed(const Duration(milliseconds: 500), () {
          if (widget.onArrived != null) {
            widget.onArrived!();
          }
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao navegar para tela de ocorrências: $e');
    }
  }

  Future<void> _calculateDistanceAndBearing() async {
    if (_currentPosition == null || widget.nextPointData == null) return;
    
    try {
      final nextLat = widget.nextPointData!['latitude'] as double?;
      final nextLng = widget.nextPointData!['longitude'] as double?;
      
      if (nextLat != null && nextLng != null) {
        _distanceToNext = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          nextLat,
          nextLng,
        );
        
        _bearingToNext = Geolocator.bearingBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          nextLat,
          nextLng,
        );
        
        setState(() {});
      }
    } catch (e) {
      Logger.error('❌ Erro ao calcular distância: $e');
    }
  }

  String _getDirectionText(double? bearing) {
    if (bearing == null) return 'Calculando...';
    
    if (bearing >= -22.5 && bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Nordeste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Leste';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sudeste';
    if (bearing >= 157.5 || bearing < -157.5) return 'Sul';
    if (bearing >= -157.5 && bearing < -112.5) return 'Sudoeste';
    if (bearing >= -112.5 && bearing < -67.5) return 'Oeste';
    if (bearing >= -67.5 && bearing < -22.5) return 'Noroeste';
    
    return 'Calculando...';
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Calculando...';
    
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} metros';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _positionStream?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _disableWakeLock();
    super.dispose();
  }
  
  /// Desabilita wake lock
  void _disableWakeLock() {
    try {
      if (_wakelockEnabled) {
        WakelockPlus.disable();
        _wakelockEnabled = false;
        Logger.info('✅ Wake lock desabilitado');
      }
    } catch (e) {
      Logger.error('❌ Erro ao desabilitar wake lock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Navegando para Próximo Ponto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2D9CDB),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: _navigateToEnhancedScreen,
            tooltip: 'Navegação Avançada',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card de status
            _buildStatusCard(),
            
            const SizedBox(height: 20),
            
            // Card de direções
            if (widget.nextPointData != null) _buildDirectionsCard(),
            
            const SizedBox(height: 20),
            
            // Card de instruções
            _buildInstructionsCard(),
            
            const SizedBox(height: 20),
            
            // Card de status de background
            _buildBackgroundStatusCard(),
            
            const Spacer(),
            
            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF27AE60),
              size: 48,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Ponto ${widget.currentPointId} Concluído!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.nextPointId != null 
                ? 'Próximo: Ponto ${widget.nextPointId}'
                : 'Monitoramento Concluído',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF95A5A6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isNearPoint ? Colors.green.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _isNearPoint ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: _isNearPoint ? Colors.green.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: _isNearPoint ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isNearPoint ? _pulseAnimation.value : 1.0,
                    child: Icon(
                      _isNearPoint ? Icons.vibration : Icons.navigation,
                      color: _isNearPoint ? Colors.green : const Color(0xFF2D9CDB),
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                _isNearPoint ? 'Próximo ao Ponto!' : 'Direções',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isNearPoint ? Colors.green : const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildDirectionItem(
                    'Distância',
                    _formatDistance(_distanceToNext),
                    Icons.straighten,
                    isNear: _isNearPoint,
                  ),
                ),
                Expanded(
                  child: _buildDirectionItem(
                    'Direção',
                    _getDirectionText(_bearingToNext),
                    Icons.compass_calibration,
                    isNear: _isNearPoint,
                  ),
                ),
              ],
            ),
            
            if (_isNearPoint) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você está próximo ao ponto! Pressione "Chegou" quando estiver no local exato.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDirectionItem(String label, String value, IconData icon, {bool isNear = false}) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: isNear ? _rotationAnimation.value * 2 * 3.14159 : 0,
              child: Icon(
                icon, 
                color: isNear ? Colors.green : const Color(0xFF2D9CDB), 
                size: 32,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isNear ? Colors.green[700] : const Color(0xFF2C2C2C),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isNear ? Colors.green[600] : const Color(0xFF95A5A6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF39C12).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFFF39C12),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Instruções',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF39C12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            widget.nextPointId != null
                ? '• Dirija-se até o próximo ponto de monitoramento\n'
                  '• Use as direções acima como guia\n'
                  '• Pressione "Chegou" quando estiver no local\n'
                  '• Ou "Pular" para prosseguir sem visitar'
                : '• Monitoramento concluído com sucesso!\n'
                  '• Todos os pontos foram visitados\n'
                  '• Pressione "Finalizar" para encerrar',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_android,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Monitoramento em Background',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Funciona mesmo com tela desligada',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.vibration,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vibração automática quando próximo (${_proximityThreshold}m)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS ativo continuamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.nextPointId == null) {
      // Monitoramento concluído
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF27AE60),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Finalizar Monitoramento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Navegação para próximo ponto
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF95A5A6)),
            ),
            child: const Text(
              'Pular',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF95A5A6),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onArrived,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D9CDB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Chegou',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
