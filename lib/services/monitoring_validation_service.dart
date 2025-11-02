import 'dart:math';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'package:uuid/uuid.dart';

/// Serviço para validar e corrigir dados do monitoramento
class MonitoringValidationService {
  
  /// Valida um monitoramento completo antes de salvar
  Future<Map<String, dynamic>> validateMonitoring(Monitoring monitoring) async {
    final errors = <String>[];
    final warnings = <String>[];
    final fixes = <String>[];
    
    try {
      Logger.info('🔍 Validando monitoramento ${monitoring.id}...');
      
      // 1. Validar dados básicos do monitoramento
      _validateBasicData(monitoring, errors, warnings, fixes);
      
      // 2. Validar pontos
      _validatePoints(monitoring.points, errors, warnings, fixes);
      
      // 3. Validar ocorrências
      _validateOccurrences(monitoring.points, errors, warnings, fixes);
      
      // 4. Validar coordenadas
      _validateCoordinates(monitoring.points, errors, warnings, fixes);
      
      // 5. Validar IDs únicos
      _validateUniqueIds(monitoring, errors, warnings, fixes);
      
      final isValid = errors.isEmpty;
      
      Logger.info('✅ Validação concluída: ${isValid ? 'VÁLIDO' : 'INVÁLIDO'}');
      if (errors.isNotEmpty) {
        Logger.warning('❌ Erros encontrados: ${errors.length}');
        for (final error in errors) {
          Logger.error('   - $error');
        }
      }
      if (warnings.isNotEmpty) {
        Logger.warning('⚠️ Avisos encontrados: ${warnings.length}');
        for (final warning in warnings) {
          Logger.warning('   - $warning');
        }
      }
      if (fixes.isNotEmpty) {
        Logger.info('🔧 Correções aplicadas: ${fixes.length}');
        for (final fix in fixes) {
          Logger.info('   - $fix');
        }
      }
      
      return {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'fixes': fixes,
        'monitoring': monitoring,
      };
      
    } catch (e) {
      Logger.error('❌ Erro durante validação: $e');
      errors.add('Erro durante validação: $e');
      return {
        'isValid': false,
        'errors': errors,
        'warnings': warnings,
        'fixes': fixes,
        'monitoring': monitoring,
      };
    }
  }
  
  /// Valida dados básicos do monitoramento
  void _validateBasicData(Monitoring monitoring, List<String> errors, List<String> warnings, List<String> fixes) {
    // ID do monitoramento
    if (monitoring.id.isEmpty) {
      errors.add('ID do monitoramento é obrigatório');
    }
    
    // Plot ID
    if (monitoring.plotId <= 0) {
      errors.add('Plot ID deve ser maior que zero');
    }
    
    // Plot Name
    if (monitoring.plotName.isEmpty) {
      errors.add('Nome do talhão é obrigatório');
    }
    
    // Crop ID
    if (monitoring.cropId < 0) {
      warnings.add('Crop ID negativo detectado, será corrigido para 0');
      fixes.add('Crop ID será corrigido para 0');
    }
    
    // Data
    if (monitoring.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      warnings.add('Data do monitoramento está no futuro');
    }
    
    // Pontos
    if (monitoring.points.isEmpty) {
      errors.add('Monitoramento deve ter pelo menos um ponto');
    }
  }
  
  /// Valida pontos do monitoramento
  void _validatePoints(List<MonitoringPoint> points, List<String> errors, List<String> warnings, List<String> fixes) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // ID do ponto
      if (point.id.isEmpty) {
        errors.add('Ponto ${i + 1}: ID é obrigatório');
      }
      
      // Plot ID do ponto
      if (point.plotId <= 0) {
        warnings.add('Ponto ${i + 1}: Plot ID inválido, será corrigido para 1');
        fixes.add('Plot ID do ponto ${i + 1} será corrigido para 1');
      }
      
      // Coordenadas
      if (point.latitude == 0.0 && point.longitude == 0.0) {
        warnings.add('Ponto ${i + 1}: Coordenadas zeradas detectadas');
      }
      
      // Latitude
      if (point.latitude < -90 || point.latitude > 90) {
        errors.add('Ponto ${i + 1}: Latitude inválida: ${point.latitude}');
      }
      
      // Longitude
      if (point.longitude < -180 || point.longitude > 180) {
        errors.add('Ponto ${i + 1}: Longitude inválida: ${point.longitude}');
      }
      
      // Ocorrências
      if (point.occurrences.isEmpty) {
        warnings.add('Ponto ${i + 1}: Nenhuma ocorrência registrada');
      }
    }
  }
  
  /// Valida ocorrências dos pontos
  void _validateOccurrences(List<MonitoringPoint> points, List<String> errors, List<String> warnings, List<String> fixes) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      for (int j = 0; j < point.occurrences.length; j++) {
        final occurrence = point.occurrences[j];
        
        // ID da ocorrência
        if (occurrence.id.isEmpty) {
          warnings.add('Ponto ${i + 1}, Ocorrência ${j + 1}: ID vazio, será gerado novo');
          fixes.add('ID da ocorrência ${j + 1} do ponto ${i + 1} será gerado');
        }
        
        // Nome da ocorrência
        if (occurrence.name.isEmpty) {
          errors.add('Ponto ${i + 1}, Ocorrência ${j + 1}: Nome é obrigatório');
        }
        

        
        // Índice de infestação
        if (occurrence.infestationIndex < 0) {
          warnings.add('Ponto ${i + 1}, Ocorrência ${j + 1}: Índice negativo, será corrigido para 0');
          fixes.add('Índice da ocorrência ${j + 1} do ponto ${i + 1} será corrigido para 0');
        } else if (occurrence.infestationIndex > 100) {
          warnings.add('Ponto ${i + 1}, Ocorrência ${j + 1}: Índice > 100%, será corrigido para 100');
          fixes.add('Índice da ocorrência ${j + 1} do ponto ${i + 1} será corrigido para 100');
        }
        
        // Data de criação
        if (occurrence.createdAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          warnings.add('Ponto ${i + 1}, Ocorrência ${j + 1}: Data de criação no futuro');
        }
      }
    }
  }
  
  /// Valida coordenadas dos pontos
  void _validateCoordinates(List<MonitoringPoint> points, List<String> errors, List<String> warnings, List<String> fixes) {
    // Verificar se há pontos muito próximos (menos de 1 metro)
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = _calculateDistance(points[i], points[j]);
        if (distance < 1.0) {
          warnings.add('Pontos ${i + 1} e ${j + 1} muito próximos (${distance.toStringAsFixed(2)}m)');
        }
      }
    }
    
    // Verificar se há pontos com coordenadas idênticas
    final coordinates = points.map((p) => '${p.latitude},${p.longitude}').toSet();
    if (coordinates.length != points.length) {
      warnings.add('Pontos com coordenadas idênticas detectados');
    }
  }
  
  /// Valida IDs únicos
  void _validateUniqueIds(Monitoring monitoring, List<String> errors, List<String> warnings, List<String> fixes) {
    // IDs dos pontos
    final pointIds = monitoring.points.map((p) => p.id).toSet();
    if (pointIds.length != monitoring.points.length) {
      errors.add('IDs de pontos duplicados detectados');
    }
    
    // IDs das ocorrências
    final occurrenceIds = <String>{};
    for (final point in monitoring.points) {
      for (final occurrence in point.occurrences) {
        if (occurrenceIds.contains(occurrence.id)) {
          warnings.add('ID de ocorrência duplicado: ${occurrence.id}');
          fixes.add('ID de ocorrência duplicado será corrigido');
        } else {
          occurrenceIds.add(occurrence.id);
        }
      }
    }
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(MonitoringPoint p1, MonitoringPoint p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1 = p1.latitude * (pi / 180);
    final lat2 = p2.latitude * (pi / 180);
    final deltaLat = (p2.latitude - p1.latitude) * (pi / 180);
    final deltaLng = (p2.longitude - p1.longitude) * (pi / 180);
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Corrige problemas comuns no monitoramento
  Future<Monitoring> fixMonitoring(Monitoring monitoring) async {
    Logger.info('🔧 Aplicando correções no monitoramento...');
    
    // Corrigir IDs vazios
    String correctedId = monitoring.id;
    if (correctedId.isEmpty) {
      correctedId = const Uuid().v4();
    }
    
    // Corrigir plot ID
    int correctedPlotId = monitoring.plotId;
    if (correctedPlotId <= 0) {
      correctedPlotId = 1;
    }
    
    // Corrigir crop ID
    int correctedCropId = monitoring.cropId;
    if (correctedCropId < 0) {
      correctedCropId = 0;
    }
    
    // Corrigir pontos
    final correctedPoints = <MonitoringPoint>[];
    for (final point in monitoring.points) {
      String correctedPointId = point.id;
      if (correctedPointId.isEmpty) {
        correctedPointId = const Uuid().v4();
      }
      
      int correctedPointPlotId = point.plotId;
      if (correctedPointPlotId <= 0) {
        correctedPointPlotId = 1;
      }
      
      // Corrigir ocorrências
      final correctedOccurrences = <Occurrence>[];
      for (final occurrence in point.occurrences) {
        String correctedOccurrenceId = occurrence.id;
        if (correctedOccurrenceId.isEmpty) {
          correctedOccurrenceId = const Uuid().v4();
        }
        
        OccurrenceType correctedType = occurrence.type;
        
        double correctedIndex = occurrence.infestationIndex;
        if (correctedIndex < 0) {
          correctedIndex = 0.0;
        } else if (correctedIndex > 100) {
          correctedIndex = 100.0;
        }
        
        correctedOccurrences.add(Occurrence(
          id: correctedOccurrenceId,
          type: correctedType,
          name: occurrence.name,
          infestationIndex: correctedIndex,
          affectedSections: occurrence.affectedSections,
          notes: occurrence.notes,
          createdAt: occurrence.createdAt,
          updatedAt: occurrence.updatedAt,
        ));
      }
      
      correctedPoints.add(MonitoringPoint(
        id: correctedPointId,
        plotId: correctedPointPlotId,
        plotName: point.plotName,
        cropId: point.cropId,
        cropName: point.cropName,
        latitude: point.latitude,
        longitude: point.longitude,
        occurrences: correctedOccurrences,
        imagePaths: point.imagePaths,
        audioPath: point.audioPath,
        observations: point.observations,
        createdAt: point.createdAt,
        updatedAt: point.updatedAt,
      ));
    }
    
    final correctedMonitoring = Monitoring(
      id: correctedId,
      date: monitoring.date,
      plotId: correctedPlotId,
      plotName: monitoring.plotName,
      cropId: correctedCropId,
      cropName: monitoring.cropName,
      cropType: monitoring.cropType,
      route: monitoring.route,
      points: correctedPoints,
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
    
    Logger.info('✅ Correções aplicadas no monitoramento');
    return correctedMonitoring;
  }
}
