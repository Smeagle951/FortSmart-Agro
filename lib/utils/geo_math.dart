import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Classe para coordenadas UTM
class CoordenadaUTM {
  final double x; // Easting (metros)
  final double y; // Northing (metros)
  
  CoordenadaUTM(this.x, this.y);
}

/// Enum para unidades de distância
enum UnidadeDistancia {
  metros,
  quilometros,
  milhas,
}

/// Classe utilitária para cálculos geoespaciais
/// Implementa funções para cálculo de área, perímetro e centroide
class GeoMath {
  /// Calcula a área de um polígono em hectares
  /// Usa fórmula de Shoelace com conversão UTM para máxima precisão
  static double calcularArea(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) return 0.0;
    
    // Normalizar pontos (remover duplicados e fechar polígono)
    final pontosNormalizados = _normalizarPontos(coordenadas);
    if (pontosNormalizados.length < 3) return 0.0;
    
    // Converter para coordenadas UTM para cálculos precisos
    final coordenadasUtm = _converterParaUTM(pontosNormalizados);
    
    // Implementação da fórmula de área de polígono (Shoelace formula)
    double area = 0.0;
    final n = coordenadasUtm.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      // Fórmula de Shoelace: área = 0.5 * |Σ(xi * yj - xj * yi)|
      area += coordenadasUtm[i].x * coordenadasUtm[j].y;
      area -= coordenadasUtm[j].x * coordenadasUtm[i].y;
    }
    
    area = area.abs() * 0.5; // Área em metros quadrados
    
    // Converter metros² para hectares (1 hectare = 10.000 m²)
    return area / 10000.0;
  }
  
  /// Calcula o perímetro de um polígono em metros usando fórmula de Haversine
  static double calcularPerimetro(List<LatLng> coordenadas) {
    if (coordenadas.length < 2) return 0.0;
    
    double perimetro = 0.0;
    
    for (int i = 0; i < coordenadas.length; i++) {
      final j = (i + 1) % coordenadas.length;
      perimetro += calcularDistancia(coordenadas[i], coordenadas[j]);
    }
    
    return perimetro;
  }
  
  /// Calcula o centroide (ponto central) de um polígono
  static LatLng calcularCentroide(List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) {
      throw ArgumentError('Lista de coordenadas vazia');
    }
    
    if (coordenadas.length == 1) {
      return coordenadas.first;
    }
    
    double lat = 0.0;
    double lng = 0.0;
    
    // Para polígonos simples, podemos usar a média das coordenadas
    for (final ponto in coordenadas) {
      lat += ponto.latitude;
      lng += ponto.longitude;
    }
    
    return LatLng(lat / coordenadas.length, lng / coordenadas.length);
  }
  
  /// Calcula a distância entre dois pontos em metros
  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  /// R = 6378137m (raio da Terra WGS84)
  static double calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double raioTerra = 6378137; // Raio da Terra WGS84 em metros
    
    final lat1Rad = ponto1.latitude * pi / 180;
    final lat2Rad = ponto2.latitude * pi / 180;
    final deltaLatRad = (ponto2.latitude - ponto1.latitude) * pi / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return raioTerra * c;
  }
  
  /// Calcula o fator de conversão para hectares baseado na latitude
  /// @deprecated Use o fator fixo de 111000 para consistência
  static double _calcularFatorConversao(double latitude) {
    // Aproximação do fator de conversão de graus² para hectares
    // Varia conforme a latitude devido à curvatura da Terra
    final latRad = latitude * (3.14159265359 / 180.0);
    final metrosPorGrauLat = 111132.92 - 559.82 * cos(2 * latRad) + 1.175 * cos(4 * latRad);
    final metrosPorGrauLng = 111412.84 * cos(latRad) - 93.5 * cos(3 * latRad);
    
    // Conversão para hectares (1 hectare = 10000 m²)
    return (metrosPorGrauLat * metrosPorGrauLng) / 10000;
  }
  
  /// Função auxiliar para cálculo de cosseno
  static double cos(double rad) {
    return _cosTaylor(rad);
  }
  
  /// Implementação de cosseno usando série de Taylor
  static double _cosTaylor(double x) {
    // Normalizar para [-π, π]
    final pi = 3.14159265359;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;
    
    // Série de Taylor para cos(x)
    double result = 1.0;
    double term = 1.0;
    double x2 = x * x;
    
    for (int i = 1; i <= 6; i++) {
      term *= -x2 / (2 * i * (2 * i - 1));
      result += term;
    }
    
    return result;
  }
  
  /// Verifica se um ponto está dentro de um polígono
  static bool pontoEstaDentroDoPoligono(LatLng ponto, List<LatLng> poligono) {
    if (poligono.length < 3) return false;
    
    bool dentro = false;
    final n = poligono.length;
    
    for (int i = 0, j = n - 1; i < n; j = i++) {
      if (((poligono[i].latitude > ponto.latitude) != 
           (poligono[j].latitude > ponto.latitude)) &&
          (ponto.longitude < (poligono[j].longitude - poligono[i].longitude) * 
           (ponto.latitude - poligono[i].latitude) / 
           (poligono[j].latitude - poligono[i].latitude) + poligono[i].longitude)) {
        dentro = !dentro;
      }
    }
    
    return dentro;
  }
  
  /// Simplifica um polígono removendo pontos redundantes
  /// Útil para otimizar polígonos com muitos pontos
  static List<LatLng> simplificarPoligono(
    List<LatLng> coordenadas, {
    double tolerancia = 0.00001, // ~1 metro
  }) {
    if (coordenadas.length <= 3) return List.from(coordenadas);
    
    List<LatLng> resultado = [coordenadas.first];
    
    for (int i = 1; i < coordenadas.length - 1; i++) {
      final anterior = coordenadas[i - 1];
      final atual = coordenadas[i];
      final proximo = coordenadas[i + 1];
      
      // Verificar se o ponto atual é significativo
      if (!_pontoEstaEmLinha(anterior, atual, proximo, tolerancia)) {
        resultado.add(atual);
      }
    }
    
    resultado.add(coordenadas.last);
    return resultado;
  }
  
  /// Verifica se um ponto está aproximadamente em linha reta com outros dois
  static bool _pontoEstaEmLinha(
    LatLng p1, 
    LatLng p2, 
    LatLng p3, 
    double tolerancia
  ) {
    final area = ((p2.latitude - p1.latitude) * (p3.longitude - p1.longitude) -
                 (p3.latitude - p1.latitude) * (p2.longitude - p1.longitude)).abs();
                 
    return area < tolerancia;
  }
  
  /// Formata a área para exibição
  static String formatarArea(double areaHectares) {
    if (areaHectares < 0.01) {
      // Converter para metros quadrados
      final areaM2 = areaHectares * 10000;
      return '${areaM2.toStringAsFixed(0)} m²';
    } else if (areaHectares < 1) {
      return '${areaHectares.toStringAsFixed(2)} ha';
    } else if (areaHectares < 10) {
      return '${areaHectares.toStringAsFixed(1)} ha';
    } else {
      return '${areaHectares.toStringAsFixed(0)} ha';
    }
  }

  /// Parse GeoJSON coordinates para List<LatLng>
  static List<LatLng> parseGeoJSONCoordinates(String geoJsonString) {
    try {
      final geoJson = jsonDecode(geoJsonString);
      
      if (geoJson['type'] == 'Polygon' && geoJson['coordinates'] != null) {
        final coordinates = geoJson['coordinates'][0]; // Primeiro anel do polígono
        return coordinates.map<LatLng>((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble()); // GeoJSON é [lng, lat]
        }).toList();
      } else if (geoJson['type'] == 'Feature' && 
                 geoJson['geometry'] != null && 
                 geoJson['geometry']['type'] == 'Polygon') {
        final coordinates = geoJson['geometry']['coordinates'][0];
        return coordinates.map<LatLng>((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();
      }
      
      throw Exception('Formato GeoJSON não suportado');
    } catch (e) {
      print('Erro ao parsear GeoJSON: $e');
      return [];
    }
  }

  /// Calcula a área de um polígono em hectares (versão melhorada)
  static double calcularAreaPoligono(List<LatLng> coordenadas) {
    return calcularArea(coordenadas);
  }

  /// Calcula o perímetro de um polígono em metros (versão melhorada)
  static double calcularPerimetroPoligono(List<LatLng> coordenadas, {UnidadeDistancia unidade = UnidadeDistancia.metros}) {
    if (coordenadas.length < 2) return 0.0;
    
    double perimetro = 0.0;
    final distance = const Distance();
    
    for (int i = 0; i < coordenadas.length; i++) {
      final j = (i + 1) % coordenadas.length;
      perimetro += distance.as(
        LengthUnit.Meter,
        coordenadas[i],
        coordenadas[j]
      );
    }
    
    // Converter para unidade solicitada
    switch (unidade) {
      case UnidadeDistancia.metros:
        return perimetro;
      case UnidadeDistancia.quilometros:
        return perimetro / 1000.0;
      case UnidadeDistancia.milhas:
        return perimetro / 1609.34;
    }
  }

  /// Calcula área para modo desenho manual (alta precisão)
  /// Usa algoritmo de Shoelace com fatores geodésicos corrigidos
  static double calcularAreaDesenhoManual(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) return 0.0;
    
    // Normalizar pontos (remover duplicados e fechar polígono)
    final pontosNormalizados = _normalizarPontos(coordenadas);
    if (pontosNormalizados.length < 3) return 0.0;
    
    // Usar cálculo de área padrão corrigido
    return calcularArea(pontosNormalizados);
  }

  /// Calcula área para modo GPS caminhada (geodésico)
  /// 1. Aplica filtro de Kalman para suavizar pontos GPS
  /// 2. Converte para UTM
  /// 3. Usa fórmula de Shoelace para cálculo preciso
  static double calcularAreaGpsCaminhada(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) return 0.0;
    
    try {
      // 1. Aplicar filtro de Kalman para suavizar pontos GPS ruidosos
      final pontosFiltrados = _aplicarFiltroKalman(coordenadas, q: 1.0, r: 25.0);
      if (pontosFiltrados.length < 3) return 0.0;
      
      // 2. Normalizar pontos (remover duplicados e fechar polígono)
      final pontosNormalizados = _normalizarPontos(pontosFiltrados);
      
      // 3. Usar o mesmo método de cálculo de área (Shoelace + UTM)
      return calcularArea(pontosNormalizados);
      
    } catch (e) {
      print('❌ Erro no cálculo de área GPS: $e');
      // Fallback para método padrão
      return calcularArea(coordenadas);
    }
  }

  /// Calcula área usando algoritmo esférico (mais preciso para GPS)
  static double _calcularAreaEsferica(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) return 0.0;
    
    // Constante do raio da Terra (WGS84)
    const double earthRadius = 6378137.0; // metros
    
    double area = 0.0;
    final n = coordenadas.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      
      // Converter para radianos
      final lat1 = coordenadas[i].latitude * pi / 180;
      final lon1 = coordenadas[i].longitude * pi / 180;
      final lat2 = coordenadas[j].latitude * pi / 180;
      final lon2 = coordenadas[j].longitude * pi / 180;
      
      // Fórmula de área esférica
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area * earthRadius * earthRadius / 2.0;
    
    // Converter para hectares
    return area.abs() / 10000.0;
  }

  /// Filtra pontos GPS ruidosos usando algoritmo de Douglas-Peucker
  /// Aplica filtro de Kalman para suavizar pontos GPS
  /// Modelo simples 2D: estado [x, y], medida [x_gps, y_gps]
  static List<LatLng> _aplicarFiltroKalman(List<LatLng> pontos, {double q = 1.0, double r = 25.0}) {
    if (pontos.length < 2) return pontos;
    
    final List<LatLng> pontosFiltrados = [];
    
    // Estado inicial: primeiro ponto
    double x = pontos[0].latitude;
    double y = pontos[0].longitude;
    double p = 1.0; // Variância do estado inicial
    
    pontosFiltrados.add(LatLng(x, y));
    
    for (int i = 1; i < pontos.length; i++) {
      final pontoGps = pontos[i];
      
      // Predição
      final xPred = x; // Modelo simples: posição não muda
      final pPred = p + q; // Adicionar incerteza do processo
      
      // Atualização (correção)
      final k = pPred / (pPred + r); // Ganho de Kalman
      x = xPred + k * (pontoGps.latitude - xPred);
      y = y + k * (pontoGps.longitude - y);
      p = (1 - k) * pPred;
      
      pontosFiltrados.add(LatLng(x, y));
    }
    
    return pontosFiltrados;
  }
  
  /// Filtra pontos GPS ruidosos usando algoritmo de suavização
  static List<LatLng> _filtrarPontosGpsRuidosos(List<LatLng> pontos, {double tolerancia = 2.0}) {
    if (pontos.length <= 3) return pontos;
    
    // Remover pontos duplicados ou muito próximos
    final pontosLimpos = <LatLng>[];
    pontosLimpos.add(pontos.first);
    
    for (int i = 1; i < pontos.length; i++) {
      final distancia = calcularDistancia(pontosLimpos.last, pontos[i]);
      if (distancia > tolerancia) {
        pontosLimpos.add(pontos[i]);
      }
    }
    
    return pontosLimpos;
  }

  /// Normaliza lista de pontos (remove duplicados, fecha polígono)
  static List<LatLng> _normalizarPontos(List<LatLng> pontos) {
    if (pontos.isEmpty) return pontos;
    
    final normalizados = <LatLng>[];
    
    // Remove pontos duplicados consecutivos
    for (final ponto in pontos) {
      if (normalizados.isEmpty || 
          normalizados.last.latitude != ponto.latitude || 
          normalizados.last.longitude != ponto.longitude) {
        normalizados.add(ponto);
      }
    }
    
    // Fecha o polígono se necessário
    if (normalizados.length >= 3) {
      final primeiro = normalizados.first;
      final ultimo = normalizados.last;
      
      if (primeiro.latitude != ultimo.latitude || primeiro.longitude != ultimo.longitude) {
        normalizados.add(LatLng(primeiro.latitude, primeiro.longitude));
      }
    }
    
    return normalizados;
  }
  
  /// Converte coordenadas Lat/Lng para UTM usando fórmula simplificada
  /// x = k₀ * N * (λ - λ₀) * cos(φ) + x₀
  /// y = k₀ * [M + N * tan(φ) * ((λ - λ₀)²/2 + ...)] + y₀
  static List<CoordenadaUTM> _converterParaUTM(List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) return [];
    
    // Calcular longitude média para determinar a zona UTM
    final lngMedia = coordenadas.map((p) => p.longitude).reduce((a, b) => a + b) / coordenadas.length;
    final latMedia = coordenadas.map((p) => p.latitude).reduce((a, b) => a + b) / coordenadas.length;
    
    // Determinar zona UTM e meridiano central
    final zonaUtm = ((lngMedia + 180) / 6).floor() + 1;
    final meridianoCentral = (zonaUtm - 1) * 6 - 180 + 3;
    
    // Parâmetros WGS84
    const double a = 6378137.0; // Semi-eixo maior
    const double e2 = 0.00669438; // Excentricidade ao quadrado
    const double k0 = 0.9996; // Fator de escala
    const double x0 = 500000; // Falso leste
    final double y0 = latMedia < 0 ? 10000000 : 0; // Falso norte (ajuste hemisfério sul)
    
    final List<CoordenadaUTM> coordenadasUtm = [];
    
    for (final coord in coordenadas) {
      final phi = coord.latitude * pi / 180; // Latitude em radianos
      final lambda = coord.longitude * pi / 180; // Longitude em radianos
      final lambda0 = meridianoCentral * pi / 180; // Meridiano central em radianos
      
      // Cálculo de N (raio de curvatura da primeira vertical)
      final N = a / sqrt(1 - e2 * sin(phi) * sin(phi));
      
      // Cálculo do arco meridional M
      final M = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * phi
          - (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * sin(2 * phi)
          + (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * sin(4 * phi)
          - (35 * e2 * e2 * e2 / 3072) * sin(6 * phi));
      
      // Coordenadas UTM simplificadas
      final x = k0 * N * (lambda - lambda0) * cos(phi) + x0;
      final y = k0 * (M + N * tan(phi) * pow(lambda - lambda0, 2) / 2) + y0;
      
      coordenadasUtm.add(CoordenadaUTM(x, y));
    }
    
    return coordenadasUtm;
  }
}
