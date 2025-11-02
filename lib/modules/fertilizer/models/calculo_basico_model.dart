/// Enum para tipo de coleta
enum TipoColeta { tempo, distancia }

/// Modelo para cálculo básico de calibração de fertilizantes
class CalculoBasicoModel {
  final String? id;
  final String nome;
  final DateTime dataCalibragem;
  final String equipamento;
  final String operador;
  final String fertilizante;
  final double velocidadeTrator; // km/h
  final double larguraTrabalho; // m (largura da faixa de trabalho)
  final double aberturaComporta; // mm (para reutilização, não entra no cálculo)
  final TipoColeta tipoColeta; // tempo ou distância
  final double? tempoColetado; // segundos (se tipoColeta == tempo)
  final double? distanciaPercorrida; // m (se tipoColeta == distancia)
  final double volumeColetado; // L ou kg
  final String unidadeVolume; // 'L' ou 'kg'
  final double? metaAplicacao; // kg/ha ou L/ha (opcional)
  final double? densidade; // kg/L (opcional, para conversão L→kg)
  
  // Campos calculados automaticamente
  final double? areaPercorrida; // m²
  final double? areaHectares; // ha
  final double? taxaAplicadaL; // L/ha
  final double? taxaAplicadaKg; // kg/ha
  final double? sacasHa; // sacas de 50kg/ha
  final double? diferencaMeta; // kg/ha ou L/ha
  final double? erroPorcentagem; // %
  final String? statusCalibragem; // "Dentro da meta", "Abaixo da meta", "Acima da meta"
  final String? sugestaoAjuste;
  final String? observacoes;

  CalculoBasicoModel({
    this.id,
    required this.nome,
    required this.dataCalibragem,
    required this.equipamento,
    required this.operador,
    required this.fertilizante,
    required this.velocidadeTrator,
    required this.larguraTrabalho,
    required this.aberturaComporta,
    required this.tipoColeta,
    this.tempoColetado,
    this.distanciaPercorrida,
    required this.volumeColetado,
    required this.unidadeVolume,
    this.metaAplicacao,
    this.densidade,
    this.areaPercorrida,
    this.areaHectares,
    this.taxaAplicadaL,
    this.taxaAplicadaKg,
    this.sacasHa,
    this.diferencaMeta,
    this.erroPorcentagem,
    this.statusCalibragem,
    this.sugestaoAjuste,
    this.observacoes,
  });

  /// Construtor factory para criar uma instância com cálculos automáticos
  factory CalculoBasicoModel.comCalculos({
    String? id,
    required String nome,
    required DateTime dataCalibragem,
    required String equipamento,
    required String operador,
    required String fertilizante,
    required double velocidadeTrator,
    required double larguraTrabalho,
    required double aberturaComporta,
    required TipoColeta tipoColeta,
    double? tempoColetado,
    double? distanciaPercorrida,
    required double volumeColetado,
    required String unidadeVolume,
    double? metaAplicacao,
    double? densidade,
    String? observacoes,
  }) {
    // Calcular distância baseada no tipo de coleta
    final distanciaCalculada = _calcularDistancia(
      velocidadeTrator, 
      tipoColeta, 
      tempoColetado, 
      distanciaPercorrida
    );
    
    // Cálculos automáticos
    final areaPercorrida = _calcularAreaPercorrida(distanciaCalculada, larguraTrabalho);
    final areaHectares = _calcularAreaHectares(areaPercorrida);
    final taxaAplicadaL = _calcularTaxaAplicadaL(volumeColetado, areaPercorrida, unidadeVolume);
    final taxaAplicadaKg = _calcularTaxaAplicadaKg(taxaAplicadaL, densidade, unidadeVolume, volumeColetado, areaPercorrida);
    final sacasHa = _calcularSacasHa(taxaAplicadaKg);
    
    double? diferencaMeta;
    double? erroPorcentagem;
    String? statusCalibragem;
    String? sugestaoAjuste;
    
    if (metaAplicacao != null && metaAplicacao > 0) {
      // Usar a taxa apropriada baseada na unidade da meta
      final taxaParaComparacao = unidadeVolume == 'L' ? taxaAplicadaL : taxaAplicadaKg;
      diferencaMeta = taxaParaComparacao - metaAplicacao;
      erroPorcentagem = _calcularErroPorcentagem(taxaParaComparacao, metaAplicacao);
      statusCalibragem = _determinarStatusCalibragem(erroPorcentagem);
      sugestaoAjuste = _gerarSugestaoAjuste(erroPorcentagem);
    }

    return CalculoBasicoModel(
      id: id,
      nome: nome,
      dataCalibragem: dataCalibragem,
      equipamento: equipamento,
      operador: operador,
      fertilizante: fertilizante,
      velocidadeTrator: velocidadeTrator,
      larguraTrabalho: larguraTrabalho,
      aberturaComporta: aberturaComporta,
      tipoColeta: tipoColeta,
      tempoColetado: tempoColetado,
      distanciaPercorrida: distanciaPercorrida,
      volumeColetado: volumeColetado,
      unidadeVolume: unidadeVolume,
      metaAplicacao: metaAplicacao,
      densidade: densidade,
      areaPercorrida: areaPercorrida,
      areaHectares: areaHectares,
      taxaAplicadaL: taxaAplicadaL,
      taxaAplicadaKg: taxaAplicadaKg,
      sacasHa: sacasHa,
      diferencaMeta: diferencaMeta,
      erroPorcentagem: erroPorcentagem,
      statusCalibragem: statusCalibragem,
      sugestaoAjuste: sugestaoAjuste,
      observacoes: observacoes,
    );
  }

  /// Calcula a distância baseada no tipo de coleta
  static double _calcularDistancia(
    double velocidade, 
    TipoColeta tipoColeta, 
    double? tempo, 
    double? distancia
  ) {
    if (tipoColeta == TipoColeta.distancia && distancia != null) {
      return distancia;
    } else if (tipoColeta == TipoColeta.tempo && tempo != null) {
      // Converte velocidade de km/h para m/s e multiplica pelo tempo
      return (velocidade * 1000) / 3600 * tempo;
    }
    return 0.0;
  }

  /// Calcula a área percorrida em m²
  /// Fórmula: Área = Distância × Largura de Trabalho
  static double _calcularAreaPercorrida(double distancia, double larguraTrabalho) {
    return distancia * larguraTrabalho;
  }

  /// Calcula a área em hectares
  static double _calcularAreaHectares(double areaM2) {
    return areaM2 / 10000;
  }

  /// Calcula a taxa de aplicação em L/ha
  static double _calcularTaxaAplicadaL(double volumeColetado, double area, String unidade) {
    if (area <= 0) return 0.0;
    
    if (unidade == 'L') {
      return (volumeColetado * 10000) / area;
    } else {
      // Se foi coletado em kg, não podemos calcular L/ha sem densidade
      return 0.0;
    }
  }

  /// Calcula a taxa de aplicação em kg/ha
  static double _calcularTaxaAplicadaKg(
    double taxaAplicadaL, 
    double? densidade, 
    String unidade, 
    double volumeColetado, 
    double area
  ) {
    if (area <= 0) return 0.0;
    
    if (unidade == 'kg') {
      // Se foi coletado em kg, calcular diretamente
      return (volumeColetado * 10000) / area;
    } else if (unidade == 'L' && densidade != null) {
      // Se foi coletado em L e temos densidade, converter
      return taxaAplicadaL * densidade;
    }
    
    return 0.0;
  }

  /// Calcula sacas por hectare (considerando sacas de 50kg)
  static double _calcularSacasHa(double taxaKgHa) {
    return taxaKgHa / 50;
  }

  /// Calcula o erro percentual em relação à meta
  /// Fórmula: Erro% = ((Taxa - Meta) / Meta) × 100
  static double _calcularErroPorcentagem(double taxa, double meta) {
    if (meta <= 0) return 0.0;
    return ((taxa - meta) / meta) * 100;
  }

  /// Determina o status da calibração baseado no erro percentual
  static String _determinarStatusCalibragem(double? erroPorcentagem) {
    if (erroPorcentagem == null) return "Sem meta definida";
    
    if (erroPorcentagem.abs() <= 5) {
      return "Dentro da meta";
    } else if (erroPorcentagem > 5) {
      return "Acima da meta";
    } else {
      return "Abaixo da meta";
    }
  }

  /// Gera sugestão de ajuste baseada no erro percentual
  static String _gerarSugestaoAjuste(double? erroPorcentagem) {
    if (erroPorcentagem == null) return "Defina uma meta para obter sugestões de ajuste";
    
    if (erroPorcentagem.abs() <= 5) {
      return "✅ Calibração dentro da margem aceitável (±5%)";
    } else if (erroPorcentagem > 5) {
      return "⚠️ Reduza a regulagem da adubadeira (${erroPorcentagem.toStringAsFixed(1)}% acima da meta)";
    } else {
      return "❌ Aumente a regulagem da adubadeira (${erroPorcentagem.abs().toStringAsFixed(1)}% abaixo da meta)";
    }
  }

  /// Converte para mapa (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_calibragem': dataCalibragem.toIso8601String(),
      'equipamento': equipamento,
      'operador': operador,
      'fertilizante': fertilizante,
      'velocidade_trator': velocidadeTrator,
      'largura_trabalho': larguraTrabalho,
      'abertura_comporta': aberturaComporta,
      'tipo_coleta': tipoColeta.name,
      'tempo_coletado': tempoColetado,
      'distancia_percorrida': distanciaPercorrida,
      'volume_coletado': volumeColetado,
      'unidade_volume': unidadeVolume,
      'meta_aplicacao': metaAplicacao,
      'densidade': densidade,
      'area_percorrida': areaPercorrida,
      'area_hectares': areaHectares,
      'taxa_aplicada_l': taxaAplicadaL,
      'taxa_aplicada_kg': taxaAplicadaKg,
      'sacas_ha': sacasHa,
      'diferenca_meta': diferencaMeta,
      'erro_porcentagem': erroPorcentagem,
      'status_calibragem': statusCalibragem,
      'sugestao_ajuste': sugestaoAjuste,
      'observacoes': observacoes,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Cria instância a partir de mapa (para ler do banco de dados)
  factory CalculoBasicoModel.fromMap(Map<String, dynamic> map) {
    return CalculoBasicoModel(
      id: map['id']?.toString(),
      nome: map['nome']?.toString() ?? '',
      dataCalibragem: DateTime.tryParse(map['data_calibragem']?.toString() ?? '') ?? DateTime.now(),
      equipamento: map['equipamento']?.toString() ?? '',
      operador: map['operador']?.toString() ?? '',
      fertilizante: map['fertilizante']?.toString() ?? '',
      velocidadeTrator: (map['velocidade_trator'] as num?)?.toDouble() ?? 0.0,
      larguraTrabalho: (map['largura_trabalho'] as num?)?.toDouble() ?? 0.0,
      aberturaComporta: (map['abertura_comporta'] as num?)?.toDouble() ?? 0.0,
      tipoColeta: TipoColeta.values.firstWhere(
        (e) => e.name == map['tipo_coleta'],
        orElse: () => TipoColeta.distancia,
      ),
      tempoColetado: (map['tempo_coletado'] as num?)?.toDouble(),
      distanciaPercorrida: (map['distancia_percorrida'] as num?)?.toDouble(),
      volumeColetado: (map['volume_coletado'] as num?)?.toDouble() ?? 0.0,
      unidadeVolume: map['unidade_volume']?.toString() ?? 'L',
      metaAplicacao: (map['meta_aplicacao'] as num?)?.toDouble(),
      densidade: (map['densidade'] as num?)?.toDouble(),
      areaPercorrida: (map['area_percorrida'] as num?)?.toDouble(),
      areaHectares: (map['area_hectares'] as num?)?.toDouble(),
      taxaAplicadaL: (map['taxa_aplicada_l'] as num?)?.toDouble(),
      taxaAplicadaKg: (map['taxa_aplicada_kg'] as num?)?.toDouble(),
      sacasHa: (map['sacas_ha'] as num?)?.toDouble(),
      diferencaMeta: (map['diferenca_meta'] as num?)?.toDouble(),
      erroPorcentagem: (map['erro_porcentagem'] as num?)?.toDouble(),
      statusCalibragem: map['status_calibragem']?.toString(),
      sugestaoAjuste: map['sugestao_ajuste']?.toString(),
      observacoes: map['observacoes']?.toString(),
    );
  }

  /// Cria uma cópia com alterações
  CalculoBasicoModel copyWith({
    String? id,
    String? nome,
    DateTime? dataCalibragem,
    String? equipamento,
    String? operador,
    String? fertilizante,
    double? velocidadeTrator,
    double? larguraTrabalho,
    double? aberturaComporta,
    TipoColeta? tipoColeta,
    double? tempoColetado,
    double? distanciaPercorrida,
    double? volumeColetado,
    String? unidadeVolume,
    double? metaAplicacao,
    double? densidade,
    double? areaPercorrida,
    double? areaHectares,
    double? taxaAplicadaL,
    double? taxaAplicadaKg,
    double? sacasHa,
    double? diferencaMeta,
    double? erroPorcentagem,
    String? statusCalibragem,
    String? sugestaoAjuste,
    String? observacoes,
  }) {
    return CalculoBasicoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataCalibragem: dataCalibragem ?? this.dataCalibragem,
      equipamento: equipamento ?? this.equipamento,
      operador: operador ?? this.operador,
      fertilizante: fertilizante ?? this.fertilizante,
      velocidadeTrator: velocidadeTrator ?? this.velocidadeTrator,
      larguraTrabalho: larguraTrabalho ?? this.larguraTrabalho,
      aberturaComporta: aberturaComporta ?? this.aberturaComporta,
      tipoColeta: tipoColeta ?? this.tipoColeta,
      tempoColetado: tempoColetado ?? this.tempoColetado,
      distanciaPercorrida: distanciaPercorrida ?? this.distanciaPercorrida,
      volumeColetado: volumeColetado ?? this.volumeColetado,
      unidadeVolume: unidadeVolume ?? this.unidadeVolume,
      metaAplicacao: metaAplicacao ?? this.metaAplicacao,
      densidade: densidade ?? this.densidade,
      areaPercorrida: areaPercorrida ?? this.areaPercorrida,
      areaHectares: areaHectares ?? this.areaHectares,
      taxaAplicadaL: taxaAplicadaL ?? this.taxaAplicadaL,
      taxaAplicadaKg: taxaAplicadaKg ?? this.taxaAplicadaKg,
      sacasHa: sacasHa ?? this.sacasHa,
      diferencaMeta: diferencaMeta ?? this.diferencaMeta,
      erroPorcentagem: erroPorcentagem ?? this.erroPorcentagem,
      statusCalibragem: statusCalibragem ?? this.statusCalibragem,
      sugestaoAjuste: sugestaoAjuste ?? this.sugestaoAjuste,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  String toString() {
    return 'CalculoBasicoModel(id: $id, nome: $nome, taxaAplicadaL: $taxaAplicadaL, taxaAplicadaKg: $taxaAplicadaKg, statusCalibragem: $statusCalibragem)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculoBasicoModel &&
        other.id == id &&
        other.nome == nome &&
        other.dataCalibragem == dataCalibragem;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nome.hashCode ^ dataCalibragem.hashCode;
  }
}
