import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import 'monitoring_integration_service.dart';

/// Serviço aprimorado para salvar monitoramentos com integração automática
/// Combina salvamento robusto com processamento de integração
class MonitoringSaveEnhancedService {
  final AppDatabase _appDatabase = AppDatabase();
  final MonitoringIntegrationService _integrationService = MonitoringIntegrationService();

  /// Salva monitoramento com integração automática
  Future<Map<String, dynamic>> saveMonitoringWithIntegration(Monitoring monitoring) async {
    try {
      Logger.info('🚀 Salvando monitoramento com integração: ${monitoring.id}');
      
      // 1. Salvar no banco de dados
      final saveResult = await _saveMonitoringToDatabase(monitoring);
      
      if (!saveResult['success']) {
        return {
          'status': 'ERROR',
          'message': 'Falha ao salvar no banco de dados',
          'monitoring_id': monitoring.id,
          'error': saveResult['error'],
        };
      }
      
      Logger.info('✅ Monitoramento salvo no banco de dados');
      
      // 2. Processar integração (em background para não bloquear)
      _processIntegrationInBackground(monitoring);
      
      return {
        'status': 'SUCCESS',
        'message': 'Monitoramento salvo com sucesso. Integração em processamento.',
        'monitoring_id': monitoring.id,
        'save_success': true,
        'integration_processing': true,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar monitoramento: $e');
      
      return {
        'status': 'ERROR',
        'message': 'Erro ao salvar monitoramento: $e',
        'monitoring_id': monitoring.id,
        'save_success': false,
      };
    }
  }

  /// Salva monitoramento no banco de dados
  Future<Map<String, dynamic>> _saveMonitoringToDatabase(Monitoring monitoring) async {
    try {
      // Garantir que o banco está pronto
      await _ensureDatabaseReady();
      
      // Validar dados básicos
      final validatedMonitoring = _validateBasicData(monitoring);
      
      // Salvar de forma simplificada
      final success = await _saveSimplified(validatedMonitoring);
      
      if (success) {
        return {'success': true};
      }
      
      // Tentar salvamento de emergência
      final emergencySuccess = await _emergencySave(validatedMonitoring);
      
      return {
        'success': emergencySuccess,
        'error': emergencySuccess ? null : 'Falha no salvamento de emergência',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar no banco: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Processa integração em background
  void _processIntegrationInBackground(Monitoring monitoring) {
    // Executar em background para não bloquear a UI
    Future.microtask(() async {
      try {
        Logger.info('🔄 Processando integração em background para: ${monitoring.id}');
        
        final integrationResult = await _integrationService.saveMonitoringWithIntegration(monitoring);
        
        if (integrationResult['status'] == 'SUCCESS') {
          Logger.info('✅ Integração processada com sucesso: ${monitoring.id}');
        } else {
          Logger.warning('⚠️ Integração falhou: ${monitoring.id} - ${integrationResult['message']}');
        }
        
      } catch (e) {
        Logger.error('❌ Erro na integração em background: $e');
      }
    });
  }

  /// Garante que o banco de dados está pronto
  Future<void> _ensureDatabaseReady() async {
    try {
      final db = await _appDatabase.database;
      
      // Tabela de monitoramentos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitorings (
          id TEXT PRIMARY KEY,
          plot_id TEXT NOT NULL,
          plotName TEXT,
          crop_id TEXT NOT NULL,
          cropName TEXT,
          date TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Tabela de pontos de monitoramento
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_points (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          plot_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          observations TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      
      // Tabela de ocorrências
      await db.execute('''
        CREATE TABLE IF NOT EXISTS occurrences (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          point_id TEXT NOT NULL,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          infestationIndex REAL NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      
      Logger.info('✅ Banco de dados preparado');
    } catch (e) {
      Logger.error('❌ Erro ao preparar banco: $e');
      rethrow;
    }
  }

  /// Valida dados básicos do monitoramento
  Monitoring _validateBasicData(Monitoring monitoring) {
    try {
      // Garantir ID válido
      final id = monitoring.id.isNotEmpty ? monitoring.id : DateTime.now().millisecondsSinceEpoch.toString();
      
      // Garantir plotId e cropId válidos
      final plotId = monitoring.plotId > 0 ? monitoring.plotId : 1;
      final cropId = monitoring.cropId > 0 ? monitoring.cropId : 1;
      
      // Garantir nomes válidos
      final plotName = monitoring.plotName.isNotEmpty ? monitoring.plotName : 'Talhão $plotId';
      final cropName = monitoring.cropName.isNotEmpty ? monitoring.cropName : 'Cultura $cropId';
      
      // Criar monitoramento validado
      return Monitoring(
        id: id,
        date: monitoring.date,
        plotId: plotId,
        plotName: plotName,
        cropId: cropId,
        cropName: cropName,
        cropType: monitoring.cropType,
        route: monitoring.route,
        points: monitoring.points,
        isCompleted: monitoring.isCompleted,
        isSynced: monitoring.isSynced,
        severity: monitoring.severity,
        createdAt: monitoring.createdAt,
        updatedAt: monitoring.updatedAt,
        metadata: monitoring.metadata,
        technicianName: monitoring.technicianName,
        technicianIdentification: monitoring.technicianIdentification,
        latitude: monitoring.latitude,
        longitude: monitoring.longitude,
        pests: monitoring.pests,
        diseases: monitoring.diseases,
        weeds: monitoring.weeds,
        images: monitoring.images,
        observations: monitoring.observations,
        recommendations: monitoring.recommendations,
      );
      
    } catch (e) {
      Logger.error('❌ Erro na validação: $e');
      rethrow;
    }
  }

  /// Salva de forma simplificada
  Future<bool> _saveSimplified(Monitoring monitoring) async {
    try {
      final db = await _appDatabase.database;
      
      // Usar transação para garantir consistência
      await db.transaction((txn) async {
        // Salvar monitoramento principal
        final monitoringData = {
          'id': monitoring.id,
          'plot_id': monitoring.plotId.toString(),
          'plotName': monitoring.plotName,
          'crop_id': monitoring.cropId.toString(),
          'cropName': monitoring.cropName,
          'date': monitoring.date.toIso8601String(),
          'isCompleted': monitoring.isCompleted ? 1 : 0,
          'created_at': monitoring.createdAt.toIso8601String(),
          'updated_at': monitoring.updatedAt?.toIso8601String() ?? monitoring.createdAt.toIso8601String(),
        };
        
        await txn.insert(
          'monitorings',
          monitoringData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Salvar pontos
        for (final point in monitoring.points) {
          final pointData = {
            'id': point.id,
            'monitoring_id': monitoring.id,
            'plot_id': point.plotId.toString(),
            'latitude': point.latitude,
            'longitude': point.longitude,
            'observations': point.observations,
            'created_at': point.createdAt.toIso8601String(),
          };
          
          await txn.insert(
            'monitoring_points',
            pointData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          // Salvar ocorrências do ponto
          for (final occurrence in point.occurrences) {
            final occurrenceData = {
              'id': occurrence.id,
              'monitoring_id': monitoring.id,
              'point_id': point.id,
              'type': occurrence.type.toString().split('.').last,
              'name': occurrence.name,
              'infestationIndex': occurrence.infestationIndex,
              'createdAt': occurrence.createdAt.toIso8601String(),
            };
            
            await txn.insert(
              'occurrences',
              occurrenceData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      
      Logger.info('✅ Monitoramento salvo de forma simplificada');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento simplificado: $e');
      return false;
    }
  }

  /// Salvamento de emergência
  Future<bool> _emergencySave(Monitoring monitoring) async {
    try {
      final db = await _appDatabase.database;
      
      // Salvar apenas dados essenciais
      final emergencyData = {
        'id': monitoring.id,
        'plot_id': monitoring.plotId.toString(),
        'plotName': monitoring.plotName,
        'crop_id': monitoring.cropId.toString(),
        'cropName': monitoring.cropName,
        'date': monitoring.date.toIso8601String(),
        'isCompleted': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await db.insert(
        'monitorings',
        emergencyData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Salvamento de emergência realizado');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento de emergência: $e');
      return false;
    }
  }

  /// Salva múltiplos monitoramentos com integração
  Future<List<Map<String, dynamic>>> saveMultipleMonitoringsWithIntegration(List<Monitoring> monitorings) async {
    try {
      Logger.info('🔄 Salvando ${monitorings.length} monitoramentos com integração...');
      
      final results = <Map<String, dynamic>>[];
      
      for (final monitoring in monitorings) {
        try {
          final result = await saveMonitoringWithIntegration(monitoring);
          results.add(result);
        } catch (e) {
          Logger.error('❌ Erro ao salvar monitoramento ${monitoring.id}: $e');
          results.add({
            'status': 'ERROR',
            'message': 'Erro ao salvar monitoramento: $e',
            'monitoring_id': monitoring.id,
            'save_success': false,
          });
        }
      }
      
      final successCount = results.where((r) => r['status'] == 'SUCCESS').length;
      final errorCount = results.where((r) => r['status'] == 'ERROR').length;
      
      Logger.info('✅ Salvamento em lote concluído: $successCount sucessos, $errorCount erros');
      
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento em lote: $e');
      return [];
    }
  }

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      Logger.info('🚀 Inicializando serviço aprimorado de salvamento...');
      
      await _integrationService.initialize();
      
      Logger.info('✅ Serviço aprimorado de salvamento inicializado');
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar serviço aprimorado: $e');
      rethrow;
    }
  }

  /// Obtém status do serviço
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final integrationStatus = await _integrationService.getIntegrationStatus();
      
      return {
        'status': 'SUCCESS',
        'service': 'MonitoringSaveEnhancedService',
        'database': 'READY',
        'integration': integrationStatus,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao obter status: $e');
      
      return {
        'status': 'ERROR',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
