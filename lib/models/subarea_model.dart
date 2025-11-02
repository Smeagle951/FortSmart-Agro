import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// Modelo de dados para uma Subárea no sistema FortSmart Agro
/// Representa uma divisão experimental dentro de um talhão
class SubareaModel {
  final String id;
  final String talhaoId;
  final String nome;
  final String? cultura;
  final String? variedade;
  final int? populacao;
  final SubareaColor cor;
  final List<LatLng> pontos;
  final double areaHa;
  final double perimetroM;
  final DateTime? dataInicio;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? observacoes;
  final bool ativa;
  final int? ordem; // Para ordenação visual

  const SubareaModel({
    required this.id,
    required this.talhaoId,
    required this.nome,
    this.cultura,
    this.variedade,
    this.populacao,
    required this.cor,
    required this.pontos,
    required this.areaHa,
    required this.perimetroM,
    this.dataInicio,
    required this.criadoEm,
    this.atualizadoEm,
    this.observacoes,
    this.ativa = true,
    this.ordem,
  });

  /// Cria uma nova subárea com ID gerado automaticamente
  factory SubareaModel.create({
    required String talhaoId,
    required String nome,
    String? cultura,
    String? variedade,
    int? populacao,
    SubareaColor? cor,
    required List<LatLng> pontos,
    required double areaHa,
    required double perimetroM,
    DateTime? dataInicio,
    String? observacoes,
    int? ordem,
  }) {
    return SubareaModel(
      id: const Uuid().v4(),
      talhaoId: talhaoId,
      nome: nome,
      cultura: cultura,
      variedade: variedade,
      populacao: populacao,
      cor: cor ?? SubareaColor.azul,
      pontos: pontos,
      areaHa: areaHa,
      perimetroM: perimetroM,
      dataInicio: dataInicio,
      criadoEm: DateTime.now(),
      observacoes: observacoes,
      ativa: true,
      ordem: ordem,
    );
  }

  /// Calcula DAE (Dias Após Emergência)
  int? get dae {
    if (dataInicio == null) return null;
    return DateTime.now().difference(dataInicio!).inDays;
  }

  /// Calcula percentual da subárea em relação ao talhão
  double calcularPercentualTalhao(double areaTalhaoHa) {
    if (areaTalhaoHa <= 0) return 0;
    return (areaHa / areaTalhaoHa) * 100;
  }

  /// Calcula centroide da subárea
  LatLng get centroide {
    if (pontos.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final ponto in pontos) {
      latSum += ponto.latitude;
      lngSum += ponto.longitude;
    }
    
    return LatLng(latSum / pontos.length, lngSum / pontos.length);
  }

  /// Verifica se a subárea está dentro do período de desenvolvimento
  bool get isEmDesenvolvimento {
    final daeValue = dae;
    return daeValue != null && daeValue >= 0 && daeValue <= 120;
  }

  /// Retorna status da subárea baseado no DAE
  SubareaStatus get status {
    final daeValue = dae;
    if (daeValue == null) return SubareaStatus.naoIniciada;
    
    if (daeValue < 0) return SubareaStatus.planejada;
    if (daeValue <= 30) return SubareaStatus.emergencia;
    if (daeValue <= 60) return SubareaStatus.vegetativo;
    if (daeValue <= 90) return SubareaStatus.reprodutivo;
    if (daeValue <= 120) return SubareaStatus.maturacao;
    return SubareaStatus.colheita;
  }

  /// Retorna cor baseada no status
  Color get statusColor {
    switch (status) {
      case SubareaStatus.naoIniciada:
        return Colors.grey;
      case SubareaStatus.planejada:
        return Colors.blue;
      case SubareaStatus.emergencia:
        return Colors.green;
      case SubareaStatus.vegetativo:
        return Colors.lightGreen;
      case SubareaStatus.reprodutivo:
        return Colors.orange;
      case SubareaStatus.maturacao:
        return Colors.amber;
      case SubareaStatus.colheita:
        return Colors.red;
    }
  }

  /// Cria uma cópia da subárea com campos alterados
  SubareaModel copyWith({
    String? id,
    String? talhaoId,
    String? nome,
    String? cultura,
    String? variedade,
    int? populacao,
    SubareaColor? cor,
    List<LatLng>? pontos,
    double? areaHa,
    double? perimetroM,
    DateTime? dataInicio,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? observacoes,
    bool? ativa,
    int? ordem,
  }) {
    return SubareaModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      nome: nome ?? this.nome,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      populacao: populacao ?? this.populacao,
      cor: cor ?? this.cor,
      pontos: pontos ?? this.pontos,
      areaHa: areaHa ?? this.areaHa,
      perimetroM: perimetroM ?? this.perimetroM,
      dataInicio: dataInicio ?? this.dataInicio,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      observacoes: observacoes ?? this.observacoes,
      ativa: ativa ?? this.ativa,
      ordem: ordem ?? this.ordem,
    );
  }

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'nome': nome,
      'cultura': cultura,
      'variedade': variedade,
      'populacao': populacao,
      'cor': cor.name,
      'pontos': pontos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'area_ha': areaHa,
      'perimetro_m': perimetroM,
      'data_inicio': dataInicio?.toIso8601String(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'observacoes': observacoes,
      'ativa': ativa ? 1 : 0,
      'ordem': ordem,
    };
  }

  /// Cria a partir de Map
  factory SubareaModel.fromMap(Map<String, dynamic> map) {
    final pontosList = (map['pontos'] as List?)
        ?.map((p) => LatLng(p['lat'], p['lng']))
        .toList() ?? <LatLng>[];

    return SubareaModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      nome: map['nome'] ?? '',
      cultura: map['cultura'],
      variedade: map['variedade'],
      populacao: map['populacao'],
      cor: SubareaColor.fromString(map['cor'] ?? 'azul'),
      pontos: pontosList,
      areaHa: (map['area_ha'] ?? 0.0).toDouble(),
      perimetroM: (map['perimetro_m'] ?? 0.0).toDouble(),
      dataInicio: map['data_inicio'] != null 
          ? DateTime.parse(map['data_inicio']) 
          : null,
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: map['atualizado_em'] != null 
          ? DateTime.parse(map['atualizado_em']) 
          : null,
      observacoes: map['observacoes'],
      ativa: (map['ativa'] ?? 1) == 1,
      ordem: map['ordem'],
    );
  }

  @override
  String toString() {
    return 'SubareaModel(id: $id, nome: $nome, areaHa: $areaHa, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubareaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum para cores das subáreas
enum SubareaColor {
  azul(Colors.blue, 'Azul'),
  verde(Colors.green, 'Verde'),
  laranja(Colors.orange, 'Laranja'),
  roxo(Colors.purple, 'Roxo'),
  vermelho(Colors.red, 'Vermelho'),
  ciano(Colors.cyan, 'Ciano'),
  amarelo(Colors.yellow, 'Amarelo'),
  rosa(Colors.pink, 'Rosa'),
  indigo(Colors.indigo, 'Índigo'),
  teal(Colors.teal, 'Teal');

  const SubareaColor(this.color, this.nome);
  final Color color;
  final String nome;

  /// Cria a partir de string
  static SubareaColor fromString(String value) {
    return SubareaColor.values.firstWhere(
      (c) => c.name == value,
      orElse: () => SubareaColor.azul,
    );
  }

  /// Retorna todas as cores disponíveis
  static List<SubareaColor> get coresDisponiveis => SubareaColor.values;
}

/// Enum para status da subárea
enum SubareaStatus {
  naoIniciada('Não Iniciada'),
  planejada('Planejada'),
  emergencia('Emergência'),
  vegetativo('Vegetativo'),
  reprodutivo('Reprodutivo'),
  maturacao('Maturação'),
  colheita('Colheita');

  const SubareaStatus(this.label);
  final String label;
}

/// Classe para filtros de subáreas
class SubareaFilter {
  final String? talhaoId;
  final String? cultura;
  final String? variedade;
  final SubareaStatus? status;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool? ativa;
  final String? busca;

  const SubareaFilter({
    this.talhaoId,
    this.cultura,
    this.variedade,
    this.status,
    this.dataInicio,
    this.dataFim,
    this.ativa,
    this.busca,
  });

  /// Cria filtro vazio
  factory SubareaFilter.empty() => const SubareaFilter();

  /// Cria filtro para um talhão específico
  factory SubareaFilter.porTalhao(String talhaoId) => 
      SubareaFilter(talhaoId: talhaoId);

  /// Cria filtro por cultura
  factory SubareaFilter.porCultura(String cultura) => 
      SubareaFilter(cultura: cultura);

  /// Cria filtro por status
  factory SubareaFilter.porStatus(SubareaStatus status) => 
      SubareaFilter(status: status);

  /// Verifica se o filtro está vazio
  bool get isEmpty => 
      talhaoId == null &&
      cultura == null &&
      variedade == null &&
      status == null &&
      dataInicio == null &&
      dataFim == null &&
      ativa == null &&
      busca == null;

  /// Aplica o filtro a uma lista de subáreas
  List<SubareaModel> aplicar(List<SubareaModel> subareas) {
    return subareas.where((subarea) {
      if (talhaoId != null && subarea.talhaoId != talhaoId) return false;
      if (cultura != null && subarea.cultura != cultura) return false;
      if (variedade != null && subarea.variedade != variedade) return false;
      if (status != null && subarea.status != status) return false;
      if (dataInicio != null && (subarea.dataInicio == null || subarea.dataInicio!.isBefore(dataInicio!))) return false;
      if (dataFim != null && (subarea.dataInicio == null || subarea.dataInicio!.isAfter(dataFim!))) return false;
      if (ativa != null && subarea.ativa != ativa) return false;
      if (busca != null && !subarea.nome.toLowerCase().contains(busca!.toLowerCase())) return false;
      
      return true;
    }).toList();
  }

  /// Cria uma cópia com campos alterados
  SubareaFilter copyWith({
    String? talhaoId,
    String? cultura,
    String? variedade,
    SubareaStatus? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativa,
    String? busca,
  }) {
    return SubareaFilter(
      talhaoId: talhaoId ?? this.talhaoId,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      status: status ?? this.status,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativa: ativa ?? this.ativa,
      busca: busca ?? this.busca,
    );
  }
}
