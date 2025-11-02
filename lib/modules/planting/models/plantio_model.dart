import 'package:uuid/uuid.dart';

/// Modelo para representar um plantio agrícola
class PlantioModel {
  final String id;
  final String talhaoId;
  final String culturaId;
  final String? safraId;
  final String? variedadeId;
  final DateTime dataPlantio;
  final int populacao;
  final double espacamento;
  final double profundidade;
  final List<String> maquinasIds;
  final String? calibragemId;
  final String? estandeId;
  final String? observacoes;
  final bool sincronizado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? tratorId;
  final String? plantadeiraId;
  // Novos campos para o layout premium
  final double? densidadeLinear;
  final double? germinacao;
  final String? metodoCalibragem;
  final String? fonteSementesId;
  final Map<String, double>? resultados;
  // Novos campos para cálculos agronômicos
  final double? pesoMilSementes;
  final double? gramasColetadas;
  final double? distanciaPercorrida;
  final int? engrenagemMotora;
  final int? engrenagemMovida;

  PlantioModel({
    String? id,
    required this.talhaoId,
    required this.culturaId,
    this.safraId,
    this.variedadeId,
    required this.dataPlantio,
    required this.populacao,
    required this.espacamento,
    required this.profundidade,
    required this.maquinasIds,
    this.calibragemId,
    this.estandeId,
    this.observacoes,
    this.sincronizado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    this.tratorId,
    this.plantadeiraId,
    this.densidadeLinear,
    this.germinacao,
    this.metodoCalibragem,
    this.fonteSementesId,
    this.resultados,
    this.pesoMilSementes,
    this.gramasColetadas,
    this.distanciaPercorrida,
    this.engrenagemMotora,
    this.engrenagemMovida,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.criadoEm = criadoEm ?? DateTime.now(),
    this.atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  PlantioModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    String? safraId,
    String? variedadeId,
    DateTime? dataPlantio,
    int? populacao,
    double? espacamento,
    double? profundidade,
    List<String>? maquinasIds,
    String? calibragemId,
    String? estandeId,
    String? observacoes,
    bool? sincronizado,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? plantadeiraId,
    String? tratorId,
    double? densidadeLinear,
    double? germinacao,
    String? metodoCalibragem,
    String? fonteSementesId,
    Map<String, double>? resultados,
    double? pesoMilSementes,
    double? gramasColetadas,
    double? distanciaPercorrida,
    int? engrenagemMotora,
    int? engrenagemMovida,
  }) {
    return PlantioModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      safraId: safraId ?? this.safraId,
      variedadeId: variedadeId ?? this.variedadeId,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      populacao: populacao ?? this.populacao,
      espacamento: espacamento ?? this.espacamento,
      profundidade: profundidade ?? this.profundidade,
      maquinasIds: maquinasIds ?? this.maquinasIds,
      calibragemId: calibragemId ?? this.calibragemId,
      estandeId: estandeId ?? this.estandeId,
      observacoes: observacoes ?? this.observacoes,
      sincronizado: sincronizado ?? this.sincronizado,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
      tratorId: tratorId ?? this.tratorId,
      plantadeiraId: plantadeiraId ?? this.plantadeiraId,
      densidadeLinear: densidadeLinear ?? this.densidadeLinear,
      germinacao: germinacao ?? this.germinacao,
      metodoCalibragem: metodoCalibragem ?? this.metodoCalibragem,
      fonteSementesId: fonteSementesId ?? this.fonteSementesId,
      resultados: resultados ?? this.resultados,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      gramasColetadas: gramasColetadas ?? this.gramasColetadas,
      distanciaPercorrida: distanciaPercorrida ?? this.distanciaPercorrida,
      engrenagemMotora: engrenagemMotora ?? this.engrenagemMotora,
      engrenagemMovida: engrenagemMovida ?? this.engrenagemMovida,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'safra_id': safraId,
      'variedade_id': variedadeId,
      'data_plantio': dataPlantio.toIso8601String(),
      'populacao': populacao,
      'espacamento': espacamento,
      'profundidade': profundidade,
      'maquinas_ids': maquinasIds.join(','),
      'calibragem_id': calibragemId,
      'estande_id': estandeId,
      'observacoes': observacoes,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'trator_id': tratorId,
      'plantadeira_id': plantadeiraId,
      'densidade_linear': densidadeLinear,
      'germinacao': germinacao,
      'metodo_calibragem': metodoCalibragem,
      'fonte_sementes_id': fonteSementesId,
      'resultados': resultados != null ? resultados!.toString() : null,
      'peso_mil_sementes': pesoMilSementes,
      'gramas_coletadas': gramasColetadas,
      'distancia_percorrida': distanciaPercorrida,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory PlantioModel.fromMap(Map<String, dynamic> map) {
    return PlantioModel(
      id: map['id']?.toString(),
      talhaoId: map['talhao_id']?.toString() ?? '',
      culturaId: map['cultura_id']?.toString() ?? '',
      safraId: map['safra_id']?.toString(),
      variedadeId: map['variedade_id']?.toString(),
      dataPlantio: map['data_plantio'] != null 
          ? DateTime.parse(map['data_plantio'].toString())
          : DateTime.now(),
      populacao: map['populacao']?.toInt() ?? 0,
      espacamento: map['espacamento']?.toDouble() ?? 0.0,
      profundidade: map['profundidade']?.toDouble() ?? 0.0,
      maquinasIds: map['maquinas_ids'] != null && map['maquinas_ids'].toString().isNotEmpty 
          ? map['maquinas_ids'].toString().split(',') 
          : <String>[],
      calibragemId: map['calibragem_id']?.toString(),
      estandeId: map['estande_id']?.toString(),
      observacoes: map['observacoes']?.toString(),
      sincronizado: map['sincronizado'] == 1,
      criadoEm: map['criado_em'] != null 
          ? DateTime.parse(map['criado_em'].toString())
          : DateTime.now(),
      atualizadoEm: map['atualizado_em'] != null 
          ? DateTime.parse(map['atualizado_em'].toString())
          : DateTime.now(),
      tratorId: map['trator_id']?.toString(),
      plantadeiraId: map['plantadeira_id']?.toString(),
      densidadeLinear: map['densidade_linear']?.toDouble(),
      germinacao: map['germinacao']?.toDouble(),
      metodoCalibragem: map['metodo_calibragem']?.toString(),
      fonteSementesId: map['fonte_sementes_id']?.toString(),
      resultados: map['resultados'] != null ? _parseResultados(map['resultados'].toString()) : null,
      pesoMilSementes: map['peso_mil_sementes']?.toDouble(),
      gramasColetadas: map['gramas_coletadas']?.toDouble(),
      distanciaPercorrida: map['distancia_percorrida']?.toDouble(),
      engrenagemMotora: map['engrenagem_motora']?.toInt(),
      engrenagemMovida: map['engrenagem_movida']?.toInt(),
    );
  }
  
  /// Parse dos resultados do banco de dados
  static Map<String, double>? _parseResultados(String resultadosStr) {
    try {
      // Implementação simples - em produção seria mais robusta
      final Map<String, double> resultados = {};
      final pairs = resultadosStr.replaceAll('{', '').replaceAll('}', '').split(',');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim());
          if (value != null) {
            resultados[key] = value;
          }
        }
      }
      return resultados;
    } catch (e) {
      return null;
    }
  }
}
