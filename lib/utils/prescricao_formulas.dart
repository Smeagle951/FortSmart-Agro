/// Utilitários com fórmulas de prescrição agronômica
class PrescricaoFormulas {
  
  /// Calcula a largura da barra baseada no número de bicos e espaçamento
  static double calcularLarguraBarra(int bicosAtivos, double espacamentoM) {
    return bicosAtivos * espacamentoM;
  }
  
  /// Calcula a vazão total baseada na vazão por bico
  static double calcularVazaoTotal(double vazaoBicoLMin, int bicosAtivos) {
    return vazaoBicoLMin * bicosAtivos;
  }
  
  /// Calcula o volume teórico (L/ha) para aplicação terrestre
  static double calcularVolumeTeoricoTerrestre({
    required double vazaoTotalLMin,
    required double velocidadeKmh,
    required double larguraM,
  }) {
    if (vazaoTotalLMin <= 0 || velocidadeKmh <= 0 || larguraM <= 0) {
      return 0;
    }
    return (600 * vazaoTotalLMin) / (velocidadeKmh * larguraM);
  }
  
  /// Calcula o volume teórico (L/ha) para aplicação aérea
  static double calcularVolumeTeoricoAerea({
    required double vazaoTotalLMin,
    required double velocidadeKmh,
    required double faixaM,
  }) {
    if (vazaoTotalLMin <= 0 || velocidadeKmh <= 0 || faixaM <= 0) {
      return 0;
    }
    return (600 * vazaoTotalLMin) / (velocidadeKmh * faixaM);
  }
  
  /// Calcula a vazão por bico necessária para um volume alvo
  static double calcularVazaoBicoNecessaria({
    required double volumeAlvoLHa,
    required double velocidadeKmh,
    required double espacamentoM,
  }) {
    if (velocidadeKmh <= 0 || espacamentoM <= 0) {
      return 0;
    }
    return (volumeAlvoLHa * velocidadeKmh * espacamentoM) / 600;
  }
  
  /// Calcula a capacidade efetiva do tanque
  static double calcularCapacidadeEfetiva({
    required double capacidadeTanqueL,
    required double volumeSegurancaL,
  }) {
    return capacidadeTanqueL - volumeSegurancaL;
  }
  
  /// Calcula hectares por tanque
  static double calcularHaPorTanque({
    required double capacidadeEfetivaL,
    required double volumeLHa,
  }) {
    if (volumeLHa <= 0) return 0;
    return capacidadeEfetivaL / volumeLHa;
  }
  
  /// Calcula o número de tanques necessários
  static int calcularNumeroTanques({
    required double areaTrabalhoHa,
    required double haPorTanque,
  }) {
    if (haPorTanque <= 0) return 0;
    return (areaTrabalhoHa / haPorTanque).ceil();
  }
  
  /// Calcula a quantidade total de produto
  static double calcularQuantidadeTotal({
    required double dosePorHa,
    required double areaTrabalhoHa,
  }) {
    return dosePorHa * areaTrabalhoHa;
  }
  
  /// Calcula a quantidade de produto por tanque
  static double calcularQuantidadePorTanque({
    required double dosePorHa,
    required double haPorTanque,
  }) {
    return dosePorHa * haPorTanque;
  }
  
  /// Calcula a quantidade de produto para o último tanque (se parcial)
  static double calcularQuantidadeUltimoTanque({
    required double dosePorHa,
    required double areaUltimoTanqueHa,
  }) {
    return dosePorHa * areaUltimoTanqueHa;
  }
  
  /// Calcula a área do último tanque (se parcial)
  static double calcularAreaUltimoTanque({
    required double areaTrabalhoHa,
    required double haPorTanque,
    required int numeroTanques,
  }) {
    if (numeroTanques <= 1) return areaTrabalhoHa;
    
    final areaCompleta = haPorTanque * (numeroTanques - 1);
    final areaUltimo = areaTrabalhoHa - areaCompleta;
    
    return areaUltimo > 0 ? areaUltimo : haPorTanque;
  }
  
  /// Calcula adjuvante por tanque (% v/v)
  static double calcularAdjuvantePorTanque({
    required double percentualVv,
    required double volumeCaldaPorTanqueL,
  }) {
    return (percentualVv / 100) * volumeCaldaPorTanqueL;
  }
  
  /// Calcula tempo por tanque
  static double calcularTempoPorTanque({
    required double capacidadeEfetivaL,
    required double vazaoTotalLMin,
  }) {
    if (vazaoTotalLMin <= 0) return 0;
    return capacidadeEfetivaL / vazaoTotalLMin;
  }
  
  /// Calcula capacidade de campo (ha/h)
  static double calcularCapacidadeCampo({
    required double velocidadeKmh,
    required double larguraM,
    required double eficienciaCampo,
  }) {
    return (velocidadeKmh * larguraM) / 10 * eficienciaCampo;
  }
  
  /// Calcula tempo total de aplicação
  static double calcularTempoTotal({
    required double areaTrabalhoHa,
    required double capacidadeCampoHaH,
  }) {
    if (capacidadeCampoHaH <= 0) return 0;
    return areaTrabalhoHa / capacidadeCampoHaH;
  }
  
  /// Calcula volume total de calda
  static double calcularVolumeTotalCalda({
    required double areaTrabalhoHa,
    required double volumeLHa,
  }) {
    return areaTrabalhoHa * volumeLHa;
  }
  
  /// Calcula custo por hectare
  static double calcularCustoPorHa({
    required double custoTotal,
    required double areaTrabalhoHa,
  }) {
    if (areaTrabalhoHa <= 0) return 0;
    return custoTotal / areaTrabalhoHa;
  }
  
  /// Calcula custo total de produtos
  static double calcularCustoTotal({
    required Map<String, double> custosPorProduto,
  }) {
    return custosPorProduto.values.fold(0.0, (sum, custo) => sum + custo);
  }
  
  /// Calcula custo de um produto específico
  static double calcularCustoProduto({
    required double quantidadeTotal,
    required double custoUnitario,
  }) {
    return quantidadeTotal * custoUnitario;
  }
  
  /// Valida diferença percentual entre volume alvo e calculado
  static double calcularDiferencaCalibracao({
    required double volumeAlvoLHa,
    required double volumeCalculadoLHa,
  }) {
    if (volumeAlvoLHa <= 0) return 0;
    final diferenca = ((volumeCalculadoLHa - volumeAlvoLHa) / volumeAlvoLHa) * 100;
    return diferenca.abs();
  }
  
  /// Verifica se a diferença de calibração está dentro do aceitável (≤ 3%)
  static bool isCalibracaoAceitavel(double diferencaPercentual) {
    return diferencaPercentual <= 3.0;
  }
  
  /// Converte unidades de produto
  static double converterUnidade({
    required double valor,
    required String unidadeOrigem,
    required String unidadeDestino,
    double? densidade,
  }) {
    // Conversões básicas
    if (unidadeOrigem == unidadeDestino) return valor;
    
    // mL para L
    if (unidadeOrigem == 'mL/ha' && unidadeDestino == 'L/ha') {
      return valor / 1000;
    }
    
    // L para mL
    if (unidadeOrigem == 'L/ha' && unidadeDestino == 'mL/ha') {
      return valor * 1000;
    }
    
    // g para kg
    if (unidadeOrigem == 'g/ha' && unidadeDestino == 'kg/ha') {
      return valor / 1000;
    }
    
    // kg para g
    if (unidadeOrigem == 'kg/ha' && unidadeDestino == 'g/ha') {
      return valor * 1000;
    }
    
    // Conversão por densidade (L para kg ou vice-versa)
    if (densidade != null) {
      if ((unidadeOrigem == 'L/ha' && unidadeDestino == 'kg/ha') ||
          (unidadeOrigem == 'L' && unidadeDestino == 'kg')) {
        return valor * densidade;
      }
      
      if ((unidadeOrigem == 'kg/ha' && unidadeDestino == 'L/ha') ||
          (unidadeOrigem == 'kg' && unidadeDestino == 'L')) {
        return valor / densidade;
      }
    }
    
    // Se não conseguir converter, retorna o valor original
    return valor;
  }
  
  /// Valida velocidade para aplicação terrestre (3-18 km/h)
  static bool isVelocidadeValidaTerrestre(double velocidadeKmh) {
    return velocidadeKmh >= 3.0 && velocidadeKmh <= 18.0;
  }
  
  /// Valida velocidade para aplicação aérea (80-200 km/h)
  static bool isVelocidadeValidaAerea(double velocidadeKmh) {
    return velocidadeKmh >= 80.0 && velocidadeKmh <= 200.0;
  }
  
  /// Valida velocidade para aplicação com drone (10-50 km/h)
  static bool isVelocidadeValidaDrone(double velocidadeKmh) {
    return velocidadeKmh >= 10.0 && velocidadeKmh <= 50.0;
  }
  
  /// Valida se há estoque suficiente
  static bool isEstoqueSuficiente({
    required double estoqueDisponivel,
    required double quantidadeNecessaria,
  }) {
    return estoqueDisponivel >= quantidadeNecessaria;
  }
  
  /// Calcula margem de segurança do estoque (20%)
  static double calcularMargemSegurancaEstoque(double quantidadeNecessaria) {
    return quantidadeNecessaria * 1.2;
  }
  
  /// Verifica se o estoque está baixo (menos que margem de segurança)
  static bool isEstoqueBaixo({
    required double estoqueDisponivel,
    required double quantidadeNecessaria,
  }) {
    final margemSeguranca = calcularMargemSegurancaEstoque(quantidadeNecessaria);
    return estoqueDisponivel < margemSeguranca;
  }
}

/// Utilitários para formatação de valores
class PrescricaoFormatadores {
  
  /// Formata valor numérico com casas decimais
  static String formatarValor(double valor, {int casasDecimais = 2}) {
    return valor.toStringAsFixed(casasDecimais);
  }
  
  /// Formata tempo em horas e minutos
  static String formatarTempo(double horas) {
    final horasInt = horas.floor();
    final minutos = ((horas - horasInt) * 60).round();
    
    if (horasInt > 0) {
      return '${horasInt}h ${minutos}min';
    } else {
      return '${minutos}min';
    }
  }
  
  /// Formata volume em litros
  static String formatarVolume(double litros) {
    if (litros >= 1000) {
      return '${(litros / 1000).toStringAsFixed(1)} m³';
    } else {
      return '${litros.toStringAsFixed(1)} L';
    }
  }
  
  /// Formata área em hectares
  static String formatarArea(double hectares) {
    return '${hectares.toStringAsFixed(2)} ha';
  }
  
  /// Formata custo em reais
  static String formatarCusto(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
  
  /// Formata velocidade em km/h
  static String formatarVelocidade(double velocidadeKmh) {
    return '${velocidadeKmh.toStringAsFixed(1)} km/h';
  }
  
  /// Formata vazão em L/min
  static String formatarVazao(double vazaoLMin) {
    return '${vazaoLMin.toStringAsFixed(1)} L/min';
  }
  
  /// Formata dose por hectare
  static String formatarDose(double dose, String unidade) {
    return '${dose.toStringAsFixed(2)} $unidade';
  }
  
  /// Formata percentual
  static String formatarPercentual(double percentual) {
    return '${percentual.toStringAsFixed(1)}%';
  }
}
