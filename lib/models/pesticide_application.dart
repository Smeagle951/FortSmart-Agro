import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Tipo de aplicação de defensivo
enum ApplicationType {
  ground,  // Terrestre
  aerial,  // Aérea
}

/// Modelo para representar uma aplicação de defensivo
class PesticideApplication {
  final String? id;
  final String plotId; // ID do talhão
  final String? plotName; // Nome do talhão
  final String? cropId; // ID da cultura
  final String? cropName; // Nome da cultura
  final String? productId; // ID do produto aplicado
  final String? productName; // Nome do produto
  final double? dose; // Dose (L ou g/ha)
  final String? doseUnit; // Unidade da dose (L/ha ou g/ha)
  final double? mixtureVolume; // Volume de calda (L/ha)
  final double? totalArea; // Área total (ha)
  final DateTime date; // Data da aplicação
  final String? responsiblePerson; // Responsável pela aplicação
  final ApplicationType? applicationType; // Tipo de aplicação
  final double? temperature; // Temperatura (°C)
  final double? humidity; // Umidade (%)
  final String? observations; // Observações
  final String? notes; // Notas adicionais
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isSynced;
  final List<String>? imageUrls; // URLs das imagens associadas à aplicação
  final String? status; // Status da aplicação
  final String? purpose; // Finalidade da aplicação
  final List<dynamic>? products; // Lista de produtos aplicados
  final List<dynamic>? productList; // Lista de produtos aplicados (novo formato)
  final double? applicationRate; // Taxa de aplicação (L/ha)
  final double? operationSpeed; // Velocidade de operação (km/h)
  final String? equipmentName; // Nome do equipamento
  final String? weather; // Condições climáticas

  /// Construtor
  PesticideApplication({
    this.id,
    required this.plotId,
    this.plotName,
    this.cropId,
    this.cropName,
    this.productId,
    this.productName,
    this.dose,
    this.doseUnit,
    this.mixtureVolume,
    this.totalArea,
    required this.date,
    this.responsiblePerson,
    this.applicationType,
    this.temperature,
    this.humidity,
    this.observations,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.imageUrls,
    this.status,
    this.purpose,
    this.products,
    this.productList,
    this.applicationRate,
    this.operationSpeed,
    this.equipmentName,
    this.weather,
  });

  /// Cria uma cópia do objeto com os campos atualizados
  PesticideApplication copyWith({
    String? id,
    String? plotId,
    String? plotName,
    String? cropId,
    String? cropName,
    String? productId,
    String? productName,
    double? dose,
    String? doseUnit,
    double? mixtureVolume,
    double? totalArea,
    DateTime? date,
    String? responsiblePerson,
    ApplicationType? applicationType,
    double? temperature,
    double? humidity,
    String? observations,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    List<String>? imageUrls,
    String? status,
    String? purpose,
    List<dynamic>? products,
    List<dynamic>? productList,
    double? applicationRate,
    double? operationSpeed,
    String? equipmentName,
    String? weather,
  }) {
    return PesticideApplication(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      dose: dose ?? this.dose,
      doseUnit: doseUnit ?? this.doseUnit,
      mixtureVolume: mixtureVolume ?? this.mixtureVolume,
      totalArea: totalArea ?? this.totalArea,
      date: date ?? this.date,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      applicationType: applicationType ?? this.applicationType,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      observations: observations ?? this.observations,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      products: products ?? this.products,
      productList: productList ?? this.productList,
      applicationRate: applicationRate ?? this.applicationRate,
      operationSpeed: operationSpeed ?? this.operationSpeed,
      equipmentName: equipmentName ?? this.equipmentName,
      weather: weather ?? this.weather,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'cropId': cropId ?? '1',
      'productId': productId ?? '1',
      'dose': dose ?? 0.0,
      'doseUnit': doseUnit ?? 'L/ha',
      'mixtureVolume': mixtureVolume ?? 0.0,
      'totalArea': totalArea ?? 0.0,
      'date': date.toIso8601String(),
      'applicationDate': date.toIso8601String(), // Mantendo para compatibilidade
      'responsiblePerson': responsiblePerson ?? '',
      'applicationType': applicationType?.index ?? 0,
      'temperature': temperature,
      'humidity': humidity,
      'observations': observations ?? '',
      'notes': notes ?? '',
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'isSynced': isSynced == true ? 1 : 0,
      'imageUrls': imageUrls, // Adicionado campo de imagens
      'status': status,
      'purpose': purpose,
      'productList': productList,
      'applicationRate': applicationRate,
      'operationSpeed': operationSpeed,
      'equipmentName': equipmentName,
      'weather': weather,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory PesticideApplication.fromMap(Map<String, dynamic> map) {
    // Processamento de imageUrls para garantir que seja uma List<String>
    List<String>? processedImageUrls;
    if (map['imageUrls'] != null) {
      if (map['imageUrls'] is List) {
        processedImageUrls = (map['imageUrls'] as List).map((e) => e.toString()).toList();
      } else if (map['imageUrls'] is String) {
        // Se for uma string JSON, tenta converter para lista
        try {
          final dynamic decoded = json.decode(map['imageUrls']);
          if (decoded is List) {
            processedImageUrls = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // Se não for um JSON válido, considera como uma única URL
          processedImageUrls = [map['imageUrls'].toString()];
        }
      }
    }
    
    return PesticideApplication(
      id: map['id'],
      plotId: map['plotId'],
      plotName: map['plotName'],
      cropId: map['cropId'],
      cropName: map['cropName'],
      productId: map['productId'],
      productName: map['productName'],
      dose: map['dose']?.toDouble(),
      doseUnit: map['doseUnit'],
      mixtureVolume: map['mixtureVolume']?.toDouble(),
      totalArea: map['totalArea']?.toDouble(),
      date: map['date'] != null ? DateTime.parse(map['date']) : (map['applicationDate'] != null ? DateTime.parse(map['applicationDate']) : DateTime.now()),
      responsiblePerson: map['responsiblePerson'],
      applicationType: map['applicationType'] != null 
          ? ApplicationType.values[map['applicationType']] 
          : null,
      temperature: map['temperature']?.toDouble(),
      humidity: map['humidity']?.toDouble(),
      observations: map['observations'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isSynced: map['isSynced'] == 1,
      imageUrls: processedImageUrls, // Adicionado processamento de imagens
      status: map['status'],
      purpose: map['purpose'],
      products: map['products'],
      productList: map['productList'],
      applicationRate: map['applicationRate']?.toDouble(),
      operationSpeed: map['operationSpeed']?.toDouble(),
      equipmentName: map['equipmentName'],
      weather: map['weather'],
    );
  }

  /// Converte o objeto para JSON
  String toJson() => json.encode(toMap());

  /// Getter para data de aplicação (compatibilidade com relatórios)
  DateTime get applicationDate => date;

  /// Cria um objeto a partir de JSON
  factory PesticideApplication.fromJson(String source) => 
      PesticideApplication.fromMap(json.decode(source));
  
  /// Calcula o volume total de calda
  /// calda_total = volume_calda_ha × área_total
  double calculateTotalMixtureVolume() {
    return (mixtureVolume ?? 0.0) * (totalArea ?? 0.0);
  }
  
  /// Calcula a quantidade total de produto
  /// produto_total = dose × área_total
  double calculateTotalProductAmount() {
    return (dose ?? 0.0) * (totalArea ?? 0.0);
  }
  
  /// Retorna o tipo de aplicação como string
  String getApplicationTypeString() {
    if (applicationType == null) return 'Não especificado';
    
    switch (applicationType) {
      case ApplicationType.ground:
        return 'Terrestre';
      case ApplicationType.aerial:
        return 'Aérea';
      default:
        return 'Desconhecido';
    }
  }
  
  /// Retorna a unidade da dose como string formatada
  String getFormattedDoseUnit() {
    return doseUnit ?? '';
  }
  
  /// Retorna a dose formatada com unidade
  String getFormattedDose() {
    return '${dose ?? 0.0} ${getFormattedDoseUnit()}';
  }
  
  /// Calcula o número de tanques necessários
  /// tanques = calda_total / capacidade_tanque
  double calculateTanksNeeded(double tankCapacity) {
    if (tankCapacity <= 0) return 0;
    return calculateTotalMixtureVolume() / tankCapacity;
  }

  // Getters para compatibilidade com relatórios
  String get responsible => responsiblePerson ?? '';
  String get applicationTypeFormatted => getApplicationTypeString();
  double get dosePerHa => dose ?? 0.0;
  double get caldaVolumePerHa => mixtureVolume ?? 0.0;
  double get totalCaldaVolume => calculateTotalMixtureVolume();
  double get totalProductAmount => calculateTotalProductAmount();
}
