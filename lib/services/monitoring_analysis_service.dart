/// Resultado da análise
class AnalysisResult {
  final String sessionId;
  final String talhaoId;
  final List<OrganismSummary> resumoPorOrganismo;
  final List<PointAnalysis> pontos;
  final String catalogVersion;
  final DateTime analyzedAt;

  const AnalysisResult({
    required this.sessionId,
    required this.talhaoId,
    required this.resumoPorOrganismo,
    required this.pontos,
    required this.catalogVersion,
    required this.analyzedAt,
  });
}

/// Resumo de organismo
class OrganismSummary {
  final int organismId;
  final double frequenciaPercent;
  final double intensidadeMedia;
  final double indicePercent;
  final String nivel;

  const OrganismSummary({
    required this.organismId,
    required this.frequenciaPercent,
    required this.intensidadeMedia,
    required this.indicePercent,
    required this.nivel,
  });
}

/// Análise de ponto
class PointAnalysis {
  final int pointId;
  final double latitude;
  final double longitude;
  final List<OrganismAnalysis> organismos;

  const PointAnalysis({
    required this.pointId,
    required this.latitude,
    required this.longitude,
    required this.organismos,
  });
}

/// Análise de organismo
class OrganismAnalysis {
  final int organismId;
  final double valorNorm;
  final String nivel;

  const OrganismAnalysis({
    required this.organismId,
    required this.valorNorm,
    required this.nivel,
  });
}

/// Serviço de análise de monitoramento (simplificado para compilação offline)
class MonitoringAnalysisService {
  // Métodos podem ser adicionados aqui se necessário
}