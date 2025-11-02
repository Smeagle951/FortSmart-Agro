import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/disease.dart';

class DiseaseDao {
  AppDatabase? _database;
  
  // Construtor
  DiseaseDao();
  
  // Getter para o database
  Future<Database> get database async {
    _database ??= AppDatabase();
    return await _database!.database;
  }
  
  // Nome da tabela
  static const String tableName = 'diseases';
  
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
  
  // Inserir uma doença
  Future<int> insert(Disease disease) async {
    try {
      print('🔄 DiseaseDao: Iniciando inserção de doença: ${disease.name}');
      final db = await database;
      print('✅ DiseaseDao: Banco de dados obtido');
      
      // Verificar se a tabela existe
      final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', tableName]);
      if (tables.isEmpty) {
        print('❌ DiseaseDao: Tabela $tableName não existe, criando...');
        await db.execute(createTable);
        print('✅ DiseaseDao: Tabela $tableName criada');
      }
      
      // Verificar se a cultura existe
      final crops = await db.query('crops', where: 'id = ?', whereArgs: [disease.cropId]);
      if (crops.isEmpty) {
        print('⚠️ DiseaseDao: Cultura ${disease.cropId} não encontrada, criando cultura padrão...');
        await db.insert('crops', {
          'id': disease.cropId,
          'name': 'Cultura ${disease.cropId}',
          'scientific_name': 'Cultura ${disease.cropId}',
          'description': 'Cultura criada automaticamente',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ DiseaseDao: Cultura padrão criada');
      }
      
      final diseaseMap = disease.toMap();
      print('📋 DiseaseDao: Dados para inserção: $diseaseMap');
      
      final result = await db.insert(
        tableName,
        diseaseMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('💾 DiseaseDao: Resultado da inserção: $result');
      return result;
    } catch (e) {
      print('❌ DiseaseDao: Erro na inserção: $e');
      print('❌ DiseaseDao: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> insertDisease(Disease disease) async {
    return await insert(disease);
  }
  
  // Atualizar uma doença
  Future<int> update(Disease disease) async {
    final db = await database;
    return await db.update(
      tableName,
      disease.toMap(),
      where: '$columnId = ?',
      whereArgs: [disease.id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> updateDisease(Disease disease) async {
    return await update(disease);
  }
  
  // Excluir uma doença
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Alias para compatibilidade com o repositório
  Future<int> deleteDisease(int id) async {
    return await delete(id);
  }
  
  // Obter uma doença pelo ID
  Future<Disease?> getById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Disease.fromMap(maps.first);
  }
  
  // Alias para compatibilidade com o repositório
  Future<Disease?> getDiseaseById(int id) async {
    return await getById(id);
  }
  
  // Obter todas as doenças
  Future<List<Disease>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) {
      return Disease.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Disease>> getAllDiseases() async {
    return await getAll();
  }
  
  // Obter doenças por cultura
  Future<List<Disease>> getByCropId(dynamic cropId) async {
    final db = await database;
    final cropIdStr = cropId.toString();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnCropId = ?',
      whereArgs: [cropIdStr],
    );
    
    return List.generate(maps.length, (i) {
      return Disease.fromMap(maps[i]);
    });
  }
  
  // Alias para compatibilidade com o repositório
  Future<List<Disease>> getDiseasesByCropId(dynamic cropId) async {
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
  
  // Obter doenças não sincronizadas
  Future<List<Disease>> getUnsyncedDiseases() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnSyncStatus = ?',
      whereArgs: [0],
    );
    
    return List.generate(maps.length, (i) {
      return Disease.fromMap(maps[i]);
    });
  }
  
  // Inserir doenças padrão atualizadas
  Future<void> insertDefaultDiseases() async {
    final db = await database;
    
    // Verificar se já existem doenças
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    );
    
    if (count == 0) {
      // Doenças da Soja (cropId = 1)
      final List<Disease> soyaDiseases = [
        Disease(id: 1, name: 'Ferrugem-asiática', scientificName: 'Phakopsora pachyrhizi', cropId: 1),
        Disease(id: 2, name: 'Mancha-alvo', scientificName: 'Corynespora cassiicola', cropId: 1),
        Disease(id: 3, name: 'Oídio', scientificName: 'Microsphaera diffusa', cropId: 1),
        Disease(id: 4, name: 'Mofo-branco', scientificName: 'Sclerotinia sclerotiorum', cropId: 1),
        Disease(id: 5, name: 'Antracnose', scientificName: 'Colletotrichum truncatum', cropId: 1),
        Disease(id: 6, name: 'Cancro-da-haste', scientificName: 'Diaporthe phaseolorum f.sp. meridionalis', cropId: 1),
        Disease(id: 7, name: 'Mancha-parda', scientificName: 'Septoria glycines', cropId: 1),
        Disease(id: 8, name: 'Nematoide-de-cisto', scientificName: 'Heterodera glycines', cropId: 1),
        Disease(id: 9, name: 'Nematoide-de-galha', scientificName: 'Meloidogyne spp.', cropId: 1),
        Disease(id: 10, name: 'Nematoide-de-lesão', scientificName: 'Pratylenchus brachyurus', cropId: 1),
      ];
      
      // Doenças do Milho (cropId = 2)
      final List<Disease> cornDiseases = [
        Disease(id: 11, name: 'Ferrugem-polissora', scientificName: 'Puccinia polysora', cropId: 2),
        Disease(id: 12, name: 'Ferrugem-comum', scientificName: 'Puccinia sorghi', cropId: 2),
        Disease(id: 13, name: 'Mancha-branca', scientificName: 'Phaeosphaeria maydis', cropId: 2),
        Disease(id: 14, name: 'Mancha-de-diplodia', scientificName: 'Stenocarpella maydis', cropId: 2),
        Disease(id: 15, name: 'Mancha-de-cercospora', scientificName: 'Cercospora zeae-maydis', cropId: 2),
        Disease(id: 16, name: 'Enfezamento-vermelho', scientificName: 'Mollicutes', cropId: 2),
        Disease(id: 17, name: 'Enfezamento-pálido', scientificName: 'Mollicutes', cropId: 2),
        Disease(id: 18, name: 'Podridão-de-colmo', scientificName: 'Fusarium spp., Colletotrichum graminicola', cropId: 2),
      ];
      
      // Doenças do Sorgo (cropId = 3)
      final List<Disease> sorghumDiseases = [
        Disease(id: 19, name: 'Antracnose', scientificName: 'Colletotrichum sublineolum', cropId: 3),
        Disease(id: 20, name: 'Mancha-foliar-de-cercospora', scientificName: 'Cercospora sorghi', cropId: 3),
        Disease(id: 21, name: 'Ferrugem-do-sorgo', scientificName: 'Puccinia purpurea', cropId: 3),
        Disease(id: 22, name: 'Podridão-do-colmo', scientificName: 'Fusarium spp., Macrophomina phaseolina', cropId: 3),
      ];
      
      // Doenças do Algodão (cropId = 4)
      final List<Disease> cottonDiseases = [
        Disease(id: 23, name: 'Ramulária', scientificName: 'Ramularia areola', cropId: 4),
        Disease(id: 24, name: 'Mancha-angular', scientificName: 'Xanthomonas citri subsp. malvacearum', cropId: 4),
        Disease(id: 25, name: 'Murcha-de-fusário', scientificName: 'Fusarium oxysporum f.sp. vasinfectum', cropId: 4),
        Disease(id: 26, name: 'Verticiliose', scientificName: 'Verticillium dahliae', cropId: 4),
        Disease(id: 27, name: 'Podridão-de-esclerotinia', scientificName: 'Sclerotinia sclerotiorum', cropId: 4),
      ];
      
      // Doenças do Feijão (cropId = 5)
      final List<Disease> beanDiseases = [
        Disease(id: 28, name: 'Antracnose', scientificName: 'Colletotrichum lindemuthianum', cropId: 5),
        Disease(id: 29, name: 'Míldio', scientificName: 'Peronospora phaseoli', cropId: 5),
        Disease(id: 30, name: 'Mancha-angular', scientificName: 'Phaeoisariopsis griseola', cropId: 5),
        Disease(id: 31, name: 'Ferrugem-do-feijoeiro', scientificName: 'Uromyces appendiculatus', cropId: 5),
        Disease(id: 32, name: 'Fusariose', scientificName: 'Fusarium oxysporum', cropId: 5),
        Disease(id: 33, name: 'Mofo-branco', scientificName: 'Sclerotinia sclerotiorum', cropId: 5),
      ];
      
      // Doenças do Girassol (cropId = 6)
      final List<Disease> sunflowerDiseases = [
        Disease(id: 34, name: 'Mofo-branco', scientificName: 'Sclerotinia sclerotiorum', cropId: 6),
        Disease(id: 35, name: 'Ferrugem-do-girassol', scientificName: 'Puccinia helianthi', cropId: 6),
        Disease(id: 36, name: 'Mancha-de-alternária', scientificName: 'Alternaria helianthi', cropId: 6),
        Disease(id: 37, name: 'Verticiliose', scientificName: 'Verticillium dahliae', cropId: 6),
        Disease(id: 38, name: 'Podridão-do-colo', scientificName: 'Phoma macdonaldii', cropId: 6),
      ];
      
      // Doenças da Aveia (cropId = 7)
      final List<Disease> oatDiseases = [
        Disease(id: 39, name: 'Ferrugem-da-aveia', scientificName: 'Puccinia coronata f.sp. avenae', cropId: 7),
        Disease(id: 40, name: 'Mancha-de-pirenofora', scientificName: 'Pyrenophora avenae', cropId: 7),
        Disease(id: 41, name: 'Oídio', scientificName: 'Blumeria graminis', cropId: 7),
        Disease(id: 42, name: 'Podridão-do-colmo', scientificName: 'Fusarium spp.', cropId: 7),
      ];
      
      // Doenças do Trigo (cropId = 8)
      final List<Disease> wheatDiseases = [
        Disease(id: 43, name: 'Ferrugem-da-folha', scientificName: 'Puccinia triticina', cropId: 8),
        Disease(id: 44, name: 'Ferrugem-do-colmo', scientificName: 'Puccinia graminis f.sp. tritici', cropId: 8),
        Disease(id: 45, name: 'Ferrugem-amarela', scientificName: 'Puccinia striiformis', cropId: 8),
        Disease(id: 46, name: 'Oídio', scientificName: 'Blumeria graminis f.sp. tritici', cropId: 8),
        Disease(id: 47, name: 'Giberela', scientificName: 'Fusarium graminearum', cropId: 8),
        Disease(id: 48, name: 'Mancha-bronzeada', scientificName: 'Bipolaris sorokiniana', cropId: 8),
        Disease(id: 49, name: 'Mancha-de-pirenofora', scientificName: 'Pyrenophora tritici-repentis', cropId: 8),
      ];
      
      // Doenças do Gergelim (cropId = 9)
      final List<Disease> sesameDiseases = [
        Disease(id: 50, name: 'Murcha-de-fusário', scientificName: 'Fusarium oxysporum f.sp. sesami', cropId: 9),
        Disease(id: 51, name: 'Mancha-de-alternária', scientificName: 'Alternaria sesami', cropId: 9),
        Disease(id: 52, name: 'Cercosporiose', scientificName: 'Cercospora sesami', cropId: 9),
        Disease(id: 53, name: 'Oídio', scientificName: 'Oidium sesami', cropId: 9),
      ];
      
      // Combinar todas as doenças
      final allDiseases = [
        ...soyaDiseases,
        ...cornDiseases,
        ...sorghumDiseases,
        ...cottonDiseases,
        ...beanDiseases,
        ...sunflowerDiseases,
        ...oatDiseases,
        ...wheatDiseases,
        ...sesameDiseases,
      ];
      
      // Inserir todas as doenças em um único batch
      final batch = db.batch();
      for (var disease in allDiseases) {
        batch.insert(tableName, disease.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}
