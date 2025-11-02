import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/soil_compaction_point_model.dart';
import '../../../services/database_service.dart';

/// Repositório para gerenciar pontos de compactação do solo
class SoilCompactionPointRepository extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  /// Inicializa a tabela de pontos de compactação
  Future<void> initTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS compactacao_pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        point_code TEXT NOT NULL,
        talhao_id INTEGER NOT NULL,
        safra_id INTEGER,
        data_coleta TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        is_auto_generated INTEGER DEFAULT 0,
        profundidade_inicio REAL NOT NULL,
        profundidade_fim REAL NOT NULL,
        penetrometria REAL,
        umidade REAL,
        textura TEXT,
        estrutura TEXT,
        nivel_compactacao TEXT,
        diagnosticos TEXT,
        observacoes TEXT,
        fotos_path TEXT,
        amostra_coletada INTEGER DEFAULT 0,
        codigo_amostra TEXT,
        resultado_laboratorio TEXT,
        data_resultado TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Criar índices para melhorar performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ponto_talhao ON compactacao_pontos(talhao_id)'
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ponto_safra ON compactacao_pontos(safra_id)'
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ponto_code ON compactacao_pontos(point_code)'
    );
  }

  /// Insere um novo ponto de compactação
  Future<int> insert(SoilCompactionPointModel ponto) async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final id = await db.insert(
        'compactacao_pontos',
        ponto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      notifyListeners();
      if (kDebugMode) {
        print('✅ Ponto ${ponto.pointCode} inserido com ID: $id');
      }
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inserir ponto de compactação: $e');
      }
      return -1;
    }
  }

  /// Insere múltiplos pontos de uma vez (bulk insert)
  Future<List<int>> insertMany(List<SoilCompactionPointModel> pontos) async {
    try {
      await initTable();
      final db = await _databaseService.database;
      List<int> ids = [];
      
      await db.transaction((txn) async {
        for (var ponto in pontos) {
          final id = await txn.insert(
            'compactacao_pontos',
            ponto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          ids.add(id);
        }
      });
      
      notifyListeners();
      if (kDebugMode) {
        print('✅ ${ids.length} pontos inseridos com sucesso');
      }
      return ids;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inserir múltiplos pontos: $e');
      }
      return [];
    }
  }

  /// Atualiza um ponto existente
  Future<int> update(SoilCompactionPointModel ponto) async {
    try {
      final db = await _databaseService.database;
      final result = await db.update(
        'compactacao_pontos',
        {...ponto.toMap(), 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [ponto.id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar ponto: $e');
      }
      return -1;
    }
  }

  /// Exclui um ponto
  Future<int> delete(int id) async {
    try {
      final db = await _databaseService.database;
      final result = await db.delete(
        'compactacao_pontos',
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao excluir ponto: $e');
      }
      return -1;
    }
  }

  /// Busca todos os pontos
  Future<List<SoilCompactionPointModel>> getAll() async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        orderBy: 'data_coleta DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos: $e');
      }
      return [];
    }
  }

  /// Busca um ponto pelo ID
  Future<SoilCompactionPointModel?> getById(int id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return SoilCompactionPointModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar ponto por ID: $e');
      }
      return null;
    }
  }

  /// Busca pontos por talhão
  Future<List<SoilCompactionPointModel>> getByTalhao(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'point_code ASC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos por talhão: $e');
      }
      return [];
    }
  }

  /// Busca pontos por safra
  Future<List<SoilCompactionPointModel>> getBySafra(int safraId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'safra_id = ?',
        whereArgs: [safraId],
        orderBy: 'data_coleta DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos por safra: $e');
      }
      return [];
    }
  }

  /// Busca pontos por talhão e safra
  Future<List<SoilCompactionPointModel>> getByTalhaoAndSafra(
    int talhaoId,
    int safraId,
  ) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'talhao_id = ? AND safra_id = ?',
        whereArgs: [talhaoId, safraId],
        orderBy: 'point_code ASC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos por talhão e safra: $e');
      }
      return [];
    }
  }

  /// Busca pontos gerados automaticamente
  Future<List<SoilCompactionPointModel>> getAutoGenerated(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'talhao_id = ? AND is_auto_generated = 1',
        whereArgs: [talhaoId],
        orderBy: 'point_code ASC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos auto-gerados: $e');
      }
      return [];
    }
  }

  /// Busca pontos com medições pendentes (sem penetrometria)
  Future<List<SoilCompactionPointModel>> getPendentes(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: 'talhao_id = ? AND penetrometria IS NULL',
        whereArgs: [talhaoId],
        orderBy: 'point_code ASC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos pendentes: $e');
      }
      return [];
    }
  }

  /// Busca pontos críticos (compactação alta)
  Future<List<SoilCompactionPointModel>> getCriticos({
    int? talhaoId,
    double limiarMPa = 2.5,
  }) async {
    try {
      final db = await _databaseService.database;
      String whereClause = 'penetrometria >= ?';
      List<dynamic> whereArgs = [limiarMPa];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'compactacao_pontos',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'penetrometria DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilCompactionPointModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar pontos críticos: $e');
      }
      return [];
    }
  }

  /// Conta total de pontos por talhão
  Future<int> countByTalhao(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM compactacao_pontos WHERE talhao_id = ?',
        [talhaoId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao contar pontos: $e');
      }
      return 0;
    }
  }

  /// Verifica se já existem pontos auto-gerados para o talhão
  Future<bool> hasAutoGeneratedPoints(int talhaoId) async {
    try {
      final pontos = await getAutoGenerated(talhaoId);
      return pontos.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Limpa todos os pontos auto-gerados de um talhão (para re-gerar)
  Future<int> deleteAutoGeneratedPoints(int talhaoId) async {
    try {
      final db = await _databaseService.database;
      final result = await db.delete(
        'compactacao_pontos',
        where: 'talhao_id = ? AND is_auto_generated = 1',
        whereArgs: [talhaoId],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao deletar pontos auto-gerados: $e');
      }
      return 0;
    }
  }
}

