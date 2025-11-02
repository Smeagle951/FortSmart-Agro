/// Modelo para representar dados de perda na colheita
class ColheitaPerdaModel {
  final String? id;
  final String dataColeta;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final String metodoCalculo; // 'peso_gramas' ou 'pms_grao'
  final double areaColeta; // m²
  final double pesoColetado; // gramas
  final double pesoSaca; // kg (padrão 60)
  final double perdaKgHa; // calculado automaticamente
  final double perdaScHa; // calculado automaticamente
  final String classificacao; // 'Aceitável', 'Alerta', 'Alta'
  final String nomeTecnico;
  final String coordenadasGps;
  final String observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;

  ColheitaPerdaModel({
    this.id,
    required this.dataColeta,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    required this.metodoCalculo,
    required this.areaColeta,
    required this.pesoColetado,
    this.pesoSaca = 60.0,
    required this.perdaKgHa,
    required this.perdaScHa,
    required this.classificacao,
    required this.nomeTecnico,
    required this.coordenadasGps,
    this.observacoes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 0,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com valores atualizados
  ColheitaPerdaModel copyWith({
    String? id,
    String? dataColeta,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    String? metodoCalculo,
    double? areaColeta,
    double? pesoColetado,
    double? pesoSaca,
    double? perdaKgHa,
    double? perdaScHa,
    String? classificacao,
    String? nomeTecnico,
    String? coordenadasGps,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return ColheitaPerdaModel(
      id: id ?? this.id,
      dataColeta: dataColeta ?? this.dataColeta,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      metodoCalculo: metodoCalculo ?? this.metodoCalculo,
      areaColeta: areaColeta ?? this.areaColeta,
      pesoColetado: pesoColetado ?? this.pesoColetado,
      pesoSaca: pesoSaca ?? this.pesoSaca,
      perdaKgHa: perdaKgHa ?? this.perdaKgHa,
      perdaScHa: perdaScHa ?? this.perdaScHa,
      classificacao: classificacao ?? this.classificacao,
      nomeTecnico: nomeTecnico ?? this.nomeTecnico,
      coordenadasGps: coordenadasGps ?? this.coordenadasGps,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Converte de Map para objeto ColheitaPerdaModel
  factory ColheitaPerdaModel.fromMap(Map<String, dynamic> map) {
    return ColheitaPerdaModel(
      id: map['id'],
      dataColeta: map['data_coleta'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaNome: map['cultura_nome'] ?? '',
      metodoCalculo: map['metodo_calculo'] ?? 'peso_gramas',
      areaColeta: (map['area_coleta'] ?? 0.0).toDouble(),
      pesoColetado: (map['peso_coletado'] ?? 0.0).toDouble(),
      pesoSaca: (map['peso_saca'] ?? 60.0).toDouble(),
      perdaKgHa: (map['perda_kg_ha'] ?? 0.0).toDouble(),
      perdaScHa: (map['perda_sc_ha'] ?? 0.0).toDouble(),
      classificacao: map['classificacao'] ?? 'Aceitável',
      nomeTecnico: map['nome_tecnico'] ?? '',
      coordenadasGps: map['coordenadas_gps'] ?? '',
      observacoes: map['observacoes'] ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  /// Converte de objeto ColheitaPerdaModel para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_coleta': dataColeta,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'metodo_calculo': metodoCalculo,
      'area_coleta': areaColeta,
      'peso_coletado': pesoColetado,
      'peso_saca': pesoSaca,
      'perda_kg_ha': perdaKgHa,
      'perda_sc_ha': perdaScHa,
      'classificacao': classificacao,
      'nome_tecnico': nomeTecnico,
      'coordenadas_gps': coordenadasGps,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  /// Calcula a perda em kg/ha
  static double calcularPerdaKgHa(double pesoColetado, double areaColeta) {
    if (areaColeta <= 0) return 0.0;
    final pesoKg = pesoColetado / 1000.0;
    return (pesoKg / areaColeta) * 10000.0;
  }

  /// Calcula a perda em sacas/ha
  static double calcularPerdaScHa(double perdaKgHa, double pesoSaca) {
    if (pesoSaca <= 0) return 0.0;
    return perdaKgHa / pesoSaca;
  }

  /// Determina a classificação da perda
  static String determinarClassificacao(double perdaScHa, double perdaAceitavel) {
    if (perdaScHa <= perdaAceitavel) {
      return 'Aceitável';
    } else if (perdaScHa <= perdaAceitavel * 1.5) {
      return 'Alerta';
    } else {
      return 'Alta';
    }
  }

  /// Obtém a cor da classificação
  static int getCorClassificacao(String classificacao) {
    switch (classificacao) {
      case 'Aceitável':
        return 0xFF4CAF50; // Verde
      case 'Alerta':
        return 0xFFFF9800; // Laranja
      case 'Alta':
        return 0xFFF44336; // Vermelho
      default:
        return 0xFF9E9E9E; // Cinza
    }
  }

  /// Obtém o ícone da classificação
  static String getIconeClassificacao(String classificacao) {
    switch (classificacao) {
      case 'Aceitável':
        return '✅';
      case 'Alerta':
        return '⚠️';
      case 'Alta':
        return '❌';
      default:
        return '❓';
    }
  }
} 