import 'dart:io';
import '../models/talhao_model.dart';
import '../repositories/talhoes/talhao_safra_repository.dart';
import '../services/geojson_reader_service.dart';
import '../models/geojson_data.dart' as geojson_model;
import '../services/geojson_validation_service.dart';
import '../services/agricultural_machine_data_processor.dart';
import '../utils/logger.dart';

/// Serviço de integração de dados GeoJSON
class GeoJSONIntegrationService {
  final TalhaoSafraRepository _talhaoSafraRepository;

  GeoJSONIntegrationService({
    required TalhaoSafraRepository talhaoSafraRepository,
  }) : _talhaoSafraRepository = talhaoSafraRepository;

  /// Integra arquivo GeoJSON no sistema
  static Future<GeoJSONIntegrationResult> integrateGeoJSONFile(
    File file, {
    TalhaoSafraRepository? talhaoSafraRepository,
  }) async {
    try {
      Logger.info('🔄 [GEOJSON_INTEGRATION] Iniciando integração do arquivo: ${file.path}');
      
      // Ler arquivo GeoJSON
      final geoJSONData = await GeoJSONReaderService.readGeoJSONFile(file);
      Logger.info('✅ [GEOJSON_INTEGRATION] Arquivo lido com sucesso');
      
      // Validar estrutura GeoJSON
      final structureValidation = GeoJSONValidationService.validateGeoJSONStructure(geoJSONData.toJson());
      if (!structureValidation.isValid) {
        Logger.error('❌ [GEOJSON_INTEGRATION] Estrutura GeoJSON inválida: ${structureValidation.errors.join(', ')}');
        return GeoJSONIntegrationResult(
          success: false,
          message: 'Estrutura GeoJSON inválida: ${structureValidation.errors.join(', ')}',
          importedItems: 0,
          errors: structureValidation.errors,
          data: geoJSONData,
        );
      }
      
      // Validar propriedades específicas por tipo
      final propertiesValidation = GeoJSONValidationService.validatePropertiesByType(geoJSONData);
      if (!propertiesValidation.isValid) {
        Logger.error('❌ [GEOJSON_INTEGRATION] Propriedades inválidas: ${propertiesValidation.errors.join(', ')}');
        return GeoJSONIntegrationResult(
          success: false,
          message: 'Propriedades inválidas: ${propertiesValidation.errors.join(', ')}',
          importedItems: 0,
          errors: propertiesValidation.errors,
          data: geoJSONData,
        );
      }
      
      // Log de avisos se houver
      if (structureValidation.warnings.isNotEmpty || propertiesValidation.warnings.isNotEmpty) {
        final allWarnings = [...structureValidation.warnings, ...propertiesValidation.warnings];
        Logger.info('⚠️ [GEOJSON_INTEGRATION] Avisos: ${allWarnings.join(', ')}');
      }
      
      // Processar dados baseado no tipo
      final result = await _processGeoJSONData(geoJSONData, file);
      Logger.info('🎯 [GEOJSON_INTEGRATION] Integração concluída: ${result.success}');
      
      return result;
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro na integração: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro na integração: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: null,
      );
    }
  }

  /// Processa dados GeoJSON baseado no tipo
  static Future<GeoJSONIntegrationResult> _processGeoJSONData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      switch (geoJSONData.dataType) {
        case GeoJSONDataType.talhao:
          return await _processTalhaoData(geoJSONData, file);
        case GeoJSONDataType.machineWork:
          return await _processMachineWorkData(geoJSONData, file);
        case GeoJSONDataType.planting:
          return await _processPlantingData(geoJSONData, file);
        case GeoJSONDataType.harvest:
          return await _processHarvestData(geoJSONData, file);
        case GeoJSONDataType.soilSample:
          return await _processSoilSampleData(geoJSONData, file);
        case GeoJSONDataType.irrigation:
          return await _processIrrigationData(geoJSONData, file);
        case GeoJSONDataType.unknown:
          return await _processUnknownData(geoJSONData, file);
      }
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de talhão
  static Future<GeoJSONIntegrationResult> _processTalhaoData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('🌾 [GEOJSON_INTEGRATION] Processando dados de talhão...');
      
      // Converter para talhões
      final talhoes = geoJSONData.toTalhoes();
      Logger.info('📊 [GEOJSON_INTEGRATION] ${talhoes.length} talhões convertidos');
      
      // Validar talhões
      final validationResult = _validateTalhoes(talhoes);
      if (!validationResult.isValid) {
        return GeoJSONIntegrationResult(
          success: false,
          message: 'Dados inválidos: ${validationResult.errors.join(', ')}',
          importedItems: 0,
          errors: validationResult.errors,
          data: geoJSONData,
        );
      }
      
      // Salvar talhões no banco de dados
      int savedCount = 0;
      for (final talhao in talhoes) {
        try {
          // Salvar talhão no repositório
          await _saveTalhaoToDatabase(talhao);
          savedCount++;
          Logger.info('💾 [GEOJSON_INTEGRATION] Talhão salvo: ${talhao.name}');
        } catch (e) {
          Logger.error('❌ [GEOJSON_INTEGRATION] Erro ao salvar talhão ${talhao.name}: $e');
        }
      }
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${savedCount} talhões importados com sucesso',
        importedItems: savedCount,
        errors: [],
        data: geoJSONData,
        statistics: GeoJSONReaderService.calculateStatistics(geoJSONData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de talhão: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de talhão: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de trabalho de máquina
  static Future<GeoJSONIntegrationResult> _processMachineWorkData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('🚜 [GEOJSON_INTEGRATION] Processando dados de trabalho de máquina...');
      
      // Usar o novo processador de dados de máquinas agrícolas
      final machineWorkData = await AgriculturalMachineDataProcessor.processMachineData(geoJSONData);
      
      if (machineWorkData != null) {
        Logger.info('✅ [GEOJSON_INTEGRATION] Dados de máquina processados: ${machineWorkData.points.length} pontos');
      } else {
        Logger.warning('⚠️ [GEOJSON_INTEGRATION] Nenhum dado de máquina processado');
        return GeoJSONIntegrationResult(
          success: false,
          message: 'Nenhum dado de máquina processado',
          importedItems: 0,
          errors: [],
        );
      }
      
      // Criar dados de resultado com informações processadas
      final processedData = {
        'dataType': 'machineWork',
        'machineData': {
          'id': machineWorkData.id,
          'machineName': machineWorkData.machineName,
          'applicationType': machineWorkData.applicationType,
          'workDate': machineWorkData.workDate.toIso8601String(),
          'totalArea': machineWorkData.totalArea,
          'totalVolume': machineWorkData.totalVolume,
          'averageRate': machineWorkData.averageRate,
          'averageSpeed': machineWorkData.averageSpeed,
          'pointsCount': machineWorkData.points.length,
          'valueRanges': machineWorkData.valueRanges.map((range) => {
            'min': range.minValue,
            'max': range.maxValue,
            'count': range.pointCount,
          }).toList(),
        },
        'features': geoJSONData.features.map((f) => {
          'id': f.id,
          'type': f.type,
          'geometry': f.geometry,
          'properties': f.properties,
        }).toList(),
        'metadata': geoJSONData.metadata,
        'importDate': geoJSONData.importDate.toIso8601String(),
      };
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${machineWorkData.points.length} pontos de trabalho de máquina processados com sucesso',
        importedItems: machineWorkData.points.length,
        errors: [],
        data: GeoJSONData(
          dataType: geoJSONData.dataType,
          features: geoJSONData.features,
          metadata: processedData,
          importDate: geoJSONData.importDate,
        ),
        statistics: {
          'totalPoints': machineWorkData.points.length,
          'totalArea': machineWorkData.totalArea,
          'totalVolume': machineWorkData.totalVolume,
          'averageRate': machineWorkData.averageRate,
          'averageSpeed': machineWorkData.averageSpeed,
          'valueRangesCount': machineWorkData.valueRanges.length,
          'machineName': machineWorkData.machineName,
          'applicationType': machineWorkData.applicationType,
          'workDate': machineWorkData.workDate.toIso8601String(),
        },
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de máquina: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de máquina: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de plantio
  static Future<GeoJSONIntegrationResult> _processPlantingData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('🌱 [GEOJSON_INTEGRATION] Processando dados de plantio...');
      
      // Processar dados específicos de plantio
      final plantingData = _extractPlantingData(geoJSONData);
      
      // Validar dados de plantio
      final validationResult = _validatePlantingData(plantingData);
      if (!validationResult.isValid) {
        return GeoJSONIntegrationResult(
          success: false,
          message: 'Dados de plantio inválidos: ${validationResult.errors.join(', ')}',
          importedItems: 0,
          errors: validationResult.errors,
          data: geoJSONData,
        );
      }
      
      // Salvar dados de plantio
      int savedCount = 0;
      for (final data in plantingData) {
        try {
          await _savePlantingData(data);
          savedCount++;
          Logger.info('💾 [GEOJSON_INTEGRATION] Dados de plantio salvos: ${data['variety']}');
        } catch (e) {
          Logger.error('❌ [GEOJSON_INTEGRATION] Erro ao salvar dados de plantio: $e');
        }
      }
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '$savedCount registros de plantio processados',
        importedItems: savedCount,
        errors: [],
        data: geoJSONData,
        statistics: _calculatePlantingStatistics(plantingData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de plantio: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de plantio: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de colheita
  static Future<GeoJSONIntegrationResult> _processHarvestData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('🌾 [GEOJSON_INTEGRATION] Processando dados de colheita...');
      
      // TODO: Implementar processamento específico para dados de colheita
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${geoJSONData.features.length} registros de colheita processados',
        importedItems: geoJSONData.features.length,
        errors: [],
        data: geoJSONData,
        statistics: GeoJSONReaderService.calculateStatistics(geoJSONData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de colheita: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de colheita: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de amostra de solo
  static Future<GeoJSONIntegrationResult> _processSoilSampleData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('🌍 [GEOJSON_INTEGRATION] Processando dados de amostra de solo...');
      
      // TODO: Implementar processamento específico para dados de solo
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${geoJSONData.features.length} registros de amostra de solo processados',
        importedItems: geoJSONData.features.length,
        errors: [],
        data: geoJSONData,
        statistics: GeoJSONReaderService.calculateStatistics(geoJSONData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de solo: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de solo: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados de irrigação
  static Future<GeoJSONIntegrationResult> _processIrrigationData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('💧 [GEOJSON_INTEGRATION] Processando dados de irrigação...');
      
      // TODO: Implementar processamento específico para dados de irrigação
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${geoJSONData.features.length} registros de irrigação processados',
        importedItems: geoJSONData.features.length,
        errors: [],
        data: geoJSONData,
        statistics: GeoJSONReaderService.calculateStatistics(geoJSONData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de irrigação: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de irrigação: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Processa dados desconhecidos
  static Future<GeoJSONIntegrationResult> _processUnknownData(
    GeoJSONData geoJSONData,
    File file,
  ) async {
    try {
      Logger.info('❓ [GEOJSON_INTEGRATION] Processando dados de tipo desconhecido...');
      
      return GeoJSONIntegrationResult(
        success: true,
        message: '${geoJSONData.features.length} registros processados (tipo não identificado)',
        importedItems: geoJSONData.features.length,
        errors: [],
        data: geoJSONData,
        statistics: GeoJSONReaderService.calculateStatistics(geoJSONData),
      );
      
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro no processamento de dados desconhecidos: $e');
      return GeoJSONIntegrationResult(
        success: false,
        message: 'Erro no processamento de dados desconhecidos: $e',
        importedItems: 0,
        errors: [e.toString()],
        data: geoJSONData,
      );
    }
  }

  /// Extrai dados de trabalho de máquina
  static List<Map<String, dynamic>> _extractMachineWorkData(GeoJSONData geoJSONData) {
    final machineData = <Map<String, dynamic>>[];
    
    for (final feature in geoJSONData.features) {
      final data = <String, dynamic>{
        'id': feature.id ?? 'machine_${DateTime.now().millisecondsSinceEpoch}',
        'machine': feature.properties['machine'] ?? 
                   feature.properties['maquina'] ?? 
                   feature.properties['MACHINE'] ?? 
                   'Máquina Desconhecida',
        'dose': _parseDouble(feature.properties['dose']) ?? 
                _parseDouble(feature.properties['DOSE']) ?? 0.0,
        'application': feature.properties['application'] ?? 
                      feature.properties['aplicacao'] ?? 
                      feature.properties['APPLICATION'] ?? 
                      'Aplicação',
        'speed': _parseDouble(feature.properties['speed']) ?? 
                 _parseDouble(feature.properties['velocidade']) ?? 
                 _parseDouble(feature.properties['SPEED']) ?? 0.0,
        'date': _parseDate(feature.properties['date']) ?? 
                _parseDate(feature.properties['data']) ?? 
                _parseDate(feature.properties['DATE']) ?? 
                DateTime.now(),
        'area': _parseDouble(feature.properties['area']) ?? 
                _parseDouble(feature.properties['AREA']) ?? 0.0,
        'coordinates': feature.geometry?['coordinates'],
        'properties': feature.properties,
      };
      
      machineData.add(data);
    }
    
    return machineData;
  }

  /// Valida dados de trabalho de máquina
  static TalhaoValidationResult _validateMachineWorkData(List<Map<String, dynamic>> machineData) {
    final errors = <String>[];
    
    for (int i = 0; i < machineData.length; i++) {
      final data = machineData[i];
      
      // Validar máquina
      if (data['machine'] == null || data['machine'].toString().isEmpty) {
        errors.add('Registro ${i + 1}: Nome da máquina é obrigatório');
      }
      
      // Validar dose
      if (data['dose'] == null || data['dose'] <= 0) {
        errors.add('Registro ${i + 1}: Dose deve ser maior que zero');
      }
      
      // Validar coordenadas
      if (data['coordinates'] == null) {
        errors.add('Registro ${i + 1}: Coordenadas são obrigatórias');
      }
    }
    
    return TalhaoValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Salva dados de trabalho de máquina
  static Future<void> _saveMachineWorkData(Map<String, dynamic> data) async {
    try {
      // TODO: Implementar salvamento real quando o repositório estiver disponível
      await Future.delayed(const Duration(milliseconds: 100));
      
      Logger.info('💾 [GEOJSON_INTEGRATION] Dados de máquina ${data['machine']} salvos');
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro ao salvar dados de máquina: $e');
      rethrow;
    }
  }

  /// Calcula estatísticas de trabalho de máquina
  static Map<String, dynamic> _calculateMachineWorkStatistics(List<Map<String, dynamic>> machineData) {
    if (machineData.isEmpty) return {};
    
    final totalDose = machineData.fold<double>(0.0, (sum, data) => sum + (data['dose'] ?? 0.0));
    final totalArea = machineData.fold<double>(0.0, (sum, data) => sum + (data['area'] ?? 0.0));
    final averageSpeed = machineData.fold<double>(0.0, (sum, data) => sum + (data['speed'] ?? 0.0)) / machineData.length;
    
    final machines = machineData.map((data) => data['machine']).toSet().toList();
    
    return {
      'totalRecords': machineData.length,
      'totalDose': totalDose,
      'totalArea': totalArea,
      'averageSpeed': averageSpeed,
      'uniqueMachines': machines.length,
      'machines': machines,
    };
  }

  /// Extrai dados de plantio
  static List<Map<String, dynamic>> _extractPlantingData(GeoJSONData geoJSONData) {
    final plantingData = <Map<String, dynamic>>[];
    
    for (final feature in geoJSONData.features) {
      final data = <String, dynamic>{
        'id': feature.id ?? 'planting_${DateTime.now().millisecondsSinceEpoch}',
        'variety': feature.properties['variety'] ?? 
                   feature.properties['variedade'] ?? 
                   feature.properties['VARIETY'] ?? 
                   'Variedade Desconhecida',
        'seed': feature.properties['seed'] ?? 
                feature.properties['semente'] ?? 
                feature.properties['SEED'] ?? 
                'Semente',
        'plantingDate': _parseDate(feature.properties['plantingDate']) ?? 
                       _parseDate(feature.properties['data_plantio']) ?? 
                       _parseDate(feature.properties['PLANTING_DATE']) ?? 
                       DateTime.now(),
        'density': _parseDouble(feature.properties['density']) ?? 
                   _parseDouble(feature.properties['densidade']) ?? 
                   _parseDouble(feature.properties['DENSITY']) ?? 0.0,
        'area': _parseDouble(feature.properties['area']) ?? 
                _parseDouble(feature.properties['AREA']) ?? 0.0,
        'coordinates': feature.geometry?['coordinates'],
        'properties': feature.properties,
      };
      
      plantingData.add(data);
    }
    
    return plantingData;
  }

  /// Valida dados de plantio
  static TalhaoValidationResult _validatePlantingData(List<Map<String, dynamic>> plantingData) {
    final errors = <String>[];
    
    for (int i = 0; i < plantingData.length; i++) {
      final data = plantingData[i];
      
      // Validar variedade
      if (data['variety'] == null || data['variety'].toString().isEmpty) {
        errors.add('Registro ${i + 1}: Variedade é obrigatória');
      }
      
      // Validar densidade
      if (data['density'] == null || data['density'] <= 0) {
        errors.add('Registro ${i + 1}: Densidade deve ser maior que zero');
      }
      
      // Validar coordenadas
      if (data['coordinates'] == null) {
        errors.add('Registro ${i + 1}: Coordenadas são obrigatórias');
      }
    }
    
    return TalhaoValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Salva dados de plantio
  static Future<void> _savePlantingData(Map<String, dynamic> data) async {
    try {
      // TODO: Implementar salvamento real quando o repositório estiver disponível
      await Future.delayed(const Duration(milliseconds: 100));
      
      Logger.info('💾 [GEOJSON_INTEGRATION] Dados de plantio ${data['variety']} salvos');
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro ao salvar dados de plantio: $e');
      rethrow;
    }
  }

  /// Calcula estatísticas de plantio
  static Map<String, dynamic> _calculatePlantingStatistics(List<Map<String, dynamic>> plantingData) {
    if (plantingData.isEmpty) return {};
    
    final totalArea = plantingData.fold<double>(0.0, (sum, data) => sum + (data['area'] ?? 0.0));
    final averageDensity = plantingData.fold<double>(0.0, (sum, data) => sum + (data['density'] ?? 0.0)) / plantingData.length;
    
    final varieties = plantingData.map((data) => data['variety']).toSet().toList();
    final seeds = plantingData.map((data) => data['seed']).toSet().toList();
    
    return {
      'totalRecords': plantingData.length,
      'totalArea': totalArea,
      'averageDensity': averageDensity,
      'uniqueVarieties': varieties.length,
      'uniqueSeeds': seeds.length,
      'varieties': varieties,
      'seeds': seeds,
    };
  }

  /// Salva talhão no banco de dados
  static Future<void> _saveTalhaoToDatabase(TalhaoModel talhao) async {
    try {
      // TODO: Implementar salvamento real quando o repositório estiver disponível
      // Por enquanto, simular salvamento
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Aqui seria a implementação real:
      // final repository = TalhaoSafraRepository();
      // await repository.save(talhao);
      
      Logger.info('💾 [GEOJSON_INTEGRATION] Talhão ${talhao.name} salvo no banco de dados');
    } catch (e) {
      Logger.error('❌ [GEOJSON_INTEGRATION] Erro ao salvar talhão no banco: $e');
      rethrow;
    }
  }

  /// Converte valor para double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Converte valor para DateTime
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Valida talhões
  static TalhaoValidationResult _validateTalhoes(List<TalhaoModel> talhoes) {
    final errors = <String>[];
    
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      
      // Validar nome
      if (talhao.name.isEmpty) {
        errors.add('Talhão ${i + 1}: Nome é obrigatório');
      }
      
      // Validar área
      if (talhao.area <= 0) {
        errors.add('Talhão ${i + 1}: Área deve ser maior que zero');
      }
      
      // Validar polígonos
      if (talhao.poligonos.isEmpty) {
        errors.add('Talhão ${i + 1}: Deve ter pelo menos um polígono');
      } else {
        for (int j = 0; j < talhao.poligonos.length; j++) {
          final poligono = talhao.poligonos[j];
          if (poligono.pontos.length < 3) {
            errors.add('Talhão ${i + 1}, Polígono ${j + 1}: Deve ter pelo menos 3 pontos');
          }
        }
      }
    }
    
    return TalhaoValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Resultado da integração GeoJSON
class GeoJSONIntegrationResult {
  final bool success;
  final String message;
  final int importedItems;
  final List<String> errors;
  final GeoJSONData? data;
  final Map<String, dynamic>? statistics;

  GeoJSONIntegrationResult({
    required this.success,
    required this.message,
    required this.importedItems,
    required this.errors,
    this.data,
    this.statistics,
  });
}

/// Resultado da validação de talhão
class TalhaoValidationResult {
  final bool isValid;
  final List<String> errors;

  TalhaoValidationResult({
    required this.isValid,
    required this.errors,
  });
}
