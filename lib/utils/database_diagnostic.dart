import '../database/app_database.dart';

/// Utilitário para diagnosticar problemas do banco de dados
class DatabaseDiagnostic {
  static final AppDatabase _database = AppDatabase();

  /// Executa um diagnóstico completo do banco de dados
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final diagnostic = <String, dynamic>{};
    
    try {
      print('🔍 Iniciando diagnóstico completo do banco de dados...');
      
      // Informações básicas
      final db = await _database.database;
      
      // Contar tabelas
      final tablesResult = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
      final tables = tablesResult.map((row) => row['name'] as String).toList();
      
      diagnostic['total_tables'] = tables.length;
      diagnostic['table_names'] = tables;
      
      print('📊 Total de tabelas: ${tables.length}');
      print('📋 Tabelas encontradas: ${tables.join(', ')}');
      
      // Verificar tabelas essenciais
      final expectedTables = [
        'farms', 'plots', 'talhoes', 'crops', 'culturas', 'monitorings', 
        'monitoring_points', 'pests', 'diseases', 'weeds', 'crop_varieties',
        'pesticide_applications', 'inventory', 'inventory_movements',
        'soil_analyses', 'properties', 'machines', 'weather_data', 'weather_forecast',
        'alerts', 'historico_plantio', 'estande_plantas', 'infestacao_resumo',
        'subareas_plantio', 'praga_images'
      ];
      
      final missingTables = expectedTables.where((table) => !tables.contains(table)).toList();
      final presentTables = expectedTables.where((table) => tables.contains(table)).toList();
      
      diagnostic['expected_tables'] = expectedTables.length;
      diagnostic['missing_tables'] = missingTables;
      diagnostic['present_tables'] = presentTables;
      diagnostic['missing_count'] = missingTables.length;
      diagnostic['present_count'] = presentTables.length;
      
      if (missingTables.isNotEmpty) {
        print('⚠️ Tabelas faltando (${missingTables.length}): ${missingTables.join(', ')}');
      } else {
        print('✅ Todas as tabelas essenciais estão presentes');
      }
      
      // Testar algumas consultas básicas
      final testResults = <String, dynamic>{};
      
      for (final table in ['plots', 'farms', 'crops', 'monitorings']) {
        if (tables.contains(table)) {
          try {
            final count = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
            final rowCount = count.first['count'] as int;
            testResults[table] = rowCount;
            print('📊 $table: $rowCount registros');
          } catch (e) {
            testResults[table] = 'ERRO: $e';
            print('❌ Erro ao consultar $table: $e');
          }
        } else {
          testResults[table] = 'TABELA_NAO_EXISTE';
          print('❌ Tabela $table não existe');
        }
      }
      
      diagnostic['table_counts'] = testResults;
      
      // Informações do banco
      final dbInfo = await db.rawQuery('PRAGMA database_list');
      diagnostic['database_info'] = dbInfo;
      
      final userVersion = await db.rawQuery('PRAGMA user_version');
      diagnostic['user_version'] = userVersion.first['user_version'];
      
      print('🔧 Versão do banco: ${diagnostic['user_version']}');
      
      diagnostic['status'] = missingTables.isEmpty ? 'OK' : 'PROBLEMAS_ENCONTRADOS';
      diagnostic['timestamp'] = DateTime.now().toIso8601String();
      
      return diagnostic;
      
    } catch (e) {
      print('❌ Erro durante diagnóstico: $e');
      diagnostic['error'] = e.toString();
      diagnostic['status'] = 'ERRO_CRITICO';
      return diagnostic;
    }
  }
  
  /// Força a recriação do banco de dados
  static Future<bool> forceRecreateDatabase() async {
    try {
      print('🔄 Forçando recriação do banco de dados...');
      
      await _database.resetDatabase();
      
      print('✅ Banco recriado com sucesso');
      
      // Executar diagnóstico após recriação
      final diagnostic = await runFullDiagnostic();
      
      return diagnostic['status'] == 'OK';
      
    } catch (e) {
      print('❌ Erro ao recriar banco: $e');
      return false;
    }
  }
  
  /// Força a criação das tabelas faltantes
  static Future<bool> forceCreateMissingTables() async {
    try {
      print('🔄 Forçando criação das tabelas faltantes...');
      
      await _database.forceCreateTables();
      
      // Verificar se funcionou
      final diagnostic = await runFullDiagnostic();
      
      return diagnostic['missing_count'] == 0;
      
    } catch (e) {
      print('❌ Erro ao criar tabelas faltantes: $e');
      return false;
    }
  }
}
