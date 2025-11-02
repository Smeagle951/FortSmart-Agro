import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/models/crop.dart';
import '../database/models/pest.dart';
import '../database/models/disease.dart';
import '../database/models/weed.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';

import '../utils/logger.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class CropRepository {
  final CropDao _cropDao;
  final PestDao _pestDao;
  final DiseaseDao _diseaseDao;
  final WeedDao _weedDao;
  AppDatabase? _database;
  
  /// Obtém a instância do AppDatabase de forma lazy
  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }
  
  CropRepository({
    CropDao? cropDao,
    PestDao? pestDao,
    DiseaseDao? diseaseDao,
    WeedDao? weedDao,
  }) : _cropDao = cropDao ?? CropDao(),
       _pestDao = pestDao ?? PestDao(),
       _diseaseDao = diseaseDao ?? DiseaseDao(),
       _weedDao = weedDao ?? WeedDao();

  /// Inicializa as tabelas de culturas e organismos
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabelas de culturas e organismos...');
      
      final db = await database.database;
      
      // Tabela de culturas - versão unificada
      const cropsTableSQL = '''
        CREATE TABLE IF NOT EXISTS crops (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          scientific_name TEXT,
          family TEXT,
          description TEXT,
          image_url TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status INTEGER NOT NULL DEFAULT 0,
          remote_id INTEGER
        )
      ''';
      
      // Tabela de pragas - versão unificada
      const pestsTableSQL = '''
        CREATE TABLE IF NOT EXISTS pests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          scientific_name TEXT NOT NULL,
          description TEXT,
          crop_id INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 1,
          sync_status INTEGER NOT NULL DEFAULT 0,
          remote_id INTEGER,
          FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE CASCADE
        )
      ''';
      
      // Tabela de doenças - versão unificada
      const diseasesTableSQL = '''
        CREATE TABLE IF NOT EXISTS diseases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          scientific_name TEXT NOT NULL,
          description TEXT,
          crop_id INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 1,
          sync_status INTEGER NOT NULL DEFAULT 0,
          remote_id INTEGER,
          FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE CASCADE
        )
      ''';
      
      // Tabela de plantas daninhas - versão unificada
      const weedsTableSQL = '''
        CREATE TABLE IF NOT EXISTS weeds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          scientific_name TEXT NOT NULL,
          description TEXT,
          crop_id INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 1,
          sync_status INTEGER NOT NULL DEFAULT 0,
          remote_id INTEGER,
          FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE CASCADE
        )
      ''';
      
      // Executar criação das tabelas
      await db.execute(cropsTableSQL);
      await db.execute(pestsTableSQL);
      await db.execute(diseasesTableSQL);
      await db.execute(weedsTableSQL);
      
      Logger.info('✅ Tabelas de culturas e organismos inicializadas com sucesso');
      
      // Verificar se existem dados padrão
      final cropsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM crops')
      ) ?? 0;
      
      if (cropsCount == 0) {
        Logger.info('📝 Inserindo culturas padrão...');
        await _insertDefaultCrops();
      }
      
      final pestsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pests')
      ) ?? 0;
      
      if (pestsCount == 0) {
        Logger.info('📝 Inserindo pragas padrão...');
        await _insertDefaultPests();
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabelas: $e');
      rethrow;
    }
  }

  /// Cria culturas padrão no banco de dados
  Future<void> _createDefaultCrops(Database db) async {
    try {
      final defaultCrops = [
        {
          'name': 'Soja',
          'scientific_name': 'Glycine max',
          'description': 'Cultura de grãos',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Milho',
          'scientific_name': 'Zea mays',
          'description': 'Cultura de grãos',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Algodão',
          'scientific_name': 'Gossypium hirsutum',
          'description': 'Cultura de fibra',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Feijão',
          'scientific_name': 'Phaseolus vulgaris',
          'description': 'Cultura de grãos',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      for (final crop in defaultCrops) {
        await db.insert('crops', crop);
      }
      
      Logger.info('✅ ${defaultCrops.length} culturas padrão criadas');
    } catch (e) {
      Logger.error('❌ Erro ao criar culturas padrão: $e');
    }
  }
  
  // Métodos para culturas
  Future<List<Crop>> getAll() async {
    return await getAllCrops();
  }
  
  // Método getCrops para compatibilidade com DataCacheService
  Future<List<Crop>> getCrops() async {
    return await getAllCrops();
  }
  
  Future<List<Crop>> getAllCrops() async {
    try {
      Logger.info('🔄 Carregando todas as culturas...');
      await initialize();
      final crops = await _cropDao.getAllCrops();
      Logger.info('✅ ${crops.length} culturas carregadas');
      return crops;
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      return [];
    }
  }
  
  Future<Crop> getById(int id) async {
    try {
      await initialize();
      final crop = await _cropDao.getCropById(id);
      Logger.info('✅ Cultura carregada: $id');
      return crop;
    } catch (e) {
      Logger.error('❌ Erro ao buscar cultura por ID: $e');
      throw Exception('Erro ao buscar cultura por ID: $e');
    }
  }
  
  Future<Crop> getCropById(dynamic id) async {
    if (id is int) {
      return await getById(id);
    } else if (id is String) {
      int? numericId = int.tryParse(id);
      if (numericId != null) {
        return await getById(numericId);
      }
    }
    throw Exception('ID inválido para cultura: $id');
  }
  
  Future<List<Crop>> getAllCropsAll() async {
    try {
      await initialize();
      final db = await database.database;
      final List<Map<String, dynamic>> maps = await db.query('crops');
      
      return List.generate(maps.length, (i) {
        return Crop.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar todas as culturas: $e');
      return [];
    }
  }
  
  Future<int> insertCrop(Crop crop) async {
    try {
      Logger.info('💾 Inserindo cultura: ${crop.name}');
      await initialize();
      final result = await _cropDao.insert(crop);
      Logger.info('✅ Cultura inserida com sucesso: ${crop.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao inserir cultura: $e');
      return -1;
    }
  }
  
  Future<int> updateCrop(Crop crop) async {
    try {
      Logger.info('🔄 Atualizando cultura: ${crop.name}');
      await initialize();
      final result = await _cropDao.update(crop);
      Logger.info('✅ Cultura atualizada com sucesso: ${crop.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar cultura: $e');
      return 0;
    }
  }
  
  Future<int> deleteCrop(int id) async {
    try {
      Logger.info('🗑️ Excluindo cultura: $id');
      await initialize();
      final result = await _cropDao.delete(id);
      Logger.info('✅ Cultura excluída com sucesso: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao excluir cultura: $e');
      return 0;
    }
  }
  
  // Métodos para pragas
  Future<List<Pest>> getAllPests() async {
    try {
      Logger.info('🔄 Carregando todas as pragas...');
      await initialize();
      final pests = await _pestDao.getAllPests();
      Logger.info('✅ ${pests.length} pragas carregadas');
      return pests;
    } catch (e) {
      Logger.error('❌ Erro ao carregar pragas: $e');
      return [];
    }
  }
  
  Future<List<Pest>> getPestsByCropId(dynamic cropId) async {
    try {
      await initialize();
      return await _pestDao.getPestsByCropId(cropId);
    } catch (e) {
      Logger.error('❌ Erro ao obter pragas por cultura: $e');
      return [];
    }
  }
  
  Future<Pest> getPestById(dynamic id) async {
    try {
      await initialize();
      if (id is int) {
        final pest = await _pestDao.getPestById(id);
        if (pest == null) throw Exception('Praga não encontrada: $id');
        return pest;
      } else if (id is String) {
        int? numericId = int.tryParse(id);
        if (numericId != null) {
          final pest = await _pestDao.getPestById(numericId);
          if (pest == null) throw Exception('Praga não encontrada: $id');
          return pest;
        }
      }
      throw Exception('ID inválido para praga: $id');
    } catch (e) {
      Logger.error('❌ Erro ao obter praga por ID: $e');
      throw Exception('Erro ao obter praga por ID: $e');
    }
  }
  
  Future<List<Pest>> getAllPestsAll() async {
    try {
      await initialize();
      final db = await _pestDao.database;
      final List<Map<String, dynamic>> maps = await db.query('pests');
      
      return List.generate(maps.length, (i) {
        return Pest.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar todas as pragas: $e');
      return [];
    }
  }
  
  Future<int> insertPest(Pest pest) async {
    try {
      Logger.info('💾 Inserindo praga: ${pest.name}');
      Logger.info('📋 Dados da praga: ${pest.toMap()}');
      
      // Verificar se os dados são válidos
      if (pest.name.isEmpty) {
        Logger.error('❌ Erro: Nome da praga está vazio');
        return -1;
      }
      
      if (pest.cropId <= 0) {
        Logger.error('❌ Erro: cropId da praga é inválido');
        return -1;
      }
      
      await initialize();
      Logger.info('✅ Repositório inicializado');
      
      final db = await database.database;
      
      // Verificar se a tabela existe
      try {
        final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'pests']);
        Logger.info('📊 Tabela pests existe: ${tables.isNotEmpty}');
        
        if (tables.isEmpty) {
          Logger.error('❌ Tabela pests não existe');
          return -1;
        }
      } catch (e) {
        Logger.error('❌ Erro ao verificar tabela pests: $e');
        return -1;
      }
      
      // Verificar se a cultura existe
      try {
        final crops = await db.query('crops', where: 'id = ?', whereArgs: [pest.cropId]);
        if (crops.isEmpty) {
          Logger.warning('⚠️ Cultura ${pest.cropId} não encontrada, criando cultura padrão...');
          
          // Criar cultura padrão
          await db.insert('crops', {
            'id': pest.cropId,
            'name': 'Cultura ${pest.cropId}',
            'scientific_name': 'Cultura ${pest.cropId}',
            'description': 'Cultura criada automaticamente',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          Logger.info('✅ Cultura padrão criada');
        }
      } catch (e) {
        Logger.error('❌ Erro ao verificar/criar cultura: $e');
        return -1;
      }
      
      final result = await _pestDao.insertPest(pest);
      Logger.info('💾 Resultado da inserção: $result');
      
      if (result > 0) {
        Logger.info('✅ Praga inserida com sucesso: ${pest.name} (ID: $result)');
      } else {
        Logger.error('❌ Falha na inserção da praga: ${pest.name} (ID: $result)');
      }
      
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao inserir praga: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return -1;
    }
  }
  
  Future<int> updatePest(Pest pest) async {
    try {
      Logger.info('🔄 Atualizando praga: ${pest.name}');
      await initialize();
      final result = await _pestDao.updatePest(pest);
      Logger.info('✅ Praga atualizada com sucesso: ${pest.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar praga: $e');
      return 0;
    }
  }
  
  Future<int> deletePest(int id) async {
    try {
      Logger.info('🗑️ Excluindo praga: $id');
      await initialize();
      final result = await _pestDao.deletePest(id);
      Logger.info('✅ Praga excluída com sucesso: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao excluir praga: $e');
      return 0;
    }
  }
  
  // Métodos para doenças
  Future<List<Disease>> getAllDiseases() async {
    try {
      Logger.info('🔄 Carregando todas as doenças...');
      await initialize();
      final diseases = await _diseaseDao.getAllDiseases();
      Logger.info('✅ ${diseases.length} doenças carregadas');
      return diseases;
    } catch (e) {
      Logger.error('❌ Erro ao carregar doenças: $e');
      return [];
    }
  }
  
  Future<List<Disease>> getDiseasesByCropId(dynamic cropId) async {
    try {
      await initialize();
      return await _diseaseDao.getDiseasesByCropId(cropId);
    } catch (e) {
      Logger.error('❌ Erro ao obter doenças por cultura: $e');
      return [];
    }
  }
  
  Future<Disease> getDiseaseById(dynamic id) async {
    try {
      await initialize();
      if (id is int) {
        final disease = await _diseaseDao.getDiseaseById(id);
        if (disease == null) throw Exception('Doença não encontrada: $id');
        return disease;
      } else if (id is String) {
        int? numericId = int.tryParse(id);
        if (numericId != null) {
          final disease = await _diseaseDao.getDiseaseById(numericId);
          if (disease == null) throw Exception('Doença não encontrada: $id');
          return disease;
        }
      }
      throw Exception('ID inválido para doença: $id');
    } catch (e) {
      Logger.error('❌ Erro ao obter doença por ID: $e');
      throw Exception('Erro ao obter doença por ID: $e');
    }
  }
  
  Future<List<Disease>> getAllDiseasesAll() async {
    try {
      await initialize();
      final db = await database.database;
      final List<Map<String, dynamic>> maps = await db.query('diseases');
      
      return List.generate(maps.length, (i) {
        return Disease.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar todas as doenças: $e');
      return [];
    }
  }
  
  Future<int> insertDisease(Disease disease) async {
    try {
      Logger.info('💾 Inserindo doença: ${disease.name}');
      Logger.info('📋 Dados da doença: ${disease.toMap()}');
      
      // Verificar se os dados são válidos
      if (disease.name.isEmpty) {
        Logger.error('❌ Erro: Nome da doença está vazio');
        return -1;
      }
      
      if (disease.cropId <= 0) {
        Logger.error('❌ Erro: cropId da doença é inválido');
        return -1;
      }
      
      await initialize();
      Logger.info('✅ Repositório inicializado');
      
      // Verificar se a tabela existe
      try {
        final db = await database.database;
        final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'diseases']);
        Logger.info('📊 Tabela diseases existe: ${tables.isNotEmpty}');
        
        if (tables.isEmpty) {
          Logger.error('❌ Tabela diseases não existe');
          return -1;
        }
      } catch (e) {
        Logger.error('❌ Erro ao verificar tabela diseases: $e');
        return -1;
      }
      
      final result = await _diseaseDao.insertDisease(disease);
      Logger.info('💾 Resultado da inserção: $result');
      
      if (result > 0) {
        Logger.info('✅ Doença inserida com sucesso: ${disease.name} (ID: $result)');
      } else {
        Logger.error('❌ Falha na inserção da doença: ${disease.name} (ID: $result)');
      }
      
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao inserir doença: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return -1;
    }
  }
  
  Future<int> updateDisease(Disease disease) async {
    try {
      Logger.info('🔄 Atualizando doença: ${disease.name}');
      await initialize();
      final result = await _diseaseDao.updateDisease(disease);
      Logger.info('✅ Doença atualizada com sucesso: ${disease.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar doença: $e');
      return 0;
    }
  }
  
  Future<int> deleteDisease(int id) async {
    try {
      Logger.info('🗑️ Excluindo doença: $id');
      await initialize();
      final result = await _diseaseDao.deleteDisease(id);
      Logger.info('✅ Doença excluída com sucesso: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao excluir doença: $e');
      return 0;
    }
  }
  
  // Métodos para plantas daninhas
  Future<List<Weed>> getAllWeeds() async {
    try {
      Logger.info('🔄 Carregando todas as plantas daninhas...');
      await initialize();
      final weeds = await _weedDao.getAllWeeds();
      Logger.info('✅ ${weeds.length} plantas daninhas carregadas');
      return weeds;
    } catch (e) {
      Logger.error('❌ Erro ao carregar plantas daninhas: $e');
      return [];
    }
  }
  
  Future<List<Weed>> getWeedsByCropId(dynamic cropId) async {
    try {
      await initialize();
      return await _weedDao.getWeedsByCropId(cropId);
    } catch (e) {
      Logger.error('❌ Erro ao obter plantas daninhas por cultura: $e');
      return [];
    }
  }
  
  Future<Weed> getWeedById(dynamic id) async {
    try {
      await initialize();
      if (id is int) {
        final weed = await _weedDao.getWeedById(id);
        if (weed == null) throw Exception('Planta daninha não encontrada: $id');
        return weed;
      } else if (id is String) {
        int? numericId = int.tryParse(id);
        if (numericId != null) {
          final weed = await _weedDao.getWeedById(numericId);
          if (weed == null) throw Exception('Planta daninha não encontrada: $id');
          return weed;
        }
      }
      throw Exception('ID inválido para planta daninha: $id');
    } catch (e) {
      Logger.error('❌ Erro ao obter planta daninha por ID: $e');
      throw Exception('Erro ao obter planta daninha por ID: $e');
    }
  }
  
  Future<List<Weed>> getAllWeedsAll() async {
    try {
      await initialize();
      final db = await database.database;
      final List<Map<String, dynamic>> maps = await db.query('weeds');
      
      return List.generate(maps.length, (i) {
        return Weed.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar todas as plantas daninhas: $e');
      return [];
    }
  }
  
  Future<int> insertWeed(Weed weed) async {
    try {
      Logger.info('💾 Inserindo planta daninha: ${weed.name}');
      Logger.info('📋 Dados da planta daninha: ${weed.toMap()}');
      
      // Verificar se os dados são válidos
      if (weed.name.isEmpty) {
        Logger.error('❌ Erro: Nome da planta daninha está vazio');
        return -1;
      }
      
      if (weed.cropId <= 0) {
        Logger.error('❌ Erro: cropId da planta daninha é inválido');
        return -1;
      }
      
      await initialize();
      Logger.info('✅ Repositório inicializado');
      
      // Verificar se a tabela existe e se a cultura existe
      try {
        final db = await database.database;
        final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'weeds']);
        Logger.info('📊 Tabela weeds existe: ${tables.isNotEmpty}');
        
        if (tables.isEmpty) {
          Logger.error('❌ Tabela weeds não existe');
          return -1;
        }
        
        // Verificar se a cultura existe
        final crops = await db.query('crops', where: 'id = ?', whereArgs: [weed.cropId]);
        if (crops.isEmpty) {
          Logger.warning('⚠️ Cultura ${weed.cropId} não encontrada, criando cultura padrão...');
          
          // Criar cultura padrão
          await db.insert('crops', {
            'id': weed.cropId,
            'name': 'Cultura ${weed.cropId}',
            'scientific_name': 'Cultura ${weed.cropId}',
            'description': 'Cultura criada automaticamente',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          Logger.info('✅ Cultura padrão criada');
        }
      } catch (e) {
        Logger.error('❌ Erro ao verificar tabela/cultura: $e');
        return -1;
      }
      
      final result = await _weedDao.insertWeed(weed);
      Logger.info('💾 Resultado da inserção: $result');
      
      if (result > 0) {
        Logger.info('✅ Planta daninha inserida com sucesso: ${weed.name} (ID: $result)');
      } else {
        Logger.error('❌ Falha na inserção da planta daninha: ${weed.name} (ID: $result)');
      }
      
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao inserir planta daninha: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return -1;
    }
  }

  Future<int> updateWeed(Weed weed) async {
    try {
      Logger.info('🔄 Atualizando planta daninha: ${weed.name}');
      await initialize();
      final result = await _weedDao.updateWeed(weed);
      Logger.info('✅ Planta daninha atualizada com sucesso: ${weed.name}');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar planta daninha: $e');
      return 0;
    }
  }

  Future<int> deleteWeed(dynamic id) async {
    try {
      Logger.info('🗑️ Deletando planta daninha ID: $id');
      await initialize();
      final result = await _weedDao.deleteWeed(id);
      Logger.info('✅ Planta daninha deletada com sucesso ID: $id');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao deletar planta daninha: $e');
      return 0;
    }
  }
  
  // Métodos de sincronização
  Future<void> syncCrops(String serverUrl, String apiKey, int userId) async {
    try {
      // Obter culturas não sincronizadas
      final unsyncedCrops = await _cropDao.getUnsyncedCrops();
      
      if (unsyncedCrops.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$serverUrl/api/crops/sync'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
          body: jsonEncode({
            'userId': userId,
            'crops': unsyncedCrops.map((crop) => crop.toJson()).toList(),
          }),
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          // Atualizar status de sincronização
          for (var crop in unsyncedCrops) {
            await _cropDao.update(crop.copyWith(syncStatus: 1));
          }
          
          // Inserir ou atualizar culturas do servidor
          if (data.containsKey('crops')) {
            final List<dynamic> serverCrops = data['crops'];
            for (var cropData in serverCrops) {
              final crop = Crop.fromJson(cropData);
              final existingCrop = await _cropDao.getCropById(crop.id);
              
              if (existingCrop != null) {
                await _cropDao.update(crop);
              } else {
                await _cropDao.insert(crop);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao sincronizar culturas: $e');
      rethrow;
    }
  }
  
  Future<void> syncPests(String serverUrl, String apiKey, int userId) async {
    try {
      // Obter pragas não sincronizadas
      final unsyncedPests = await _pestDao.getUnsyncedPests();
      
      if (unsyncedPests.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$serverUrl/api/pests/sync'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
          body: jsonEncode({
            'userId': userId,
            'pests': unsyncedPests.map((pest) => pest.toJson()).toList(),
          }),
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          // Atualizar status de sincronização
          for (var pest in unsyncedPests) {
            await _pestDao.updatePest(pest.copyWith(syncStatus: 1));
          }
          
          // Inserir ou atualizar pragas do servidor
          if (data.containsKey('pests')) {
            final List<dynamic> serverPests = data['pests'];
            for (var pestData in serverPests) {
              final pest = Pest.fromJson(pestData);
              final existingPest = await _pestDao.getPestById(pest.id);
              
              if (existingPest != null) {
                await _pestDao.updatePest(pest);
              } else {
                await _pestDao.insertPest(pest);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao sincronizar pragas: $e');
      rethrow;
    }
  }
  
  Future<void> syncDiseases(String serverUrl, String apiKey, int userId) async {
    try {
      // Obter doenças não sincronizadas
      final unsyncedDiseases = await _diseaseDao.getUnsyncedDiseases();
      
      if (unsyncedDiseases.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$serverUrl/api/diseases/sync'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
          body: jsonEncode({
            'userId': userId,
            'diseases': unsyncedDiseases.map((disease) => disease.toJson()).toList(),
          }),
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          // Atualizar status de sincronização
          for (var disease in unsyncedDiseases) {
            await _diseaseDao.updateDisease(disease.copyWith(syncStatus: 1));
          }
          
          // Inserir ou atualizar doenças do servidor
          if (data.containsKey('diseases')) {
            final List<dynamic> serverDiseases = data['diseases'];
            for (var diseaseData in serverDiseases) {
              final disease = Disease.fromJson(diseaseData);
              final existingDisease = await _diseaseDao.getDiseaseById(disease.id);
              
              if (existingDisease != null) {
                await _diseaseDao.updateDisease(disease);
              } else {
                await _diseaseDao.insertDisease(disease);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao sincronizar doenças: $e');
      rethrow;
    }
  }
  
  Future<void> syncWeeds(String serverUrl, String apiKey, int userId) async {
    try {
      // Obter plantas daninhas não sincronizadas
      final unsyncedWeeds = await _weedDao.getUnsyncedWeeds();
      
      if (unsyncedWeeds.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$serverUrl/api/weeds/sync'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
          body: jsonEncode({
            'userId': userId,
            'weeds': unsyncedWeeds.map((weed) => weed.toJson()).toList(),
          }),
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          // Atualizar status de sincronização
          for (var weed in unsyncedWeeds) {
            await _weedDao.updateWeed(weed.copyWith(syncStatus: 1));
          }
          
          // Inserir ou atualizar plantas daninhas do servidor
          if (data.containsKey('weeds')) {
            final List<dynamic> serverWeeds = data['weeds'];
            for (var weedData in serverWeeds) {
              final weed = Weed.fromJson(weedData);
              final existingWeed = await _weedDao.getWeedById(weed.id);
              
              if (existingWeed != null) {
                await _weedDao.updateWeed(weed);
              } else {
                await _weedDao.insertWeed(weed);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao sincronizar plantas daninhas: $e');
      rethrow;
    }
  }
  
  // Método para sincronizar todos os dados
  Future<void> syncAll(String serverUrl, String apiKey, int userId) async {
    await syncCrops(serverUrl, apiKey, userId);
    await syncPests(serverUrl, apiKey, userId);
    await syncDiseases(serverUrl, apiKey, userId);
    await syncWeeds(serverUrl, apiKey, userId);
  }

  /// Insere culturas padrão
  Future<void> _insertDefaultCrops() async {
    try {
      final db = await database.database;
      
      final defaultCrops = [
        {
          'name': 'Soja',
          'scientific_name': 'Glycine max',
          'family': 'Fabaceae',
          'description': 'Cultura principal do Brasil',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Milho',
          'scientific_name': 'Zea mays',
          'family': 'Poaceae',
          'description': 'Cultura de grãos importante',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Algodão',
          'scientific_name': 'Gossypium hirsutum',
          'family': 'Malvaceae',
          'description': 'Cultura de fibra',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Feijão',
          'scientific_name': 'Phaseolus vulgaris',
          'family': 'Fabaceae',
          'description': 'Cultura de grãos',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Girassol',
          'scientific_name': 'Helianthus annuus',
          'family': 'Asteraceae',
          'description': 'Cultura oleaginosa',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];
      
      for (final crop in defaultCrops) {
        await db.insert('crops', crop);
      }
      
      Logger.info('✅ Culturas padrão inseridas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inserir culturas padrão: $e');
    }
  }
  
  /// Insere pragas padrão
  Future<void> _insertDefaultPests() async {
    try {
      final db = await database.database;
      
      // Obter IDs das culturas
      final crops = await db.query('crops');
      final cropIds = <String, int>{};
      for (final crop in crops) {
        cropIds[crop['name'] as String] = crop['id'] as int;
      }
      
      final defaultPests = [
        // Pragas da Soja
        {
          'name': 'Lagarta-da-soja',
          'scientific_name': 'Anticarsia gemmatalis',
          'description': 'Praga importante da soja',
          'crop_id': cropIds['Soja'] ?? 1,
        },
        {
          'name': 'Percevejo-marrom',
          'scientific_name': 'Euschistus heros',
          'description': 'Percevejo que ataca a soja',
          'crop_id': cropIds['Soja'] ?? 1,
        },
        {
          'name': 'Falsa-medideira',
          'scientific_name': 'Chrysodeixis includens',
          'description': 'Lagarta que ataca folhas da soja',
          'crop_id': cropIds['Soja'] ?? 1,
        },
        
        // Pragas do Milho
        {
          'name': 'Lagarta-do-cartucho',
          'scientific_name': 'Spodoptera frugiperda',
          'description': 'Principal praga do milho',
          'crop_id': cropIds['Milho'] ?? 2,
        },
        {
          'name': 'Larva-alfinete',
          'scientific_name': 'Diabrotica speciosa',
          'description': 'Larva que ataca raízes do milho',
          'crop_id': cropIds['Milho'] ?? 2,
        },
        
        // Pragas do Algodão
        {
          'name': 'Helicoverpa',
          'scientific_name': 'Helicoverpa armigera',
          'description': 'Praga polífaga importante',
          'crop_id': cropIds['Algodão'] ?? 3,
        },
        {
          'name': 'Bicudo-do-algodoeiro',
          'scientific_name': 'Anthonomus grandis',
          'description': 'Praga específica do algodão',
          'crop_id': cropIds['Algodão'] ?? 3,
        },
      ];
      
      for (final pest in defaultPests) {
        await db.insert('pests', pest);
      }
      
      Logger.info('✅ Pragas padrão inseridas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inserir pragas padrão: $e');
    }
  }


}
