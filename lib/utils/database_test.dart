import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/database_helper.dart';
import 'database_cleanup.dart';

/// Utilitário para testar se a correção do banco de dados funcionou
class DatabaseTest {
  static final AppDatabase _appDatabase = AppDatabase();
  static final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  /// Testa se o banco de dados está funcionando corretamente
  static Future<Map<String, dynamic>> testDatabase() async {
    final results = <String, dynamic>{};
    
    try {
      print('=== TESTE DO BANCO DE DADOS ===');
      
      // 1. Testar se o banco está corrompido
      print('1. Verificando se o banco está corrompido...');
      final isCorrupted = await DatabaseCleanup.isDatabaseCorrupted();
      results['isCorrupted'] = isCorrupted;
      print('   Resultado: ${isCorrupted ? 'CORROMPIDO' : 'OK'}');
      
      if (isCorrupted) {
        print('   Banco corrompido detectado!');
        return results;
      }
      
      // 2. Testar abertura do banco principal
      print('2. Testando abertura do banco principal...');
      final db = await _appDatabase.database;
      results['mainDatabaseOpen'] = db.isOpen;
      print('   Resultado: ${db.isOpen ? 'OK' : 'FALHOU'}');
      
      // 3. Testar consulta simples
      print('3. Testando consulta simples...');
      final testQuery = await db.rawQuery('SELECT 1 as test');
      results['simpleQuery'] = testQuery.isNotEmpty;
      print('   Resultado: ${testQuery.isNotEmpty ? 'OK' : 'FALHOU'}');
      
      // 4. Verificar versão do banco
      print('4. Verificando versão do banco...');
      final version = await db.getVersion();
      results['databaseVersion'] = version;
      print('   Versão: $version');
      
      // 5. Verificar tabelas essenciais
      print('5. Verificando tabelas essenciais...');
      final essentialTables = [
        'farms', 'plots', 'crops', 'pests', 'diseases', 'weeds',
        'monitorings', 'monitoring_points', 'pesticide_applications'
      ];
      
      final tableResults = <String, bool>{};
      for (final tableName in essentialTables) {
        try {
          final tables = await db.query(
            'sqlite_master',
            where: 'type = ? AND name = ?',
            whereArgs: ['table', tableName],
          );
          tableResults[tableName] = tables.isNotEmpty;
          print('   $tableName: ${tables.isNotEmpty ? 'OK' : 'FALTANDO'}');
        } catch (e) {
          tableResults[tableName] = false;
          print('   $tableName: ERRO - $e');
        }
      }
      results['essentialTables'] = tableResults;
      
      // 6. Testar PRAGMA
      print('6. Testando configurações PRAGMA...');
      try {
        final pragmaResults = await db.rawQuery('PRAGMA journal_mode');
        results['pragmaJournalMode'] = pragmaResults.isNotEmpty;
        print('   journal_mode: ${pragmaResults.isNotEmpty ? 'OK' : 'FALHOU'}');
        
        final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
        results['pragmaForeignKeys'] = foreignKeys.isNotEmpty;
        print('   foreign_keys: ${foreignKeys.isNotEmpty ? 'OK' : 'FALHOU'}');
      } catch (e) {
        results['pragmaError'] = e.toString();
        print('   ERRO PRAGMA: $e');
      }
      
      // 7. Testar DatabaseHelper
      print('7. Testando DatabaseHelper...');
      try {
        final helperDb = await _databaseHelper.database;
        results['helperDatabaseOpen'] = helperDb.isOpen;
        print('   Resultado: ${helperDb.isOpen ? 'OK' : 'FALHOU'}');
      } catch (e) {
        results['helperError'] = e.toString();
        print('   ERRO DatabaseHelper: $e');
      }
      
      // 8. Verificar se há tabelas duplicadas
      print('8. Verificando tabelas duplicadas...');
      try {
        final allTables = await db.query(
          'sqlite_master',
          where: 'type = ?',
          whereArgs: ['table'],
        );
        
        final tableNames = allTables.map((t) => t['name'] as String).toList();
        final duplicates = <String>[];
        
        for (final tableName in tableNames) {
          if (tableNames.where((name) => name == tableName).length > 1) {
            duplicates.add(tableName);
          }
        }
        
        results['duplicateTables'] = duplicates;
        if (duplicates.isNotEmpty) {
          print('   TABELAS DUPLICADAS ENCONTRADAS: $duplicates');
        } else {
          print('   Nenhuma tabela duplicada encontrada');
        }
      } catch (e) {
        results['duplicateCheckError'] = e.toString();
        print('   ERRO ao verificar duplicatas: $e');
      }
      
      print('=== TESTE CONCLUÍDO ===');
      
    } catch (e) {
      results['testError'] = e.toString();
      print('ERRO GERAL NO TESTE: $e');
    }
    
    return results;
  }
  
  /// Executa um teste completo e retorna um resumo
  static Future<String> runFullTest() async {
    final results = await testDatabase();
    
    final summary = StringBuffer();
    summary.writeln('=== RESUMO DO TESTE DO BANCO DE DADOS ===');
    
    if (results['isCorrupted'] == true) {
      summary.writeln('❌ BANCO DE DADOS CORROMPIDO');
      summary.writeln('   Recomendação: Limpar e recriar o banco');
      return summary.toString();
    }
    
    if (results['mainDatabaseOpen'] == true) {
      summary.writeln('✅ Banco principal aberto com sucesso');
    } else {
      summary.writeln('❌ Falha ao abrir banco principal');
    }
    
    if (results['simpleQuery'] == true) {
      summary.writeln('✅ Consultas funcionando');
    } else {
      summary.writeln('❌ Falha em consultas simples');
    }
    
    summary.writeln('📊 Versão do banco: ${results['databaseVersion']}');
    
    final tableResults = results['essentialTables'] as Map<String, bool>?;
    if (tableResults != null) {
      final missingTables = tableResults.entries.where((e) => !e.value).map((e) => e.key).toList();
      if (missingTables.isNotEmpty) {
        summary.writeln('⚠️  Tabelas faltando: ${missingTables.join(', ')}');
      } else {
        summary.writeln('✅ Todas as tabelas essenciais presentes');
      }
    }
    
    final duplicates = results['duplicateTables'] as List<String>?;
    if (duplicates != null && duplicates.isNotEmpty) {
      summary.writeln('⚠️  Tabelas duplicadas: ${duplicates.join(', ')}');
    } else {
      summary.writeln('✅ Nenhuma tabela duplicada');
    }
    
    if (results['pragmaJournalMode'] == true) {
      summary.writeln('✅ Configurações PRAGMA OK');
    } else {
      summary.writeln('❌ Problemas com configurações PRAGMA');
    }
    
    if (results['helperDatabaseOpen'] == true) {
      summary.writeln('✅ DatabaseHelper funcionando');
    } else {
      summary.writeln('❌ Problemas com DatabaseHelper');
    }
    
    if (results.containsKey('testError')) {
      summary.writeln('❌ ERRO GERAL: ${results['testError']}');
    }
    
    summary.writeln('=== FIM DO RESUMO ===');
    
    return summary.toString();
  }
} 