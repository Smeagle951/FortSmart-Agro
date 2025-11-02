import 'package:uuid/uuid.dart';

/// Enum para representar o método de calibragem
enum MetodoCalibragrem {
  engrenagem,
  gramas,
}

/// Modelo para representar uma calibragem de sementes
class CalibragemSementeModel {
  final String id;
  final String talhaoId;
  final String culturaId;
  final String? variedadeId;
  final String tratorId;
  final String plantadeiraId;
  final DateTime dataCalibragem;
  final double espacamentoCm;
  final int populacaoDesejada;
  final double densidadeMetro;
  final double germinacaoPercentual;
  final MetodoCalibragrem metodoCalibragrem;
  final String? engrenagemConfigurada;
  final double? pesoMilSementes;
  final int? sementesColetadas;
  final int sementesCalculadas;
  final double diferencaPercentual;
  final String? observacoes;
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  CalibragemSementeModel({
    String? id,
    required this.talhaoId,
    required this.culturaId,
    this.variedadeId,
    required this.tratorId,
    required this.plantadeiraId,
    required this.dataCalibragem,
    required this.espacamentoCm,
    required this.populacaoDesejada,
    required this.densidadeMetro,
    required this.germinacaoPercentual,
    required this.metodoCalibragrem,
    this.engrenagemConfigurada,
    this.pesoMilSementes,
    this.sementesColetadas,
    required this.sementesCalculadas,
    required this.diferencaPercentual,
    this.observacoes,
    this.sincronizado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.criadoEm = criadoEm ?? DateTime.now(),
    this.atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  CalibragemSementeModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    String? variedadeId,
    String? tratorId,
    String? plantadeiraId,
    DateTime? dataCalibragem,
    double? espacamentoCm,
    int? populacaoDesejada,
    double? densidadeMetro,
    double? germinacaoPercentual,
    MetodoCalibragrem? metodoCalibragrem,
    String? engrenagemConfigurada,
    double? pesoMilSementes,
    int? sementesColetadas,
    int? sementesCalculadas,
    double? diferencaPercentual,
    String? observacoes,
    bool? sincronizado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return CalibragemSementeModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      tratorId: tratorId ?? this.tratorId,
      plantadeiraId: plantadeiraId ?? this.plantadeiraId,
      dataCalibragem: dataCalibragem ?? this.dataCalibragem,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      densidadeMetro: densidadeMetro ?? this.densidadeMetro,
      germinacaoPercentual: germinacaoPercentual ?? this.germinacaoPercentual,
      metodoCalibragrem: metodoCalibragrem ?? this.metodoCalibragrem,
      engrenagemConfigurada: engrenagemConfigurada ?? this.engrenagemConfigurada,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      sementesColetadas: sementesColetadas ?? this.sementesColetadas,
      sementesCalculadas: sementesCalculadas ?? this.sementesCalculadas,
      diferencaPercentual: diferencaPercentual ?? this.diferencaPercentual,
      observacoes: observacoes ?? this.observacoes,
      sincronizado: sincronizado ?? this.sincronizado,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'trator_id': tratorId,
      'plantadeira_id': plantadeiraId,
      'data_calibragem': dataCalibragem.toIso8601String(),
      'espacamento_cm': espacamentoCm,
      'populacao_desejada': populacaoDesejada,
      'densidade_metro': densidadeMetro,
      'germinacao_percentual': germinacaoPercentual,
      'metodo_calibragem': metodoCalibragrem.toString().split('.').last,
      'engrenagem_configurada': engrenagemConfigurada,
      'peso_mil_sementes': pesoMilSementes,
      'sementes_coletadas': sementesColetadas,
      'sementes_calculadas': sementesCalculadas,
      'diferenca_percentual': diferencaPercentual,
      'observacoes': observacoes,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory CalibragemSementeModel.fromMap(Map<String, dynamic> map) {
    return CalibragemSementeModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      tratorId: map['trator_id'],
      plantadeiraId: map['plantadeira_id'],
      dataCalibragem: DateTime.parse(map['data_calibragem']),
      espacamentoCm: map['espacamento_cm'],
      populacaoDesejada: map['populacao_desejada'],
      densidadeMetro: map['densidade_metro'],
      germinacaoPercentual: map['germinacao_percentual'],
      metodoCalibragrem: map['metodo_calibragem'] == 'engrenagem' 
          ? MetodoCalibragrem.engrenagem 
          : MetodoCalibragrem.gramas,
      engrenagemConfigurada: map['engrenagem_configurada'],
      pesoMilSementes: map['peso_mil_sementes'],
      sementesColetadas: map['sementes_coletadas'],
      sementesCalculadas: map['sementes_calculadas'],
      diferencaPercentual: map['diferenca_percentual'],
      observacoes: map['observacoes'],
      sincronizado: map['sincronizado'] == 1,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
    );
  }
}
