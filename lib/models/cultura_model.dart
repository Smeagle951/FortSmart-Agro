import 'package:flutter/material.dart';
import '../services/cultura_icon_service.dart';

class CulturaModel {
  final String id;
  final String name;
  final String? scientificName;
  final String? description;
  final Color color;
  final IconData? icon;
  final String? imagePath;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;


  CulturaModel({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    required this.color,
    this.icon,
    this.imagePath,
    this.isDefault = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Obtém o ícone da cultura usando o serviço de ícones
  Widget getIconOrInitial({double size = 24.0, Color? iconColor}) {
    return CulturaIconService.getCulturaIcon(
      culturaNome: name,
      size: size,
      backgroundColor: color,
      iconColor: iconColor,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'color': color.value,
      'icon': icon?.codePoint,
      'image_path': imagePath,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),

    };
  }

  /// Cria a partir de Map
  factory CulturaModel.fromMap(Map<String, dynamic> map) {
    return CulturaModel(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      scientificName: map['scientific_name']?.toString(),
      description: map['description']?.toString(),
      color: Color(map['color'] is int ? map['color'] : int.tryParse(map['color'].toString()) ?? Colors.green.value),
      icon: map['icon'] != null ? IconData(map['icon'], fontFamily: 'MaterialIcons') : null,
      imagePath: map['image_path']?.toString(),
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,

    );
  }

  /// Cria uma instância vazia
  factory CulturaModel.empty() {
    return CulturaModel(
      id: '',
      name: 'Sem Cultura',
      color: Colors.grey,
    );
  }

  /// Cria cópia com alterações
  CulturaModel copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    Color? color,
    IconData? icon,
    String? imagePath,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,

  }) {
    return CulturaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CulturaModel(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CulturaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Getter para compatibilidade com código existente
  String get nome => name;
  
  /// Getter para compatibilidade com código existente
  String get descricao => description ?? '';
}

/// Cores padrão para culturas
class CulturaColors {
  static const List<Color> defaultColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.pink,
    Colors.lime,
    Colors.brown,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
  ];

  /// Obtém cor baseada no ID da cultura
  static Color getColorForId(int id) {
    return defaultColors[id % defaultColors.length];
  }

  /// Obtém cor baseada no nome da cultura
  static Color getColorForName(String name) {
    int hash = name.hashCode;
    return defaultColors[hash.abs() % defaultColors.length];
  }
}

/// Ícones padrão para culturas
class CulturaIcons {
  static const Map<String, IconData> defaultIcons = {
    'soja': Icons.eco,
    'milho': Icons.grain,
    'feijao': Icons.circle,
    'arroz': Icons.grain,
    'trigo': Icons.grain,
    'cafe': Icons.coffee,
    'cana': Icons.grass,
    'algodao': Icons.circle,
    'girassol': Icons.wb_sunny,
    'tomate': Icons.circle,
    'batata': Icons.circle,
    'cenoura': Icons.circle,
    'alface': Icons.eco,
    'couve': Icons.eco,
    'repolho': Icons.circle,
    'beterraba': Icons.circle,
    'cebola': Icons.circle,
    'alho': Icons.circle,
    'pimentao': Icons.circle,
    'berinjela': Icons.circle,
    'abobora': Icons.circle,
    'melancia': Icons.circle,
    'melao': Icons.circle,
    'uva': Icons.circle,
    'laranja': Icons.circle,
    'limao': Icons.circle,
    'maca': Icons.circle,
    'banana': Icons.circle,
    'manga': Icons.circle,
    'abacaxi': Icons.circle,
    'mamao': Icons.circle,
    'goiaba': Icons.circle,
    'maracuja': Icons.circle,
    'caju': Icons.circle,
    'coco': Icons.circle,
    'castanha': Icons.circle,
    'amendoim': Icons.circle,
    'gergelim': Icons.circle,
    'linhaca': Icons.circle,
    'chia': Icons.circle,
    'quinoa': Icons.grain,
    'aveia': Icons.grain,
    'cevada': Icons.grain,
    'centeio': Icons.grain,
    'sorgo': Icons.grain,
  };

  /// Obtém ícone baseado no nome da cultura
  static IconData? getIconForName(String name) {
    final normalizedName = name.toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u');
    
    return defaultIcons[normalizedName];
  }
}
