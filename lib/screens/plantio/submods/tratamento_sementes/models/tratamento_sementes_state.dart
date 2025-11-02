import '../../../../../models/seed_calc_result.dart';
import '../../../../../modules/tratamento_sementes/models/dose_ts_model.dart';
import '../../../../../modules/tratamento_sementes/models/produto_ts_model.dart';

/// Estado do tratamento de sementes
class TratamentoSementesState {
  final SeedCalcResult? resultadoCalculo;
  final double pesoBag;
  final int numeroBags;
  final double sementesPorBag;
  final double germinacao;
  final double vigor;
  
  // Campos editáveis
  final double pesoBagEditavel;
  final int numeroBagsEditavel;
  final String descricao;
  
  // Dados da dose
  final DoseTS? doseSelecionada;
  final List<DoseTS> dosesDisponiveis;
  final List<ProdutoTS> produtosDose;
  
  // Estados de UI
  final bool isLoading;
  final bool isCalculando;
  final String? error;

  const TratamentoSementesState({
    this.resultadoCalculo,
    required this.pesoBag,
    required this.numeroBags,
    required this.sementesPorBag,
    required this.germinacao,
    required this.vigor,
    required this.pesoBagEditavel,
    required this.numeroBagsEditavel,
    this.descricao = '',
    this.doseSelecionada,
    this.dosesDisponiveis = const [],
    this.produtosDose = const [],
    this.isLoading = false,
    this.isCalculando = false,
    this.error,
  });

  TratamentoSementesState copyWith({
    SeedCalcResult? resultadoCalculo,
    double? pesoBag,
    int? numeroBags,
    double? sementesPorBag,
    double? germinacao,
    double? vigor,
    double? pesoBagEditavel,
    int? numeroBagsEditavel,
    String? descricao,
    DoseTS? doseSelecionada,
    List<DoseTS>? dosesDisponiveis,
    List<ProdutoTS>? produtosDose,
    bool? isLoading,
    bool? isCalculando,
    String? error,
  }) {
    return TratamentoSementesState(
      resultadoCalculo: resultadoCalculo ?? this.resultadoCalculo,
      pesoBag: pesoBag ?? this.pesoBag,
      numeroBags: numeroBags ?? this.numeroBags,
      sementesPorBag: sementesPorBag ?? this.sementesPorBag,
      germinacao: germinacao ?? this.germinacao,
      vigor: vigor ?? this.vigor,
      pesoBagEditavel: pesoBagEditavel ?? this.pesoBagEditavel,
      numeroBagsEditavel: numeroBagsEditavel ?? this.numeroBagsEditavel,
      descricao: descricao ?? this.descricao,
      doseSelecionada: doseSelecionada ?? this.doseSelecionada,
      dosesDisponiveis: dosesDisponiveis ?? this.dosesDisponiveis,
      produtosDose: produtosDose ?? this.produtosDose,
      isLoading: isLoading ?? this.isLoading,
      isCalculando: isCalculando ?? this.isCalculando,
      error: error ?? this.error,
    );
  }

  /// Calcula valores derivados
  double get pesoTotalSementes => pesoBagEditavel * numeroBagsEditavel;
  
  double get hectaresCobertos {
    if (resultadoCalculo == null) return 0.0;
    final fatorPeso = pesoTotalSementes / (pesoBag * numeroBags);
    return resultadoCalculo!.hectaresCovered * fatorPeso;
  }
  
  double get kgPorHectare => resultadoCalculo?.kgPerHa ?? 0.0;
}
