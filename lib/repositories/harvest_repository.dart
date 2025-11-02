import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../models/harvest_new.dart' as new_model;
import '../models/harvest.dart';
import '../utils/logger.dart';

class HarvestRepository {
  final AppDatabase _database = AppDatabase();

  /// Inicializa as tabelas de colheita
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabela de colheitas...');
      
      const harvestsTableSQL = '''
        CREATE TABLE IF NOT EXISTS harvests (
          id TEXT PRIMARY KEY,
          plotId TEXT NOT NULL,
          cropId TEXT NOT NULL,
          varietyId TEXT NOT NULL,
          harvestDate TEXT NOT NULL,
          yield REAL NOT NULL,
          totalProduction REAL NOT NULL,
          responsiblePerson TEXT NOT NULL,
          observations TEXT,
          imageUrls TEXT,
          coordinates TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          lastAccessedAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0,
          harvestedArea REAL NOT NULL DEFAULT 0.0,
          sackWeight REAL NOT NULL DEFAULT 60.0,
          FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE CASCADE
        )
      ''';
      
      final db = await _database.database;
      await db.execute(harvestsTableSQL);
      Logger.info('✅ Tabela de colheitas inicializada com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabela de colheitas: $e');
      rethrow;
    }
  }

  // Obter todas as colheitas não expiradas
  Future<List<new_model.Harvest>> getAll() async {
    try {
      Logger.info('🔄 Carregando todas as colheitas...');
      
      // Inicializar tabela se necessário
      await initialize();
      
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('harvests');
      
      final harvests = List.generate(maps.length, (i) {
        try {
          // Tentar converter para o novo modelo
          final Map<String, dynamic> jsonData = Map<String, dynamic>.from(maps[i]);
          
          // Garantir que o campo lastAccessedAt existe
          if (!jsonData.containsKey('lastAccessedAt')) {
            jsonData['lastAccessedAt'] = DateTime.now().toIso8601String();
          }
          
          return new_model.Harvest.fromJson(jsonData);
        } catch (e) {
          Logger.warning('⚠️ Erro ao converter colheita: $e');
          // Criar um objeto padrão em caso de erro
          return new_model.Harvest(
            id: maps[i]['id'] ?? 'erro-${DateTime.now().millisecondsSinceEpoch}',
            plotId: maps[i]['plotId'] ?? '',
            cropId: maps[i]['cropId'] ?? '',
            varietyId: maps[i]['varietyId'] ?? '',
            harvestDate: DateTime.tryParse(maps[i]['harvestDate'] ?? '') ?? DateTime.now(),
            yield: double.tryParse(maps[i]['yield']?.toString() ?? '0') ?? 0.0,
            totalProduction: double.tryParse(maps[i]['totalProduction']?.toString() ?? '0') ?? 0.0,
            responsiblePerson: maps[i]['responsiblePerson'] ?? '',
            observations: maps[i]['observations'] ?? '',
            imageUrls: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lastAccessedAt: DateTime.now(),
            isSynced: false,
            harvestedArea: double.tryParse(maps[i]['harvestedArea']?.toString() ?? '0') ?? 0.0,
            sackWeight: 60.0,
          );
        }
      });
      
      // Filtrar colheitas não expiradas
      final validHarvests = harvests.where((harvest) => !harvest.isExpired).toList();
      
      Logger.info('✅ ${validHarvests.length} colheitas válidas carregadas');
      return validHarvests;
    } catch (e) {
      Logger.error('❌ Erro ao carregar colheitas: $e');
      return [];
    }
  }
  
  // Método legado para compatibilidade
  Future<List<Harvest>> getAllHarvests() async {
    try {
      await initialize();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('harvests');
      return List.generate(maps.length, (i) {
        return Harvest.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar colheitas legadas: $e');
      return [];
    }
  }

  // Obter uma colheita pelo ID e atualizar o último acesso
  Future<new_model.Harvest?> getById(String id) async {
    try {
      await initialize();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'harvests',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      
      try {
        // Converter para o novo modelo
        final harvest = new_model.Harvest.fromJson(maps.first);
        
        // Atualizar último acesso
        await updateLastAccessed(id);
        
        Logger.info('✅ Colheita carregada: $id');
        return harvest;
      } catch (e) {
        Logger.error('❌ Erro ao converter colheita: $e');
        return null;
      }
    } catch (e) {
      Logger.error('❌ Erro ao obter colheita por ID: $e');
      return null;
    }
  }
  
  // Método legado para compatibilidade
  Future<Harvest?> getHarvest(String id) async {
    try {
      await initialize();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'harvests',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Harvest.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter colheita legada por ID: $e');
      return null;
    }
  }

  Future<List<Harvest>> getRecentHarvests({int limit = 5}) async {
    try {
      await initialize();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'harvests',
        orderBy: 'harvestDate DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) {
        return Harvest.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao obter colheitas recentes: $e');
      return [];
    }
  }

  // Adicionar uma nova colheita
  Future<String> add(new_model.Harvest harvest) async {
    try {
      Logger.info('💾 Salvando nova colheita: ${harvest.id}');
      
      await initialize();
      final db = await _database.database;
      
      // Garantir que lastAccessedAt está definido como agora
      final Map<String, dynamic> data = harvest.toJson();
      data['lastAccessedAt'] = DateTime.now().toIso8601String();
      
      await db.insert(
        'harvests',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Colheita salva com sucesso: ${harvest.id}');
      return harvest.id;
    } catch (e) {
      Logger.error('❌ Erro ao adicionar colheita: $e');
      return '';
    }
  }
  
  // Atualizar uma colheita existente
  Future<int> update(new_model.Harvest harvest) async {
    try {
      Logger.info('🔄 Atualizando colheita: ${harvest.id}');
      
      await initialize();
      final db = await _database.database;
      
      // Garantir que lastAccessedAt está definido como agora
      final Map<String, dynamic> data = harvest.toJson();
      data['lastAccessedAt'] = DateTime.now().toIso8601String();
      
      final result = await db.update(
        'harvests',
        data,
        where: 'id = ?',
        whereArgs: [harvest.id],
      );
      
      Logger.info('✅ Colheita atualizada com sucesso: ${harvest.id}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar colheita: $e');
      return 0;
    }
  }
  
  // Atualizar apenas o campo lastAccessedAt
  Future<int> updateLastAccessed(String id) async {
    try {
      await initialize();
      final db = await _database.database;
      
      return await db.update(
        'harvests',
        {'lastAccessedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Logger.error('❌ Erro ao atualizar último acesso: $e');
      return 0;
    }
  }
  
  // Remover colheitas expiradas
  Future<int> removeExpiredHarvests() async {
    try {
      Logger.info('🗑️ Removendo colheitas expiradas...');
      
      await initialize();
      final db = await _database.database;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      final result = await db.delete(
        'harvests',
        where: 'lastAccessedAt < ?',
        whereArgs: [sevenDaysAgo],
      );
      
      Logger.info('✅ $result colheitas expiradas removidas');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao remover colheitas expiradas: $e');
      return 0;
    }
  }
  
  // Método legado para compatibilidade
  Future<String> saveHarvest(Harvest harvest) async {
    try {
      await initialize();
      final db = await _database.database;
      await db.insert(
        'harvests',
        harvest.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return harvest.id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar colheita legada: $e');
      return '';
    }
  }

  Future<int> updateHarvest(Harvest harvest) async {
    try {
      await initialize();
      final db = await _database.database;
      return await db.update(
        'harvests',
        harvest.toMap(),
        where: 'id = ?',
        whereArgs: [harvest.id],
      );
    } catch (e) {
      Logger.error('❌ Erro ao atualizar colheita legada: $e');
      return 0;
    }
  }

  Future<int> deleteHarvest(String id) async {
    try {
      Logger.info('🗑️ Excluindo colheita: $id');
      
      await initialize();
      final db = await _database.database;
      final result = await db.delete(
        'harvests',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Colheita excluída com sucesso: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao excluir colheita: $e');
      return 0;
    }
  }
  
  /// Obtém colheitas por talhão
  Future<List<Harvest>> getHarvestsByPlotId(String plotId) async {
    try {
      Logger.info('🔍 Buscando colheitas do talhão: $plotId');
      
      await initialize();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'harvests',
        where: 'plotId = ?',
        whereArgs: [plotId],
      );
      
      final harvests = List.generate(maps.length, (i) {
        return Harvest.fromMap(maps[i]);
      });
      
      Logger.info('✅ ${harvests.length} colheitas encontradas para o talhão: $plotId');
      return harvests;
    } catch (e) {
      Logger.error('❌ Erro ao obter colheitas por talhão: $e');
      return [];
    }
  }
}
