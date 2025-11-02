import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_calculator.dart';

/// Serviço de navegação GPS para talhões
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();
  
  bool _initialized = false;
  bool _isNavigating = false;
  bool _isPaused = false;
  
  // Callbacks
  Function(Position)? _onLocationUpdate;
  Function()? _onStepCompleted;
  Function()? _onNavigationComplete;
  Function(String)? _onError;
  
  // Dados da navegação
  Position? _currentPosition;
  Position? _destinationPosition;
  List<NavigationStep> _routeSteps = [];
  int _currentStepIndex = 0;
  
  // Timer para atualizações
  Timer? _navigationTimer;
  StreamSubscription<Position>? _positionSubscription;

  /// Inicializa o serviço de navegação
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Verificar permissões de localização
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      _initialized = true;
    } catch (e) {
      throw Exception('Erro ao inicializar navegação: $e');
    }
  }

  /// Calcula rota até o destino
  Future<List<NavigationStep>> calculateRoute(
    Position start,
    Position destination,
  ) async {
    try {
      final startLatLng = LatLng(start.latitude, start.longitude);
      final destLatLng = LatLng(destination.latitude, destination.longitude);
      
      // Calcular distância total
      final totalDistance = GeoCalculator.calculateDistance(startLatLng, destLatLng);
      
      // Calcular direção inicial
      final initialBearing = GeoCalculator.calculateBearing(startLatLng, destLatLng);
      
      // Gerar passos de navegação baseados na distância
      final steps = <NavigationStep>[];
      
      if (totalDistance < 100) {
        // Muito próximo - apenas um passo
        steps.add(NavigationStep(
          instruction: 'Continue em frente até o talhão',
          distance: totalDistance,
          bearing: initialBearing,
          position: destLatLng,
        ));
      } else if (totalDistance < 500) {
        // Próximo - dividir em 2 passos
        final midPoint = _calculateMidPoint(startLatLng, destLatLng);
        steps.add(NavigationStep(
          instruction: 'Continue em direção ao talhão',
          distance: totalDistance / 2,
          bearing: initialBearing,
          position: midPoint,
        ));
        steps.add(NavigationStep(
          instruction: 'Continue até chegar ao talhão',
          distance: totalDistance / 2,
          bearing: initialBearing,
          position: destLatLng,
        ));
      } else {
        // Distante - dividir em múltiplos passos
        final stepCount = (totalDistance / 200).ceil(); // Passos de ~200m
        final stepDistance = totalDistance / stepCount;
        
        for (int i = 0; i < stepCount; i++) {
          final progress = (i + 1) / stepCount;
          final stepPosition = _interpolatePosition(startLatLng, destLatLng, progress);
          
          String instruction;
          if (i == 0) {
            instruction = 'Inicie a navegação em direção ao talhão';
          } else if (i == stepCount - 1) {
            instruction = 'Continue até chegar ao talhão';
          } else {
            instruction = 'Continue em direção ao talhão';
          }
          
          steps.add(NavigationStep(
            instruction: instruction,
            distance: stepDistance,
            bearing: initialBearing,
            position: stepPosition,
          ));
        }
      }
      
      return steps;
    } catch (e) {
      throw Exception('Erro ao calcular rota: $e');
    }
  }

  /// Inicia a navegação
  Future<void> startNavigation({
    required Function(Position) onLocationUpdate,
    required Function() onStepCompleted,
    required Function() onNavigationComplete,
    required Function(String) onError,
  }) async {
    if (_isNavigating) return;
    
    try {
      _onLocationUpdate = onLocationUpdate;
      _onStepCompleted = onStepCompleted;
      _onNavigationComplete = onNavigationComplete;
      _onError = onError;
      
      _isNavigating = true;
      _isPaused = false;
      _currentStepIndex = 0;
      
      // Iniciar stream de posição
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Atualizar a cada 5 metros
        ),
      ).listen(
        (position) {
          _currentPosition = position;
          _onLocationUpdate?.call(position);
          _checkStepCompletion();
        },
        onError: (error) {
          _onError?.call('Erro de GPS: $error');
        },
      );
      
    } catch (e) {
      _onError?.call('Erro ao iniciar navegação: $e');
    }
  }

  /// Pausa a navegação
  void pauseNavigation() {
    if (!_isNavigating) return;
    _isPaused = true;
  }

  /// Retoma a navegação
  void resumeNavigation() {
    if (!_isNavigating) return;
    _isPaused = false;
  }

  /// Para a navegação
  void stopNavigation() {
    _isNavigating = false;
    _isPaused = false;
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Verifica se um passo foi completado
  void _checkStepCompletion() {
    if (!_isNavigating || _isPaused || _currentPosition == null) return;
    if (_currentStepIndex >= _routeSteps.length) return;
    
    final currentStep = _routeSteps[_currentStepIndex];
    final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    
    // Verificar se chegou ao ponto do passo atual
    final distanceToStep = GeoCalculator.calculateDistance(currentLatLng, currentStep.position);
    
    if (distanceToStep < 20) { // Dentro de 20 metros
      _currentStepIndex++;
      _onStepCompleted?.call();
      
      // Verificar se chegou ao destino final
      if (_currentStepIndex >= _routeSteps.length) {
        _onNavigationComplete?.call();
        stopNavigation();
      }
    }
  }

  /// Calcula ponto médio entre duas posições
  LatLng _calculateMidPoint(LatLng start, LatLng end) {
    return LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );
  }

  /// Interpola posição entre dois pontos
  LatLng _interpolatePosition(LatLng start, LatLng end, double progress) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * progress,
      start.longitude + (end.longitude - start.longitude) * progress,
    );
  }

  /// Obtém instrução de direção baseada no bearing
  String getDirectionInstruction(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'Continue em direção ao Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Continue em direção ao Nordeste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Continue em direção ao Leste';
    if (bearing >= 112.5 && bearing < 157.5) return 'Continue em direção ao Sudeste';
    if (bearing >= 157.5 && bearing < 202.5) return 'Continue em direção ao Sul';
    if (bearing >= 202.5 && bearing < 247.5) return 'Continue em direção ao Sudoeste';
    if (bearing >= 247.5 && bearing < 292.5) return 'Continue em direção ao Oeste';
    if (bearing >= 292.5 && bearing < 337.5) return 'Continue em direção ao Noroeste';
    return 'Continue em direção ao destino';
  }

  /// Obtém ícone de direção
  String getDirectionIcon(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return '↑';
    if (bearing >= 22.5 && bearing < 67.5) return '↗';
    if (bearing >= 67.5 && bearing < 112.5) return '→';
    if (bearing >= 112.5 && bearing < 157.5) return '↘';
    if (bearing >= 157.5 && bearing < 202.5) return '↓';
    if (bearing >= 202.5 && bearing < 247.5) return '↙';
    if (bearing >= 247.5 && bearing < 292.5) return '←';
    if (bearing >= 292.5 && bearing < 337.5) return '↖';
    return '↑';
  }

  /// Getters
  bool get isNavigating => _isNavigating;
  bool get isPaused => _isPaused;
  Position? get currentPosition => _currentPosition;
  List<NavigationStep> get routeSteps => _routeSteps;
  int get currentStepIndex => _currentStepIndex;
}

/// Classe para representar um passo da navegação
class NavigationStep {
  final String instruction;
  final double distance;
  final double bearing;
  final LatLng position;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.bearing,
    required this.position,
  });
}
