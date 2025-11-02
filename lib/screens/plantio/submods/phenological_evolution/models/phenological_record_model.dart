/// 📋 Model: Registro Fenológico Quinzenal
/// 
/// Este modelo representa um registro de acompanhamento fenológico,
/// coletado quinzenalmente no campo. Contém todos os dados medidos
/// e observados em cada visita de campo.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/foundation.dart';

class PhenologicalRecordModel {
  /// Identificador único do registro
  final String id;
  
  /// ID do talhão onde foi feito o registro
  final String talhaoId;
  
  /// ID da cultura avaliada
  final String culturaId;
  
  /// Data do registro de campo
  final DateTime dataRegistro;
  
  /// Dias após emergência (DAE)
  final int diasAposEmergencia;
  
  /// 📏 MEDIÇÕES DE CRESCIMENTO VEGETATIVO
  
  /// Altura média das plantas (cm)
  final double? alturaCm;
  
  /// Número médio de folhas expandidas
  final int? numeroFolhas;
  
  /// Número médio de folhas trifolioladas (soja/feijão)
  final int? numeroFolhasTrifolioladas;
  
  /// Diâmetro do colmo (mm) - para milho, sorgo
  final double? diametroColmoMm;
  
  /// Número de nós (soja, feijão)
  final int? numeroNos;
  
  /// Espaçamento médio entre nós (cm)
  final double? espacamentoEntreNosCm;
  
  /// Número de ramos vegetativos (algodão)
  final int? numeroRamosVegetativos;
  
  /// Número de ramos reprodutivos/frutíferos (algodão)
  final int? numeroRamosReprodutivos;
  
  /// Altura do primeiro ramo frutífero (cm) - algodão
  final double? alturaPrimeiroRamoFrutiferoCm;
  
  /// Número de botões florais (algodão)
  final int? numeroBotoesFlorais;
  
  /// Número de maçãs/capulhos (algodão)
  final int? numeroMacasCapulhos;
  
  /// Número de afilhos (trigo, aveia, arroz)
  final int? numeroAfilhos;
  
  /// Comprimento da panícula (cm) - arroz, sorgo
  final double? comprimentoPaniculaCm;
  
  /// Inserção da espiga (cm) - milho
  final double? insercaoEspigaCm;
  
  /// Comprimento da espiga (cm) - milho
  final double? comprimentoEspigaCm;
  
  /// Número de fileiras de grãos - milho
  final int? numeroFileirasGraos;
  
  /// 🌸 MEDIÇÕES DE DESENVOLVIMENTO REPRODUTIVO
  
  /// Número médio de vagens por planta (leguminosas)
  final double? vagensPlanta;
  
  /// Número médio de espigas por planta (milho)
  final double? espigasPlanta;
  
  /// Comprimento médio de vagens (cm)
  final double? comprimentoVagensCm;
  
  /// Número médio de grãos por vagem/espiga
  final double? graosVagem;
  
  /// 🌱 ESTANDE E DENSIDADE
  
  /// Estande real (plantas/ha)
  final double? estandePlantas;
  
  /// Percentual de falhas no estande (%)
  final double? percentualFalhas;
  
  /// 🩺 SANIDADE E ESTADO GERAL
  
  /// Percentual de plantas sadias (%)
  final double? percentualSanidade;
  
  /// Observações de sintomas visuais
  final String? sintomasObservados;
  
  /// Presença de pragas (bool)
  final bool? presencaPragas;
  
  /// Presença de doenças (bool)
  final bool? presencaDoencas;
  
  /// 📊 CLASSIFICAÇÃO AUTOMÁTICA
  
  /// Estágio fenológico identificado (ex: V4, R1, R5)
  final String? estagioFenologico;
  
  /// Descrição do estágio
  final String? descricaoEstagio;
  
  /// 📷 DOCUMENTAÇÃO
  
  /// Lista de caminhos das fotos
  final List<String> fotos;
  
  /// Observações gerais do técnico
  final String? observacoes;
  
  /// Coordenadas GPS do ponto de coleta
  final double? latitude;
  final double? longitude;
  
  /// 🔄 METADADOS
  
  /// Responsável pelo registro
  final String? responsavel;
  
  /// Data de criação do registro
  final DateTime createdAt;
  
  /// Data de última atualização
  final DateTime updatedAt;

  PhenologicalRecordModel({
    required this.id,
    required this.talhaoId,
    required this.culturaId,
    required this.dataRegistro,
    required this.diasAposEmergencia,
    this.alturaCm,
    this.numeroFolhas,
    this.numeroFolhasTrifolioladas,
    this.diametroColmoMm,
    this.numeroNos,
    this.espacamentoEntreNosCm,
    this.numeroRamosVegetativos,
    this.numeroRamosReprodutivos,
    this.alturaPrimeiroRamoFrutiferoCm,
    this.numeroBotoesFlorais,
    this.numeroMacasCapulhos,
    this.numeroAfilhos,
    this.comprimentoPaniculaCm,
    this.insercaoEspigaCm,
    this.comprimentoEspigaCm,
    this.numeroFileirasGraos,
    this.vagensPlanta,
    this.espigasPlanta,
    this.comprimentoVagensCm,
    this.graosVagem,
    this.estandePlantas,
    this.percentualFalhas,
    this.percentualSanidade,
    this.sintomasObservados,
    this.presencaPragas,
    this.presencaDoencas,
    this.estagioFenologico,
    this.descricaoEstagio,
    this.fotos = const [],
    this.observacoes,
    this.latitude,
    this.longitude,
    this.responsavel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory: Criar novo registro
  factory PhenologicalRecordModel.novo({
    required String talhaoId,
    required String culturaId,
    required DateTime dataRegistro,
    required int diasAposEmergencia,
    double? alturaCm,
    int? numeroFolhas,
    int? numeroFolhasTrifolioladas,
    double? diametroColmoMm,
    int? numeroNos,
    double? espacamentoEntreNosCm,
    int? numeroRamosVegetativos,
    int? numeroRamosReprodutivos,
    double? alturaPrimeiroRamoFrutiferoCm,
    int? numeroBotoesFlorais,
    int? numeroMacasCapulhos,
    int? numeroAfilhos,
    double? comprimentoPaniculaCm,
    double? insercaoEspigaCm,
    double? comprimentoEspigaCm,
    int? numeroFileirasGraos,
    double? vagensPlanta,
    double? espigasPlanta,
    double? comprimentoVagensCm,
    double? graosVagem,
    double? estandePlantas,
    double? percentualFalhas,
    double? percentualSanidade,
    String? sintomasObservados,
    bool? presencaPragas,
    bool? presencaDoencas,
    String? estagioFenologico,
    String? descricaoEstagio,
    List<String>? fotos,
    String? observacoes,
    double? latitude,
    double? longitude,
    String? responsavel,
  }) {
    final now = DateTime.now();
    return PhenologicalRecordModel(
      id: '${talhaoId}_${culturaId}_${now.millisecondsSinceEpoch}',
      talhaoId: talhaoId,
      culturaId: culturaId,
      dataRegistro: dataRegistro,
      diasAposEmergencia: diasAposEmergencia,
      alturaCm: alturaCm,
      numeroFolhas: numeroFolhas,
      numeroFolhasTrifolioladas: numeroFolhasTrifolioladas,
      diametroColmoMm: diametroColmoMm,
      numeroNos: numeroNos,
      espacamentoEntreNosCm: espacamentoEntreNosCm,
      numeroRamosVegetativos: numeroRamosVegetativos,
      numeroRamosReprodutivos: numeroRamosReprodutivos,
      alturaPrimeiroRamoFrutiferoCm: alturaPrimeiroRamoFrutiferoCm,
      numeroBotoesFlorais: numeroBotoesFlorais,
      numeroMacasCapulhos: numeroMacasCapulhos,
      numeroAfilhos: numeroAfilhos,
      comprimentoPaniculaCm: comprimentoPaniculaCm,
      insercaoEspigaCm: insercaoEspigaCm,
      comprimentoEspigaCm: comprimentoEspigaCm,
      numeroFileirasGraos: numeroFileirasGraos,
      vagensPlanta: vagensPlanta,
      espigasPlanta: espigasPlanta,
      comprimentoVagensCm: comprimentoVagensCm,
      graosVagem: graosVagem,
      estandePlantas: estandePlantas,
      percentualFalhas: percentualFalhas,
      percentualSanidade: percentualSanidade,
      sintomasObservados: sintomasObservados,
      presencaPragas: presencaPragas,
      presencaDoencas: presencaDoencas,
      estagioFenologico: estagioFenologico,
      descricaoEstagio: descricaoEstagio,
      fotos: fotos ?? [],
      observacoes: observacoes,
      latitude: latitude,
      longitude: longitude,
      responsavel: responsavel,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Converter para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId, // ✅ CORRIGIDO: snake_case
      'cultura_id': culturaId, // ✅ CORRIGIDO: snake_case
      'data_registro': dataRegistro.toIso8601String(), // ✅ CORRIGIDO: snake_case
      'dias_apos_emergencia': diasAposEmergencia, // ✅ CORRIGIDO: snake_case
      'altura_cm': alturaCm, // ✅ CORRIGIDO: snake_case
      'numero_folhas': numeroFolhas, // ✅ CORRIGIDO: snake_case
      'numero_folhas_trifolioladas': numeroFolhasTrifolioladas, // ✅ CORRIGIDO: snake_case
      'diametro_colmo_mm': diametroColmoMm, // ✅ CORRIGIDO: snake_case
      'numero_nos': numeroNos, // ✅ CORRIGIDO: snake_case
      'espacamento_entre_nos_cm': espacamentoEntreNosCm, // ✅ CORRIGIDO: snake_case
      'numero_ramos_vegetativos': numeroRamosVegetativos, // ✅ CORRIGIDO: snake_case
      'numero_ramos_reprodutivos': numeroRamosReprodutivos, // ✅ CORRIGIDO: snake_case
      'altura_primeiro_ramo_frutifero_cm': alturaPrimeiroRamoFrutiferoCm, // ✅ CORRIGIDO: snake_case
      'numero_botoes_florais': numeroBotoesFlorais, // ✅ CORRIGIDO: snake_case
      'numero_macas_capulhos': numeroMacasCapulhos, // ✅ CORRIGIDO: snake_case
      'numero_afilhos': numeroAfilhos, // ✅ CORRIGIDO: snake_case
      'comprimento_panicula_cm': comprimentoPaniculaCm, // ✅ CORRIGIDO: snake_case
      'insercao_espiga_cm': insercaoEspigaCm, // ✅ CORRIGIDO: snake_case
      'comprimento_espiga_cm': comprimentoEspigaCm, // ✅ CORRIGIDO: snake_case
      'numero_fileiras_graos': numeroFileirasGraos, // ✅ CORRIGIDO: snake_case
      'vagens_planta': vagensPlanta, // ✅ CORRIGIDO: snake_case
      'espigas_planta': espigasPlanta, // ✅ CORRIGIDO: snake_case
      'comprimento_vagens_cm': comprimentoVagensCm, // ✅ CORRIGIDO: snake_case
      'graos_vagem': graosVagem, // ✅ CORRIGIDO: snake_case
      'estande_plantas': estandePlantas, // ✅ CORRIGIDO: snake_case
      'percentual_falhas': percentualFalhas, // ✅ CORRIGIDO: snake_case
      'percentual_sanidade': percentualSanidade, // ✅ CORRIGIDO: snake_case
      'sintomas_observados': sintomasObservados, // ✅ CORRIGIDO: snake_case
      'presenca_pragas': presencaPragas == true ? 1 : 0, // ✅ CORRIGIDO: snake_case
      'presenca_doencas': presencaDoencas == true ? 1 : 0, // ✅ CORRIGIDO: snake_case
      'estagio_fenologico': estagioFenologico, // ✅ CORRIGIDO: snake_case
      'descricao_estagio': descricaoEstagio, // ✅ CORRIGIDO: snake_case
      'fotos': fotos.join('|'), // Separar por pipe
      'observacoes': observacoes,
      'latitude': latitude,
      'longitude': longitude,
      'responsavel': responsavel,
      'created_at': createdAt.toIso8601String(), // ✅ CORRIGIDO: snake_case
      'updated_at': updatedAt.toIso8601String(), // ✅ CORRIGIDO: snake_case
    };
  }

  /// Criar a partir de Map (do banco de dados)
  factory PhenologicalRecordModel.fromMap(Map<String, dynamic> map) {
    return PhenologicalRecordModel(
      id: map['id'] as String,
      talhaoId: map['talhao_id'] as String, // ✅ CORRIGIDO: snake_case
      culturaId: map['cultura_id'] as String, // ✅ CORRIGIDO: snake_case
      dataRegistro: DateTime.parse(map['data_registro'] as String), // ✅ CORRIGIDO
      diasAposEmergencia: map['dias_apos_emergencia'] as int, // ✅ CORRIGIDO
      alturaCm: (map['altura_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      numeroFolhas: map['numero_folhas'] as int?, // ✅ CORRIGIDO
      numeroFolhasTrifolioladas: map['numero_folhas_trifolioladas'] as int?, // ✅ CORRIGIDO
      diametroColmoMm: (map['diametro_colmo_mm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      numeroNos: map['numero_nos'] as int?, // ✅ CORRIGIDO
      espacamentoEntreNosCm: (map['espacamento_entre_nos_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      numeroRamosVegetativos: map['numero_ramos_vegetativos'] as int?, // ✅ CORRIGIDO
      numeroRamosReprodutivos: map['numero_ramos_reprodutivos'] as int?, // ✅ CORRIGIDO
      alturaPrimeiroRamoFrutiferoCm: (map['altura_primeiro_ramo_frutifero_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      numeroBotoesFlorais: map['numero_botoes_florais'] as int?, // ✅ CORRIGIDO
      numeroMacasCapulhos: map['numero_macas_capulhos'] as int?, // ✅ CORRIGIDO
      numeroAfilhos: map['numero_afilhos'] as int?, // ✅ CORRIGIDO
      comprimentoPaniculaCm: (map['comprimento_panicula_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      insercaoEspigaCm: (map['insercao_espiga_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      comprimentoEspigaCm: (map['comprimento_espiga_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      numeroFileirasGraos: map['numero_fileiras_graos'] as int?, // ✅ CORRIGIDO
      vagensPlanta: (map['vagens_planta'] as num?)?.toDouble(), // ✅ CORRIGIDO
      espigasPlanta: (map['espigas_planta'] as num?)?.toDouble(), // ✅ CORRIGIDO
      comprimentoVagensCm: (map['comprimento_vagens_cm'] as num?)?.toDouble(), // ✅ CORRIGIDO
      graosVagem: (map['graos_vagem'] as num?)?.toDouble(), // ✅ CORRIGIDO
      estandePlantas: (map['estande_plantas'] as num?)?.toDouble(), // ✅ CORRIGIDO
      percentualFalhas: (map['percentual_falhas'] as num?)?.toDouble(), // ✅ CORRIGIDO
      percentualSanidade: (map['percentual_sanidade'] as num?)?.toDouble(), // ✅ CORRIGIDO
      sintomasObservados: map['sintomas_observados'] as String?, // ✅ CORRIGIDO
      presencaPragas: map['presenca_pragas'] == 1, // ✅ CORRIGIDO
      presencaDoencas: map['presenca_doencas'] == 1, // ✅ CORRIGIDO
      estagioFenologico: map['estagio_fenologico'] as String?, // ✅ CORRIGIDO
      descricaoEstagio: map['descricao_estagio'] as String?, // ✅ CORRIGIDO
      fotos: (map['fotos'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? [],
      observacoes: map['observacoes'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      responsavel: map['responsavel'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String), // ✅ CORRIGIDO
      updatedAt: DateTime.parse(map['updated_at'] as String), // ✅ CORRIGIDO
    );
  }

  /// Copiar com modificações
  PhenologicalRecordModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    DateTime? dataRegistro,
    int? diasAposEmergencia,
    double? alturaCm,
    int? numeroFolhas,
    int? numeroFolhasTrifolioladas,
    double? diametroColmoMm,
    int? numeroNos,
    double? espacamentoEntreNosCm,
    int? numeroRamosVegetativos,
    int? numeroRamosReprodutivos,
    double? alturaPrimeiroRamoFrutiferoCm,
    int? numeroBotoesFlorais,
    int? numeroMacasCapulhos,
    int? numeroAfilhos,
    double? comprimentoPaniculaCm,
    double? insercaoEspigaCm,
    double? comprimentoEspigaCm,
    int? numeroFileirasGraos,
    double? vagensPlanta,
    double? espigasPlanta,
    double? comprimentoVagensCm,
    double? graosVagem,
    double? estandePlantas,
    double? percentualFalhas,
    double? percentualSanidade,
    String? sintomasObservados,
    bool? presencaPragas,
    bool? presencaDoencas,
    String? estagioFenologico,
    String? descricaoEstagio,
    List<String>? fotos,
    String? observacoes,
    double? latitude,
    double? longitude,
    String? responsavel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhenologicalRecordModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      diasAposEmergencia: diasAposEmergencia ?? this.diasAposEmergencia,
      alturaCm: alturaCm ?? this.alturaCm,
      numeroFolhas: numeroFolhas ?? this.numeroFolhas,
      numeroFolhasTrifolioladas: numeroFolhasTrifolioladas ?? this.numeroFolhasTrifolioladas,
      diametroColmoMm: diametroColmoMm ?? this.diametroColmoMm,
      numeroNos: numeroNos ?? this.numeroNos,
      espacamentoEntreNosCm: espacamentoEntreNosCm ?? this.espacamentoEntreNosCm,
      numeroRamosVegetativos: numeroRamosVegetativos ?? this.numeroRamosVegetativos,
      numeroRamosReprodutivos: numeroRamosReprodutivos ?? this.numeroRamosReprodutivos,
      alturaPrimeiroRamoFrutiferoCm: alturaPrimeiroRamoFrutiferoCm ?? this.alturaPrimeiroRamoFrutiferoCm,
      numeroBotoesFlorais: numeroBotoesFlorais ?? this.numeroBotoesFlorais,
      numeroMacasCapulhos: numeroMacasCapulhos ?? this.numeroMacasCapulhos,
      numeroAfilhos: numeroAfilhos ?? this.numeroAfilhos,
      comprimentoPaniculaCm: comprimentoPaniculaCm ?? this.comprimentoPaniculaCm,
      insercaoEspigaCm: insercaoEspigaCm ?? this.insercaoEspigaCm,
      comprimentoEspigaCm: comprimentoEspigaCm ?? this.comprimentoEspigaCm,
      numeroFileirasGraos: numeroFileirasGraos ?? this.numeroFileirasGraos,
      vagensPlanta: vagensPlanta ?? this.vagensPlanta,
      espigasPlanta: espigasPlanta ?? this.espigasPlanta,
      comprimentoVagensCm: comprimentoVagensCm ?? this.comprimentoVagensCm,
      graosVagem: graosVagem ?? this.graosVagem,
      estandePlantas: estandePlantas ?? this.estandePlantas,
      percentualFalhas: percentualFalhas ?? this.percentualFalhas,
      percentualSanidade: percentualSanidade ?? this.percentualSanidade,
      sintomasObservados: sintomasObservados ?? this.sintomasObservados,
      presencaPragas: presencaPragas ?? this.presencaPragas,
      presencaDoencas: presencaDoencas ?? this.presencaDoencas,
      estagioFenologico: estagioFenologico ?? this.estagioFenologico,
      descricaoEstagio: descricaoEstagio ?? this.descricaoEstagio,
      fotos: fotos ?? this.fotos,
      observacoes: observacoes ?? this.observacoes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      responsavel: responsavel ?? this.responsavel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PhenologicalRecordModel(id: $id, talhaoId: $talhaoId, culturaId: $culturaId, '
           'dataRegistro: $dataRegistro, diasAposEmergencia: $diasAposEmergencia, '
           'estagioFenologico: $estagioFenologico)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhenologicalRecordModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

