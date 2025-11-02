

/// Implementação de um filtro de Kalman para suavizar coordenadas de GPS
/// Baseado em: https://en.wikipedia.org/wiki/Kalman_filter
class KalmanFilter {
  // Estado atual (posição estimada)
  double _x; // Latitude ou Longitude
  
  // Covariância do erro de estimativa
  double _p;
  
  // Ruído do processo (quanto maior, mais rápido o filtro se adapta a mudanças)
  final double _q;
  
  // Ruído da medição (quanto maior, menos confiança nas medições)
  final double _r;
  
  /// Construtor do filtro de Kalman
  /// [initialValue] - Valor inicial (latitude ou longitude)
  /// [initialError] - Erro inicial estimado
  /// [processNoise] - Ruído do processo (padrão: 1e-5)
  /// [measurementNoise] - Ruído da medição (padrão: 1e-2)
  KalmanFilter({
    required double initialValue,
    double initialError = 1.0,
    double processNoise = 1e-5,
    double measurementNoise = 1e-2,
  }) : _x = initialValue,
       _p = initialError,
       _q = processNoise,
       _r = measurementNoise;
  
  /// Atualiza o filtro com uma nova medição
  /// [measurement] - Nova medição (latitude ou longitude)
  /// Retorna o valor filtrado
  double update(double measurement) {
    // Predição
    // Como não temos modelo de movimento, a predição é igual ao estado anterior
    // Atualiza a covariância de erro
    _p = _p + _q;
    
    // Atualização
    // Ganho de Kalman
    final k = _p / (_p + _r);
    
    // Atualiza a estimativa com a medição
    _x = _x + k * (measurement - _x);
    
    // Atualiza a covariância do erro
    _p = (1 - k) * _p;
    
    return _x;
  }
  
  /// Retorna o valor atual filtrado sem atualização
  double get value => _x;
  
  /// Retorna a covariância do erro atual
  double get errorCovariance => _p;
  
  /// Reinicia o filtro com um novo valor
  void reset(double value) {
    _x = value;
    _p = 1.0;
  }
}

/// Filtro de Kalman para coordenadas GPS (latitude e longitude)
class GpsKalmanFilter {
  final KalmanFilter _latFilter;
  final KalmanFilter _lngFilter;
  
  /// Construtor do filtro de Kalman para GPS
  /// [initialLat] - Latitude inicial
  /// [initialLng] - Longitude inicial
  /// [initialError] - Erro inicial estimado
  /// [processNoise] - Ruído do processo (padrão: 1e-5)
  /// [measurementNoise] - Ruído da medição (padrão: 1e-2)
  GpsKalmanFilter({
    required double initialLat,
    required double initialLng,
    double initialError = 1.0,
    double processNoise = 1e-5,
    double measurementNoise = 1e-2,
  }) : _latFilter = KalmanFilter(
         initialValue: initialLat,
         initialError: initialError,
         processNoise: processNoise,
         measurementNoise: measurementNoise,
       ),
       _lngFilter = KalmanFilter(
         initialValue: initialLng,
         initialError: initialError,
         processNoise: processNoise,
         measurementNoise: measurementNoise,
       );
  
  /// Atualiza o filtro com novas coordenadas GPS
  /// [lat] - Nova latitude
  /// [lng] - Nova longitude
  /// Retorna um Map com as coordenadas filtradas
  Map<String, double> update(double lat, double lng) {
    final filteredLat = _latFilter.update(lat);
    final filteredLng = _lngFilter.update(lng);
    
    return {
      'latitude': filteredLat,
      'longitude': filteredLng,
    };
  }
  
  /// Retorna as coordenadas atuais filtradas
  Map<String, double> get currentPosition => {
    'latitude': _latFilter.value,
    'longitude': _lngFilter.value,
  };
  
  /// Reinicia o filtro com novas coordenadas
  void reset(double lat, double lng) {
    _latFilter.reset(lat);
    _lngFilter.reset(lng);
  }
}
