/// 🔧 CORREÇÃO DO SCHEMA DA TABELA monitoring_sessions
/// Adiciona colunas faltantes sem perder dados

import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

class FixMonitoringSessionsSchema {
  static Future<void> run() async {
    try {
      Logger.info('🔧 Verificando schema de monitoring_sessions...');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar schema atual
      final tableInfo = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      final colunas = tableInfo.map((col) => col['name'] as String).toList();
      
      Logger.info('📊 Colunas atuais: ${colunas.join(", ")}');
      
      // 2. Verificar colunas faltantes
      final colunasFaltantes = <String>[];
      
      if (!colunas.contains('talhao_nome')) colunasFaltantes.add('talhao_nome');
      if (!colunas.contains('cultura_nome')) colunasFaltantes.add('cultura_nome');
      if (!colunas.contains('amostragem_padrao_plantas_por_ponto')) colunasFaltantes.add('amostragem_padrao_plantas_por_ponto');
      if (!colunas.contains('started_at')) colunasFaltantes.add('started_at');
      if (!colunas.contains('finished_at')) colunasFaltantes.add('finished_at');
      if (!colunas.contains('device_id')) colunasFaltantes.add('device_id');
      if (!colunas.contains('catalog_version')) colunasFaltantes.add('catalog_version');
      if (!colunas.contains('sync_state')) colunasFaltantes.add('sync_state');
      
      if (colunasFaltantes.isEmpty) {
        Logger.info('✅ Todas as colunas estão presentes!');
        return;
      }
      
      Logger.info('⚠️ Colunas faltantes: ${colunasFaltantes.join(", ")}');
      
      // 3. Adicionar colunas faltantes
      for (final coluna in colunasFaltantes) {
        try {
          String tipoColuna = 'TEXT';
          String defaultValue = "''";
          
          switch (coluna) {
            case 'amostragem_padrao_plantas_por_ponto':
              tipoColuna = 'INTEGER';
              defaultValue = '10';
              break;
            case 'started_at':
            case 'finished_at':
              tipoColuna = 'TEXT';
              defaultValue = 'NULL';
              break;
            case 'sync_state':
              defaultValue = "'pending'";
              break;
            case 'catalog_version':
              defaultValue = "'1.0.0'";
              break;
            case 'device_id':
              defaultValue = "'device_default'";
              break;
          }
          
          await db.execute('''
            ALTER TABLE monitoring_sessions 
            ADD COLUMN $coluna $tipoColuna DEFAULT $defaultValue
          ''');
          
          Logger.info('✅ Coluna $coluna adicionada');
        } catch (e) {
          Logger.error('❌ Erro ao adicionar coluna $coluna: $e');
        }
      }
      
      // 4. Verificar novamente
      final tableInfoFinal = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      final colunasFinal = tableInfoFinal.map((col) => col['name'] as String).toList();
      
      Logger.info('✅ Schema corrigido! Colunas finais: ${colunasFinal.join(", ")}');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir schema: $e');
    }
  }
}

