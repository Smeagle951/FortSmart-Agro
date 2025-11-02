import 'package:uuid/uuid.dart';

/// Modelo para tratamentos experimentais
class TratamentoModel {
  final String id;
  final String experimentoId;
  final String nome;
  final String descricao;
  final String tipo; // 'testemunha', 'fertilizante', 'defensivo', 'semente', 'outros'
  final Map<String, dynamic> parametros; // Parâmetros específicos do tratamento
  final int numeroRepeticao; // 1, 2, 3, etc.
  final String codigo; // T1, T2, T3, etc.
  final String observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TratamentoModel({
    required this.id,
    required this.experimentoId,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.parametros,
    required this.numeroRepeticao,
    required this.codigo,
    required this.observacoes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria um novo tratamento
  factory TratamentoModel.create({
    required String experimentoId,
    required String nome,
    required String descricao,
    required String tipo,
    required Map<String, dynamic> parametros,
    required int numeroRepeticao,
    required String codigo,
    String? observacoes,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return TratamentoModel(
      id: uuid.v4(),
      experimentoId: experimentoId,
      nome: nome,
      descricao: descricao,
      tipo: tipo,
      parametros: parametros,
      numeroRepeticao: numeroRepeticao,
      codigo: codigo,
      observacoes: observacoes ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia do tratamento com campos alterados
  TratamentoModel copyWith({
    String? id,
    String? experimentoId,
    String? nome,
    String? descricao,
    String? tipo,
    Map<String, dynamic>? parametros,
    int? numeroRepeticao,
    String? codigo,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TratamentoModel(
      id: id ?? this.id,
      experimentoId: experimentoId ?? this.experimentoId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      parametros: parametros ?? this.parametros,
      numeroRepeticao: numeroRepeticao ?? this.numeroRepeticao,
      codigo: codigo ?? this.codigo,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experimento_id': experimentoId,
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'parametros': _mapToString(parametros),
      'numero_repeticao': numeroRepeticao,
      'codigo': codigo,
      'observacoes': observacoes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory TratamentoModel.fromMap(Map<String, dynamic> map) {
    return TratamentoModel(
      id: map['id'],
      experimentoId: map['experimento_id'],
      nome: map['nome'],
      descricao: map['descricao'],
      tipo: map['tipo'],
      parametros: _stringToMap(map['parametros']),
      numeroRepeticao: map['numero_repeticao'],
      codigo: map['codigo'],
      observacoes: map['observacoes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  /// Converte Map para string JSON
  static String _mapToString(Map<String, dynamic> map) {
    // Implementação simplificada - em produção usar jsonEncode
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Converte string JSON para Map
  static Map<String, dynamic> _stringToMap(String? str) {
    if (str == null || str.isEmpty) return {};
    // Implementação simplificada - em produção usar jsonDecode
    final map = <String, dynamic>{};
    final pairs = str.split(',');
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    return map;
  }

  /// Obtém parâmetro específico
  dynamic getParametro(String chave) => parametros[chave];

  /// Define parâmetro específico
  TratamentoModel setParametro(String chave, dynamic valor) {
    final novosParametros = Map<String, dynamic>.from(parametros);
    novosParametros[chave] = valor;
    return copyWith(parametros: novosParametros);
  }

  @override
  String toString() {
    return 'TratamentoModel(id: $id, nome: $nome, codigo: $codigo, tipo: $tipo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TratamentoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
