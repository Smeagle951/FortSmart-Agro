import 'planting_cv_model.dart';
import 'planting_stand_model.dart';
import '../enums/integration_analysis_enum.dart';
import 'package:uuid/uuid.dart';

/// Modelo para análise integrada de plantio
/// Combina dados de CV% com estande de plantas para análise completa
class PlantingIntegrationModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final PlantingCVModel? cvModel;
  final PlantingStandModel? estandeModel;
  final DateTime dataAnalise;
  final String qualidadePlantio;
  final List<String> recomendacoes;
  final String statusGeral;
  final String observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  
  // Campos adicionais para compatibilidade
  final IntegrationAnalysis? analiseIntegracao;
  final String? analiseTexto;
  final String? diagnosticoIA;
  final String? nivelPrioridade;
  final PlantingCVModel? cvPlantio;
  final PlantingStandModel? estandePlantas;

  PlantingIntegrationModel({
    String? id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    this.cvModel,
    this.estandeModel,
    required this.dataAnalise,
    required this.qualidadePlantio,
    required this.recomendacoes,
    required this.statusGeral,
    required this.observacoes,
    DateTime? createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    // Campos adicionais
    this.analiseIntegracao,
    this.analiseTexto,
    this.diagnosticoIA,
    this.nivelPrioridade,
    this.cvPlantio,
    this.estandePlantas,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'cv_model_id': cvModel?.id,
      'estande_model_id': estandeModel?.id,
      'data_analise': dataAnalise.toIso8601String(),
      'qualidade_plantio': qualidadePlantio,
      'recomendacoes': recomendacoes.join('|'),
      'status_geral': statusGeral,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  /// Cria a partir de Map
  factory PlantingIntegrationModel.fromMap(Map<String, dynamic> map) {
    return PlantingIntegrationModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaNome: map['cultura_nome'] ?? '',
      cvModel: null, // Será carregado separadamente se necessário
      estandeModel: null, // Será carregado separadamente se necessário
      dataAnalise: DateTime.parse(map['data_analise'] ?? DateTime.now().toIso8601String()),
      qualidadePlantio: map['qualidade_plantio'] ?? '',
      recomendacoes: (map['recomendacoes'] ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      statusGeral: map['status_geral'] ?? '',
      observacoes: map['observacoes'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  /// Cria uma cópia com novos valores
  PlantingIntegrationModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    PlantingCVModel? cvModel,
    PlantingStandModel? estandeModel,
    DateTime? dataAnalise,
    String? qualidadePlantio,
    List<String>? recomendacoes,
    String? statusGeral,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return PlantingIntegrationModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      cvModel: cvModel ?? this.cvModel,
      estandeModel: estandeModel ?? this.estandeModel,
      dataAnalise: dataAnalise ?? this.dataAnalise,
      qualidadePlantio: qualidadePlantio ?? this.qualidadePlantio,
      recomendacoes: recomendacoes ?? this.recomendacoes,
      statusGeral: statusGeral ?? this.statusGeral,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Retorna a cor do indicador baseada na qualidade do plantio
  String get corIndicador {
    switch (qualidadePlantio.toLowerCase()) {
      case 'excelente':
        return '#4CAF50'; // Verde
      case 'boa':
        return '#8BC34A'; // Verde claro
      case 'moderada':
        return '#FFC107'; // Amarelo
      case 'ruim':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Retorna o ícone baseado na qualidade do plantio
  String get icone {
    switch (qualidadePlantio.toLowerCase()) {
      case 'excelente':
        return '✅';
      case 'boa':
        return '👍';
      case 'moderada':
        return '⚠️';
      case 'ruim':
        return '❌';
      default:
        return '❓';
    }
  }

  /// Verifica se tem dados completos (CV% e estande)
  bool get temDadosCompletos => cvModel != null && estandeModel != null;

  /// Verifica se tem apenas CV%
  bool get temApenasCv => cvModel != null && estandeModel == null;

  /// Verifica se tem apenas estande
  bool get temApenasEstande => cvModel == null && estandeModel != null;

  /// Retorna o resumo da análise
  String get resumo {
    if (temDadosCompletos) {
      return 'Análise completa: $qualidadePlantio CV% + Estande';
    } else if (temApenasCv) {
      return 'Análise parcial: $qualidadePlantio CV% (sem estande)';
    } else if (temApenasEstande) {
      return 'Análise parcial: Estande (sem CV%)';
    } else {
      return 'Sem dados para análise';
    }
  }
}