import 'package:flutter/material.dart';
import '../services/unified_database_service.dart';
import '../utils/logger.dart';

/// Classe responsável por inicializar o banco de dados na inicialização do aplicativo
class DatabaseStartup {
  final UnifiedDatabaseService _unifiedService = UnifiedDatabaseService();

  /// Inicializa o banco de dados
  Future<bool> initialize() async {
    try {
      debugPrint('DatabaseStartup: Iniciando inicialização do banco de dados');
      Logger.info('🚀 DatabaseStartup: Iniciando inicialização...');
      
      // Usar o serviço unificado
      final success = await _unifiedService.initialize();
      
      if (success) {
        debugPrint('DatabaseStartup: Inicialização do banco de dados concluída com sucesso');
        Logger.info('✅ DatabaseStartup: Inicialização concluída com sucesso');
        return true;
      } else {
        debugPrint('DatabaseStartup: Falha na inicialização do banco de dados');
        Logger.error('❌ DatabaseStartup: Falha na inicialização');
        return false;
      }
    } catch (e) {
      debugPrint('DatabaseStartup: Erro durante a inicialização do banco de dados: $e');
      Logger.error('❌ DatabaseStartup: Erro durante inicialização: $e');
      return false;
    }
  }

  /// Verifica se o banco está saudável
  Future<bool> isHealthy() async {
    try {
      return await _unifiedService.isHealthy();
    } catch (e) {
      Logger.error('❌ Erro ao verificar saúde do banco: $e');
      return false;
    }
  }

  /// Força reinicialização
  Future<bool> forceReinitialize() async {
    try {
      await _unifiedService.forceReinitialize();
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao forçar reinicialização: $e');
      return false;
    }
  }

  /// Obtém status do banco
  Map<String, dynamic> getStatus() {
    return _unifiedService.getStatus();
  }
}

/// Função para inicializar o banco de dados na inicialização do aplicativo
Future<void> initializeDatabaseOnStartup() async {
  try {
    final startup = DatabaseStartup();
    await startup.initialize();
  } catch (e) {
    debugPrint('Erro ao inicializar banco de dados: $e');
  }
}
