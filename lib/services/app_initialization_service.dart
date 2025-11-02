import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import '../repositories/soil_sample_repository.dart';
import '../services/connectivity_monitor_service.dart';
import '../services/database_integrity_service.dart';
import '../services/image_management_service.dart';
import '../services/soil_sample_sync_service.dart';
import '../services/storage_management_service.dart';
import '../services/sync_recovery_service.dart';
import '../utils/config.dart';
import '../utils/logger.dart';

/// Serviço responsável pela inicialização coordenada da aplicação
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  
  // Serviços gerenciados
  final DatabaseIntegrityService _dbIntegrityService = DatabaseIntegrityService();
  final SoilSampleRepository _repository = SoilSampleRepository();
  final SoilSampleSyncService _syncService = SoilSampleSyncService();
  final ConnectivityMonitorService _connectivityService = ConnectivityMonitorService();
  final StorageManagementService _storageService = StorageManagementService();
  final SyncRecoveryService _recoveryService = SyncRecoveryService();
  final ImageManagementService _imageService = ImageManagementService();
  
  // Status de inicialização
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;
  
  // Stream para notificar sobre o progresso da inicialização
  final _initProgressController = StreamController<InitializationProgress>.broadcast();
  Stream<InitializationProgress> get initProgressStream => _initProgressController.stream;
  
  // Singleton pattern
  factory AppInitializationService() {
    return _instance;
  }
  
  AppInitializationService._internal();
  
  /// Inicializa todos os serviços da aplicação de forma coordenada
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      // Aguardar até que a inicialização atual termine
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return _isInitializing;
      });
      return _isInitialized;
    }
    
    try {
      _isInitializing = true;
      _initializationError = null;
      
      // 1. Inicializar configurações
      _updateProgress(InitStep.config, 0, 'Inicializando configurações');
      await AppConfig.initialize();
      _updateProgress(InitStep.config, 100, 'Configurações inicializadas');
      
      // 2. Verificar armazenamento disponível
      _updateProgress(InitStep.storage, 0, 'Verificando armazenamento');
      final hasEnoughSpace = await AppConfig.hasEnoughStorage();
      if (!hasEnoughSpace) {
        throw Exception('Espaço insuficiente para inicializar o aplicativo');
      }
      _updateProgress(InitStep.storage, 100, 'Armazenamento verificado');
      
      // 3. Verificar e reparar integridade do banco de dados
      _updateProgress(InitStep.databaseIntegrity, 0, 'Verificando integridade do banco de dados');
      
      // Verificar se o banco de dados está corrompido
      final isCorrupted = await DatabaseCleanup.isDatabaseCorrupted();
      if (isCorrupted) {
        _updateProgress(InitStep.databaseIntegrity, 25, 'Banco de dados corrompido detectado');
        Logger.warning('Banco de dados corrompido detectado, iniciando limpeza automática');
        
        // Limpar e recriar o banco de dados
        final cleaned = await DatabaseCleanup.forceRecreateDatabase();
        if (!cleaned) {
          Logger.error('Falha ao limpar banco de dados corrompido');
          throw Exception('Falha ao limpar banco de dados corrompido');
        }
        
        _updateProgress(InitStep.databaseIntegrity, 50, 'Banco de dados limpo e recriado');
      }
      
      // Verificar integridade normal
      if (AppConfig.verifyDbIntegrityOnStartup) {
        final isIntegrityOk = await _dbIntegrityService.checkDatabaseIntegrity();
        if (!isIntegrityOk && AppConfig.autoRepairDb) {
          _updateProgress(InitStep.databaseIntegrity, 75, 'Reparando banco de dados');
          final repaired = await _dbIntegrityService.repairDatabase();
          if (!repaired) {
            Logger.error('Falha ao reparar banco de dados');
            throw Exception('Falha ao reparar banco de dados');
          }
        }
      }
      _updateProgress(InitStep.databaseIntegrity, 100, 'Integridade do banco de dados verificada');
      
      // 4. Inicializar repositório
      _updateProgress(InitStep.repository, 0, 'Inicializando repositório');
      await _repository.initialize();
      _updateProgress(InitStep.repository, 100, 'Repositório inicializado');
      
      // 5. Inicializar serviço de monitoramento de conectividade
      _updateProgress(InitStep.connectivity, 0, 'Inicializando monitoramento de conectividade');
      await _connectivityService.initialize();
      _updateProgress(InitStep.connectivity, 100, 'Monitoramento de conectividade inicializado');
      
      // 6. Inicializar serviço de gerenciamento de armazenamento
      _updateProgress(InitStep.storageManagement, 0, 'Inicializando gerenciamento de armazenamento');
      await _storageService.initialize();
      _updateProgress(InitStep.storageManagement, 100, 'Gerenciamento de armazenamento inicializado');
      
      // 7. Inicializar serviço de recuperação de sincronização
      _updateProgress(InitStep.recovery, 0, 'Inicializando serviço de recuperação');
      await _recoveryService.initialize();
      _updateProgress(InitStep.recovery, 100, 'Serviço de recuperação inicializado');
      
      // 8. Iniciar monitoramento de sincronização
      _updateProgress(InitStep.sync, 0, 'Inicializando serviço de sincronização');
      _syncService.startMonitoring();
      _updateProgress(InitStep.sync, 100, 'Serviço de sincronização inicializado');
      
      // Inicialização concluída com sucesso
      _isInitialized = true;
      _isInitializing = false;
      _updateProgress(InitStep.completed, 100, 'Inicialização concluída com sucesso');
      
      Logger.log('Inicialização da aplicação concluída com sucesso');
      return true;
    } catch (e) {
      _isInitialized = false;
      _isInitializing = false;
      _initializationError = e.toString();
      
      _updateProgress(InitStep.error, 0, 'Erro durante inicialização: $e');
      Logger.error('Erro durante inicialização da aplicação: $e');
      
      // Tentar inicialização de emergência
      await _emergencyInitialization();
      
      return false;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Tenta uma inicialização de emergência com funcionalidades limitadas
  Future<void> _emergencyInitialization() async {
    try {
      Logger.log('Tentando inicialização de emergência');
      _updateProgress(InitStep.emergency, 0, 'Tentando inicialização de emergência');
      
      // 1. Tentar criar/verificar diretórios essenciais
      await _ensureDirectoriesExist();
      
      // 2. Tentar inicializar repositório com modo de emergência
      await _repository.initializeEmergencyMode();
      
      // 3. Inicializar serviço de conectividade (básico)
      await _connectivityService.initialize();
      
      _updateProgress(InitStep.emergency, 100, 'Inicialização de emergência concluída');
      Logger.log('Inicialização de emergência concluída');
    } catch (e) {
      Logger.error('Falha na inicialização de emergência: $e');
      _updateProgress(InitStep.emergencyFailed, 0, 'Falha na inicialização de emergência: $e');
    }
  }
  
  /// Garante que os diretórios essenciais existam
  Future<void> _ensureDirectoriesExist() async {
    try {
      final dirs = [
        AppConfig.documentsPath,
        AppConfig.tempPath,
        AppConfig.backupsPath,
        AppConfig.imagesPath,
        AppConfig.logsPath,
        AppConfig.cachePath,
      ];
      
      for (final dir in dirs) {
        final directory = Directory(dir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }
    } catch (e) {
      Logger.error('Erro ao criar diretórios essenciais: $e');
    }
  }
  
  /// Atualiza o progresso da inicialização
  void _updateProgress(InitStep step, int percentComplete, String message) {
    final progress = InitializationProgress(
      step: step,
      percentComplete: percentComplete,
      message: message,
      timestamp: DateTime.now(),
    );
    
    _initProgressController.add(progress);
  }
  
  /// Verifica se a aplicação está inicializada
  bool get isInitialized => _isInitialized;
  
  /// Obtém o erro de inicialização, se houver
  String? get initializationError => _initializationError;
  
  /// Reinicia a aplicação (limpa cache e reinicia serviços)
  Future<bool> restart() async {
    try {
      Logger.log('Reiniciando aplicação');
      
      // Parar serviços
      _syncService.stopMonitoring();
      
      // Limpar cache
      await _storageService._cleanupCache();
      
      // Reiniciar
      return await initialize();
    } catch (e) {
      Logger.error('Erro ao reiniciar aplicação: $e');
      return false;
    }
  }
  
  /// Realiza uma verificação completa do sistema
  Future<Map<String, dynamic>> performSystemCheck() async {
    try {
      final result = <String, dynamic>{};
      
      // 1. Verificar integridade do banco de dados
      result['databaseIntegrity'] = await _dbIntegrityService.checkDatabaseIntegrity();
      
      // 2. Verificar armazenamento
      result['storage'] = (await _storageService.checkStorage()).toMap();
      
      // 3. Verificar conectividade
      result['connectivity'] = (await _connectivityService.isOnline()) 
          ? 'online' 
          : 'offline';
      
      // 4. Verificar estatísticas de sincronização
      result['syncStats'] = await _syncService.getSyncStats();
      
      return result;
    } catch (e) {
      Logger.error('Erro ao realizar verificação do sistema: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Encerra todos os serviços
  void dispose() {
    _initProgressController.close();
    _syncService.stopMonitoring();
    _connectivityService.dispose();
    _storageService.dispose();
  }
}

class SoilSampleRepository {
}

/// Enum para definir as etapas de inicialização
enum InitStep {
  config,
  storage,
  databaseIntegrity,
  repository,
  connectivity,
  storageManagement,
  recovery,
  sync,
  completed,
  error,
  emergency,
  emergencyFailed,
}

/// Classe para representar o progresso da inicialização
class InitializationProgress {
  final InitStep step;
  final int percentComplete;
  final String message;
  final DateTime timestamp;
  
  InitializationProgress({
    required this.step,
    required this.percentComplete,
    required this.message,
    required this.timestamp,
  });
  
  /// Converte o progresso para um mapa
  Map<String, dynamic> toMap() {
    return {
      'step': step.toString().split('.').last,
      'percentComplete': percentComplete,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'InitializationProgress: ${toMap()}';
  }
}
