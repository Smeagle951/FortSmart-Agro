import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'agro_base_model.dart';

/// Enum para definir os diferentes tipos de atividades agrícolas
enum TipoAtividade {
  plantio,
  aplicacao,
  colheita, // Descontinuado, mantido apenas para compatibilidade com registros existentes
  monitoramento,
  estande,
  experimento,
  integracao,
  outro
}

/// Extensão para facilitar a conversão entre String e TipoAtividade
extension TipoAtividadeExtension on TipoAtividade {
  String get nome {
    switch (this) {
      case TipoAtividade.plantio:
        return 'Plantio';
      case TipoAtividade.aplicacao:
        return 'Aplicação';
      case TipoAtividade.colheita:
        return 'Colheita (Descontinuado)';
      case TipoAtividade.monitoramento:
        return 'Monitoramento';
      case TipoAtividade.estande:
        return 'Estande';
      case TipoAtividade.experimento:
        return 'Experimento';
      case TipoAtividade.integracao:
        return 'Integração';
      case TipoAtividade.outro:
        return 'Outro';
    }
  }
  
  /// Ícone associado ao tipo de atividade
  String get icone {
    switch (this) {
      case TipoAtividade.plantio:
        return '🌱';
      case TipoAtividade.aplicacao:
        return '🚿';
      case TipoAtividade.colheita:
        return '🚜';
      case TipoAtividade.monitoramento:
        return '🔍';
      case TipoAtividade.estande:
        return '📏';
      case TipoAtividade.experimento:
        return '🧪';
      case TipoAtividade.integracao:
        return '🔗';
      case TipoAtividade.outro:
        return '📝';
    }
  }
  
  /// Converte string para TipoAtividade
  static TipoAtividade fromString(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'plantio':
        return TipoAtividade.plantio;
      case 'aplicacao':
      case 'aplicação':
        return TipoAtividade.aplicacao;
      case 'colheita':
        return TipoAtividade.colheita;
      case 'monitoramento':
        return TipoAtividade.monitoramento;
      case 'estande':
        return TipoAtividade.estande;
      case 'experimento':
        return TipoAtividade.experimento;
      case 'integracao':
      case 'integração':
        return TipoAtividade.integracao;
      default:
        return TipoAtividade.outro;
    }
  }
}

/// Modelo para registrar atividades agrícolas no sistema com rastreabilidade completa
class AtividadeAgricola extends AgroBaseModel {
  final String talhaoId;
  final String safraId;
  final String culturaId;
  final TipoAtividade tipoAtividade;
  final DateTime dataAtividade;
  final String detalhesId;
  final String? descricao;

  AtividadeAgricola({
    required String id,
    required this.talhaoId,
    required this.safraId,
    required this.culturaId,
    required this.tipoAtividade,
    required this.dataAtividade,
    required this.detalhesId,
    this.descricao,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
    required bool sincronizado,
  }) : super(
          id: id,
          criadoEm: criadoEm,
          atualizadoEm: atualizadoEm,
          sincronizado: sincronizado,
        );

  /// Cria uma nova atividade agrícola
  factory AtividadeAgricola.criar({
    required String talhaoId,
    required String safraId,
    required String culturaId,
    required TipoAtividade tipoAtividade,
    required String detalhesId,
    String? descricao,
    DateTime? dataAtividade,
  }) {
    final now = DateTime.now();
    return AtividadeAgricola(
      id: const Uuid().v4(),
      talhaoId: talhaoId,
      safraId: safraId,
      culturaId: culturaId,
      tipoAtividade: tipoAtividade,
      dataAtividade: dataAtividade ?? now,
      detalhesId: detalhesId,
      descricao: descricao,
      criadoEm: now,
      atualizadoEm: now,
      sincronizado: false,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'safraId': safraId,
      'culturaId': culturaId,
      'tipoAtividade': tipoAtividade.name,
      'dataAtividade': dataAtividade.toIso8601String(),
      'detalhesId': detalhesId,
      'descricao': descricao,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  /// Cria uma AtividadeAgricola a partir de um mapa
  factory AtividadeAgricola.fromMap(Map<String, dynamic> map) {
    return AtividadeAgricola(
      id: map['id'] as String,
      talhaoId: map['talhaoId'] as String,
      safraId: map['safraId'] as String,
      culturaId: map['culturaId'] as String,
      tipoAtividade: TipoAtividadeExtension.fromString(map['tipoAtividade'] as String),
      dataAtividade: DateTime.parse(map['dataAtividade'] as String),
      detalhesId: map['detalhesId'] as String,
      descricao: map['descricao'] as String?,
      criadoEm: DateTime.parse(map['criadoEm'] as String),
      atualizadoEm: DateTime.parse(map['atualizadoEm'] as String),
      sincronizado: map['sincronizado'] == 1,
    );
  }

  /// Cria uma cópia desta atividade com valores opcionalmente alterados
  AtividadeAgricola copyWith({
    String? id,
    String? talhaoId,
    String? safraId,
    String? culturaId,
    TipoAtividade? tipoAtividade,
    DateTime? dataAtividade,
    String? detalhesId,
    String? descricao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    bool? sincronizado,
  }) {
    return AtividadeAgricola(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      tipoAtividade: tipoAtividade ?? this.tipoAtividade,
      dataAtividade: dataAtividade ?? this.dataAtividade,
      detalhesId: detalhesId ?? this.detalhesId,
      descricao: descricao ?? this.descricao,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }
}
