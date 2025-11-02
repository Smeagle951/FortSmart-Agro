import 'dart:convert';
import '../services/calibracao_fertilizante_service.dart';

/// Modelo para calibração de fertilizantes
/// Implementa todas as validações e cálculos necessários
class CalibracaoFertilizanteModel {
  final String? id;
  final String nome;
  final DateTime dataCalibracao;
  final String responsavel;
  
  // Dados obrigatórios
  final List<double> pesos; // gramas
  final double distanciaColeta; // metros
  final double espacamento; // metros
  final double? faixaEsperada; // metros (opcional)
  final double? granulometria; // g/L (opcional)
  final double? taxaDesejada; // kg/ha (opcional)
  
  // Configuração da máquina
  final String tipoPaleta; // "pequena" ou "grande"
  final double? diametroPratoMm; // mm (opcional)
  final double? rpm; // rpm (opcional)
  final double? velocidade; // km/h (opcional)
  
  // Resultados calculados
  final double taxaRealKgHa;
  final double coeficienteVariacao;
  final double faixaReal;
  final String classificacaoCV;
  final String? observacoes;
  
  // Metadados
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  final String? remoteId;

  CalibracaoFertilizanteModel({
    this.id,
    required this.nome,
    required this.dataCalibracao,
    required this.responsavel,
    required this.pesos,
    required this.distanciaColeta,
    required this.espacamento,
    this.faixaEsperada,
    this.granulometria,
    this.taxaDesejada,
    required this.tipoPaleta,
    this.diametroPratoMm,
    this.rpm,
    this.velocidade,
    required this.taxaRealKgHa,
    required this.coeficienteVariacao,
    required this.faixaReal,
    required this.classificacaoCV,
    this.observacoes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 0,
    this.remoteId,
  });

  /// Cria uma instância com cálculos automáticos
  factory CalibracaoFertilizanteModel.calcular({
    String? id,
    required String nome,
    required DateTime dataCalibracao,
    required String responsavel,
    required List<double> pesos,
    required double distanciaColeta,
    required double espacamento,
    double? faixaEsperada,
    double? granulometria,
    double? taxaDesejada,
    required String tipoPaleta,
    double? diametroPratoMm,
    double? rpm,
    double? velocidade,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int syncStatus = 0,
    String? remoteId,
  }) {
    // Validações
    if (pesos.length < 5) {
      throw ArgumentError('Mínimo de 5 pesos é obrigatório');
    }
    if (distanciaColeta <= 0) {
      throw ArgumentError('Distância de coleta deve ser maior que zero');
    }
    if (espacamento <= 0) {
      throw ArgumentError('Espaçamento deve ser maior que zero');
    }
    if (!['pequena', 'grande'].contains(tipoPaleta.toLowerCase())) {
      throw ArgumentError('Tipo de paleta deve ser "pequena" ou "grande"');
    }

    // Cálculos
    final taxaRealKgHa = CalibracaoFertilizanteService.calcularTaxaRealKgHa(
      pesos, distanciaColeta, espacamento);
    
    final coeficienteVariacao = CalibracaoFertilizanteService.calcularCV(pesos);
    
    final faixaReal = CalibracaoFertilizanteService.calcularFaixaReal(
      pesos, espacamento, tipoPaleta);
    
    final classificacaoCV = CalibracaoFertilizanteService.classificarCV(coeficienteVariacao);

    return CalibracaoFertilizanteModel(
      id: id,
      nome: nome,
      dataCalibracao: dataCalibracao,
      responsavel: responsavel,
      pesos: List.from(pesos),
      distanciaColeta: distanciaColeta,
      espacamento: espacamento,
      faixaEsperada: faixaEsperada,
      granulometria: granulometria,
      taxaDesejada: taxaDesejada,
      tipoPaleta: tipoPaleta,
      diametroPratoMm: diametroPratoMm,
      rpm: rpm,
      velocidade: velocidade,
      taxaRealKgHa: taxaRealKgHa,
      coeficienteVariacao: coeficienteVariacao,
      faixaReal: faixaReal,
      classificacaoCV: classificacaoCV,
      observacoes: observacoes,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      syncStatus: syncStatus,
      remoteId: remoteId,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_calibracao': dataCalibracao.toIso8601String(),
      'responsavel': responsavel,
      'pesos': pesos,
      'distancia_coleta': distanciaColeta,
      'espacamento': espacamento,
      'faixa_esperada': faixaEsperada,
      'granulometria': granulometria,
      'taxa_desejada': taxaDesejada,
      'tipo_paleta': tipoPaleta,
      'diametro_prato_mm': diametroPratoMm,
      'rpm': rpm,
      'velocidade': velocidade,
      'taxa_real_kg_ha': taxaRealKgHa,
      'coeficiente_variacao': coeficienteVariacao,
      'faixa_real': faixaReal,
      'classificacao_cv': classificacaoCV,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'remote_id': remoteId,
    };
  }

  /// Cria a partir de Map
  factory CalibracaoFertilizanteModel.fromMap(Map<String, dynamic> map) {
    return CalibracaoFertilizanteModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      dataCalibracao: DateTime.parse(map['data_calibracao']),
      responsavel: map['responsavel'] ?? '',
      pesos: List<double>.from(map['pesos'] ?? []),
      distanciaColeta: (map['distancia_coleta'] ?? 0.0).toDouble(),
      espacamento: (map['espacamento'] ?? 0.0).toDouble(),
      faixaEsperada: map['faixa_esperada']?.toDouble(),
      granulometria: map['granulometria']?.toDouble(),
      taxaDesejada: map['taxa_desejada']?.toDouble(),
      tipoPaleta: map['tipo_paleta'] ?? 'pequena',
      diametroPratoMm: map['diametro_prato_mm']?.toDouble(),
      rpm: map['rpm']?.toDouble(),
      velocidade: map['velocidade']?.toDouble(),
      taxaRealKgHa: (map['taxa_real_kg_ha'] ?? 0.0).toDouble(),
      coeficienteVariacao: (map['coeficiente_variacao'] ?? 0.0).toDouble(),
      faixaReal: (map['faixa_real'] ?? 0.0).toDouble(),
      classificacaoCV: map['classificacao_cv'] ?? 'Desconhecido',
      observacoes: map['observacoes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'] ?? 0,
      remoteId: map['remote_id'],
    );
  }

  /// Cria uma cópia com novos valores
  CalibracaoFertilizanteModel copyWith({
    String? id,
    String? nome,
    DateTime? dataCalibracao,
    String? responsavel,
    List<double>? pesos,
    double? distanciaColeta,
    double? espacamento,
    double? faixaEsperada,
    double? granulometria,
    double? taxaDesejada,
    String? tipoPaleta,
    double? diametroPratoMm,
    double? rpm,
    double? velocidade,
    double? taxaRealKgHa,
    double? coeficienteVariacao,
    double? faixaReal,
    String? classificacaoCV,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    String? remoteId,
  }) {
    return CalibracaoFertilizanteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataCalibracao: dataCalibracao ?? this.dataCalibracao,
      responsavel: responsavel ?? this.responsavel,
      pesos: pesos ?? this.pesos,
      distanciaColeta: distanciaColeta ?? this.distanciaColeta,
      espacamento: espacamento ?? this.espacamento,
      faixaEsperada: faixaEsperada ?? this.faixaEsperada,
      granulometria: granulometria ?? this.granulometria,
      taxaDesejada: taxaDesejada ?? this.taxaDesejada,
      tipoPaleta: tipoPaleta ?? this.tipoPaleta,
      diametroPratoMm: diametroPratoMm ?? this.diametroPratoMm,
      rpm: rpm ?? this.rpm,
      velocidade: velocidade ?? this.velocidade,
      taxaRealKgHa: taxaRealKgHa ?? this.taxaRealKgHa,
      coeficienteVariacao: coeficienteVariacao ?? this.coeficienteVariacao,
      faixaReal: faixaReal ?? this.faixaReal,
      classificacaoCV: classificacaoCV ?? this.classificacaoCV,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  /// Converte para JSON
  String toJson() => json.encode(toMap());

  /// Cria a partir de JSON
  factory CalibracaoFertilizanteModel.fromJson(String source) =>
      CalibracaoFertilizanteModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CalibracaoFertilizanteModel(id: $id, nome: $nome, taxaRealKgHa: $taxaRealKgHa, coeficienteVariacao: $coeficienteVariacao, faixaReal: $faixaReal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalibracaoFertilizanteModel &&
        other.id == id &&
        other.nome == nome &&
        other.dataCalibracao == dataCalibracao;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nome.hashCode ^ dataCalibracao.hashCode;
  }
}
