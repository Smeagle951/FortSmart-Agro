import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Modelo para representar uma calibragem de plantadeira (sementes + adubo)
/// Implementação atualizada conforme as novas especificações
class PlanterCalibrationNew {
  final String id;
  final String name; // Nome da calibragem
  final int? talhaoId; // ID do talhão (opcional)
  final int culturaId; // ID da cultura
  final int? variedadeId; // ID da variedade
  final String tipo; // 'semente' ou 'adubo'
  final double populacao; // plantas/ha
  final double espacamento; // Espaçamento em cm
  final int numLinhas; // Número de linhas da plantadeira
  final double? pesoMilSementes; // Peso de mil sementes (g)
  final String? disco; // Tipo de disco usado
  final int? engrenagemMotora; // Número de dentes da engrenagem motora
  final int? engrenagemMovida; // Número de dentes da engrenagem movida
  final double? roscaPasso1; // Rosca passo 1 (adubo)
  final double? roscaPasso2; // Rosca passo 2 (adubo)
  final double? distanciaPercorrida; // Distância percorrida em metros (adubo)
  final double? pesoColetado; // Peso coletado no trajeto (adubo)
  final double? resultadoKgHa; // Resultado em kg/ha
  final double? resultadoKgMetro; // Resultado em kg/metro
  final String? observacoes; // Observações
  final String? fotos; // URLs das fotos separadas por vírgula
  final String dataRegulagem; // Data da regulagem
  final String createdAt; // Data de criação

  PlanterCalibrationNew({
    String? id,
    required this.name,
    this.talhaoId,
    required this.culturaId,
    this.variedadeId,
    required this.tipo,
    required this.populacao,
    required this.espacamento,
    required this.numLinhas,
    this.pesoMilSementes,
    this.disco,
    this.engrenagemMotora,
    this.engrenagemMovida,
    this.roscaPasso1,
    this.roscaPasso2,
    this.distanciaPercorrida,
    this.pesoColetado,
    this.resultadoKgHa,
    this.resultadoKgMetro,
    this.observacoes,
    this.fotos,
    String? dataRegulagem,
    String? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    dataRegulagem = dataRegulagem ?? DateTime.now().toIso8601String(),
    createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Getters para compatibilidade com código existente
  double get calibrationDistance => distanciaPercorrida != null ? distanciaPercorrida! * 100 : 0.0;
  int get seedsCount => 0; // Compatibilidade
  String get notes => observacoes ?? '';
  String? get cropName => null; // Será preenchido pelo repositório
  String? get planterName => null; // Será preenchido pelo repositório
  String? get plotName => null; // Será preenchido pelo repositório
  DateTime get calibrationDate => DateTime.tryParse(dataRegulagem) ?? DateTime.now();
  double get targetSeedRate => populacao;
  double get rowSpacing => espacamento;
  double get targetPopulation => populacao;
  
  // Getters adicionais para relatórios
  double get seedsPerMeter => calculateSeedsPerMeter();
  double get estimatedPopulation => populacao;
  String? get responsible => null; // Compatibilidade
  
  // Novos getters para facilitar acesso aos dados
  double get relacaoEngrenagens => engrenagemMotora != null && engrenagemMovida != null ? 
      engrenagemMovida! / engrenagemMotora! : 0.0;
      
  String get tipoFormatado => tipo == 'semente' ? 'Sementes' : 'Adubo';
  
  /// Calcula sementes por metro linear
  double calculateSeedsPerMeter() {
    // Usando a fórmula: (População / 10000) * Espaçamento
    return (populacao / 10000) * espacamento;
  }
  
  /// Calcula kg por hectare para sementes
  double calculateKgPerHectare() {
    if (pesoMilSementes == null || pesoMilSementes! <= 0) return 0.0;
    
    // Quantidade de sementes por hectare * peso de mil sementes / 1000
    return (populacao * pesoMilSementes!) / 1000;
  }
  
  /// Calcula a dosagem de adubo por hectare
  double calculateFertilizerPerHectare() {
    if (distanciaPercorrida == null || distanciaPercorrida! <= 0 ||
        pesoColetado == null || pesoColetado! <= 0) {
      return 0.0;
    }
    
    // Fórmula: (Peso coletado * 10000) / (Distância * Largura da máquina)
    double larguraMaquina = numLinhas * (espacamento / 100); // Converter espaçamento para metros
    return (pesoColetado! * 10000) / (distanciaPercorrida! * larguraMaquina);
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'tipo': tipo,
      'populacao': populacao,
      'espacamento': espacamento,
      'num_linhas': numLinhas,
      'peso_mil_sementes': pesoMilSementes,
      'disco': disco,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'rosca_passo1': roscaPasso1,
      'rosca_passo2': roscaPasso2,
      'distancia_percorrida': distanciaPercorrida,
      'peso_coletado': pesoColetado,
      'resultado_kg_ha': resultadoKgHa,
      'resultado_kg_metro': resultadoKgMetro,
      'observacoes': observacoes,
      'fotos': fotos,
      'data_regulagem': dataRegulagem,
      'created_at': createdAt,
    };
  }

  factory PlanterCalibrationNew.fromMap(Map<String, dynamic> map) {
    return PlanterCalibrationNew(
      id: map['id'],
      name: map['name'] ?? '',
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'] ?? 0,
      variedadeId: map['variedade_id'],
      tipo: map['tipo'] ?? 'semente',
      populacao: map['populacao']?.toDouble() ?? 0.0,
      espacamento: map['espacamento']?.toDouble() ?? 0.0,
      numLinhas: map['num_linhas'] ?? 0,
      pesoMilSementes: map['peso_mil_sementes']?.toDouble(),
      disco: map['disco'],
      engrenagemMotora: map['engrenagem_motora'],
      engrenagemMovida: map['engrenagem_movida'],
      roscaPasso1: map['rosca_passo1']?.toDouble(),
      roscaPasso2: map['rosca_passo2']?.toDouble(),
      distanciaPercorrida: map['distancia_percorrida']?.toDouble(),
      pesoColetado: map['peso_coletado']?.toDouble(),
      resultadoKgHa: map['resultado_kg_ha']?.toDouble(),
      resultadoKgMetro: map['resultado_kg_metro']?.toDouble(),
      observacoes: map['observacoes'],
      fotos: map['fotos'],
      dataRegulagem: map['data_regulagem'] ?? DateTime.now().toIso8601String(),
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlanterCalibrationNew.fromJson(String source) => 
      PlanterCalibrationNew.fromMap(json.decode(source));
  
  /// Método auxiliar para formatar datas
  String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  /// Cria uma cópia da calibragem com os valores atualizados
  PlanterCalibrationNew copyWith({
    String? id,
    String? name,
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    String? tipo,
    double? populacao,
    double? espacamento,
    int? numLinhas,
    double? pesoMilSementes,
    String? disco,
    int? engrenagemMotora,
    int? engrenagemMovida,
    double? roscaPasso1,
    double? roscaPasso2,
    double? distanciaPercorrida,
    double? pesoColetado,
    double? resultadoKgHa,
    double? resultadoKgMetro,
    String? observacoes,
    String? fotos,
    String? dataRegulagem,
    String? createdAt,
  }) {
    return PlanterCalibrationNew(
      id: id ?? this.id,
      name: name ?? this.name,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      tipo: tipo ?? this.tipo,
      populacao: populacao ?? this.populacao,
      espacamento: espacamento ?? this.espacamento,
      numLinhas: numLinhas ?? this.numLinhas,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      disco: disco ?? this.disco,
      engrenagemMotora: engrenagemMotora ?? this.engrenagemMotora,
      engrenagemMovida: engrenagemMovida ?? this.engrenagemMovida,
      roscaPasso1: roscaPasso1 ?? this.roscaPasso1,
      roscaPasso2: roscaPasso2 ?? this.roscaPasso2,
      distanciaPercorrida: distanciaPercorrida ?? this.distanciaPercorrida,
      pesoColetado: pesoColetado ?? this.pesoColetado,
      resultadoKgHa: resultadoKgHa ?? this.resultadoKgHa,
      resultadoKgMetro: resultadoKgMetro ?? this.resultadoKgMetro,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      dataRegulagem: dataRegulagem ?? this.dataRegulagem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PlanterCalibrationNew(id: $id, name: $name, tipo: $tipo, culturaId: $culturaId, variedadeId: $variedadeId, talhaoId: $talhaoId)';
  }
}
