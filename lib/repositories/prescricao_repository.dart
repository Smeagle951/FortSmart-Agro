import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../models/prescricao_model.dart';
import '../utils/logger.dart';

/// Repositório para gerenciar prescrições agronômicas
class PrescricaoRepository {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'prescricoes';

  /// Inicializa as tabelas de prescrição
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabelas de prescrição...');
      
      final db = await _appDatabase.database;
      
      // Tabela principal de prescrições
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          talhao_nome TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          cultura_nome TEXT NOT NULL,
          data TEXT NOT NULL,
          responsavel_id TEXT NOT NULL,
          responsavel_nome TEXT NOT NULL,
          tipo_aplicacao TEXT NOT NULL,
          volume_l_ha REAL NOT NULL,
          capacidade_tanque_l REAL NOT NULL,
          volume_seguranca_l REAL NOT NULL,
          area_trabalho_ha REAL NOT NULL,
          observacoes TEXT,
          status TEXT NOT NULL DEFAULT 'Rascunho',
          temperatura REAL,
          umidade REAL,
          velocidade_vento REAL,
          horario_aplicacao TEXT,
          calibracao TEXT,
          produtos TEXT,
          resultados TEXT,
          totais TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          device_id TEXT
        )
      ''');
      
      // Índices para performance
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prescricoes_talhao ON $tableName (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prescricoes_data ON $tableName (data)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prescricoes_status ON $tableName (status)');
      
      Logger.info('✅ Tabelas de prescrição inicializadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabelas de prescrição: $e');
      rethrow;
    }
  }

  /// Salva uma prescrição no banco de dados
  Future<bool> salvarPrescricao(PrescricaoModel prescricao) async {
    try {
      print('🗄️ Inicializando banco de dados...');
      await initialize();
      final db = await _appDatabase.database;
      print('✅ Banco de dados inicializado');
      
      print('📝 Convertendo prescrição para mapa...');
      final map = prescricao.toMap();
      map['device_id'] = 'local'; // Identificador do dispositivo
      print('✅ Prescrição convertida para mapa');
      
      print('💾 Inserindo prescrição no banco...');
      final result = await db.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('💾 Resultado da inserção: $result');
      
      Logger.info('✅ Prescrição salva com sucesso: ${prescricao.id}');
      print('✅ Prescrição salva com sucesso: ${prescricao.id}');
      return result > 0;
    } catch (e) {
      print('❌ Erro ao salvar prescrição: $e');
      Logger.error('❌ Erro ao salvar prescrição: $e');
      return false;
    }
  }

  /// Atualiza uma prescrição existente
  Future<bool> atualizarPrescricao(PrescricaoModel prescricao) async {
    try {
      final db = await _appDatabase.database;
      
      final map = prescricao.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      map['device_id'] = 'local';
      
      final result = await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [prescricao.id],
      );
      
      Logger.info('✅ Prescrição atualizada com sucesso: ${prescricao.id}');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar prescrição: $e');
      return false;
    }
  }

  /// Busca uma prescrição pelo ID
  Future<PrescricaoModel?> buscarPorId(String id) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return PrescricaoModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar prescrição por ID: $e');
      return null;
    }
  }

  /// Lista todas as prescrições
  Future<List<PrescricaoModel>> listarTodas() async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'data DESC, created_at DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições: $e');
      return [];
    }
  }

  /// Lista prescrições por talhão
  Future<List<PrescricaoModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições por talhão: $e');
      return [];
    }
  }

  /// Lista prescrições por status
  Future<List<PrescricaoModel>> listarPorStatus(String status) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'data DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições por status: $e');
      return [];
    }
  }

  /// Lista prescrições por período
  Future<List<PrescricaoModel>> listarPorPeriodo(DateTime inicio, DateTime fim) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'data BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
        orderBy: 'data DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições por período: $e');
      return [];
    }
  }

  /// Exclui uma prescrição
  Future<bool> excluirPrescricao(String id) async {
    try {
      final db = await _appDatabase.database;
      
      final result = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Prescrição excluída com sucesso: $id');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao excluir prescrição: $e');
      return false;
    }
  }

  /// Busca prescrições por cultura
  Future<List<PrescricaoModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições por cultura: $e');
      return [];
    }
  }

  /// Busca prescrições por responsável
  Future<List<PrescricaoModel>> listarPorResponsavel(String responsavelId) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'responsavel_id = ?',
        whereArgs: [responsavelId],
        orderBy: 'data DESC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições por responsável: $e');
      return [];
    }
  }

  /// Busca prescrições recentes (últimos 30 dias)
  Future<List<PrescricaoModel>> listarRecentes() async {
    try {
      final db = await _appDatabase.database;
      final dataLimite = DateTime.now().subtract(const Duration(days: 30));
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'data >= ?',
        whereArgs: [dataLimite.toIso8601String()],
        orderBy: 'data DESC',
        limit: 50,
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições recentes: $e');
      return [];
    }
  }

  /// Conta o número total de prescrições
  Future<int> contarTotal() async {
    try {
      final db = await _appDatabase.database;
      
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      Logger.error('❌ Erro ao contar prescrições: $e');
      return 0;
    }
  }

  /// Conta prescrições por status
  Future<Map<String, int>> contarPorStatus() async {
    try {
      final db = await _appDatabase.database;
      
      final result = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM $tableName 
        GROUP BY status
      ''');
      
      final Map<String, int> contadores = {};
      for (final row in result) {
        contadores[row['status'] as String] = row['count'] as int;
      }
      
      return contadores;
    } catch (e) {
      Logger.error('❌ Erro ao contar prescrições por status: $e');
      return {};
    }
  }

  /// Busca estatísticas de prescrições
  Future<Map<String, dynamic>> buscarEstatisticas() async {
    try {
      final db = await _appDatabase.database;
      
      // Total de prescrições
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final total = totalResult.first['count'] as int? ?? 0;
      
      // Prescrições por status
      final statusResult = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM $tableName 
        GROUP BY status
      ''');
      
      // Prescrições por mês (últimos 12 meses)
      final mesResult = await db.rawQuery('''
        SELECT strftime('%Y-%m', data) as mes, COUNT(*) as count 
        FROM $tableName 
        WHERE data >= date('now', '-12 months')
        GROUP BY mes 
        ORDER BY mes DESC
      ''');
      
      // Área total tratada
      final areaResult = await db.rawQuery('''
        SELECT SUM(area_trabalho_ha) as area_total 
        FROM $tableName 
        WHERE status = 'Finalizada'
      ''');
      
      final areaTotal = areaResult.first['area_total'] as double? ?? 0.0;
      
      return {
        'total': total,
        'por_status': statusResult,
        'por_mes': mesResult,
        'area_total': areaTotal,
      };
    } catch (e) {
      Logger.error('❌ Erro ao buscar estatísticas: $e');
      return {};
    }
  }

  /// Marca uma prescrição como finalizada
  Future<bool> finalizarPrescricao(String id) async {
    try {
      final db = await _appDatabase.database;
      
      final result = await db.update(
        tableName,
        {
          'status': 'Finalizada',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Prescrição finalizada: $id');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao finalizar prescrição: $e');
      return false;
    }
  }

  /// Marca uma prescrição como executada
  Future<bool> executarPrescricao(String id) async {
    try {
      final db = await _appDatabase.database;
      
      final result = await db.update(
        tableName,
        {
          'status': 'Executada',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Prescrição executada: $id');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao executar prescrição: $e');
      return false;
    }
  }

  /// Busca prescrições pendentes (Rascunho ou Calculada)
  Future<List<PrescricaoModel>> listarPendentes() async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'status IN (?, ?)',
        whereArgs: ['Rascunho', 'Calculada'],
        orderBy: 'data ASC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições pendentes: $e');
      return [];
    }
  }

  /// Busca prescrições para execução (Finalizada)
  Future<List<PrescricaoModel>> listarParaExecucao() async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'status = ?',
        whereArgs: ['Finalizada'],
        orderBy: 'data ASC',
      );
      
      return maps.map((map) => PrescricaoModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar prescrições para execução: $e');
      return [];
    }
  }

  /// Sincroniza prescrições com o servidor (placeholder)
  Future<bool> sincronizar() async {
    try {
      Logger.info('🔄 Sincronizando prescrições...');
      
      // TODO: Implementar sincronização com servidor
      // Por enquanto, apenas simula a sincronização
      
      await Future.delayed(const Duration(seconds: 1));
      
      Logger.info('✅ Prescrições sincronizadas com sucesso');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar prescrições: $e');
      return false;
    }
  }
}
