import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Modelo completo para experimento de talhão
class ExperimentoCompleto {
  final String id;
  final String nome;
  final String talhaoId;
  final String talhaoNome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final ExperimentoStatus status;
  final String? descricao;
  final String? objetivo;
  final List<SubareaCompleta> subareas;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExperimentoCompleto({
    required this.id,
    required this.nome,
    required this.talhaoId,
    required this.talhaoNome,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    this.descricao,
    this.objetivo,
    required this.subareas,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calcula dias restantes
  int get diasRestantes {
    final now = DateTime.now();
    final diferenca = dataFim.difference(now);
    return diferenca.inDays;
  }

  /// Verifica se o experimento está ativo
  bool get isAtivo => status == ExperimentoStatus.ativo && diasRestantes > 0;

  /// Verifica se o experimento está concluído
  bool get isConcluido => status == ExperimentoStatus.concluido || diasRestantes <= 0;

  /// Verifica se pode criar mais subáreas
  bool get podeCriarSubarea => subareas.length < 6;

  /// Obtém cor do status
  Color get statusColor {
    switch (status) {
      case ExperimentoStatus.ativo:
        return Colors.green;
      case ExperimentoStatus.concluido:
        return Colors.blue;
      case ExperimentoStatus.pendente:
        return Colors.orange;
      case ExperimentoStatus.cancelado:
        return Colors.red;
    }
  }

  /// Obtém texto do status
  String get statusText {
    switch (status) {
      case ExperimentoStatus.ativo:
        return 'Ativo';
      case ExperimentoStatus.concluido:
        return 'Concluído';
      case ExperimentoStatus.pendente:
        return 'Pendente';
      case ExperimentoStatus.cancelado:
        return 'Cancelado';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'status': status.index,
      'descricao': descricao,
      'objetivo': objetivo,
      'subareas': subareas.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExperimentoCompleto.fromMap(Map<String, dynamic> map) {
    return ExperimentoCompleto(
      id: map['id'] as String,
      nome: map['nome'] as String,
      talhaoId: map['talhaoId'] as String,
      talhaoNome: map['talhaoNome'] as String,
      dataInicio: DateTime.parse(map['dataInicio'] as String),
      dataFim: DateTime.parse(map['dataFim'] as String),
      status: ExperimentoStatus.values[map['status'] as int],
      descricao: map['descricao'] as String?,
      objetivo: map['objetivo'] as String?,
      subareas: (map['subareas'] as List<dynamic>?)
          ?.map((s) => SubareaCompleta.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ExperimentoCompleto copyWith({
    String? id,
    String? nome,
    String? talhaoId,
    String? talhaoNome,
    DateTime? dataInicio,
    DateTime? dataFim,
    ExperimentoStatus? status,
    String? descricao,
    String? objetivo,
    List<SubareaCompleta>? subareas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExperimentoCompleto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      descricao: descricao ?? this.descricao,
      objetivo: objetivo ?? this.objetivo,
      subareas: subareas ?? this.subareas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Status do experimento
enum ExperimentoStatus {
  ativo,
  concluido,
  pendente,
  cancelado,
}

/// Modelo completo para subárea de experimento
class SubareaCompleta {
  final String id;
  final String experimentoId;
  final String nome;
  final String tipo;
  final Color cor;
  final List<LatLng> pontos;
  final double area;
  final double perimetro;
  final String? descricao;
  final String? cultura;
  final String? variedade;
  final String? observacoes;
  final SubareaStatus status;
  final DateTime dataCriacao;
  final DateTime? dataFinalizacao;
  final Map<String, dynamic>? dadosPlantio;
  final Map<String, dynamic>? dadosColheita;

  const SubareaCompleta({
    required this.id,
    required this.experimentoId,
    required this.nome,
    required this.tipo,
    required this.cor,
    required this.pontos,
    required this.area,
    required this.perimetro,
    this.descricao,
    this.cultura,
    this.variedade,
    this.observacoes,
    required this.status,
    required this.dataCriacao,
    this.dataFinalizacao,
    this.dadosPlantio,
    this.dadosColheita,
  });

  /// Obtém cor do status
  Color get statusColor {
    switch (status) {
      case SubareaStatus.ativa:
        return Colors.green;
      case SubareaStatus.finalizada:
        return Colors.blue;
      case SubareaStatus.pendente:
        return Colors.orange;
    }
  }

  /// Obtém texto do status
  String get statusText {
    switch (status) {
      case SubareaStatus.ativa:
        return 'Ativa';
      case SubareaStatus.finalizada:
        return 'Finalizada';
      case SubareaStatus.pendente:
        return 'Pendente';
    }
  }

  /// Obtém área formatada
  String get areaFormatada {
    if (area < 1) {
      return '${(area * 10000).toStringAsFixed(0)} m²';
    } else {
      return '${area.toStringAsFixed(2)} ha';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experimentoId': experimentoId,
      'nome': nome,
      'tipo': tipo,
      'cor': cor.value,
      'pontos': pontos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'area': area,
      'perimetro': perimetro,
      'descricao': descricao,
      'cultura': cultura,
      'variedade': variedade,
      'observacoes': observacoes,
      'status': status.index,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataFinalizacao': dataFinalizacao?.toIso8601String(),
      'dadosPlantio': dadosPlantio,
      'dadosColheita': dadosColheita,
    };
  }

  factory SubareaCompleta.fromMap(Map<String, dynamic> map) {
    return SubareaCompleta(
      id: map['id'] as String,
      experimentoId: map['experimentoId'] as String,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String,
      cor: Color(map['cor'] as int),
      pontos: (map['pontos'] as List<dynamic>)
          .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList(),
      area: (map['area'] as num).toDouble(),
      perimetro: (map['perimetro'] as num).toDouble(),
      descricao: map['descricao'] as String?,
      cultura: map['cultura'] as String?,
      variedade: map['variedade'] as String?,
      observacoes: map['observacoes'] as String?,
      status: SubareaStatus.values[map['status'] as int],
      dataCriacao: DateTime.parse(map['dataCriacao'] as String),
      dataFinalizacao: map['dataFinalizacao'] != null 
          ? DateTime.parse(map['dataFinalizacao'] as String) 
          : null,
      dadosPlantio: map['dadosPlantio'] as Map<String, dynamic>?,
      dadosColheita: map['dadosColheita'] as Map<String, dynamic>?,
    );
  }

  SubareaCompleta copyWith({
    String? id,
    String? experimentoId,
    String? nome,
    String? tipo,
    Color? cor,
    List<LatLng>? pontos,
    double? area,
    double? perimetro,
    String? descricao,
    String? cultura,
    String? variedade,
    String? observacoes,
    SubareaStatus? status,
    DateTime? dataCriacao,
    DateTime? dataFinalizacao,
    Map<String, dynamic>? dadosPlantio,
    Map<String, dynamic>? dadosColheita,
  }) {
    return SubareaCompleta(
      id: id ?? this.id,
      experimentoId: experimentoId ?? this.experimentoId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      cor: cor ?? this.cor,
      pontos: pontos ?? this.pontos,
      area: area ?? this.area,
      perimetro: perimetro ?? this.perimetro,
      descricao: descricao ?? this.descricao,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
      dadosPlantio: dadosPlantio ?? this.dadosPlantio,
      dadosColheita: dadosColheita ?? this.dadosColheita,
    );
  }
}

/// Status da subárea
enum SubareaStatus {
  ativa,
  finalizada,
  pendente,
}

/// Tipos de experimento
class TipoExperimento {
  static const String sementes = 'Sementes';
  static const String variedade = 'Variedade';
  static const String adubo = 'Adubo';
  static const String defensivo = 'Defensivo';
  static const String espacamento = 'Espaçamento';
  static const String populacao = 'População';
  static const String irrigacao = 'Irrigação';
  static const String outros = 'Outros';

  static const List<String> tipos = [
    sementes,
    variedade,
    adubo,
    defensivo,
    espacamento,
    populacao,
    irrigacao,
    outros,
  ];

  static IconData getIcon(String tipo) {
    switch (tipo) {
      case sementes:
        return Icons.eco;
      case variedade:
        return Icons.agriculture;
      case adubo:
        return Icons.grass;
      case defensivo:
        return Icons.bug_report;
      case espacamento:
        return Icons.grid_view;
      case populacao:
        return Icons.people;
      case irrigacao:
        return Icons.water_drop;
      default:
        return Icons.science;
    }
  }

  static Color getColor(String tipo) {
    switch (tipo) {
      case sementes:
        return Colors.green;
      case variedade:
        return Colors.blue;
      case adubo:
        return Colors.brown;
      case defensivo:
        return Colors.red;
      case espacamento:
        return Colors.orange;
      case populacao:
        return Colors.purple;
      case irrigacao:
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

/// Paleta de cores para subáreas
class PaletaCoresSubareas {
  static const List<Color> cores = [
    Color(0xFFE57373), // Vermelho claro
    Color(0xFF81C784), // Verde claro
    Color(0xFF64B5F6), // Azul claro
    Color(0xFFFFB74D), // Laranja claro
    Color(0xFFBA68C8), // Roxo claro
    Color(0xFF4DB6AC), // Turquesa claro
  ];

  static Color getCor(int index) {
    return cores[index % cores.length];
  }
}
