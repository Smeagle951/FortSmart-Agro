import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Serviço para rastreamento GPS em tempo real durante avaliação de campo
class SoilGpsTrackingService extends ChangeNotifier {
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _trajeto = [];
  List<LatLng> _pontosColetados = [];
  Position? _currentPosition;
  bool _isTracking = false;
  double _distanciaTotal = 0.0;
  DateTime? _inicioTrajeto;
  Timer? _timer;
  int _tempoDecorrido = 0; // em segundos

  // Configurações
  static const double _distanciaMinimaPontos = 5.0; // metros
  static const Duration _intervaloAtualizacao = Duration(seconds: 2);
  static const double _precisaoMinima = 10.0; // metros

  // Getters
  List<LatLng> get trajeto => List.unmodifiable(_trajeto);
  List<LatLng> get pontosColetados => List.unmodifiable(_pontosColetados);
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  double get distanciaTotal => _distanciaTotal;
  int get tempoDecorrido => _tempoDecorrido;
  String get tempoFormatado => _formatarTempo(_tempoDecorrido);

  /// Inicia o rastreamento GPS
  Future<bool> iniciarRastreamento() async {
    try {
      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização permanentemente negada');
      }

      // Verifica se GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      // Limpa dados anteriores
      _limparDados();

      // Inicia stream de posições
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // 1 metro
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          if (kDebugMode) {
            print('Erro GPS: $error');
          }
        },
      );

      _isTracking = true;
      _inicioTrajeto = DateTime.now();
      
      // Inicia timer para tempo decorrido
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _tempoDecorrido++;
        notifyListeners();
      });

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao iniciar rastreamento: $e');
      }
      return false;
    }
  }

  /// Para o rastreamento GPS
  void pararRastreamento() {
    _positionStream?.cancel();
    _timer?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  /// Adiciona um ponto de coleta manual
  void adicionarPontoColeta() {
    if (_currentPosition != null) {
      final ponto = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _pontosColetados.add(ponto);
      notifyListeners();
      
      if (kDebugMode) {
        print('Ponto de coleta adicionado: ${_pontosColetados.length}');
      }
    }
  }

  /// Adiciona um ponto de coleta com penetrometria
  void adicionarPontoComMedicao(double penetrometria) {
    if (_currentPosition != null) {
      final ponto = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _pontosColetados.add(ponto);
      notifyListeners();
      
      if (kDebugMode) {
        print('Ponto com medição adicionado: $penetrometria MPa');
      }
    }
  }

  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    // Verifica precisão
    if (position.accuracy > _precisaoMinima) {
      return;
    }

    _currentPosition = position;
    final novaPosicao = LatLng(position.latitude, position.longitude);

    // Adiciona ao trajeto se for diferente da última posição
    if (_trajeto.isEmpty || _distanciaDaUltimaPosicao(novaPosicao) > 1.0) {
      _trajeto.add(novaPosicao);
      _calcularDistanciaTotal();
      notifyListeners();
    }
  }

  /// Calcula distância da última posição no trajeto
  double _distanciaDaUltimaPosicao(LatLng novaPosicao) {
    if (_trajeto.isEmpty) return double.infinity;
    
    final ultimaPosicao = _trajeto.last;
    return _calcularDistancia(ultimaPosicao, novaPosicao);
  }

  /// Calcula distância total percorrida
  void _calcularDistanciaTotal() {
    if (_trajeto.length < 2) {
      _distanciaTotal = 0.0;
      return;
    }

    double total = 0.0;
    for (int i = 1; i < _trajeto.length; i++) {
      total += _calcularDistancia(_trajeto[i - 1], _trajeto[i]);
    }
    _distanciaTotal = total;
  }

  /// Calcula distância entre dois pontos usando Haversine
  double _calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double earthRadius = 6371000; // metros
    
    double dLat = _toRadians(ponto2.latitude - ponto1.latitude);
    double dLon = _toRadians(ponto2.longitude - ponto1.longitude);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_toRadians(ponto1.latitude)) * cos(_toRadians(ponto2.latitude)) *
               sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Formata tempo em HH:MM:SS
  String _formatarTempo(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segs = segundos % 60;
    
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    } else {
      return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    }
  }

  /// Limpa todos os dados
  void _limparDados() {
    _trajeto.clear();
    _pontosColetados.clear();
    _distanciaTotal = 0.0;
    _tempoDecorrido = 0;
    _inicioTrajeto = null;
  }

  /// Exporta dados do trajeto
  Map<String, dynamic> exportarDados() {
    return {
      'inicio': _inicioTrajeto?.toIso8601String(),
      'fim': DateTime.now().toIso8601String(),
      'duracao_segundos': _tempoDecorrido,
      'distancia_metros': _distanciaTotal,
      'pontos_trajeto': _trajeto.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
      'pontos_coletados': _pontosColetados.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
    };
  }

  /// Calcula estatísticas do trajeto
  Map<String, dynamic> calcularEstatisticas() {
    if (_trajeto.isEmpty) {
      return {
        'distancia_total': 0.0,
        'tempo_total': 0,
        'velocidade_media': 0.0,
        'pontos_coletados': 0,
        'densidade_pontos': 0.0,
      };
    }

    final velocidadeMedia = _distanciaTotal > 0 && _tempoDecorrido > 0
        ? (_distanciaTotal / _tempoDecorrido) * 3.6 // km/h
        : 0.0;

    final densidadePontos = _distanciaTotal > 0
        ? (_pontosColetados.length / (_distanciaTotal / 1000)) // pontos por km
        : 0.0;

    return {
      'distancia_total': _distanciaTotal,
      'tempo_total': _tempoDecorrido,
      'velocidade_media': velocidadeMedia,
      'pontos_coletados': _pontosColetados.length,
      'densidade_pontos': densidadePontos,
    };
  }

  @override
  void dispose() {
    pararRastreamento();
    super.dispose();
  }
}

/// Serviço para integração com penetrômetro via Bluetooth
class SoilPenetrometerBluetoothService {
  // Placeholder para integração futura com Bluetooth
  // Esta classe pode ser expandida quando houver integração real
  
  static bool _isConnected = false;
  static StreamController<double>? _penetrometriaStream;

  /// Simula conexão com penetrômetro
  static Future<bool> conectar() async {
    // Simula delay de conexão
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
    return true;
  }

  /// Simula desconexão
  static void desconectar() {
    _isConnected = false;
    _penetrometriaStream?.close();
    _penetrometriaStream = null;
  }

  /// Verifica se está conectado
  static bool get isConnected => _isConnected;

  /// Stream de leituras de penetrometria
  static Stream<double>? get penetrometriaStream => _penetrometriaStream?.stream;

  /// Simula leitura de penetrometria
  static void simularLeitura() {
    if (!_isConnected) return;
    
    _penetrometriaStream ??= StreamController<double>.broadcast();
    
    // Simula leitura aleatória entre 0.5 e 4.0 MPa
    final random = Random();
    final leitura = 0.5 + (random.nextDouble() * 3.5);
    _penetrometriaStream!.add(leitura);
  }

  /// Para simulação
  static void pararSimulacao() {
    _penetrometriaStream?.close();
    _penetrometriaStream = null;
  }
}

