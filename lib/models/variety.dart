import 'dart:convert';

/// Modelo para representar uma variedade de cultura
/// Esta implementação substitui a versão anterior no módulo de estoque
class Variety {
  final int? id;
  final String nome;
  final int culturaId;
  final String createdAt;
  final bool isSynced;
  
  // Getter para compatibilidade com outras partes do código
  String get name => nome;

  Variety({
    this.id,
    required this.nome,
    required this.culturaId,
    String? createdAt,
    this.isSynced = false,
  }) : this.createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cultura_id': culturaId,
      'created_at': createdAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Variety.fromMap(Map<String, dynamic> map) {
    return Variety(
      id: map['id'],
      nome: map['nome'],
      culturaId: map['cultura_id'],
      isSynced: map['is_synced'] == 1,
      createdAt: map['created_at'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Variety.fromJson(String source) => Variety.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Variety(id: $id, nome: $nome, culturaId: $culturaId, createdAt: $createdAt)';
  }

  Variety copyWith({
    int? id,
    String? nome,
    int? culturaId,
    String? createdAt,
  }) {
    return Variety(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      culturaId: culturaId ?? this.culturaId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
