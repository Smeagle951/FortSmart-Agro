/// 🔍 VERIFICAÇÃO COMPLETA DE TODAS AS TABELAS DO SISTEMA
/// Verifica se todas as tabelas necessárias existem

import '../database/app_database.dart';
import '../utils/logger.dart';

class VerifyAllTables {
  static Future<void> run() async {
    try {
      Logger.info('🔍 ====== VERIFICAÇÃO COMPLETA DE TABELAS ======');
      
      final db = await AppDatabase.instance.database;
      
      // Listar todas as tabelas existentes
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      final tabelasExistentes = tables.map((t) => t['name'] as String).toList();
      
      Logger.info('📊 Total de tabelas no banco: ${tabelasExistentes.length}');
      Logger.info('');
      
      // Tabelas esperadas (principais módulos)
      final tabelasEsperadas = {
        // CORE
        'talhoes': 'Talhões',
        'safras': 'Safras',
        'poligonos': 'Polígonos dos Talhões',
        
        // PLANTIO
        'plantio': 'Plantios (novo)',
        'plantios': 'Plantios (legado)',
        'historico_plantio': 'Histórico de Plantio',
        'crop_varieties': 'Variedades de Culturas',
        
        // MONITORAMENTO
        'monitoring_sessions': 'Sessões de Monitoramento',
        'monitoring_points': 'Pontos de Monitoramento',
        'monitoring_occurrences': 'Ocorrências de Monitoramento',
        'monitoring_history': 'Histórico de Monitoramento',
        'pontos_monitoramento': 'Pontos (legado)',
        
        // INFESTAÇÃO
        'infestation_map': 'Mapa de Infestação',
        'infestation_summaries': 'Resumos de Infestação',
        'infestation_alerts': 'Alertas de Infestação',
        
        // FENOLOGIA
        'phenological_records': 'Registros Fenológicos',
        
        // ESTANDE
        'estande_plantas': 'Estande de Plantas',
        'plantios_cv': 'CV% de Plantios',
        
        // CALIBRAÇÃO
        'fertilizer_calibrations': 'Calibrações de Fertilizantes',
        
        // PRODUTOS
        'agricultural_products': 'Produtos Agrícolas',
        'inventory_products': 'Produtos do Inventário',
        
        // GERMINAÇÃO
        'germination_tests': 'Testes de Germinação',
        'germination_subtests': 'Subtestes de Germinação',
        'germination_daily_records': 'Registros Diários de Germinação',
        'germination_subtest_daily_records': 'Registros de Subtestes',
      };
      
      Logger.info('✅ TABELAS PRESENTES:');
      for (final tabela in tabelasEsperadas.keys) {
        if (tabelasExistentes.contains(tabela)) {
          Logger.info('  ✅ $tabela - ${tabelasEsperadas[tabela]}');
        }
      }
      
      Logger.info('');
      Logger.info('❌ TABELAS FALTANDO:');
      var faltando = false;
      for (final tabela in tabelasEsperadas.keys) {
        if (!tabelasExistentes.contains(tabela)) {
          Logger.info('  ❌ $tabela - ${tabelasEsperadas[tabela]}');
          faltando = true;
        }
      }
      
      if (!faltando) {
        Logger.info('  ✅ Nenhuma tabela faltando!');
      }
      
      Logger.info('');
      Logger.info('📋 TABELAS EXTRAS (não mapeadas):');
      for (final tabela in tabelasExistentes) {
        if (!tabelasEsperadas.containsKey(tabela) && 
            !tabela.startsWith('sqlite_') &&
            !tabela.startsWith('android_')) {
          Logger.info('  ℹ️ $tabela');
        }
      }
      
      Logger.info('');
      Logger.info('📊 CONTAGEM DE REGISTROS NAS PRINCIPAIS TABELAS:');
      
      for (final tabela in ['talhoes', 'monitoring_sessions', 'monitoring_points', 
                            'monitoring_occurrences', 'plantio', 'plantios', 
                            'historico_plantio', 'crop_varieties', 'phenological_records', 
                            'estande_plantas']) {
        if (tabelasExistentes.contains(tabela)) {
          try {
            final count = await db.rawQuery('SELECT COUNT(*) as total FROM $tabela');
            final total = count.first['total'] as int? ?? 0;
            Logger.info('  $tabela: $total registros');
          } catch (e) {
            Logger.error('  $tabela: ERRO ao contar - $e');
          }
        }
      }
      
      Logger.info('');
      Logger.info('🔍 ====== VERIFICAÇÃO COMPLETA ======');
      
    } catch (e) {
      Logger.error('❌ Erro na verificação: $e');
    }
  }
}

