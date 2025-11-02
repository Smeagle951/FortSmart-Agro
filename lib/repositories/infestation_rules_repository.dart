import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/infestation_rule.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Repositório para gerenciar regras de infestação personalizadas
class InfestationRulesRepository {
  final AppDatabase _database = AppDatabase();
  bool _isInitialized = false;

  /// Inicializa o repositório e cria tabela se necessário
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final db = await _database.database;
      
      // Criar tabela de regras de infestação
      await db.execute('''
        CREATE TABLE IF NOT EXISTS infestation_rules (
          id TEXT PRIMARY KEY,
          organism_id TEXT NOT NULL,
          organism_name TEXT NOT NULL,
          type TEXT NOT NULL,
          low_threshold REAL NOT NULL DEFAULT 0.5,
          medium_threshold REAL NOT NULL DEFAULT 1.5,
          high_threshold REAL NOT NULL DEFAULT 3.0,
          critical_threshold REAL NOT NULL DEFAULT 5.0,
          unit TEXT NOT NULL DEFAULT 'organismos/ponto',
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // ✅ ADICIONAR COLUNA 'unit' se tabela já existir (migração)
      try {
        await db.execute('ALTER TABLE infestation_rules ADD COLUMN unit TEXT DEFAULT "organismos/ponto"');
        Logger.info('✅ Coluna "unit" adicionada à tabela infestation_rules');
      } catch (e) {
        // Coluna já existe, continuar
      }

      // Criar índices
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_rules_organism 
        ON infestation_rules(organism_id)
      ''');

      _isInitialized = true;
      Logger.info('✅ InfestationRulesRepository inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar InfestationRulesRepository: $e');
      rethrow;
    }
  }

  /// Obtém regra para um organismo específico
  Future<InfestationRule?> getRuleForOrganism(String organismId, String? cropId) async {
    try {
      await initialize();
      
      final db = await _database.database;
      final results = await db.query(
        'infestation_rules',
        where: 'organism_id = ?',
        whereArgs: [organismId],
        limit: 1,
      );

      if (results.isEmpty) {
        return null; // Retorna null se não há regra personalizada
      }

      return InfestationRule.fromMap(results.first);
    } catch (e) {
      Logger.error('❌ Erro ao buscar regra para organismo $organismId: $e');
      return null;
    }
  }

  /// Obtém todas as regras
  Future<List<InfestationRule>> getAllRules() async {
    try {
      await initialize();
      
      final db = await _database.database;
      final results = await db.query(
        'infestation_rules',
        orderBy: 'organism_name ASC',
      );

      return results.map((map) => InfestationRule.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar todas as regras: $e');
      return [];
    }
  }

  /// Salva ou atualiza uma regra
  Future<void> saveRule(InfestationRule rule) async {
    try {
      await initialize();
      
      final db = await _database.database;
      await db.insert(
        'infestation_rules',
        rule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ Regra salva: ${rule.organismName}');
    } catch (e) {
      Logger.error('❌ Erro ao salvar regra: $e');
      rethrow;
    }
  }

  /// Exclui uma regra
  Future<void> deleteRule(String ruleId) async {
    try {
      await initialize();
      
      final db = await _database.database;
      await db.delete(
        'infestation_rules',
        where: 'id = ?',
        whereArgs: [ruleId],
      );

      Logger.info('✅ Regra excluída: $ruleId');
    } catch (e) {
      Logger.error('❌ Erro ao excluir regra: $e');
      rethrow;
    }
  }

  /// Cria regra padrão se não existir
  Future<InfestationRule> getOrCreateDefaultRule(
    String organismId,
    String organismName,
    OccurrenceType type,
  ) async {
    // Tentar buscar regra existente
    final existingRule = await getRuleForOrganism(organismId, null);
    if (existingRule != null) {
      return existingRule;
    }

    // Criar regra padrão
    final defaultRule = InfestationRule.defaultForOrganism(
      organismId,
      organismName,
      type,
    );

    // Salvar regra padrão
    await saveRule(defaultRule);

    return defaultRule;
  }

  /// Obtém regras por tipo de ocorrência
  Future<List<InfestationRule>> getRulesByType(OccurrenceType type) async {
    try {
      await initialize();
      
      final db = await _database.database;
      final results = await db.query(
        'infestation_rules',
        where: 'type = ?',
        whereArgs: [type.toString().split('.').last],
        orderBy: 'organism_name ASC',
      );

      return results.map((map) => InfestationRule.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar regras por tipo: $e');
      return [];
    }
  }

  /// Atualiza thresholds de uma regra
  Future<void> updateThresholds(
    String ruleId, {
    double? lowThreshold,
    double? mediumThreshold,
    double? highThreshold,
    double? criticalThreshold,
  }) async {
    try {
      await initialize();
      
      final db = await _database.database;
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (lowThreshold != null) updates['low_threshold'] = lowThreshold;
      if (mediumThreshold != null) updates['medium_threshold'] = mediumThreshold;
      if (highThreshold != null) updates['high_threshold'] = highThreshold;
      if (criticalThreshold != null) updates['critical_threshold'] = criticalThreshold;

      await db.update(
        'infestation_rules',
        updates,
        where: 'id = ?',
        whereArgs: [ruleId],
      );

      Logger.info('✅ Thresholds atualizados: $ruleId');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar thresholds: $e');
      rethrow;
    }
  }

  /// Reseta regra para valores padrão
  Future<void> resetToDefault(String ruleId) async {
    try {
      await initialize();
      
      final db = await _database.database;
      await db.update(
        'infestation_rules',
        {
          'low_threshold': 0.5,
          'medium_threshold': 1.5,
          'high_threshold': 3.0,
          'critical_threshold': 5.0,
          'unit': 'organismos/ponto', // ✅ NOVO
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [ruleId],
      );

      Logger.info('✅ Regra resetada para padrão: $ruleId');
    } catch (e) {
      Logger.error('❌ Erro ao resetar regra: $e');
      rethrow;
    }
  }

  /// Limpa todas as regras personalizadas
  Future<void> clearAllRules() async {
    try {
      await initialize();
      
      final db = await _database.database;
      await db.delete('infestation_rules');

      Logger.info('✅ Todas as regras foram limpas');
    } catch (e) {
      Logger.error('❌ Erro ao limpar regras: $e');
      rethrow;
    }
  }
}

