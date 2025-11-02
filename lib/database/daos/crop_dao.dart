import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/crop.dart';
import '../../utils/logger.dart';

class CropDao {
  AppDatabase? _database;
  
  /// Obtém a instância do AppDatabase de forma lazy
  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }

  
  static const String tableName = 'crops';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnScientificName = 'scientific_name';
  static const String columnFamily = 'family';
  static const String columnDescription = 'description';
  static const String columnImageUrl = 'image_url';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncStatus = 'sync_status';
  static const String columnRemoteId = 'remote_id';

  /// Inicializa a tabela de culturas
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabela de culturas...');
      
      const cropsTableSQL = '''
        CREATE TABLE IF NOT EXISTS $tableName (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnName TEXT NOT NULL,
          $columnScientificName TEXT,
          $columnFamily TEXT,
          $columnDescription TEXT,
          $columnImageUrl TEXT,
          $columnCreatedAt TEXT NOT NULL,
          $columnUpdatedAt TEXT NOT NULL,
          $columnSyncStatus INTEGER NOT NULL DEFAULT 0,
          $columnRemoteId INTEGER
        )
      ''';
      
      final db = await database.database;
      await db.execute(cropsTableSQL);
      Logger.info('✅ Tabela de culturas inicializada com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabela de culturas: $e');
      rethrow;
    }
  }

  // Inserir uma nova cultura
  Future<int> insert(Crop crop) async {
    try {
      Logger.info('💾 Inserindo cultura: ${crop.name}');
      
      await initialize();
      final db = await database.database;
      
      final result = await db.insert(
        tableName,
        crop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Cultura inserida com sucesso: ${crop.name} (ID: $result)');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao inserir cultura: $e');
      return -1;
    }
  }

  // Atualizar uma cultura existente
  Future<int> update(Crop crop) async {
    try {
      Logger.info('🔄 Atualizando cultura: ${crop.name}');
      
      await initialize();
      final db = await database.database;
      
      final result = await db.update(
        tableName,
        crop.toMap(),
        where: '$columnId = ?',
        whereArgs: [crop.id],
      );
      
      Logger.info('✅ Cultura atualizada com sucesso: ${crop.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar cultura: $e');
      return 0;
    }
  }

  // Excluir uma cultura
  Future<int> delete(int id) async {
    try {
      Logger.info('🗑️ Excluindo cultura: $id');
      
      await initialize();
      final db = await database.database;
      
      final result = await db.delete(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Cultura excluída com sucesso: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao excluir cultura: $e');
      return 0;
    }
  }

  // Obter uma cultura por ID
  Future<Crop> getById(int id) async {
    try {
      await initialize();
      final db = await database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        Logger.info('ℹ️ Cultura não encontrada: $id');
        throw Exception('Cultura não encontrada: $id');
      }
      
      Logger.info('✅ Cultura carregada: ${maps.first[columnName]}');
      return Crop.fromMap(maps.first);
    } catch (e) {
      Logger.error('❌ Erro ao obter cultura por ID: $e');
      throw Exception('Erro ao obter cultura por ID: $e');
    }
  }
  
  // Alias para compatibilidade com o repositório
  Future<Crop> getCropById(int id) async {
    return await getById(id);
  }
  
  // Obter todas as culturas
  Future<List<Crop>> getAll() async {
    try {
      Logger.info('🔄 Carregando todas as culturas...');
      
      await initialize();
      final db = await database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      
      final crops = List.generate(maps.length, (i) {
        return Crop.fromMap(maps[i]);
      });
      
      Logger.info('✅ ${crops.length} culturas carregadas');
      return crops;
    } catch (e) {
      Logger.error('❌ Erro ao carregar todas as culturas: $e');
      return [];
    }
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Crop>> getAllCrops() async {
    return await getAll();
  }
  
  // Atualizar status de sincronização
  Future<int> updateSyncStatus(int id, int syncStatus, {int? remoteId}) async {
    try {
      Logger.info('🔄 Atualizando status de sincronização da cultura: $id');
      
      await initialize();
      final db = await database.database;
      
      final Map<String, dynamic> values = {
        columnSyncStatus: syncStatus,
      };
      
      if (remoteId != null) {
        values[columnRemoteId] = remoteId;
      }
      
      final result = await db.update(
        tableName,
        values,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Status de sincronização atualizado: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar status de sincronização: $e');
      return 0;
    }
  }
  
  // Obter culturas não sincronizadas
  Future<List<Crop>> getUnsyncedCrops() async {
    try {
      Logger.info('🔄 Carregando culturas não sincronizadas...');
      
      await initialize();
      final db = await database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$columnSyncStatus = ?',
        whereArgs: [0],
      );
      
      final crops = List.generate(maps.length, (i) {
        return Crop.fromMap(maps[i]);
      });
      
      Logger.info('✅ ${crops.length} culturas não sincronizadas encontradas');
      return crops;
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas não sincronizadas: $e');
      return [];
    }
  }
  
  // Inserir culturas padrão
  Future<void> insertDefaultCrops() async {
    try {
      Logger.info('🔄 Inserindo culturas padrão...');
      
      await initialize();
      final db = await database.database;
      
      // Verificar se já existem culturas
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName')
      );
      Logger.info('📊 ${count ?? 0} culturas existentes');
      
      if (count == 0) {
        Logger.info('🔄 Inserindo culturas padrão...');
        // Inserir culturas padrão atualizadas com todas as 9 culturas principais
        final List<Crop> defaultCrops = [
          Crop(id: 1, name: 'Soja', description: 'Glycine max - Cultura principal do Brasil'),
          Crop(id: 2, name: 'Milho', description: 'Zea mays - Cereal mais cultivado'),
          Crop(id: 3, name: 'Sorgo', description: 'Sorghum bicolor - Cereal resistente à seca'),
          Crop(id: 4, name: 'Algodão', description: 'Gossypium hirsutum - Fibra natural'),
          Crop(id: 5, name: 'Feijão', description: 'Phaseolus vulgaris - Proteína vegetal'),
          Crop(id: 6, name: 'Girassol', description: 'Helianthus annuus - Oleaginosa'),
          Crop(id: 7, name: 'Aveia', description: 'Avena sativa - Cereal de inverno'),
          Crop(id: 8, name: 'Trigo', description: 'Triticum aestivum - Cereal de inverno'),
          Crop(id: 9, name: 'Gergelim', description: 'Sesamum indicum - Cultura oleaginosa'),
        ];
        
        final batch = db.batch();
        for (var crop in defaultCrops) {
          Logger.info('  - Inserindo: ${crop.name}');
          batch.insert(tableName, crop.toMap());
        }
        await batch.commit(noResult: true);
        Logger.info('✅ ${defaultCrops.length} culturas padrão inseridas');
      } else {
        Logger.info('ℹ️ Culturas já existem, pulando inserção');
      }
    } catch (e) {
      Logger.error('❌ Erro ao inserir culturas padrão: $e');
      rethrow;
    }
  }
}
