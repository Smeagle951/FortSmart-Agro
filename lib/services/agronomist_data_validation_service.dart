import 'dart:math';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';

/// Resultado da validação de dados
class DataValidationResult {
  final bool isValid;
  final double confidenceScore;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, dynamic> metadata;
  final String qualityLevel;

  DataValidationResult({
    required this.isValid,
    required this.confidenceScore,
    required this.warnings,
    required this.errors,
    required this.metadata,
    required this.qualityLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'confidenceScore': confidenceScore,
      'warnings': warnings,
      'errors': errors,
      'metadata': metadata,
      'qualityLevel': qualityLevel,
    };
  }
}

/// Serviço de validação de dados agronômicos
/// Garante confiabilidade e qualidade dos dados para relatórios profissionais
class AgronomistDataValidationService {
  
  /// Valida dados de monitoramento para relatórios agronômicos
  Future<DataValidationResult> validateMonitoringData(Monitoring monitoring) async {
    try {
      Logger.info('🔍 [VALIDAÇÃO] Validando dados de monitoramento: ${monitoring.id}');
      
      final warnings = <String>[];
      final errors = <String>[];
      final metadata = <String, dynamic>{};
      double confidenceScore = 100.0;
      
      // 1. Validação básica de estrutura
      final structureValidation = _validateStructure(monitoring);
      warnings.addAll(structureValidation['warnings']);
      errors.addAll(structureValidation['errors']);
      confidenceScore -= structureValidation['penalty'];
      
      // 2. Validação de precisão GPS
      final gpsValidation = _validateGPSAccuracy(monitoring);
      warnings.addAll(gpsValidation['warnings']);
      errors.addAll(gpsValidation['errors']);
      confidenceScore -= gpsValidation['penalty'];
      
      // 3. Validação de dados de infestação
      final infestationValidation = _validateInfestationData(monitoring);
      warnings.addAll(infestationValidation['warnings']);
      errors.addAll(infestationValidation['errors']);
      confidenceScore -= infestationValidation['penalty'];
      
      // 4. Validação de consistência temporal
      final temporalValidation = _validateTemporalConsistency(monitoring);
      warnings.addAll(temporalValidation['warnings']);
      errors.addAll(temporalValidation['errors']);
      confidenceScore -= temporalValidation['penalty'];
      
      // 5. Validação de qualidade dos dados
      final qualityValidation = _validateDataQuality(monitoring);
      warnings.addAll(qualityValidation['warnings']);
      errors.addAll(qualityValidation['errors']);
      confidenceScore -= qualityValidation['penalty'];
      
      // Calcular score final
      confidenceScore = confidenceScore.clamp(0.0, 100.0);
      
      // Determinar nível de qualidade
      final qualityLevel = _determineQualityLevel(confidenceScore, errors.length);
      
      // Coletar metadados
      metadata['totalPoints'] = monitoring.points.length;
      metadata['totalOccurrences'] = monitoring.points.fold(0, (sum, point) => sum + point.occurrences.length);
      metadata['averageAccuracy'] = _calculateAverageAccuracy(monitoring);
      metadata['dataCompleteness'] = _calculateDataCompleteness(monitoring);
      metadata['temporalConsistency'] = _calculateTemporalConsistency(monitoring);
      
      final result = DataValidationResult(
        isValid: errors.isEmpty && confidenceScore >= 70.0,
        confidenceScore: confidenceScore,
        warnings: warnings,
        errors: errors,
        metadata: metadata,
        qualityLevel: qualityLevel,
      );
      
      Logger.info('✅ [VALIDAÇÃO] Validação concluída - Score: ${confidenceScore.toStringAsFixed(1)}% - Nível: $qualityLevel');
      
      return result;
      
    } catch (e) {
      Logger.error('❌ [VALIDAÇÃO] Erro na validação: $e');
      return DataValidationResult(
        isValid: false,
        confidenceScore: 0.0,
        warnings: [],
        errors: ['Erro na validação: $e'],
        metadata: {},
        qualityLevel: 'INVÁLIDO',
      );
    }
  }

  /// Valida estrutura dos dados
  Map<String, dynamic> _validateStructure(Monitoring monitoring) {
    final warnings = <String>[];
    final errors = <String>[];
    double penalty = 0.0;
    
    // Verificar se há pontos
    if (monitoring.points.isEmpty) {
      errors.add('❌ Nenhum ponto de monitoramento encontrado');
      penalty += 50.0;
    } else if (monitoring.points.length < 3) {
      warnings.add('⚠️ Poucos pontos de monitoramento (${monitoring.points.length})');
      penalty += 10.0;
    }
    
    // Verificar se há ocorrências
    final totalOccurrences = monitoring.points.fold(0, (sum, point) => sum + point.occurrences.length);
    if (totalOccurrences == 0) {
      errors.add('❌ Nenhuma ocorrência encontrada nos pontos');
      penalty += 40.0;
    } else if (totalOccurrences < 2) {
      warnings.add('⚠️ Poucas ocorrências encontradas ($totalOccurrences)');
      penalty += 5.0;
    }
    
    // Verificar se há infestações
    final infestationCount = monitoring.points.fold(0, (sum, point) => 
      sum + point.occurrences.where((occ) => occ.infestationIndex > 0).length);
    
    if (infestationCount == 0) {
      warnings.add('⚠️ Nenhuma infestação detectada (infestation_index = 0)');
      penalty += 15.0;
    }
    
    return {
      'warnings': warnings,
      'errors': errors,
      'penalty': penalty,
    };
  }

  /// Valida precisão GPS
  Map<String, dynamic> _validateGPSAccuracy(Monitoring monitoring) {
    final warnings = <String>[];
    final errors = <String>[];
    double penalty = 0.0;
    
    for (final point in monitoring.points) {
      final accuracy = point.gpsAccuracy ?? 10.0;
      
      if (accuracy > 20.0) {
        errors.add('❌ Precisão GPS muito baixa: ${accuracy.toStringAsFixed(1)}m');
        penalty += 20.0;
      } else if (accuracy > 10.0) {
        warnings.add('⚠️ Precisão GPS moderada: ${accuracy.toStringAsFixed(1)}m');
        penalty += 5.0;
      } else if (accuracy <= 2.0) {
        // Precisão excelente - bonus
        penalty -= 2.0;
      }
    }
    
    return {
      'warnings': warnings,
      'errors': errors,
      'penalty': penalty,
    };
  }

  /// Valida dados de infestação
  Map<String, dynamic> _validateInfestationData(Monitoring monitoring) {
    final warnings = <String>[];
    final errors = <String>[];
    double penalty = 0.0;
    
    for (final point in monitoring.points) {
      for (final occurrence in point.occurrences) {
        // Verificar índice de infestação
        if (occurrence.infestationIndex < 0 || occurrence.infestationIndex > 100) {
          errors.add('❌ Índice de infestação inválido: ${occurrence.infestationIndex}%');
          penalty += 15.0;
        } else if (occurrence.infestationIndex > 0 && occurrence.infestationIndex < 5) {
          warnings.add('⚠️ Índice de infestação muito baixo: ${occurrence.infestationIndex}%');
          penalty += 2.0;
        }
        
        // Verificar se há observações
        if (occurrence.notes == null || occurrence.notes!.isEmpty) {
          warnings.add('⚠️ Ocorrência sem observações: ${occurrence.name}');
          penalty += 1.0;
        }
        
        // Verificar seções afetadas
        if (occurrence.affectedSections.isEmpty) {
          warnings.add('⚠️ Nenhuma seção afetada especificada: ${occurrence.name}');
          penalty += 1.0;
        }
      }
    }
    
    return {
      'warnings': warnings,
      'errors': errors,
      'penalty': penalty,
    };
  }

  /// Valida consistência temporal
  Map<String, dynamic> _validateTemporalConsistency(Monitoring monitoring) {
    final warnings = <String>[];
    final errors = <String>[];
    double penalty = 0.0;
    
    // Verificar se a data do monitoramento é recente
    final daysSinceMonitoring = DateTime.now().difference(monitoring.date).inDays;
    
    if (daysSinceMonitoring > 30) {
      warnings.add('⚠️ Dados antigos: ${daysSinceMonitoring} dias');
      penalty += 5.0;
    } else if (daysSinceMonitoring > 7) {
      warnings.add('⚠️ Dados não recentes: ${daysSinceMonitoring} dias');
      penalty += 2.0;
    }
    
    // Verificar consistência entre pontos
    final pointDates = monitoring.points.map((p) => p.createdAt).toList();
    if (pointDates.isNotEmpty) {
      final minDate = pointDates.reduce((a, b) => a.isBefore(b) ? a : b);
      final maxDate = pointDates.reduce((a, b) => a.isAfter(b) ? a : b);
      final timeSpan = maxDate.difference(minDate).inHours;
      
      if (timeSpan > 24) {
        warnings.add('⚠️ Monitoramento realizado em período longo: ${timeSpan.toStringAsFixed(1)}h');
        penalty += 3.0;
      }
    }
    
    return {
      'warnings': warnings,
      'errors': errors,
      'penalty': penalty,
    };
  }

  /// Valida qualidade dos dados
  Map<String, dynamic> _validateDataQuality(Monitoring monitoring) {
    final warnings = <String>[];
    final errors = <String>[];
    double penalty = 0.0;
    
    // Verificar completude dos dados
    int completePoints = 0;
    int totalPoints = monitoring.points.length;
    
    for (final point in monitoring.points) {
      bool isComplete = true;
      
      // Verificar coordenadas
      if (point.latitude == 0.0 || point.longitude == 0.0) {
        isComplete = false;
      }
      
      // Verificar ocorrências
      if (point.occurrences.isEmpty) {
        isComplete = false;
      }
      
      // Verificar dados das ocorrências
      for (final occurrence in point.occurrences) {
        if (occurrence.name.isEmpty || occurrence.type == OccurrenceType.other) {
          isComplete = false;
        }
      }
      
      if (isComplete) completePoints++;
    }
    
    final completeness = totalPoints > 0 ? (completePoints / totalPoints) * 100 : 0.0;
    
    if (completeness < 50.0) {
      errors.add('❌ Dados muito incompletos: ${completeness.toStringAsFixed(1)}%');
      penalty += 25.0;
    } else if (completeness < 80.0) {
      warnings.add('⚠️ Dados parcialmente incompletos: ${completeness.toStringAsFixed(1)}%');
      penalty += 10.0;
    }
    
    return {
      'warnings': warnings,
      'errors': errors,
      'penalty': penalty,
    };
  }

  /// Determina nível de qualidade
  String _determineQualityLevel(double confidenceScore, int errorCount) {
    if (errorCount > 0) return 'INVÁLIDO';
    if (confidenceScore >= 95.0) return 'EXCELENTE';
    if (confidenceScore >= 85.0) return 'MUITO BOM';
    if (confidenceScore >= 75.0) return 'BOM';
    if (confidenceScore >= 65.0) return 'REGULAR';
    return 'BAIXO';
  }

  /// Calcula precisão média
  double _calculateAverageAccuracy(Monitoring monitoring) {
    if (monitoring.points.isEmpty) return 0.0;
    
    double totalAccuracy = 0.0;
    for (final point in monitoring.points) {
      totalAccuracy += point.gpsAccuracy ?? 10.0;
    }
    
    return totalAccuracy / monitoring.points.length;
  }

  /// Calcula completude dos dados
  double _calculateDataCompleteness(Monitoring monitoring) {
    if (monitoring.points.isEmpty) return 0.0;
    
    int completeFields = 0;
    int totalFields = 0;
    
    for (final point in monitoring.points) {
      // Coordenadas
      totalFields += 2;
      if (point.latitude != 0.0 && point.longitude != 0.0) completeFields += 2;
      
      // Precisão GPS
      totalFields += 1;
      if (point.gpsAccuracy != null && point.gpsAccuracy! > 0) completeFields += 1;
      
      // Ocorrências
      for (final occurrence in point.occurrences) {
        totalFields += 3; // nome, tipo, índice
        if (occurrence.name.isNotEmpty) completeFields += 1;
        if (occurrence.type != OccurrenceType.other) completeFields += 1;
        if (occurrence.infestationIndex >= 0) completeFields += 1;
      }
    }
    
    return totalFields > 0 ? (completeFields / totalFields) * 100 : 0.0;
  }

  /// Calcula consistência temporal
  double _calculateTemporalConsistency(Monitoring monitoring) {
    if (monitoring.points.length < 2) return 100.0;
    
    final pointDates = monitoring.points.map((p) => p.createdAt).toList();
    final minDate = pointDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = pointDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final timeSpan = maxDate.difference(minDate).inHours;
    
    // Penalizar se o monitoramento foi feito em período muito longo
    if (timeSpan > 24) return max(0.0, 100.0 - (timeSpan - 24) * 2);
    return 100.0;
  }

  /// Valida dados para relatório executivo
  Future<DataValidationResult> validateExecutiveReportData(List<Monitoring> monitorings) async {
    try {
      Logger.info('🔍 [VALIDAÇÃO] Validando dados para relatório executivo...');
      
      final warnings = <String>[];
      final errors = <String>[];
      final metadata = <String, dynamic>{};
      double confidenceScore = 100.0;
      
      // Verificar quantidade de monitoramentos
      if (monitorings.isEmpty) {
        errors.add('❌ Nenhum monitoramento encontrado');
        return DataValidationResult(
          isValid: false,
          confidenceScore: 0.0,
          warnings: warnings,
          errors: errors,
          metadata: metadata,
          qualityLevel: 'INVÁLIDO',
        );
      }
      
      if (monitorings.length < 3) {
        warnings.add('⚠️ Poucos monitoramentos para análise estatística (${monitorings.length})');
        confidenceScore -= 10.0;
      }
      
      // Validar cada monitoramento
      int validMonitorings = 0;
      double totalConfidence = 0.0;
      
      for (final monitoring in monitorings) {
        final validation = await validateMonitoringData(monitoring);
        if (validation.isValid) {
          validMonitorings++;
          totalConfidence += validation.confidenceScore;
        }
      }
      
      final averageConfidence = validMonitorings > 0 ? totalConfidence / validMonitorings : 0.0;
      final dataQuality = (validMonitorings / monitorings.length) * 100;
      
      if (dataQuality < 50.0) {
        errors.add('❌ Muitos monitoramentos inválidos: ${(100 - dataQuality).toStringAsFixed(1)}%');
        confidenceScore -= 30.0;
      } else if (dataQuality < 80.0) {
        warnings.add('⚠️ Alguns monitoramentos com problemas: ${(100 - dataQuality).toStringAsFixed(1)}%');
        confidenceScore -= 15.0;
      }
      
      // Ajustar score baseado na confiança média
      confidenceScore = (confidenceScore + averageConfidence) / 2;
      
      metadata['totalMonitorings'] = monitorings.length;
      metadata['validMonitorings'] = validMonitorings;
      metadata['dataQuality'] = dataQuality;
      metadata['averageConfidence'] = averageConfidence;
      
      final qualityLevel = _determineQualityLevel(confidenceScore, errors.length);
      
      final result = DataValidationResult(
        isValid: errors.isEmpty && confidenceScore >= 70.0,
        confidenceScore: confidenceScore,
        warnings: warnings,
        errors: errors,
        metadata: metadata,
        qualityLevel: qualityLevel,
      );
      
      Logger.info('✅ [VALIDAÇÃO] Validação executiva concluída - Score: ${confidenceScore.toStringAsFixed(1)}% - Nível: $qualityLevel');
      
      return result;
      
    } catch (e) {
      Logger.error('❌ [VALIDAÇÃO] Erro na validação executiva: $e');
      return DataValidationResult(
        isValid: false,
        confidenceScore: 0.0,
        warnings: [],
        errors: ['Erro na validação executiva: $e'],
        metadata: {},
        qualityLevel: 'INVÁLIDO',
      );
    }
  }
}
