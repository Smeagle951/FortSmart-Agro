import 'dart:math';
import '../services/geojson_reader_service.dart';
import '../utils/logger.dart';

/// Serviço para validação avançada de dados GeoJSON
class GeoJSONValidationService {
  
  /// Valida estrutura GeoJSON
  static ValidationResult validateGeoJSONStructure(Map<String, dynamic> geoJSON) {
    final errors = <String>[];
    final warnings = <String>[];
    
    try {
      // Validar estrutura básica
      if (!geoJSON.containsKey('type')) {
        errors.add('Campo "type" é obrigatório');
      } else if (geoJSON['type'] != 'FeatureCollection') {
        errors.add('Tipo deve ser "FeatureCollection"');
      }
      
      if (!geoJSON.containsKey('features')) {
        errors.add('Campo "features" é obrigatório');
      } else if (geoJSON['features'] is! List) {
        errors.add('Campo "features" deve ser uma lista');
      } else {
        final features = geoJSON['features'] as List;
        
        if (features.isEmpty) {
          warnings.add('Nenhuma feature encontrada no arquivo');
        }
        
        // Validar cada feature
        for (int i = 0; i < features.length; i++) {
          final featureErrors = _validateFeature(features[i], i);
          errors.addAll(featureErrors);
        }
      }
      
      // Validar CRS (Sistema de Coordenadas)
      if (geoJSON.containsKey('crs')) {
        final crsWarnings = _validateCRS(geoJSON['crs']);
        warnings.addAll(crsWarnings);
      } else {
        warnings.add('CRS não especificado - assumindo WGS84 (EPSG:4326)');
      }
      
    } catch (e) {
      errors.add('Erro na validação da estrutura: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Valida feature individual
  static List<String> _validateFeature(dynamic feature, int index) {
    final errors = <String>[];
    
    try {
      if (feature is! Map<String, dynamic>) {
        errors.add('Feature $index: Deve ser um objeto');
        return errors;
      }
      
      // Validar tipo
      if (!feature.containsKey('type') || feature['type'] != 'Feature') {
        errors.add('Feature $index: Tipo deve ser "Feature"');
      }
      
      // Validar geometria
      if (!feature.containsKey('geometry')) {
        errors.add('Feature $index: Geometria é obrigatória');
      } else {
        final geometryErrors = _validateGeometry(feature['geometry'], index);
        errors.addAll(geometryErrors);
      }
      
      // Validar propriedades
      if (!feature.containsKey('properties')) {
        errors.add('Feature $index: Propriedades são obrigatórias');
      } else if (feature['properties'] is! Map<String, dynamic>) {
        errors.add('Feature $index: Propriedades devem ser um objeto');
      }
      
    } catch (e) {
      errors.add('Feature $index: Erro na validação - $e');
    }
    
    return errors;
  }
  
  /// Valida geometria
  static List<String> _validateGeometry(dynamic geometry, int featureIndex) {
    final errors = <String>[];
    
    try {
      if (geometry is! Map<String, dynamic>) {
        errors.add('Feature $featureIndex: Geometria deve ser um objeto');
        return errors;
      }
      
      if (!geometry.containsKey('type')) {
        errors.add('Feature $featureIndex: Tipo da geometria é obrigatório');
        return errors;
      }
      
      final type = geometry['type'] as String;
      
      if (!geometry.containsKey('coordinates')) {
        errors.add('Feature $featureIndex: Coordenadas são obrigatórias');
        return errors;
      }
      
      final coordinates = geometry['coordinates'];
      final coordErrors = _validateCoordinates(coordinates, type, featureIndex);
      errors.addAll(coordErrors);
      
    } catch (e) {
      errors.add('Feature $featureIndex: Erro na validação da geometria - $e');
    }
    
    return errors;
  }
  
  /// Valida coordenadas
  static List<String> _validateCoordinates(dynamic coordinates, String type, int featureIndex) {
    final errors = <String>[];
    
    try {
      switch (type) {
        case 'Point':
          errors.addAll(_validatePointCoordinates(coordinates, featureIndex));
          break;
        case 'LineString':
          errors.addAll(_validateLineStringCoordinates(coordinates, featureIndex));
          break;
        case 'Polygon':
          errors.addAll(_validatePolygonCoordinates(coordinates, featureIndex));
          break;
        case 'MultiPolygon':
          errors.addAll(_validateMultiPolygonCoordinates(coordinates, featureIndex));
          break;
        default:
          errors.add('Feature $featureIndex: Tipo de geometria não suportado: $type');
      }
    } catch (e) {
      errors.add('Feature $featureIndex: Erro na validação das coordenadas - $e');
    }
    
    return errors;
  }
  
  /// Valida coordenadas de ponto
  static List<String> _validatePointCoordinates(dynamic coordinates, int featureIndex) {
    final errors = <String>[];
    
    if (coordinates is! List || coordinates.length < 2) {
      errors.add('Feature $featureIndex: Ponto deve ter pelo menos 2 coordenadas [lng, lat]');
      return errors;
    }
    
    final lng = coordinates[0];
    final lat = coordinates[1];
    
    if (lng is! num || lat is! num) {
      errors.add('Feature $featureIndex: Coordenadas devem ser números');
      return errors;
    }
    
    // Validar limites geográficos
    if (lng < -180 || lng > 180) {
      errors.add('Feature $featureIndex: Longitude deve estar entre -180 e 180');
    }
    
    if (lat < -90 || lat > 90) {
      errors.add('Feature $featureIndex: Latitude deve estar entre -90 e 90');
    }
    
    return errors;
  }
  
  /// Valida coordenadas de linha
  static List<String> _validateLineStringCoordinates(dynamic coordinates, int featureIndex) {
    final errors = <String>[];
    
    if (coordinates is! List || coordinates.length < 2) {
      errors.add('Feature $featureIndex: LineString deve ter pelo menos 2 pontos');
      return errors;
    }
    
    for (int i = 0; i < coordinates.length; i++) {
      final pointErrors = _validatePointCoordinates(coordinates[i], featureIndex);
      errors.addAll(pointErrors.map((e) => e.replaceAll('Ponto', 'Ponto $i')));
    }
    
    return errors;
  }
  
  /// Valida coordenadas de polígono
  static List<String> _validatePolygonCoordinates(dynamic coordinates, int featureIndex) {
    final errors = <String>[];
    
    if (coordinates is! List || coordinates.isEmpty) {
      errors.add('Feature $featureIndex: Polígono deve ter pelo menos um anel');
      return errors;
    }
    
    // Validar anel externo
    final outerRing = coordinates[0];
    if (outerRing is! List || outerRing.length < 4) {
      errors.add('Feature $featureIndex: Anel externo deve ter pelo menos 4 pontos');
      return errors;
    }
    
    // Verificar se o polígono é fechado
    if (outerRing.first.toString() != outerRing.last.toString()) {
      errors.add('Feature $featureIndex: Anel externo deve ser fechado (primeiro e último ponto iguais)');
    }
    
    // Validar todos os pontos do anel externo
    for (int i = 0; i < outerRing.length; i++) {
      final pointErrors = _validatePointCoordinates(outerRing[i], featureIndex);
      errors.addAll(pointErrors.map((e) => e.replaceAll('Ponto', 'Ponto $i do anel externo')));
    }
    
    // Validar anéis internos (buracos)
    for (int ringIndex = 1; ringIndex < coordinates.length; ringIndex++) {
      final innerRing = coordinates[ringIndex];
      if (innerRing is! List || innerRing.length < 4) {
        errors.add('Feature $featureIndex: Anel interno $ringIndex deve ter pelo menos 4 pontos');
        continue;
      }
      
      // Verificar se o anel interno é fechado
      if (innerRing.first.toString() != innerRing.last.toString()) {
        errors.add('Feature $featureIndex: Anel interno $ringIndex deve ser fechado');
      }
      
      // Validar pontos do anel interno
      for (int i = 0; i < innerRing.length; i++) {
        final pointErrors = _validatePointCoordinates(innerRing[i], featureIndex);
        errors.addAll(pointErrors.map((e) => e.replaceAll('Ponto', 'Ponto $i do anel interno $ringIndex')));
      }
    }
    
    return errors;
  }
  
  /// Valida coordenadas de multipolígono
  static List<String> _validateMultiPolygonCoordinates(dynamic coordinates, int featureIndex) {
    final errors = <String>[];
    
    if (coordinates is! List || coordinates.isEmpty) {
      errors.add('Feature $featureIndex: MultiPolígono deve ter pelo menos um polígono');
      return errors;
    }
    
    for (int polygonIndex = 0; polygonIndex < coordinates.length; polygonIndex++) {
      final polygonErrors = _validatePolygonCoordinates(coordinates[polygonIndex], featureIndex);
      errors.addAll(polygonErrors.map((e) => e.replaceAll('Polígono', 'Polígono $polygonIndex')));
    }
    
    return errors;
  }
  
  /// Valida CRS (Sistema de Coordenadas)
  static List<String> _validateCRS(dynamic crs) {
    final warnings = <String>[];
    
    try {
      if (crs is Map<String, dynamic>) {
        if (crs.containsKey('type') && crs['type'] == 'name') {
          final properties = crs['properties'];
          if (properties is Map<String, dynamic> && properties.containsKey('name')) {
            final name = properties['name'] as String;
            if (!name.contains('4326') && !name.contains('WGS84')) {
              warnings.add('CRS não é WGS84 (EPSG:4326): $name');
            }
          }
        }
      }
    } catch (e) {
      warnings.add('Erro na validação do CRS: $e');
    }
    
    return warnings;
  }
  
  /// Valida propriedades específicas por tipo de dados
  static ValidationResult validatePropertiesByType(GeoJSONData geoJSONData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    switch (geoJSONData.dataType) {
      case GeoJSONDataType.talhao:
        _validateTalhaoProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.machineWork:
        _validateMachineWorkProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.planting:
        _validatePlantingProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.harvest:
        _validateHarvestProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.soilSample:
        _validateSoilSampleProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.irrigation:
        _validateIrrigationProperties(geoJSONData.features, errors, warnings);
        break;
      case GeoJSONDataType.unknown:
        warnings.add('Tipo de dados não identificado - validação genérica aplicada');
        break;
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Valida propriedades de talhão
  static void _validateTalhaoProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Propriedades obrigatórias
      if (!props.containsKey('nome') && !props.containsKey('name') && !props.containsKey('NOME')) {
        errors.add('Feature $i: Nome do talhão é obrigatório');
      }
      
      // Validar área
      final area = _parseDouble(props['area'] ?? props['AREA'] ?? props['hectares'] ?? props['HECTARES']);
      if (area == null || area <= 0) {
        warnings.add('Feature $i: Área não especificada ou inválida');
      } else if (area > 10000) {
        warnings.add('Feature $i: Área muito grande (${area}ha) - verificar se está em hectares');
      }
      
      // Validar cultura
      if (!props.containsKey('cultura_id') && !props.containsKey('culturaId') && !props.containsKey('CULTURA_ID')) {
        warnings.add('Feature $i: ID da cultura não especificado');
      }
    }
  }
  
  /// Valida propriedades de trabalho de máquina
  static void _validateMachineWorkProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Propriedades obrigatórias
      if (!props.containsKey('machine') && !props.containsKey('maquina') && !props.containsKey('MACHINE')) {
        errors.add('Feature $i: Nome da máquina é obrigatório');
      }
      
      // Validar dose
      final dose = _parseDouble(props['dose'] ?? props['DOSE']);
      if (dose == null || dose <= 0) {
        errors.add('Feature $i: Dose deve ser maior que zero');
      }
      
      // Validar velocidade
      final speed = _parseDouble(props['speed'] ?? props['velocidade'] ?? props['SPEED']);
      if (speed != null && (speed < 0 || speed > 50)) {
        warnings.add('Feature $i: Velocidade suspeita (${speed} km/h)');
      }
    }
  }
  
  /// Valida propriedades de plantio
  static void _validatePlantingProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Propriedades obrigatórias
      if (!props.containsKey('variety') && !props.containsKey('variedade') && !props.containsKey('VARIETY')) {
        errors.add('Feature $i: Variedade é obrigatória');
      }
      
      // Validar densidade
      final density = _parseDouble(props['density'] ?? props['densidade'] ?? props['DENSITY']);
      if (density == null || density <= 0) {
        errors.add('Feature $i: Densidade deve ser maior que zero');
      } else if (density > 200000) {
        warnings.add('Feature $i: Densidade muito alta (${density} plantas/ha)');
      }
    }
  }
  
  /// Valida propriedades de colheita
  static void _validateHarvestProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Validar produção
      final production = _parseDouble(props['production'] ?? props['producao'] ?? props['PRODUCTION']);
      if (production != null && production < 0) {
        errors.add('Feature $i: Produção não pode ser negativa');
      }
      
      // Validar rendimento
      final yield = _parseDouble(props['yield'] ?? props['rendimento'] ?? props['YIELD']);
      if (yield != null && (yield < 0 || yield > 200)) {
        warnings.add('Feature $i: Rendimento suspeito (${yield} t/ha)');
      }
    }
  }
  
  /// Valida propriedades de amostra de solo
  static void _validateSoilSampleProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Validar pH
      final ph = _parseDouble(props['ph'] ?? props['pH'] ?? props['PH']);
      if (ph != null && (ph < 0 || ph > 14)) {
        errors.add('Feature $i: pH deve estar entre 0 e 14');
      }
      
      // Validar matéria orgânica
      final organicMatter = _parseDouble(props['organic_matter'] ?? props['materia_organica'] ?? props['ORGANIC_MATTER']);
      if (organicMatter != null && (organicMatter < 0 || organicMatter > 100)) {
        warnings.add('Feature $i: Matéria orgânica suspeita (${organicMatter}%)');
      }
    }
  }
  
  /// Valida propriedades de irrigação
  static void _validateIrrigationProperties(List<GeoJSONFeature> features, List<String> errors, List<String> warnings) {
    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final props = feature.properties;
      
      // Validar vazão
      final flow = _parseDouble(props['flow'] ?? props['vazao'] ?? props['FLOW']);
      if (flow != null && flow < 0) {
        errors.add('Feature $i: Vazão não pode ser negativa');
      }
      
      // Validar pressão
      final pressure = _parseDouble(props['pressure'] ?? props['pressao'] ?? props['PRESSURE']);
      if (pressure != null && (pressure < 0 || pressure > 100)) {
        warnings.add('Feature $i: Pressão suspeita (${pressure} bar)');
      }
    }
  }
  
  /// Converte valor para double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Resultado da validação
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}
