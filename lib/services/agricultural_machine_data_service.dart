import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../utils/logger.dart';

/// Tipos de máquinas agrícolas suportadas
enum MachineType {
  jactoNPK,        // Jacto NPK 5030
  staraPlantio,    // Stara Plantio
  staraColheita,   // Stara Colheita
  staraAplicacao,  // Stara Aplicação
  johnDeerePlantio, // John Deere Plantio
  johnDeereColheita, // John Deere Colheita
  johnDeereAplicacao, // John Deere Aplicação
  casePlantio,     // Case Plantio
  caseColheita,    // Case Colheita
  newHolland,      // New Holland
  masseyFerguson,  // Massey Ferguson
  valtra,          // Valtra
  fendt,           // Fendt
  desconhecido     // Tipo não identificado
}

/// Tipos de operações agrícolas
enum OperationType {
  plantio,         // Plantio
  colheita,        // Colheita
  aplicacao,       // Aplicação de defensivos/fertilizantes
  pulverizacao,    // Pulverização
  adubacao,        // Adubação
  semeadura,       // Semeadura
  capina,          // Capina
  gradagem,        // Gradagem
  desconhecido     // Operação não identificada
}

/// Dados de trabalho de máquina agrícola
class MachineWorkData {
  final String id;
  final MachineType machineType;
  final OperationType operationType;
  final String machineModel;
  final String operatorName;
  final DateTime workDate;
  final List<WorkPoint> workPoints;
  final WorkStatistics statistics;
  final Map<String, dynamic> metadata;

  MachineWorkData({
    required this.id,
    required this.machineType,
    required this.operationType,
    required this.machineModel,
    required this.operatorName,
    required this.workDate,
    required this.workPoints,
    required this.statistics,
    required this.metadata,
  });

  /// Converte para talhões com dados de trabalho
  List<TalhaoModel> toTalhoesWithWorkData() {
    final talhoes = <TalhaoModel>[];
    final groupedPoints = _groupPointsByArea();

    for (final entry in groupedPoints.entries) {
      final areaId = entry.key;
      final points = entry.value;
      
      if (points.isNotEmpty) {
        final talhao = _createTalhaoFromWorkPoints(areaId, points);
        talhoes.add(talhao);
      }
    }

    return talhoes;
  }

  /// Agrupa pontos por área de trabalho
  Map<String, List<WorkPoint>> _groupPointsByArea() {
    final grouped = <String, List<WorkPoint>>{};
    
    for (final point in workPoints) {
      final areaId = point.areaId ?? 'area_${point.id}';
      grouped.putIfAbsent(areaId, () => []).add(point);
    }
    
    return grouped;
  }

  /// Cria talhão a partir de pontos de trabalho
  TalhaoModel _createTalhaoFromWorkPoints(String areaId, List<WorkPoint> points) {
    final firstPoint = points.first;
    final lastPoint = points.last;
    
    // Calcular área aproximada
    final area = _calculateWorkArea(points);
    
    // Criar polígono baseado nos pontos
    final polygon = _createPolygonFromPoints(points);
    
    return TalhaoModel(
      id: areaId,
      name: 'Área de Trabalho - ${machineModel}',
      area: area,
      culturaId: firstPoint.cropType,
      fazendaId: '1',
      poligonos: [polygon],
      dataCriacao: workDate,
      dataAtualizacao: workDate,
      safras: [],
    );
  }

  /// Calcula área de trabalho
  double _calculateWorkArea(List<WorkPoint> points) {
    if (points.length < 3) return 0.0;
    
    // Usar fórmula de Shoelace
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares
    final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latRad = latMedia * pi / 180;
    final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latRad) + 1.175 * cos(4 * latRad);
    final metersPerDegLng = (pi / 180) * 6378137.0 * cos(latRad);
    
    final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
    return areaMetersSquared / 10000.0;
  }

  /// Cria polígono a partir dos pontos
  PoligonoModel _createPolygonFromPoints(List<WorkPoint> points) {
    final polygonPoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    
    return PoligonoModel(
      id: '${id}_polygon',
      pontos: polygonPoints,
      dataCriacao: workDate,
      dataAtualizacao: workDate,
      ativo: true,
      area: _calculateWorkArea(points),
      perimetro: 0.0,
      talhaoId: '${id}_talhao',
    );
  }
}

/// Ponto de trabalho da máquina
class WorkPoint {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;           // Velocidade em km/h
  final double applicationRate; // Taxa de aplicação em kg/ha
  final double totalApplied;    // Total aplicado em kg
  final double areaCovered;     // Área coberta em ha
  final String? areaId;         // ID da área de trabalho
  final String? cropType;       // Tipo de cultura
  final Map<String, dynamic> additionalData;

  WorkPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speed,
    required this.applicationRate,
    required this.totalApplied,
    required this.areaCovered,
    this.areaId,
    this.cropType,
    required this.additionalData,
  });
}

/// Estatísticas de trabalho
class WorkStatistics {
  final double totalArea;           // Área total trabalhada em ha
  final double totalApplied;        // Total aplicado em kg
  final double averageSpeed;        // Velocidade média em km/h
  final double averageApplicationRate; // Taxa média de aplicação em kg/ha
  final double totalWorkTime;       // Tempo total de trabalho em horas
  final double efficiency;          // Eficiência de trabalho
  final Map<String, double> performanceMetrics;

  WorkStatistics({
    required this.totalArea,
    required this.totalApplied,
    required this.averageSpeed,
    required this.averageApplicationRate,
    required this.totalWorkTime,
    required this.efficiency,
    required this.performanceMetrics,
  });
}

/// Serviço para leitura e processamento de dados de máquinas agrícolas
class AgriculturalMachineDataService {
  static const String _tag = 'MachineDataService';

  /// Lê arquivo de dados de máquina agrícola
  static Future<MachineWorkData?> readMachineDataFile() async {
    try {
      Logger.info('$_tag: Iniciando leitura de dados de máquina...');
      
      // Permitir seleção de arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['shp', 'csv', 'txt', 'dat', 'log'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        Logger.info('$_tag: Nenhum arquivo selecionado');
        return null;
      }

      final file = File(result.files.first.path!);
      final fileName = path.basenameWithoutExtension(file.path);
      
      Logger.info('$_tag: Arquivo selecionado: $fileName');

      // Detectar tipo de máquina pelo nome do arquivo
      final machineType = _detectMachineType(fileName);
      
      // Ler dados do arquivo
      final workData = await _parseMachineDataFile(file, machineType);
      
      if (workData != null) {
        Logger.info('$_tag: Dados de máquina lidos com sucesso - ${workData.workPoints.length} pontos');
        Logger.info('$_tag: Tipo de máquina: ${workData.machineType}');
        Logger.info('$_tag: Tipo de operação: ${workData.operationType}');
      }
      
      return workData;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao ler dados de máquina: $e');
      return null;
    }
  }

  /// Detecta tipo de máquina pelo nome do arquivo
  static MachineType _detectMachineType(String fileName) {
    final fileNameLower = fileName.toLowerCase();
    
    // Jacto
    if (fileNameLower.contains('jacto') || fileNameLower.contains('npk')) {
      return MachineType.jactoNPK;
    }
    
    // Stara
    if (fileNameLower.contains('stara')) {
      if (fileNameLower.contains('plantio')) return MachineType.staraPlantio;
      if (fileNameLower.contains('colheita')) return MachineType.staraColheita;
      if (fileNameLower.contains('aplicacao') || fileNameLower.contains('aplicação')) {
        return MachineType.staraAplicacao;
      }
      return MachineType.staraPlantio; // Default
    }
    
    // John Deere
    if (fileNameLower.contains('john') || fileNameLower.contains('deere')) {
      if (fileNameLower.contains('plantio')) return MachineType.johnDeerePlantio;
      if (fileNameLower.contains('colheita')) return MachineType.johnDeereColheita;
      if (fileNameLower.contains('aplicacao') || fileNameLower.contains('aplicação')) {
        return MachineType.johnDeereAplicacao;
      }
      return MachineType.johnDeerePlantio; // Default
    }
    
    // Case
    if (fileNameLower.contains('case')) {
      if (fileNameLower.contains('plantio')) return MachineType.casePlantio;
      if (fileNameLower.contains('colheita')) return MachineType.caseColheita;
      return MachineType.casePlantio; // Default
    }
    
    // Outras marcas
    if (fileNameLower.contains('newholland') || fileNameLower.contains('new holland')) {
      return MachineType.newHolland;
    }
    if (fileNameLower.contains('massey') || fileNameLower.contains('ferguson')) {
      return MachineType.masseyFerguson;
    }
    if (fileNameLower.contains('valtra')) {
      return MachineType.valtra;
    }
    if (fileNameLower.contains('fendt')) {
      return MachineType.fendt;
    }
    
    return MachineType.desconhecido;
  }

  /// Detecta tipo de operação pelo nome do arquivo
  static OperationType _detectOperationType(String fileName) {
    final fileNameLower = fileName.toLowerCase();
    
    if (fileNameLower.contains('plantio')) return OperationType.plantio;
    if (fileNameLower.contains('colheita')) return OperationType.colheita;
    if (fileNameLower.contains('aplicacao') || fileNameLower.contains('aplicação')) {
      return OperationType.aplicacao;
    }
    if (fileNameLower.contains('pulverizacao') || fileNameLower.contains('pulverização')) {
      return OperationType.pulverizacao;
    }
    if (fileNameLower.contains('adubacao') || fileNameLower.contains('adubação')) {
      return OperationType.adubacao;
    }
    if (fileNameLower.contains('semeadura')) return OperationType.semeadura;
    if (fileNameLower.contains('capina')) return OperationType.capina;
    if (fileNameLower.contains('gradagem')) return OperationType.gradagem;
    
    return OperationType.desconhecido;
  }

  /// Parse dos dados do arquivo de máquina
  static Future<MachineWorkData?> _parseMachineDataFile(File file, MachineType machineType) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      
      switch (extension) {
        case '.shp':
          return await _parseShapefileData(file, machineType);
        case '.csv':
          return await _parseCsvData(file, machineType);
        case '.txt':
        case '.dat':
        case '.log':
          return await _parseTextData(file, machineType);
        default:
          Logger.error('$_tag: Formato de arquivo não suportado: $extension');
          return null;
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear dados de máquina: $e');
      return null;
    }
  }

  /// Parse de dados Shapefile
  static Future<MachineWorkData?> _parseShapefileData(File file, MachineType machineType) async {
    // Implementar parse específico para Shapefile de máquinas
    // Por enquanto, retornar dados simulados
    return _createSampleMachineData(machineType);
  }

  /// Parse de dados CSV
  static Future<MachineWorkData?> _parseCsvData(File file, MachineType machineType) async {
    try {
      final lines = await file.readAsLines();
      if (lines.isEmpty) return null;
      
      final header = lines.first.split(',');
      final workPoints = <WorkPoint>[];
      
      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split(',');
        if (values.length >= header.length) {
          final point = _createWorkPointFromCsvRow(header, values);
          if (point != null) {
            workPoints.add(point);
          }
        }
      }
      
      if (workPoints.isEmpty) return null;
      
      return MachineWorkData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        machineType: machineType,
        operationType: _detectOperationType(file.path),
        machineModel: _getMachineModel(machineType),
        operatorName: 'Operador',
        workDate: DateTime.now(),
        workPoints: workPoints,
        statistics: _calculateWorkStatistics(workPoints),
        metadata: {'source': 'csv', 'file': file.path},
      );
    } catch (e) {
      Logger.error('$_tag: Erro ao parsear CSV: $e');
      return null;
    }
  }

  /// Parse de dados de texto
  static Future<MachineWorkData?> _parseTextData(File file, MachineType machineType) async {
    // Implementar parse específico para arquivos de texto de máquinas
    // Por enquanto, retornar dados simulados
    return _createSampleMachineData(machineType);
  }

  /// Cria ponto de trabalho a partir de linha CSV
  static WorkPoint? _createWorkPointFromCsvRow(List<String> header, List<String> values) {
    try {
      final data = <String, dynamic>{};
      for (int i = 0; i < header.length && i < values.length; i++) {
        data[header[i].trim()] = values[i].trim();
      }
      
      return WorkPoint(
        id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
        longitude: double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
        speed: double.tryParse(data['speed']?.toString() ?? '0') ?? 0.0,
        applicationRate: double.tryParse(data['application_rate']?.toString() ?? '0') ?? 0.0,
        totalApplied: double.tryParse(data['total_applied']?.toString() ?? '0') ?? 0.0,
        areaCovered: double.tryParse(data['area_covered']?.toString() ?? '0') ?? 0.0,
        areaId: data['area_id']?.toString(),
        cropType: data['crop_type']?.toString(),
        additionalData: data,
      );
    } catch (e) {
      Logger.error('$_tag: Erro ao criar ponto de trabalho: $e');
      return null;
    }
  }

  /// Calcula estatísticas de trabalho
  static WorkStatistics _calculateWorkStatistics(List<WorkPoint> points) {
    if (points.isEmpty) {
      return WorkStatistics(
        totalArea: 0.0,
        totalApplied: 0.0,
        averageSpeed: 0.0,
        averageApplicationRate: 0.0,
        totalWorkTime: 0.0,
        efficiency: 0.0,
        performanceMetrics: {},
      );
    }
    
    final totalArea = points.fold(0.0, (sum, p) => sum + p.areaCovered);
    final totalApplied = points.fold(0.0, (sum, p) => sum + p.totalApplied);
    final averageSpeed = points.fold(0.0, (sum, p) => sum + p.speed) / points.length;
    final averageApplicationRate = points.fold(0.0, (sum, p) => sum + p.applicationRate) / points.length;
    
    final firstTime = points.map((p) => p.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastTime = points.map((p) => p.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalWorkTime = lastTime.difference(firstTime).inHours.toDouble();
    
    final efficiency = totalArea > 0 ? (totalApplied / totalArea) : 0.0;
    
    return WorkStatistics(
      totalArea: totalArea,
      totalApplied: totalApplied,
      averageSpeed: averageSpeed,
      averageApplicationRate: averageApplicationRate,
      totalWorkTime: totalWorkTime,
      efficiency: efficiency,
      performanceMetrics: {
        'max_speed': points.map((p) => p.speed).reduce((a, b) => a > b ? a : b),
        'min_speed': points.map((p) => p.speed).reduce((a, b) => a < b ? a : b),
        'max_application_rate': points.map((p) => p.applicationRate).reduce((a, b) => a > b ? a : b),
        'min_application_rate': points.map((p) => p.applicationRate).reduce((a, b) => a < b ? a : b),
      },
    );
  }

  /// Obtém modelo da máquina
  static String _getMachineModel(MachineType type) {
    switch (type) {
      case MachineType.jactoNPK:
        return 'Jacto NPK 5030';
      case MachineType.staraPlantio:
        return 'Stara Plantio';
      case MachineType.staraColheita:
        return 'Stara Colheita';
      case MachineType.staraAplicacao:
        return 'Stara Aplicação';
      case MachineType.johnDeerePlantio:
        return 'John Deere Plantio';
      case MachineType.johnDeereColheita:
        return 'John Deere Colheita';
      case MachineType.johnDeereAplicacao:
        return 'John Deere Aplicação';
      case MachineType.casePlantio:
        return 'Case Plantio';
      case MachineType.caseColheita:
        return 'Case Colheita';
      case MachineType.newHolland:
        return 'New Holland';
      case MachineType.masseyFerguson:
        return 'Massey Ferguson';
      case MachineType.valtra:
        return 'Valtra';
      case MachineType.fendt:
        return 'Fendt';
      case MachineType.desconhecido:
        return 'Máquina Desconhecida';
    }
  }

  /// Cria dados de exemplo para teste
  static MachineWorkData _createSampleMachineData(MachineType machineType) {
    final workPoints = <WorkPoint>[];
    final now = DateTime.now();
    
    // Criar pontos de exemplo
    for (int i = 0; i < 100; i++) {
      workPoints.add(WorkPoint(
        id: 'point_$i',
        latitude: -15.7801 + (i * 0.0001),
        longitude: -47.9292 + (i * 0.0001),
        timestamp: now.add(Duration(minutes: i)),
        speed: 8.0 + (i % 5) * 2.0, // 8-16 km/h
        applicationRate: 50.0 + (i % 20) * 5.0, // 50-150 kg/ha
        totalApplied: 100.0 + (i % 10) * 10.0, // 100-200 kg
        areaCovered: 0.1 + (i % 5) * 0.05, // 0.1-0.35 ha
        areaId: 'area_${i ~/ 10}',
        cropType: 'Soja',
        additionalData: {
          'temperature': 25.0 + (i % 10),
          'humidity': 60.0 + (i % 20),
          'wind_speed': 5.0 + (i % 5),
        },
      ));
    }
    
    return MachineWorkData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      machineType: machineType,
      operationType: OperationType.aplicacao,
      machineModel: _getMachineModel(machineType),
      operatorName: 'João Silva',
      workDate: now,
      workPoints: workPoints,
      statistics: _calculateWorkStatistics(workPoints),
      metadata: {
        'source': 'sample',
        'created_at': now.toIso8601String(),
      },
    );
  }
}
