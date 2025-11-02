import 'package:uuid/uuid.dart';

class EstandePlantasModel {
  String? id;
  String? talhaoId;
  String? culturaId;
  DateTime? dataEmergencia;
  DateTime? dataAvaliacao;
  int? diasAposEmergencia;
  double? metrosLinearesMedidos;
  int? plantasContadas;
  double? espacamento;
  double? plantasPorMetro;
  double? plantasPorHectare;
  double? populacaoIdeal;
  double? eficiencia;
  List<String> fotos;
  DateTime? createdAt;
  DateTime? updatedAt;
  int syncStatus;

  EstandePlantasModel({
    this.id,
    this.talhaoId,
    this.culturaId,
    this.dataEmergencia,
    this.dataAvaliacao,
    this.diasAposEmergencia,
    this.metrosLinearesMedidos,
    this.plantasContadas,
    this.espacamento,
    this.plantasPorMetro,
    this.plantasPorHectare,
    this.populacaoIdeal,
    this.eficiencia,
    List<String>? fotos,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  }) : fotos = fotos ?? [];

  // Cria um novo modelo com ID gerado
  factory EstandePlantasModel.novo({
    required String talhaoId,
    required String culturaId,
    required DateTime dataEmergencia,
    required DateTime dataAvaliacao,
    required int diasAposEmergencia,
    required double metrosLinearesMedidos,
    required int plantasContadas,
    required double espacamento,
    required double plantasPorMetro,
    required double plantasPorHectare,
    double? populacaoIdeal,
    double? eficiencia,
    List<String>? fotos,
  }) {
    final now = DateTime.now();
    return EstandePlantasModel(
      id: const Uuid().v4(),
      talhaoId: talhaoId,
      culturaId: culturaId,
      dataEmergencia: dataEmergencia,
      dataAvaliacao: dataAvaliacao,
      diasAposEmergencia: diasAposEmergencia,
      metrosLinearesMedidos: metrosLinearesMedidos,
      plantasContadas: plantasContadas,
      espacamento: espacamento,
      plantasPorMetro: plantasPorMetro,
      plantasPorHectare: plantasPorHectare,
      populacaoIdeal: populacaoIdeal,
      eficiencia: eficiencia,
      fotos: fotos ?? [],
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );
  }

  // Converte o modelo para um mapa para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'data_emergencia': dataEmergencia?.toIso8601String(),
      'data_avaliacao': dataAvaliacao?.toIso8601String(),
      'dias_apos_emergencia': diasAposEmergencia,
      'metros_lineares_medidos': metrosLinearesMedidos,
      'plantas_contadas': plantasContadas,
      'espacamento': espacamento,
      'plantas_por_metro': plantasPorMetro,
      'plantas_por_hectare': plantasPorHectare,
      'populacao_ideal': populacaoIdeal,
      'eficiencia': eficiencia,
      'fotos': fotos.join(','), // Armazena como string separada por vírgulas
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  // Cria um modelo a partir de um mapa do banco de dados
  factory EstandePlantasModel.fromMap(Map<String, dynamic> map) {
    return EstandePlantasModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      dataEmergencia: map['data_emergencia'] != null
          ? DateTime.parse(map['data_emergencia'])
          : null,
      dataAvaliacao: map['data_avaliacao'] != null
          ? DateTime.parse(map['data_avaliacao'])
          : null,
      diasAposEmergencia: map['dias_apos_emergencia'],
      metrosLinearesMedidos: map['metros_lineares_medidos'],
      plantasContadas: map['plantas_contadas'],
      espacamento: map['espacamento'],
      plantasPorMetro: map['plantas_por_metro'],
      plantasPorHectare: map['plantas_por_hectare'],
      populacaoIdeal: map['populacao_ideal'],
      eficiencia: map['eficiencia'],
      fotos: map['fotos'] != null && map['fotos'].isNotEmpty
          ? map['fotos'].split(',')
          : [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  // Cria uma cópia do modelo com valores atualizados
  EstandePlantasModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    DateTime? dataEmergencia,
    DateTime? dataAvaliacao,
    int? diasAposEmergencia,
    double? metrosLinearesMedidos,
    int? plantasContadas,
    double? espacamento,
    double? plantasPorMetro,
    double? plantasPorHectare,
    double? populacaoIdeal,
    double? eficiencia,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return EstandePlantasModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      dataEmergencia: dataEmergencia ?? this.dataEmergencia,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      diasAposEmergencia: diasAposEmergencia ?? this.diasAposEmergencia,
      metrosLinearesMedidos: metrosLinearesMedidos ?? this.metrosLinearesMedidos,
      plantasContadas: plantasContadas ?? this.plantasContadas,
      espacamento: espacamento ?? this.espacamento,
      plantasPorMetro: plantasPorMetro ?? this.plantasPorMetro,
      plantasPorHectare: plantasPorHectare ?? this.plantasPorHectare,
      populacaoIdeal: populacaoIdeal ?? this.populacaoIdeal,
      eficiencia: eficiencia ?? this.eficiencia,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
