import 'package:uuid/uuid.dart';
import 'dart:convert';

enum TargetType {
  pest,      // Praga
  disease,   // Doença
  weed,      // Planta daninha
}

// Classe para representar os tipos de controle que uma aplicação pode ter
class ApplicationControlType {
  final bool controlsPests;
  final bool controlsDiseases;
  final bool controlsWeeds;
  
  const ApplicationControlType({
    this.controlsPests = false,
    this.controlsDiseases = false,
    this.controlsWeeds = false,
  });
  
  // Verifica se controla pelo menos um tipo
  bool get hasAnyControl => controlsPests || controlsDiseases || controlsWeeds;
  
  // Retorna uma lista dos tipos de controle em formato legível
  List<String> get controlTypesList {
    final List<String> types = [];
    if (controlsPests) types.add('Pragas');
    if (controlsDiseases) types.add('Doenças');
    if (controlsWeeds) types.add('Plantas Daninhas');
    return types;
  }
  
  // Retorna uma string formatada com os tipos de controle
  String get controlTypesString => controlTypesList.join(', ');
  
  // Converter para Map para persistência
  Map<String, dynamic> toMap() => {
    'controlsPests': controlsPests ? 1 : 0,
    'controlsDiseases': controlsDiseases ? 1 : 0,
    'controlsWeeds': controlsWeeds ? 1 : 0,
  };
  
  // Criar a partir de um Map
  factory ApplicationControlType.fromMap(Map<String, dynamic> map) => ApplicationControlType(
    controlsPests: map['controlsPests'] == 1,
    controlsDiseases: map['controlsDiseases'] == 1,
    controlsWeeds: map['controlsWeeds'] == 1,
  );
  
  // Serializar para JSON
  String toJson() => jsonEncode(toMap());
  
  // Deserializar de JSON
  factory ApplicationControlType.fromJson(String json) => 
      ApplicationControlType.fromMap(jsonDecode(json));
}

class ApplicationTargetModel {
  final String id;
  final String name;
  final TargetType type;
  final String? scientificName;
  final String? description;
  final String? iconPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  ApplicationTargetModel({
    String? id,
    required this.name,
    required this.type,
    this.scientificName,
    this.description,
    this.iconPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Método para criar uma cópia do modelo com alterações
  ApplicationTargetModel copyWith({
    String? id,
    String? name,
    TargetType? type,
    String? scientificName,
    String? description,
    String? iconPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ApplicationTargetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Converter para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'scientificName': scientificName,
      'description': description,
      'iconPath': iconPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Criar a partir de um Map
  factory ApplicationTargetModel.fromMap(Map<String, dynamic> map) {
    return ApplicationTargetModel(
      id: map['id'],
      name: map['name'],
      type: TargetType.values[map['type']],
      scientificName: map['scientificName'],
      description: map['description'],
      iconPath: map['iconPath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }
  
  // Método para obter o ícone padrão baseado no tipo
  String get defaultIcon {
    switch (type) {
      case TargetType.pest:
        return '🐞';
      case TargetType.disease:
        return '🦠';
      case TargetType.weed:
        return '🌿';
    }
  }
  
  // Método para obter o ícone (personalizado ou padrão)
  String get icon => iconPath ?? defaultIcon;
}
