import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Serviço de backup automático para talhões
class AutomaticBackupService {
  static final AutomaticBackupService _instance = AutomaticBackupService._internal();
  factory AutomaticBackupService() => _instance;
  AutomaticBackupService._internal();
  
  Timer? _backupTimer;
  Timer? _cleanupTimer;
  bool _isBackingUp = false;
  
  // Configurações
  static const Duration _backupInterval = Duration(hours: 6); // Backup a cada 6 horas
  static const Duration _cleanupInterval = Duration(days: 1); // Limpeza diária
  static const int _maxBackups = 30; // Manter últimos 30 backups
  static const String _backupPrefix = 'talhoes_backup_';
  static const String _backupExtension = '.json';
  
  /// Inicializa o serviço de backup automático
  Future<void> initialize() async {
    try {
      Logger.info('🔄 [BACKUP] Inicializando serviço de backup automático...');
      
      // Verificar se o backup automático está habilitado
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('backup_automatico_habilitado') ?? true;
      
      if (isEnabled) {
        await _startAutomaticBackup();
        await _startCleanupTimer();
        Logger.info('✅ [BACKUP] Serviço de backup automático inicializado');
      } else {
        Logger.info('ℹ️ [BACKUP] Backup automático desabilitado');
      }
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao inicializar serviço de backup: $e');
    }
  }
  
  /// Inicia o timer de backup automático
  Future<void> _startAutomaticBackup() async {
    _backupTimer?.cancel();
    
    _backupTimer = Timer.periodic(_backupInterval, (timer) async {
      await performBackup();
    });
    
    Logger.info('⏰ [BACKUP] Timer de backup configurado para ${_backupInterval.inHours} horas');
  }
  
  /// Inicia o timer de limpeza
  Future<void> _startCleanupTimer() async {
    _cleanupTimer?.cancel();
    
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) async {
      await _cleanupOldBackups();
    });
    
    Logger.info('🧹 [BACKUP] Timer de limpeza configurado para ${_cleanupInterval.inDays} dias');
  }
  
  /// Executa backup manual
  Future<bool> performBackup() async {
    if (_isBackingUp) {
      Logger.warning('⚠️ [BACKUP] Backup já em andamento, ignorando...');
      return false;
    }
    
    try {
      _isBackingUp = true;
      Logger.info('🔄 [BACKUP] Iniciando backup automático...');
      
      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      // Criar diretório se não existir
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Gerar nome do arquivo de backup
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('${backupDir.path}/$_backupPrefix$timestamp$_backupExtension');
      
      // Criar dados de backup
      final backupData = await _createBackupData();
      
      // Salvar arquivo de backup
      await backupFile.writeAsString(jsonEncode(backupData));
      
      // Salvar metadados do backup
      await _saveBackupMetadata(backupFile.path, backupData);
      
      Logger.info('✅ [BACKUP] Backup concluído: ${backupFile.path}');
      return true;
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro durante backup: $e');
      return false;
    } finally {
      _isBackingUp = false;
    }
  }
  
  /// Cria dados de backup
  Future<Map<String, dynamic>> _createBackupData() async {
    try {
      // Aqui você deve integrar com o serviço de talhões para obter os dados
      // Por enquanto, criamos uma estrutura de exemplo
      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
        'talhoes': [], // Será preenchido com dados reais
        'culturas': [], // Será preenchido com dados reais
        'safras': [], // Será preenchido com dados reais
        'metadata': {
          'total_talhoes': 0,
          'total_area': 0.0,
          'backup_type': 'automatic',
        },
      };
      
      return backupData;
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao criar dados de backup: $e');
      return {};
    }
  }
  
  /// Salva metadados do backup
  Future<void> _saveBackupMetadata(String filePath, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupList = prefs.getStringList('backup_list') ?? [];
      
      final metadata = {
        'file_path': filePath,
        'timestamp': data['timestamp'],
        'total_talhoes': data['metadata']['total_talhoes'],
        'total_area': data['metadata']['total_area'],
        'size': await File(filePath).length(),
      };
      
      backupList.add(jsonEncode(metadata));
      
      // Manter apenas os últimos backups
      if (backupList.length > _maxBackups) {
        backupList.removeRange(0, backupList.length - _maxBackups);
      }
      
      await prefs.setStringList('backup_list', backupList);
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao salvar metadados: $e');
    }
  }
  
  /// Limpa backups antigos
  Future<void> _cleanupOldBackups() async {
    try {
      Logger.info('🧹 [BACKUP] Iniciando limpeza de backups antigos...');
      
      final prefs = await SharedPreferences.getInstance();
      final backupList = prefs.getStringList('backup_list') ?? [];
      
      if (backupList.length <= _maxBackups) {
        Logger.info('ℹ️ [BACKUP] Nenhum backup antigo para remover');
        return;
      }
      
      // Ordenar por timestamp
      final sortedBackups = backupList.map((json) {
        final data = jsonDecode(json);
        return {
          'json': json,
          'timestamp': DateTime.parse(data['timestamp']),
          'file_path': data['file_path'],
        };
      }).toList();
      
      sortedBackups.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      
      // Remover backups antigos
      final toRemove = sortedBackups.take(sortedBackups.length - _maxBackups);
      
      for (final backup in toRemove) {
        try {
          final file = File(backup['file_path']);
          if (await file.exists()) {
            await file.delete();
            Logger.info('🗑️ [BACKUP] Backup removido: ${backup['file_path']}');
          }
        } catch (e) {
          Logger.error('❌ [BACKUP] Erro ao remover backup: $e');
        }
      }
      
      // Atualizar lista de backups
      final remainingBackups = sortedBackups
          .skip(sortedBackups.length - _maxBackups)
          .map((b) => b['json'] as String)
          .toList();
      
      await prefs.setStringList('backup_list', remainingBackups);
      
      Logger.info('✅ [BACKUP] Limpeza concluída');
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro durante limpeza: $e');
    }
  }
  
  /// Restaura backup
  Future<bool> restoreBackup(String filePath) async {
    try {
      Logger.info('🔄 [BACKUP] Iniciando restauração: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.error('❌ [BACKUP] Arquivo de backup não encontrado: $filePath');
        return false;
      }
      
      final content = await file.readAsString();
      final backupData = jsonDecode(content);
      
      // Validar estrutura do backup
      if (!_validateBackupData(backupData)) {
        Logger.error('❌ [BACKUP] Dados de backup inválidos');
        return false;
      }
      
      // Restaurar dados
      await _restoreBackupData(backupData);
      
      Logger.info('✅ [BACKUP] Restauração concluída com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro durante restauração: $e');
      return false;
    }
  }
  
  /// Valida dados de backup
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // Verificar campos obrigatórios
      if (!data.containsKey('version') ||
          !data.containsKey('timestamp') ||
          !data.containsKey('talhoes')) {
        return false;
      }
      
      // Verificar se talhões é uma lista
      if (data['talhoes'] is! List) {
        return false;
      }
      
      return true;
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro na validação: $e');
      return false;
    }
  }
  
  /// Restaura dados do backup
  Future<void> _restoreBackupData(Map<String, dynamic> data) async {
    try {
      // Aqui você deve integrar com o serviço de talhões para restaurar os dados
      // Por enquanto, apenas logamos o que seria restaurado
      
      final talhoes = data['talhoes'] as List;
      final culturas = data['culturas'] as List;
      final safras = data['safras'] as List;
      
      Logger.info('📊 [BACKUP] Dados a serem restaurados:');
      Logger.info('   - Talhões: ${talhoes.length}');
      Logger.info('   - Culturas: ${culturas.length}');
      Logger.info('   - Safras: ${safras.length}');
      
      // TODO: Implementar restauração real dos dados
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao restaurar dados: $e');
    }
  }
  
  /// Lista backups disponíveis
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupList = prefs.getStringList('backup_list') ?? [];
      
      return backupList.map((json) {
        final data = jsonDecode(json);
        return {
          'file_path': data['file_path'],
          'timestamp': DateTime.parse(data['timestamp']),
          'total_talhoes': data['total_talhoes'],
          'total_area': data['total_area'],
          'size': data['size'],
        };
      }).toList();
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao listar backups: $e');
      return [];
    }
  }
  
  /// Habilita/desabilita backup automático
  Future<void> setAutomaticBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backup_automatico_habilitado', enabled);
      
      if (enabled) {
        await _startAutomaticBackup();
        await _startCleanupTimer();
        Logger.info('✅ [BACKUP] Backup automático habilitado');
      } else {
        _backupTimer?.cancel();
        _cleanupTimer?.cancel();
        Logger.info('⏸️ [BACKUP] Backup automático desabilitado');
      }
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao alterar configuração: $e');
    }
  }
  
  /// Verifica se backup automático está habilitado
  Future<bool> isAutomaticBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('backup_automatico_habilitado') ?? true;
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao verificar configuração: $e');
      return false;
    }
  }
  
  /// Obtém estatísticas de backup
  Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final backups = await listBackups();
      final totalSize = backups.fold<int>(0, (sum, backup) => sum + (backup['size'] as int));
      
      return {
        'total_backups': backups.length,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'last_backup': backups.isNotEmpty ? backups.last['timestamp'] : null,
        'automatic_enabled': await isAutomaticBackupEnabled(),
      };
      
    } catch (e) {
      Logger.error('❌ [BACKUP] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Para o serviço
  void dispose() {
    _backupTimer?.cancel();
    _cleanupTimer?.cancel();
  }
}
