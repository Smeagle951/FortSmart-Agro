import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/weed.dart';

class WeedDao {
  AppDatabase? _database;
  
  // Construtor
  WeedDao();
  
  // Getter para o database
  Future<Database> get database async {
    _database ??= AppDatabase();
    return await _database!.database;
  }
  
  // Nome da tabela
  static const String tableName = 'weeds';
  
  // Colunas da tabela
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnScientificName = 'scientific_name';
  static const String columnDescription = 'description';
  static const String columnCropId = 'crop_id';
  static const String columnIsDefault = 'is_default';
  static const String columnSyncStatus = 'sync_status';
  static const String columnRemoteId = 'remote_id';
  
  // Criar tabela
  static const String createTable = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnName TEXT NOT NULL,
      $columnScientificName TEXT NOT NULL,
      $columnDescription TEXT,
      $columnCropId INTEGER NOT NULL,
      $columnIsDefault INTEGER NOT NULL DEFAULT 1,
      $columnSyncStatus INTEGER NOT NULL DEFAULT 0,
      $columnRemoteId INTEGER,
      FOREIGN KEY ($columnCropId) REFERENCES crops(id) ON DELETE CASCADE
    )
  ''';
  
  // Inserir uma planta daninha
  Future<int> insert(Weed weed) async {
    try {
      print('🔄 WeedDao: Iniciando inserção de planta daninha: ${weed.name}');
      final db = await database;
      print('✅ WeedDao: Banco de dados obtido');
      
      // Verificar se a tabela existe
      final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', tableName]);
      if (tables.isEmpty) {
        print('❌ WeedDao: Tabela $tableName não existe, criando...');
        await db.execute(createTable);
        print('✅ WeedDao: Tabela $tableName criada');
      }
      
      // Verificar se a cultura existe
      final crops = await db.query('crops', where: 'id = ?', whereArgs: [weed.cropId]);
      if (crops.isEmpty) {
        print('⚠️ WeedDao: Cultura ${weed.cropId} não encontrada, criando cultura padrão...');
        await db.insert('crops', {
          'id': weed.cropId,
          'name': 'Cultura ${weed.cropId}',
          'scientific_name': 'Cultura ${weed.cropId}',
          'description': 'Cultura criada automaticamente',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ WeedDao: Cultura padrão criada');
      }
      
      final weedMap = weed.toMap();
      print('📋 WeedDao: Dados para inserção: $weedMap');
      
      final result = await db.insert(
        tableName,
        weedMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('💾 WeedDao: Resultado da inserção: $result');
      return result;
    } catch (e) {
      print('❌ WeedDao: Erro na inserção: $e');
      print('❌ WeedDao: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> insertWeed(Weed weed) async {
    return await insert(weed);
  }
  
  // Atualizar uma planta daninha
  Future<int> update(Weed weed) async {
    final db = await database;
    return await db.update(
      tableName,
      weed.toMap(),
      where: '$columnId = ?',
      whereArgs: [weed.id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> updateWeed(Weed weed) async {
    return await update(weed);
  }
  
  // Excluir uma planta daninha
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> deleteWeed(int id) async {
    return await delete(id);
  }
  
  // Obter uma planta daninha pelo ID
  Future<Weed?> getById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Weed.fromMap(maps.first);
  }
  
  // Alias para compatibilidade com o repositório
  Future<Weed?> getWeedById(int id) async {
    return await getById(id);
  }
  
  // Obter todas as plantas daninhas
  Future<List<Weed>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) {
      return Weed.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Weed>> getAllWeeds() async {
    return await getAll();
  }
  
  // Obter plantas daninhas por cultura
  Future<List<Weed>> getByCropId(dynamic cropId) async {
    final db = await database;
    final cropIdStr = cropId.toString();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnCropId = ?',
      whereArgs: [cropIdStr],
    );
    
    return List.generate(maps.length, (i) {
      return Weed.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Weed>> getWeedsByCropId(dynamic cropId) async {
    return await getByCropId(cropId);
  }
  
  // Atualizar status de sincronização
  Future<int> updateSyncStatus(int id, int syncStatus, {int? remoteId}) async {
    final db = await database;
    final Map<String, dynamic> values = {
      columnSyncStatus: syncStatus,
    };
    
    if (remoteId != null) {
      values[columnRemoteId] = remoteId;
    }
    
    return await db.update(
      tableName,
      values,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Obter plantas daninhas não sincronizadas
  Future<List<Weed>> getUnsyncedWeeds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnSyncStatus = ?',
      whereArgs: [0],
    );
    
    return List.generate(maps.length, (i) {
      return Weed.fromMap(maps[i]);
    });
  }
  
  // Inserir plantas daninhas padrão
  Future<void> insertDefaultWeeds() async {
    final db = await database;
    
    // Verificar se já existem plantas daninhas
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    );
    
    if (count == 0) {
      // Plantas daninhas do Gergelim (cropId = 1)
      final List<Weed> sesameWeeds = [
        Weed(id: 1, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 1),
        Weed(id: 2, name: 'Picão-preto', scientificName: 'Bidens pilosa', cropId: 1),
        Weed(id: 3, name: 'Capim-amargoso', scientificName: 'Digitaria insularis', cropId: 1),
        Weed(id: 4, name: 'Capim-pé-de-galinha', scientificName: 'Eleusine indica', cropId: 1),
      ];
      
      // Plantas daninhas da Soja (cropId = 2)
      final List<Weed> soyaWeeds = [
        Weed(id: 5, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 2),
        Weed(id: 6, name: 'Leiteiro', scientificName: 'Euphorbia heterophylla', cropId: 2),
        Weed(id: 7, name: 'Picão-preto', scientificName: 'Bidens pilosa', cropId: 2),
        Weed(id: 8, name: 'Buva', scientificName: 'Conyza spp.', cropId: 2),
        Weed(id: 9, name: 'Capim-amargoso', scientificName: 'Digitaria insularis', cropId: 2),
        Weed(id: 10, name: 'Azevém', scientificName: 'Lolium multiflorum', cropId: 2),
        Weed(id: 11, name: 'Capim-pé-de-galinha', scientificName: 'Eleusine indica', cropId: 2),
        Weed(id: 12, name: 'Capim-marmelada', scientificName: 'Cenchrus echinatus', cropId: 2),
      ];
      
      // Plantas daninhas do Milho (cropId = 3)
      final List<Weed> cornWeeds = [
        Weed(id: 13, name: 'Sorgo-de-alepo', scientificName: 'Sorghum halepense', cropId: 3),
        Weed(id: 14, name: 'Capim-pé-de-galinha-grande', scientificName: 'Rottboellia exaltata', cropId: 3),
        Weed(id: 15, name: 'Capim-marmelada', scientificName: 'Brachiaria plantaginea', cropId: 3),
        Weed(id: 16, name: 'Capins', scientificName: 'Digitaria spp.', cropId: 3),
        Weed(id: 17, name: 'Capim-carrapicho', scientificName: 'Cenchrus echinatus', cropId: 3),
        Weed(id: 18, name: 'Buva', scientificName: 'Conyza spp.', cropId: 3),
        Weed(id: 19, name: 'Caruru-roxo', scientificName: 'Amaranthus hybridus', cropId: 3),
      ];
      
      // Plantas daninhas do Algodão (cropId = 4)
      final List<Weed> cottonWeeds = [
        Weed(id: 20, name: 'Cordas-de-viola', scientificName: 'Ipomoea spp.', cropId: 4),
        Weed(id: 21, name: 'Trapoeraba', scientificName: 'Commelina benghalensis', cropId: 4),
        Weed(id: 22, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 4),
        Weed(id: 23, name: 'Guaxuma', scientificName: 'Sida spp.', cropId: 4),
        Weed(id: 24, name: 'Capim-carrapicho', scientificName: 'Cenchrus echinatus', cropId: 4),
        Weed(id: 25, name: 'Capim-amargoso', scientificName: 'Digitaria insularis', cropId: 4),
        Weed(id: 26, name: 'Leiteiro', scientificName: 'Euphorbia heterophylla', cropId: 4),
        Weed(id: 27, name: 'Picão-preto', scientificName: 'Bidens pilosa', cropId: 4),
      ];
      
      // Plantas daninhas do Feijão (cropId = 5)
      final List<Weed> beanWeeds = [
        Weed(id: 28, name: 'Picão-preto', scientificName: 'Bidens pilosa', cropId: 5),
        Weed(id: 29, name: 'Capins', scientificName: 'Digitaria spp.', cropId: 5),
        Weed(id: 30, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 5),
        Weed(id: 31, name: 'Buva', scientificName: 'Conyza spp.', cropId: 5),
        Weed(id: 32, name: 'Capim-pé-de-galinha', scientificName: 'Eleusine indica', cropId: 5),
      ];
      
      // Plantas daninhas do Girassol (cropId = 6)
      final List<Weed> sunflowerWeeds = [
        Weed(id: 33, name: 'Cordas-de-viola', scientificName: 'Ipomoea spp.', cropId: 6),
        Weed(id: 34, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 6),
        Weed(id: 35, name: 'Picão-preto', scientificName: 'Bidens pilosa', cropId: 6),
        Weed(id: 36, name: 'Capim-amargoso', scientificName: 'Digitaria insularis', cropId: 6),
        Weed(id: 37, name: 'Trapoeraba', scientificName: 'Commelina benghalensis', cropId: 6),
      ];
      
      // Plantas daninhas do Arroz (cropId = 7)
      final List<Weed> riceWeeds = [
        Weed(id: 38, name: 'Capim-arroz', scientificName: 'Echinochloa spp.', cropId: 7),
        Weed(id: 39, name: 'Alface-d\'água', scientificName: 'Sagittaria montevidensis', cropId: 7),
        Weed(id: 40, name: 'Tiriricas', scientificName: 'Cyperus spp.', cropId: 7),
        Weed(id: 41, name: 'Cuminho', scientificName: 'Fimbristylis spp.', cropId: 7),
      ];
      
      // Plantas daninhas do Sorgo (cropId = 8)
      final List<Weed> sorghumWeeds = [
        Weed(id: 42, name: 'Sorgo-de-alepo', scientificName: 'Sorghum halepense', cropId: 8),
        Weed(id: 43, name: 'Capins', scientificName: 'Digitaria spp.', cropId: 8),
        Weed(id: 44, name: 'Capim-carrapicho', scientificName: 'Cenchrus spp.', cropId: 8),
        Weed(id: 45, name: 'Caruru', scientificName: 'Amaranthus spp.', cropId: 8),
        Weed(id: 46, name: 'Trapoeraba', scientificName: 'Commelina benghalensis', cropId: 8),
      ];
      
      // Combinar todas as plantas daninhas
      final allWeeds = [
        ...sesameWeeds,
        ...soyaWeeds,
        ...cornWeeds,
        ...cottonWeeds,
        ...beanWeeds,
        ...sunflowerWeeds,
        ...riceWeeds,
        ...sorghumWeeds,
      ];
      
      // Inserir todas as plantas daninhas em um único batch
      final batch = db.batch();
      for (var weed in allWeeds) {
        batch.insert(tableName, weed.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}
