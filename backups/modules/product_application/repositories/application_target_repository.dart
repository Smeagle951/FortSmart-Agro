import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/application_target_model.dart';
import '../../../services/database_service.dart';

class ApplicationTargetRepository {
  final DatabaseService _databaseService = DatabaseService();
  final String _tableName = 'application_targets';
  
  // Inicialização da tabela
  Future<void> initTable() async {
    final db = await _databaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        scientificName TEXT,
        description TEXT,
        iconPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
    
    print('Tabela $_tableName inicializada com sucesso');
    
    // Inserir dados iniciais se a tabela estiver vazia
    await _insertInitialData();
  }
  
  // Inserir dados iniciais de pragas, doenças e plantas daninhas
  Future<void> _insertInitialData() async {
    final db = await _databaseService.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_tableName'));
    
    if (count == 0) {
      print('Inserindo dados iniciais de pragas, doenças e plantas daninhas');
      
      // Lista de pragas comuns
      final pests = [
        {'name': 'Lagarta-do-cartucho', 'type': TargetType.pest.index, 'scientificName': 'Spodoptera frugiperda'},
        {'name': 'Percevejo-marrom', 'type': TargetType.pest.index, 'scientificName': 'Euschistus heros'},
        {'name': 'Helicoverpa', 'type': TargetType.pest.index, 'scientificName': 'Helicoverpa armigera'},
        {'name': 'Bicudo-do-algodoeiro', 'type': TargetType.pest.index, 'scientificName': 'Anthonomus grandis'},
        {'name': 'Mosca-branca', 'type': TargetType.pest.index, 'scientificName': 'Bemisia tabaci'},
      ];
      
      // Lista de doenças comuns
      final diseases = [
        {'name': 'Ferrugem asiática', 'type': TargetType.disease.index, 'scientificName': 'Phakopsora pachyrhizi'},
        {'name': 'Mancha branca do milho', 'type': TargetType.disease.index, 'scientificName': 'Pantoea ananatis'},
        {'name': 'Mofo branco', 'type': TargetType.disease.index, 'scientificName': 'Sclerotinia sclerotiorum'},
        {'name': 'Antracnose', 'type': TargetType.disease.index, 'scientificName': 'Colletotrichum spp.'},
        {'name': 'Oídio', 'type': TargetType.disease.index, 'scientificName': 'Blumeria graminis'},
      ];
      
      // Lista de plantas daninhas comuns
      final weeds = [
        {'name': 'Buva', 'type': TargetType.weed.index, 'scientificName': 'Conyza spp.'},
        {'name': 'Capim-amargoso', 'type': TargetType.weed.index, 'scientificName': 'Digitaria insularis'},
        {'name': 'Caruru', 'type': TargetType.weed.index, 'scientificName': 'Amaranthus spp.'},
        {'name': 'Picão-preto', 'type': TargetType.weed.index, 'scientificName': 'Bidens pilosa'},
        {'name': 'Trapoeraba', 'type': TargetType.weed.index, 'scientificName': 'Commelina benghalensis'},
      ];
      
      final allTargets = [...pests, ...diseases, ...weeds];
      final batch = db.batch();
      
      for (var target in allTargets) {
        final model = ApplicationTargetModel(
          name: target['name'] as String,
          type: TargetType.values[target['type'] as int],
          scientificName: target['scientificName'] as String,
        );
        
        batch.insert(
          _tableName,
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      print('Dados iniciais inseridos com sucesso');
    }
  }
  
  // Inserir um novo alvo
  Future<String> insert(ApplicationTargetModel target) async {
    try {
      final db = await _databaseService.database;
      
      await db.insert(
        _tableName,
        target.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('Alvo inserido com sucesso: ${target.id}');
      return target.id;
    } catch (e) {
      print('Erro ao inserir alvo: $e');
      throw Exception('Falha ao inserir alvo: $e');
    }
  }
  
  // Atualizar um alvo existente
  Future<int> update(ApplicationTargetModel target) async {
    try {
      final db = await _databaseService.database;
      
      return await db.update(
        _tableName,
        target.toMap(),
        where: 'id = ?',
        whereArgs: [target.id],
      );
    } catch (e) {
      print('Erro ao atualizar alvo: $e');
      throw Exception('Falha ao atualizar alvo: $e');
    }
  }
  
  // Excluir um alvo
  Future<int> delete(String id) async {
    try {
      final db = await _databaseService.database;
      
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Erro ao excluir alvo: $e');
      throw Exception('Falha ao excluir alvo: $e');
    }
  }
  
  // Obter um alvo pelo ID
  Future<ApplicationTargetModel?> getById(String id) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return ApplicationTargetModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar alvo: $e');
      throw Exception('Falha ao buscar alvo: $e');
    }
  }
  
  // Listar todos os alvos
  Future<List<ApplicationTargetModel>> getAll() async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'name ASC',
      );
      
      return List.generate(maps.length, (i) {
        return ApplicationTargetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar alvos: $e');
      throw Exception('Falha ao listar alvos: $e');
    }
  }
  
  // Listar alvos por tipo (praga, doença ou planta daninha)
  Future<List<ApplicationTargetModel>> getByType(TargetType type) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'type = ?',
        whereArgs: [type.index],
        orderBy: 'name ASC',
      );
      
      return List.generate(maps.length, (i) {
        return ApplicationTargetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar alvos por tipo: $e');
      throw Exception('Falha ao listar alvos por tipo: $e');
    }
  }
  
  // Buscar alvos por nome (pesquisa parcial)
  Future<List<ApplicationTargetModel>> searchByName(String query) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      
      return List.generate(maps.length, (i) {
        return ApplicationTargetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar alvos por nome: $e');
      throw Exception('Falha ao buscar alvos por nome: $e');
    }
  }
}
