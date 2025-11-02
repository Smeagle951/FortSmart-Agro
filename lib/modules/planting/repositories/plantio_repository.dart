import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';

/// Repositório para operações CRUD relacionadas ao plantio
class PlantioRepository {
  static final PlantioRepository _instance = PlantioRepository._internal();
  
  factory PlantioRepository() {
    return _instance;
  }
  
  PlantioRepository._internal();
  
  final String _tableName = 'plantio';
  
  /// Insere um novo registro de plantio no banco de dados
  Future<int> inserir(PlantioModel plantio) async {
    try {
      final db = await AppDatabase().database;
      return await db.insert(_tableName, plantio.toMap());
    } catch (e) {
      debugPrint('Erro ao inserir plantio: $e');
      return -1;
    }
  }
  
  /// Atualiza um registro de plantio existente
  Future<int> atualizar(PlantioModel plantio) async {
    try {
      final db = await AppDatabase().database;
      return await db.update(
        _tableName,
        plantio.toMap(),
        where: 'id = ?',
        whereArgs: [plantio.id],
      );
    } catch (e) {
      debugPrint('Erro ao atualizar plantio: $e');
      return -1;
    }
  }
  
  /// Exclui um registro de plantio
  Future<int> excluir(String id) async {
    try {
      final db = await AppDatabase().database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Erro ao excluir plantio: $e');
      return -1;
    }
  }
  
  /// Obtém um registro de plantio pelo ID
  Future<PlantioModel?> obterPorId(String id) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return PlantioModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter plantio por ID: $e');
      return null;
    }
  }
  
  /// Lista todos os registros de plantio
  Future<List<PlantioModel>> listar() async {
    try {
      print('🔍 PlantioRepository.listar() - Iniciando busca...');
      final db = await AppDatabase().database;
      print('✅ PlantioRepository.listar() - Banco obtido');
      
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      print('📋 PlantioRepository.listar() - ${maps.length} registros encontrados na tabela $_tableName');
      
      if (maps.isNotEmpty) {
        print('🔍 PlantioRepository.listar() - Primeiro registro: ${maps.first}');
      }
      
      final plantios = <PlantioModel>[];
      
      for (var map in maps) {
        try {
          // Adaptador para compatibilidade entre diferentes estruturas de dados
          final adaptedMap = _adaptarEstruturaDados(map);
          final plantio = PlantioModel.fromMap(adaptedMap);
          plantios.add(plantio);
        } catch (e) {
          print('⚠️ Erro ao processar registro ${map['id']}: $e');
          // Continua processando outros registros
        }
      }
      
      print('✅ PlantioRepository.listar() - ${plantios.length} objetos PlantioModel criados');
      return plantios;
    } catch (e, stackTrace) {
      print('❌ PlantioRepository.listar() - Erro: $e');
      print('Stack trace: $stackTrace');
      debugPrint('Erro ao listar plantios: $e');
      return [];
    }
  }
  
  /// Adapta estrutura de dados para compatibilidade entre modelos diferentes
  Map<String, dynamic> _adaptarEstruturaDados(Map<String, dynamic> originalMap) {
    final adaptedMap = Map<String, dynamic>.from(originalMap);
    
    print('🔍 Adaptador: Dados originais: ${originalMap.keys.join(', ')}');
    
    // Converter estrutura do modelo antigo (submódulo "Novo Plantio") 
    // para o modelo novo (módulo principal)
    
    // Mapear campos de cultura
    if (adaptedMap.containsKey('cultura') && !adaptedMap.containsKey('culturaId')) {
      adaptedMap['culturaId'] = adaptedMap['cultura'] ?? '';
      print('🔄 Mapeamento: cultura -> culturaId = ${adaptedMap['culturaId']}');
    }
    
    // Mapear campos de variedade  
    if (adaptedMap.containsKey('variedade') && !adaptedMap.containsKey('variedadeId')) {
      adaptedMap['variedadeId'] = adaptedMap['variedade'] ?? '';
      print('🔄 Mapeamento: variedade -> variedadeId = ${adaptedMap['variedadeId']}');
    }
    
    // Mapear campos de datas
    if (adaptedMap.containsKey('data_plantio') && !adaptedMap.containsKey('dataPlantio')) {
      adaptedMap['dataPlantio'] = adaptedMap['data_plantio'];
      print('🔄 Mapeamento: data_plantio -> dataPlantio = ${adaptedMap['dataPlantio']}');
    }
    
    // Mapear campos de IDs  
    if (adaptedMap.containsKey('talhao_id') && !adaptedMap.containsKey('talhaoId')) {
      adaptedMap['talhaoId'] = adaptedMap['talhao_id'];
      print('🔄 Mapeamento: talhao_id -> talhaoId = ${adaptedMap['talhaoId']}');
    }
    
    // Mapear campos de espaçamento
    if (adaptedMap.containsKey('espacamento_cm') && !adaptedMap.containsKey('espacamento')) {
      adaptedMap['espacamento'] = adaptedMap['espacamento_cm'] ?? 0.0;
      print('🔄 Mapeamento: espacamento_cm -> espacamento = ${adaptedMap['espacamento']}');
    }
    
    // Mapear campos de população
    if (adaptedMap.containsKey('populacao_por_m') && !adaptedMap.containsKey('populacao')) {
      adaptedMap['populacao'] = (adaptedMap['populacao_por_m'] ?? 0.0).toInt();
      print('🔄 Mapeamento: populacao_por_m -> populacao = ${adaptedMap['populacao']}');
    }
    
    // Mapear campos de datas (criação/atualização)
    if (adaptedMap.containsKey('created_at') && !adaptedMap.containsKey('criadoEm')) {
      adaptedMap['criadoEm'] = adaptedMap['created_at'];
      print('🔄 Mapeamento: created_at -> criadoEm = ${adaptedMap['criadoEm']}');
    }
    
    if (adaptedMap.containsKey('updated_at') && !adaptedMap.containsKey('atualizadoEm')) {
      adaptedMap['atualizadoEm'] = adaptedMap['updated_at'];
      print('🔄 Mapeamento: updated_at -> atualizadoEm = ${adaptedMap['atualizadoEm']}');
    }
    
    // Campos obrigatórios com valores padrão
    if (!adaptedMap.containsKey('profundidade')) {
      adaptedMap['profundidade'] = 3.0; // Valor padrão
      print('🔄 Adicionando campo padrão: profundidade = 3.0');
    }
    
    if (!adaptedMap.containsKey('maquinasIds')) {
      adaptedMap['maquinasIds'] = []; // Lista vazia
      print('🔄 Adicionando campo padrão: maquinasIds = []');
    }
    
    // Campos obrigatórios adicionais para evitar erros
    if (!adaptedMap.containsKey('sincronizado')) {
      adaptedMap['sincronizado'] = false;
    }
    
    print('🔄 Dados adaptados finais: ${adaptedMap.keys.join(', ')}');
    return adaptedMap;
  }
  
  /// Lista plantios por talhão
  Future<List<PlantioModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
      );
      
      return List.generate(maps.length, (i) {
        return PlantioModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar plantios por talhão: $e');
      return [];
    }
  }
  
  /// Lista plantios por cultura
  Future<List<PlantioModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'culturaId = ?',
        whereArgs: [culturaId],
      );
      
      return List.generate(maps.length, (i) {
        return PlantioModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar plantios por cultura: $e');
      return [];
    }
  }
  
  /// Alias para manter compatibilidade
  Future<PlantioModel?> getById(String id) async {
    return await obterPorId(id);
  }

  /// Método getAll para compatibilidade com o DataCacheService
  /// Retorna todos os registros de plantio
  Future<List<PlantioModel>> getAll() async {
    try {
      return await listar();
    } catch (e) {
      debugPrint('Erro ao obter todos os plantios (getAll): $e');
      return [];
    }
  }
}
