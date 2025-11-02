import 'dart:math';

/// Serviço para cálculos automáticos de aplicação agrícola
class AplicacaoCalculoService {
  
  /// Tipos de máquina disponíveis
  static const List<String> tiposMaquina = ['Terrestre', 'Aérea'];
  
  /// Calcula a capacidade da máquina (hectares cobertos por tanque)
  /// Fórmula: Hectares_cobertos_por_tanque = Capacidade_Tanque / Vazão_por_Ha
  static double calcularCapacidadeMaquina({
    required double capacidadeTanque,
    required double vazaoPorHectare,
  }) {
    if (vazaoPorHectare <= 0) return 0;
    return capacidadeTanque / vazaoPorHectare;
  }
  
  /// Calcula o número de tanques/bombas/vôos necessários
  /// Fórmula: Nº_Tanques = Área_Total / Hectares_cobertos_por_tanque
  static int calcularNumeroTanques({
    required double areaTotal,
    required double hectaresPorTanque,
  }) {
    if (hectaresPorTanque <= 0) return 0;
    return (areaTotal / hectaresPorTanque).ceil();
  }
  
  /// Calcula a quantidade total de produto
  /// Fórmula: Quantidade_total_produto = Dose_Ha * Área_Total
  static double calcularQuantidadeTotalProduto({
    required double dosePorHectare,
    required double areaTotal,
  }) {
    return dosePorHectare * areaTotal;
  }
  
  /// Calcula a quantidade de produto por tanque
  /// Fórmula: Quantidade_produto_por_tanque = Dose_Ha * Hectares_cobertos_por_tanque
  static double calcularQuantidadeProdutoPorTanque({
    required double dosePorHectare,
    required double hectaresPorTanque,
  }) {
    return dosePorHectare * hectaresPorTanque;
  }
  
  /// Calcula o custo total de um produto
  static double calcularCustoTotalProduto({
    required double quantidadeTotal,
    required double precoUnitario,
  }) {
    return quantidadeTotal * precoUnitario;
  }
  
  /// Calcula o custo por hectare
  static double calcularCustoPorHectare({
    required double custoTotal,
    required double areaTotal,
  }) {
    if (areaTotal <= 0) return 0;
    return custoTotal / areaTotal;
  }
  
  /// Calcula a eficiência operacional
  static double calcularEficienciaOperacional({
    required double areaTotal,
    required double areaEfetiva,
  }) {
    if (areaTotal <= 0) return 0;
    return (areaEfetiva / areaTotal) * 100;
  }
  
  /// Valida se há estoque suficiente
  static bool validarEstoque({
    required double quantidadeNecessaria,
    required double estoqueDisponivel,
  }) {
    return estoqueDisponivel >= quantidadeNecessaria;
  }
  
  /// Calcula o volume residual no último tanque
  static double calcularVolumeResidual({
    required double areaTotal,
    required double hectaresPorTanque,
    required double vazaoPorHectare,
    required double capacidadeTanque,
  }) {
    final numeroTanques = calcularNumeroTanques(
      areaTotal: areaTotal,
      hectaresPorTanque: hectaresPorTanque,
    );
    
    final areaCoberta = numeroTanques * hectaresPorTanque;
    final volumeTotal = areaCoberta * vazaoPorHectare;
    final volumeTanques = numeroTanques * capacidadeTanque;
    
    return volumeTanques - volumeTotal;
  }
  
  /// Calcula a velocidade ideal baseada na largura e vazão
  static double calcularVelocidadeIdeal({
    required double larguraTrabalho,
    required double vazaoPorHectare,
    required double vazaoBico,
  }) {
    if (larguraTrabalho <= 0 || vazaoPorHectare <= 0) return 0;
    
    // Fórmula: Velocidade (km/h) = (Vazão_Bico * 600) / (Largura * Vazão_Ha)
    return (vazaoBico * 600) / (larguraTrabalho * vazaoPorHectare);
  }
  
  /// Calcula a pressão ideal baseada na vazão do bico
  static double calcularPressaoIdeal({
    required double vazaoBico,
    required double fatorBico,
  }) {
    // Fórmula: Pressão = (Vazão_Bico / Fator_Bico)²
    return pow(vazaoBico / fatorBico, 2).toDouble();
  }
  
  /// Gera resumo operacional completo
  static Map<String, dynamic> gerarResumoOperacional({
    required double areaTotal,
    required double vazaoPorHectare,
    required double capacidadeTanque,
    required String tipoMaquina,
    required List<Map<String, dynamic>> produtos,
  }) {
    final hectaresPorTanque = calcularCapacidadeMaquina(
      capacidadeTanque: capacidadeTanque,
      vazaoPorHectare: vazaoPorHectare,
    );
    
    final numeroTanques = calcularNumeroTanques(
      areaTotal: areaTotal,
      hectaresPorTanque: hectaresPorTanque,
    );
    
    final volumeResidual = calcularVolumeResidual(
      areaTotal: areaTotal,
      hectaresPorTanque: hectaresPorTanque,
      vazaoPorHectare: vazaoPorHectare,
      capacidadeTanque: capacidadeTanque,
    );
    
    double custoTotal = 0;
    List<Map<String, dynamic>> resumoProdutos = [];
    
    for (final produto in produtos) {
      final quantidadeTotal = calcularQuantidadeTotalProduto(
        dosePorHectare: produto['dosePorHectare'] ?? 0,
        areaTotal: areaTotal,
      );
      
      final quantidadePorTanque = calcularQuantidadeProdutoPorTanque(
        dosePorHectare: produto['dosePorHectare'] ?? 0,
        hectaresPorTanque: hectaresPorTanque,
      );
      
      final custoProduto = calcularCustoTotalProduto(
        quantidadeTotal: quantidadeTotal,
        precoUnitario: produto['precoUnitario'] ?? 0,
      );
      
      custoTotal += custoProduto;
      
      resumoProdutos.add({
        'nome': produto['nome'],
        'dosePorHectare': produto['dosePorHectare'],
        'quantidadeTotal': quantidadeTotal,
        'quantidadePorTanque': quantidadePorTanque,
        'custoTotal': custoProduto,
        'unidade': produto['unidade'],
        'estoqueDisponivel': produto['estoqueDisponivel'] ?? 0,
        'estoqueSuficiente': validarEstoque(
          quantidadeNecessaria: quantidadeTotal,
          estoqueDisponivel: produto['estoqueDisponivel'] ?? 0,
        ),
      });
    }
    
    final custoPorHectare = calcularCustoPorHectare(
      custoTotal: custoTotal,
      areaTotal: areaTotal,
    );
    
    return {
      'areaTotal': areaTotal,
      'vazaoPorHectare': vazaoPorHectare,
      'capacidadeTanque': capacidadeTanque,
      'tipoMaquina': tipoMaquina,
      'hectaresPorTanque': hectaresPorTanque,
      'numeroTanques': numeroTanques,
      'volumeResidual': volumeResidual,
      'custoTotal': custoTotal,
      'custoPorHectare': custoPorHectare,
      'produtos': resumoProdutos,
      'eficiencia': 95.0, // Valor padrão, pode ser calculado com dados reais
    };
  }
  
  /// Valida configurações da máquina
  static Map<String, dynamic> validarConfiguracaoMaquina({
    required double vazaoPorHectare,
    required double capacidadeTanque,
    required String tipoMaquina,
  }) {
    List<String> alertas = [];
    List<String> sugestoes = [];
    
    // Validações para máquina terrestre
    if (tipoMaquina == 'Terrestre') {
      if (vazaoPorHectare < 50) {
        alertas.add('Vazão muito baixa para aplicação terrestre');
        sugestoes.add('Considere aumentar a vazão para 100-200 L/ha');
      } else if (vazaoPorHectare > 400) {
        alertas.add('Vazão muito alta para aplicação terrestre');
        sugestoes.add('Considere reduzir a vazão para 100-200 L/ha');
      }
      
      if (capacidadeTanque < 200) {
        alertas.add('Capacidade do tanque muito baixa');
        sugestoes.add('Considere usar tanque com capacidade mínima de 500L');
      }
    }
    
    // Validações para máquina aérea
    if (tipoMaquina == 'Aérea') {
      if (vazaoPorHectare < 10) {
        alertas.add('Vazão muito baixa para aplicação aérea');
        sugestoes.add('Considere aumentar a vazão para 20-50 L/ha');
      } else if (vazaoPorHectare > 100) {
        alertas.add('Vazão muito alta para aplicação aérea');
        sugestoes.add('Considere reduzir a vazão para 20-50 L/ha');
      }
      
      if (capacidadeTanque < 100) {
        alertas.add('Capacidade do tanque muito baixa para aplicação aérea');
        sugestoes.add('Considere usar tanque com capacidade mínima de 200L');
      }
    }
    
    return {
      'valido': alertas.isEmpty,
      'alertas': alertas,
      'sugestoes': sugestoes,
    };
  }
}
