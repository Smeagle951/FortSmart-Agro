import 'dart:convert';

/// Modelo para representar uma cultura associada a uma fazenda
class CulturaFazendaModel {
  final String? id;
  final String? fazendaId;
  final String? culturaId;
  final String? nome;
  final String? descricao;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isDeleted;
  final bool? isPending;

  CulturaFazendaModel({
    this.id,
    this.fazendaId,
    this.culturaId,
    this.nome,
    this.descricao,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.isPending = false,
  });

  CulturaFazendaModel copyWith({
    String? id,
    String? fazendaId,
    String? culturaId,
    String? nome,
    String? descricao,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isPending,
  }) {
    return CulturaFazendaModel(
      id: id ?? this.id,
      fazendaId: fazendaId ?? this.fazendaId,
      culturaId: culturaId ?? this.culturaId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fazendaId': fazendaId,
      'culturaId': culturaId,
      'nome': nome,
      'descricao': descricao,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
      'isPending': isPending,
    };
  }

  factory CulturaFazendaModel.fromMap(Map<String, dynamic> map) {
    return CulturaFazendaModel(
      id: map['id'],
      fazendaId: map['fazendaId'],
      culturaId: map['culturaId'],
      nome: map['nome'],
      descricao: map['descricao'],
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
      isPending: map['isPending'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CulturaFazendaModel.fromJson(String source) => CulturaFazendaModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CulturaFazendaModel(id: $id, fazendaId: $fazendaId, culturaId: $culturaId, nome: $nome, descricao: $descricao, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, isPending: $isPending)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CulturaFazendaModel &&
      other.id == id &&
      other.fazendaId == fazendaId &&
      other.culturaId == culturaId &&
      other.nome == nome &&
      other.descricao == descricao &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.isDeleted == isDeleted &&
      other.isPending == isPending;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      fazendaId.hashCode ^
      culturaId.hashCode ^
      nome.hashCode ^
      descricao.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isDeleted.hashCode ^
      isPending.hashCode;
  }
}
