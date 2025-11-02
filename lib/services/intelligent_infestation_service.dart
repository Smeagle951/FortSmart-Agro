import '../models/infestation_rule.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../models/organism_catalog.dart';
import '../repositories/organism_catalog_repository.dart';
import '../repositories/infestation_rules_repository.dart';
import '../utils/enums.dart';

/// Resultado do cálculo de infestação para um organismo específico
class InfestationResult {
  final OrganismCatalog organism;
  final int totalQuantity; // Quantidade total encontrada
  final int totalPoints; // Total de pontos monitorados
  final int pointsWithOccurrence; // Pontos com ocorrência
  final double frequency; // Frequência (% de pontos com ocorrência)
  final double averageQuantity; // Quantidade média por ponto
  final double infestationPercentage; // Porcentagem de infestação
  final String alertLevel; // Nível de alerta
  final String alertColor; // Cor do alerta

  InfestationResult({
    required this.organism,
    required this.totalQuantity,
    required this.totalPoints,
    required this.pointsWithOccurrence,
    required this.frequency,
    required this.averageQuantity,
    required this.infestationPercentage,
    required this.alertLevel,
    required this.alertColor,
  });

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'organism_id': organism.id,
      'organism_name': organism.name,
      'organism_type': organism.type.toString().split('.').last,
      'total_quantity': totalQuantity,
      'total_points': totalPoints,
      'points_with_occurrence': pointsWithOccurrence,
      'frequency': frequency,
      'average_quantity': averageQuantity,
      'infestation_percentage': infestationPercentage,
      'alert_level': alertLevel.toString().split('.').last,
      'alert_color': alertColor,
    };
  }
}

/// Resultado consolidado do monitoramento
class MonitoringInfestationResult {
  final String monitoringId;
  final String plotId;
  final String plotName;
  final String cropName;
  final DateTime date;
  final int totalPoints;
  final List<InfestationResult> results;
  final String overallAlertLevel; // Nível de alerta geral
  final String overallAlertColor; // Cor do alerta geral

  MonitoringInfestationResult({
    required this.monitoringId,
    required this.plotId,
    required this.plotName,
    required this.cropName,
    required this.date,
    required this.totalPoints,
    required this.results,
    required this.overallAlertLevel,
    required this.overallAlertColor,
  });

  /// Obtém o resultado mais crítico
  InfestationResult? get mostCriticalResult {
    if (results.isEmpty) return null;
    
    return results.reduce((a, b) {
      final aIndex = _getAlertLevelIndex(a.alertLevel);
      final bIndex = _getAlertLevelIndex(b.alertLevel);
      return aIndex > bIndex ? a : b;
    });
  }

  /// Obtém resultados por tipo
  List<InfestationResult> getResultsByType(OccurrenceType type) {
    return results.where((result) => result.organism.type == type).toList();
  }

  /// Obtém o índice do nível de alerta
  int _getAlertLevelIndex(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'monitoring_id': monitoringId,
      'plot_id': plotId,
      'plot_name': plotName,
      'crop_name': cropName,
      'date': date.toIso8601String(),
      'total_points': totalPoints,
      'results': results.map((r) => r.toMap()).toList(),
      'overall_alert_level': overallAlertLevel.toString().split('.').last,
      'overall_alert_color': overallAlertColor,
    };
  }
}

/// Serviço de cálculo de infestação inteligente
/// Usa o catálogo de organismos para calcular níveis de alerta baseados em limites definidos
class IntelligentInfestationService {
  final OrganismCatalogRepository _catalogRepository = OrganismCatalogRepository();
  final InfestationRulesRepository _rulesRepository = InfestationRulesRepository();

  /// Calcula a infestação para um conjunto de pontos de monitoramento
  Future<MonitoringInfestationResult> calculateInfestation({
    required String monitoringId,
    required String plotId,
    required String plotName,
    required String cropName,
    required DateTime date,
    required List<MonitoringPoint> points,
    String? farmId, // ID da fazenda para buscar regras personalizadas
  }) async {
    try {
      // Inicializa o repositório se necessário
      await _catalogRepository.initialize();
      
      // Obtém todos os organismos da cultura
      final organisms = await _catalogRepository.getByCrop(cropName.toLowerCase());
      
      if (organisms.isEmpty) {
        throw Exception('Nenhum organismo encontrado para a cultura: $cropName');
      }

      final List<InfestationResult> results = [];
      
      // Processa cada organismo
      for (final organism in organisms) {
        final result = await _calculateOrganismInfestationWithRules(
          organism, 
          points, 
          farmId ?? '1', // Usa fazenda padrão se não fornecida
          plotId,
        );
        if (result != null) {
          results.add(result);
        }
      }

      // Calcula o nível de alerta geral
      final overallAlertLevel = _calculateOverallAlertLevel(results);
      final overallAlertColor = _getAlertLevelColor(overallAlertLevel);

      return MonitoringInfestationResult(
        monitoringId: monitoringId,
        plotId: plotId,
        plotName: plotName,
        cropName: cropName,
        date: date,
        totalPoints: points.length,
        results: results,
        overallAlertLevel: overallAlertLevel,
        overallAlertColor: overallAlertColor,
      );
    } catch (e) {
      throw Exception('Erro ao calcular infestação: $e');
    }
  }

  /// Calcula a infestação para um organismo específico
  InfestationResult? _calculateOrganismInfestation(
    OrganismCatalog organism,
    List<MonitoringPoint> points,
  ) {
    if (points.isEmpty) return null;

    int totalQuantity = 0;
    int pointsWithOccurrence = 0;

    // Conta as ocorrências do organismo em todos os pontos
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        // Verifica se a ocorrência corresponde ao organismo
        if (_matchesOrganism(occurrence, organism)) {
          totalQuantity += occurrence.infestationIndex.toInt(); // Usa a quantidade como número
          pointsWithOccurrence++;
          break; // Conta apenas uma vez por ponto
        }
      }
    }

    // Se não encontrou ocorrências, retorna null
    if (pointsWithOccurrence == 0) return null;

    // Calcula as métricas
    final frequency = (pointsWithOccurrence / points.length) * 100;
    final averageQuantity = totalQuantity / pointsWithOccurrence;
    final infestationPercentage = organism.calculateInfestationPercentage(averageQuantity.toInt());
    final alertLevel = organism.getAlertLevel(averageQuantity.toInt());
    final alertColor = organism.getAlertLevelColor(alertLevel);

    return InfestationResult(
      organism: organism,
      totalQuantity: totalQuantity,
      totalPoints: points.length,
      pointsWithOccurrence: pointsWithOccurrence,
      frequency: frequency,
      averageQuantity: averageQuantity,
      infestationPercentage: infestationPercentage,
      alertLevel: alertLevel.toString(),
      alertColor: alertColor,
    );
  }

  /// Calcula a infestação para um organismo específico usando regras personalizadas
  Future<InfestationResult?> _calculateOrganismInfestationWithRules(
    OrganismCatalog organism,
    List<MonitoringPoint> points,
    String farmId,
    String plotId,
  ) async {
    if (points.isEmpty) return null;

    int totalQuantity = 0;
    int pointsWithOccurrence = 0;

    // Conta as ocorrências do organismo em todos os pontos
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        // Verifica se a ocorrência corresponde ao organismo
        if (_matchesOrganism(occurrence, organism)) {
          totalQuantity += occurrence.infestationIndex.toInt();
          pointsWithOccurrence++;
          break; // Conta apenas uma vez por ponto
        }
      }
    }

    // Se não encontrou ocorrências, retorna null
    if (pointsWithOccurrence == 0) return null;

    // Busca regra personalizada (hierarquia: específica > global > padrão)
    InfestationRule? customRule = await _rulesRepository.getRuleForOrganism(
      organism.id,
      farmId,
    );

    // Calcula as métricas
    final frequency = (pointsWithOccurrence / points.length) * 100;
    final averageQuantity = totalQuantity / pointsWithOccurrence;
    final infestationPercentage = organism.calculateInfestationPercentage(averageQuantity.toInt());
    
    String alertLevel;
    String alertColor;
    
    if (customRule != null) {
      // Usa regra personalizada
      final levelString = customRule.getAlertLevel(infestationPercentage);
      alertLevel = _parseAlertLevel(levelString);
      alertColor = customRule.getAlertColor(infestationPercentage);
    } else {
      // Usa regra padrão do catálogo
      final levelString = organism.getAlertLevel(averageQuantity.toInt());
      alertLevel = levelString.toString();
      alertColor = organism.getAlertLevelColor(levelString);
    }

    return InfestationResult(
      organism: organism,
      totalQuantity: totalQuantity,
      totalPoints: points.length,
      pointsWithOccurrence: pointsWithOccurrence,
      frequency: frequency,
      averageQuantity: averageQuantity,
      infestationPercentage: infestationPercentage,
      alertLevel: alertLevel,
      alertColor: alertColor,
    );
  }

  /// Converte string de nível de alerta para string
  String _parseAlertLevel(String level) {
    switch (level.toUpperCase()) {
      case 'BAIXO':
        return 'low';
      case 'MÉDIO':
        return 'medium';
      case 'ALTO':
        return 'high';
      default:
        return 'low';
    }
  }

  /// Verifica se uma ocorrência corresponde ao organismo
  bool _matchesOrganism(Occurrence occurrence, OrganismCatalog organism) {
    // Verifica se o tipo corresponde
    if (occurrence.type != organism.type) return false;
    
    // Verifica se o nome corresponde (ignorando maiúsculas/minúsculas)
    final occurrenceName = occurrence.name.toLowerCase();
    final organismName = organism.name.toLowerCase();
    
    return occurrenceName.contains(organismName) || 
           organismName.contains(occurrenceName);
  }

  /// Calcula o nível de alerta geral baseado nos resultados individuais
  String _calculateOverallAlertLevel(List<InfestationResult> results) {
    if (results.isEmpty) return 'low';

    // Encontra o nível mais crítico
    String mostCritical = 'low';
    
    for (final result in results) {
      if (_getAlertLevelIndex(result.alertLevel) > _getAlertLevelIndex(mostCritical)) {
        mostCritical = result.alertLevel;
      }
    }

    return mostCritical;
  }

  /// Obtém o índice do nível de alerta para comparação
  int _getAlertLevelIndex(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 1;
      case 'medium':
        return 2;
      case 'high':
        return 3;
      case 'critical':
        return 4;
      default:
        return 1;
    }
  }

  /// Obtém a cor do nível de alerta
  String _getAlertLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return '#4CAF50'; // Verde
      case 'medium':
        return '#FF9800'; // Laranja
      case 'high':
        return '#F44336'; // Vermelho
      case 'critical':
        return '#9C27B0'; // Roxo
      default:
        return '#4CAF50'; // Verde padrão
    }
  }

  /// Calcula infestação para um ponto específico
  Future<List<InfestationResult>> calculatePointInfestation({
    required MonitoringPoint point,
    required String cropName,
  }) async {
    try {
      await _catalogRepository.initialize();
      final organisms = await _catalogRepository.getByCrop(cropName.toLowerCase());
      
      final List<InfestationResult> results = [];
      
      for (final organism in organisms) {
        final result = _calculateOrganismInfestation(organism, [point]);
        if (result != null) {
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      throw Exception('Erro ao calcular infestação do ponto: $e');
    }
  }

  /// Obtém recomendações baseadas nos resultados de infestação
  List<String> getRecommendations(MonitoringInfestationResult result) {
    final recommendations = <String>[];

    // Verifica se há resultados críticos
    final criticalResults = result.results.where((r) => r.alertLevel == 'critical').toList();
    if (criticalResults.isNotEmpty) {
      recommendations.add('🚨 AÇÃO IMEDIATA NECESSÁRIA: ${criticalResults.length} organismo(s) em nível crítico');
      for (final critical in criticalResults) {
        recommendations.add('• ${critical.organism.name}: ${critical.averageQuantity.toStringAsFixed(1)} ${critical.organism.unit}');
      }
    }

    // Verifica resultados altos
    final highResults = result.results.where((r) => r.alertLevel == 'high').toList();
    if (highResults.isNotEmpty) {
      recommendations.add('⚠️ ATENÇÃO: ${highResults.length} organismo(s) em nível alto');
      for (final high in highResults) {
        recommendations.add('• ${high.organism.name}: ${high.averageQuantity.toStringAsFixed(1)} ${high.organism.unit}');
      }
    }

    // Verifica resultados médios
    final mediumResults = result.results.where((r) => r.alertLevel == 'medium').toList();
    if (mediumResults.isNotEmpty) {
      recommendations.add('📊 MONITORAMENTO: ${mediumResults.length} organismo(s) em nível médio');
    }

    // Se não há problemas críticos ou altos
    if (criticalResults.isEmpty && highResults.isEmpty) {
      recommendations.add('✅ SITUAÇÃO CONTROLADA: Nenhum organismo em nível crítico ou alto');
    }

    // Recomendações gerais
    recommendations.add('📋 Próximo monitoramento recomendado em 7 dias');
    
    if (result.results.isNotEmpty) {
      final mostCritical = result.mostCriticalResult;
      if (mostCritical != null) {
        recommendations.add('🎯 Foco principal: ${mostCritical.organism.name}');
      }
    }

    return recommendations;
  }

  /// Gera relatório de infestação
  Map<String, dynamic> generateInfestationReport(MonitoringInfestationResult result) {
    final report = {
      'monitoring_info': {
        'id': result.monitoringId,
        'plot_name': result.plotName,
        'crop_name': result.cropName,
        'date': result.date.toIso8601String(),
        'total_points': result.totalPoints,
      },
      'overall_summary': {
        'alert_level': result.overallAlertLevel.toString().split('.').last,
        'alert_color': result.overallAlertColor,
        'total_organisms_found': result.results.length,
      },
      'organism_details': result.results.map((r) => {
        'name': r.organism.name,
        'type': r.organism.type.toString().split('.').last,
        'total_quantity': r.totalQuantity,
        'frequency': r.frequency,
        'average_quantity': r.averageQuantity,
        'infestation_percentage': r.infestationPercentage,
        'alert_level': r.alertLevel.toString().split('.').last,
        'alert_color': r.alertColor,
        'unit': r.organism.unit,
      }).toList(),
      'recommendations': getRecommendations(result),
      'generated_at': DateTime.now().toIso8601String(),
    };

    return report;
  }
}
