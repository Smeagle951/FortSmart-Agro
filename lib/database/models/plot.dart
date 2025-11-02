import 'dart:convert';
import '../models/plot.dart' as AppModel;

class Plot {
  int? id;
  int propertyId;
  int farmId; // Campo farmId explícito
  String name;
  double? area;
  String? cropType;
  String? plantingDate;
  String? harvestDate;
  String createdAt;
  String updatedAt;
  int syncStatus;
  int? remoteId;
  String? polygonJson;
  
  // Getter para compatibilidade com o modelo antigo
  List<Map<String, double>> get coordinates => getCoordinates();

  Plot({
    this.id,
    required this.propertyId,
    required this.farmId, // Agora é obrigatório
    required this.name,
    this.area,
    this.cropType,
    this.plantingDate,
    this.harvestDate,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
    this.polygonJson,
  });

  // Converter de Map para objeto Plot
  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['id'],
      propertyId: map['property_id'] ?? 0,
      farmId: map['farm_id'] ?? 0, // Garantir valor padrão
      name: map['name'] ?? '',
      area: map['area'],
      cropType: map['crop_type'],
      plantingDate: map['planting_date'],
      harvestDate: map['harvest_date'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
      syncStatus: map['sync_status'] ?? 0,
      remoteId: map['remote_id'],
      polygonJson: map['polygon_json'],
    );
  }

  // Converter de objeto Plot para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'farm_id': farmId, // Incluído no mapa
      'name': name,
      'area': area,
      'crop_type': cropType,
      'planting_date': plantingDate,
      'harvest_date': harvestDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'remote_id': remoteId,
      'polygon_json': polygonJson,
    };
  }

  // Criar uma cópia do objeto com alterações
  Plot copyWith({
    int? id,
    int? propertyId,
    int? farmId,
    String? name,
    double? area,
    String? cropType,
    String? plantingDate,
    String? harvestDate,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
    String? polygonJson,
  }) {
    return Plot(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      area: area ?? this.area,
      cropType: cropType ?? this.cropType,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      polygonJson: polygonJson ?? this.polygonJson,
    );
  }

  // Método para obter as coordenadas como uma lista de mapas
  List<Map<String, double>> getCoordinates() {
    return parseCoordinates();
  }
  
  // Método para compatibilidade com o modelo antigo
  List<Map<String, double>> parseCoordinates() {
    if (polygonJson == null || polygonJson!.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonData = jsonDecode(polygonJson!);
      return List<Map<String, double>>.from(
        jsonData.map((coord) => {
          'latitude': (coord['latitude'] is int) 
              ? (coord['latitude'] as int).toDouble() 
              : coord['latitude'] as double,
          'longitude': (coord['longitude'] is int) 
              ? (coord['longitude'] as int).toDouble() 
              : coord['longitude'] as double,
        }),
      );
    } catch (e) {
      print('Erro ao decodificar coordenadas: $e');
      return [];
    }
  }
  
  // Converter para o modelo de Plot da aplicação
  AppModel.Plot toAppModel() {
    // Criar um mapa intermediário com os dados do modelo do banco de dados
    final map = {
      'id': id?.toString(),
      'name': name,
      'area': area ?? 0.0,
      'coordinates': jsonEncode(getCoordinates()),
      'farmId': farmId.toString(), // Convertido para string
      'propertyId': propertyId,
      'description': null,
      'isSynced': syncStatus == 1 ? 1 : 0,
      'syncStatus': syncStatus,
    };
    
    // Usar o construtor fromMap do modelo da aplicação
    return AppModel.Plot.fromMap(map);
  }
  
  // Método estático para criar um Plot do banco de dados a partir de um Plot da aplicação
  static Plot fromAppModel(dynamic appPlot) {
    return Plot(
      id: appPlot.id != null ? int.tryParse(appPlot.id) : null,
      propertyId: appPlot.propertyId,
      farmId: appPlot.farmId != null ? int.tryParse(appPlot.farmId) ?? 0 : 0, // Converter de string para int
      name: appPlot.name,
      area: appPlot.area,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: appPlot.syncStatus ?? 0,
      polygonJson: appPlot.coordinates != null ? jsonEncode(appPlot.coordinates) : null,
    );
  }
}
