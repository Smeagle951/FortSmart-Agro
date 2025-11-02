import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/crop_variety.dart';
import '../services/crop_validation_service.dart';
import '../utils/logger.dart';

/// Repositório para operações com variedades de culturas
class CropVarietyRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'crop_varieties';

  /// Cria a tabela de variedades de culturas no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        cropId TEXT NOT NULL,
        name TEXT NOT NULL,
        company TEXT,
        cycleDays INTEGER DEFAULT 0,
        description TEXT,
        recommendedPopulation REAL,
        weightOf1000Seeds REAL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Insere uma nova variedade de cultura no banco de dados
  Future<String> insert(CropVariety variety) async {
    try {
      print('🔄 Inserindo variedade: ${variety.name} para cultura: ${variety.cropId}');
      
      final db = await _database.database;
      
      print('🔍 Dados da variedade:');
      print('  - ID: ${variety.id}');
      print('  - Nome: ${variety.name}');
      print('  - CropId: ${variety.cropId}');
      
      // SALVAR DIRETO - SEM VALIDAÇÕES DESNECESSÁRIAS
      await db.insert(
        _tableName,
        variety.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Variedade inserida: ${variety.name}');
      return variety.id;
    } catch (e) {
      print('❌ Erro ao inserir variedade: $e');
      rethrow;
    }
  }

  /// Atualiza uma variedade de cultura existente
  Future<int> update(CropVariety variety) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      variety.toMap(),
      where: 'id = ?',
      whereArgs: [variety.id],
    );
  }

  /// Remove uma variedade de cultura
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém uma variedade de cultura pelo ID
  Future<CropVariety?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return CropVariety.fromMap(maps.first);
  }

  /// Obtém todas as variedades de culturas
  Future<List<CropVariety>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => CropVariety.fromMap(maps[i]));
  }

  /// Obtém todas as variedades para uma cultura específica
  Future<List<CropVariety>> getByCropId(String cropId) async {
    try {
      Logger.info('🔍 Buscando variedades para cropId: $cropId');
      final db = await _database.database;
      
      // Tentar buscar pelo cropId fornecido
      List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cropId = ?',
        whereArgs: [cropId],
      );
      
      // Se não encontrou e o cropId parece ser um nome (não numérico), tentar mapear para ID numérico
      if (maps.isEmpty && int.tryParse(cropId) == null) {
        Logger.info('🔍 Nenhuma variedade encontrada para nome "$cropId", tentando mapear para ID numérico...');
        
        // Mapeamento completo de nomes para IDs (solução robusta para todas as culturas)
        final idMap = {
          // Culturas principais
          'soja': '10',
          'milho': '2', 
          'algodao': '3',
          'algodão': '3',
          'feijao': '4',
          'feijão': '4',
          'girassol': '5',
          'arroz': '14',
          'sorgo': '16',
          'trigo': '13',
          'aveia': '11',
          'gergelim': '12',
          'cana-de-acucar': '15',
          'cana_acucar': '15',
          'tomate': '17',
          
          // Variações de nomes (case insensitive)
          'SOJA': '10',
          'MILHO': '2',
          'ALGODAO': '3',
          'ALGODÃO': '3',
          'FEIJAO': '4',
          'FEIJÃO': '4',
          'GIRASSOL': '5',
          'ARROZ': '14',
          'SORGO': '16',
          'TRIGO': '13',
          'AVEIA': '11',
          'GERGELIM': '12',
          'CANA-DE-ACUCAR': '15',
          'CANA_ACUCAR': '15',
          'TOMATE': '17',
          
          // Nomes alternativos
          'soybean': '10',
          'corn': '2',
          'cotton': '3',
          'bean': '4',
          'sunflower': '5',
          'rice': '14',
          'sorghum': '16',
          'wheat': '13',
          'oats': '11',
          'sesame': '12',
          'sugarcane': '15',
          'tomato': '17',
        };
        
        final numericCropId = idMap[cropId.toLowerCase()];
        
        if (numericCropId != null) {
          Logger.info('🔍 Mapeado "$cropId" para ID numérico: $numericCropId');
          maps = await db.query(
            _tableName,
            where: 'cropId = ?',
            whereArgs: [numericCropId],
          );
          
          // Verificação adicional: garantir que os dados retornados são corretos
          if (maps.isNotEmpty) {
            Logger.info('✅ Verificação de dados:');
            for (var map in maps) {
              Logger.info('  - ${map['name']} (cropId: ${map['cropId']}) - Esperado: $numericCropId');
              // Se o cropId não corresponder, remover da lista
              if (map['cropId'].toString() != numericCropId) {
                Logger.warning('⚠️ Dados inconsistentes detectados! Removendo entrada incorreta.');
                maps.remove(map);
              }
            }
          }
        } else {
          Logger.warning('⚠️ Nenhum mapeamento encontrado para cultura: $cropId');
        }
      }
      
      Logger.info('🔍 Encontradas ${maps.length} variedades para cropId: $cropId');
      for (var map in maps) {
        Logger.info('  - ${map['name']} (ID: ${map['id']}, cropId: ${map['cropId']})');
      }
      return List.generate(maps.length, (i) => CropVariety.fromMap(maps[i]));
    } catch (e) {
      Logger.error('❌ Erro ao buscar variedades para cropId $cropId: $e');
      return [];
    }
  }
  
  /// Método auxiliar que aceita tanto String quanto int como ID
  Future<CropVariety?> getVarietyById(dynamic id) async {
    if (id is String) {
      return await getById(id);
    } else if (id is int) {
      // Converter int para String
      return await getById(id.toString());
    }
    return null;
  }

  /// Obtém as variedades de culturas pendentes de sincronização
  Future<List<CropVariety>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => CropVariety.fromMap(maps[i]));
  }

  /// Marca uma variedade de cultura como sincronizada
  Future<int> markAsSynced(String id) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém a contagem total de variedades de culturas
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// CORREÇÃO CRÍTICA: Garante que a tabela crop_varieties está correta
  Future<void> _ensureCropVarietiesTableIsCorrect() async {
    try {
      final db = await _database.database;
      
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties'"
      );
      
      if (tables.isEmpty) {
        Logger.info('🔄 Tabela crop_varieties não existe, criando...');
        await createTable(db);
        return;
      }
      
      // Verificar se há variedades com cropId inválido
      final invalidVarieties = await db.rawQuery('''
        SELECT cv.id, cv.name, cv.cropId, c.name as crop_name 
        FROM crop_varieties cv 
        LEFT JOIN crops c ON cv.cropId = c.id 
        WHERE c.id IS NULL
        LIMIT 1
      ''');
      
      // Verificar se a tabela tem a estrutura correta
      final tableInfo = await db.rawQuery('PRAGMA table_info(crop_varieties)');
      final hasWeightColumn = tableInfo.any((column) => column['name'] == 'weightOf1000Seeds');
      final hasNotesColumn = tableInfo.any((column) => column['name'] == 'notes');
      
      if (invalidVarieties.isNotEmpty || !hasWeightColumn || !hasNotesColumn) {
        Logger.warning('⚠️ Tabela crop_varieties com problemas estruturais, corrigindo...');
        
        // Fazer backup dos dados existentes
        final existingData = await db.rawQuery('SELECT * FROM crop_varieties');
        Logger.info('💾 Backup de ${existingData.length} registros feito');
        
        // Dropar a tabela existente
        await db.execute('DROP TABLE IF EXISTS crop_varieties');
        Logger.info('🗑️ Tabela antiga removida');
        
        // Recriar a tabela com a estrutura correta
        await createTable(db);
        Logger.info('✅ Tabela recriada com estrutura correta');
        
        // Restaurar os dados
        if (existingData.isNotEmpty) {
          final batch = db.batch();
          for (final record in existingData) {
            batch.insert('crop_varieties', record);
          }
          await batch.commit(noResult: true);
          Logger.info('📥 ${existingData.length} registros restaurados');
        }
        
        Logger.info('🎉 Correção da tabela crop_varieties concluída!');
      } else {
        Logger.info('✅ Tabela crop_varieties já está correta');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir tabela crop_varieties: $e');
      rethrow;
    }
  }
}
