import 'package:shared_preferences/shared_preferences.dart';
import 'culture_import_service.dart';

/// Serviço para inicialização de dados do módulo de Culturas e Pragas
/// Garante que todos os dados padrão sejam carregados na primeira execução
class DataInitializationService {
  static const String _keyDataInitialized = 'data_initialized';
  static const String _keyLastInitialization = 'last_initialization';
  
  final CultureImportService _importService = CultureImportService();

  /// Verifica se os dados já foram inicializados
  Future<bool> isDataInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDataInitialized) ?? false;
    } catch (e) {
      print('❌ Erro ao verificar inicialização: $e');
      return false;
    }
  }

  /// Marca os dados como inicializados
  Future<void> markDataAsInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDataInitialized, true);
      await prefs.setString(_keyLastInitialization, DateTime.now().toIso8601String());
      print('✅ Dados marcados como inicializados');
    } catch (e) {
      print('❌ Erro ao marcar dados como inicializados: $e');
    }
  }

  /// Obtém a data da última inicialização
  Future<DateTime?> getLastInitialization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_keyLastInitialization);
      return dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (e) {
      print('❌ Erro ao obter data da última inicialização: $e');
      return null;
    }
  }

  /// Inicializa todos os dados necessários
  Future<bool> initializeAllData() async {
    try {
      print('🚀 Iniciando inicialização de dados...');
      
      // Verificar se já foi inicializado
      if (await isDataInitialized()) {
        print('ℹ️ Dados já foram inicializados anteriormente');
        return true;
      }

      // Inicializar o serviço de importação
      await _importService.initialize();
      
      // Marcar como inicializado
      await markDataAsInitialized();
      
      print('🎉 Inicialização de dados concluída com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro na inicialização de dados: $e');
      return false;
    }
  }

  /// Força a reinicialização dos dados (útil para desenvolvimento)
  Future<bool> forceReinitialize() async {
    try {
      print('🔄 Forçando reinicialização de dados...');
      
      // Limpar dados existentes
      await _importService.clearAllData();
      
      // Reinicializar
      await _importService.initialize();
      
      // Atualizar timestamp
      await markDataAsInitialized();
      
      print('✅ Reinicialização forçada concluída com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro na reinicialização forçada: $e');
      return false;
    }
  }

  /// Verifica se os dados estão completos
  Future<Map<String, bool>> checkDataCompleteness() async {
    try {
      final stats = await _importService.getStatistics();
      
      return {
        'crops': stats['crops']! > 0,
        'pests': stats['pests']! > 0,
        'diseases': stats['diseases']! > 0,
        'weeds': stats['weeds']! > 0,
        'varieties': stats['varieties']! > 0,
      };
    } catch (e) {
      print('❌ Erro ao verificar completude dos dados: $e');
      return {
        'crops': false,
        'pests': false,
        'diseases': false,
        'weeds': false,
        'varieties': false,
      };
    }
  }

  /// Obtém estatísticas detalhadas dos dados
  Future<Map<String, dynamic>> getDetailedStatistics() async {
    try {
      final stats = await _importService.getStatistics();
      final lastInit = await getLastInitialization();
      final isInitialized = await isDataInitialized();
      
      return {
        'isInitialized': isInitialized,
        'lastInitialization': lastInit?.toIso8601String(),
        'statistics': stats,
        'totalItems': stats.values.reduce((a, b) => a + b),
        'checkDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas detalhadas: $e');
      return {
        'isInitialized': false,
        'lastInitialization': null,
        'statistics': {},
        'totalItems': 0,
        'checkDate': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Exporta todos os dados para backup
  Future<Map<String, dynamic>?> exportAllData() async {
    try {
      print('📤 Exportando todos os dados...');
      final data = await _importService.exportData();
      
      // Adicionar informações de inicialização
      data['initializationInfo'] = {
        'isInitialized': await isDataInitialized(),
        'lastInitialization': (await getLastInitialization())?.toIso8601String(),
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      print('✅ Exportação concluída com sucesso!');
      return data;
    } catch (e) {
      print('❌ Erro na exportação: $e');
      return null;
    }
  }

  /// Valida a integridade dos dados
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    try {
      final stats = await _importService.getStatistics();
      final completeness = await checkDataCompleteness();
      
      // Verificar se todos os tipos de dados estão presentes
      final allComplete = completeness.values.every((complete) => complete);
      
      // Verificar se há dados suficientes
      final hasMinimumData = stats['crops']! >= 5 && 
                           stats['pests']! >= 10 && 
                           stats['diseases']! >= 10 && 
                           stats['weeds']! >= 10;
      
      return {
        'isValid': allComplete && hasMinimumData,
        'completeness': completeness,
        'statistics': stats,
        'hasMinimumData': hasMinimumData,
        'validationDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erro na validação de integridade: $e');
      return {
        'isValid': false,
        'error': e.toString(),
        'validationDate': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Reseta todos os dados (apenas para desenvolvimento)
  Future<bool> resetAllData() async {
    try {
      print('🗑️ Resetando todos os dados...');
      
      // Limpar dados
      await _importService.clearAllData();
      
      // Limpar flags de inicialização
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDataInitialized);
      await prefs.remove(_keyLastInitialization);
      
      print('✅ Reset concluído com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro no reset: $e');
      return false;
    }
  }

  /// Obtém informações de diagnóstico
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final isInitialized = await isDataInitialized();
      final lastInit = await getLastInitialization();
      final stats = await _importService.getStatistics();
      final completeness = await checkDataCompleteness();
      final integrity = await validateDataIntegrity();
      
      return {
        'initialization': {
          'isInitialized': isInitialized,
          'lastInitialization': lastInit?.toIso8601String(),
          'daysSinceLastInit': lastInit != null 
              ? DateTime.now().difference(lastInit).inDays 
              : null,
        },
        'statistics': stats,
        'completeness': completeness,
        'integrity': integrity,
        'diagnosticDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erro ao obter informações de diagnóstico: $e');
      return {
        'error': e.toString(),
        'diagnosticDate': DateTime.now().toIso8601String(),
      };
    }
  }
} 