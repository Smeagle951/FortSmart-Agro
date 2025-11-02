import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../services/organism_catalog_loader_service.dart';

/// Repositório para gerenciar o catálogo de organismos
class OrganismCatalogRepository {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogLoaderService _loaderService = OrganismCatalogLoaderService();
  final String tableName = 'organism_catalog';

  /// Inicializa a tabela no banco de dados
  Future<void> initialize() async {
    final db = await _database.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT,
        type TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        low_limit INTEGER NOT NULL,
        medium_limit INTEGER NOT NULL,
        high_limit INTEGER NOT NULL,
        description TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  /// Cria um novo organismo no catálogo
  Future<String> create(OrganismCatalog organism) async {
    final db = await _database.database;
    
    await db.insert(
      tableName,
      organism.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return organism.id;
  }

  /// Atualiza um organismo existente
  Future<void> update(OrganismCatalog organism) async {
    final db = await _database.database;
    
    await db.update(
      tableName,
      organism.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [organism.id],
    );
  }

  /// Exclui um organismo
  Future<void> delete(String id) async {
    final db = await _database.database;
    
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém um organismo pelo ID
  Future<OrganismCatalog?> getById(String id) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return OrganismCatalog.fromMap(maps.first);
  }

  /// Obtém todos os organismos
  Future<List<OrganismCatalog>> getAll() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos por tipo
  Future<List<OrganismCatalog>> getByType(OccurrenceType type) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'type = ? AND is_active = 1',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos por cultura
  Future<List<OrganismCatalog>> getByCrop(String cropId) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'crop_id = ? AND is_active = 1',
      whereArgs: [cropId],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos por cultura e tipo
  Future<List<OrganismCatalog>> getByCropAndType(String cropId, OccurrenceType type) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'crop_id = ? AND type = ? AND is_active = 1',
      whereArgs: [cropId, type.toString().split('.').last],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Busca organismos por nome
  Future<List<OrganismCatalog>> searchByName(String name) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name LIKE ? AND is_active = 1',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Insere dados padrão do catálogo
  Future<void> insertDefaultData() async {
    try {
      // Primeiro, garantir que as culturas existam
      await _ensureCropsExist();
      
      // Carregar organismos dos arquivos JSON
      final organisms = await _loaderService.loadAllOrganisms();
      
      if (organisms.isEmpty) {
        Logger.warning('⚠️ Nenhum organismo encontrado nos arquivos JSON');
        return;
      }
      
      // Inserir organismos no banco de dados
      for (var organism in organisms) {
        await create(organism);
      }
      
      Logger.info('✅ Inseridos ${organisms.length} organismos no catálogo');
      
    } catch (e) {
      Logger.error('❌ Erro ao inserir dados padrão: $e');
      // Fallback para dados básicos se necessário
      await _insertBasicData();
    }
  }
  
  /// Insere dados básicos como fallback
  Future<void> _insertBasicData() async {
    final defaultOrganisms = [
      // Pragas da Soja (ID: 2)
      OrganismCatalog(
        name: 'Percevejo Marrom',
        scientificName: 'Euschistus heros',
        type: OccurrenceType.pest,
        cropId: '2',
        cropName: 'Soja',
        unit: 'indivíduos/ponto',
        lowLimit: 2,
        mediumLimit: 6,
        highLimit: 10,
        description: 'Praga sugadora que causa danos diretos e indiretos na soja',
      ),
      OrganismCatalog(
        name: 'Lagarta Spodoptera',
        scientificName: 'Spodoptera frugiperda',
        type: OccurrenceType.pest,
        cropId: '2',
        cropName: 'Soja',
        unit: 'indivíduos/ponto',
        lowLimit: 1,
        mediumLimit: 3,
        highLimit: 5,
        description: 'Lagarta desfolhadora que pode causar danos severos',
      ),
      OrganismCatalog(
        name: 'Lagarta Helicoverpa',
        scientificName: 'Helicoverpa armigera',
        type: OccurrenceType.pest,
        cropId: '2',
        cropName: 'Soja',
        unit: 'indivíduos/ponto',
        lowLimit: 1,
        mediumLimit: 2,
        highLimit: 4,
        description: 'Lagarta polífaga que ataca vagens e grãos',
      ),
      
      // Doenças da Soja (ID: 2)
      OrganismCatalog(
        name: 'Ferrugem Asiática',
        scientificName: 'Phakopsora pachyrhizi',
        type: OccurrenceType.disease,
        cropId: '2',
        cropName: 'Soja',
        unit: '% folhas afetadas',
        lowLimit: 5,
        mediumLimit: 15,
        highLimit: 30,
        description: 'Doença fúngica que pode causar perdas de até 80%',
      ),
      OrganismCatalog(
        name: 'Mancha Parda',
        scientificName: 'Septoria glycines',
        type: OccurrenceType.disease,
        cropId: '2',
        cropName: 'Soja',
        unit: '% folhas afetadas',
        lowLimit: 10,
        mediumLimit: 25,
        highLimit: 50,
        description: 'Doença fúngica que afeta folhas e vagens',
      ),
      
      // Plantas Daninhas da Soja (ID: 2)
      OrganismCatalog(
        name: 'Buva',
        scientificName: 'Conyza spp.',
        type: OccurrenceType.weed,
        cropId: '2',
        cropName: 'Soja',
        unit: 'plantas/m²',
        lowLimit: 2,
        mediumLimit: 5,
        highLimit: 10,
        description: 'Planta daninha resistente a herbicidas',
      ),
      OrganismCatalog(
        name: 'Capim Amargoso',
        scientificName: 'Digitaria insularis',
        type: OccurrenceType.weed,
        cropId: '2',
        cropName: 'Soja',
        unit: 'plantas/m²',
        lowLimit: 1,
        mediumLimit: 3,
        highLimit: 6,
        description: 'Planta daninha de difícil controle',
      ),
      
      // Pragas do Milho (ID: 3)
      OrganismCatalog(
        name: 'Lagarta do Cartucho',
        scientificName: 'Spodoptera frugiperda',
        type: OccurrenceType.pest,
        cropId: '3',
        cropName: 'Milho',
        unit: 'indivíduos/ponto',
        lowLimit: 1,
        mediumLimit: 2,
        highLimit: 4,
        description: 'Principal praga do milho',
      ),
      OrganismCatalog(
        name: 'Cigarrinha do Milho',
        scientificName: 'Dalbulus maidis',
        type: OccurrenceType.pest,
        cropId: '3',
        cropName: 'Milho',
        unit: 'indivíduos/ponto',
        lowLimit: 3,
        mediumLimit: 8,
        highLimit: 15,
        description: 'Vetor de doenças virais',
      ),
      
      // Doenças do Milho (ID: 3)
      OrganismCatalog(
        name: 'Ferrugem Comum',
        scientificName: 'Puccinia sorghi',
        type: OccurrenceType.disease,
        cropId: '3',
        cropName: 'Milho',
        unit: '% folhas afetadas',
        lowLimit: 10,
        mediumLimit: 25,
        highLimit: 50,
        description: 'Doença fúngica que afeta folhas',
      ),
      OrganismCatalog(
        name: 'Mancha Branca',
        scientificName: 'Phaeosphaeria maydis',
        type: OccurrenceType.disease,
        cropId: '3',
        cropName: 'Milho',
        unit: '% folhas afetadas',
        lowLimit: 5,
        mediumLimit: 15,
        highLimit: 30,
        description: 'Doença fúngica que pode reduzir produtividade',
      ),
      
      // Plantas Daninhas do Milho (ID: 3)
      OrganismCatalog(
        name: 'Capim Colchão',
        scientificName: 'Digitaria horizontalis',
        type: OccurrenceType.weed,
        cropId: '3',
        cropName: 'Milho',
        unit: 'plantas/m²',
        lowLimit: 3,
        mediumLimit: 8,
        highLimit: 15,
        description: 'Planta daninha comum em lavouras de milho',
      ),
      OrganismCatalog(
        name: 'Caruru',
        scientificName: 'Amaranthus spp.',
        type: OccurrenceType.weed,
        cropId: '3',
        cropName: 'Milho',
        unit: 'plantas/m²',
        lowLimit: 2,
        mediumLimit: 5,
        highLimit: 10,
        description: 'Planta daninha de crescimento rápido',
      ),
    ];

    final db = await _database.database;
    
    for (final organism in defaultOrganisms) {
      try {
        await db.insert(
          tableName,
          organism.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('Erro ao inserir organismo ${organism.name}: $e');
      }
    }
  }

  /// Verifica se o catálogo está vazio
  Future<bool> isEmpty() async {
    final db = await _database.database;
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    );
    
    return count == 0;
  }

  /// Obtém estatísticas do catálogo
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _database.database;
    
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE is_active = 1')
    ) ?? 0;
    
    final pestsCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE type = ? AND is_active = 1',
        ['pest']
      )
    ) ?? 0;
    
    final diseasesCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE type = ? AND is_active = 1',
        ['disease']
      )
    ) ?? 0;
    
    final weedsCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE type = ? AND is_active = 1',
        ['weed']
      )
    ) ?? 0;
    
    final cropsCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(DISTINCT crop_id) FROM $tableName WHERE is_active = 1'
      )
    ) ?? 0;
    
    return {
      'total': totalCount,
      'pests': pestsCount,
      'diseases': diseasesCount,
      'weeds': weedsCount,
      'crops': cropsCount,
    };
  }

  /// Obtém organismos por cultura
  Future<Map<String, List<OrganismCatalog>>> getByCrops() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'crop_name ASC, name ASC',
    );
    
    final Map<String, List<OrganismCatalog>> result = {};
    
    for (final map in maps) {
      final organism = OrganismCatalog.fromMap(map);
      final cropName = organism.cropName;
      
      if (!result.containsKey(cropName)) {
        result[cropName] = [];
      }
      
      result[cropName]!.add(organism);
    }
    
    return result;
  }

  /// Obtém organismos por tipo e cultura
  Future<Map<String, Map<OccurrenceType, List<OrganismCatalog>>>> getByTypeAndCrops() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'crop_name ASC, type ASC, name ASC',
    );
    
    final Map<String, Map<OccurrenceType, List<OrganismCatalog>>> result = {};
    
    for (final map in maps) {
      final organism = OrganismCatalog.fromMap(map);
      final cropName = organism.cropName;
      final type = organism.type;
      
      if (!result.containsKey(cropName)) {
        result[cropName] = {};
      }
      
      if (!result[cropName]!.containsKey(type)) {
        result[cropName]![type] = [];
      }
      
      result[cropName]![type]!.add(organism);
    }
    
    return result;
  }

  /// Busca organismos por texto
  Future<List<OrganismCatalog>> search(String query) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '(name LIKE ? OR scientific_name LIKE ? OR description LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos mais utilizados
  Future<List<OrganismCatalog>> getMostUsed({int limit = 10}) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'name ASC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos por severidade
  Future<List<OrganismCatalog>> getBySeverity(String severity) async {
    final db = await _database.database;
    
    String whereClause;
    List<Object> whereArgs;
    
    switch (severity.toLowerCase()) {
      case 'low':
        whereClause = 'low_limit > 0 AND is_active = 1';
        whereArgs = [];
        break;
      case 'medium':
        whereClause = 'medium_limit > 0 AND is_active = 1';
        whereArgs = [];
        break;
      case 'high':
        whereClause = 'high_limit > 0 AND is_active = 1';
        whereArgs = [];
        break;
      default:
        return [];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém organismos por unidade de medida
  Future<List<OrganismCatalog>> getByUnit(String unit) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'unit = ? AND is_active = 1',
      whereArgs: [unit],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OrganismCatalog.fromMap(maps[i]);
    });
  }

  /// Obtém unidades de medida disponíveis
  Future<List<String>> getAvailableUnits() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT unit FROM $tableName WHERE is_active = 1 ORDER BY unit ASC'
    );
    
    return List.generate(maps.length, (i) {
      return maps[i]['unit'] as String;
    });
  }

  /// Obtém culturas disponíveis
  Future<List<String>> getAvailableCrops() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT crop_name FROM $tableName WHERE is_active = 1 ORDER BY crop_name ASC'
    );
    
    return List.generate(maps.length, (i) {
      return maps[i]['crop_name'] as String;
    });
  }

  /// Obtém tipos disponíveis
  Future<List<OccurrenceType>> getAvailableTypes() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT type FROM $tableName WHERE is_active = 1 ORDER BY type ASC'
    );
    
    return List.generate(maps.length, (i) {
      final typeString = maps[i]['type'] as String;
      switch (typeString) {
        case 'pest':
          return OccurrenceType.pest;
        case 'disease':
          return OccurrenceType.disease;
        case 'weed':
          return OccurrenceType.weed;
        default:
          return OccurrenceType.pest;
      }
    });
  }

  /// Garante que as culturas necessárias existam na tabela crops
  Future<void> _ensureCropsExist() async {
    final db = await _database.database;
    
    // Verificar se a tabela crops existe, se não, criar
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id INTEGER
      )
    ''');
    
         // Lista de culturas necessárias para o catálogo de organismos
     final requiredCrops = [
       {'id': '1', 'name': 'Soja', 'description': 'Cultura da soja'},
       {'id': '2', 'name': 'Milho', 'description': 'Cultura do milho'},
       {'id': '3', 'name': 'Trigo', 'description': 'Cultura do trigo'},
       {'id': '4', 'name': 'Feijão', 'description': 'Cultura do feijão'},
       {'id': '5', 'name': 'Algodão', 'description': 'Cultura do algodão'},
       {'id': '6', 'name': 'Sorgo', 'description': 'Cultura do sorgo'},
       {'id': '7', 'name': 'Girassol', 'description': 'Cultura do girassol'},
       {'id': '8', 'name': 'Aveia', 'description': 'Cultura da aveia'},
       {'id': '9', 'name': 'Gergelim', 'description': 'Cultura do gergelim'},
     ];
    
    // Inserir culturas se não existirem
    for (final crop in requiredCrops) {
      try {
        await db.insert(
          'crops',
          {
            'id': crop['id'],
            'name': crop['name'],
            'description': crop['description'],
            'sync_status': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        print('Erro ao inserir cultura ${crop['name']}: $e');
      }
    }
  }

  /// Obtém todos os organismos como Map<String, dynamic>
  Future<List<Map<String, dynamic>>> getAllOrganisms() async {
    final organisms = await getAll();
    return organisms.map((org) => org.toMap()).toList();
  }

  /// Obtém organismos por cultura como Map<String, dynamic>
  Future<List<Map<String, dynamic>>> getOrganismsByCrop(String cropId) async {
    final organisms = await getByCrop(cropId);
    return organisms.map((org) => org.toMap()).toList();
  }
}
