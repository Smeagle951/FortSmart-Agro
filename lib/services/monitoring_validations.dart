import '../database/app_database.dart';
import '../utils/logger.dart';
import 'organism_catalog_service.dart';

/// Serviço de Validações e Regras de Negócio para Monitoramento Avançado
/// Implementa todas as validações necessárias conforme especificado no guia
class MonitoringValidations {
  static const String _tag = 'MonitoringValidations';
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogService _catalogService = OrganismCatalogService();

  /// Resultado de uma validação
  class ValidationResult {
    final bool isValid;
    final List<ValidationError> errors;
    final List<ValidationWarning> warnings;

    ValidationResult({
      required this.isValid,
      required this.errors,
      required this.warnings,
    });

    bool get hasErrors => errors.isNotEmpty;
    bool get hasWarnings => warnings.isNotEmpty;
  }

  /// Erro de validação
  class ValidationError {
    final String field;
    final String message;
    final String code;

    ValidationError({
      required this.field,
      required this.message,
      required this.code,
    });

    @override
    String toString() => '$field: $message';
  }

  /// Aviso de validação
  class ValidationWarning {
    final String field;
    final String message;
    final String code;

    ValidationWarning({
      required this.field,
      required this.message,
      required this.code,
    });

    @override
    String toString() => '$field: $message';
  }

  /// Valida uma sessão de monitoramento
  Future<ValidationResult> validateSession(Map<String, dynamic> sessionData) async {
    Logger.info('$_tag: Validando sessão de monitoramento...');
    
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // 1. Validações obrigatórias
    if (sessionData['fazenda_id'] == null || sessionData['fazenda_id'].toString().isEmpty) {
      errors.add(ValidationError(
        field: 'fazenda_id',
        message: 'ID da fazenda é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    if (sessionData['talhao_id'] == null || sessionData['talhao_id'].toString().isEmpty) {
      errors.add(ValidationError(
        field: 'talhao_id',
        message: 'ID do talhão é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    if (sessionData['cultura_id'] == null || sessionData['cultura_id'].toString().isEmpty) {
      errors.add(ValidationError(
        field: 'cultura_id',
        message: 'ID da cultura é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    // 2. Validação de amostragem padrão
    final amostragem = sessionData['amostragem_padrao_plantas_por_ponto'] ?? 10;
    if (amostragem < 1 || amostragem > 50) {
      errors.add(ValidationError(
        field: 'amostragem_padrao_plantas_por_ponto',
        message: 'Amostragem deve estar entre 1 e 50 plantas',
        code: 'INVALID_RANGE',
      ));
    }

    // 3. Validação de status
    final status = sessionData['status'] ?? 'draft';
    if (!['draft', 'finalized', 'cancelled'].contains(status)) {
      errors.add(ValidationError(
        field: 'status',
        message: 'Status inválido. Deve ser draft, finalized ou cancelled',
        code: 'INVALID_STATUS',
      ));
    }

    // 4. Validação de datas
    if (sessionData['started_at'] != null) {
      try {
        DateTime.parse(sessionData['started_at']);
      } catch (e) {
        errors.add(ValidationError(
          field: 'started_at',
          message: 'Data de início inválida',
          code: 'INVALID_DATE',
        ));
      }
    }

    if (sessionData['finished_at'] != null) {
      try {
        final finishedAt = DateTime.parse(sessionData['finished_at']);
        final startedAt = sessionData['started_at'] != null 
            ? DateTime.parse(sessionData['started_at'])
            : DateTime.now();
        
        if (finishedAt.isBefore(startedAt)) {
          errors.add(ValidationError(
            field: 'finished_at',
            message: 'Data de finalização não pode ser anterior à data de início',
            code: 'INVALID_DATE_RANGE',
          ));
        }
      } catch (e) {
        errors.add(ValidationError(
          field: 'finished_at',
          message: 'Data de finalização inválida',
          code: 'INVALID_DATE',
        ));
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Valida um ponto de monitoramento
  Future<ValidationResult> validatePoint(Map<String, dynamic> pointData) async {
    Logger.info('$_tag: Validando ponto de monitoramento...');
    
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // 1. Validações obrigatórias
    if (pointData['session_id'] == null || pointData['session_id'].toString().isEmpty) {
      errors.add(ValidationError(
        field: 'session_id',
        message: 'ID da sessão é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    if (pointData['numero'] == null) {
      errors.add(ValidationError(
        field: 'numero',
        message: 'Número do ponto é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    // 2. Validação de coordenadas GPS
    final latitude = pointData['latitude'];
    final longitude = pointData['longitude'];
    final manualEntry = pointData['manual_entry'] ?? false;

    if (!manualEntry) {
      if (latitude == null || longitude == null) {
        errors.add(ValidationError(
          field: 'coordinates',
          message: 'Coordenadas GPS são obrigatórias para pontos não manuais',
          code: 'REQUIRED_GPS',
        ));
      } else {
        // Validar latitude (-90 a 90)
        if (latitude < -90 || latitude > 90) {
          errors.add(ValidationError(
            field: 'latitude',
            message: 'Latitude deve estar entre -90 e 90',
            code: 'INVALID_LATITUDE',
          ));
        }

        // Validar longitude (-180 a 180)
        if (longitude < -180 || longitude > 180) {
          errors.add(ValidationError(
            field: 'longitude',
            message: 'Longitude deve estar entre -180 e 180',
            code: 'INVALID_LONGITUDE',
          ));
        }
      }
    }

    // 3. Validação de precisão GPS
    final gpsAccuracy = pointData['gps_accuracy'];
    if (gpsAccuracy != null && !manualEntry) {
      if (gpsAccuracy > 10) {
        warnings.add(ValidationWarning(
          field: 'gps_accuracy',
          message: 'Precisão GPS baixa (${gpsAccuracy}m). Recomendado ≤ 5m',
          code: 'LOW_GPS_ACCURACY',
        ));
      }
      
      if (gpsAccuracy > 20) {
        errors.add(ValidationError(
          field: 'gps_accuracy',
          message: 'Precisão GPS muito baixa (${gpsAccuracy}m). Máximo permitido: 20m',
          code: 'TOO_LOW_GPS_ACCURACY',
        ));
      }
    }

    // 4. Validação de plantas avaliadas
    final plantasAvaliadas = pointData['plantas_avaliadas'];
    if (plantasAvaliadas != null) {
      if (plantasAvaliadas < 1) {
        errors.add(ValidationError(
          field: 'plantas_avaliadas',
          message: 'Número de plantas avaliadas deve ser maior que zero',
          code: 'INVALID_PLANT_COUNT',
        ));
      }
      
      if (plantasAvaliadas > 100) {
        warnings.add(ValidationWarning(
          field: 'plantas_avaliadas',
          message: 'Número alto de plantas avaliadas ($plantasAvaliadas). Verificar se está correto',
          code: 'HIGH_PLANT_COUNT',
        ));
      }
    }

    // 5. Validação de timestamp
    if (pointData['timestamp'] != null) {
      try {
        final timestamp = DateTime.parse(pointData['timestamp']);
        final now = DateTime.now();
        
        if (timestamp.isAfter(now)) {
          errors.add(ValidationError(
            field: 'timestamp',
            message: 'Timestamp não pode ser no futuro',
            code: 'FUTURE_TIMESTAMP',
          ));
        }
        
        if (timestamp.isBefore(now.subtract(const Duration(days: 7)))) {
          warnings.add(ValidationWarning(
            field: 'timestamp',
            message: 'Timestamp muito antigo. Verificar se está correto',
            code: 'OLD_TIMESTAMP',
          ));
        }
      } catch (e) {
        errors.add(ValidationError(
          field: 'timestamp',
          message: 'Timestamp inválido',
          code: 'INVALID_TIMESTAMP',
        ));
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Valida uma ocorrência de monitoramento
  Future<ValidationResult> validateOccurrence(Map<String, dynamic> occurrenceData) async {
    Logger.info('$_tag: Validando ocorrência de monitoramento...');
    
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // 1. Validações obrigatórias
    if (occurrenceData['point_id'] == null || occurrenceData['point_id'].toString().isEmpty) {
      errors.add(ValidationError(
        field: 'point_id',
        message: 'ID do ponto é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    if (occurrenceData['organism_id'] == null) {
      errors.add(ValidationError(
        field: 'organism_id',
        message: 'ID do organismo é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    if (occurrenceData['valor_bruto'] == null) {
      errors.add(ValidationError(
        field: 'valor_bruto',
        message: 'Valor bruto é obrigatório',
        code: 'REQUIRED_FIELD',
      ));
    }

    // 2. Validação do organismo
    final organismId = occurrenceData['organism_id'];
    if (organismId != null) {
      final organism = await _catalogService.getOrganismById(organismId);
      if (organism == null) {
        errors.add(ValidationError(
          field: 'organism_id',
          message: 'Organismo não encontrado no catálogo',
          code: 'INVALID_ORGANISM',
        ));
      } else if (!organism.ativo) {
        errors.add(ValidationError(
          field: 'organism_id',
          message: 'Organismo inativo no catálogo',
          code: 'INACTIVE_ORGANISM',
        ));
      }
    }

    // 3. Validação do valor bruto
    final valorBruto = occurrenceData['valor_bruto'];
    if (valorBruto != null) {
      if (valorBruto < 0) {
        errors.add(ValidationError(
          field: 'valor_bruto',
          message: 'Valor bruto não pode ser negativo',
          code: 'NEGATIVE_VALUE',
        ));
      }

      // Validações específicas por tipo de unidade
      if (organismId != null) {
        final organism = await _catalogService.getOrganismById(organismId);
        if (organism != null) {
          final unidade = organism.unidade;
          
          switch (unidade) {
            case 'percent_folha':
            case 'percent_plantas':
              if (valorBruto > 100) {
                errors.add(ValidationError(
                  field: 'valor_bruto',
                  message: 'Percentual não pode ser maior que 100%',
                  code: 'INVALID_PERCENTAGE',
                ));
              }
              break;
              
            case 'individuos/10_plantas':
            case 'individuos/planta':
              if (valorBruto > 1000) {
                warnings.add(ValidationWarning(
                  field: 'valor_bruto',
                  message: 'Valor muito alto ($valorBruto). Verificar se está correto',
                  code: 'HIGH_VALUE',
                ));
              }
              break;
              
            case 'plantas/m2':
              if (valorBruto > 100) {
                warnings.add(ValidationWarning(
                  field: 'valor_bruto',
                  message: 'Densidade muito alta ($valorBruto plantas/m²). Verificar se está correto',
                  code: 'HIGH_DENSITY',
                ));
              }
              break;
          }
        }
      }
    }

    // 4. Validação de observações
    final observacao = occurrenceData['observacao'];
    if (observacao != null && observacao.toString().length > 500) {
      warnings.add(ValidationWarning(
        field: 'observacao',
        message: 'Observação muito longa. Máximo recomendado: 500 caracteres',
        code: 'LONG_OBSERVATION',
      ));
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Valida uma sessão completa (sessão + pontos + ocorrências)
  Future<ValidationResult> validateCompleteSession(String sessionId) async {
    Logger.info('$_tag: Validando sessão completa: $sessionId');
    
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final db = await _database.database;

    try {
      // 1. Validar sessão
      final sessionData = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (sessionData.isEmpty) {
        errors.add(ValidationError(
          field: 'session',
          message: 'Sessão não encontrada',
          code: 'SESSION_NOT_FOUND',
        ));
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final sessionValidation = await validateSession(sessionData.first);
      errors.addAll(sessionValidation.errors);
      warnings.addAll(sessionValidation.warnings);

      // 2. Validar pontos
      final pointsData = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'numero ASC',
      );

      if (pointsData.isEmpty) {
        errors.add(ValidationError(
          field: 'points',
          message: 'Sessão deve ter pelo menos um ponto',
          code: 'NO_POINTS',
        ));
      } else {
        // Validar sequência de números
        final numeros = pointsData.map((p) => p['numero'] as int).toList();
        numeros.sort();
        
        for (int i = 0; i < numeros.length; i++) {
          if (numeros[i] != i + 1) {
            warnings.add(ValidationWarning(
              field: 'points',
              message: 'Sequência de pontos não contínua. Esperado: ${i + 1}, Encontrado: ${numeros[i]}',
              code: 'NON_SEQUENTIAL_POINTS',
            ));
          }
        }

        // Validar cada ponto
        for (final point in pointsData) {
          final pointValidation = await validatePoint(point);
          errors.addAll(pointValidation.errors);
          warnings.addAll(pointValidation.warnings);
        }
      }

      // 3. Validar ocorrências
      final occurrencesData = await db.rawQuery('''
        SELECT o.* FROM monitoring_occurrences o
        INNER JOIN monitoring_points p ON o.point_id = p.id
        WHERE p.session_id = ?
      ''', [sessionId]);

      if (occurrencesData.isEmpty) {
        warnings.add(ValidationWarning(
          field: 'occurrences',
          message: 'Nenhuma ocorrência registrada na sessão',
          code: 'NO_OCCURRENCES',
        ));
      } else {
        // Validar cada ocorrência
        for (final occurrence in occurrencesData) {
          final occurrenceValidation = await validateOccurrence(occurrence);
          errors.addAll(occurrenceValidation.errors);
          warnings.addAll(occurrenceValidation.warnings);
        }
      }

      // 4. Validações de consistência
      final session = sessionData.first;
      final amostragemPadrao = session['amostragem_padrao_plantas_por_ponto'] ?? 10;
      
      // Verificar se todos os pontos têm o número correto de plantas avaliadas
      for (final point in pointsData) {
        final plantasAvaliadas = point['plantas_avaliadas'];
        if (plantasAvaliadas != null && plantasAvaliadas != amostragemPadrao) {
          warnings.add(ValidationWarning(
            field: 'plantas_avaliadas',
            message: 'Ponto ${point['numero']}: plantas avaliadas ($plantasAvaliadas) diferente do padrão ($amostragemPadrao)',
            code: 'INCONSISTENT_PLANT_COUNT',
          ));
        }
      }

    } catch (e) {
      errors.add(ValidationError(
        field: 'validation',
        message: 'Erro durante validação: $e',
        code: 'VALIDATION_ERROR',
      ));
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Valida se uma sessão pode ser finalizada
  Future<ValidationResult> validateSessionFinalization(String sessionId) async {
    Logger.info('$_tag: Validando finalização da sessão: $sessionId');
    
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final db = await _database.database;

    try {
      // 1. Verificar se a sessão existe e está em draft
      final sessionData = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (sessionData.isEmpty) {
        errors.add(ValidationError(
          field: 'session',
          message: 'Sessão não encontrada',
          code: 'SESSION_NOT_FOUND',
        ));
        return ValidationResult(isValid: false, errors: errors, warnings: warnings);
      }

      final session = sessionData.first;
      if (session['status'] != 'draft') {
        errors.add(ValidationError(
          field: 'status',
          message: 'Sessão já foi finalizada ou cancelada',
          code: 'ALREADY_FINALIZED',
        ));
      }

      // 2. Verificar se há pontos
      final pointsCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM monitoring_points 
        WHERE session_id = ?
      ''', [sessionId]);
      
      if (pointsCount.first['count'] == 0) {
        errors.add(ValidationError(
          field: 'points',
          message: 'Sessão deve ter pelo menos um ponto para ser finalizada',
          code: 'NO_POINTS',
        ));
      }

      // 3. Verificar se há ocorrências
      final occurrencesCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM monitoring_occurrences o
        INNER JOIN monitoring_points p ON o.point_id = p.id
        WHERE p.session_id = ?
      ''', [sessionId]);
      
      if (occurrencesCount.first['count'] == 0) {
        warnings.add(ValidationWarning(
          field: 'occurrences',
          message: 'Nenhuma ocorrência registrada. A sessão será finalizada sem dados de infestação',
          code: 'NO_OCCURRENCES',
        ));
      }

      // 4. Verificar se todos os pontos têm GPS válido
      final invalidGpsPoints = await db.rawQuery('''
        SELECT numero FROM monitoring_points 
        WHERE session_id = ? AND (latitude IS NULL OR longitude IS NULL) AND manual_entry = 0
      ''', [sessionId]);
      
      if (invalidGpsPoints.isNotEmpty) {
        final pontos = invalidGpsPoints.map((p) => p['numero']).join(', ');
        warnings.add(ValidationWarning(
          field: 'gps',
          message: 'Pontos sem GPS válido: $pontos',
          code: 'INVALID_GPS_POINTS',
        ));
      }

    } catch (e) {
      errors.add(ValidationError(
        field: 'validation',
        message: 'Erro durante validação: $e',
        code: 'VALIDATION_ERROR',
      ));
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Obtém estatísticas de validação
  Future<Map<String, dynamic>> getValidationStats() async {
    final db = await _database.database;
    
    final stats = <String, dynamic>{};
    
    // Total de sessões
    final totalSessions = await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_sessions');
    stats['total_sessions'] = totalSessions.first['count'];
    
    // Sessões com problemas de GPS
    final gpsIssues = await db.rawQuery('''
      SELECT COUNT(*) as count FROM monitoring_points 
      WHERE gps_accuracy > 10 OR (latitude IS NULL AND manual_entry = 0)
    ''');
    stats['gps_issues'] = gpsIssues.first['count'];
    
    // Pontos sem ocorrências
    final pointsWithoutOccurrences = await db.rawQuery('''
      SELECT COUNT(*) as count FROM monitoring_points p
      LEFT JOIN monitoring_occurrences o ON p.id = o.point_id
      WHERE o.id IS NULL
    ''');
    stats['points_without_occurrences'] = pointsWithoutOccurrences.first['count'];
    
    // Ocorrências com valores suspeitos
    final suspiciousValues = await db.rawQuery('''
      SELECT COUNT(*) as count FROM monitoring_occurrences 
      WHERE valor_bruto > 1000 OR valor_bruto < 0
    ''');
    stats['suspicious_values'] = suspiciousValues.first['count'];
    
    return stats;
  }
}
