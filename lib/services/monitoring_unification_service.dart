import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../modules/monitoring/models/monitoring_model.dart' as module_models;
import '../modules/monitoring/models/monitoring_point_model.dart' as module_models;
import '../repositories/monitoring_repository.dart';
import '../modules/monitoring/repositories/monitoring_repository.dart' as module_repo;
import '../utils/logger.dart';

/// Serviço para unificar os modelos e repositórios conflitantes do módulo de monitoramento
/// Resolve os problemas de duplicação de código e incompatibilidade entre modelos
class MonitoringUnificationService {
  final MonitoringRepository _mainRepository = MonitoringRepository();
  final module_repo.MonitoringRepository _moduleRepository = module_repo.MonitoringRepository();

  /// Converte MonitoringModel (módulo) para Monitoring (principal)
  static Monitoring fromModuleModel(module_models.MonitoringModel moduleModel) {
    try {
      // Converter pontos
      final List<MonitoringPoint> points = moduleModel.points.map((modulePoint) {
        return MonitoringPoint(
          id: modulePoint.id,
          monitoringId: moduleModel.id,
          plotId: int.tryParse(modulePoint.plotId) ?? 1,
          plotName: modulePoint.plotName,
          cropId: int.tryParse(modulePoint.cropId) ?? 1,
          cropName: modulePoint.cropName,
          latitude: modulePoint.latitude,
          longitude: modulePoint.longitude,
          occurrences: _convertOccurrences(modulePoint),
          imagePaths: modulePoint.photos,
          audioPath: modulePoint.audioPath,
          observations: modulePoint.observations,
          createdAt: modulePoint.createdAt,
          updatedAt: modulePoint.updatedAt,
          isSynced: modulePoint.isSynced,
          metadata: modulePoint.metadata,
        );
      }).toList();

      // Converter rota
      final List<Map<String, dynamic>> route = moduleModel.route.map((latLng) {
        return {
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        };
      }).toList();

      return Monitoring(
        id: moduleModel.id,
        date: moduleModel.dateTime,
        plotId: int.tryParse(moduleModel.plotId) ?? 1,
        plotName: moduleModel.plotName,
        cropId: int.tryParse(moduleModel.cropId) ?? 1,
        cropName: moduleModel.cropName,
        cropType: moduleModel.cropName,
        route: route,
        points: points,
        isCompleted: moduleModel.status == module_models.MonitoringStatus.completed,
        isSynced: moduleModel.isSynced,
        severity: (moduleModel.averageSeverity * 100).round(),
        createdAt: moduleModel.dateTime,
        updatedAt: DateTime.now(),
        metadata: moduleModel.notes,
        technicianName: moduleModel.operatorName,
        observations: moduleModel.notes,
      );
    } catch (e) {
      Logger.error('❌ Erro ao converter MonitoringModel para Monitoring: $e');
      rethrow;
    }
  }

  /// Converte Monitoring (principal) para MonitoringModel (módulo)
  static module_models.MonitoringModel toModuleModel(Monitoring monitoring) {
    try {
      // Converter pontos
      final List<module_models.MonitoringPointModel> points = monitoring.points.map((point) {
        return module_models.MonitoringPointModel(
          id: point.id,
          monitoringId: monitoring.id,
          plotId: point.plotId.toString(),
          plotName: point.plotName,
          cropId: point.cropId.toString(),
          cropName: point.cropName,
          latitude: point.latitude,
          longitude: point.longitude,
          pests: _convertPests(point.occurrences),
          diseases: _convertDiseases(point.occurrences),
          weeds: _convertWeeds(point.occurrences),
          photos: point.imagePaths,
          audioPath: point.audioPath,
          observations: point.observations,
          createdAt: point.createdAt,
          updatedAt: point.updatedAt,
          isSynced: point.isSynced,
          metadata: point.metadata,
        );
      }).toList();

      // Converter rota
      final List<LatLng> route = monitoring.route.map((routePoint) {
        return LatLng(
          routePoint['latitude']?.toDouble() ?? 0.0,
          routePoint['longitude']?.toDouble() ?? 0.0,
        );
      }).toList();

      return module_models.MonitoringModel(
        id: monitoring.id,
        dateTime: monitoring.date,
        farmId: '1', // Valor padrão
        farmName: monitoring.plotName,
        plotId: monitoring.plotId.toString(),
        plotName: monitoring.plotName,
        safraId: '1', // Valor padrão
        safraName: 'Safra Atual',
        cropId: monitoring.cropId.toString(),
        cropName: monitoring.cropName,
        operatorName: monitoring.technicianName ?? 'Técnico',
        notes: monitoring.observations,
        route: route,
        points: points,
        status: monitoring.isCompleted 
            ? module_models.MonitoringStatus.completed 
            : module_models.MonitoringStatus.inProgress,
        isSynced: monitoring.isSynced,
      );
    } catch (e) {
      Logger.error('❌ Erro ao converter Monitoring para MonitoringModel: $e');
      rethrow;
    }
  }

  /// Converte ocorrências do modelo de módulo para o modelo principal
  static List<Occurrence> _convertOccurrences(module_models.MonitoringPointModel modulePoint) {
    final List<Occurrence> occurrences = [];

    // Converter pragas
    for (final pest in modulePoint.pests) {
      occurrences.add(Occurrence(
        id: pest.id,
        type: OccurrenceType.pest,
        name: pest.name,
        infestationIndex: pest.infestationLevel * 100, // Converter para porcentagem
        affectedSections: _convertPlantSections(pest.plantSection),
        notes: pest.notes,
        createdAt: pest.createdAt,
        updatedAt: pest.updatedAt,
      ));
    }

    // Converter doenças
    for (final disease in modulePoint.diseases) {
      occurrences.add(Occurrence(
        id: disease.id,
        type: OccurrenceType.disease,
        name: disease.name,
        infestationIndex: disease.infestationLevel * 100,
        affectedSections: _convertPlantSections(disease.plantSection),
        notes: disease.notes,
        createdAt: disease.createdAt,
        updatedAt: disease.updatedAt,
      ));
    }

    // Converter plantas daninhas
    for (final weed in modulePoint.weeds) {
      occurrences.add(Occurrence(
        id: weed.id,
        type: OccurrenceType.weed,
        name: weed.name,
        infestationIndex: weed.infestationLevel * 100,
        affectedSections: _convertPlantSections(weed.plantSection),
        notes: weed.notes,
        createdAt: weed.createdAt,
        updatedAt: weed.updatedAt,
      ));
    }

    return occurrences;
  }

  /// Converte seções de planta do modelo de módulo para o modelo principal
  static List<PlantSection> _convertPlantSections(String plantSection) {
    switch (plantSection.toLowerCase()) {
      case 'upper':
      case 'superior':
        return [PlantSection.upper];
      case 'middle':
      case 'medio':
        return [PlantSection.middle];
      case 'lower':
      case 'inferior':
        return [PlantSection.lower];
      default:
        return [PlantSection.upper, PlantSection.middle, PlantSection.lower];
    }
  }

  /// Converte pragas do modelo principal para o modelo de módulo
  static List<module_models.PestOccurrence> _convertPests(List<Occurrence> occurrences) {
    return occurrences
        .where((occ) => occ.type == OccurrenceType.pest)
        .map((occ) => module_models.PestOccurrence(
              id: occ.id,
              name: occ.name,
              infestationLevel: occ.infestationIndex / 100, // Converter de porcentagem
              plantSection: _convertPlantSectionToString(occ.affectedSections),
              notes: occ.notes,
              createdAt: occ.createdAt,
              updatedAt: occ.updatedAt,
            ))
        .toList();
  }

  /// Converte doenças do modelo principal para o modelo de módulo
  static List<module_models.DiseaseOccurrence> _convertDiseases(List<Occurrence> occurrences) {
    return occurrences
        .where((occ) => occ.type == OccurrenceType.disease)
        .map((occ) => module_models.DiseaseOccurrence(
              id: occ.id,
              name: occ.name,
              infestationLevel: occ.infestationIndex / 100,
              plantSection: _convertPlantSectionToString(occ.affectedSections),
              notes: occ.notes,
              createdAt: occ.createdAt,
              updatedAt: occ.updatedAt,
            ))
        .toList();
  }

  /// Converte plantas daninhas do modelo principal para o modelo de módulo
  static List<module_models.WeedOccurrence> _convertWeeds(List<Occurrence> occurrences) {
    return occurrences
        .where((occ) => occ.type == OccurrenceType.weed)
        .map((occ) => module_models.WeedOccurrence(
              id: occ.id,
              name: occ.name,
              infestationLevel: occ.infestationIndex / 100,
              plantSection: _convertPlantSectionToString(occ.affectedSections),
              notes: occ.notes,
              createdAt: occ.createdAt,
              updatedAt: occ.updatedAt,
            ))
        .toList();
  }

  /// Converte seções de planta para string
  static String _convertPlantSectionToString(List<PlantSection> sections) {
    if (sections.isEmpty) return 'upper';
    if (sections.length == 1) {
      switch (sections.first) {
        case PlantSection.upper:
          return 'upper';
        case PlantSection.middle:
          return 'middle';
        case PlantSection.lower:
          return 'lower';
      }
    }
    return 'upper'; // Padrão
  }

  /// Migra dados do repositório de módulo para o repositório principal
  Future<bool> migrateModuleDataToMain() async {
    try {
      Logger.info('🔄 Iniciando migração de dados do módulo para o repositório principal...');

      // Obter todos os monitoramentos do módulo
      final moduleMonitorings = await _moduleRepository.getAll();
      Logger.info('📊 ${moduleMonitorings.length} monitoramentos encontrados no módulo');

      int successCount = 0;
      int errorCount = 0;

      for (final moduleMonitoring in moduleMonitorings) {
        try {
          // Converter para o modelo principal
          final mainMonitoring = fromModuleModel(moduleMonitoring);

          // Salvar no repositório principal
          final success = await _mainRepository.saveMonitoring(mainMonitoring);

          if (success) {
            successCount++;
            Logger.info('✅ Monitoramento ${moduleMonitoring.id} migrado com sucesso');
          } else {
            errorCount++;
            Logger.error('❌ Falha ao migrar monitoramento ${moduleMonitoring.id}');
          }
        } catch (e) {
          errorCount++;
          Logger.error('❌ Erro ao migrar monitoramento ${moduleMonitoring.id}: $e');
        }
      }

      Logger.info('🏁 Migração concluída: $successCount sucessos, $errorCount erros');
      return errorCount == 0;

    } catch (e) {
      Logger.error('❌ Erro durante migração: $e');
      return false;
    }
  }

  /// Verifica se há dados duplicados entre os repositórios
  Future<Map<String, dynamic>> checkDataDuplication() async {
    try {
      Logger.info('🔍 Verificando duplicação de dados...');

      final mainMonitorings = await _mainRepository.getAllMonitorings();
      final moduleMonitorings = await _moduleRepository.getAll();

      final mainIds = mainMonitorings.map((m) => m.id).toSet();
      final moduleIds = moduleMonitorings.map((m) => m.id).toSet();

      final duplicatedIds = mainIds.intersection(moduleIds);

      return {
        'mainCount': mainMonitorings.length,
        'moduleCount': moduleMonitorings.length,
        'duplicatedCount': duplicatedIds.length,
        'duplicatedIds': duplicatedIds.toList(),
        'hasDuplication': duplicatedIds.isNotEmpty,
      };

    } catch (e) {
      Logger.error('❌ Erro ao verificar duplicação: $e');
      return {
        'error': e.toString(),
        'hasDuplication': false,
      };
    }
  }

  /// Remove dados duplicados do repositório de módulo
  Future<bool> removeDuplicatedData() async {
    try {
      Logger.info('🧹 Removendo dados duplicados...');

      final duplicationInfo = await checkDataDuplication();
      
      if (!duplicationInfo['hasDuplication']) {
        Logger.info('✅ Nenhum dado duplicado encontrado');
        return true;
      }

      final duplicatedIds = duplicationInfo['duplicatedIds'] as List<String>;
      Logger.info('🗑️ Removendo ${duplicatedIds.length} monitoramentos duplicados...');

      int removedCount = 0;
      for (final id in duplicatedIds) {
        try {
          await _moduleRepository.delete(id);
          removedCount++;
        } catch (e) {
          Logger.error('❌ Erro ao remover monitoramento $id: $e');
        }
      }

      Logger.info('✅ $removedCount monitoramentos duplicados removidos');
      return removedCount == duplicatedIds.length;

    } catch (e) {
      Logger.error('❌ Erro ao remover dados duplicados: $e');
      return false;
    }
  }

  /// Executa processo completo de unificação
  Future<bool> unifyMonitoringData() async {
    try {
      Logger.info('🚀 Iniciando processo completo de unificação...');

      // 1. Verificar duplicação
      final duplicationInfo = await checkDataDuplication();
      Logger.info('📊 Informações de duplicação: $duplicationInfo');

      // 2. Migrar dados
      final migrationSuccess = await migrateModuleDataToMain();
      if (!migrationSuccess) {
        Logger.error('❌ Falha na migração de dados');
        return false;
      }

      // 3. Remover dados duplicados
      final cleanupSuccess = await removeDuplicatedData();
      if (!cleanupSuccess) {
        Logger.error('❌ Falha na limpeza de dados duplicados');
        return false;
      }

      Logger.info('✅ Unificação concluída com sucesso!');
      return true;

    } catch (e) {
      Logger.error('❌ Erro durante unificação: $e');
      return false;
    }
  }

  /// Obtém estatísticas dos dados
  Future<Map<String, dynamic>> getDataStatistics() async {
    try {
      final mainMonitorings = await _mainRepository.getAllMonitorings();
      final moduleMonitorings = await _moduleRepository.getAll();

      int totalPoints = 0;
      int totalOccurrences = 0;

      for (final monitoring in mainMonitorings) {
        totalPoints += monitoring.points.length;
        for (final point in monitoring.points) {
          totalOccurrences += point.occurrences.length;
        }
      }

      return {
        'mainRepository': {
          'monitorings': mainMonitorings.length,
          'points': totalPoints,
          'occurrences': totalOccurrences,
        },
        'moduleRepository': {
          'monitorings': moduleMonitorings.length,
        },
        'total': {
          'monitorings': mainMonitorings.length + moduleMonitorings.length,
          'points': totalPoints,
          'occurrences': totalOccurrences,
        },
      };

    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}
