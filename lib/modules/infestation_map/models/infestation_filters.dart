/// Modelo para representar filtros de infestação
class InfestationFilters {
  final String? talhaoId;
  final String? culturaId;
  final String? organismoId;
  final List<String>? organismTypes; // NOVO: Filtro por tipo de organismo (pest, disease, weed)
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<String>? niveis;
  final bool apenasAlertas;
  final bool apenasNaoReconhecidos;
  final String? searchQuery;

  const InfestationFilters({
    this.talhaoId,
    this.culturaId,
    this.organismoId,
    this.organismTypes,
    this.dataInicio,
    this.dataFim,
    this.niveis,
    this.apenasAlertas = false,
    this.apenasNaoReconhecidos = false,
    this.searchQuery,
  });

  /// Cria uma cópia com campos atualizados
  InfestationFilters copyWith({
    String? talhaoId,
    String? culturaId,
    String? organismoId,
    List<String>? organismTypes,
    DateTime? dataInicio,
    DateTime? dataFim,
    List<String>? niveis,
    bool? apenasAlertas,
    bool? apenasNaoReconhecidos,
    String? searchQuery,
  }) {
    return InfestationFilters(
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      organismoId: organismoId ?? this.organismoId,
      organismTypes: organismTypes ?? this.organismTypes,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      niveis: niveis ?? this.niveis,
      apenasAlertas: apenasAlertas ?? this.apenasAlertas,
      apenasNaoReconhecidos: apenasNaoReconhecidos ?? this.apenasNaoReconhecidos,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Cria filtros padrão (últimos 30 dias)
  factory InfestationFilters.defaultFilters() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    return InfestationFilters(
      dataInicio: thirtyDaysAgo,
      dataFim: now,
      niveis: ['ALTO', 'CRITICO'],
      apenasAlertas: true,
    );
  }

  /// Cria filtros para período específico
  factory InfestationFilters.forPeriod(DateTime inicio, DateTime fim) {
    return InfestationFilters(
      dataInicio: inicio,
      dataFim: fim,
    );
  }

  /// Cria filtros para talhão específico
  factory InfestationFilters.forTalhao(String talhaoId) {
    return InfestationFilters(
      talhaoId: talhaoId,
    );
  }

  /// Verifica se há filtros ativos
  bool get hasActiveFilters {
    return talhaoId != null ||
           culturaId != null ||
           organismoId != null ||
           (organismTypes != null && organismTypes!.isNotEmpty) ||
           dataInicio != null ||
           dataFim != null ||
           (niveis != null && niveis!.isNotEmpty) ||
           apenasAlertas ||
           apenasNaoReconhecidos ||
           (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Limpa todos os filtros
  InfestationFilters clear() {
    return const InfestationFilters();
  }

  /// Converte para Map (para persistência)
  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'culturaId': culturaId,
      'organismoId': organismoId,
      'organismTypes': organismTypes,
      'dataInicio': dataInicio?.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
      'niveis': niveis,
      'apenasAlertas': apenasAlertas,
      'apenasNaoReconhecidos': apenasNaoReconhecidos,
      'searchQuery': searchQuery,
    };
  }

  /// Cria a partir de Map (para restauração)
  factory InfestationFilters.fromMap(Map<String, dynamic> map) {
    return InfestationFilters(
      talhaoId: map['talhaoId'] as String?,
      culturaId: map['culturaId'] as String?,
      organismoId: map['organismoId'] as String?,
      organismTypes: map['organismTypes'] != null 
          ? List<String>.from(map['organismTypes'] as List) 
          : null,
      dataInicio: map['dataInicio'] != null 
          ? DateTime.parse(map['dataInicio'] as String) 
          : null,
      dataFim: map['dataFim'] != null 
          ? DateTime.parse(map['dataFim'] as String) 
          : null,
      niveis: map['niveis'] != null 
          ? List<String>.from(map['niveis'] as List) 
          : null,
      apenasAlertas: map['apenasAlertas'] as bool? ?? false,
      apenasNaoReconhecidos: map['apenasNaoReconhecidos'] as bool? ?? false,
      searchQuery: map['searchQuery'] as String?,
    );
  }

  @override
  String toString() {
    return 'InfestationFilters('
           'talhaoId: $talhaoId, '
           'culturaId: $culturaId, '
           'organismoId: $organismoId, '
           'organismTypes: $organismTypes, '
           'dataInicio: $dataInicio, '
           'dataFim: $dataFim, '
           'niveis: $niveis, '
           'apenasAlertas: $apenasAlertas, '
           'apenasNaoReconhecidos: $apenasNaoReconhecidos, '
           'searchQuery: $searchQuery)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfestationFilters &&
           other.talhaoId == talhaoId &&
           other.culturaId == culturaId &&
           other.organismoId == organismoId &&
           other.organismTypes == organismTypes &&
           other.dataInicio == dataInicio &&
           other.dataFim == dataFim &&
           other.niveis == niveis &&
           other.apenasAlertas == apenasAlertas &&
           other.apenasNaoReconhecidos == apenasNaoReconhecidos &&
           other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return Object.hash(
      talhaoId,
      culturaId,
      organismoId,
      organismTypes,
      dataInicio,
      dataFim,
      niveis,
      apenasAlertas,
      apenasNaoReconhecidos,
      searchQuery,
    );
  }
}
