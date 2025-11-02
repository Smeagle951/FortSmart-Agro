import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// Utilitário para listar todas as tabelas definidas no sistema
class DatabaseTableLister {
  static final AppDatabase _appDatabase = AppDatabase();
  
  /// Lista todas as tabelas definidas no sistema
  static List<String> getAllDefinedTables() {
    return [
      // Tabelas principais do sistema
      'farms',
      'properties', 
      'plots',
      'talhoes',
      'crops',
      'culturas',
      'crop_varieties',
      
      // Tabelas de monitoramento
      'monitorings',
      'monitoring_points',
      'infestacao_resumo',
      
      // Tabelas de pragas, doenças e plantas daninhas
      'pests',
      'diseases', 
      'weeds',
      
      // Tabelas de atividades
              // Módulo de atividades removido
      'plantings',
      'harvest_losses',
      'pesticide_applications',
      
      // Tabelas de inventário
      'inventory',
      'inventory_movements',
      
      // Tabelas de máquinas
      'machines',
      
      // Tabelas de clima
      'weather_data',
      'weather_forecast',
      
      // Tabelas de análise de solo
      'soil_analyses',
      
      // Tabelas de integração
      'talhoes_unificados',
      'safras_unificadas',
      'atividades_agricolas',
      'alertas_integrados',
      
      // Tabelas específicas de módulos
      'plantio',
      'colheita', 
      'monitoramento',
      'aplicacao',
      'historico_atividades',
      'safra',
      
      // Tabelas de calibragem
      'calibragem_adubo_coleta',
      'calibragem_plantadeira',
      'estande_plantas',
      'historico_plantio',
      
      // Tabelas de ocorrências
      'occurrences',
      'alerts',
      
      // Tabelas de pontos de monitoramento
      'monitoring_points',
      'monitoring_routes',
      
      // Tabelas de imagens
      'praga_images',
      
      // Tabelas de produtos agrícolas
      'agricultural_products',
      'farm_crops',
      'crop_items',
      
      // Tabelas de subáreas
      'subareas_plantio',
      
      // Tabelas de alertas (removidas mas podem existir)
      'alerts',
      
      // Tabelas de sincronização
      'sync_log',
      'sync_status',
      
      // Tabelas de configuração
      'app_config',
      'user_preferences',
      
      // Tabelas de backup
      'backup_log',
      'restore_log',
    ];
  }
  
  /// Verifica quais tabelas existem no banco de dados
  static Future<List<String>> getExistingTables() async {
    try {
      final db = await _appDatabase.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      return result.map((item) => item['name'] as String).toList();
    } catch (e) {
      print('Erro ao listar tabelas existentes: $e');
      return [];
    }
  }
  
  /// Verifica quais tabelas estão faltando
  static Future<List<String>> getMissingTables() async {
    final definedTables = getAllDefinedTables();
    final existingTables = await getExistingTables();
    
    return definedTables.where((table) => !existingTables.contains(table)).toList();
  }
  
  /// Verifica quais tabelas existem mas não estão na lista definida
  static Future<List<String>> getUnexpectedTables() async {
    final definedTables = getAllDefinedTables();
    final existingTables = await getExistingTables();
    
    return existingTables.where((table) => !definedTables.contains(table)).toList();
  }
  
  /// Gera relatório completo das tabelas
  static Future<Map<String, dynamic>> generateTableReport() async {
    final definedTables = getAllDefinedTables();
    final existingTables = await getExistingTables();
    final missingTables = await getMissingTables();
    final unexpectedTables = await getUnexpectedTables();
    
    return {
      'total_defined': definedTables.length,
      'total_existing': existingTables.length,
      'missing_tables': missingTables,
      'unexpected_tables': unexpectedTables,
      'defined_tables': definedTables,
      'existing_tables': existingTables,
    };
  }
}
