import 'dart:convert';

/// Modelo para amostras laboratoriais de solo
class SoilLaboratorySampleModel {
  final int? id;
  final int pointId; // Relacionado ao ponto de coleta
  final String codigoAmostra;
  final DateTime dataColeta;
  final DateTime? dataAnalise;
  final String? laboratorio;
  final String? metodologia;
  
  // Parâmetros químicos
  final double? ph;
  final double? materiaOrganica; // %
  final double? fosforo; // mg/dm³
  final double? potassio; // mg/dm³
  final double? calcio; // cmolc/dm³
  final double? magnesio; // cmolc/dm³
  final double? ctc; // cmolc/dm³
  final double? v; // % (saturação por bases)
  final double? m; // % (saturação por alumínio)
  final double? aluminio; // cmolc/dm³
  final double? hidrogenio; // cmolc/dm³
  
  // Parâmetros físicos
  final double? argila; // %
  final double? silte; // %
  final double? areia; // %
  final double? densidade; // g/cm³
  final double? porosidade; // %
  
  // Micronutrientes
  final double? zinco; // mg/dm³
  final double? ferro; // mg/dm³
  final double? manganes; // mg/dm³
  final double? cobre; // mg/dm³
  final double? boro; // mg/dm³
  
  // Dados do arquivo
  final String? arquivoOriginal; // Nome do arquivo CSV/PDF
  final String? dadosBrutos; // Dados originais em JSON
  final String? observacoes;
  
  // Análises cruzadas geradas automaticamente
  final List<String>? diagnosticosCruzados;
  final List<String>? recomendacoesNutricionais;
  final String? classificacaoFertilidade;

  SoilLaboratorySampleModel({
    this.id,
    required this.pointId,
    required this.codigoAmostra,
    required this.dataColeta,
    this.dataAnalise,
    this.laboratorio,
    this.metodologia,
    this.ph,
    this.materiaOrganica,
    this.fosforo,
    this.potassio,
    this.calcio,
    this.magnesio,
    this.ctc,
    this.v,
    this.m,
    this.aluminio,
    this.hidrogenio,
    this.argila,
    this.silte,
    this.areia,
    this.densidade,
    this.porosidade,
    this.zinco,
    this.ferro,
    this.manganes,
    this.cobre,
    this.boro,
    this.arquivoOriginal,
    this.dadosBrutos,
    this.observacoes,
    this.diagnosticosCruzados,
    this.recomendacoesNutricionais,
    this.classificacaoFertilidade,
  });

  /// Calcula a classificação de fertilidade do solo
  String calcularClassificacaoFertilidade() {
    if (ph == null || materiaOrganica == null || ctc == null) {
      return 'Dados Insuficientes';
    }

    // Classificação baseada em pH, MO e CTC
    if (ph! >= 6.0 && materiaOrganica! >= 3.0 && ctc! >= 7.0) {
      return 'Alta Fertilidade';
    } else if (ph! >= 5.5 && materiaOrganica! >= 2.0 && ctc! >= 5.0) {
      return 'Média Fertilidade';
    } else if (ph! >= 5.0 && materiaOrganica! >= 1.0 && ctc! >= 3.0) {
      return 'Baixa Fertilidade';
    } else {
      return 'Muito Baixa Fertilidade';
    }
  }

  /// Calcula saturação por bases (V%)
  double? calcularSaturacaoBases() {
    if (calcio == null || magnesio == null || potassio == null || ctc == null) {
      return null;
    }
    
    final somaBases = (calcio! + magnesio! + (potassio! / 10)); // K convertido
    return (somaBases / ctc!) * 100;
  }

  /// Calcula saturação por alumínio (m%)
  double? calcularSaturacaoAluminio() {
    if (aluminio == null || ctc == null) {
      return null;
    }
    
    return (aluminio! / ctc!) * 100;
  }

  /// Verifica se há deficiência de nutrientes
  Map<String, bool> verificarDeficiencias() {
    return {
      'fosforo_baixo': fosforo != null && fosforo! < 10.0,
      'potassio_baixo': potassio != null && potassio! < 80.0,
      'calcio_baixo': calcio != null && calcio! < 2.0,
      'magnesio_baixo': magnesio != null && magnesio! < 0.5,
      'ph_baixo': ph != null && ph! < 5.5,
      'ph_alto': ph != null && ph! > 7.0,
      'mo_baixa': materiaOrganica != null && materiaOrganica! < 2.0,
      'ctc_baixa': ctc != null && ctc! < 5.0,
      'aluminio_alto': aluminio != null && aluminio! > 1.0,
    };
  }

  SoilLaboratorySampleModel copyWith({
    int? id,
    int? pointId,
    String? codigoAmostra,
    DateTime? dataColeta,
    DateTime? dataAnalise,
    String? laboratorio,
    String? metodologia,
    double? ph,
    double? materiaOrganica,
    double? fosforo,
    double? potassio,
    double? calcio,
    double? magnesio,
    double? ctc,
    double? v,
    double? m,
    double? aluminio,
    double? hidrogenio,
    double? argila,
    double? silte,
    double? areia,
    double? densidade,
    double? porosidade,
    double? zinco,
    double? ferro,
    double? manganes,
    double? cobre,
    double? boro,
    String? arquivoOriginal,
    String? dadosBrutos,
    String? observacoes,
    List<String>? diagnosticosCruzados,
    List<String>? recomendacoesNutricionais,
    String? classificacaoFertilidade,
  }) {
    return SoilLaboratorySampleModel(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      codigoAmostra: codigoAmostra ?? this.codigoAmostra,
      dataColeta: dataColeta ?? this.dataColeta,
      dataAnalise: dataAnalise ?? this.dataAnalise,
      laboratorio: laboratorio ?? this.laboratorio,
      metodologia: metodologia ?? this.metodologia,
      ph: ph ?? this.ph,
      materiaOrganica: materiaOrganica ?? this.materiaOrganica,
      fosforo: fosforo ?? this.fosforo,
      potassio: potassio ?? this.potassio,
      calcio: calcio ?? this.calcio,
      magnesio: magnesio ?? this.magnesio,
      ctc: ctc ?? this.ctc,
      v: v ?? this.v,
      m: m ?? this.m,
      aluminio: aluminio ?? this.aluminio,
      hidrogenio: hidrogenio ?? this.hidrogenio,
      argila: argila ?? this.argila,
      silte: silte ?? this.silte,
      areia: areia ?? this.areia,
      densidade: densidade ?? this.densidade,
      porosidade: porosidade ?? this.porosidade,
      zinco: zinco ?? this.zinco,
      ferro: ferro ?? this.ferro,
      manganes: manganes ?? this.manganes,
      cobre: cobre ?? this.cobre,
      boro: boro ?? this.boro,
      arquivoOriginal: arquivoOriginal ?? this.arquivoOriginal,
      dadosBrutos: dadosBrutos ?? this.dadosBrutos,
      observacoes: observacoes ?? this.observacoes,
      diagnosticosCruzados: diagnosticosCruzados ?? this.diagnosticosCruzados,
      recomendacoesNutricionais: recomendacoesNutricionais ?? this.recomendacoesNutricionais,
      classificacaoFertilidade: classificacaoFertilidade ?? this.classificacaoFertilidade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'point_id': pointId,
      'codigo_amostra': codigoAmostra,
      'data_coleta': dataColeta.toIso8601String(),
      'data_analise': dataAnalise?.toIso8601String(),
      'laboratorio': laboratorio,
      'metodologia': metodologia,
      'ph': ph,
      'materia_organica': materiaOrganica,
      'fosforo': fosforo,
      'potassio': potassio,
      'calcio': calcio,
      'magnesio': magnesio,
      'ctc': ctc,
      'v': v,
      'm': m,
      'aluminio': aluminio,
      'hidrogenio': hidrogenio,
      'argila': argila,
      'silte': silte,
      'areia': areia,
      'densidade': densidade,
      'porosidade': porosidade,
      'zinco': zinco,
      'ferro': ferro,
      'manganes': manganes,
      'cobre': cobre,
      'boro': boro,
      'arquivo_original': arquivoOriginal,
      'dados_brutos': dadosBrutos,
      'observacoes': observacoes,
      'diagnosticos_cruzados': diagnosticosCruzados != null ? jsonEncode(diagnosticosCruzados) : null,
      'recomendacoes_nutricionais': recomendacoesNutricionais != null ? jsonEncode(recomendacoesNutricionais) : null,
      'classificacao_fertilidade': classificacaoFertilidade ?? calcularClassificacaoFertilidade(),
    };
  }

  factory SoilLaboratorySampleModel.fromMap(Map<String, dynamic> map) {
    return SoilLaboratorySampleModel(
      id: map['id'],
      pointId: map['point_id'],
      codigoAmostra: map['codigo_amostra'],
      dataColeta: DateTime.parse(map['data_coleta']),
      dataAnalise: map['data_analise'] != null ? DateTime.parse(map['data_analise']) : null,
      laboratorio: map['laboratorio'],
      metodologia: map['metodologia'],
      ph: map['ph'],
      materiaOrganica: map['materia_organica'],
      fosforo: map['fosforo'],
      potassio: map['potassio'],
      calcio: map['calcio'],
      magnesio: map['magnesio'],
      ctc: map['ctc'],
      v: map['v'],
      m: map['m'],
      aluminio: map['aluminio'],
      hidrogenio: map['hidrogenio'],
      argila: map['argila'],
      silte: map['silte'],
      areia: map['areia'],
      densidade: map['densidade'],
      porosidade: map['porosidade'],
      zinco: map['zinco'],
      ferro: map['ferro'],
      manganes: map['manganes'],
      cobre: map['cobre'],
      boro: map['boro'],
      arquivoOriginal: map['arquivo_original'],
      dadosBrutos: map['dados_brutos'],
      observacoes: map['observacoes'],
      diagnosticosCruzados: map['diagnosticos_cruzados'] != null 
          ? List<String>.from(jsonDecode(map['diagnosticos_cruzados']))
          : null,
      recomendacoesNutricionais: map['recomendacoes_nutricionais'] != null 
          ? List<String>.from(jsonDecode(map['recomendacoes_nutricionais']))
          : null,
      classificacaoFertilidade: map['classificacao_fertilidade'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SoilLaboratorySampleModel.fromJson(String source) =>
      SoilLaboratorySampleModel.fromMap(jsonDecode(source));

  @override
  String toString() {
    return 'SoilLaboratorySampleModel(id: $id, codigoAmostra: $codigoAmostra, ph: $ph, classificacao: $classificacaoFertilidade)';
  }
}
