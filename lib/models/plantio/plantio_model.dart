import 'package:uuid/uuid.dart';

/// Modelo para representar um registro de plantio
class PlantioModel {
  final String? id;
  final DateTime dataPlantio;
  final String talhaoId;
  final String safraId;
  final String culturaId;
  final String variedadeId;
  final double espacamentoCm;
  final int populacaoDesejada;
  final double densidadeMetro;
  final double germinacaoPercentual;
  final MetodoCalibragrem metodoCalibragrem;
  final String fonteEstoqueId;
  final int sementesHa;
  final double kgHa;
  final double sacasHa;
  final String usuarioId;
  final bool sincronizado;
  final DateTime criadoEm;
  
  // Campos extras premium
  final String? fotoPlantabilidade;
  final double? latitude;
  final double? longitude;
  final String? qrCodeLote;

  PlantioModel({
    this.id,
    required this.dataPlantio,
    required this.talhaoId,
    required this.safraId,
    required this.culturaId,
    required this.variedadeId,
    required this.espacamentoCm,
    required this.populacaoDesejada,
    required this.densidadeMetro,
    required this.germinacaoPercentual,
    required this.metodoCalibragrem,
    required this.fonteEstoqueId,
    required this.sementesHa,
    required this.kgHa,
    required this.sacasHa,
    required this.usuarioId,
    this.sincronizado = false,
    DateTime? criadoEm,
    this.fotoPlantabilidade,
    this.latitude,
    this.longitude,
    this.qrCodeLote,
  }) : this.criadoEm = criadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  PlantioModel copyWith({
    String? id,
    DateTime? dataPlantio,
    String? talhaoId,
    String? safraId,
    String? culturaId,
    String? variedadeId,
    double? espacamentoCm,
    int? populacaoDesejada,
    double? densidadeMetro,
    double? germinacaoPercentual,
    MetodoCalibragrem? metodoCalibragrem,
    String? fonteEstoqueId,
    int? sementesHa,
    double? kgHa,
    double? sacasHa,
    String? usuarioId,
    bool? sincronizado,
    DateTime? criadoEm,
    String? fotoPlantabilidade,
    double? latitude,
    double? longitude,
    String? qrCodeLote,
  }) {
    return PlantioModel(
      id: id ?? this.id,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      densidadeMetro: densidadeMetro ?? this.densidadeMetro,
      germinacaoPercentual: germinacaoPercentual ?? this.germinacaoPercentual,
      metodoCalibragrem: metodoCalibragrem ?? this.metodoCalibragrem,
      fonteEstoqueId: fonteEstoqueId ?? this.fonteEstoqueId,
      sementesHa: sementesHa ?? this.sementesHa,
      kgHa: kgHa ?? this.kgHa,
      sacasHa: sacasHa ?? this.sacasHa,
      usuarioId: usuarioId ?? this.usuarioId,
      sincronizado: sincronizado ?? this.sincronizado,
      criadoEm: criadoEm ?? this.criadoEm,
      fotoPlantabilidade: fotoPlantabilidade ?? this.fotoPlantabilidade,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      qrCodeLote: qrCodeLote ?? this.qrCodeLote,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'data_plantio': dataPlantio.toIso8601String(),
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'espacamento_cm': espacamentoCm,
      'populacao_desejada': populacaoDesejada,
      'densidade_metro': densidadeMetro,
      'germinacao_percentual': germinacaoPercentual,
      'metodo_calibragem': metodoCalibragrem.toString().split('.').last,
      'fonte_estoque_id': fonteEstoqueId,
      'sementes_ha': sementesHa,
      'kg_ha': kgHa,
      'sacas_ha': sacasHa,
      'usuario_id': usuarioId,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'foto_plantabilidade': fotoPlantabilidade,
      'latitude': latitude,
      'longitude': longitude,
      'qr_code_lote': qrCodeLote,
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory PlantioModel.fromMap(Map<String, dynamic> map) {
    return PlantioModel(
      id: map['id'],
      dataPlantio: DateTime.parse(map['data_plantio']),
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      espacamentoCm: map['espacamento_cm'],
      populacaoDesejada: map['populacao_desejada'],
      densidadeMetro: map['densidade_metro'],
      germinacaoPercentual: map['germinacao_percentual'],
      metodoCalibragrem: map['metodo_calibragem'] == 'engrenagem' 
          ? MetodoCalibragrem.engrenagem 
          : MetodoCalibragrem.gramas,
      fonteEstoqueId: map['fonte_estoque_id'],
      sementesHa: map['sementes_ha'],
      kgHa: map['kg_ha'],
      sacasHa: map['sacas_ha'],
      usuarioId: map['usuario_id'],
      sincronizado: map['sincronizado'] == 1,
      criadoEm: DateTime.parse(map['criado_em']),
      fotoPlantabilidade: map['foto_plantabilidade'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      qrCodeLote: map['qr_code_lote'],
    );
  }
}

/// Enum para representar o método de calibragem
enum MetodoCalibragrem {
  engrenagem,
  gramas,
}
