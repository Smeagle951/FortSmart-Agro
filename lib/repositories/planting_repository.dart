import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/planting.dart';
import '../utils/logger.dart';

/// Repositório para operações com registros de plantio
class PlantingRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'plantings';

  /// Cria a tabela de plantios no banco de dados
  Future<void> createTable(Database db) async {
    try {
      Logger.info('🔍 Verificando tabela de plantios...');
      
      final createTableSQL = '''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          plotId TEXT NOT NULL,
          cropId TEXT NOT NULL,
          varietyId TEXT NOT NULL,
          plantingDate TEXT NOT NULL,
          responsiblePerson TEXT NOT NULL,
          planterId TEXT,
          tractorId TEXT,
          seedLot TEXT NOT NULL,
          targetPopulation REAL NOT NULL,
          rowSpacing REAL NOT NULL,
          observations TEXT,
          imageUrls TEXT,
          coordinates TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE CASCADE,
          FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE RESTRICT,
          FOREIGN KEY (varietyId) REFERENCES crop_varieties (id) ON DELETE RESTRICT
        )
      ''';
      
      await db.execute(createTableSQL);
      Logger.info('✅ Tabela de plantios verificada/criada com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao verificar/criar tabela de plantios: $e');
      rethrow;
    }
  }

  /// Insere um novo registro de plantio no banco de dados
  Future<String> insert(Planting planting) async {
    try {
      final db = await _database.database;
      await createTable(db);
      
      await db.insert(
        _tableName,
        planting.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Plantio inserido com sucesso: ${planting.id}');
      return planting.id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir plantio: $e');
      return '';
    }
  }

  /// Atualiza um registro de plantio existente
  Future<int> update(Planting planting) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      planting.toMap(),
      where: 'id = ?',
      whereArgs: [planting.id],
    );
  }

  /// Remove um registro de plantio
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém um registro de plantio pelo ID
  Future<Planting?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Planting.fromMap(maps.first);
  }

  /// Obtém todos os registros de plantio
  Future<List<Planting>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => Planting.fromMap(maps[i]));
  }

  /// Obtém todos os registros de plantio
  Future<List<Planting>> getAllPlantings() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) {
        return Planting.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao obter todos os plantios: $e');
      return [];
    }
  }

  /// Obtém registros de plantio por cultura
  Future<List<Planting>> getPlantingsByCrop(String cropName) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cropType = ?',
        whereArgs: [cropName],
      );
      return List.generate(maps.length, (i) {
        return Planting.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao obter plantios por cultura: $e');
      return [];
    }
  }

  /// Obtém registros de plantio por talhão
  Future<List<Planting>> getPlantingsByPlotId(String plotId) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'plotId = ?',
        whereArgs: [plotId],
      );
      return List.generate(maps.length, (i) {
        return Planting.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao obter plantios por talhão: $e');
      return [];
    }
  }

  /// Obtém todos os registros de plantio para uma cultura específica
  Future<List<Planting>> getByCropId(String cropId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'cropId = ?',
      whereArgs: [cropId],
    );
    return List.generate(maps.length, (i) => Planting.fromMap(maps[i]));
  }

  /// Obtém os registros de plantio pendentes de sincronização
  Future<List<Planting>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Planting.fromMap(maps[i]));
  }

  /// Marca um registro de plantio como sincronizado
  Future<int> markAsSynced(String id) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Conta o número total de registros de plantio
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Busca os plantios mais recentes
  Future<List<Planting>> getRecentPlantings({int limit = 5}) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'plantingDate DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Planting.fromMap(maps[i]));
  }
  
  /// Atualiza os progressos de plantio com dados recebidos da API
  Future<bool> updatePlantingProgress(List<dynamic> progressData) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      // Criar tabela de progresso de plantio se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS planting_progress (
          id TEXT PRIMARY KEY,
          plot_id TEXT NOT NULL,
          planting_id TEXT,
          dae INTEGER NOT NULL,
          expected_stage TEXT NOT NULL,
          current_stage TEXT,
          progress_percentage REAL NOT NULL,
          next_milestone TEXT,
          days_to_next_milestone INTEGER,
          issues TEXT,
          recommendations TEXT,
          last_updated TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE,
          FOREIGN KEY (planting_id) REFERENCES $_tableName (id) ON DELETE CASCADE
        )
      ''');
      
      // Iniciar transação para atualizar progresso de plantio
      await db.transaction((txn) async {
        // Processar cada registro de progresso recebido da API
        for (final progressItem in progressData) {
          final String progressId = progressItem['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          final String plotId = progressItem['plot_id'];
          final String? plantingId = progressItem['planting_id'];
          final int dae = progressItem['dae'] ?? 0;
          final String expectedStage = progressItem['expected_stage'] ?? 'Não definido';
          final String? currentStage = progressItem['current_stage'];
          final double progressPercentage = (progressItem['progress_percentage'] ?? 0.0).toDouble();
          final String? nextMilestone = progressItem['next_milestone'];
          final int? daysToNextMilestone = progressItem['days_to_next_milestone'];
          final String? issues = progressItem['issues'];
          final String? recommendations = progressItem['recommendations'];
          final String lastUpdated = progressItem['last_updated'] ?? DateTime.now().toIso8601String();
          
          // Verificar se o registro já existe
          final existingProgress = await txn.query(
            'planting_progress',
            where: 'plot_id = ? AND planting_id = ?',
            whereArgs: [plotId, plantingId],
            limit: 1,
          );
          
          if (existingProgress.isEmpty) {
            // Inserir novo registro de progresso
            await txn.insert(
              'planting_progress',
              {
                'id': progressId,
                'plot_id': plotId,
                'planting_id': plantingId,
                'dae': dae,
                'expected_stage': expectedStage,
                'current_stage': currentStage,
                'progress_percentage': progressPercentage,
                'next_milestone': nextMilestone,
                'days_to_next_milestone': daysToNextMilestone,
                'issues': issues,
                'recommendations': recommendations,
                'last_updated': lastUpdated,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          } else {
            // Atualizar registro existente
            await txn.update(
              'planting_progress',
              {
                'dae': dae,
                'expected_stage': expectedStage,
                'current_stage': currentStage,
                'progress_percentage': progressPercentage,
                'next_milestone': nextMilestone,
                'days_to_next_milestone': daysToNextMilestone,
                'issues': issues,
                'recommendations': recommendations,
                'last_updated': lastUpdated,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'plot_id = ? AND planting_id = ?',
              whereArgs: [plotId, plantingId],
            );
          }
        }
      });
      
      print('Progresso de plantio atualizado com sucesso');
      return true;
    } catch (e) {
      print('Erro ao atualizar progresso de plantio: $e');
      return false;
    }
  }
}
