import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/pest.dart';

class PestDao {
  AppDatabase? _database;
  
  // Construtor
  PestDao();
  
  // Getter para o database
  Future<Database> get database async {
    _database ??= AppDatabase();
    return await _database!.database;
  }
  
  // Nome da tabela
  static const String tableName = 'pests';
  
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
  
  // Inserir uma praga
  Future<int> insert(Pest pest) async {
    try {
      print('🔄 PestDao: Iniciando inserção de praga: ${pest.name}');
      final db = await database;
      print('✅ PestDao: Banco de dados obtido');
      
      // Verificar se a tabela existe
      final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', tableName]);
      if (tables.isEmpty) {
        print('❌ PestDao: Tabela $tableName não existe, criando...');
        await db.execute(createTable);
        print('✅ PestDao: Tabela $tableName criada');
      }
      
      // Verificar se a cultura existe
      final crops = await db.query('crops', where: 'id = ?', whereArgs: [pest.cropId]);
      if (crops.isEmpty) {
        print('⚠️ PestDao: Cultura ${pest.cropId} não encontrada, criando cultura padrão...');
        await db.insert('crops', {
          'id': pest.cropId,
          'name': 'Cultura ${pest.cropId}',
          'scientific_name': 'Cultura ${pest.cropId}',
          'description': 'Cultura criada automaticamente',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ PestDao: Cultura padrão criada');
      }
      
      final pestMap = pest.toMap();
      print('📋 PestDao: Dados para inserção: $pestMap');
      
      // Remover o ID se for 0 para permitir auto-incremento
      if (pestMap['id'] == 0) {
        pestMap.remove('id');
      }
      
      final result = await db.insert(
        tableName,
        pestMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('💾 PestDao: Resultado da inserção: $result');
      return result;
    } catch (e) {
      print('❌ PestDao: Erro na inserção: $e');
      print('❌ PestDao: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> insertPest(Pest pest) async {
    return await insert(pest);
  }
  
  // Atualizar uma praga
  Future<int> update(Pest pest) async {
    final db = await database;
    return await db.update(
      tableName,
      pest.toMap(),
      where: '$columnId = ?',
      whereArgs: [pest.id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> updatePest(Pest pest) async {
    return await update(pest);
  }
  
  // Excluir uma praga
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> deletePest(int id) async {
    return await delete(id);
  }
  
  // Obter uma praga pelo ID
  Future<Pest?> getById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Pest.fromMap(maps.first);
  }
  
  // Alias para compatibilidade com o repositório
  Future<Pest?> getPestById(int id) async {
    return await getById(id);
  }
  
  // Obter todas as pragas
  Future<List<Pest>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) {
      return Pest.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Pest>> getAllPests() async {
    return await getAll();
  }
  
  // Obter pragas por cultura
  Future<List<Pest>> getByCropId(dynamic cropId) async {
    final db = await database;
    final cropIdStr = cropId.toString();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnCropId = ?',
      whereArgs: [cropIdStr],
    );
    
    return List.generate(maps.length, (i) {
      return Pest.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Pest>> getPestsByCropId(dynamic cropId) async {
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
  
  // Obter pragas não sincronizadas
  Future<List<Pest>> getUnsyncedPests() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnSyncStatus = ?',
      whereArgs: [0],
    );
    
    return List.generate(maps.length, (i) {
      return Pest.fromMap(maps[i]);
    });
  }
  
  // Inserir pragas padrão atualizadas
  Future<void> insertDefaultPests() async {
    final db = await database;
    
    // Verificar se já existem pragas
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    );
    
    if (count == 0) {
      // Pragas da Soja (cropId = 1) - Todas as pragas principais
      final List<Pest> soyaPests = [
        Pest(id: 1, name: 'Bicudo-da-soja', scientificName: 'Sternechus subsignatus', cropId: 1),
        Pest(id: 2, name: 'Tamanduá-da-soja', scientificName: 'Sternechus spp.', cropId: 1),
        Pest(id: 3, name: 'Percevejo-marrom', scientificName: 'Euschistus heros', cropId: 1),
        Pest(id: 4, name: 'Percevejo-verde', scientificName: 'Nezara viridula', cropId: 1),
        Pest(id: 5, name: 'Percevejo-verde-pequeno', scientificName: 'Piezodorus guildinii', cropId: 1),
        Pest(id: 6, name: 'Lagarta-da-soja', scientificName: 'Anticarsia gemmatalis', cropId: 1),
        Pest(id: 7, name: 'Lagarta-falsa-medideira', scientificName: 'Chrysodeixis includens', cropId: 1),
        Pest(id: 8, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 1),
        Pest(id: 9, name: 'Lagarta-helicoverpa', scientificName: 'Helicoverpa armigera', cropId: 1),
        Pest(id: 10, name: 'Mosca-branca', scientificName: 'Bemisia tabaci', cropId: 1),
        Pest(id: 11, name: 'Vaquinha', scientificName: 'Diabrotica speciosa', cropId: 1),
        Pest(id: 12, name: 'Ácaro-rajado', scientificName: 'Tetranychus urticae', cropId: 1),
        Pest(id: 13, name: 'Caramujo', scientificName: 'Achatina fulica', cropId: 1),
        Pest(id: 56, name: 'Torrãozinho', scientificName: 'Scaptocoris castanea', cropId: 1),
      ];
      
      // Pragas do Milho (cropId = 2)
      final List<Pest> cornPests = [
        Pest(id: 14, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 2),
        Pest(id: 15, name: 'Lagarta-elasmo', scientificName: 'Elasmopalpus lignosellus', cropId: 2),
        Pest(id: 16, name: 'Lagarta-rosca', scientificName: 'Agrotis ipsilon', cropId: 2),
        Pest(id: 17, name: 'Percevejo-barriga-verde', scientificName: 'Dichelops spp.', cropId: 2),
        Pest(id: 18, name: 'Cigarrinha-do-milho', scientificName: 'Dalbulus maidis', cropId: 2),
        Pest(id: 19, name: 'Pulgão-do-milho', scientificName: 'Rhopalosiphum maidis', cropId: 2),
        Pest(id: 20, name: 'Coró', scientificName: 'Phyllophaga spp.', cropId: 2),
        Pest(id: 21, name: 'Broca-da-cana', scientificName: 'Diatraea saccharalis', cropId: 2),
      ];
      
      // Pragas do Sorgo (cropId = 3)
      final List<Pest> sorghumPests = [
        Pest(id: 22, name: 'Pulgão-do-sorgo', scientificName: 'Melanaphis sacchari', cropId: 3),
        Pest(id: 23, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 3),
        Pest(id: 24, name: 'Percevejo-barriga-verde', scientificName: 'Dichelops spp.', cropId: 3),
        Pest(id: 25, name: 'Lagarta-das-panículas', scientificName: 'Helicoverpa zea', cropId: 3),
        Pest(id: 26, name: 'Mosca-do-sorgo', scientificName: 'Contarinia sorghicola', cropId: 3),
      ];
      
      // Pragas do Algodão (cropId = 4)
      final List<Pest> cottonPests = [
        Pest(id: 27, name: 'Bicudo-do-algodoeiro', scientificName: 'Anthonomus grandis', cropId: 4),
        Pest(id: 28, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 4),
        Pest(id: 29, name: 'Lagarta-rosada', scientificName: 'Pectinophora gossypiella', cropId: 4),
        Pest(id: 30, name: 'Ácaro-rajado', scientificName: 'Tetranychus urticae', cropId: 4),
        Pest(id: 31, name: 'Pulgão-do-algodoeiro', scientificName: 'Aphis gossypii', cropId: 4),
        Pest(id: 32, name: 'Mosca-branca', scientificName: 'Bemisia tabaci', cropId: 4),
        Pest(id: 33, name: 'Tripes', scientificName: 'Frankliniella schultzei', cropId: 4),
        Pest(id: 34, name: 'Vaquinha', scientificName: 'Diabrotica speciosa', cropId: 4),
      ];
      
      // Pragas do Feijão (cropId = 5)
      final List<Pest> beanPests = [
        Pest(id: 35, name: 'Mosca-branca', scientificName: 'Bemisia tabaci', cropId: 5),
        Pest(id: 36, name: 'Pulgão-preto', scientificName: 'Aphis craccivora', cropId: 5),
        Pest(id: 37, name: 'Cigarrinha-verde', scientificName: 'Empoasca kraemeri', cropId: 5),
        Pest(id: 38, name: 'Lagarta-helicoverpa', scientificName: 'Helicoverpa armigera', cropId: 5),
        Pest(id: 39, name: 'Lagarta-das-vagens', scientificName: 'Etiella zinckenella', cropId: 5),
        Pest(id: 40, name: 'Ácaro-rajado', scientificName: 'Tetranychus urticae', cropId: 5),
      ];
      
      // Pragas do Girassol (cropId = 6)
      final List<Pest> sunflowerPests = [
        Pest(id: 41, name: 'Lagarta-da-coroa', scientificName: 'Agrotis ipsilon', cropId: 6),
        Pest(id: 42, name: 'Lagarta-do-capítulo', scientificName: 'Helicoverpa armigera', cropId: 6),
        Pest(id: 43, name: 'Percevejo-marrom', scientificName: 'Nezara viridula', cropId: 6),
        Pest(id: 44, name: 'Pulgão-preto', scientificName: 'Aphis fabae', cropId: 6),
      ];
      
      // Pragas da Aveia (cropId = 7)
      final List<Pest> oatPests = [
        Pest(id: 45, name: 'Pulgão-da-aveia', scientificName: 'Rhopalosiphum padi', cropId: 7),
        Pest(id: 46, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 7),
        Pest(id: 47, name: 'Gorgulho-do-colmo', scientificName: 'Sitodiplosis mosellana', cropId: 7),
      ];
      
      // Pragas do Trigo (cropId = 8)
      final List<Pest> wheatPests = [
        Pest(id: 48, name: 'Pulgão-verde-dos-cereais', scientificName: 'Schizaphis graminum', cropId: 8),
        Pest(id: 49, name: 'Pulgão-da-espiga', scientificName: 'Sitobion avenae', cropId: 8),
        Pest(id: 50, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 8),
        Pest(id: 51, name: 'Gorgulho-do-colmo', scientificName: 'Sitodiplosis mosellana', cropId: 8),
      ];
      
      // Pragas do Gergelim (cropId = 9)
      final List<Pest> sesamePests = [
        Pest(id: 52, name: 'Lagarta-helicoverpa', scientificName: 'Helicoverpa armigera', cropId: 9),
        Pest(id: 53, name: 'Lagarta-do-cartucho', scientificName: 'Spodoptera frugiperda', cropId: 9),
        Pest(id: 54, name: 'Mosca-branca', scientificName: 'Bemisia tabaci', cropId: 9),
        Pest(id: 55, name: 'Tripes', scientificName: 'Frankliniella schultzei', cropId: 9),
      ];
      
            // Combinar todas as pragas
      final allPests = [
        ...soyaPests,
        ...cornPests,
        ...sorghumPests,
        ...cottonPests,
        ...beanPests,
        ...sunflowerPests,
        ...oatPests,
        ...wheatPests,
        ...sesamePests,
      ];
      
      // Inserir todas as pragas em um único batch
      final batch = db.batch();
      for (var pest in allPests) {
        batch.insert(tableName, pest.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}
