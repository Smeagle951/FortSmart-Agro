import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'plot.dart';

/// Modelo para representar uma fazenda
class Farm {
  final String id;
  final String name;
  String? logoUrl; // Alterado de final para permitir atualização
  final String? responsiblePerson;
  final String? documentNumber; // CNPJ/CPF
  final String? phone;
  final String? email;
  final String address;
  final double totalArea;
  final int plotsCount;
  final List<String> crops;
  final String? cultivationSystem;
  final bool hasIrrigation;
  final String? irrigationType;
  final String? mechanizationLevel;
  final String? technicalResponsibleName;
  final String? technicalResponsibleId; // CREA
  final List<FarmDocument> documents;
  final List<Plot> plots; // adicionado lista de talhões
  bool isVerified;
  bool isActive; // Adicionado campo para controlar se a fazenda está ativa
  final double? latitude; // Adicionado campo para latitude
  final double? longitude; // Adicionado campo para longitude
  final int propertyId; // ID da propriedade no sistema
  final String? ownerName; // Nome do proprietário para relatórios
  final String? municipality; // Município onde fica a fazenda
  final String? state; // Estado onde fica a fazenda  
  final String? website; // Website da fazenda ou produtor
  final DateTime createdAt;
  final DateTime updatedAt;

  Farm({
    String? id,
    required this.name,
    this.logoUrl,
    this.responsiblePerson,
    this.documentNumber,
    this.phone,
    this.email,
    required this.address,
    required this.totalArea,
    required this.plotsCount,
    required this.crops,
    this.cultivationSystem,
    required this.hasIrrigation,
    this.irrigationType,
    this.mechanizationLevel,
    this.technicalResponsibleName,
    this.technicalResponsibleId,
    List<FarmDocument>? documents,
    List<Plot>? plots,
    bool? isVerified,
    bool? isActive,
    this.latitude,
    this.longitude,
    this.propertyId = 0,
    this.ownerName,
    this.municipality,
    this.state,
    this.website,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        documents = documents ?? [],
        plots = plots ?? [],
        isVerified = isVerified ?? false,
        isActive = isActive ?? true,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  Farm copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? responsiblePerson,
    String? documentNumber,
    String? phone,
    String? email,
    String? address,
    double? totalArea,
    int? plotsCount,
    List<String>? crops,
    String? cultivationSystem,
    bool? hasIrrigation,
    String? irrigationType,
    String? mechanizationLevel,
    String? technicalResponsibleName,
    String? technicalResponsibleId,
    List<FarmDocument>? documents,
    List<Plot>? plots,
    bool? isVerified,
    bool? isActive,
    double? latitude,
    double? longitude,
    int? propertyId,
    String? ownerName,
    String? municipality,
    String? state,
    String? website,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      documentNumber: documentNumber ?? this.documentNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalArea: totalArea ?? this.totalArea,
      plotsCount: plotsCount ?? this.plotsCount,
      crops: crops ?? this.crops,
      cultivationSystem: cultivationSystem ?? this.cultivationSystem,
      hasIrrigation: hasIrrigation ?? this.hasIrrigation,
      irrigationType: irrigationType ?? this.irrigationType,
      mechanizationLevel: mechanizationLevel ?? this.mechanizationLevel,
      technicalResponsibleName: technicalResponsibleName ?? this.technicalResponsibleName,
      technicalResponsibleId: technicalResponsibleId ?? this.technicalResponsibleId,
      documents: documents ?? this.documents,
      plots: plots ?? this.plots,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      propertyId: propertyId ?? this.propertyId,
      ownerName: ownerName ?? this.ownerName,
      municipality: municipality ?? this.municipality,
      state: state ?? this.state,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'responsiblePerson': responsiblePerson,
      'documentNumber': documentNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'totalArea': totalArea,
      'plotsCount': plotsCount,
      'crops': crops,
      'cultivationSystem': cultivationSystem,
      'hasIrrigation': hasIrrigation ? 1 : 0,
      'irrigationType': irrigationType,
      'mechanizationLevel': mechanizationLevel,
      'technicalResponsibleName': technicalResponsibleName,
      'technicalResponsibleId': technicalResponsibleId,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'plots': plots.map((plot) => plot.toMap()).toList(),
      'isVerified': isVerified ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'propertyId': propertyId,
      'ownerName': ownerName,
      'municipality': municipality,
      'state': state,
      'website': website,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      name: map['name'],
      logoUrl: map['logoUrl'],
      responsiblePerson: map['responsiblePerson'],
      documentNumber: map['documentNumber'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      totalArea: map['totalArea'],
      plotsCount: map['plotsCount'],
      crops: List<String>.from(map['crops']),
      cultivationSystem: map['cultivationSystem'],
      hasIrrigation: map['hasIrrigation'] == 1,
      irrigationType: map['irrigationType'],
      mechanizationLevel: map['mechanizationLevel'],
      technicalResponsibleName: map['technicalResponsibleName'],
      technicalResponsibleId: map['technicalResponsibleId'],
      documents: List<FarmDocument>.from(
        map['documents']?.map((x) => FarmDocument.fromMap(x)) ?? [],
      ),
      plots: List<Plot>.from(
        map['plots']?.map((x) => Plot.fromMap(x)) ?? [],
      ),
      isVerified: map['isVerified'] == 1,
      isActive: map['isActive'] == 1,
      latitude: map['latitude'],
      longitude: map['longitude'],
      propertyId: map['propertyId'],
      ownerName: map['ownerName'],
      municipality: map['municipality'],
      state: map['state'],
      website: map['website'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory Farm.fromJson(String source) => Farm.fromMap(jsonDecode(source));
}

/// Modelo para representar um documento da fazenda
class FarmDocument {
  final String id;
  final String name;
  final String type; // CAR, CCIR, etc.
  final String fileUrl;
  final DateTime uploadDate;

  FarmDocument({
    String? id,
    required this.name,
    required this.type,
    required this.fileUrl,
    DateTime? uploadDate,
  }) : 
    id = id ?? const Uuid().v4(),
    uploadDate = uploadDate ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  FarmDocument copyWith({
    String? id,
    String? name,
    String? type,
    String? fileUrl,
    DateTime? uploadDate,
  }) {
    return FarmDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'fileUrl': fileUrl,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  /// Cria um objeto a partir de um mapa
  factory FarmDocument.fromMap(Map<String, dynamic> map) {
    return FarmDocument(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      fileUrl: map['fileUrl'],
      uploadDate: DateTime.parse(map['uploadDate']),
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory FarmDocument.fromJson(String source) => 
      FarmDocument.fromMap(jsonDecode(source));
}
