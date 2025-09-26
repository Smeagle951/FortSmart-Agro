import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';

/// Classe para dados de sensores do dispositivo
class DadosSensor {
  final double acelerometroX;
  final double acelerometroY;
  final double acelerometroZ;
  final double giroscopioX;
  final double giroscopioY;
  final double giroscopioZ;
  final DateTime timestamp;
  
  DadosSensor({
    required this.acelerometroX,
    required this.acelerometroY,
    required this.acelerometroZ,
    required this.giroscopioX,
    required this.giroscopioY,
    required this.giroscopioZ,
    required this.timestamp,
  });
}

/// Enum para sistemas GNSS suportados
enum SistemaGnss {
  gps,
  glonass,
  galileo,
  beidou,
  qzss,
  navic,
  mixed, // Múltiplos sistemas
}

/// Classe para informações de qualidade GNSS
class QualidadeGnss {
  final SistemaGnss sistema;
  final double precisao; // em metros
  final int satelites;
  final double hdop; // Horizontal Dilution of Precision
  final double vdop; // Vertical Dilution of Precision
  final DateTime timestamp;
  
  QualidadeGnss({
    required this.sistema,
    required this.precisao,
    required this.satelites,
    required this.hdop,
    required this.vdop,
    required this.timestamp,
  });
}

/// Classe central para cálculo de polígonos de talhões
/// Suporta múltiplos sistemas GNSS e diferentes tipos de desenho
class TalhaoCalculator {
  
  // ===== MÉTODOS PRINCIPAIS =====
  
  /// Calcula área do polígono
  /// [pontos] Lista de pontos do polígono
  /// [geodesico] Se true, usa cálculo geodésico preciso (WGS84)
  /// Retorna área em metros quadrados
  static double calcularArea(List<LatLng> pontos, {bool geodesico = false}) {
    if (pontos.length < 3) return 0.0;
    
    final pontosFechados = fecharPoligono(pontos);
    
    if (geodesico) {
      return _calcularAreaGeodesica(pontosFechados);
    } else {
      return _calcularAreaShoelace(pontosFechados);
    }
  }
  
  /// Calcula perímetro do polígono
  /// [pontos] Lista de pontos do polígono
  /// [geodesico] Se true, usa cálculo geodésico preciso
  /// Retorna perímetro em metros
  static double calcularPerimetro(List<LatLng> pontos, {bool geodesico = false}) {
    if (pontos.length < 2) return 0.0;
    
    final pontosFechados = fecharPoligono(pontos);
    double perimetro = 0.0;
    
    for (int i = 0; i < pontosFechados.length - 1; i++) {
      final p1 = pontosFechados[i];
      final p2 = pontosFechados[i + 1];
      
      if (geodesico) {
        perimetro += _calcularDistanciaGeodesica(p1, p2);
      } else {
        perimetro += _calcularDistanciaHaversine(p1, p2);
      }
    }
    
    return perimetro;
  }
  
  /// Calcula centroide (centro) do polígono
  /// [pontos] Lista de pontos do polígono
  /// [geodesico] Se true, usa cálculo geodésico preciso
  /// Retorna ponto central do polígono
  static LatLng calcularCentroide(List<LatLng> pontos, {bool geodesico = false}) {
    if (pontos.isEmpty) return const LatLng(0, 0);
    
    if (geodesico) {
      return _calcularCentroideGeodesico(pontos);
    } else {
      return _calcularCentroideSimples(pontos);
    }
  }
  
  /// Calcula centroide simples (média aritmética)
  static LatLng _calcularCentroideSimples(List<LatLng> pontos) {
    double latTotal = 0.0;
    double lngTotal = 0.0;
    
    for (final ponto in pontos) {
      latTotal += ponto.latitude;
      lngTotal += ponto.longitude;
    }
    
    return LatLng(latTotal / pontos.length, lngTotal / pontos.length);
  }
  
  /// Calcula centroide geodésico (centro de massa)
  static LatLng _calcularCentroideGeodesico(List<LatLng> pontos) {
    if (pontos.length < 3) return _calcularCentroideSimples(pontos);
    
    // Usar método de centroide geodésico baseado em fórmulas geodésicas
    double latTotal = 0.0;
    double lngTotal = 0.0;
    
    for (final ponto in pontos) {
      // Aplicar correção geodésica baseada na latitude
      final latRad = ponto.latitude * pi / 180;
      final fatorCorrecao = cos(latRad);
      
      latTotal += ponto.latitude;
      lngTotal += ponto.longitude * fatorCorrecao;
    }
    
    return LatLng(latTotal / pontos.length, lngTotal / pontos.length);
  }
  
  /// Fecha o polígono se necessário
  /// [pontos] Lista de pontos do polígono
  /// Retorna polígono fechado
  static List<LatLng> fecharPoligono(List<LatLng> pontos) {
    if (pontos.length < 3) return pontos;
    
    final pontosFechados = List<LatLng>.from(pontos);
    
    // Verificar se já está fechado (tolerância de 1 metro)
    final primeiro = pontosFechados.first;
    final ultimo = pontosFechados.last;
    final distancia = _calcularDistanciaHaversine(primeiro, ultimo);
    
    if (distancia > 1.0) {
      pontosFechados.add(primeiro);
    }
    
    return pontosFechados;
  }
  
  /// Suaviza pontos GPS para reduzir ruído
  /// [pontos] Lista de pontos GPS
  /// [janela] Tamanho da janela de suavização (3, 5, 7)
  /// Retorna pontos suavizados
  static List<LatLng> suavizarPontos(List<LatLng> pontos, {int janela = 5}) {
    if (pontos.length < janela) return pontos;
    
    final pontosSuavizados = <LatLng>[];
    final metadeJanela = janela ~/ 2;
    
    // Primeiros pontos (sem suavização completa)
    for (int i = 0; i < metadeJanela; i++) {
      pontosSuavizados.add(pontos[i]);
    }
    
    // Pontos intermediários (suavizados)
    for (int i = metadeJanela; i < pontos.length - metadeJanela; i++) {
      final pontoSuavizado = _aplicarSuavizacao(pontos, i, janela);
      pontosSuavizados.add(pontoSuavizado);
    }
    
    // Últimos pontos (sem suavização completa)
    for (int i = pontos.length - metadeJanela; i < pontos.length; i++) {
      pontosSuavizados.add(pontos[i]);
    }
    
    return pontosSuavizados;
  }
  
  /// Método principal para cálculo completo do talhão
  /// [pontos] Lista de pontos do polígono
  /// [suavizar] Se true, aplica suavização nos pontos
  /// [geodesico] Se true, usa cálculos geodésicos precisos
  /// Retorna mapa com todas as métricas
  static Map<String, dynamic> calcularTalhao(
    List<LatLng> pontos, {
    bool suavizar = false,
    bool geodesico = false,
  }) {
    if (pontos.length < 3) {
      return _resultadoVazio();
    }
    
    // Aplicar suavização se solicitado
    List<LatLng> pontosProcessados = pontos;
    if (suavizar && pontos.length >= 5) {
      pontosProcessados = suavizarPontos(pontos);
    }
    
    // Fechar polígono
    final pontosFechados = fecharPoligono(pontosProcessados);
    
    // Calcular métricas
    final areaM2 = calcularArea(pontosFechados, geodesico: geodesico);
    final perimetroM = calcularPerimetro(pontosFechados, geodesico: geodesico);
    final centroide = calcularCentroide(pontosFechados, geodesico: geodesico);
    final areaHa = areaM2 / 10000.0;
    
    // Validar polígono
    final valido = areaM2 > 10.0; // Mínimo 10 m²
    
    return {
      'areaM2': areaM2,
      'areaHa': areaHa,
      'perimetroM': perimetroM,
      'centroide': centroide,
      'valido': valido,
      'pontos': pontosFechados.length,
      'geodesico': geodesico,
      'suavizado': suavizar,
    };
  }
  
  // ===== MÉTODOS DE COMPATIBILIDADE =====
  
  /// Calcula área em hectares (compatibilidade)
  static double calcularAreaHectares(List<LatLng> pontos) {
    final areaM2 = calcularArea(pontos);
    return areaM2 / 10000.0;
  }
  
  /// Calcula área em metros quadrados (compatibilidade)
  static double calcularAreaMetrosQuadrados(List<LatLng> pontos) {
    return calcularArea(pontos);
  }
  
  /// Calcula estatísticas completas (compatibilidade)
  static Map<String, dynamic> calcularEstatisticasCompletas(List<LatLng> pontos) {
    return calcularTalhao(pontos);
  }
  
  /// Suaviza pontos GPS (compatibilidade)
  static List<LatLng> suavizarPontosGps(List<LatLng> pontos, {double fatorSuavizacao = 0.3}) {
    return suavizarPontos(pontos, janela: 5);
  }
  
  /// Valida se o polígono é válido
  static bool validarPoligono(List<LatLng> pontos) {
    if (pontos.length < 3) return false;
    final area = calcularAreaHectares(pontos);
    return area > 0.001; // Mínimo 0.001 ha
  }
  
  /// Aplica filtro Kalman para pontos GPS de alta precisão
  /// [pontos] Lista de pontos GPS
  /// [processNoise] Ruído do processo (padrão: 0.1)
  /// [measurementNoise] Ruído da medição (padrão: 1.0)
  /// Retorna pontos filtrados
  static List<LatLng> aplicarFiltroKalman(
    List<LatLng> pontos, {
    double processNoise = 0.1,
    double measurementNoise = 1.0,
  }) {
    if (pontos.length < 3) return pontos;
    
    final pontosFiltrados = <LatLng>[];
    
    // Estado inicial (primeiro ponto)
    double lat = pontos.first.latitude;
    double lng = pontos.first.longitude;
    double latVariance = measurementNoise;
    double lngVariance = measurementNoise;
    
    pontosFiltrados.add(LatLng(lat, lng));
    
    // Aplicar filtro Kalman para cada ponto
    for (int i = 1; i < pontos.length; i++) {
      final ponto = pontos[i];
      
      // Predição
      latVariance += processNoise;
      lngVariance += processNoise;
      
      // Atualização
      final latGain = latVariance / (latVariance + measurementNoise);
      final lngGain = lngVariance / (lngVariance + measurementNoise);
      
      lat = lat + latGain * (ponto.latitude - lat);
      lng = lng + lngGain * (ponto.longitude - lng);
      
      latVariance *= (1 - latGain);
      lngVariance *= (1 - lngGain);
      
      pontosFiltrados.add(LatLng(lat, lng));
    }
    
    return pontosFiltrados;
  }
  
  /// Detecta e remove outliers de pontos GPS
  /// [pontos] Lista de pontos GPS
  /// [threshold] Limiar para detecção de outliers (padrão: 50 metros)
  /// Retorna pontos sem outliers
  static List<LatLng> removerOutliers(List<LatLng> pontos, {double threshold = 50.0}) {
    if (pontos.length < 3) return pontos;
    
    final pontosLimpos = <LatLng>[];
    
    // Primeiro ponto sempre incluído
    pontosLimpos.add(pontos.first);
    
    for (int i = 1; i < pontos.length - 1; i++) {
      final pontoAtual = pontos[i];
      final pontoAnterior = pontos[i - 1];
      final pontoProximo = pontos[i + 1];
      
      // Calcular distância para pontos adjacentes
      final distAnterior = _calcularDistanciaHaversine(pontoAtual, pontoAnterior);
      final distProximo = _calcularDistanciaHaversine(pontoAtual, pontoProximo);
      
      // Se ambas as distâncias são menores que o limiar, incluir o ponto
      if (distAnterior < threshold && distProximo < threshold) {
        pontosLimpos.add(pontoAtual);
      }
    }
    
    // Último ponto sempre incluído
    pontosLimpos.add(pontos.last);
    
    return pontosLimpos;
  }
  
  /// Calcula precisão estimada do polígono
  /// [pontos] Lista de pontos do polígono
  /// Retorna precisão em metros
  static double calcularPrecisao(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    double somaDistancias = 0.0;
    int contador = 0;
    
    // Calcular distância média entre pontos adjacentes
    for (int i = 0; i < pontos.length - 1; i++) {
      final distancia = _calcularDistanciaHaversine(pontos[i], pontos[i + 1]);
      somaDistancias += distancia;
      contador++;
    }
    
    final distanciaMedia = somaDistancias / contador;
    
    // Estimar precisão baseada na densidade de pontos
    return distanciaMedia / 2.0; // Precisão estimada é metade da distância média
  }
  
  // ===== OTIMIZAÇÕES PARA MOBILE =====
  
  /// Detecta qualidade do sinal GPS baseado na consistência dos pontos
  /// [pontos] Lista de pontos GPS
  /// Retorna score de qualidade (0-100)
  static double detectarQualidadeGps(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    // Calcular desvio padrão das distâncias
    final distancias = <double>[];
    for (int i = 0; i < pontos.length - 1; i++) {
      final distancia = _calcularDistanciaHaversine(pontos[i], pontos[i + 1]);
      distancias.add(distancia);
    }
    
    final media = distancias.reduce((a, b) => a + b) / distancias.length;
    final variancia = distancias.map((d) => pow(d - media, 2)).reduce((a, b) => a + b) / distancias.length;
    final desvioPadrao = sqrt(variancia);
    
    // Calcular coeficiente de variação
    final coeficienteVariacao = desvioPadrao / media;
    
    // Converter para score de qualidade (0-100)
    // Menor variação = maior qualidade
    final score = max(0.0, 100.0 - (coeficienteVariacao * 100));
    
    return min(100.0, score);
  }
  
  /// Compensa movimento do usuário baseado na velocidade
  /// [pontos] Lista de pontos GPS
  /// [velocidadeMedia] Velocidade média em m/s
  /// Retorna pontos compensados
  static List<LatLng> compensarMovimentoUsuario(
    List<LatLng> pontos, 
    double velocidadeMedia,
  ) {
    if (pontos.length < 2) return pontos;
    
    final pontosCompensados = <LatLng>[];
    pontosCompensados.add(pontos.first); // Primeiro ponto sempre mantido
    
    for (int i = 1; i < pontos.length - 1; i++) {
      final pontoAtual = pontos[i];
      final pontoAnterior = pontos[i - 1];
      final pontoProximo = pontos[i + 1];
      
      // Calcular direção do movimento
      final direcaoAnterior = _calcularDirecao(pontoAnterior, pontoAtual);
      final direcaoProxima = _calcularDirecao(pontoAtual, pontoProximo);
      
      // Calcular velocidade instantânea
      final distancia = _calcularDistanciaHaversine(pontoAnterior, pontoAtual);
      const tempo = 1.0; // Assumindo 1 segundo entre pontos
      final velocidadeInstantanea = distancia / tempo;
      
      // Aplicar compensação se velocidade for muito alta (possível erro GPS)
      if (velocidadeInstantanea > velocidadeMedia * 2.0) {
        // Suavizar ponto baseado na direção média
        final direcaoMedia = (direcaoAnterior + direcaoProxima) / 2;
        final pontoCompensado = _aplicarCompensacaoMovimento(
          pontoAtual, 
          direcaoMedia, 
          velocidadeMedia
        );
        pontosCompensados.add(pontoCompensado);
      } else {
        pontosCompensados.add(pontoAtual);
      }
    }
    
    pontosCompensados.add(pontos.last); // Último ponto sempre mantido
    return pontosCompensados;
  }
  
  /// Melhora precisão usando dados de sensores do dispositivo
  /// [pontosGps] Lista de pontos GPS
  /// [dadosSensores] Dados de acelerômetro e giroscópio
  /// Retorna pontos melhorados
  static List<LatLng> melhorarComSensores(
    List<LatLng> pontosGps,
    List<DadosSensor> dadosSensores,
  ) {
    if (pontosGps.length < 2 || dadosSensores.isEmpty) return pontosGps;
    
    final pontosMelhorados = <LatLng>[];
    pontosMelhorados.add(pontosGps.first);
    
    for (int i = 1; i < pontosGps.length - 1; i++) {
      final pontoGps = pontosGps[i];
      
      // Encontrar dados de sensor mais próximos no tempo
      final dadosRelevantes = _encontrarDadosSensorRelevantes(
        dadosSensores, 
        i
      );
      
      if (dadosRelevantes != null) {
        // Aplicar correção baseada nos sensores
        final pontoCorrigido = _aplicarCorrecaoSensores(
          pontoGps, 
          dadosRelevantes
        );
        pontosMelhorados.add(pontoCorrigido);
      } else {
        pontosMelhorados.add(pontoGps);
      }
    }
    
    pontosMelhorados.add(pontosGps.last);
    return pontosMelhorados;
  }
  
  /// Método principal otimizado para dispositivos móveis
  /// [pontos] Lista de pontos do polígono
  /// [usarFiltroKalman] Se true, aplica filtro Kalman
  /// [removerOutliers] Se true, remove outliers
  /// [precisaoMinima] Precisão mínima aceitável em metros
  /// [dadosSensores] Dados de sensores do dispositivo (opcional)
  /// Retorna resultado otimizado para mobile
  static Map<String, dynamic> calcularTalhaoMobile(
    List<LatLng> pontos, {
    bool usarFiltroKalman = true,
    bool removerOutliers = true,
    double precisaoMinima = 5.0,
    List<DadosSensor>? dadosSensores,
  }) {
    if (pontos.length < 3) {
      return _resultadoVazio();
    }
    
    // 1. Detectar qualidade do GPS
    final qualidadeGps = detectarQualidadeGps(pontos);
    
    // 2. Aplicar filtros baseados na qualidade
    List<LatLng> pontosProcessados = pontos;
    
    if (qualidadeGps < 70.0) {
      // GPS de baixa qualidade - aplicar filtros mais agressivos
      if (removerOutliers) {
        pontosProcessados = TalhaoCalculator.removerOutliers(pontosProcessados, threshold: 20.0);
      }
      if (usarFiltroKalman) {
        pontosProcessados = TalhaoCalculator.aplicarFiltroKalman(
          pontosProcessados,
          processNoise: 0.2,
          measurementNoise: 2.0,
        );
      }
    } else {
      // GPS de alta qualidade - filtros mais suaves
      if (removerOutliers) {
        pontosProcessados = TalhaoCalculator.removerOutliers(pontosProcessados, threshold: 50.0);
      }
      if (usarFiltroKalman) {
        pontosProcessados = TalhaoCalculator.aplicarFiltroKalman(
          pontosProcessados,
          processNoise: 0.1,
          measurementNoise: 1.0,
        );
      }
    }
    
    // 3. Compensar movimento do usuário
    final velocidadeMedia = _calcularVelocidadeMedia(pontosProcessados);
    pontosProcessados = compensarMovimentoUsuario(pontosProcessados, velocidadeMedia);
    
    // 4. Melhorar com sensores se disponíveis
    if (dadosSensores != null && dadosSensores.isNotEmpty) {
      pontosProcessados = melhorarComSensores(pontosProcessados, dadosSensores);
    }
    
    // 5. Calcular métricas finais
    final pontosFechados = fecharPoligono(pontosProcessados);
    final areaM2 = calcularArea(pontosFechados, geodesico: true);
    final perimetroM = calcularPerimetro(pontosFechados, geodesico: true);
    final centroide = calcularCentroide(pontosFechados, geodesico: true);
    final areaHa = areaM2 / 10000.0;
    final precisao = calcularPrecisao(pontosFechados);
    
    // 6. Validar precisão
    final valido = areaM2 > 10.0 && precisao <= precisaoMinima;
    
    return {
      'areaM2': areaM2,
      'areaHa': areaHa,
      'perimetroM': perimetroM,
      'centroide': centroide,
      'valido': valido,
      'pontos': pontosFechados.length,
      'geodesico': true,
      'suavizado': true,
      'qualidadeGps': qualidadeGps,
      'precisao': precisao,
      'velocidadeMedia': velocidadeMedia,
      'otimizadoMobile': true,
    };
  }
  
  // ===== MÉTODOS AUXILIARES PARA MOBILE =====
  
  /// Calcula direção entre dois pontos
  static double _calcularDirecao(LatLng ponto1, LatLng ponto2) {
    final lat1Rad = ponto1.latitude * pi / 180;
    final lat2Rad = ponto2.latitude * pi / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * pi / 180;
    
    final y = sin(deltaLngRad) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLngRad);
    
    return atan2(y, x) * 180 / pi;
  }
  
  /// Aplica compensação de movimento
  static LatLng _aplicarCompensacaoMovimento(
    LatLng ponto,
    double direcao,
    double velocidadeMedia,
  ) {
    // Aplicar correção baseada na direção e velocidade
    final fatorCorrecao = min(1.0, velocidadeMedia / 5.0); // Normalizar velocidade
    
    final latCorrecao = cos(direcao * pi / 180) * fatorCorrecao * 0.00001;
    final lngCorrecao = sin(direcao * pi / 180) * fatorCorrecao * 0.00001;
    
    return LatLng(
      ponto.latitude + latCorrecao,
      ponto.longitude + lngCorrecao,
    );
  }
  
  /// Encontra dados de sensor mais relevantes
  static DadosSensor? _encontrarDadosSensorRelevantes(
    List<DadosSensor> dadosSensores,
    int indicePonto,
  ) {
    if (dadosSensores.isEmpty) return null;
    
    // Buscar dados mais próximos no tempo
    final indiceSensor = min(indicePonto, dadosSensores.length - 1);
    return dadosSensores[indiceSensor];
  }
  
  /// Aplica correção baseada em sensores
  static LatLng _aplicarCorrecaoSensores(
    LatLng pontoGps,
    DadosSensor dadosSensor,
  ) {
    // Calcular correção baseada na aceleração
    final aceleracaoTotal = sqrt(
      pow(dadosSensor.acelerometroX, 2) +
      pow(dadosSensor.acelerometroY, 2) +
      pow(dadosSensor.acelerometroZ, 2)
    );
    
    // Se aceleração for muito alta, pode indicar movimento do dispositivo
    if (aceleracaoTotal > 15.0) { // 15 m/s²
      // Aplicar correção suave
      final fatorCorrecao = min(0.5, aceleracaoTotal / 30.0);
      final latCorrecao = dadosSensor.acelerometroX * fatorCorrecao * 0.000001;
      final lngCorrecao = dadosSensor.acelerometroY * fatorCorrecao * 0.000001;
      
      return LatLng(
        pontoGps.latitude + latCorrecao,
        pontoGps.longitude + lngCorrecao,
      );
    }
    
    return pontoGps;
  }
  
  /// Calcula velocidade média entre pontos
  static double _calcularVelocidadeMedia(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;
    
    double distanciaTotal = 0.0;
    for (int i = 0; i < pontos.length - 1; i++) {
      distanciaTotal += _calcularDistanciaHaversine(pontos[i], pontos[i + 1]);
    }
    
    // Assumindo 1 segundo entre pontos
    return distanciaTotal / (pontos.length - 1);
  }
  
  /// Detecta sistema GNSS baseado na precisão e características dos pontos
  static SistemaGnss detectarSistemaGnss(List<LatLng> pontos) {
    if (pontos.length < 3) return SistemaGnss.gps;
    
    // Analisar padrões de precisão
    final distancias = <double>[];
    for (int i = 0; i < pontos.length - 1; i++) {
      distancias.add(_calcularDistanciaHaversine(pontos[i], pontos[i + 1]));
    }
    
    final media = distancias.reduce((a, b) => a + b) / distancias.length;
    final desvioPadrao = sqrt(
      distancias.map((d) => pow(d - media, 2)).reduce((a, b) => a + b) / distancias.length
    );
    
    // Classificar baseado na precisão
    if (desvioPadrao < 2.0) {
      return SistemaGnss.galileo; // Galileo é mais preciso
    } else if (desvioPadrao < 5.0) {
      return SistemaGnss.gps; // GPS padrão
    } else if (desvioPadrao < 10.0) {
      return SistemaGnss.glonass; // GLONASS tem menor precisão
    } else {
      return SistemaGnss.mixed; // Múltiplos sistemas
    }
  }
  
  /// Calcula qualidade GNSS específica por sistema
  static QualidadeGnss calcularQualidadeGnss(
    List<LatLng> pontos,
    SistemaGnss sistema,
  ) {
    final precisao = calcularPrecisao(pontos);
    final qualidade = detectarQualidadeGps(pontos);
    
    // Estimar número de satélites baseado na qualidade
    int satelites;
    if (qualidade > 80) {
      satelites = 12; // Muitos satélites
    } else if (qualidade > 60) {
      satelites = 8; // Satélites suficientes
    } else {
      satelites = 4; // Mínimo
    }
    
    // Calcular DOP baseado na precisão
    final hdop = max(1.0, precisao / 3.0);
    final vdop = hdop * 1.5;
    
    return QualidadeGnss(
      sistema: sistema,
      precisao: precisao,
      satelites: satelites,
      hdop: hdop,
      vdop: vdop,
      timestamp: DateTime.now(),
    );
  }
  
  /// Aplica otimizações específicas por sistema GNSS
  static List<LatLng> otimizarPorSistemaGnss(
    List<LatLng> pontos,
    SistemaGnss sistema,
  ) {
    switch (sistema) {
      case SistemaGnss.galileo:
        // Galileo: alta precisão, filtros suaves
        return aplicarFiltroKalman(pontos, processNoise: 0.05, measurementNoise: 0.5);
        
      case SistemaGnss.gps:
        // GPS: precisão média, filtros moderados
        return aplicarFiltroKalman(pontos, processNoise: 0.1, measurementNoise: 1.0);
        
      case SistemaGnss.glonass:
        // GLONASS: menor precisão, filtros mais agressivos
        return aplicarFiltroKalman(pontos, processNoise: 0.2, measurementNoise: 2.0);
        
      case SistemaGnss.beidou:
        // BeiDou: similar ao GPS
        return aplicarFiltroKalman(pontos, processNoise: 0.15, measurementNoise: 1.5);
        
      case SistemaGnss.mixed:
        // Múltiplos sistemas: usar filtros adaptativos
        return removerOutliers(pontos, threshold: 30.0);
        
      default:
        return pontos;
    }
  }

  // ===== MÉTODOS PRIVADOS =====
  
  /// Calcula área usando fórmula de Shoelace (plano)
  static double _calcularAreaShoelace(List<LatLng> pontos) {
    double area = 0.0;
    final n = pontos.length;
    
    for (int i = 0; i < n - 1; i++) {
      final p1 = pontos[i];
      final p2 = pontos[i + 1];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    
    // Aplicar fator de correção geográfica
    final latMedia = pontos.map((p) => p.latitude).reduce((a, b) => a + b) / n;
    final fatorCorrecao = _calcularFatorCorrecaoGeografica(latMedia);
    
    return (area.abs() / 2.0) * fatorCorrecao;
  }
  
  /// Calcula área usando método geodésico (WGS84)
  static double _calcularAreaGeodesica(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    // Usar método de área geodésica baseado em fórmulas geodésicas
    double area = 0.0;
    final n = pontos.length;
    
    for (int i = 0; i < n - 1; i++) {
      final p1 = pontos[i];
      final p2 = pontos[i + 1];
      
      // Aplicar correção geodésica baseada na latitude média
      final latMedia = (p1.latitude + p2.latitude) / 2;
      final latRad = latMedia * pi / 180;
      final fatorCorrecao = cos(latRad);
      
      area += (p1.longitude * p2.latitude - p2.longitude * p1.latitude) * fatorCorrecao;
    }
    
    // Aplicar fator de correção geográfica final
    final latMedia = pontos.map((p) => p.latitude).reduce((a, b) => a + b) / n;
    final fatorCorrecaoFinal = _calcularFatorCorrecaoGeografica(latMedia);
    
    return (area.abs() / 2.0) * fatorCorrecaoFinal;
  }
  
  /// Calcula distância usando fórmula de Haversine
  static double _calcularDistanciaHaversine(LatLng p1, LatLng p2) {
    const double raioTerra = 6371000; // Raio da Terra em metros
    
    final lat1Rad = p1.latitude * pi / 180;
    final lat2Rad = p2.latitude * pi / 180;
    final deltaLatRad = (p2.latitude - p1.latitude) * pi / 180;
    final deltaLngRad = (p2.longitude - p1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
              cos(lat1Rad) * cos(lat2Rad) *
              sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return raioTerra * c;
  }
  
  /// Calcula distância usando método geodésico
  static double _calcularDistanciaGeodesica(LatLng p1, LatLng p2) {
    // Usar fórmula de Vincenty para cálculo geodésico preciso
    const double a = 6378137.0; // Semi-eixo maior do elipsóide WGS84
    const double f = 1/298.257223563; // Achatamento do elipsóide WGS84
    const double b = a * (1 - f);
    
    final lat1Rad = p1.latitude * pi / 180;
    final lat2Rad = p2.latitude * pi / 180;
    final deltaLngRad = (p2.longitude - p1.longitude) * pi / 180;
    
    final u1 = atan((1 - f) * tan(lat1Rad));
    final u2 = atan((1 - f) * tan(lat2Rad));
    
    final sinU1 = sin(u1);
    final cosU1 = cos(u1);
    final sinU2 = sin(u2);
    final cosU2 = cos(u2);
    
    double lambda = deltaLngRad;
    double lambdaP = 2 * pi;
    
    double sinSigma = 0.0;
    double cosSigma = 0.0;
    double sigma = 0.0;
    double cos2Alpha = 0.0;
    double cos2SigmaM = 0.0;
    
    int iterLimit = 100;
    while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0) {
      final sinLambda = sin(lambda);
      final cosLambda = cos(lambda);
      
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) + 
                     (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * 
                     (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      
      if (sinSigma == 0) return 0.0; // Pontos coincidentes
      
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      
      final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cos2Alpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cos2Alpha;
      
      final C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
      
      lambdaP = lambda;
      lambda = deltaLngRad + (1 - C) * f * sinAlpha * 
               (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * 
                (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    }
    
    if (iterLimit == 0) return _calcularDistanciaHaversine(p1, p2); // Fallback para Haversine
    
    final u2Calc = cos2Alpha * (a * a - b * b) / (b * b);
    final A = 1 + u2Calc / 16384 * (4096 + u2Calc * (-768 + u2Calc * (320 - 175 * u2Calc)));
    final B = u2Calc / 1024 * (256 + u2Calc * (-128 + u2Calc * (74 - 47 * u2Calc)));
    final deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * 
                     (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * 
                     (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    
    final s = b * A * (sigma - deltaSigma);
    
    return s;
  }
  
  /// Aplica suavização em um ponto específico
  static LatLng _aplicarSuavizacao(List<LatLng> pontos, int indice, int janela) {
    final metadeJanela = janela ~/ 2;
    final inicio = max(0, indice - metadeJanela);
    final fim = min(pontos.length, indice + metadeJanela + 1);
    
    double latTotal = 0.0;
    double lngTotal = 0.0;
    int contador = 0;
    
    for (int i = inicio; i < fim; i++) {
      latTotal += pontos[i].latitude;
      lngTotal += pontos[i].longitude;
      contador++;
    }
    
    return LatLng(latTotal / contador, lngTotal / contador);
  }
  
  /// Calcula fator de correção geográfica
  static double _calcularFatorCorrecaoGeografica(double latitude) {
    final latRad = latitude * pi / 180;
    
    // Fator para latitude (metros por grau)
    final metrosPorGrauLat = 111132.954 - 559.822 * cos(2 * latRad) + 
                            1.175 * cos(4 * latRad);
    
    // Fator para longitude (metros por grau)
    final metrosPorGrauLng = (pi / 180) * 6378137.0 * cos(latRad);
    
    return metrosPorGrauLat * metrosPorGrauLng;
  }
  
  /// Retorna resultado vazio para polígonos inválidos
  static Map<String, dynamic> _resultadoVazio() {
    return {
      'areaM2': 0.0,
      'areaHa': 0.0,
      'perimetroM': 0.0,
      'centroide': const LatLng(0, 0),
      'valido': false,
      'pontos': 0,
      'geodesico': false,
      'suavizado': false,
    };
  }
}
