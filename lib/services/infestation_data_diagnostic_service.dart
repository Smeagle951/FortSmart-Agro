import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço de diagnóstico para verificar dados de infestação
class InfestationDataDiagnosticService {
  final AppDatabase _appDatabase = AppDatabase();
  
  /// Executa diagnóstico completo dos dados de infestação
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      Logger.info('🔍 [INFESTATION_DIAGNOSTIC] Iniciando diagnóstico completo...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar estrutura das tabelas
      results['table_structure'] = await _checkTableStructure();
      
      // 2. Verificar dados existentes
      results['data_counts'] = await _checkDataCounts();
      
      // 3. Verificar integridade dos dados
      results['data_integrity'] = await _checkDataIntegrity();
      
      // 4. Verificar relacionamentos
      results['relationships'] = await _checkRelationships();
      
      // 5. Verificar dados para heatmap
      results['heatmap_data'] = await _checkHeatmapData();
      
      Logger.info('✅ [INFESTATION_DIAGNOSTIC] Diagnóstico completo finalizado');
      return results;
      
    } catch (e) {
      Logger.error('❌ [INFESTATION_DIAGNOSTIC] Erro no diagnóstico: $e');
      return {
        'error': e.toString(),
        'status': 'failed',
      };
    }
  }
  
  /// Verifica estrutura das tabelas
  Future<Map<String, dynamic>> _checkTableStructure() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Tabelas principais
      final tables = [
        'infestacoes_monitoramento',
        'monitoring_sessions',
        'monitoring_points',
        'occurrences',
        'organism_catalog',
        'talhoes',
      ];
      
      for (final table in tables) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
          results[table] = {
            'exists': tableInfo.isNotEmpty,
            'columns': tableInfo.length,
            'structure': tableInfo.map((c) => {
              'name': c['name'],
              'type': c['type'],
              'notnull': c['notnull'],
            }).toList(),
          };
        } catch (e) {
          results[table] = {
            'exists': false,
            'error': e.toString(),
          };
        }
      }
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica contagem de dados
  Future<Map<String, dynamic>> _checkDataCounts() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Contar registros em cada tabela
      final tables = [
        'infestacoes_monitoramento',
        'monitoring_sessions',
        'monitoring_points',
        'occurrences',
        'organism_catalog',
        'talhoes',
      ];
      
      for (final table in tables) {
        try {
          final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')
          ) ?? 0;
          
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
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica integridade dos dados
  Future<Map<String, dynamic>> _checkDataIntegrity() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar dados de infestação
      final infestationData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN talhao_id IS NULL THEN 1 END) as null_talhao,
          COUNT(CASE WHEN tipo IS NULL OR tipo = '' THEN 1 END) as null_tipo,
          COUNT(CASE WHEN percentual IS NULL THEN 1 END) as null_percentual,
          COUNT(CASE WHEN latitude IS NULL OR longitude IS NULL THEN 1 END) as null_coords
        FROM infestacoes_monitoramento
      ''');
      
      results['infestation_data'] = infestationData.first;
      
      // Verificar dados de monitoramento
      final monitoringData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_sessions,
          COUNT(CASE WHEN status = 'finalized' THEN 1 END) as finalized_sessions,
          COUNT(CASE WHEN status = 'active' THEN 1 END) as active_sessions
        FROM monitoring_sessions
      ''');
      
      results['monitoring_data'] = monitoringData.first;
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica relacionamentos
  Future<Map<String, dynamic>> _checkRelationships() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar se há talhões com dados de infestação
      final talhoesComInfestacao = await db.rawQuery('''
        SELECT DISTINCT t.id, t.nome, COUNT(i.id) as infestacoes_count
        FROM talhoes t
        LEFT JOIN infestacoes_monitoramento i ON t.id = i.talhao_id
        GROUP BY t.id, t.nome
        HAVING COUNT(i.id) > 0
        ORDER BY infestacoes_count DESC
      ''');
      
      results['talhoes_com_infestacao'] = talhoesComInfestacao;
      
      // Verificar organismos com dados
      final organismosComDados = await db.rawQuery('''
        SELECT 
          o.id, 
          o.nome_comum, 
          o.tipo,
          COUNT(i.id) as ocorrencias
        FROM organism_catalog o
        LEFT JOIN infestacoes_monitoramento i ON o.nome_comum = i.tipo
        GROUP BY o.id, o.nome_comum, o.tipo
        HAVING COUNT(i.id) > 0
        ORDER BY ocorrencias DESC
      ''');
      
      results['organismos_com_dados'] = organismosComDados;
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica dados para heatmap
  Future<Map<String, dynamic>> _checkHeatmapData() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar dados suficientes para heatmap
      final heatmapData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_points,
          COUNT(DISTINCT talhao_id) as talhoes_distintos,
          COUNT(DISTINCT tipo) as tipos_distintos,
          AVG(percentual) as media_percentual,
          MIN(percentual) as min_percentual,
          MAX(percentual) as max_percentual,
          COUNT(CASE WHEN percentual > 50 THEN 1 END) as pontos_alto,
          COUNT(CASE WHEN percentual > 75 THEN 1 END) as pontos_critico
        FROM infestacoes_monitoramento
      ''');
      
      results['heatmap_stats'] = heatmapData.first;
      
      // Verificar distribuição por talhão
      final distribuicaoTalhoes = await db.rawQuery('''
        SELECT 
          t.nome as talhao_nome,
          COUNT(i.id) as pontos_infestacao,
          AVG(i.percentual) as media_percentual,
          MAX(i.percentual) as max_percentual,
          COUNT(CASE WHEN i.percentual > 50 THEN 1 END) as pontos_alto
        FROM talhoes t
        LEFT JOIN infestacoes_monitoramento i ON t.id = i.talhao_id
        GROUP BY t.id, t.nome
        HAVING COUNT(i.id) > 0
        ORDER BY pontos_infestacao DESC
      ''');
      
      results['distribuicao_talhoes'] = distribuicaoTalhoes;
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Gera dados de teste se necessário
  Future<Map<String, dynamic>> generateTestDataIfNeeded() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar se há dados
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM infestacoes_monitoramento')
      ) ?? 0;
      
      if (count == 0) {
        Logger.info('🔄 [INFESTATION_DIAGNOSTIC] Gerando dados de teste...');
        
        // Inserir dados de teste
        await db.insert('infestacoes_monitoramento', {
          'id': 'test_1',
          'talhao_id': 1,
          'ponto_id': 1,
          'latitude': -23.5505,
          'longitude': -46.6333,
          'tipo': 'Plantas Daninhas',
          'subtipo': 'Buva',
          'nivel': 'ALTO',
          'percentual': 65,
          'foto_paths': '',
          'data_hora': DateTime.now().toIso8601String(),
        });
        
        await db.insert('infestacoes_monitoramento', {
          'id': 'test_2',
          'talhao_id': 1,
          'ponto_id': 2,
          'latitude': -23.5515,
          'longitude': -46.6343,
          'tipo': 'Plantas Daninhas',
          'subtipo': 'Capim-colchão',
          'nivel': 'CRÍTICO',
          'percentual': 85,
          'foto_paths': '',
          'data_hora': DateTime.now().toIso8601String(),
        });
        
        await db.insert('infestacoes_monitoramento', {
          'id': 'test_3',
          'talhao_id': 2,
          'ponto_id': 1,
          'latitude': -23.5525,
          'longitude': -46.6353,
          'tipo': 'Pragas',
          'subtipo': 'Lagarta',
          'nivel': 'MODERADO',
          'percentual': 35,
          'foto_paths': '',
          'data_hora': DateTime.now().toIso8601String(),
        });
        
        results['test_data_created'] = true;
        results['test_records'] = 3;
        Logger.info('✅ [INFESTATION_DIAGNOSTIC] Dados de teste criados');
      } else {
        results['test_data_created'] = false;
        results['existing_records'] = count;
        Logger.info('ℹ️ [INFESTATION_DIAGNOSTIC] Dados já existem: $count registros');
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ [INFESTATION_DIAGNOSTIC] Erro ao gerar dados de teste: $e');
      return {'error': e.toString()};
    }
  }
}
