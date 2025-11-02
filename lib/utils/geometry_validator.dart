import 'package:latlong2/latlong.dart';

/// 🚀 FORTSMART ORIGINAL - Validador de geometrias geoespaciais
class GeometryValidator {
  
  /// Valida se um polígono é válido (método simples)
  static bool isValidPolygonSimple(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se não há pontos duplicados consecutivos
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] == points[i + 1]) return false;
    }
    
    // Verificar se o primeiro e último ponto são iguais (polígono fechado)
    if (points.first != points.last) return false;
    
    // Verificar se a área é maior que zero
    return calculatePolygonArea(points) > 0.001; // Mínimo 0.001 hectares
  }
  
  /// Valida se as coordenadas estão em range válido
  static bool isValidCoordinate(LatLng point) {
    return point.latitude >= -90 && point.latitude <= 90 &&
           point.longitude >= -180 && point.longitude <= 180;
  }
  
  /// Valida se todas as coordenadas de um polígono são válidas
  static bool hasValidCoordinates(List<LatLng> points) {
    return points.every((point) => isValidCoordinate(point));
  }
  
  /// Verifica se o polígono tem área mínima
  static bool hasMinimumArea(List<LatLng> points, {double minAreaHectares = 0.01}) {
    final area = calculatePolygonArea(points);
    return area >= minAreaHectares;
  }
  
  /// Verifica se o polígono não é muito complexo (muitos pontos)
  static bool isNotTooComplex(List<LatLng> points, {int maxPoints = 1000}) {
    return points.length <= maxPoints;
  }
  
  /// Calcula área aproximada do polígono em hectares
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    // Converter para hectares (aproximação)
    return (area.abs() / 2.0) * 111320 * 111320 / 10000;
  }
  
  /// Verifica se o polígono não tem auto-intersecções (simplificado)
  static bool hasNoSelfIntersections(List<LatLng> points) {
    // Implementação simplificada - para produção, use algoritmo mais robusto
    if (points.length < 4) return true;
    
    // Verificar se não há pontos muito próximos que possam causar problemas
    for (int i = 0; i < points.length - 1; i++) {
      for (int j = i + 2; j < points.length - 1; j++) {
        final distance = _calculateDistance(points[i], points[j]);
        if (distance < 0.0001) { // Muito próximo
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Calcula distância entre dois pontos (aproximação)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    final latDiff = point1.latitude - point2.latitude;
    final lngDiff = point1.longitude - point2.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff);
  }
  
  /// Validação completa do polígono
  static ValidationResult validatePolygon(List<LatLng> points) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Verificações básicas
    if (points.length < 3) {
      errors.add('Polígono deve ter pelo menos 3 pontos');
      return ValidationResult(errors: errors, warnings: warnings, isValid: false);
    }
    
    // Verificar coordenadas válidas
    if (!hasValidCoordinates(points)) {
      errors.add('Coordenadas inválidas encontradas');
    }
    
    // Verificar área mínima
    if (!hasMinimumArea(points)) {
      warnings.add('Polígono muito pequeno (área < 0.01 ha)');
    }
    
    // Verificar complexidade
    if (!isNotTooComplex(points)) {
      warnings.add('Polígono muito complexo (mais de 1000 pontos)');
    }
    
    // Verificar auto-intersecções
    if (!hasNoSelfIntersections(points)) {
      warnings.add('Possíveis auto-intersecções detectadas');
    }
    
    // Verificar se é válido
    if (!isValidPolygonSimple(points)) {
      errors.add('Polígono inválido');
    }
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      isValid: errors.isEmpty,
    );
  }

  /// Método de conveniência para validação síncrona
  static ValidationResult isValidPolygon(List<LatLng> points) {
    return validatePolygon(points);
  }
}

/// Resultado da validação
class ValidationResult {
  final List<String> errors;
  final List<String> warnings;
  final bool isValid;
  
  const ValidationResult({
    required this.errors,
    required this.warnings,
    required this.isValid,
  });
  
  /// Verifica se tem erros críticos
  bool get hasErrors => errors.isNotEmpty;
  
  /// Verifica se tem apenas avisos
  bool get hasOnlyWarnings => errors.isEmpty && warnings.isNotEmpty;
  
  /// Obtém mensagem resumida
  String get summary {
    if (hasErrors) {
      return 'Erros: ${errors.join(', ')}';
    } else if (hasOnlyWarnings) {
      return 'Avisos: ${warnings.join(', ')}';
    } else {
      return 'Polígono válido';
    }
  }
}