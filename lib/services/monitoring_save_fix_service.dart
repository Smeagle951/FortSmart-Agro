import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import 'monitoring_infestation_integration_service.dart';

/// Serviço simplificado e robusto para salvar monitoramentos
class MonitoringSaveFixService {
  final AppDatabase _appDatabase = AppDatabase();

  /// Salva o monitoramento de forma simplificada e robusta
  Future<bool> saveMonitoringWithFix(Monitoring monitoring) async {
    try {
      Logger.info('🔧 Iniciando salvamento simplificado do monitoramento ${monitoring.id}...');
      
      // Estratégia 1: Garantir que o banco está pronto
      await _ensureDatabaseReady();
      
      // Estratégia 2: Validar dados básicos
      final validatedMonitoring = _validateBasicData(monitoring);
      
      // Estratégia 3: Salvar de forma simplificada
      final success = await _saveSimplified(validatedMonitoring);
      
      if (success) {
        Logger.info('✅ Monitoramento salvo com sucesso');
        
        // Processar dados para o mapa de infestação
        await _processForInfestationMap(validatedMonitoring);
        
        return true;
      }
      
      // Estratégia 4: Salvamento de emergência
      Logger.info('🔄 Tentando salvamento de emergência...');
      return await _emergencySave(validatedMonitoring);
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento: $e');
      return false;
    }
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
      
      // Garantir nome válido
      final plotName = monitoring.plotName.isNotEmpty ? monitoring.plotName : 'Talhão $plotId';
      final cropName = monitoring.cropName.isNotEmpty ? monitoring.cropName : 'Cultura $cropId';
      
      // Validar pontos
      final validPoints = <MonitoringPoint>[];
      for (final point in monitoring.points) {
        final validPoint = _validatePoint(point, id);
        validPoints.add(validPoint);
      }
      
      return Monitoring(
        id: id,
        date: monitoring.date,
        plotId: plotId,
        plotName: plotName,
        cropId: cropId,
        cropName: cropName,
        route: monitoring.route,
        points: validPoints,
        isCompleted: true,
        createdAt: monitoring.createdAt,
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao validar dados: $e');
      rethrow;
    }
  }

  /// Valida um ponto de monitoramento
  MonitoringPoint _validatePoint(MonitoringPoint point, String monitoringId) {
    try {
      // Garantir ID válido
      final id = point.id.isNotEmpty ? point.id : DateTime.now().millisecondsSinceEpoch.toString();
      
      // Garantir coordenadas válidas
      final latitude = point.latitude.isFinite ? point.latitude : 0.0;
      final longitude = point.longitude.isFinite ? point.longitude : 0.0;
      
      // Garantir plotId válido
      final plotId = point.plotId > 0 ? point.plotId : 1;
      
      // Validar ocorrências
      final validOccurrences = <Occurrence>[];
      for (final occurrence in point.occurrences) {
        final validOccurrence = _validateOccurrence(occurrence);
        validOccurrences.add(validOccurrence);
      }
      
      return MonitoringPoint(
        id: id,
        monitoringId: monitoringId,
        plotId: plotId,
        plotName: point.plotName.isNotEmpty ? point.plotName : 'Talhão $plotId',
        latitude: latitude,
        longitude: longitude,
        occurrences: validOccurrences,
        observations: point.observations ?? '',
        createdAt: point.createdAt,
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao validar ponto: $e');
      rethrow;
    }
  }

  /// Valida uma ocorrência
  Occurrence _validateOccurrence(Occurrence occurrence) {
    try {
      // Garantir ID válido
      final id = occurrence.id.isNotEmpty ? occurrence.id : DateTime.now().millisecondsSinceEpoch.toString();
      
      // Garantir nome válido
      final name = occurrence.name.isNotEmpty ? occurrence.name : 'Ocorrência não identificada';
      
      // Garantir índice válido
      final infestationIndex = occurrence.infestationIndex.clamp(0.0, 100.0);
      
      return Occurrence(
        id: id,
        type: occurrence.type,
        name: name,
        infestationIndex: infestationIndex,
        affectedSections: occurrence.affectedSections,
        notes: occurrence.notes,
        createdAt: occurrence.createdAt,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao validar ocorrência: $e');
      rethrow;
    }
  }

  /// Salvamento simplificado
  Future<bool> _saveSimplified(Monitoring monitoring) async {
    try {
      Logger.info('💾 Salvamento simplificado...');
      
      final db = await _appDatabase.database;
      
      await db.transaction((txn) async {
        // Salvar monitoramento principal
        final monitoringData = {
          'id': monitoring.id,
          'plot_id': monitoring.plotId.toString(),
          'plotName': monitoring.plotName,
          'crop_id': monitoring.cropId.toString(),
          'cropName': monitoring.cropName,
          'date': monitoring.date.toIso8601String(),
          'isCompleted': 1,
          'created_at': monitoring.createdAt.toIso8601String(),
          'updated_at': monitoring.updatedAt!.toIso8601String(),
        };
        
        await txn.insert(
          'monitorings',
          monitoringData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        Logger.info('✅ Monitoramento principal salvo');
        
        // Salvar pontos
        for (final point in monitoring.points) {
          final pointData = {
            'id': point.id,
            'monitoring_id': monitoring.id,
            'plot_id': point.plotId.toString(),
            'latitude': point.latitude,
            'longitude': point.longitude,
            'observations': point.observations ?? '',
            'created_at': point.createdAt.toIso8601String(),
          };
          
          await txn.insert(
            'monitoring_points',
            pointData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          // Salvar ocorrências
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
        
        Logger.info('✅ Pontos e ocorrências salvos');
      });
      
      Logger.info('✅ Salvamento simplificado concluído');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento simplificado: $e');
      return false;
    }
  }

  /// Salvamento de emergência (apenas dados essenciais)
  Future<bool> _emergencySave(Monitoring monitoring) async {
    try {
      Logger.info('🚨 Salvamento de emergência...');
      
      final db = await _appDatabase.database;
      
      // Salvar apenas o monitoramento principal
      final emergencyData = {
        'id': monitoring.id,
        'plot_id': monitoring.plotId.toString(),
        'plotName': monitoring.plotName,
        'crop_id': monitoring.cropId.toString(),
        'cropName': monitoring.cropName,
        'date': monitoring.date.toIso8601String(),
        'isCompleted': 1,
        'created_at': monitoring.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await db.insert(
        'monitorings',
        emergencyData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Salvamento de emergência concluído');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento de emergência: $e');
      return false;
    }
  }

  /// Processa dados do monitoramento para o mapa de infestação
  Future<void> _processForInfestationMap(Monitoring monitoring) async {
    try {
      Logger.info('🔄 Processando monitoramento para mapa de infestação...');
      
      // Usar o novo serviço de integração unificado
      final integrationService = MonitoringInfestationIntegrationService();
      final success = await integrationService.processMonitoringForInfestation(monitoring);
      
      if (success) {
        Logger.info('✅ Monitoramento processado para mapa de infestação com sucesso');
      } else {
        Logger.warning('⚠️ Falha ao processar monitoramento para mapa de infestação');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramento para mapa de infestação: $e');
      // Não rethrow para não quebrar o salvamento principal
    }
  }
}
