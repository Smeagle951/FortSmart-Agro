import '../database/models/crop.dart' as db;
import 'package:flutter/material.dart';

class Crop {
  final int? id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;

  /// Caminho local ou URL da imagem real tirada pelo usuário
  final String? imagePath;
  final bool isSynced;
  final bool isDefault;
  final int? growthCycle;
  final double? plantSpacing;
  final double? rowSpacing;
  final double? plantingDepth;
  final String? idealTemperature;
  final String? waterRequirement;
  final String? iconPath; // Caminho para o ícone personalizado
  final int? colorValue; // Valor da cor em formato int (0xFFRRGGBB)

  Crop({
    this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    this.imagePath, // Campo opcional para armazenar o caminho da imagem
    this.isSynced = false,
    this.isDefault = false,
    this.growthCycle,
    this.plantSpacing,
    this.rowSpacing,
    this.plantingDepth,
    this.idealTemperature,
    this.waterRequirement,
    this.iconPath,
    this.colorValue,
  });
  
  // Retorna a cor da cultura, ou uma cor padrão baseada no nome se não estiver definida
  Color get color {
    if (colorValue != null) {
      return Color(colorValue!);
    } else {
      // Gerar uma cor baseada no nome da cultura para consistência
      final int hashCode = name.hashCode;
      return Color(0xFF000000 + (hashCode % 0xFFFFFF));
    }
  }
  
  // Getter para cor (para compatibilidade com outros modelos)
  Color get cor => color;
  
  // Getter para nome (para compatibilidade com outros modelos)
  String get nome => name;
  
  // Retorna o código hexadecimal da cor (sem o prefixo #)
  String? getColorHex() {
    // Primeiro tentar extrair da descrição se estiver no formato esperado
    if (description != null && description!.contains('#')) {
      final parts = description!.split('#');
      if (parts.length > 1) {
        final hexCode = parts.last.trim();
        if (hexCode.length == 6) {
          return hexCode;
        }
      }
    }
    
    // Se não encontrar na descrição, usar o colorValue
    if (colorValue != null) {
      return (colorValue! & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    }
    
    // Se não tiver colorValue, gerar baseado no nome
    final int hashCode = name.hashCode;
    return (hashCode % 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  }
  
  // Retorna o ícone da cultura como um widget
  Widget getIcon({double size = 24.0}) {
    if (iconPath != null && iconPath!.isNotEmpty) {
      return Image.asset(
        iconPath!,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultIcon(size: size);
        },
      );
    } else {
      return _getDefaultIcon(size: size);
    }
  }
  
  // Gera um ícone padrão baseado no nome da cultura
  Widget _getDefaultIcon({double size = 24.0}) {
    // Mapear culturas comuns para ícones específicos
    final Map<String, IconData> commonCrops = {
      'soja': Icons.grass,
      'milho': Icons.agriculture,
      'trigo': Icons.grain,
      'algodão': Icons.cloud,
      'café': Icons.coffee,
      'cana': Icons.grass,
      'feijão': Icons.spa,
    };
    
    // Verificar se o nome da cultura contém alguma das palavras-chave
    final String lowerName = name.toLowerCase();
    IconData iconData = Icons.grass; // Ícone padrão
    
    for (final entry in commonCrops.entries) {
      if (lowerName.contains(entry.key)) {
        iconData = entry.value;
        break;
      }
    }
    
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath, // Adicionado o campo imagePath
      'isSynced': isSynced ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'growthCycle': growthCycle,
      'plantSpacing': plantSpacing,
      'rowSpacing': rowSpacing,
      'plantingDepth': plantingDepth,
      'idealTemperature': idealTemperature,
      'waterRequirement': waterRequirement,
      'iconPath': iconPath,
      'colorValue': colorValue,
    };
  }
  
  // Converter para o modelo de banco de dados
  db.Crop toDbModel() {
    return db.Crop(
      id: id ?? 0,
      name: name,
      description: description ?? '',
      syncStatus: isSynced ? 1 : 0,
    );
  }
  
  // Criar a partir do modelo de banco de dados
  factory Crop.fromDbModel(db.Crop dbModel) {
    // Garantir que o ID seja sempre um número válido
    // Não definir como null se for 0, pois isso causa problemas na verificação de existência
    final validId = dbModel.id;
    
    return Crop(
      id: validId,
      name: dbModel.name,
      description: dbModel.description,
      isSynced: dbModel.syncStatus == 1,
      isDefault: true, // Por padrão, consideramos os modelos do banco como padrão
      // Valores padrão para propriedades que não existem no modelo de banco de dados
      scientificName: '',
      growthCycle: 0,
      plantSpacing: 0.0,
      rowSpacing: 0.0,
      plantingDepth: 0.0,
      idealTemperature: '',
      waterRequirement: '',
      iconPath: null,
      colorValue: null,
      imagePath: null, // Adicionado o campo imagePath
    );
  }
  
  // Converter lista de modelos de banco de dados para lista de modelos de aplicação
  static List<Crop> fromDbModelList(List<db.Crop> dbModels) {
    return dbModels.map((dbModel) => Crop.fromDbModel(dbModel)).toList();
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'],
      name: map['name'],
      scientificName: map['scientificName'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      imagePath: map['imagePath'], // Adicionado o campo imagePath
      isSynced: map['isSynced'] == 1,
      isDefault: map['isDefault'] == 1,
      growthCycle: map['growthCycle'],
      plantSpacing: map['plantSpacing'],
      rowSpacing: map['rowSpacing'],
      plantingDepth: map['plantingDepth'],
      idealTemperature: map['idealTemperature'],
      waterRequirement: map['waterRequirement'],
      iconPath: map['iconPath'],
      colorValue: map['colorValue'],
    );
  }

  Crop copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageUrl,
    String? imagePath, // Adicionado o campo imagePath
    bool? isSynced,
    bool? isDefault,
    int? growthCycle,
    double? plantSpacing,
    double? rowSpacing,
    double? plantingDepth,
    String? idealTemperature,
    String? waterRequirement,
    String? iconPath,
    int? colorValue,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath, // Adicionado o campo imagePath
      isSynced: isSynced ?? this.isSynced,
      isDefault: isDefault ?? this.isDefault,
      growthCycle: growthCycle ?? this.growthCycle,
      plantSpacing: plantSpacing ?? this.plantSpacing,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      plantingDepth: plantingDepth ?? this.plantingDepth,
      idealTemperature: idealTemperature ?? this.idealTemperature,
      waterRequirement: waterRequirement ?? this.waterRequirement,
      iconPath: iconPath ?? this.iconPath,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  getColor() {}
}
