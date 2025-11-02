import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Classe para validação de polígonos de talhões
/// Implementa verificações de integridade, área mínima e auto-intersecção
class ValidadorTalhao {
  /// Área mínima em hectares para um talhão ser considerado válido
  static const double areaMinima = 0.1;
  
  /// Verifica se um polígono é válido para criação de talhão
  static bool isPoligonoValido(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) {
      return false; // Precisa de pelo menos 3 pontos para formar um polígono
    }
    
    // Verificar se há pontos duplicados
    if (_temPontosDuplicados(coordenadas)) {
      return false;
    }
    
    // Verificar área mínima
    final area = calcularArea(coordenadas);
    if (area < areaMinima) {
      return false;
    }
    
    // Verificar se não há auto-intersecção
    if (_temAutoInterseccao(coordenadas)) {
      return false;
    }
    
    return true;
  }
  
  /// Verifica se há pontos duplicados na lista de coordenadas
  static bool _temPontosDuplicados(List<LatLng> coordenadas) {
    final Set<String> pontos = {};
    
    for (final ponto in coordenadas) {
      // Usar precisão de 6 casas decimais (aproximadamente 10cm)
      final chave = '${ponto.latitude.toStringAsFixed(6)},${ponto.longitude.toStringAsFixed(6)}';
      
      if (pontos.contains(chave)) {
        return true; // Ponto duplicado encontrado
      }
      
      pontos.add(chave);
    }
    
    return false;
  }
  
  /// Verifica se o polígono tem auto-intersecção (cruzamento de arestas)
  static bool _temAutoInterseccao(List<LatLng> coordenadas) {
    // Implementação do algoritmo de detecção de intersecção de segmentos
    for (int i = 0; i < coordenadas.length; i++) {
      final p1 = coordenadas[i];
      final p2 = coordenadas[(i + 1) % coordenadas.length];
      
      for (int j = i + 2; j < coordenadas.length + (i < 2 ? 1 : 0); j++) {
        final p3 = coordenadas[j % coordenadas.length];
        final p4 = coordenadas[(j + 1) % coordenadas.length];
        
        // Verificar se os segmentos (p1,p2) e (p3,p4) se intersectam
        if (_segmentosSeIntersectam(p1, p2, p3, p4)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Verifica se dois segmentos de reta se intersectam
  static bool _segmentosSeIntersectam(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    // Implementação do algoritmo de intersecção de segmentos
    final o1 = _orientacao(p1, p2, p3);
    final o2 = _orientacao(p1, p2, p4);
    final o3 = _orientacao(p3, p4, p1);
    final o4 = _orientacao(p3, p4, p2);
    
    // Caso geral
    if (o1 != o2 && o3 != o4) {
      return true;
    }
    
    // Casos especiais (colinearidade)
    if (o1 == 0 && _pontoDentroDoSegmento(p1, p3, p2)) return true;
    if (o2 == 0 && _pontoDentroDoSegmento(p1, p4, p2)) return true;
    if (o3 == 0 && _pontoDentroDoSegmento(p3, p1, p4)) return true;
    if (o4 == 0 && _pontoDentroDoSegmento(p3, p2, p4)) return true;
    
    return false;
  }
  
  /// Calcula a orientação de três pontos (horário, anti-horário ou colinear)
  static int _orientacao(LatLng p, LatLng q, LatLng r) {
    final val = (q.longitude - p.longitude) * (r.latitude - q.latitude) -
                (q.latitude - p.latitude) * (r.longitude - q.longitude);
    
    if (val.abs() < 1e-10) return 0;  // Colinear
    return (val > 0) ? 1 : 2;  // Horário ou anti-horário
  }
  
  /// Verifica se um ponto está dentro de um segmento de reta
  static bool _pontoDentroDoSegmento(LatLng p, LatLng q, LatLng r) {
    return q.longitude <= p.longitude &&
           q.longitude >= p.longitude &&
           q.latitude <= p.latitude &&
           q.latitude >= p.latitude;
  }
  
  /// Calcula a área do polígono em hectares
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
    
    // Converter para hectares usando fator de conversão consistente
    // 1 grau² ≈ 111 km² na latitude média do Brasil
    const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
    return area * grauParaHectares;
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
  
  /// Retorna mensagem de erro específica para o problema encontrado
  static String getMensagemErro(List<LatLng> coordenadas) {
    if (coordenadas.length < 3) {
      return 'O talhão precisa ter pelo menos 3 pontos para formar um polígono válido.';
    }
    
    if (_temPontosDuplicados(coordenadas)) {
      return 'Existem pontos duplicados no desenho do talhão. Remova os pontos duplicados.';
    }
    
    final area = calcularArea(coordenadas);
    if (area < areaMinima) {
      return 'A área do talhão (${area.toStringAsFixed(2)} ha) é menor que o mínimo permitido (${areaMinima.toStringAsFixed(2)} ha).';
    }
    
    if (_temAutoInterseccao(coordenadas)) {
      return 'O desenho do talhão possui cruzamentos. Evite que as linhas se cruzem.';
    }
    
    return 'O talhão é válido.';
  }
}
