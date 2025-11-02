import 'package:uuid/uuid.dart';

/// Modelo para relatório de qualidade de plantio
class PlantingQualityReportModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final String variedade;
  final String safra;
  final double areaHectares;
  final DateTime dataPlantio;
  final DateTime dataAvaliacao;
  final String executor;
  
  // Dados de qualidade de plantio
  final double coeficienteVariacao; // CV%
  final String classificacaoCV; // Excelente, Bom, Moderado, Ruim
  final double plantasPorMetro;
  final double populacaoEstimadaPorHectare;
  final double singulacao; // %
  final double plantasDuplas; // %
  final double plantasFalhadas; // %
  
  // Dados de estande de plantas
  final double populacaoAlvo;
  final double populacaoReal;
  final double eficaciaEmergencia; // %
  final double desvioPopulacao; // plantas/ha
  
  // Análise automática
  final String analiseAutomatica;
  final String sugestoes;
  final String statusGeral; // Alta qualidade, Boa qualidade, Regular, Atenção
  
  // Dados de rastreabilidade
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String appVersion;
  final String deviceInfo;
  
  // Dados do mapa (opcional)
  final String? mapaPoligono; // GeoJSON do polígono do talhão
  final double? latitudeColeta;
  final double? longitudeColeta;
  
  // Imagem do estande
  final String? imagemEstandePath;

  PlantingQualityReportModel({
    String? id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    this.variedade = '',
    this.safra = '',
    required this.areaHectares,
    required this.dataPlantio,
    required this.dataAvaliacao,
    required this.executor,
    required this.coeficienteVariacao,
    required this.classificacaoCV,
    required this.plantasPorMetro,
    required this.populacaoEstimadaPorHectare,
    required this.singulacao,
    required this.plantasDuplas,
    required this.plantasFalhadas,
    required this.populacaoAlvo,
    required this.populacaoReal,
    required this.eficaciaEmergencia,
    required this.desvioPopulacao,
    required this.analiseAutomatica,
    required this.sugestoes,
    required this.statusGeral,
    DateTime? createdAt,
    this.updatedAt,
    this.appVersion = '1.0.0',
    this.deviceInfo = '',
    this.mapaPoligono,
    this.latitudeColeta,
    this.longitudeColeta,
    this.imagemEstandePath,
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
      'variedade': variedade,
      'safra': safra,
      'area_hectares': areaHectares,
      'data_plantio': dataPlantio.toIso8601String(),
      'data_avaliacao': dataAvaliacao.toIso8601String(),
      'executor': executor,
      'coeficiente_variacao': coeficienteVariacao,
      'classificacao_cv': classificacaoCV,
      'plantas_por_metro': plantasPorMetro,
      'populacao_estimada_hectare': populacaoEstimadaPorHectare,
      'singulacao': singulacao,
      'plantas_duplas': plantasDuplas,
      'plantas_falhadas': plantasFalhadas,
      'populacao_alvo': populacaoAlvo,
      'populacao_real': populacaoReal,
      'eficacia_emergencia': eficaciaEmergencia,
      'desvio_populacao': desvioPopulacao,
      'analise_automatica': analiseAutomatica,
      'sugestoes': sugestoes,
      'status_geral': statusGeral,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'app_version': appVersion,
      'device_info': deviceInfo,
      'mapa_poligono': mapaPoligono,
      'latitude_coleta': latitudeColeta,
      'longitude_coleta': longitudeColeta,
      'imagem_estande_path': imagemEstandePath,
    };
  }

  /// Cria a partir de Map
  factory PlantingQualityReportModel.fromMap(Map<String, dynamic> map) {
    return PlantingQualityReportModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaNome: map['cultura_nome'] ?? '',
      variedade: map['variedade'] ?? '',
      safra: map['safra'] ?? '',
      areaHectares: (map['area_hectares'] ?? 0.0).toDouble(),
      dataPlantio: DateTime.parse(map['data_plantio'] ?? DateTime.now().toIso8601String()),
      dataAvaliacao: DateTime.parse(map['data_avaliacao'] ?? DateTime.now().toIso8601String()),
      executor: map['executor'] ?? '',
      coeficienteVariacao: (map['coeficiente_variacao'] ?? 0.0).toDouble(),
      classificacaoCV: map['classificacao_cv'] ?? '',
      plantasPorMetro: (map['plantas_por_metro'] ?? 0.0).toDouble(),
      populacaoEstimadaPorHectare: (map['populacao_estimada_hectare'] ?? 0.0).toDouble(),
      singulacao: (map['singulacao'] ?? 0.0).toDouble(),
      plantasDuplas: (map['plantas_duplas'] ?? 0.0).toDouble(),
      plantasFalhadas: (map['plantas_falhadas'] ?? 0.0).toDouble(),
      populacaoAlvo: (map['populacao_alvo'] ?? 0.0).toDouble(),
      populacaoReal: (map['populacao_real'] ?? 0.0).toDouble(),
      eficaciaEmergencia: (map['eficacia_emergencia'] ?? 0.0).toDouble(),
      desvioPopulacao: (map['desvio_populacao'] ?? 0.0).toDouble(),
      analiseAutomatica: map['analise_automatica'] ?? '',
      sugestoes: map['sugestoes'] ?? '',
      statusGeral: map['status_geral'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      appVersion: map['app_version'] ?? '1.0.0',
      deviceInfo: map['device_info'] ?? '',
      mapaPoligono: map['mapa_poligono'],
      latitudeColeta: map['latitude_coleta']?.toDouble(),
      longitudeColeta: map['longitude_coleta']?.toDouble(),
      imagemEstandePath: map['imagem_estande_path'],
    );
  }

  /// Cria uma cópia com novos valores
  PlantingQualityReportModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    String? variedade,
    String? safra,
    double? areaHectares,
    DateTime? dataPlantio,
    DateTime? dataAvaliacao,
    String? executor,
    double? coeficienteVariacao,
    String? classificacaoCV,
    double? plantasPorMetro,
    double? populacaoEstimadaPorHectare,
    double? singulacao,
    double? plantasDuplas,
    double? plantasFalhadas,
    double? populacaoAlvo,
    double? populacaoReal,
    double? eficaciaEmergencia,
    double? desvioPopulacao,
    String? analiseAutomatica,
    String? sugestoes,
    String? statusGeral,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? appVersion,
    String? deviceInfo,
    String? mapaPoligono,
    double? latitudeColeta,
    double? longitudeColeta,
    String? imagemEstandePath,
  }) {
    return PlantingQualityReportModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      variedade: variedade ?? this.variedade,
      safra: safra ?? this.safra,
      areaHectares: areaHectares ?? this.areaHectares,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      executor: executor ?? this.executor,
      coeficienteVariacao: coeficienteVariacao ?? this.coeficienteVariacao,
      classificacaoCV: classificacaoCV ?? this.classificacaoCV,
      plantasPorMetro: plantasPorMetro ?? this.plantasPorMetro,
      populacaoEstimadaPorHectare: populacaoEstimadaPorHectare ?? this.populacaoEstimadaPorHectare,
      singulacao: singulacao ?? this.singulacao,
      plantasDuplas: plantasDuplas ?? this.plantasDuplas,
      plantasFalhadas: plantasFalhadas ?? this.plantasFalhadas,
      populacaoAlvo: populacaoAlvo ?? this.populacaoAlvo,
      populacaoReal: populacaoReal ?? this.populacaoReal,
      eficaciaEmergencia: eficaciaEmergencia ?? this.eficaciaEmergencia,
      desvioPopulacao: desvioPopulacao ?? this.desvioPopulacao,
      analiseAutomatica: analiseAutomatica ?? this.analiseAutomatica,
      sugestoes: sugestoes ?? this.sugestoes,
      statusGeral: statusGeral ?? this.statusGeral,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      mapaPoligono: mapaPoligono ?? this.mapaPoligono,
      latitudeColeta: latitudeColeta ?? this.latitudeColeta,
      longitudeColeta: longitudeColeta ?? this.longitudeColeta,
      imagemEstandePath: imagemEstandePath ?? this.imagemEstandePath,
    );
  }

  /// Retorna a cor do indicador de status geral
  String get corStatusGeral {
    switch (statusGeral.toLowerCase()) {
      case 'alta qualidade':
        return '#4CAF50'; // Verde
      case 'boa qualidade':
        return '#8BC34A'; // Verde claro
      case 'regular':
        return '#FFC107'; // Amarelo
      case 'atenção':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Retorna o emoji do status geral
  String get emojiStatusGeral {
    switch (statusGeral.toLowerCase()) {
      case 'alta qualidade':
        return '🟢';
      case 'boa qualidade':
        return '🟡';
      case 'regular':
        return '🟠';
      case 'atenção':
        return '🔴';
      default:
        return '⚪';
    }
  }

  /// Retorna a cor do indicador de CV%
  String get corCV {
    if (coeficienteVariacao < 10) return '#4CAF50'; // Verde - Excelente
    if (coeficienteVariacao < 20) return '#8BC34A'; // Verde claro - Bom
    if (coeficienteVariacao <= 30) return '#FFC107'; // Amarelo - Moderado
    return '#F44336'; // Vermelho - Ruim
  }

  /// Retorna o emoji do CV%
  String get emojiCV {
    if (coeficienteVariacao < 10) return '🟢';
    if (coeficienteVariacao < 20) return '🟡';
    if (coeficienteVariacao <= 30) return '🟠';
    return '🔴';
  }

  /// Retorna a cor do indicador de singulação
  String get corSingulacao {
    if (singulacao >= 95) return '#4CAF50'; // Verde
    if (singulacao >= 90) return '#8BC34A'; // Verde claro
    if (singulacao >= 85) return '#FFC107'; // Amarelo
    return '#F44336'; // Vermelho
  }

  /// Retorna a cor do indicador de eficácia de emergência
  String get corEficaciaEmergencia {
    if (eficaciaEmergencia >= 95) return '#4CAF50'; // Verde
    if (eficaciaEmergencia >= 90) return '#8BC34A'; // Verde claro
    if (eficaciaEmergencia >= 85) return '#FFC107'; // Amarelo
    return '#F44336'; // Vermelho
  }

  /// Retorna o percentual de diferença da população alvo
  double get percentualDiferencaPopulacao {
    if (populacaoAlvo == 0) return 0.0;
    return ((populacaoReal - populacaoAlvo) / populacaoAlvo) * 100;
  }

  /// Retorna o status da população em relação ao alvo
  String get statusPopulacao {
    final diferenca = percentualDiferencaPopulacao.abs();
    if (diferenca <= 5) return 'Dentro da meta';
    if (diferenca <= 15) return 'Próximo da meta';
    return 'Fora da meta';
  }

  /// Retorna a cor do status da população
  String get corStatusPopulacao {
    final diferenca = percentualDiferencaPopulacao.abs();
    if (diferenca <= 5) return '#4CAF50'; // Verde
    if (diferenca <= 15) return '#FFC107'; // Amarelo
    return '#F44336'; // Vermelho
  }
}
