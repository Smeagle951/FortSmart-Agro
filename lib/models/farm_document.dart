// Importações removidas

/// Modelo de documento associado a uma fazenda
class FarmDocument {
  final String id;
  final String name;
  final String type;
  final String? url;
  final String? filePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmDocument({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.filePath,
    required this.createdAt,
    this.updatedAt,
  });

  /// Cria um FarmDocument a partir de um mapa (JSON)
  factory FarmDocument.fromJson(Map<String, dynamic> json) {
    return FarmDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      filePath: json['filePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converte o FarmDocument para um mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Cria uma cópia do FarmDocument com os campos especificados alterados
  FarmDocument copyWith({
    String? id,
    String? name,
    String? type,
    String? url,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FarmDocument &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.url == url &&
        other.filePath == filePath &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      url,
      filePath,
      createdAt,
      updatedAt,
    );
  }
}
