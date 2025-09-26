import 'package:latlong2/latlong.dart';

/// Classe utilitária para cálculos geoespaciais
/// Implementa funções para cálculo de área, perímetro e centroide
class GeoMath {
  /// Calcula a área de um polígono em hectares
  static double calcularArea(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) return 0.0;
    
    // Implementação da fórmula de área de polígono (Shoelace formula)
    double area = 0.0;
    final n = coordenadas.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += coordenadas[i].latitude * coordenadas[j].longitude;
      area -= coordenadas[j].latitude * coordenadas[i].longitude;
    }
    
    area = area.abs() * 0.5;
    
    // Converter para hectares (aproximação)
    // Fator de conversão depende da latitude
    final latMedia = coordenadas.fold(0.0, (sum, point) => (sum as double) + point.latitude) / n;
    final fatorConversao = _calcularFatorConversao(latMedia);
    
    return area * fatorConversao;
  }
  
  /// Calcula o perímetro de um polígono em metros
  static double calcularPerimetro(List<LatLng> coordenadas) {
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
  
  /// Calcula o fator de conversão para hectares baseado na latitude
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
}
