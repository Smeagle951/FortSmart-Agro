import '../../../../../modules/tratamento_sementes/models/produto_ts_model.dart';
import '../models/tratamento_sementes_state.dart';

/// Serviço para tratamento de sementes
class TratamentoSementesService {
  /// Simula produtos baseados no cálculo de sementes
  static List<ProdutoTS> simularProdutos(TratamentoSementesState state) {
    if (state.doseSelecionada == null) return [];
    
    return [
      ProdutoTS(
        doseId: state.doseSelecionada!.id ?? 0,
        nomeProduto: 'Carbendazim',
        tipoCalculo: TipoCalculoTS.kg,
        valor: 0.5, // 0.5 mL por kg de sementes
        unidade: 'mL',
        valorUnitario: 15.0, // R$ 15,00 por mL
      ),
      ProdutoTS(
        doseId: state.doseSelecionada!.id ?? 0,
        nomeProduto: 'Thiram',
        tipoCalculo: TipoCalculoTS.kg,
        valor: 2.0, // 2g por kg de sementes
        unidade: 'g',
        valorUnitario: 0.8, // R$ 0,80 por g
      ),
      ProdutoTS(
        doseId: state.doseSelecionada!.id ?? 0,
        nomeProduto: 'Inoculante',
        tipoCalculo: TipoCalculoTS.milKg,
        valor: 1.0, // 1 dose por 1000 kg
        unidade: 'dose',
        valorUnitario: 25.0, // R$ 25,00 por dose
      ),
    ];
  }

  /// Calcula quantidade de produto baseada no tipo de cálculo
  static double calcularQuantidadeProduto(ProdutoTS produto, TratamentoSementesState state) {
    switch (produto.tipoCalculo) {
      case TipoCalculoTS.kg:
        return produto.valor * state.pesoTotalSementes;
      case TipoCalculoTS.milKg:
        return produto.valor * (state.pesoTotalSementes / 1000.0);
      case TipoCalculoTS.ha:
        return produto.valor * state.hectaresCobertos;
    }
  }

  /// Calcula custo total do produto
  static double calcularCustoProduto(ProdutoTS produto, TratamentoSementesState state) {
    if (produto.valorUnitario == null) return 0.0;
    
    final quantidade = calcularQuantidadeProduto(produto, state);
    return quantidade * produto.valorUnitario!;
  }

  /// Valida campos do estado
  static String? validarPesoBag(double? value) {
    if (value == null || value <= 0) {
      return 'Peso do bag deve ser maior que zero';
    }
    return null;
  }

  static String? validarNumeroBags(int? value) {
    if (value == null || value <= 0) {
      return 'Número de bags deve ser maior que zero';
    }
    return null;
  }
}
