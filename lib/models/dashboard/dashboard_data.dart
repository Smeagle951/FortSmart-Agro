import 'package:uuid/uuid.dart';

/// Dados principais do dashboard
class DashboardData {
  final String id;
  final FarmProfile farmProfile;
  final List<Alert> alerts;
  final TalhoesSummary talhoesSummary;
  final PlantiosAtivos plantiosAtivos;
  final MonitoramentosSummary monitoramentosSummary;
  final EstoqueSummary estoqueSummary;
  final WeatherData weatherData;
  final IndicadoresRapidos indicadoresRapidos;
  final DateTime lastUpdated;

  const DashboardData({
    required this.id,
    required this.farmProfile,
    required this.alerts,
    required this.talhoesSummary,
    required this.plantiosAtivos,
    required this.monitoramentosSummary,
    required this.estoqueSummary,
    required this.weatherData,
    required this.indicadoresRapidos,
    required this.lastUpdated,
  });

  factory DashboardData.create() {
    return DashboardData(
      id: const Uuid().v4(),
      farmProfile: FarmProfile.empty(),
      alerts: [],
      talhoesSummary: TalhoesSummary.empty(),
      plantiosAtivos: PlantiosAtivos.empty(),
      monitoramentosSummary: MonitoramentosSummary.empty(),
      estoqueSummary: EstoqueSummary.empty(),
      weatherData: WeatherData.empty(),
      indicadoresRapidos: IndicadoresRapidos.empty(),
      lastUpdated: DateTime.now(),
    );
  }

  DashboardData copyWith({
    String? id,
    FarmProfile? farmProfile,
    List<Alert>? alerts,
    TalhoesSummary? talhoesSummary,
    PlantiosAtivos? plantiosAtivos,
    MonitoramentosSummary? monitoramentosSummary,
    EstoqueSummary? estoqueSummary,
    WeatherData? weatherData,
    IndicadoresRapidos? indicadoresRapidos,
    DateTime? lastUpdated,
  }) {
    return DashboardData(
      id: id ?? this.id,
      farmProfile: farmProfile ?? this.farmProfile,
      alerts: alerts ?? this.alerts,
      talhoesSummary: talhoesSummary ?? this.talhoesSummary,
      plantiosAtivos: plantiosAtivos ?? this.plantiosAtivos,
      monitoramentosSummary: monitoramentosSummary ?? this.monitoramentosSummary,
      estoqueSummary: estoqueSummary ?? this.estoqueSummary,
      weatherData: weatherData ?? this.weatherData,
      indicadoresRapidos: indicadoresRapidos ?? this.indicadoresRapidos,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Perfil da fazenda
class FarmProfile {
  final String nome;
  final String proprietario;
  final String cidade;
  final String uf;
  final double areaTotal;
  final int totalTalhoes;
  final String? logoUrl;

  const FarmProfile({
    required this.nome,
    required this.proprietario,
    required this.cidade,
    required this.uf,
    required this.areaTotal,
    required this.totalTalhoes,
    this.logoUrl,
  });

  factory FarmProfile.empty() {
    return const FarmProfile(
      nome: 'Fazenda não configurada',
      proprietario: 'Não informado',
      cidade: 'Não informado',
      uf: 'N/A',
      areaTotal: 0.0,
      totalTalhoes: 0,
    );
  }

  String get localizacao => '$cidade/$uf';
}

/// Alertas do sistema
class Alert {
  final String id;
  final String titulo;
  final String descricao;
  final String talhao;
  final DateTime data;
  final AlertLevel level;
  final AlertType type;
  final bool isActive;

  const Alert({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.talhao,
    required this.data,
    required this.level,
    required this.type,
    this.isActive = true,
  });

  factory Alert.create({
    required String titulo,
    required String descricao,
    required String talhao,
    required AlertLevel level,
    required AlertType type,
  }) {
    return Alert(
      id: const Uuid().v4(),
      titulo: titulo,
      descricao: descricao,
      talhao: talhao,
      data: DateTime.now(),
      level: level,
      type: type,
    );
  }
}

/// Nível de alerta
enum AlertLevel {
  baixo,
  medio,
  alto,
  critico
}

/// Tipo de alerta
enum AlertType {
  infestacao,
  monitoramento,
  plantio,
  colheita,
  estoque,
  sistema
}

/// Resumo de talhões
class TalhoesSummary {
  final int totalTalhoes;
  final double areaTotal;
  final DateTime ultimaAtualizacao;
  final int talhoesAtivos;

  const TalhoesSummary({
    required this.totalTalhoes,
    required this.areaTotal,
    required this.ultimaAtualizacao,
    required this.talhoesAtivos,
  });

  factory TalhoesSummary.empty() {
    return TalhoesSummary(
      totalTalhoes: 0,
      areaTotal: 0.0,
      ultimaAtualizacao: DateTime.now(),
      talhoesAtivos: 0,
    );
  }
}

/// Plantios ativos
class PlantiosAtivos {
  final List<PlantioAtivo> plantios;
  final double areaTotalPlantada;
  final int totalPlantios;

  const PlantiosAtivos({
    required this.plantios,
    required this.areaTotalPlantada,
    required this.totalPlantios,
  });

  factory PlantiosAtivos.empty() {
    return const PlantiosAtivos(
      plantios: [],
      areaTotalPlantada: 0.0,
      totalPlantios: 0,
    );
  }
}

/// Plantio ativo individual
class PlantioAtivo {
  final String id;
  final String cultura;
  final String variedade;
  final double area;
  final EstagioFenologico estagio;
  final DateTime? previsaoColheita;
  final String talhao;

  const PlantioAtivo({
    required this.id,
    required this.cultura,
    required this.variedade,
    required this.area,
    required this.estagio,
    this.previsaoColheita,
    required this.talhao,
  });
}

/// Estágio fenológico
enum EstagioFenologico {
  emergencia,
  vegetativo,
  florescimento,
  enchimento,
  maturacao,
  colheita
}

/// Resumo de monitoramentos
class MonitoramentosSummary {
  final int pendentes;
  final int realizados;
  final DateTime? ultimoMonitoramento;
  final String? ultimoTalhao;

  const MonitoramentosSummary({
    required this.pendentes,
    required this.realizados,
    this.ultimoMonitoramento,
    this.ultimoTalhao,
  });

  factory MonitoramentosSummary.empty() {
    return const MonitoramentosSummary(
      pendentes: 0,
      realizados: 0,
    );
  }
}

/// Resumo de estoque
class EstoqueSummary {
  final int totalItens;
  final List<ItemEstoque> principaisInsumos;
  final int itensBaixoEstoque;

  const EstoqueSummary({
    required this.totalItens,
    required this.principaisInsumos,
    required this.itensBaixoEstoque,
  });

  factory EstoqueSummary.empty() {
    return const EstoqueSummary(
      totalItens: 0,
      principaisInsumos: [],
      itensBaixoEstoque: 0,
    );
  }
}

/// Item do estoque
class ItemEstoque {
  final String id;
  final String nome;
  final String categoria;
  final double quantidade;
  final String unidade;
  final EstoqueStatus status;

  const ItemEstoque({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    required this.status,
  });
}

/// Status do estoque
enum EstoqueStatus {
  disponivel,
  baixo,
  indisponivel
}

/// Dados climáticos
class WeatherData {
  final String localizacao;
  final double temperatura;
  final String condicao;
  final double umidade;
  final double vento;
  final double probabilidadeChuva;
  final List<PrevisaoTempo> previsao3Dias;

  const WeatherData({
    required this.localizacao,
    required this.temperatura,
    required this.condicao,
    required this.umidade,
    required this.vento,
    required this.probabilidadeChuva,
    required this.previsao3Dias,
  });

  factory WeatherData.empty() {
    return const WeatherData(
      localizacao: 'Não disponível',
      temperatura: 0.0,
      condicao: 'Não disponível',
      umidade: 0.0,
      vento: 0.0,
      probabilidadeChuva: 0.0,
      previsao3Dias: [],
    );
  }
}

/// Previsão do tempo
class PrevisaoTempo {
  final DateTime data;
  final double temperaturaMax;
  final double temperaturaMin;
  final String condicao;
  final double probabilidadeChuva;

  const PrevisaoTempo({
    required this.data,
    required this.temperaturaMax,
    required this.temperaturaMin,
    required this.condicao,
    required this.probabilidadeChuva,
  });
}

/// Indicadores rápidos
class IndicadoresRapidos {
  final double areaPlantada;
  final double produtividadeEstimada;
  final double hectaresInfestados;
  final double custosAcumulados;

  const IndicadoresRapidos({
    required this.areaPlantada,
    required this.produtividadeEstimada,
    required this.hectaresInfestados,
    required this.custosAcumulados,
  });

  factory IndicadoresRapidos.empty() {
    return const IndicadoresRapidos(
      areaPlantada: 0.0,
      produtividadeEstimada: 0.0,
      hectaresInfestados: 0.0,
      custosAcumulados: 0.0,
    );
  }
}
