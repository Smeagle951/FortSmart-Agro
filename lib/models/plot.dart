import 'dart:convert';

class Plot {
  final String? id;
  final String name; // Não pode ser nulo
  final double? area;
  final List<Map<String, double>>? coordinates;
  final int farmId; // Não pode ser nulo
  final int propertyId; // Não pode ser nulo
  final String? cropType;
  final String? plantingDate;
  final String? harvestDate;
  final String createdAt; // Não pode ser nulo
  final String updatedAt; // Não pode ser nulo
  final int? syncStatus;
  final int? remoteId;
  final String? polygonJson;
  // Campos adicionais que estavam faltando
  final String? description;
  final String? cropName;
  final Map<String, dynamic>? geometry;
  final String? notes;
  final bool isSynced;
  final String? safraInfo; // Informação da safra atual
  final String? culturaId; // ID da cultura associada

  Plot({
    this.id,
    required this.name,
    this.area,
    this.coordinates,
    required this.farmId,
    required this.propertyId,
    this.cropType,
    this.plantingDate,
    this.harvestDate,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus,
    this.remoteId,
    this.polygonJson,
    this.description,
    this.cropName,
    this.geometry,
    this.notes,
    this.isSynced = false,
    this.safraInfo,
    this.culturaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'coordinates': coordinates,
      'farmId': farmId,
      'propertyId': propertyId,
      'cropType': cropType,
      'plantingDate': plantingDate,
      'harvestDate': harvestDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
      'remoteId': remoteId,
      'polygonJson': polygonJson,
      'description': description,
      'cropName': cropName,
      'geometry': geometry,
      'notes': notes,
      'isSynced': isSynced,
      'safraInfo': safraInfo,
      'culturaId': culturaId,
    };
  }

  factory Plot.fromMap(Map<String, dynamic> map) {
    // Tenta converter o polygon_json para uma lista de coordenadas
    List<Map<String, double>>? coords;
    if (map['polygon_json'] != null) {
      try {
        final List<dynamic> decodedJson = jsonDecode(map['polygon_json']);
        coords = decodedJson.map<Map<String, double>>((item) {
          return {
            'latitude': item['latitude'] is double ? item['latitude'] : double.tryParse(item['latitude'].toString()) ?? 0.0,
            'longitude': item['longitude'] is double ? item['longitude'] : double.tryParse(item['longitude'].toString()) ?? 0.0,
          };
        }).toList();
      } catch (e) {
        print('Erro ao decodificar polygon_json: $e');
        coords = null;
      }
    }

    return Plot(
      id: map['id'],
      name: map['name'] ?? 'Sem nome', // Valor padrão para evitar nulos
      area: map['area'] is double ? map['area'] : double.tryParse(map['area']?.toString() ?? '0'),
      coordinates: coords,
      propertyId: map['property_id'] is int ? map['property_id'] : int.tryParse(map['property_id']?.toString() ?? '0') ?? 0,
      farmId: map['farm_id'] is int ? map['farm_id'] : int.tryParse(map['farm_id']?.toString() ?? '0') ?? 0,
      cropType: map['crop_type'],
      cropName: map['crop_name'],
      description: map['description'],
      plantingDate: map['planting_date'],
      harvestDate: map['harvest_date'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
      syncStatus: map['sync_status'],
      remoteId: map['remote_id'],
      polygonJson: map['polygon_json'],
      geometry: map['geometry'],
      notes: map['notes'],
      isSynced: map['is_synced'] == 1,
      safraInfo: map['safraInfo'],
      culturaId: map['culturaId'],
    );
  }

  // Cria uma cópia do objeto com alterações
  Plot copyWith({
    String? id,
    String? name,
    double? area,
    List<Map<String, double>>? coordinates,
    int? farmId,
    int? propertyId,
    String? cropType,
    String? cropName,
    String? description,
    String? plantingDate,
    String? harvestDate,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
    int? remoteId,
    String? polygonJson,
    Map<String, dynamic>? geometry,
    String? notes,
    bool? isSynced,
    String? safraInfo,
    String? culturaId,
  }) {
    return Plot(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      coordinates: coordinates ?? this.coordinates,
      farmId: farmId ?? this.farmId,
      propertyId: propertyId ?? this.propertyId,
      cropType: cropType ?? this.cropType,
      cropName: cropName ?? this.cropName,
      description: description ?? this.description,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      polygonJson: polygonJson ?? this.polygonJson,
      geometry: geometry ?? this.geometry,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      safraInfo: safraInfo ?? this.safraInfo,
      culturaId: culturaId ?? this.culturaId,
    );
  }

  // Método para calcular o centro do polígono (centroide)
  Map<String, double> getCenter() {
    if (coordinates == null || coordinates!.isEmpty) {
      return {'latitude': 0, 'longitude': 0};
    }

    double sumLat = 0;
    double sumLng = 0;

    for (var coord in coordinates!) {
      sumLat += coord['latitude'] ?? 0;
      sumLng += coord['longitude'] ?? 0;
    }

    return {
      'latitude': sumLat / coordinates!.length,
      'longitude': sumLng / coordinates!.length,
    };
  }

  // Método para obter coordenadas do polygonJson
  List<Map<String, double>> getCoordinates() {
    if (coordinates != null) {
      return coordinates!;
    }
    
    if (polygonJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(polygonJson!);
        return decoded.map<Map<String, double>>((coord) {
          if (coord is Map) {
            return {
              'latitude': (coord['latitude'] is num) 
                  ? (coord['latitude'] as num).toDouble() 
                  : 0.0,
              'longitude': (coord['longitude'] is num) 
                  ? (coord['longitude'] as num).toDouble() 
                  : 0.0,
            };
          }
          return {'latitude': 0.0, 'longitude': 0.0};
        }).toList();
      } catch (e) {
        print('Erro ao decodificar coordenadas: $e');
      }
    }
    
    return [];
  }

  // Método para verificar se um ponto está dentro do polígono
  bool containsPoint(double latitude, double longitude) {
    final coords = getCoordinates();
    if (coords.length < 3) return false;

    bool isInside = false;
    int j = coords.length - 1;

    for (int i = 0; i < coords.length; i++) {
      final lat1 = coords[i]['latitude'] ?? 0;
      final lng1 = coords[i]['longitude'] ?? 0;
      final lat2 = coords[j]['latitude'] ?? 0;
      final lng2 = coords[j]['longitude'] ?? 0;

      final isPointBetweenLatitudes = 
          (lat1 < latitude && lat2 >= latitude) || 
          (lat2 < latitude && lat1 >= latitude);
      
      if (isPointBetweenLatitudes && 
          lat1 != lat2 && 
          longitude < lng1 + (latitude - lat1) / (lat2 - lat1) * (lng2 - lng1)) {
        isInside = !isInside;
      }

      j = i;
    }

    return isInside;
  }

  // Método para calcular a área do polígono em hectares
  double calculateAreaInHectares() {
    final coords = getCoordinates();
    if (coords.length < 3) return 0;

    double area = 0;
    int j = coords.length - 1;

    for (int i = 0; i < coords.length; i++) {
      final lat1 = coords[i]['latitude'] ?? 0;
      final lng1 = coords[i]['longitude'] ?? 0;
      final lat2 = coords[j]['latitude'] ?? 0;
      final lng2 = coords[j]['longitude'] ?? 0;

      // Fórmula da área de Gauss (Shoelace formula)
      area += (lng1 + lng2) * (lat1 - lat2);
      j = i;
    }

    // Converte para hectares usando fator de conversão consistente
    // 1 grau² ≈ 111 km² na latitude média do Brasil
    const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
    return (area.abs() / 2) * grauParaHectares;
  }

  @override
  String toString() {
    return 'Plot(id: $id, name: $name, area: $area, farmId: $farmId, propertyId: $propertyId)';
  }
}
