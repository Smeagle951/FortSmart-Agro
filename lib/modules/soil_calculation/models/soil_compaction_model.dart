import 'dart:convert';

/// Modelo para armazenar dados de compactação do solo
class SoilCompactionModel {
  final int? id;
  final int talhaoId;
  final int safraId;
  final String data;
  final double latitude;
  final double longitude;
  final String tipoCalculo; // 'simples' ou 'irp'
  final double pesoMartelo;
  final double alturaQueda;
  final double diametroPonteira;
  final double? anguloPonteira;
  final int numGolpes;
  final double distanciaTotal;
  final double resultadoRp;
  final String interpretacao;
  final double profundidade;
  final String? fotoCaminho;

  SoilCompactionModel({
    this.id,
    required this.talhaoId,
    required this.safraId,
    required this.data,
    required this.latitude,
    required this.longitude,
    required this.tipoCalculo,
    required this.pesoMartelo,
    required this.alturaQueda,
    required this.diametroPonteira,
    this.anguloPonteira,
    required this.numGolpes,
    required this.distanciaTotal,
    required this.resultadoRp,
    required this.interpretacao,
    required this.profundidade,
    this.fotoCaminho,
  });

  SoilCompactionModel copyWith({
    int? id,
    int? talhaoId,
    int? safraId,
    String? data,
    double? latitude,
    double? longitude,
    String? tipoCalculo,
    double? pesoMartelo,
    double? alturaQueda,
    double? diametroPonteira,
    double? anguloPonteira,
    int? numGolpes,
    double? distanciaTotal,
    double? resultadoRp,
    String? interpretacao,
    double? profundidade,
    String? fotoCaminho,
  }) {
    return SoilCompactionModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      data: data ?? this.data,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tipoCalculo: tipoCalculo ?? this.tipoCalculo,
      pesoMartelo: pesoMartelo ?? this.pesoMartelo,
      alturaQueda: alturaQueda ?? this.alturaQueda,
      diametroPonteira: diametroPonteira ?? this.diametroPonteira,
      anguloPonteira: anguloPonteira ?? this.anguloPonteira,
      numGolpes: numGolpes ?? this.numGolpes,
      distanciaTotal: distanciaTotal ?? this.distanciaTotal,
      resultadoRp: resultadoRp ?? this.resultadoRp,
      interpretacao: interpretacao ?? this.interpretacao,
      profundidade: profundidade ?? this.profundidade,
      fotoCaminho: fotoCaminho ?? this.fotoCaminho,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'data': data,
      'latitude': latitude,
      'longitude': longitude,
      'tipo_calculo': tipoCalculo,
      'peso_martelo': pesoMartelo,
      'altura_queda': alturaQueda,
      'diametro_ponteira': diametroPonteira,
      'angulo_ponteira': anguloPonteira,
      'num_golpes': numGolpes,
      'distancia_total': distanciaTotal,
      'resultado_rp': resultadoRp,
      'interpretacao': interpretacao,
      'profundidade': profundidade,
      'foto_caminho': fotoCaminho,
    };
  }

  factory SoilCompactionModel.fromMap(Map<String, dynamic> map) {
    return SoilCompactionModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      data: map['data'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      tipoCalculo: map['tipo_calculo'],
      pesoMartelo: map['peso_martelo'],
      alturaQueda: map['altura_queda'],
      diametroPonteira: map['diametro_ponteira'],
      anguloPonteira: map['angulo_ponteira'],
      numGolpes: map['num_golpes'],
      distanciaTotal: map['distancia_total'],
      resultadoRp: map['resultado_rp'],
      interpretacao: map['interpretacao'],
      profundidade: map['profundidade'],
      fotoCaminho: map['foto_caminho'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SoilCompactionModel.fromJson(String source) =>
      SoilCompactionModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SoilCompactionModel(id: $id, talhaoId: $talhaoId, safraId: $safraId, data: $data, latitude: $latitude, longitude: $longitude, tipoCalculo: $tipoCalculo, pesoMartelo: $pesoMartelo, alturaQueda: $alturaQueda, diametroPonteira: $diametroPonteira, anguloPonteira: $anguloPonteira, numGolpes: $numGolpes, distanciaTotal: $distanciaTotal, resultadoRp: $resultadoRp, interpretacao: $interpretacao, profundidade: $profundidade, fotoCaminho: $fotoCaminho)';
  }
}
