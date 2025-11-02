import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/app_database.dart';

/// Utilitário para resetar e recriar o banco de dados
class DatabaseResetHelper {
  static final AppDatabase _appDatabase = AppDatabase();
  
  /// Força a recriação do banco de dados
  static Future<void> forceDatabaseRecreation() async {
    try {
      print('🔄 Forçando recriação do banco de dados...');
      
      // Obter caminho do banco
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'fortsmartagro.db');
      
      // Fechar conexão atual se existir
      if (_appDatabase.database != null) {
        try {
          final db = await _appDatabase.database;
          await db.close();
        } catch (e) {
          print('Erro ao fechar conexão: $e');
        }
      }
      
      // Excluir arquivo do banco
      await deleteDatabase(path);
      print('✅ Banco de dados excluído');
      
      // Recriar banco
      final newDb = await _appDatabase.database;
      print('✅ Banco de dados recriado com sucesso');
      
      // Verificar tabelas criadas
      final tables = await newDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      print('📊 Tabelas criadas: ${tables.length}');
      for (final table in tables) {
        print('  - ${table['name']}');
      }
      
    } catch (e) {
      print('❌ Erro ao recriar banco de dados: $e');
      rethrow;
    }
  }
  
  /// Verifica se todas as tabelas essenciais existem
  static Future<Map<String, bool>> checkEssentialTables() async {
    try {
      final db = await _appDatabase.database;
      final essentialTables = [
        'farms', 'properties', 'plots', 'talhoes', 'crops', 'culturas',
        'monitorings', 'monitoring_points', 'infestacao_resumo',
        'pests', 'diseases', 'weeds', 'plantings',
        'harvest_losses', 'pesticide_applications', 'inventory',
        'inventory_movements', 'machines', 'weather_data',
        'weather_forecast', 'soil_analyses', 'occurrences', 'alerts',
        'agricultural_products', 'farm_crops', 'crop_items',
        'subareas_plantio', 'monitoring_routes', 'sync_log',
        'sync_status', 'app_config', 'user_preferences',
        'backup_log', 'restore_log'
      ];
      
      final results = <String, bool>{};
      
      for (final tableName in essentialTables) {
        final tables = await db.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', tableName],
        );
        results[tableName] = tables.isNotEmpty;
      }
      
      return results;
    } catch (e) {
      print('❌ Erro ao verificar tabelas essenciais: $e');
      return {};
    }
  }
  
  /// Executa verificação completa do banco
  static Future<void> performFullDatabaseCheck() async {
    try {
      print('🔍 Executando verificação completa do banco de dados...');
      
      final tableStatus = await checkEssentialTables();
      final totalTables = tableStatus.length;
      final existingTables = tableStatus.values.where((exists) => exists).length;
      final missingTables = tableStatus.values.where((exists) => !exists).length;
      
      print('📊 Resumo da verificação:');
      print('  - Total de tabelas essenciais: $totalTables');
      print('  - Tabelas existentes: $existingTables');
      print('  - Tabelas faltando: $missingTables');
      
      if (missingTables > 0) {
        print('⚠️ Tabelas faltando:');
        tableStatus.forEach((table, exists) {
          if (!exists) {
            print('  - $table');
          }
        });
        
        print('🔄 Recomendação: Execute forceDatabaseRecreation() para recriar o banco');
      } else {
        print('✅ Todas as tabelas essenciais estão presentes!');
      }
      
    } catch (e) {
      print('❌ Erro na verificação completa: $e');
    }
  }
}
