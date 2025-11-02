import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/organism_catalog.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';

/// Serviço para validação de dados com especialistas agrícolas
class AgriculturalExpertValidationService {
  static const String _tag = 'AGRICULTURAL_EXPERT_VALIDATION';

  /// Valida dados de organismos contra critérios de especialistas
  Future<ValidationResult> validateOrganismData(OrganismCatalog organism) async {
    try {
      Logger.info('$_tag: Validando dados do organismo: ${organism.name}');
      
      final List<ValidationIssue> issues = [];
      final List<ValidationSuggestion> suggestions = [];
      
      // 1. Validação de limites de ação
      final limitValidation = _validateActionLimits(organism);
      issues.addAll(limitValidation.issues);
      suggestions.addAll(limitValidation.suggestions);
      
      // 2. Validação de nomenclatura
      final nomenclatureValidation = _validateNomenclature(organism);
      issues.addAll(nomenclatureValidation.issues);
      suggestions.addAll(nomenclatureValidation.suggestions);
      
      // 3. Validação de unidade de medida
      final unitValidation = _validateUnit(organism);
      issues.addAll(unitValidation.issues);
      suggestions.addAll(unitValidation.suggestions);
      
      // 4. Validação de descrição
      final descriptionValidation = _validateDescription(organism);
      issues.addAll(descriptionValidation.issues);
      suggestions.addAll(descriptionValidation.suggestions);
      
      // 5. Validação de consistência com especialistas
      final expertValidation = await _validateWithExpertCriteria(organism);
      issues.addAll(expertValidation.issues);
      suggestions.addAll(expertValidation.suggestions);
      
      final severity = _calculateOverallSeverity(issues);
      
      Logger.info('$_tag: Validação concluída - ${issues.length} problemas, ${suggestions.length} sugestões');
      
      return ValidationResult(
        organism: organism,
        isValid: severity == ValidationSeverity.none,
        severity: severity,
        issues: issues,
        suggestions: suggestions,
        validatedAt: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('$_tag: Erro na validação: $e');
      return ValidationResult(
        organism: organism,
        isValid: false,
        severity: ValidationSeverity.critical,
        issues: [ValidationIssue(
          type: ValidationIssueType.system,
          severity: ValidationSeverity.critical,
          message: 'Erro no sistema de validação: $e',
          field: 'system',
        )],
        suggestions: [],
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Valida limites de ação
  ValidationResult _validateActionLimits(OrganismCatalog organism) {
    final issues = <ValidationIssue>[];
    final suggestions = <ValidationSuggestion>[];
    
    // Verificar se os limites estão em ordem crescente
    if (organism.lowLimit >= organism.mediumLimit) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.logic,
        severity: ValidationSeverity.high,
        message: 'Limite baixo deve ser menor que limite médio',
        field: 'limits',
        currentValue: '${organism.lowLimit} >= ${organism.mediumLimit}',
      ));
      
      suggestions.add(ValidationSuggestion(
        type: SuggestionType.correction,
        message: 'Ajustar limite baixo para ${(organism.mediumLimit * 0.5).round()}',
        field: 'lowLimit',
        suggestedValue: (organism.mediumLimit * 0.5).round(),
      ));
    }
    
    if (organism.mediumLimit >= organism.highLimit) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.logic,
        severity: ValidationSeverity.high,
        message: 'Limite médio deve ser menor que limite alto',
        field: 'limits',
        currentValue: '${organism.mediumLimit} >= ${organism.highLimit}',
      ));
      
      suggestions.add(ValidationSuggestion(
        type: SuggestionType.correction,
        message: 'Ajustar limite médio para ${(organism.highLimit * 0.7).round()}',
        field: 'mediumLimit',
        suggestedValue: (organism.highLimit * 0.7).round(),
      ));
    }
    
    // Verificar se os limites são realistas para o tipo de organismo
    final realisticLimits = _getRealisticLimits(organism.type, organism.unit);
    if (realisticLimits != null) {
      final minLimit = realisticLimits['min'];
      final maxLimit = realisticLimits['max'];
      
      if (minLimit != null && maxLimit != null) {
        if (organism.lowLimit < minLimit || organism.lowLimit > maxLimit) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.expert,
            severity: ValidationSeverity.medium,
            message: 'Limite baixo fora do range esperado para ${organism.type}',
            field: 'lowLimit',
            currentValue: organism.lowLimit.toString(),
          ));
        }
        
        if (organism.highLimit > maxLimit * 2) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.expert,
            severity: ValidationSeverity.medium,
            message: 'Limite alto muito elevado para ${organism.type}',
            field: 'highLimit',
            currentValue: organism.highLimit.toString(),
          ));
        }
      }
    }
    
    return ValidationResult(
      organism: organism,
      isValid: issues.isEmpty,
      severity: _calculateOverallSeverity(issues),
      issues: issues,
      suggestions: suggestions,
      validatedAt: DateTime.now(),
    );
  }

  /// Valida nomenclatura
  ValidationResult _validateNomenclature(OrganismCatalog organism) {
    final issues = <ValidationIssue>[];
    final suggestions = <ValidationSuggestion>[];
    
    // Verificar nome comum
    if (organism.name.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.required,
        severity: ValidationSeverity.critical,
        message: 'Nome comum é obrigatório',
        field: 'name',
      ));
    } else if (organism.name.length < 3) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.format,
        severity: ValidationSeverity.medium,
        message: 'Nome comum muito curto',
        field: 'name',
        currentValue: organism.name,
      ));
    }
    
    // Verificar nome científico
    if (organism.scientificName.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.required,
        severity: ValidationSeverity.high,
        message: 'Nome científico é obrigatório',
        field: 'scientificName',
      ));
    } else if (!_isValidScientificName(organism.scientificName)) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.format,
        severity: ValidationSeverity.medium,
        message: 'Formato do nome científico inválido',
        field: 'scientificName',
        currentValue: organism.scientificName,
      ));
      
      suggestions.add(ValidationSuggestion(
        type: SuggestionType.format,
        message: 'Nome científico deve seguir formato: Gênero espécie',
        field: 'scientificName',
        example: 'Anthonomus grandis',
      ));
    }
    
    return ValidationResult(
      organism: organism,
      isValid: issues.isEmpty,
      severity: _calculateOverallSeverity(issues),
      issues: issues,
      suggestions: suggestions,
      validatedAt: DateTime.now(),
    );
  }

  /// Valida unidade de medida
  ValidationResult _validateUnit(OrganismCatalog organism) {
    final issues = <ValidationIssue>[];
    final suggestions = <ValidationSuggestion>[];
    
    final validUnits = _getValidUnits(organism.type);
    
    if (!validUnits.contains(organism.unit.toLowerCase())) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.expert,
        severity: ValidationSeverity.medium,
        message: 'Unidade de medida não é padrão para ${organism.type}',
        field: 'unit',
        currentValue: organism.unit,
      ));
      
      suggestions.add(ValidationSuggestion(
        type: SuggestionType.correction,
        message: 'Unidades recomendadas: ${validUnits.join(', ')}',
        field: 'unit',
        suggestedValue: validUnits.first,
      ));
    }
    
    return ValidationResult(
      organism: organism,
      isValid: issues.isEmpty,
      severity: _calculateOverallSeverity(issues),
      issues: issues,
      suggestions: suggestions,
      validatedAt: DateTime.now(),
    );
  }

  /// Valida descrição
  ValidationResult _validateDescription(OrganismCatalog organism) {
    final issues = <ValidationIssue>[];
    final suggestions = <ValidationSuggestion>[];
    
    if (organism.description == null || organism.description!.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.required,
        severity: ValidationSeverity.medium,
        message: 'Descrição é recomendada',
        field: 'description',
      ));
      
      suggestions.add(ValidationSuggestion(
        type: SuggestionType.enhancement,
        message: 'Adicionar descrição com sintomas e danos',
        field: 'description',
        example: 'Descrever sintomas, danos econômicos e condições favoráveis',
      ));
    } else if (organism.description!.length < 20) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.quality,
        severity: ValidationSeverity.low,
        message: 'Descrição muito curta',
        field: 'description',
        currentValue: '${organism.description!.length} caracteres',
      ));
    }
    
    return ValidationResult(
      organism: organism,
      isValid: issues.isEmpty,
      severity: _calculateOverallSeverity(issues),
      issues: issues,
      suggestions: suggestions,
      validatedAt: DateTime.now(),
    );
  }

  /// Valida com critérios de especialistas
  Future<ValidationResult> _validateWithExpertCriteria(OrganismCatalog organism) async {
    final issues = <ValidationIssue>[];
    final suggestions = <ValidationSuggestion>[];
    
    try {
      // Carregar critérios de especialistas
      final expertCriteria = await _loadExpertCriteria();
      
      // Validar contra critérios específicos do tipo
      final typeCriteria = expertCriteria[organism.type.toString().split('.').last];
      if (typeCriteria != null) {
        // Validar limites específicos
        if (typeCriteria.containsKey('limits')) {
          final limits = typeCriteria['limits'] as Map<String, dynamic>;
          if (limits.containsKey('min') && organism.lowLimit < limits['min']) {
            issues.add(ValidationIssue(
              type: ValidationIssueType.expert,
              severity: ValidationSeverity.medium,
              message: 'Limite baixo abaixo do mínimo recomendado por especialistas',
              field: 'lowLimit',
              currentValue: organism.lowLimit.toString(),
            ));
          }
        }
        
        // Validar unidade específica
        if (typeCriteria.containsKey('preferred_units')) {
          final preferredUnits = List<String>.from(typeCriteria['preferred_units']);
          if (!preferredUnits.contains(organism.unit.toLowerCase())) {
            suggestions.add(ValidationSuggestion(
              type: SuggestionType.expert,
              message: 'Especialistas recomendam: ${preferredUnits.join(', ')}',
              field: 'unit',
              suggestedValue: preferredUnits.first,
            ));
          }
        }
      }
      
    } catch (e) {
      Logger.warning('$_tag: Erro ao carregar critérios de especialistas: $e');
    }
    
    return ValidationResult(
      organism: organism,
      isValid: issues.isEmpty,
      severity: _calculateOverallSeverity(issues),
      issues: issues,
      suggestions: suggestions,
      validatedAt: DateTime.now(),
    );
  }

  /// Carrega critérios de especialistas
  Future<Map<String, dynamic>> _loadExpertCriteria() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/expert_criteria.json');
      return json.decode(jsonString);
    } catch (e) {
      Logger.warning('$_tag: Arquivo de critérios não encontrado, usando padrões');
      return _getDefaultExpertCriteria();
    }
  }

  /// Critérios padrão de especialistas
  Map<String, dynamic> _getDefaultExpertCriteria() {
    return {
      'pest': {
        'limits': {'min': 1, 'max': 100},
        'preferred_units': ['indivíduos/m²', 'insetos/m²', '%'],
      },
      'disease': {
        'limits': {'min': 1, 'max': 100},
        'preferred_units': ['%', 'folhas/m²', 'plantas/m²'],
      },
      'weed': {
        'limits': {'min': 1, 'max': 50},
        'preferred_units': ['plantas/m²', '%', 'indivíduos/m²'],
      },
    };
  }

  /// Obtém limites realistas para o tipo de organismo
  Map<String, int>? _getRealisticLimits(OccurrenceType type, String unit) {
    switch (type) {
      case OccurrenceType.pest:
        return {'min': 1, 'max': 100};
      case OccurrenceType.disease:
        return {'min': 1, 'max': 100};
      case OccurrenceType.weed:
        return {'min': 1, 'max': 50};
      default:
        return null;
    }
  }

  /// Obtém unidades válidas para o tipo
  List<String> _getValidUnits(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return ['indivíduos/m²', 'insetos/m²', '%', 'unidades'];
      case OccurrenceType.disease:
        return ['%', 'folhas/m²', 'plantas/m²', 'unidades'];
      case OccurrenceType.weed:
        return ['plantas/m²', '%', 'indivíduos/m²', 'unidades'];
      default:
        return ['unidades', '%'];
    }
  }

  /// Valida formato do nome científico
  bool _isValidScientificName(String name) {
    // Formato básico: Gênero espécie (opcional: subsp. subespécie)
    final regex = RegExp(r'^[A-Z][a-z]+ [a-z]+(?:\s+[a-z]+)*$');
    return regex.hasMatch(name);
  }

  /// Calcula severidade geral
  ValidationSeverity _calculateOverallSeverity(List<ValidationIssue> issues) {
    if (issues.isEmpty) return ValidationSeverity.none;
    
    if (issues.any((issue) => issue.severity == ValidationSeverity.critical)) {
      return ValidationSeverity.critical;
    }
    if (issues.any((issue) => issue.severity == ValidationSeverity.high)) {
      return ValidationSeverity.high;
    }
    if (issues.any((issue) => issue.severity == ValidationSeverity.medium)) {
      return ValidationSeverity.medium;
    }
    return ValidationSeverity.low;
  }
}

/// Resultado da validação
class ValidationResult {
  final OrganismCatalog organism;
  final bool isValid;
  final ValidationSeverity severity;
  final List<ValidationIssue> issues;
  final List<ValidationSuggestion> suggestions;
  final DateTime validatedAt;

  ValidationResult({
    required this.organism,
    required this.isValid,
    required this.severity,
    required this.issues,
    required this.suggestions,
    required this.validatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'organism_id': organism.id,
      'organism_name': organism.name,
      'is_valid': isValid,
      'severity': severity.toString(),
      'issues_count': issues.length,
      'suggestions_count': suggestions.length,
      'validated_at': validatedAt.toIso8601String(),
    };
  }
}

/// Problema de validação
class ValidationIssue {
  final ValidationIssueType type;
  final ValidationSeverity severity;
  final String message;
  final String field;
  final String? currentValue;

  ValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.field,
    this.currentValue,
  });
}

/// Sugestão de melhoria
class ValidationSuggestion {
  final SuggestionType type;
  final String message;
  final String field;
  final dynamic suggestedValue;
  final String? example;

  ValidationSuggestion({
    required this.type,
    required this.message,
    required this.field,
    this.suggestedValue,
    this.example,
  });
}

/// Tipos de problema de validação
enum ValidationIssueType {
  required,
  format,
  logic,
  expert,
  quality,
  system,
}

/// Tipos de sugestão
enum SuggestionType {
  correction,
  enhancement,
  format,
  expert,
}

/// Níveis de severidade
enum ValidationSeverity {
  none,
  low,
  medium,
  high,
  critical,
}
