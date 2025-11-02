import 'dart:math';

/// Serviço de cálculo profissional para prescrições agronômicas
/// Implementa todas as fórmulas profissionais para cálculo de calda, tanques e produtos
class PrescricaoCalculoProfissionalService {
  
  /// Resultado do cálculo de prescrição
  static PrescricaoCalculoResultado calcularPrescricao({
    required double areaHa,
    required double vazaoLHa,
    required double capacidadeTanqueL,
    required List<PrescricaoProduto> produtos,
    required bool permitirFracao,
    String tipoAplicacao = 'Terrestre',
    double? volumeSegurancaL,
    // Parâmetros opcionais para calibração terrestre
    double? nozzleQLMin,
    int? numNozzles,
    double? velocidadeKmh,
    double? espacamentoM,
  }) {
    
    // Validações básicas
    if (areaHa <= 0) {
      return PrescricaoCalculoResultado.erro('Área deve ser maior que zero');
    }
    if (vazaoLHa <= 0) {
      return PrescricaoCalculoResultado.erro('Vazão deve ser maior que zero');
    }
    if (capacidadeTanqueL <= 0) {
      return PrescricaoCalculoResultado.erro('Capacidade do tanque deve ser maior que zero');
    }
    if (produtos.isEmpty) {
      return PrescricaoCalculoResultado.erro('Adicione pelo menos um produto');
    }

    try {
      // 1. Volume total da calda (L)
      final volumeTotalL = areaHa * vazaoLHa;
      
      // 2. Número de tanques/voos
      final nTanquesRaw = volumeTotalL / capacidadeTanqueL;
      final nTanques = permitirFracao 
          ? double.parse(nTanquesRaw.toStringAsFixed(1))
          : nTanquesRaw.ceil().toDouble();
      
      // 3. Calcular produtos
      final produtosCalculados = <PrescricaoProdutoCalculado>[];
      final alertasEstoque = <String>[];
      
      for (final produto in produtos) {
        // Quantidade total necessária de cada produto
        final produtoTotal = produto.doseHa * areaHa;
        
        // Concentração (produto por litro de calda)
        final concentracao = produtoTotal / volumeTotalL;
        
        // Verificar estoque
        if (produto.estoqueDisponivel < produtoTotal) {
          final falta = produtoTotal - produto.estoqueDisponivel;
          alertasEstoque.add(
            'Estoque insuficiente para ${produto.nome}: faltam ${falta.toStringAsFixed(2)} ${produto.unidade}'
          );
        }
        
        // Calcular produto por tanque
        final produtoPorTanque = _calcularProdutoPorTanque(
          concentracao: concentracao,
          volumeTotalL: volumeTotalL,
          capacidadeTanqueL: capacidadeTanqueL,
          nTanques: nTanques,
          permitirFracao: permitirFracao,
        );
        
        produtosCalculados.add(PrescricaoProdutoCalculado(
          produto: produto,
          produtoTotal: produtoTotal,
          concentracao: concentracao,
          produtoPorTanque: produtoPorTanque,
          estoqueSuficiente: produto.estoqueDisponivel >= produtoTotal,
        ));
      }
      
      // 4. Calcular volumes por tanque
      final volumesPorTanque = _calcularVolumesPorTanque(
        volumeTotalL: volumeTotalL,
        capacidadeTanqueL: capacidadeTanqueL,
        nTanques: nTanques,
        permitirFracao: permitirFracao,
      );
      
      // 5. Calcular tempo de descarga (se parâmetros de calibração disponíveis)
      double? tempoDescargaMinutos;
      if (nozzleQLMin != null && numNozzles != null) {
        final vazaoTotalBicosLMin = nozzleQLMin * numNozzles;
        tempoDescargaMinutos = capacidadeTanqueL / vazaoTotalBicosLMin;
      }
      
      // 6. Calcular vazão sugerida (se parâmetros de calibração disponíveis)
      double? vazaoSugeridaLHa;
      if (nozzleQLMin != null && velocidadeKmh != null && espacamentoM != null) {
        vazaoSugeridaLHa = (600 * nozzleQLMin) / (velocidadeKmh * espacamentoM);
      }
      
      // 7. Criar totais
      final totais = PrescricaoTotais(
        volumeTotalL: volumeTotalL,
        nTanques: nTanques,
        volumesPorTanque: volumesPorTanque,
        tempoDescargaMinutos: tempoDescargaMinutos,
        vazaoSugeridaLHa: vazaoSugeridaLHa,
        permitirFracao: permitirFracao,
        tipoAplicacao: tipoAplicacao,
      );
      
      return PrescricaoCalculoResultado.sucesso(
        produtosCalculados: produtosCalculados,
        totais: totais,
        alertasEstoque: alertasEstoque,
      );
      
    } catch (e) {
      return PrescricaoCalculoResultado.erro('Erro no cálculo: $e');
    }
  }
  
  /// Calcula o produto por tanque baseado na concentração
  static List<double> _calcularProdutoPorTanque({
    required double concentracao,
    required double volumeTotalL,
    required double capacidadeTanqueL,
    required double nTanques,
    required bool permitirFracao,
  }) {
    final produtoPorTanque = <double>[];
    
    if (permitirFracao) {
      // Com fração permitida
      final numTanquesInteiros = nTanques.floor();
      final volumeUltimoTanque = volumeTotalL - (numTanquesInteiros * capacidadeTanqueL);
      
      // Tanques cheios
      for (int i = 0; i < numTanquesInteiros; i++) {
        produtoPorTanque.add(concentracao * capacidadeTanqueL);
      }
      
      // Último tanque (se houver volume restante)
      if (volumeUltimoTanque > 0) {
        produtoPorTanque.add(concentracao * volumeUltimoTanque);
      }
    } else {
      // Sem fração - distribuir igualmente
      final produtoPorTanqueIgual = (concentracao * volumeTotalL) / nTanques;
      for (int i = 0; i < nTanques.toInt(); i++) {
        produtoPorTanque.add(produtoPorTanqueIgual);
      }
    }
    
    return produtoPorTanque;
  }
  
  /// Calcula os volumes por tanque
  static List<double> _calcularVolumesPorTanque({
    required double volumeTotalL,
    required double capacidadeTanqueL,
    required double nTanques,
    required bool permitirFracao,
  }) {
    final volumesPorTanque = <double>[];
    
    if (permitirFracao) {
      final numTanquesInteiros = nTanques.floor();
      final volumeUltimoTanque = volumeTotalL - (numTanquesInteiros * capacidadeTanqueL);
      
      // Tanques cheios
      for (int i = 0; i < numTanquesInteiros; i++) {
        volumesPorTanque.add(capacidadeTanqueL);
      }
      
      // Último tanque (se houver volume restante)
      if (volumeUltimoTanque > 0) {
        volumesPorTanque.add(volumeUltimoTanque);
      }
    } else {
      // Sem fração - todos os tanques com capacidade total
      for (int i = 0; i < nTanques.toInt(); i++) {
        volumesPorTanque.add(capacidadeTanqueL);
      }
    }
    
    return volumesPorTanque;
  }
  
  /// Valida se os parâmetros de calibração são consistentes
  static ValidacaoCalibracao validarCalibracao({
    required double vazaoLHa,
    double? nozzleQLMin,
    int? numNozzles,
    double? velocidadeKmh,
    double? espacamentoM,
  }) {
    if (nozzleQLMin == null || velocidadeKmh == null || espacamentoM == null) {
      return ValidacaoCalibracao(
        valida: false,
        mensagem: 'Parâmetros de calibração incompletos',
      );
    }
    
    final vazaoCalculada = (600 * nozzleQLMin) / (velocidadeKmh * espacamentoM);
    final diferenca = (vazaoCalculada - vazaoLHa).abs();
    final percentualDiferenca = (diferenca / vazaoLHa) * 100;
    
    if (percentualDiferenca > 10) {
      return ValidacaoCalibracao(
        valida: false,
        mensagem: 'Vazão calculada (${vazaoCalculada.toStringAsFixed(1)} L/ha) difere muito da desejada (${vazaoLHa.toStringAsFixed(1)} L/ha)',
        vazaoCalculada: vazaoCalculada,
      );
    }
    
    return ValidacaoCalibracao(
      valida: true,
      mensagem: 'Calibração consistente',
      vazaoCalculada: vazaoCalculada,
    );
  }
}

/// Modelo para produto de prescrição
class PrescricaoProduto {
  final String id;
  final String nome;
  final String tipo;
  final String unidade;
  final double doseHa;
  final double estoqueDisponivel;
  final double precoUnitario;
  final String? lote;
  
  PrescricaoProduto({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidade,
    required this.doseHa,
    required this.estoqueDisponivel,
    required this.precoUnitario,
    this.lote,
  });
}

/// Modelo para produto calculado
class PrescricaoProdutoCalculado {
  final PrescricaoProduto produto;
  final double produtoTotal;
  final double concentracao;
  final List<double> produtoPorTanque;
  final bool estoqueSuficiente;
  
  PrescricaoProdutoCalculado({
    required this.produto,
    required this.produtoTotal,
    required this.concentracao,
    required this.produtoPorTanque,
    required this.estoqueSuficiente,
  });
}

/// Modelo para totais da prescrição
class PrescricaoTotais {
  final double volumeTotalL;
  final double nTanques;
  final List<double> volumesPorTanque;
  final double? tempoDescargaMinutos;
  final double? vazaoSugeridaLHa;
  final bool permitirFracao;
  final String tipoAplicacao;
  final double? volumeResidualL;
  final double? custoPorHectare;
  final double? custoTotal;
  
  PrescricaoTotais({
    required this.volumeTotalL,
    required this.nTanques,
    required this.volumesPorTanque,
    this.tempoDescargaMinutos,
    this.vazaoSugeridaLHa,
    required this.permitirFracao,
    required this.tipoAplicacao,
    this.volumeResidualL,
    this.custoPorHectare,
    this.custoTotal,
  });
  
  /// Retorna o volume do último tanque (se fracionado)
  double? get volumeUltimoTanque {
    if (volumesPorTanque.isEmpty) return null;
    final ultimoVolume = volumesPorTanque.last;
    if (ultimoVolume < volumesPorTanque.first) {
      return ultimoVolume;
    }
    return null;
  }
  
  /// Retorna a porcentagem do último tanque
  double? get percentualUltimoTanque {
    final volumeUltimo = volumeUltimoTanque;
    if (volumeUltimo == null) return null;
    return (volumeUltimo / volumesPorTanque.first) * 100;
  }
}

/// Resultado do cálculo de prescrição
class PrescricaoCalculoResultado {
  final bool sucesso;
  final String? erro;
  final List<PrescricaoProdutoCalculado>? produtosCalculados;
  final PrescricaoTotais? totais;
  final List<String> alertasEstoque;
  
  PrescricaoCalculoResultado._({
    required this.sucesso,
    this.erro,
    this.produtosCalculados,
    this.totais,
    this.alertasEstoque = const [],
  });
  
  factory PrescricaoCalculoResultado.sucesso({
    required List<PrescricaoProdutoCalculado> produtosCalculados,
    required PrescricaoTotais totais,
    List<String> alertasEstoque = const [],
  }) {
    return PrescricaoCalculoResultado._(
      sucesso: true,
      produtosCalculados: produtosCalculados,
      totais: totais,
      alertasEstoque: alertasEstoque,
    );
  }
  
  factory PrescricaoCalculoResultado.erro(String erro) {
    return PrescricaoCalculoResultado._(
      sucesso: false,
      erro: erro,
    );
  }
}

/// Validação de calibração
class ValidacaoCalibracao {
  final bool valida;
  final String mensagem;
  final double? vazaoCalculada;
  
  ValidacaoCalibracao({
    required this.valida,
    required this.mensagem,
    this.vazaoCalculada,
  });
}
