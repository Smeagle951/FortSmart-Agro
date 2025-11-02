import '../models/organism_catalog.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';

/// Serviço para cálculos de monitoramento avançado
class MonitoringCalculationService {
  
  /// Converte quantidade numérica em porcentagem baseado no catálogo de organismos
  static double calculateInfestationPercentage({
    required int quantity,
    required OrganismCatalog organism,
    required int totalPlantsEvaluated,
    String? unit,
  }) {
    try {
      if (totalPlantsEvaluated <= 0) {
        Logger.warning('Total de plantas avaliadas deve ser maior que zero');
        return 0.0;
      }

      // Se a unidade for porcentagem, retorna direto
      if (unit == 'percentage' || unit == '%') {
        return quantity.toDouble();
      }

      // Se a unidade for número absoluto, calcula porcentagem
      if (unit == 'count' || unit == 'number' || unit == null) {
        return (quantity / totalPlantsEvaluated) * 100;
      }

      // Se a unidade for por metro quadrado, converte baseado na densidade
      if (unit == 'm2' || unit == 'per_m2') {
        // Assumindo 1m² = aproximadamente 10 plantas (varia por cultura)
        final plantsPerM2 = 10; // Valor padrão
        final totalPlantsInArea = quantity * plantsPerM2;
        return (totalPlantsInArea / totalPlantsEvaluated) * 100;
      }

      // Se a unidade for por metro linear, converte baseado na densidade
      if (unit == 'm' || unit == 'per_m') {
        // Assumindo 1m linear = aproximadamente 5 plantas
        final plantsPerM = 5; // Valor padrão
        final totalPlantsInArea = quantity * plantsPerM;
        return (totalPlantsInArea / totalPlantsEvaluated) * 100;
      }

      Logger.warning('Unidade não reconhecida: $unit. Usando cálculo padrão.');
      return (quantity / totalPlantsEvaluated) * 100;

    } catch (e) {
      Logger.error('Erro ao calcular porcentagem de infestação: $e');
      return 0.0;
    }
  }

  /// Determina o nível de infestação baseado na porcentagem e limiares do organismo
  static InfestationLevel determineInfestationLevel({
    required double percentage,
    required OrganismCatalog organism,
  }) {
    try {
      // Usar limiares específicos do organismo se disponíveis
      final lowThreshold = organism.lowThreshold ?? 5.0;
      final mediumThreshold = organism.mediumThreshold ?? 15.0;
      final highThreshold = organism.highThreshold ?? 30.0;

      if (percentage < lowThreshold) {
        return InfestationLevel.low;
      } else if (percentage < mediumThreshold) {
        return InfestationLevel.medium;
      } else if (percentage < highThreshold) {
        return InfestationLevel.high;
      } else {
        return InfestationLevel.critical;
      }
    } catch (e) {
      Logger.error('Erro ao determinar nível de infestação: $e');
      return InfestationLevel.low;
    }
  }

  /// Cria uma ocorrência a partir de dados numéricos
  static Occurrence createOccurrenceFromNumericData({
    required OrganismCatalog organism,
    required int quantity,
    required int totalPlantsEvaluated,
    required String unit,
    required List<PlantSection> affectedSections,
    String? notes,
  }) {
    try {
      // Calcular porcentagem
      final percentage = calculateInfestationPercentage(
        quantity: quantity,
        organism: organism,
        totalPlantsEvaluated: totalPlantsEvaluated,
        unit: unit,
      );

      // Determinar tipo de ocorrência baseado no organismo
      final occurrenceType = _mapOrganismTypeToOccurrenceType(organism.type.toString());

      return Occurrence(
        type: occurrenceType,
        name: organism.name,
        infestationIndex: percentage,
        affectedSections: affectedSections,
        notes: notes ?? 'Quantidade: $quantity $unit',
      );
    } catch (e) {
      Logger.error('Erro ao criar ocorrência: $e');
      rethrow;
    }
  }

  /// Mapeia tipo de organismo para tipo de ocorrência
  static OccurrenceType _mapOrganismTypeToOccurrenceType(String organismType) {
    switch (organismType.toLowerCase()) {
      case 'pest':
      case 'praga':
        return OccurrenceType.pest;
      case 'disease':
      case 'doença':
        return OccurrenceType.disease;
      case 'weed':
      case 'planta daninha':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.pest;
    }
  }

  /// Gera descrição formatada da infestação
  static String generateInfestationDescription({
    required int quantity,
    required String unit,
    required OrganismCatalog organism,
    required double percentage,
    required InfestationLevel level,
  }) {
    final levelText = _getLevelText(level);
    final unitText = _getUnitText(unit);
    
    return '$quantity $unitText de ${organism.name} ($percentage.toStringAsFixed(1)%) - Nível $levelText';
  }

  /// Obtém texto do nível de infestação
  static String _getLevelText(InfestationLevel level) {
    switch (level) {
      case InfestationLevel.low:
        return 'Baixo';
      case InfestationLevel.medium:
        return 'Médio';
      case InfestationLevel.high:
        return 'Alto';
      case InfestationLevel.critical:
        return 'Crítico';
    }
  }

  /// Obtém texto da unidade
  static String _getUnitText(String unit) {
    switch (unit.toLowerCase()) {
      case 'count':
      case 'number':
        return 'indivíduos';
      case 'percentage':
      case '%':
        return '%';
      case 'm2':
      case 'per_m2':
        return 'por m²';
      case 'm':
      case 'per_m':
        return 'por metro';
      default:
        return unit;
    }
  }
}

/// Enum para níveis de infestação
enum InfestationLevel {
  low,
  medium,
  high,
  critical,
}
