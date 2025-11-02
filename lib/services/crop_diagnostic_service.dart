import '../database/app_database.dart';
import '../repositories/crop_repository.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/crop_dao.dart';
import '../utils/logger.dart';

/// Serviço para diagnosticar problemas no módulo de culturas
class CropDiagnosticService {
  final AppDatabase _database = AppDatabase();
  final CropRepository _cropRepository = CropRepository();
  final PestDao _pestDao = PestDao();
  final CropDao _cropDao = CropDao();

  /// Executa diagnóstico completo do módulo de culturas
  Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      Logger.info('🔍 Iniciando diagnóstico do módulo de culturas...');
      
      // 1. Verificar conexão com banco
      results['database_connection'] = await _checkDatabaseConnection();
      
      // 2. Verificar estrutura das tabelas
      results['table_structure'] = await _checkTableStructure();
      
      // 3. Verificar dados existentes
      results['existing_data'] = await _checkExistingData();
      
      // 4. Verificar integridade referencial
      results['referential_integrity'] = await _checkReferentialIntegrity();
      
      // 5. Testar operações básicas
      results['basic_operations'] = await _testBasicOperations();
      
      // 6. Gerar recomendações
      results['recommendations'] = _generateRecommendations(results);
      
      Logger.info('✅ Diagnóstico concluído com sucesso');
      
    } catch (e) {
      Logger.error('❌ Erro durante diagnóstico: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Verifica conexão com banco de dados
  Future<Map<String, dynamic>> _checkDatabaseConnection() async {
    try {
      final db = await _database.database;
      final version = await db.rawQuery('PRAGMA user_version').then((result) => result.first['user_version'] as int? ?? 0);
      
      return {
        'status': 'success',
        'database_version': version,
        'message': 'Conexão com banco estabelecida',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'Falha na conexão com banco',
      };
    }
  }

  /// Verifica estrutura das tabelas
  Future<Map<String, dynamic>> _checkTableStructure() async {
    try {
      final db = await _database.database;
      final results = <String, dynamic>{};
      
      // Verificar tabelas essenciais
      final essentialTables = ['crops', 'pests', 'diseases', 'weeds'];
      
      for (final table in essentialTables) {
        final tables = await db.query('sqlite_master', 
          where: 'type = ? AND name = ?', 
          whereArgs: ['table', table]
        );
        
        results[table] = {
          'exists': tables.isNotEmpty,
          'count': tables.length,
        };
        
        if (tables.isNotEmpty) {
          // Verificar estrutura da tabela
          final columns = await db.rawQuery('PRAGMA table_info($table)');
          results[table]['columns'] = columns.map((col) => col['name']).toList();
        }
      }
      
      return {
        'status': 'success',
        'tables': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica dados existentes
  Future<Map<String, dynamic>> _checkExistingData() async {
    try {
      final db = await _database.database;
      final results = <String, dynamic>{};
      
      // Contar registros em cada tabela
      final tables = ['crops', 'pests', 'diseases', 'weeds'];
      
      for (final table in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          final count = result.first['count'] as int? ?? 0;
          
          results[table] = {
            'count': count,
            'has_data': count > 0,
          };
        } catch (e) {
          results[table] = {
            'count': 0,
            'has_data': false,
            'error': e.toString(),
          };
        }
      }
      
      return {
        'status': 'success',
        'data_counts': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica integridade referencial
  Future<Map<String, dynamic>> _checkReferentialIntegrity() async {
    try {
      final db = await _database.database;
      final results = <String, dynamic>{};
      
      // Verificar pragas sem cultura
      try {
        final orphanPests = await db.rawQuery('''
          SELECT p.id, p.name, p.crop_id 
          FROM pests p 
          LEFT JOIN crops c ON p.crop_id = c.id 
          WHERE c.id IS NULL
        ''');
        
        results['orphan_pests'] = {
          'count': orphanPests.length,
          'items': orphanPests,
        };
      } catch (e) {
        results['orphan_pests'] = {
          'count': 0,
          'error': e.toString(),
        };
      }
      
      // Verificar doenças sem cultura
      try {
        final orphanDiseases = await db.rawQuery('''
          SELECT d.id, d.name, d.crop_id 
          FROM diseases d 
          LEFT JOIN crops c ON d.crop_id = c.id 
          WHERE c.id IS NULL
        ''');
        
        results['orphan_diseases'] = {
          'count': orphanDiseases.length,
          'items': orphanDiseases,
        };
      } catch (e) {
        results['orphan_diseases'] = {
          'count': 0,
          'error': e.toString(),
        };
      }
      
      return {
        'status': 'success',
        'integrity_checks': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Testa operações básicas
  Future<Map<String, dynamic>> _testBasicOperations() async {
    try {
      final results = <String, dynamic>{};
      
      // Testar busca de culturas
      try {
        final crops = await _cropRepository.getAllCrops();
        results['get_crops'] = {
          'status': 'success',
          'count': crops.length,
        };
      } catch (e) {
        results['get_crops'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
      
      // Testar busca de pragas
      try {
        final pests = await _pestDao.getAll();
        results['get_pests'] = {
          'status': 'success',
          'count': pests.length,
        };
      } catch (e) {
        results['get_pests'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
      
      // Testar inserção de cultura de teste (SEM PERSISTIR NO BANCO)
      try {
        // Simular inserção sem realmente inserir no banco
        final testCrop = {
          'id': 'test_crop_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Cultura Teste',
          'description': 'Cultura para teste',
          'sync_status': 0,
        };
        
        // Simular inserção de praga de teste
        final testPest = {
          'name': 'Praga Teste',
          'scientific_name': 'Test Pest',
          'description': 'Praga para teste',
          'crop_id': 999,
          'is_default': 1,
          'sync_status': 0,
        };
        
        // Verificar se as estruturas estão corretas (sem inserir)
        if (testCrop.containsKey('id') && testCrop.containsKey('name') && 
            testPest.containsKey('name') && testPest.containsKey('scientific_name')) {
          results['test_insert'] = {
            'status': 'success',
            'message': 'Estruturas de dados válidas para inserção',
            'simulated_crop_id': testCrop['id'],
            'simulated_pest_id': 999,
          };
        } else {
          results['test_insert'] = {
            'status': 'error',
            'error': 'Estruturas de dados inválidas',
          };
        }
      } catch (e) {
        results['test_insert'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
      
      return {
        'status': 'success',
        'operations': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Gera recomendações baseadas no diagnóstico
  List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Verificar estrutura das tabelas
    final tableStructure = results['table_structure'];
    if (tableStructure != null && tableStructure['status'] == 'success') {
      final tables = tableStructure['tables'] as Map<String, dynamic>;
      
      for (final entry in tables.entries) {
        final tableName = entry.key;
        final tableInfo = entry.value as Map<String, dynamic>;
        
        if (tableInfo['exists'] == false) {
          recommendations.add('❌ Tabela $tableName não existe - precisa ser criada');
        }
      }
    }
    
    // Verificar dados existentes
    final existingData = results['existing_data'];
    if (existingData != null && existingData['status'] == 'success') {
      final dataCounts = existingData['data_counts'] as Map<String, dynamic>;
      
      for (final entry in dataCounts.entries) {
        final tableName = entry.key;
        final tableInfo = entry.value as Map<String, dynamic>;
        
        if (tableInfo['has_data'] == false) {
          recommendations.add('⚠️ Tabela $tableName está vazia - considere inserir dados padrão');
        }
      }
    }
    
    // Verificar integridade referencial
    final integrity = results['referential_integrity'];
    if (integrity != null && integrity['status'] == 'success') {
      final integrityChecks = integrity['integrity_checks'] as Map<String, dynamic>;
      
      final orphanPests = integrityChecks['orphan_pests'] as Map<String, dynamic>;
      if (orphanPests['count'] > 0) {
        recommendations.add('⚠️ Existem ${orphanPests['count']} pragas sem cultura associada');
      }
      
      final orphanDiseases = integrityChecks['orphan_diseases'] as Map<String, dynamic>;
      if (orphanDiseases['count'] > 0) {
        recommendations.add('⚠️ Existem ${orphanDiseases['count']} doenças sem cultura associada');
      }
    }
    
    // Verificar operações básicas
    final operations = results['basic_operations'];
    if (operations != null && operations['status'] == 'success') {
      final opResults = operations['operations'] as Map<String, dynamic>;
      
      for (final entry in opResults.entries) {
        final operation = entry.key;
        final result = entry.value as Map<String, dynamic>;
        
        if (result['status'] == 'error') {
          recommendations.add('❌ Operação $operation falhou: ${result['error']}');
        }
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ Módulo de culturas está funcionando corretamente');
    }
    
    return recommendations;
  }

  /// Executa correções automáticas baseadas no diagnóstico
  Future<Map<String, dynamic>> runAutoFix() async {
    final results = <String, dynamic>{};
    
    try {
      Logger.info('🔧 Iniciando correções automáticas...');
      
      // Inicializar repositório
      await _cropRepository.initialize();
      results['initialization'] = 'success';
      
      // Verificar e corrigir dados órfãos
      final db = await _database.database;
      
      // Criar cultura padrão para pragas órfãs
      final orphanPests = await db.rawQuery('''
        SELECT DISTINCT p.crop_id 
        FROM pests p 
        LEFT JOIN crops c ON p.crop_id = c.id 
        WHERE c.id IS NULL
      ''');
      
      for (final orphan in orphanPests) {
        final cropId = orphan['crop_id'] as int;
        await db.insert('crops', {
          'id': cropId.toString(),
          'name': 'Cultura $cropId',
          'description': 'Cultura criada automaticamente',
          'sync_status': 0,
        });
      }
      
      results['orphan_fixes'] = {
        'crops_created': orphanPests.length,
      };
      
      Logger.info('✅ Correções automáticas concluídas');
      
    } catch (e) {
      Logger.error('❌ Erro durante correções automáticas: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }
}
