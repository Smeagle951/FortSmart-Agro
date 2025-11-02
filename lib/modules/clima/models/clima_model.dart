// lib/modules/clima/models/clima_model.dart
import 'dart:convert';

class ClimaModel {
  final String id;
  final double latitude;
  final double longitude;
  final String cidade;
  final String pais;
  final double temperatura;
  final double sensacaoTermica;
  final double temperaturaMinima;
  final double temperaturaMaxima;
  final int umidade;
  final double pressao;
  final double visibilidade;
  final double velocidadeVento;
  final int direcaoVento;
  final int nuvens;
  final String condicao;
  final String descricao;
  final String icone;
  final DateTime nascer;
  final DateTime porSol;
  final DateTime dataHora;
  final DateTime? ultimaAtualizacao;
  final double? precipitacao1h;
  final double? precipitacao3h;
  final double? indiceUV;
  final String? alertas;
  final Map<String, dynamic>? dadosAdicionais;

  ClimaModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.cidade,
    required this.pais,
    required this.temperatura,
    required this.sensacaoTermica,
    required this.temperaturaMinima,
    required this.temperaturaMaxima,
    required this.umidade,
    required this.pressao,
    required this.visibilidade,
    required this.velocidadeVento,
    required this.direcaoVento,
    required this.nuvens,
    required this.condicao,
    required this.descricao,
    required this.icone,
    required this.nascer,
    required this.porSol,
    required this.dataHora,
    this.ultimaAtualizacao,
    this.precipitacao1h,
    this.precipitacao3h,
    this.indiceUV,
    this.alertas,
    this.dadosAdicionais,
  });

  // Factory para criar a partir da API OpenWeatherMap
  factory ClimaModel.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final sys = json['sys'] as Map<String, dynamic>;
    final coord = json['coord'] as Map<String, dynamic>;
    final rain = json['rain'] as Map<String, dynamic>?;
    final snow = json['snow'] as Map<String, dynamic>?;

    return ClimaModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: (coord['lat'] as num).toDouble(),
      longitude: (coord['lon'] as num).toDouble(),
      cidade: json['name'] as String? ?? 'Desconhecida',
      pais: sys['country'] as String? ?? 'BR',
      temperatura: (main['temp'] as num).toDouble(),
      sensacaoTermica: (main['feels_like'] as num).toDouble(),
      temperaturaMinima: (main['temp_min'] as num).toDouble(),
      temperaturaMaxima: (main['temp_max'] as num).toDouble(),
      umidade: main['humidity'] as int,
      pressao: (main['pressure'] as num).toDouble(),
      visibilidade: ((json['visibility'] as num?) ?? 10000).toDouble(),
      velocidadeVento: ((wind['speed'] as num?) ?? 0).toDouble() * 3.6, // m/s para km/h
      direcaoVento: (wind['deg'] as num?)?.toInt() ?? 0,
      nuvens: (clouds['all'] as num?)?.toInt() ?? 0,
      condicao: weather['main'] as String,
      descricao: weather['description'] as String,
      icone: weather['icon'] as String,
      nascer: DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000),
      porSol: DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000),
      dataHora: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      ultimaAtualizacao: DateTime.now(),
      precipitacao1h: rain?['1h']?.toDouble() ?? snow?['1h']?.toDouble(),
      precipitacao3h: rain?['3h']?.toDouble() ?? snow?['3h']?.toDouble(),
      dadosAdicionais: {
        'timezone': json['timezone'],
        'cod': json['cod'],
        'base': json['base'],
        'weather_id': weather['id'],
      },
    );
  }

  // Factory para criar a partir do banco de dados
  factory ClimaModel.fromMap(Map<String, dynamic> map) {
    return ClimaModel(
      id: map['id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      cidade: map['cidade'] as String,
      pais: map['pais'] as String,
      temperatura: map['temperatura'] as double,
      sensacaoTermica: map['sensacao_termica'] as double,
      temperaturaMinima: map['temperatura_minima'] as double,
      temperaturaMaxima: map['temperatura_maxima'] as double,
      umidade: map['umidade'] as int,
      pressao: map['pressao'] as double,
      visibilidade: map['visibilidade'] as double,
      velocidadeVento: map['velocidade_vento'] as double,
      direcaoVento: map['direcao_vento'] as int,
      nuvens: map['nuvens'] as int,
      condicao: map['condicao'] as String,
      descricao: map['descricao'] as String,
      icone: map['icone'] as String,
      nascer: DateTime.parse(map['nascer'] as String),
      porSol: DateTime.parse(map['por_sol'] as String),
      dataHora: DateTime.parse(map['data_hora'] as String),
      ultimaAtualizacao: map['ultima_atualizacao'] != null 
        ? DateTime.parse(map['ultima_atualizacao'] as String)
        : null,
      precipitacao1h: map['precipitacao_1h'] as double?,
      precipitacao3h: map['precipitacao_3h'] as double?,
      indiceUV: map['indice_uv'] as double?,
      alertas: map['alertas'] as String?,
      dadosAdicionais: map['dados_adicionais'] != null 
        ? jsonDecode(map['dados_adicionais'] as String) as Map<String, dynamic>
        : null,
    );
  }

  // Converter para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'cidade': cidade,
      'pais': pais,
      'temperatura': temperatura,
      'sensacao_termica': sensacaoTermica,
      'temperatura_minima': temperaturaMinima,
      'temperatura_maxima': temperaturaMaxima,
      'umidade': umidade,
      'pressao': pressao,
      'visibilidade': visibilidade,
      'velocidade_vento': velocidadeVento,
      'direcao_vento': direcaoVento,
      'nuvens': nuvens,
      'condicao': condicao,
      'descricao': descricao,
      'icone': icone,
      'nascer': nascer.toIso8601String(),
      'por_sol': porSol.toIso8601String(),
      'data_hora': dataHora.toIso8601String(),
      'ultima_atualizacao': ultimaAtualizacao?.toIso8601String(),
      'precipitacao_1h': precipitacao1h,
      'precipitacao_3h': precipitacao3h,
      'indice_uv': indiceUV,
      'alertas': alertas,
      'dados_adicionais': dadosAdicionais != null ? jsonEncode(dadosAdicionais) : null,
    };
  }

  // Converter para JSON
  String toJson() => jsonEncode(toMap());

  // Factory para criar a partir de JSON
  factory ClimaModel.fromJson(String source) => ClimaModel.fromMap(jsonDecode(source));

  // Métodos auxiliares
  bool get isDayTime => icone.endsWith('d');
  
  bool get isNightTime => icone.endsWith('n');
  
  bool get isRaining => condicao.toLowerCase().contains('rain') || 
                       condicao.toLowerCase().contains('drizzle');
  
  bool get isStormy => condicao.toLowerCase().contains('thunderstorm');
  
  bool get isCloudy => condicao.toLowerCase().contains('cloud');
  
  bool get isClear => condicao.toLowerCase().contains('clear');
  
  bool get isFoggy => condicao.toLowerCase().contains('fog') || 
                      condicao.toLowerCase().contains('mist');

  // Avaliação de condições para agricultura
  bool get isGoodForSpraying {
    return velocidadeVento < 15 && // Vento baixo
           !isRaining && // Sem chuva
           !isStormy && // Sem tempestade
           umidade > 30 && umidade < 90; // Umidade adequada
  }

  bool get hasFrostRisk {
    return temperatura <= 3.0 || temperaturaMinima <= 0.0;
  }

  bool get hasHighWindAlert {
    return velocidadeVento >= 25.0;
  }

  bool get hasHeatAlert {
    return temperatura >= 38.0;
  }

  String get windDirection {
    if (direcaoVento >= 337.5 || direcaoVento < 22.5) return 'N';
    if (direcaoVento >= 22.5 && direcaoVento < 67.5) return 'NE';
    if (direcaoVento >= 67.5 && direcaoVento < 112.5) return 'E';
    if (direcaoVento >= 112.5 && direcaoVento < 157.5) return 'SE';
    if (direcaoVento >= 157.5 && direcaoVento < 202.5) return 'S';
    if (direcaoVento >= 202.5 && direcaoVento < 247.5) return 'SO';
    if (direcaoVento >= 247.5 && direcaoVento < 292.5) return 'O';
    if (direcaoVento >= 292.5 && direcaoVento < 337.5) return 'NO';
    return 'N/A';
  }

  String get humidityLevel {
    if (umidade >= 80) return 'Muito alta';
    if (umidade >= 60) return 'Alta';
    if (umidade >= 40) return 'Moderada';
    if (umidade >= 20) return 'Baixa';
    return 'Muito baixa';
  }

  String get windIntensity {
    if (velocidadeVento >= 30) return 'Muito forte';
    if (velocidadeVento >= 20) return 'Forte';
    if (velocidadeVento >= 10) return 'Moderado';
    if (velocidadeVento >= 5) return 'Fraco';
    return 'Calmo';
  }

  // Cópia com modificações
  ClimaModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? cidade,
    String? pais,
    double? temperatura,
    double? sensacaoTermica,
    double? temperaturaMinima,
    double? temperaturaMaxima,
    int? umidade,
    double? pressao,
    double? visibilidade,
    double? velocidadeVento,
    int? direcaoVento,
    int? nuvens,
    String? condicao,
    String? descricao,
    String? icone,
    DateTime? nascer,
    DateTime? porSol,
    DateTime? dataHora,
    DateTime? ultimaAtualizacao,
    double? precipitacao1h,
    double? precipitacao3h,
    double? indiceUV,
    String? alertas,
    Map<String, dynamic>? dadosAdicionais,
  }) {
    return ClimaModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cidade: cidade ?? this.cidade,
      pais: pais ?? this.pais,
      temperatura: temperatura ?? this.temperatura,
      sensacaoTermica: sensacaoTermica ?? this.sensacaoTermica,
      temperaturaMinima: temperaturaMinima ?? this.temperaturaMinima,
      temperaturaMaxima: temperaturaMaxima ?? this.temperaturaMaxima,
      umidade: umidade ?? this.umidade,
      pressao: pressao ?? this.pressao,
      visibilidade: visibilidade ?? this.visibilidade,
      velocidadeVento: velocidadeVento ?? this.velocidadeVento,
      direcaoVento: direcaoVento ?? this.direcaoVento,
      nuvens: nuvens ?? this.nuvens,
      condicao: condicao ?? this.condicao,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      nascer: nascer ?? this.nascer,
      porSol: porSol ?? this.porSol,
      dataHora: dataHora ?? this.dataHora,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      precipitacao1h: precipitacao1h ?? this.precipitacao1h,
      precipitacao3h: precipitacao3h ?? this.precipitacao3h,
      indiceUV: indiceUV ?? this.indiceUV,
      alertas: alertas ?? this.alertas,
      dadosAdicionais: dadosAdicionais ?? this.dadosAdicionais,
    );
  }

  @override
  String toString() {
    return 'ClimaModel(id: $id, cidade: $cidade, temperatura: $temperatura°C, '
           'condicao: $condicao, dataHora: $dataHora)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClimaModel &&
           other.id == id &&
           other.dataHora == dataHora;
  }

  @override
  int get hashCode => id.hashCode ^ dataHora.hashCode;
}

// Modelo para previsão do tempo (múltiplos dias)
class PrevisaoModel {
  final String id;
  final double latitude;
  final double longitude;
  final String cidade;
  final List<ClimaModel> previsoes;
  final DateTime ultimaAtualizacao;

  PrevisaoModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.cidade,
    required this.previsoes,
    required this.ultimaAtualizacao,
  });

  factory PrevisaoModel.fromOpenWeatherMap(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>;
    final list = json['list'] as List;
    
    final previsoes = list.map((item) {
      // Adaptar cada item da lista para o formato do ClimaModel
      final adaptedItem = {
        ...item,
        'coord': city['coord'],
        'name': city['name'],
        'sys': {
          'country': city['country'],
          'sunrise': city['sunrise'],
          'sunset': city['sunset'],
        },
        'id': city['id'],
        'timezone': city['timezone'],
      };
      return ClimaModel.fromOpenWeatherMap(adaptedItem);
    }).toList();

    return PrevisaoModel(
      id: city['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: (city['coord']['lat'] as num).toDouble(),
      longitude: (city['coord']['lon'] as num).toDouble(),
      cidade: city['name'] as String,
      previsoes: previsoes,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'cidade': cidade,
      'previsoes': previsoes.map((p) => p.toMap()).toList(),
      'ultima_atualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  factory PrevisaoModel.fromMap(Map<String, dynamic> map) {
    return PrevisaoModel(
      id: map['id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      cidade: map['cidade'] as String,
      previsoes: (map['previsoes'] as List)
          .map((p) => ClimaModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      ultimaAtualizacao: DateTime.parse(map['ultima_atualizacao'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PrevisaoModel.fromJson(String source) => PrevisaoModel.fromMap(jsonDecode(source));
}
