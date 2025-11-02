import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../services/germination_model_integration_service.dart';
import '../utils/logger.dart';

/// Utilitário para diagnosticar e corrigir problemas de banco de dados
class DatabaseDiagnosticHelper {
  static final AppDatabase _appDatabase = AppDatabase();
  static final GerminationModelIntegrationService _germinationService = GerminationModelIntegrationService();

  /// Diagnostica e corrige problemas com a tabela de testes de germinação
  static Future<Map<String, dynamic>> diagnoseAndFixGerminationTable() async {
    try {
      Logger.info('🔍 Iniciando diagnóstico da tabela de testes de germinação...');
      
      // 1. Diagnóstico inicial
      final diagnosis = await _germinationService.diagnoseCompatibilityTable();
      Logger.info('📊 Diagnóstico inicial: $diagnosis');
      
      // 2. Se há problemas, tentar corrigir
      if (diagnosis['status'] == 'error') {
        Logger.warning('⚠️ Problema detectado: ${diagnosis['message']}');
        
        if (diagnosis['message'].toString().contains('não existe')) {
          Logger.info('🔧 Criando tabela de compatibilidade...');
          await _germinationService.createCompatibilityTable();
          
          // Verificar novamente
          final newDiagnosis = await _germinationService.diagnoseCompatibilityTable();
          return {
            'status': 'fixed',
            'original_problem': diagnosis,
            'fix_applied': 'Tabela criada',
            'new_diagnosis': newDiagnosis,
            'message': 'Problema corrigido com sucesso'
          };
        }
      }
      
      // 3. Se a tabela existe mas falta a coluna 'tipo'
      if (diagnosis['status'] == 'success' && diagnosis['has_tipo_column'] == false) {
        Logger.warning('⚠️ Tabela existe mas falta coluna "tipo"');
        Logger.info('🔧 Recriando tabela com coluna "tipo"...');
        
        await _germinationService.recreateCompatibilityTable();
        
        // Verificar novamente
        final newDiagnosis = await _germinationService.diagnoseCompatibilityTable();
        return {
          'status': 'fixed',
          'original_problem': diagnosis,
          'fix_applied': 'Tabela recriada com coluna "tipo"',
          'new_diagnosis': newDiagnosis,
          'message': 'Problema corrigido com sucesso'
        };
      }
      
      // 4. Se tudo está OK
      return {
        'status': 'ok',
        'diagnosis': diagnosis,
        'message': 'Tabela está funcionando corretamente'
      };
      
    } catch (e) {
      Logger.error('❌ Erro durante diagnóstico: $e');
      return {
        'status': 'error',
        'message': 'Erro durante diagnóstico: $e'
      };
    }
  }

  /// Força a correção completa da tabela de testes de germinação
  static Future<Map<String, dynamic>> forceFixGerminationTable() async {
    try {
      Logger.warning('🔧 Forçando correção da tabela de testes de germinação...');
      
      // Sempre recriar a tabela para garantir que está correta
      await _germinationService.recreateCompatibilityTable();
      
      // Verificar se a correção funcionou
      final diagnosis = await _germinationService.diagnoseCompatibilityTable();
      
      return {
        'status': diagnosis['has_tipo_column'] == true ? 'success' : 'error',
        'diagnosis': diagnosis,
        'message': diagnosis['has_tipo_column'] == true 
          ? 'Tabela corrigida com sucesso'
          : 'Falha ao corrigir tabela'
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao forçar correção: $e');
      return {
        'status': 'error',
        'message': 'Erro ao forçar correção: $e'
      };
    }
  }

  /// Verifica a integridade geral do banco de dados
  static Future<Map<String, dynamic>> checkDatabaseIntegrity() async {
    try {
      final database = await _appDatabase.database;
      
      // Verificar tabelas importantes
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((table) => table['name'] as String).toList();
      
      // Verificar tabelas específicas
      final hasGerminationTests = tableNames.contains('germination_tests');
      final hasGerminationTestsLegacy = tableNames.contains('germination_tests_legacy');
      
      return {
        'status': 'success',
        'total_tables': tableNames.length,
        'table_names': tableNames,
        'has_germination_tests': hasGerminationTests,
        'has_germination_tests_legacy': hasGerminationTestsLegacy,
        'message': 'Verificação de integridade concluída'
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Erro ao verificar integridade: $e'
      };
    }
  }
}
