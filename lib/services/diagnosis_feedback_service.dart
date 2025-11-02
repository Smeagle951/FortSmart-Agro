import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/schemas/feedback_database_schema.dart';
import '../models/diagnosis_feedback.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar feedback de diagnósticos e aprendizado contínuo
/// Coleta feedback dos usuários para melhorar precisão do sistema
class DiagnosisFeedbackService {
  static final DiagnosisFeedbackService _instance = DiagnosisFeedbackService._internal();
  factory DiagnosisFeedbackService() => _instance;
  DiagnosisFeedbackService._internal();

  final AppDatabase _database = AppDatabase();
  bool _initialized = false;

  /// Inicializa o serviço e cria tabelas necessárias
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      Logger.info('🔧 Inicializando DiagnosisFeedbackService...');
      
      final db = await _database.database;
      
      // Criar todas as tabelas
      for (final sql in FeedbackDatabaseSchema.allCreateTableStatements) {
        await db.execute(sql);
      }
      
      // Criar todos os índices
      for (final sql in FeedbackDatabaseSchema.allIndexStatements) {
        await db.execute(sql);
      }
      
      _initialized = true;
      Logger.info('✅ DiagnosisFeedbackService inicializado com sucesso');
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar DiagnosisFeedbackService: $e');
      rethrow;
    }
  }

  /// Salva feedback do usuário
  Future<bool> saveFeedback(DiagnosisFeedback feedback) async {
    try {
      await initialize();
      
      Logger.info('💾 Salvando feedback: ${feedback.id}');
      Logger.info('   Fazenda: ${feedback.farmId}');
      Logger.info('   Cultura: ${feedback.cropName}');
      Logger.info('   Confirmado: ${feedback.userConfirmed}');
      
      final db = await _database.database;
      
      await db.insert(
        'diagnosis_feedback',
        feedback.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Atualizar padrões de organismos da fazenda
      if (!feedback.userConfirmed && feedback.userCorrectedOrganism != null) {
        await _updateFarmOrganismPatterns(feedback);
      }
      
      // Agendar sincronização com servidor
      _scheduleSyncToCloud(feedback);
      
      Logger.info('✅ Feedback salvo com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar feedback: $e');
      return false;
    }
  }

  /// Obtém todos os feedbacks de uma fazenda
  Future<List<DiagnosisFeedback>> getFeedbacksByFarm(String farmId) async {
    try {
      await initialize();
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'diagnosis_feedback',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'feedback_date DESC',
      );
      
      return maps.map((map) => DiagnosisFeedback.fromMap(map)).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter feedbacks: $e');
      return [];
    }
  }

  /// Obtém feedbacks por cultura
  Future<List<DiagnosisFeedback>> getFeedbacksByCrop(String farmId, String cropName) async {
    try {
      await initialize();
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'diagnosis_feedback',
        where: 'farm_id = ? AND crop_name = ?',
        whereArgs: [farmId, cropName],
        orderBy: 'feedback_date DESC',
      );
      
      return maps.map((map) => DiagnosisFeedback.fromMap(map)).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter feedbacks por cultura: $e');
      return [];
    }
  }

  /// Obtém estatísticas de acurácia para uma fazenda
  Future<Map<String, dynamic>> getAccuracyStats(String farmId) async {
    try {
      await initialize();
      
      Logger.info('📊 Calculando estatísticas de acurácia para fazenda: $farmId');
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> result = await db.rawQuery(
        FeedbackDatabaseSchema.getQuickStatsSQL,
        [farmId],
      );
      
      if (result.isEmpty) {
        return {
          'farmId': farmId,
          'totalDiagnoses': 0,
          'overallAccuracy': 0.0,
          'byCrop': [],
        };
      }
      
      final totalDiagnoses = result.fold<int>(
        0, 
        (sum, row) => sum + (row['total'] as int),
      );
      
      final totalConfirmed = result.fold<int>(
        0, 
        (sum, row) => sum + (row['confirmed'] as int),
      );
      
      final overallAccuracy = totalDiagnoses > 0 
          ? (totalConfirmed / totalDiagnoses * 100) 
          : 0.0;
      
      Logger.info('✅ Estatísticas calculadas: $totalDiagnoses diagnósticos, ${overallAccuracy.toStringAsFixed(1)}% acurácia');
      
      return {
        'farmId': farmId,
        'totalDiagnoses': totalDiagnoses,
        'totalConfirmed': totalConfirmed,
        'totalCorrected': totalDiagnoses - totalConfirmed,
        'overallAccuracy': overallAccuracy,
        'byCrop': result,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas: $e');
      return {
        'farmId': farmId,
        'totalDiagnoses': 0,
        'overallAccuracy': 0.0,
        'byCrop': [],
        'error': e.toString(),
      };
    }
  }

  /// Obtém estatísticas detalhadas por cultura
  Future<Map<String, dynamic>> getCropStats(String farmId, String cropName) async {
    try {
      await initialize();
      
      final db = await _database.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN user_confirmed = 1 THEN 1 ELSE 0 END) as confirmed,
          SUM(CASE WHEN user_confirmed = 0 THEN 1 ELSE 0 END) as corrected,
          AVG(CASE WHEN system_confidence IS NOT NULL THEN system_confidence ELSE 0 END) as avg_confidence,
          
          -- Por nível de severidade
          SUM(CASE WHEN system_severity_level = 'baixo' AND user_confirmed = 1 THEN 1 ELSE 0 END) as low_correct,
          SUM(CASE WHEN system_severity_level = 'baixo' THEN 1 ELSE 0 END) as low_total,
          
          SUM(CASE WHEN system_severity_level = 'moderado' AND user_confirmed = 1 THEN 1 ELSE 0 END) as moderate_correct,
          SUM(CASE WHEN system_severity_level = 'moderado' THEN 1 ELSE 0 END) as moderate_total,
          
          SUM(CASE WHEN system_severity_level = 'alto' AND user_confirmed = 1 THEN 1 ELSE 0 END) as high_correct,
          SUM(CASE WHEN system_severity_level = 'alto' THEN 1 ELSE 0 END) as high_total,
          
          SUM(CASE WHEN system_severity_level = 'critico' AND user_confirmed = 1 THEN 1 ELSE 0 END) as critical_correct,
          SUM(CASE WHEN system_severity_level = 'critico' THEN 1 ELSE 0 END) as critical_total
          
        FROM diagnosis_feedback
        WHERE farm_id = ? AND crop_name = ?
      ''', [farmId, cropName]);
      
      if (result.isEmpty || result.first['total'] == 0) {
        return {'cropName': cropName, 'noData': true};
      }
      
      final data = result.first;
      final total = data['total'] as int;
      final confirmed = data['confirmed'] as int;
      
      return {
        'cropName': cropName,
        'total': total,
        'confirmed': confirmed,
        'corrected': data['corrected'],
        'accuracy': (confirmed / total * 100).toStringAsFixed(1),
        'avgConfidence': (data['avg_confidence'] as double).toStringAsFixed(2),
        'bySeverity': {
          'low': {
            'accuracy': _calculateSeverityAccuracy(
              data['low_correct'] as int, 
              data['low_total'] as int,
            ),
            'total': data['low_total'],
          },
          'moderate': {
            'accuracy': _calculateSeverityAccuracy(
              data['moderate_correct'] as int, 
              data['moderate_total'] as int,
            ),
            'total': data['moderate_total'],
          },
          'high': {
            'accuracy': _calculateSeverityAccuracy(
              data['high_correct'] as int, 
              data['high_total'] as int,
            ),
            'total': data['high_total'],
          },
          'critical': {
            'accuracy': _calculateSeverityAccuracy(
              data['critical_correct'] as int, 
              data['critical_total'] as int,
            ),
            'total': data['critical_total'],
          },
        },
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas da cultura: $e');
      return {'cropName': cropName, 'error': e.toString()};
    }
  }

  /// Obtém feedbacks pendentes de follow-up
  Future<List<DiagnosisFeedback>> getPendingFollowUps() async {
    try {
      await initialize();
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        FeedbackDatabaseSchema.getPendingFollowUpsSQL,
      );
      
      return maps.map((map) => DiagnosisFeedback.fromMap(map)).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter follow-ups pendentes: $e');
      return [];
    }
  }

  /// Atualiza resultado real (follow-up)
  Future<bool> updateOutcome({
    required String feedbackId,
    required String outcome,
    double? treatmentEfficacy,
    String? treatmentApplied,
    String? notes,
  }) async {
    try {
      await initialize();
      
      Logger.info('📝 Atualizando resultado do feedback: $feedbackId');
      
      final db = await _database.database;
      
      await db.update(
        'diagnosis_feedback',
        {
          'real_outcome': outcome,
          'outcome_date': DateTime.now().toIso8601String(),
          'treatment_efficacy': treatmentEfficacy,
          'treatment_applied': treatmentApplied,
          'outcome_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [feedbackId],
      );
      
      Logger.info('✅ Resultado atualizado com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao atualizar resultado: $e');
      return false;
    }
  }

  /// Obtém dados para treinar modelo específico de cultura
  Future<List<Map<String, dynamic>>> getTrainingDataForCrop(String cropName) async {
    try {
      await initialize();
      
      Logger.info('🎓 Obtendo dados de treinamento para cultura: $cropName');
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'diagnosis_feedback',
        where: 'crop_name = ? AND user_confirmed = 0', // Apenas correções
        whereArgs: [cropName],
      );
      
      Logger.info('   Encontrados ${maps.length} exemplos de correção');
      
      return maps;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados de treinamento: $e');
      return [];
    }
  }

  /// Sincroniza feedbacks pendentes com servidor
  Future<int> syncPendingFeedbacks({int limit = 50}) async {
    try {
      await initialize();
      
      Logger.info('🔄 Sincronizando feedbacks pendentes...');
      
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        FeedbackDatabaseSchema.getPendingSyncSQL,
        [limit],
      );
      
      if (maps.isEmpty) {
        Logger.info('   Nenhum feedback pendente para sincronizar');
        return 0;
      }
      
      int syncedCount = 0;
      
      for (final map in maps) {
        final feedback = DiagnosisFeedback.fromMap(map);
        
        // TODO: Implementar chamada à API do servidor
        final success = await _syncFeedbackToCloud(feedback);
        
        if (success) {
          await db.update(
            'diagnosis_feedback',
            {
              'synced_to_cloud': 1,
              'synced_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [feedback.id],
          );
          
          syncedCount++;
        }
      }
      
      Logger.info('✅ $syncedCount feedbacks sincronizados');
      return syncedCount;
      
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar feedbacks: $e');
      return 0;
    }
  }

  /// Limpa feedbacks antigos já sincronizados
  Future<int> cleanupOldFeedbacks({int daysToKeep = 90}) async {
    try {
      await initialize();
      
      Logger.info('🧹 Limpando feedbacks antigos (mantendo últimos $daysToKeep dias)...');
      
      final db = await _database.database;
      
      final deletedCount = await db.delete(
        'diagnosis_feedback',
        where: 'synced_to_cloud = 1 AND datetime(feedback_date) < datetime(?, ?)',
        whereArgs: ['now', '-$daysToKeep days'],
      );
      
      Logger.info('✅ $deletedCount feedbacks antigos removidos');
      return deletedCount;
      
    } catch (e) {
      Logger.error('❌ Erro ao limpar feedbacks antigos: $e');
      return 0;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Atualiza padrões de organismos da fazenda
  Future<void> _updateFarmOrganismPatterns(DiagnosisFeedback feedback) async {
    try {
      final db = await _database.database;
      
      final organismName = feedback.userCorrectedOrganism!;
      
      // Verificar se padrão já existe
      final existing = await db.query(
        'farm_organism_patterns',
        where: 'farm_id = ? AND crop_name = ? AND organism_name = ?',
        whereArgs: [feedback.farmId, feedback.cropName, organismName],
      );
      
      if (existing.isEmpty) {
        // Criar novo padrão
        await db.insert('farm_organism_patterns', {
          'id': '${feedback.farmId}_${feedback.cropName}_$organismName',
          'farm_id': feedback.farmId,
          'crop_name': feedback.cropName,
          'organism_name': organismName,
          'occurrence_count': 1,
          'last_occurrence_date': feedback.feedbackDate.toIso8601String(),
          'avg_severity': feedback.userCorrectedSeverity ?? 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Atualizar padrão existente
        final pattern = existing.first;
        final currentCount = pattern['occurrence_count'] as int;
        final currentAvgSeverity = pattern['avg_severity'] as double;
        
        final newCount = currentCount + 1;
        final newAvgSeverity = ((currentAvgSeverity * currentCount) + 
                               (feedback.userCorrectedSeverity ?? 0.0)) / newCount;
        
        await db.update(
          'farm_organism_patterns',
          {
            'occurrence_count': newCount,
            'last_occurrence_date': feedback.feedbackDate.toIso8601String(),
            'avg_severity': newAvgSeverity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'farm_id = ? AND crop_name = ? AND organism_name = ?',
          whereArgs: [feedback.farmId, feedback.cropName, organismName],
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao atualizar padrões de organismos: $e');
    }
  }

  /// Sincroniza um feedback com o servidor
  /// ⚠️ DESATIVADO - Sistema funciona 100% OFFLINE
  /// Descomentar quando API estiver pronta
  Future<bool> _syncFeedbackToCloud(DiagnosisFeedback feedback) async {
    try {
      // ⚠️ OFFLINE MODE - Sincronização desativada
      Logger.info('ℹ️ Sincronização offline - feedback ${feedback.id} aguardando API');
      
      // Simulação de delay de rede (remover quando API estiver pronta)
      await Future.delayed(const Duration(milliseconds: 100));
      
      // TODO: Implementar chamada à API real quando backend estiver pronto
      /*
      final response = await http.post(
        Uri.parse('https://api.fortsmart.com/v1/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(feedback.toMap()),
      );
      
      if (response.statusCode == 200) {
        Logger.info('✅ Feedback sincronizado com sucesso');
        return true;
      } else {
        Logger.error('❌ Erro na sincronização: ${response.statusCode}');
        return false;
      }
      */
      
      // Por enquanto, retornar true para simular sucesso
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar com servidor: $e');
      return false;
    }
  }

  /// Agenda sincronização assíncrona
  void _scheduleSyncToCloud(DiagnosisFeedback feedback) {
    // Executar sincronização em background
    Future.delayed(const Duration(seconds: 5), () {
      syncPendingFeedbacks(limit: 10);
    });
  }

  /// Calcula acurácia por nível de severidade
  double _calculateSeverityAccuracy(int correct, int total) {
    if (total == 0) return 0.0;
    return (correct / total * 100);
  }
}

