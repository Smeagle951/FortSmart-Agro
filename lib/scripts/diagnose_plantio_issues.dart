import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Script para diagnosticar problemas no módulo de plantio SEM ALTERAR DADOS
class DiagnosePlantioIssues {
  static Future<void> diagnose() async {
    try {
      print('🔍 DIAGNÓSTICO: Analisando problemas no módulo de plantio...');
      
      // Obter diretório do banco
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'fortsmart_agro.db');
      
      final db = await openDatabase(path);
      
      // 1. Verificar se tabela plantios existe
      print('\n📋 1. VERIFICANDO TABELA PLANTIOS:');
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantios'"
      );
      
      if (tables.isEmpty) {
        print('❌ PROBLEMA: Tabela plantios não existe!');
        return;
      }
      print('✅ Tabela plantios existe');
      
      // 2. Verificar estrutura da tabela
      print('\n📊 2. ESTRUTURA DA TABELA PLANTIOS:');
      final columns = await db.rawQuery("PRAGMA table_info(plantios)");
      final existingColumns = columns.map((col) => col['name'] as String).toSet();
      print('Colunas existentes: ${existingColumns.join(', ')}');
      
      // 3. Verificar dados na tabela
      print('\n📈 3. DADOS NA TABELA:');
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM plantios');
      final recordCount = count.first['count'] as int;
      print('Total de registros: $recordCount');
      
      if (recordCount > 0) {
        // Mostrar alguns registros de exemplo
        final sample = await db.rawQuery('SELECT * FROM plantios LIMIT 3');
        print('Exemplos de registros:');
        for (int i = 0; i < sample.length; i++) {
          print('  Registro ${i + 1}: ${sample[i]}');
        }
      }
      
      // 4. Verificar integridade referencial
      print('\n🔗 4. VERIFICANDO INTEGRIDADE REFERENCIAL:');
      
      // Verificar se há registros órfãos (sem talhão válido)
      try {
        final orphanRecords = await db.rawQuery('''
          SELECT COUNT(*) as count FROM plantios p 
          LEFT JOIN talhoes t ON p.talhao_id = t.id 
          WHERE t.id IS NULL
        ''');
        final orphanCount = orphanRecords.first['count'] as int;
        print('Registros órfãos (sem talhão válido): $orphanCount');
        
        if (orphanCount > 0) {
          print('⚠️ PROBLEMA: Existem registros órfãos na tabela plantios');
        } else {
          print('✅ Todos os registros têm talhão válido');
        }
      } catch (e) {
        print('⚠️ Erro ao verificar integridade: $e');
      }
      
      // 5. Verificar índices
      print('\n📇 5. VERIFICANDO ÍNDICES:');
      final indexes = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='plantios'");
      final existingIndexes = indexes.map((idx) => idx['name'] as String).toSet();
      print('Índices existentes: ${existingIndexes.join(', ')}');
      
      // 6. Verificar problemas comuns
      print('\n🔧 6. PROBLEMAS COMUNS:');
      
      // Verificar se há colunas com nomes inconsistentes
      final problematicColumns = ['talhaold', 'culturald', 'variedadeld', 'safrald', 'usuariold'];
      final hasOldColumns = problematicColumns.any((col) => existingColumns.contains(col));
      
      if (hasOldColumns) {
        print('⚠️ PROBLEMA: Tabela tem colunas com nomes antigos (talhaold, culturald, etc.)');
        print('   Isso pode causar problemas de compatibilidade');
      } else {
        print('✅ Estrutura da tabela parece correta');
      }
      
      // 7. Verificar se há dados corrompidos
      print('\n🔍 7. VERIFICANDO DADOS CORROMPIDOS:');
      try {
        final corruptedData = await db.rawQuery('''
          SELECT COUNT(*) as count FROM plantios 
          WHERE id IS NULL OR talhao_id IS NULL OR data_plantio IS NULL
        ''');
        final corruptedCount = corruptedData.first['count'] as int;
        print('Registros com dados corrompidos: $corruptedCount');
        
        if (corruptedCount > 0) {
          print('⚠️ PROBLEMA: Existem registros com dados nulos obrigatórios');
        } else {
          print('✅ Dados parecem íntegros');
        }
      } catch (e) {
        print('⚠️ Erro ao verificar dados corrompidos: $e');
      }
      
      print('\n✅ DIAGNÓSTICO CONCLUÍDO!');
      print('📋 RESUMO:');
      print('  - Tabela plantios: ${tables.isNotEmpty ? "EXISTE" : "NÃO EXISTE"}');
      print('  - Registros: $recordCount');
      print('  - Colunas: ${existingColumns.length}');
      print('  - Índices: ${existingIndexes.length}');
      
    } catch (e) {
      print('❌ Erro durante diagnóstico: $e');
    }
  }
}
