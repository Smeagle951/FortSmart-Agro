import '../models/enhanced_ai_organism_data.dart';
import '../repositories/enhanced_ai_organism_repository.dart';
import '../../../modules/infestation_map/models/infestation_summary.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';

/// Validador de alinhamento entre IA expandida e mapa de infestação
class AIInfestationAlignmentValidator {
  final EnhancedAIOrganismRepository _aiRepository = EnhancedAIOrganismRepository();

  /// Valida se os dados da IA estão alinhados para o mapa de infestação
  Future<Map<String, dynamic>> validateAlignment() async {
    try {
      Logger.info('🔍 Iniciando validação de alinhamento IA ↔ Mapa de Infestação');
      
      final organisms = await _aiRepository.getAllOrganisms();
      final validationReport = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'totalOrganisms': organisms.length,
        'alignmentScore': 0.0,
        'severityData': <String, dynamic>{},
        'phaseData': <String, dynamic>{},
        'economicData': <String, dynamic>{},
        'managementData': <String, dynamic>{},
        'infestationMapCompatibility': <String, dynamic>{},
        'recommendations': <String>[],
        'issues': <String>[],
      };

      // 1. Validação de dados de severidade
      await _validateSeverityData(organisms, validationReport);
      
      // 2. Validação de dados de fase
      await _validatePhaseData(organisms, validationReport);
      
      // 3. Validação de dados econômicos
      await _validateEconomicData(organisms, validationReport);
      
      // 4. Validação de dados de manejo
      await _validateManagementData(organisms, validationReport);
      
      // 5. Validação de compatibilidade com mapa de infestação
      await _validateInfestationMapCompatibility(organisms, validationReport);
      
      // 6. Cálculo do score de alinhamento
      _calculateAlignmentScore(validationReport);
      
      // 7. Geração de recomendações
      _generateRecommendations(validationReport);
      
      Logger.info('✅ Validação concluída - Score: ${validationReport['alignmentScore']}');
      return validationReport;

    } catch (e) {
      Logger.error('❌ Erro na validação de alinhamento: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Valida dados de severidade
  Future<void> _validateSeverityData(
    List<EnhancedAIOrganismData> organisms,
    Map<String, dynamic> report,
  ) async {
    int organismsWithSeverity = 0;
    int organismsWithCompleteSeverity = 0;
    final severityIssues = <String>[];
    
    for (final organism in organisms) {
      if (organism.severidadeDetalhada.isNotEmpty) {
        organismsWithSeverity++;
        
        // Verifica se tem todos os níveis
        final hasBaixo = organism.severidadeDetalhada.containsKey('baixo');
        final hasMedio = organism.severidadeDetalhada.containsKey('medio');
        final hasAlto = organism.severidadeDetalhada.containsKey('alto');
        
        if (hasBaixo && hasMedio && hasAlto) {
          organismsWithCompleteSeverity++;
        } else {
          severityIssues.add('${organism.name}: Severidade incompleta (faltam níveis)');
        }
        
        // Valida dados de cada nível
        for (final entry in organism.severidadeDetalhada.entries) {
          final severity = entry.value;
          if (severity.descricao.isEmpty) {
            severityIssues.add('${organism.name}: Descrição vazia para ${entry.key}');
          }
          if (severity.corAlerta.isEmpty) {
            severityIssues.add('${organism.name}: Cor de alerta vazia para ${entry.key}');
          }
          if (severity.acao.isEmpty) {
            severityIssues.add('${organism.name}: Ação vazia para ${entry.key}');
          }
        }
      } else {
        severityIssues.add('${organism.name}: Sem dados de severidade');
      }
    }
    
    report['severityData'] = {
      'organismsWithSeverity': organismsWithSeverity,
      'organismsWithCompleteSeverity': organismsWithCompleteSeverity,
      'severityCoverage': organisms.isNotEmpty ? (organismsWithSeverity / organisms.length) : 0.0,
      'completeSeverityCoverage': organisms.isNotEmpty ? (organismsWithCompleteSeverity / organisms.length) : 0.0,
      'issues': severityIssues,
    };
  }

  /// Valida dados de fase
  Future<void> _validatePhaseData(
    List<EnhancedAIOrganismData> organisms,
    Map<String, dynamic> report,
  ) async {
    int organismsWithPhase = 0;
    int organismsWithCompletePhase = 0;
    final phaseIssues = <String>[];
    
    for (final organism in organisms) {
      if (organism.fases.isNotEmpty) {
        organismsWithPhase++;
        
        // Verifica se tem pelo menos 2 fases
        if (organism.fases.length >= 2) {
          organismsWithCompletePhase++;
        } else {
          phaseIssues.add('${organism.name}: Poucas fases (${organism.fases.length})');
        }
        
        // Valida dados de cada fase
        for (final fase in organism.fases) {
          if (fase.fase.isEmpty) {
            phaseIssues.add('${organism.name}: Nome da fase vazio');
          }
          if (fase.tamanhoMM.isEmpty) {
            phaseIssues.add('${organism.name}: Tamanho da fase vazio');
          }
          if (fase.danos.isEmpty) {
            phaseIssues.add('${organism.name}: Danos da fase vazios');
          }
        }
      } else {
        phaseIssues.add('${organism.name}: Sem dados de fase');
      }
    }
    
    report['phaseData'] = {
      'organismsWithPhase': organismsWithPhase,
      'organismsWithCompletePhase': organismsWithCompletePhase,
      'phaseCoverage': organisms.isNotEmpty ? (organismsWithPhase / organisms.length) : 0.0,
      'completePhaseCoverage': organisms.isNotEmpty ? (organismsWithCompletePhase / organisms.length) : 0.0,
      'issues': phaseIssues,
    };
  }

  /// Valida dados econômicos
  Future<void> _validateEconomicData(
    List<EnhancedAIOrganismData> organisms,
    Map<String, dynamic> report,
  ) async {
    int organismsWithEconomic = 0;
    final economicIssues = <String>[];
    
    for (final organism in organisms) {
      if (organism.danoEconomico.descricao.isNotEmpty) {
        organismsWithEconomic++;
        
        // Valida descrição
        if (organism.danoEconomico.descricao.length < 10) {
          economicIssues.add('${organism.name}: Descrição econômica muito curta');
        }
        
        // Valida perda máxima
        if (organism.danoEconomico.perdaMaxima.isEmpty) {
          economicIssues.add('${organism.name}: Perda máxima não especificada');
        }
      } else {
        economicIssues.add('${organism.name}: Sem dados econômicos');
      }
    }
    
    report['economicData'] = {
      'organismsWithEconomic': organismsWithEconomic,
      'economicCoverage': organisms.isNotEmpty ? (organismsWithEconomic / organisms.length) : 0.0,
      'issues': economicIssues,
    };
  }

  /// Valida dados de manejo
  Future<void> _validateManagementData(
    List<EnhancedAIOrganismData> organisms,
    Map<String, dynamic> report,
  ) async {
    int organismsWithManagement = 0;
    int organismsWithCompleteManagement = 0;
    final managementIssues = <String>[];
    
    for (final organism in organisms) {
      final hasQuimico = organism.manejoIntegrado.quimico.isNotEmpty;
      final hasBiologico = organism.manejoIntegrado.biologico.isNotEmpty;
      final hasCultural = organism.manejoIntegrado.cultural.isNotEmpty;
      
      if (hasQuimico || hasBiologico || hasCultural) {
        organismsWithManagement++;
        
        if (hasQuimico && hasBiologico && hasCultural) {
          organismsWithCompleteManagement++;
        } else {
          managementIssues.add('${organism.name}: Manejo incompleto (faltam estratégias)');
        }
        
        // Valida qualidade das estratégias
        if (hasQuimico) {
          for (final estrategia in organism.manejoIntegrado.quimico) {
            if (estrategia.length < 5) {
              managementIssues.add('${organism.name}: Estratégia química muito curta: $estrategia');
            }
          }
        }
      } else {
        managementIssues.add('${organism.name}: Sem dados de manejo');
      }
    }
    
    report['managementData'] = {
      'organismsWithManagement': organismsWithManagement,
      'organismsWithCompleteManagement': organismsWithCompleteManagement,
      'managementCoverage': organisms.isNotEmpty ? (organismsWithManagement / organisms.length) : 0.0,
      'completeManagementCoverage': organisms.isNotEmpty ? (organismsWithCompleteManagement / organisms.length) : 0.0,
      'issues': managementIssues,
    };
  }

  /// Valida compatibilidade com mapa de infestação
  Future<void> _validateInfestationMapCompatibility(
    List<EnhancedAIOrganismData> organisms,
    Map<String, dynamic> report,
  ) async {
    int compatibleOrganisms = 0;
    final compatibilityIssues = <String>[];
    
    for (final organism in organisms) {
      bool isCompatible = true;
      final organismIssues = <String>[];
      
      // Verifica se tem dados mínimos para mapa de infestação
      if (organism.severidadeDetalhada.isEmpty) {
        isCompatible = false;
        organismIssues.add('Sem dados de severidade');
      }
      
      if (organism.limiaresAcao.baixo == 0 && organism.limiaresAcao.medio == 0 && organism.limiaresAcao.alto == 0) {
        isCompatible = false;
        organismIssues.add('Sem limiares de ação');
      }
      
      if (organism.crops.isEmpty) {
        isCompatible = false;
        organismIssues.add('Sem culturas associadas');
      }
      
      if (organism.condicoesFavoraveis.temperatura.isEmpty) {
        isCompatible = false;
        organismIssues.add('Sem dados de condições favoráveis');
      }
      
      if (isCompatible) {
        compatibleOrganisms++;
      } else {
        compatibilityIssues.add('${organism.name}: ${organismIssues.join(', ')}');
      }
    }
    
    report['infestationMapCompatibility'] = {
      'compatibleOrganisms': compatibleOrganisms,
      'compatibilityRate': organisms.isNotEmpty ? (compatibleOrganisms / organisms.length) : 0.0,
      'issues': compatibilityIssues,
    };
  }

  /// Calcula score de alinhamento
  void _calculateAlignmentScore(Map<String, dynamic> report) {
    final severityData = report['severityData'] as Map<String, dynamic>;
    final phaseData = report['phaseData'] as Map<String, dynamic>;
    final economicData = report['economicData'] as Map<String, dynamic>;
    final managementData = report['managementData'] as Map<String, dynamic>;
    final compatibility = report['infestationMapCompatibility'] as Map<String, dynamic>;
    
    // Pesos para cada categoria
    final severityWeight = 0.3;
    final phaseWeight = 0.2;
    final economicWeight = 0.2;
    final managementWeight = 0.15;
    final compatibilityWeight = 0.15;
    
    final severityScore = severityData['completeSeverityCoverage'] as double;
    final phaseScore = phaseData['completePhaseCoverage'] as double;
    final economicScore = economicData['economicCoverage'] as double;
    final managementScore = managementData['completeManagementCoverage'] as double;
    final compatibilityScore = compatibility['compatibilityRate'] as double;
    
    final alignmentScore = (severityScore * severityWeight) +
                          (phaseScore * phaseWeight) +
                          (economicScore * economicWeight) +
                          (managementScore * managementWeight) +
                          (compatibilityScore * compatibilityWeight);
    
    report['alignmentScore'] = alignmentScore;
  }

  /// Gera recomendações baseadas na validação
  void _generateRecommendations(Map<String, dynamic> report) {
    final recommendations = <String>[];
    final issues = <String>[];
    
    final severityData = report['severityData'] as Map<String, dynamic>;
    final phaseData = report['phaseData'] as Map<String, dynamic>;
    final economicData = report['economicData'] as Map<String, dynamic>;
    final managementData = report['managementData'] as Map<String, dynamic>;
    final compatibility = report['infestationMapCompatibility'] as Map<String, dynamic>;
    
    // Recomendações baseadas na severidade
    if (severityData['completeSeverityCoverage'] < 0.8) {
      recommendations.add('Expandir dados de severidade para mais organismos');
    }
    if (severityData['issues'].isNotEmpty) {
      issues.addAll(severityData['issues'] as List<String>);
    }
    
    // Recomendações baseadas na fase
    if (phaseData['completePhaseCoverage'] < 0.6) {
      recommendations.add('Adicionar dados de fase de desenvolvimento');
    }
    if (phaseData['issues'].isNotEmpty) {
      issues.addAll(phaseData['issues'] as List<String>);
    }
    
    // Recomendações baseadas em dados econômicos
    if (economicData['economicCoverage'] < 0.5) {
      recommendations.add('Incluir dados econômicos de danos');
    }
    if (economicData['issues'].isNotEmpty) {
      issues.addAll(economicData['issues'] as List<String>);
    }
    
    // Recomendações baseadas no manejo
    if (managementData['completeManagementCoverage'] < 0.7) {
      recommendations.add('Completar estratégias de manejo integrado');
    }
    if (managementData['issues'].isNotEmpty) {
      issues.addAll(managementData['issues'] as List<String>);
    }
    
    // Recomendações de compatibilidade
    if (compatibility['compatibilityRate'] < 0.9) {
      recommendations.add('Melhorar compatibilidade com mapa de infestação');
    }
    if (compatibility['issues'].isNotEmpty) {
      issues.addAll(compatibility['issues'] as List<String>);
    }
    
    report['recommendations'] = recommendations;
    report['issues'] = issues;
  }

  /// Valida dados específicos para um organismo
  Future<Map<String, dynamic>> validateOrganismForInfestationMap(String organismId) async {
    try {
      final organism = await _aiRepository.getOrganismById(organismId.hashCode);
      if (organism == null) {
        return {
          'valid': false,
          'error': 'Organismo não encontrado',
        };
      }
      
      final validation = <String, dynamic>{
        'organismId': organismId,
        'organismName': organism.name,
        'valid': true,
        'severityData': organism.severidadeDetalhada.isNotEmpty,
        'phaseData': organism.fases.isNotEmpty,
        'economicData': organism.danoEconomico.descricao.isNotEmpty,
        'managementData': organism.manejoIntegrado.quimico.isNotEmpty || 
                         organism.manejoIntegrado.biologico.isNotEmpty || 
                         organism.manejoIntegrado.cultural.isNotEmpty,
        'actionLimits': organism.limiaresAcao.baixo > 0 || organism.limiaresAcao.medio > 0 || organism.limiaresAcao.alto > 0,
        'favorableConditions': organism.condicoesFavoraveis.temperatura.isNotEmpty,
        'crops': organism.crops.isNotEmpty,
        'issues': <String>[],
        'recommendations': <String>[],
      };
      
      // Verifica problemas específicos
      if (!validation['severityData']) {
        validation['issues'].add('Sem dados de severidade');
        validation['recommendations'].add('Adicionar dados de severidade detalhada');
      }
      
      if (!validation['phaseData']) {
        validation['issues'].add('Sem dados de fase');
        validation['recommendations'].add('Adicionar fases de desenvolvimento');
      }
      
      if (!validation['economicData']) {
        validation['issues'].add('Sem dados econômicos');
        validation['recommendations'].add('Adicionar dados de danos econômicos');
      }
      
      if (!validation['managementData']) {
        validation['issues'].add('Sem dados de manejo');
        validation['recommendations'].add('Adicionar estratégias de manejo');
      }
      
      if (!validation['actionLimits']) {
        validation['issues'].add('Sem limiares de ação');
        validation['recommendations'].add('Definir limiares de ação');
      }
      
      if (!validation['favorableConditions']) {
        validation['issues'].add('Sem condições favoráveis');
        validation['recommendations'].add('Adicionar condições favoráveis');
      }
      
      if (!validation['crops']) {
        validation['issues'].add('Sem culturas associadas');
        validation['recommendations'].add('Associar culturas');
      }
      
      // Calcula score de validação
      final totalChecks = 7;
      final passedChecks = [
        validation['severityData'],
        validation['phaseData'],
        validation['economicData'],
        validation['managementData'],
        validation['actionLimits'],
        validation['favorableConditions'],
        validation['crops'],
      ].where((check) => check == true).length;
      
      validation['validationScore'] = passedChecks / totalChecks;
      validation['valid'] = validation['validationScore'] >= 0.7;
      
      return validation;

    } catch (e) {
      Logger.error('❌ Erro na validação do organismo: $e');
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }

  /// Gera relatório de alinhamento
  Future<Map<String, dynamic>> generateAlignmentReport() async {
    try {
      final validation = await validateAlignment();
      
      final report = {
        'title': 'Relatório de Alinhamento IA ↔ Mapa de Infestação',
        'timestamp': DateTime.now().toIso8601String(),
        'summary': {
          'totalOrganisms': validation['totalOrganisms'],
          'alignmentScore': validation['alignmentScore'],
          'status': validation['alignmentScore'] >= 0.8 ? 'Excelente' : 
                   validation['alignmentScore'] >= 0.6 ? 'Bom' : 
                   validation['alignmentScore'] >= 0.4 ? 'Regular' : 'Ruim',
        },
        'details': validation,
        'nextSteps': _generateNextSteps(validation),
      };
      
      return report;

    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Gera próximos passos baseados na validação
  List<String> _generateNextSteps(Map<String, dynamic> validation) {
    final nextSteps = <String>[];
    
    if (validation['alignmentScore'] < 0.8) {
      nextSteps.add('Melhorar dados de severidade para organismos sem informações completas');
    }
    
    if (validation['phaseData']['completePhaseCoverage'] < 0.6) {
      nextSteps.add('Adicionar dados de fase de desenvolvimento para mais organismos');
    }
    
    if (validation['economicData']['economicCoverage'] < 0.5) {
      nextSteps.add('Incluir dados econômicos de danos para organismos importantes');
    }
    
    if (validation['managementData']['completeManagementCoverage'] < 0.7) {
      nextSteps.add('Completar estratégias de manejo integrado');
    }
    
    if (validation['infestationMapCompatibility']['compatibilityRate'] < 0.9) {
      nextSteps.add('Resolver problemas de compatibilidade com mapa de infestação');
    }
    
    nextSteps.add('Testar integração com mapa de infestação em ambiente de desenvolvimento');
    nextSteps.add('Validar mapas térmicos com dados reais de campo');
    
    return nextSteps;
  }
}
