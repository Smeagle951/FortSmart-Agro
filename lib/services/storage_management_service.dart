import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../repositories/soil_sample_repository.dart';
import '../services/image_management_service.dart';
import '../utils/config.dart';
import '../utils/logger.dart';

/// Estratégia de limpeza de armazenamento
enum StorageCleanupStrategy {
  /// Limpa os arquivos mais antigos primeiro
  oldestFirst,
  
  /// Limpa os arquivos maiores primeiro
  largestFirst,
  
  /// Limpa os arquivos não utilizados
  unusedOnly,
  
  /// Limpa todos os arquivos temporários
  allTemporary
}

/// Serviço responsável pelo gerenciamento de armazenamento do aplicativo
class StorageManagementService {
  static final StorageManagementService _instance = StorageManagementService._internal();
  final SoilSampleRepository _repository = SoilSampleRepository();
  final ImageManagementService _imageService = ImageManagementService();
  
  // Stream para notificar sobre o status do armazenamento
  final _storageStatusController = StreamController<StorageStatus>.broadcast();
  Stream<StorageStatus> get storageStatusStream => _storageStatusController.stream;
  
  bool _isCleaningUp = false;
  
  // Constantes de configuração
  static const double cleanupThresholdMB = 500.0; // Iniciar limpeza quando espaço disponível for menor que 500MB
  static const double lowStorageThresholdMB = 200.0; // Aviso de armazenamento baixo quando menor que 200MB
  static const double criticalStorageThresholdMB = 50.0; // Aviso crítico quando menor que 50MB
  
  // Singleton pattern
  factory StorageManagementService() {
    return _instance;
  }
  
  StorageManagementService._internal();
  
  /// Inicializa o serviço de gerenciamento de armazenamento
  Future<void> initialize() async {
    try {
      // Verificar armazenamento inicial
      await checkStorage();
      
      // Iniciar timer para verificação periódica
      Timer.periodic(Duration(hours: AppConfig.storageCheckIntervalHours), (timer) {
        checkStorage();
      });
      
      Logger.log('Serviço de gerenciamento de armazenamento inicializado');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de armazenamento: $e');
    }
  }
  
  /// Verifica o estado atual do armazenamento
  Future<StorageStatus> checkStorage() async {
    try {
      final status = await _getStorageStatus();
      _storageStatusController.add(status);
      
      // Verificar se é necessário limpar dados antigos
      if (AppConfig.autoCleanupEnabled && status.needsCleanup) {
        await cleanupStorage(StorageCleanupStrategy.oldestFirst);
      }
      
      return status;
    } catch (e) {
      Logger.error('Erro ao verificar armazenamento: $e');
      return StorageStatus(
        totalSpaceMB: 0.0,
        availableSpaceMB: 0.0,
        appDataSizeMB: 0.0,
        databaseSizeMB: 0.0,
        imagesSizeMB: 0.0,
        logsSizeMB: 0.0,
        cacheDataSizeMB: 0.0,
        needsCleanup: false,
        error: e.toString(),
      );
    }
  }
  
  /// Obtém o status atual do armazenamento
  Future<StorageStatus> _getStorageStatus() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      final appDataSizeMB = await _getDirectorySizeMB(appDir.path);
      final dbSizeMB = await _getDatabaseInfo();
      final imagesSizeMB = await _getDirectorySizeMB(path.join(appDir.path, 'images'));
      final logsSizeMB = await _getLogsInfo();
      final cacheSizeMB = await _getDirectorySizeMB(cacheDir.path);
      
      final availableSpaceMB = await _getAvailableStorageSpace();
      final needsCleanup = availableSpaceMB < StorageManagementService.cleanupThresholdMB;
      
      return StorageStatus(
        totalSpaceMB: 0.0, // Não é possível obter com precisão em todas as plataformas
        availableSpaceMB: availableSpaceMB.toDouble(),
        appDataSizeMB: appDataSizeMB,
        databaseSizeMB: dbSizeMB,
        imagesSizeMB: imagesSizeMB,
        logsSizeMB: logsSizeMB,
        cacheDataSizeMB: cacheSizeMB,
        needsCleanup: needsCleanup,
      );
    } catch (e) {
      Logger.error('Erro ao obter status do armazenamento: $e');
      return StorageStatus(
        totalSpaceMB: 0.0,
        availableSpaceMB: 0.0,
        appDataSizeMB: 0.0,
        databaseSizeMB: 0.0,
        imagesSizeMB: 0.0,
        logsSizeMB: 0.0,
        cacheDataSizeMB: 0.0,
        needsCleanup: false,
        error: e.toString(),
      );
    }
  }
  
  /// Calcula o tamanho de um diretório em MB
  Future<double> _getDirectorySizeMB(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return 0.0;
      }
      
      int totalSize = 0;
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize / (1024 * 1024);
    } catch (e) {
      Logger.error('Erro ao calcular tamanho do diretório: $e');
      return 0.0;
    }
  }
  
  /// Limpa dados antigos para liberar espaço
  Future<Map<String, dynamic>> cleanupStorage(StorageCleanupStrategy strategy) async {
    if (_isCleaningUp) {
      return {'status': 'already_running'};
    }
    
    try {
      _isCleaningUp = true;
      Logger.log('Iniciando limpeza de armazenamento usando estratégia: $strategy');
      
      final result = <String, dynamic>{
        'strategy': strategy.toString().split('.').last,
        'cleanedItems': <String, dynamic>{},
      };
      
      // Aplicar estratégia de limpeza
      switch (strategy) {
        case StorageCleanupStrategy.oldestFirst:
          // 1. Limpar amostras sincronizadas antigas
          final cutoffDate = DateTime.now().subtract(Duration(days: AppConfig.oldDataRetentionDays));
          final deletedSamples = await _repository.deleteOldSyncedSamples(cutoffDate);
          result['cleanedItems']['oldSyncedSamples'] = deletedSamples;
          
          // 2. Limpar imagens órfãs
          final deletedImages = await _imageService.cleanupOrphanedImages();
          result['cleanedItems']['orphanedImages'] = deletedImages;
          
          // 3. Limpar logs antigos
          final deletedLogs = await _cleanupOldLogs();
          result['cleanedItems']['oldLogs'] = deletedLogs;
          
          // 4. Limpar cache
          final deletedCache = await _cleanupCache();
          result['cleanedItems']['cache'] = deletedCache;
          break;
          
        case StorageCleanupStrategy.largestFirst:
          // Implementar limpeza baseada em tamanho
          // 1. Primeiro limpar cache
          final deletedCache = await _cleanupCache();
          result['cleanedItems']['cache'] = deletedCache;
          
          // 2. Limpar imagens grandes
          final deletedLargeImages = await _cleanupLargeImages();
          result['cleanedItems']['largeImages'] = deletedLargeImages;
          
          // 3. Limpar logs
          final deletedLogs = await _cleanupOldLogs();
          result['cleanedItems']['oldLogs'] = deletedLogs;
          
          // 4. Limpar amostras sincronizadas
          final cutoffDate = DateTime.now().subtract(Duration(days: AppConfig.oldDataRetentionDays));
          final deletedSamples = await _repository.deleteOldSyncedSamples(cutoffDate);
          result['cleanedItems']['oldSyncedSamples'] = deletedSamples;
          break;
          
        default:
          // Estratégia padrão: limpar cache e imagens órfãs
          final deletedCache = await _cleanupCache();
          result['cleanedItems']['cache'] = deletedCache;
          
          final deletedImages = await _imageService.cleanupOrphanedImages();
          result['cleanedItems']['orphanedImages'] = deletedImages;
      }
      
      // Verificar armazenamento após limpeza
      final newStatus = await checkStorage();
      result['afterCleanup'] = newStatus.toMap();
      
      Logger.log('Limpeza de armazenamento concluída');
      return result;
    } catch (e) {
      Logger.error('Erro durante limpeza de armazenamento: $e');
      return {'error': e.toString()};
    } finally {
      _isCleaningUp = false;
    }
  }
  
  /// Limpa logs antigos
  Future<int> _cleanupOldLogs() async {
    try {
      final logsDir = Directory(AppConfig.logsPath);
      if (!await logsDir.exists()) {
        return 0;
      }
      
      final now = DateTime.now();
      final files = await logsDir.list().toList();
      int removedCount = 0;
      
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.txt')) {
          // Verificar idade do arquivo
          final stat = await entity.stat();
          final fileAge = now.difference(stat.modified).inDays;
          
          // Remover logs antigos (mais de 7 dias)
          if (fileAge > 7) {
            await entity.delete();
            removedCount++;
          }
        }
      }
      
      return removedCount;
    } catch (e) {
      Logger.error('Erro ao limpar logs antigos: $e');
      return 0;
    }
  }
  
  /// Limpa arquivos de cache
  Future<int> _cleanupCache() async {
    try {
      final cacheDir = Directory(AppConfig.cachePath);
      if (!await cacheDir.exists()) {
        return 0;
      }
      
      final files = await cacheDir.list().toList();
      int removedCount = 0;
      
      for (final entity in files) {
        if (entity is File) {
          await entity.delete();
          removedCount++;
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
          removedCount++;
        }
      }
      
      return removedCount;
    } catch (e) {
      Logger.error('Erro ao limpar cache: $e');
      return 0;
    }
  }
  
  /// Limpa imagens grandes
  Future<int> _cleanupLargeImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      
      if (!await photoDir.exists()) {
        return 0;
      }
      
      final largeFiles = await photoDir
          .list()
          .where((entity) => entity is File && 
                  path.extension(entity.path).toLowerCase() == '.jpg' || 
                  path.extension(entity.path).toLowerCase() == '.jpeg')
          .toList();
      
      // Precisamos coletar os tamanhos de forma assíncrona antes de ordenar
      List<Map<String, dynamic>> filesWithSize = [];
      for (var entity in largeFiles) {
        if (entity is File) {
          int size = await entity.length();
          filesWithSize.add({
            'file': entity,
            'size': size
          });
        }
      }
      
      // Agora ordenamos usando os tamanhos já obtidos
      filesWithSize.sort((a, b) => b['size'].compareTo(a['size']));
      
      int removedCount = 0;
      
      // Processar apenas as 20 maiores imagens
      for (int i = 0; i < min(20, filesWithSize.length); i++) {
        final file = filesWithSize[i]['file'] as File;
        final originalSize = filesWithSize[i]['size'] as int;
        
        if (originalSize < 500 * 1024) { // Ignorar arquivos menores que 500KB
          continue;
        }
        
        try {
          // Comprimir a imagem
          final result = await _imageService.processImage(
            photoFile: file,
            compress: true,
            quality: 70, // Qualidade mais baixa para economizar espaço
            maxWidth: 1280,
            maxHeight: 1280,
          );
          
          if (result['success'] == true) {
            // Substituir arquivo original pelo comprimido
            final compressedFile = File(result['path']);
            final compressedSize = await compressedFile.length();
            
            if (compressedSize < originalSize) {
              await file.delete();
              await compressedFile.copy(file.path);
              await compressedFile.delete();
              removedCount++;
            }
          }
        } catch (e) {
          Logger.error('Erro ao comprimir imagem grande: $e');
        }
      }
      
      return removedCount;
    } catch (e) {
      Logger.error('Erro ao limpar imagens grandes: $e');
      return 0;
    }
  }
  
  /// Verifica se há espaço suficiente para uma operação
  Future<bool> hasEnoughSpaceForOperation(double requiredSpaceMB) async {
    try {
      final status = await checkStorage();
      return status.availableSpaceMB >= requiredSpaceMB;
    } catch (e) {
      Logger.error('Erro ao verificar espaço disponível: $e');
      return false;
    }
  }
  
  /// Limpa o diretório temporário
  Future<int> cleanupTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir.list().toList();
      int removedCount = 0;
      
      for (final entity in files) {
        try {
          if (entity is File) {
            await entity.delete();
            removedCount++;
          } else if (entity is Directory && path.basename(entity.path) != 'cache') {
            await entity.delete(recursive: true);
            removedCount++;
          }
        } catch (e) {
          // Ignorar erros individuais
          Logger.log('Não foi possível excluir ${entity.path}: $e');
        }
      }
      
      return removedCount;
    } catch (e) {
      Logger.error('Erro ao limpar diretório temporário: $e');
      return 0;
    }
  }
  
  /// Obtém informações detalhadas sobre o armazenamento
  Future<Map<String, dynamic>> getDetailedStorageInfo() async {
    try {
      final totalSpace = await _getTotalStorageSpace();
      final availableSpace = await _getAvailableStorageSpace();
      
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      final appDirStats = await _getDirStats(appDir.path);
      final tempDirStats = await _getDirStats(tempDir.path);
      final cacheDirStats = await _getDirStats(cacheDir.path);
      
      final databaseInfo = await _getDatabaseInfo();
      final logsInfo = await _getLogsInfo();
      final cacheInfo = await _getCacheInfo();
      
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'device': {
          'totalStorageMB': totalSpace.toDouble(),
          'availableStorageMB': availableSpace.toDouble(),
          'usedPercentage': ((totalSpace - availableSpace) / totalSpace * 100).toDouble(),
        },
        'app': {
          'totalSizeMB': appDirStats.toDouble(),
          'databases': databaseInfo,
          'logs': logsInfo,
          'cache': cacheInfo,
          'directories': {
            'appSizeMB': appDirStats.toDouble(),
            'tempSizeMB': tempDirStats.toDouble(),
            'cacheSizeMB': cacheDirStats.toDouble(),
          }
        },
        'status': {
          'needsCleanup': availableSpace < StorageManagementService.cleanupThresholdMB,
          'lowStorage': availableSpace < StorageManagementService.lowStorageThresholdMB,
          'criticalStorage': availableSpace < StorageManagementService.criticalStorageThresholdMB,
        }
      };
      
      // Adicionar contagem de registros do banco de dados se disponível
      try {
        result['recordCounts'] = await _repository.getTableRecordCounts();
      } catch (e) {
        Logger.error('Erro ao obter contagem de registros: $e');
      }
      
      return result;
    } catch (e) {
      Logger.error('Erro ao obter informações detalhadas de armazenamento: $e');
      return {
        'error': e.toString(),
        'storage': {
          'totalSpaceMB': 0.0,
          'availableSpaceMB': 0.0,
          'usedSpaceMB': 0.0,
        }
      };
    }
  }
  
  /// Obtém informações sobre o banco de dados
  Future<double> _getDatabaseInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(path.join(appDir.path, 'databases'));
      
      if (!dbDir.existsSync()) {
        return 0.0;
      }
      
      return await _getDirectorySizeMB(dbDir.path);
    } catch (e) {
      Logger.error('Erro ao obter informações do banco de dados: $e');
      return 0.0;
    }
  }
  
  /// Obtém informações sobre os logs
  Future<double> _getLogsInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!logsDir.existsSync()) {
        return 0.0;
      }
      
      return await _getDirectorySizeMB(logsDir.path);
    } catch (e) {
      Logger.error('Erro ao obter informações dos logs: $e');
      return 0.0;
    }
  }
  
  /// Obtém informações sobre o cache
  Future<Map<String, dynamic>> _getCacheInfo() async {
    try {
      final result = <String, dynamic>{};
      
      final cacheDir = Directory(AppConfig.cachePath);
      if (!await cacheDir.exists()) {
        return {'count': 0, 'sizeMB': 0.0};
      }
      
      int fileCount = 0;
      int totalSize = 0;
      
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }
      
      result['count'] = fileCount;
      result['sizeMB'] = totalSize / (1024 * 1024);
      
      return result;
    } catch (e) {
      Logger.error('Erro ao obter informações do cache: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Verifica o status do armazenamento do dispositivo
  Future<StorageStatus> checkStorageStatus() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      final appDirStats = await _getDirStats(appDir.path);
      final tempDirStats = await _getDirStats(tempDir.path);
      final cacheDirStats = await _getDirStats(cacheDir.path);
      
      final availableSpace = await _getAvailableStorageSpace();
      final totalSpace = await _getTotalStorageSpace();
      
      return StorageStatus(
        totalSpaceMB: totalSpace.toDouble(),
        availableSpaceMB: availableSpace.toDouble(),
        appDataSizeMB: appDirStats.toDouble(),
        databaseSizeMB: await _getDatabaseInfo(),
        imagesSizeMB: await _getDirectorySizeMB(path.join(appDir.path, 'images')),
        logsSizeMB: await _getLogsInfo(),
        cacheDataSizeMB: cacheDirStats.toDouble(),
        needsCleanup: availableSpace < StorageManagementService.cleanupThresholdMB,
      );
    } catch (e) {
      Logger.error('Erro ao verificar status do armazenamento: $e');
      return StorageStatus(
        totalSpaceMB: 0.0,
        availableSpaceMB: 0.0,
        appDataSizeMB: 0.0,
        databaseSizeMB: 0.0,
        imagesSizeMB: 0.0,
        logsSizeMB: 0.0,
        cacheDataSizeMB: 0.0,
        needsCleanup: false,
        error: e.toString(),
      );
    }
  }
  
  /// Obtém o tamanho total do armazenamento em MB
  Future<double> _getTotalStorageSpace() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await FileStat.stat(appDir.path);
      // Como não há uma API direta para obter o espaço total, usamos uma estimativa
      return 32 * 1024; // 32 GB como valor padrão
    } catch (e) {
      Logger.error('Erro ao obter espaço total: $e');
      return 0.0;
    }
  }
  
  /// Obtém o espaço disponível em MB
  Future<double> _getAvailableStorageSpace() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);
      
      // Em sistemas mais recentes, podemos usar o pacote disk_space
      // Por enquanto, usamos uma estimativa baseada no diretório da aplicação
      final stat = await FileStat.stat(appDir.path);
      
      // Valor estimado - em uma implementação real, usaríamos APIs específicas da plataforma
      return 1024; // 1 GB como valor padrão
    } catch (e) {
      Logger.error('Erro ao obter espaço disponível: $e');
      return 0.0;
    }
  }
  
  /// Calcula o tamanho de um diretório em MB
  Future<double> _getDirStats(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return 0.0;
      }
      
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize / (1024 * 1024); // Converter para MB
    } catch (e) {
      Logger.error('Erro ao calcular tamanho do diretório $dirPath: $e');
      return 0.0;
    }
  }
  
  /// Encerra o serviço de gerenciamento de armazenamento
  void dispose() {
    _storageStatusController.close();
  }
}

/// Classe para representar o status do armazenamento
class StorageStatus {
  final double totalSpaceMB;
  final double availableSpaceMB;
  final double appDataSizeMB;
  final double databaseSizeMB;
  final double imagesSizeMB;
  final double logsSizeMB;
  final double cacheDataSizeMB;
  final bool needsCleanup;
  final String? error;
  
  StorageStatus({
    required this.totalSpaceMB,
    required this.availableSpaceMB,
    required this.appDataSizeMB,
    required this.databaseSizeMB,
    required this.imagesSizeMB,
    required this.logsSizeMB,
    required this.cacheDataSizeMB,
    required this.needsCleanup,
    this.error,
  });
  
  /// Converte o status para um mapa
  Map<String, dynamic> toMap() {
    return {
      'totalSpaceMB': totalSpaceMB,
      'availableSpaceMB': availableSpaceMB,
      'appDataSizeMB': appDataSizeMB,
      'databaseSizeMB': databaseSizeMB,
      'imagesSizeMB': imagesSizeMB,
      'logsSizeMB': logsSizeMB,
      'cacheDataSizeMB': cacheDataSizeMB,
      'needsCleanup': needsCleanup,
      'error': error,
    };
  }
  
  @override
  String toString() {
    return 'StorageStatus: ${toMap()}';
  }
}
