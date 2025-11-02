import 'prescricao_formulas.dart';

/// Validações para prescrição agronômica
class PrescricaoValidators {
  
  /// Valida se um valor é maior que zero
  static String? validarMaiorQueZero(double? valor, String campo) {
    if (valor == null || valor <= 0) {
      return '$campo deve ser maior que zero';
    }
    return null;
  }
  
  /// Valida se um valor é maior ou igual a zero
  static String? validarMaiorOuIgualZero(double? valor, String campo) {
    if (valor == null || valor < 0) {
      return '$campo deve ser maior ou igual a zero';
    }
    return null;
  }
  
  /// Valida se um valor está dentro de um intervalo
  static String? validarIntervalo(double? valor, String campo, double min, double max) {
    if (valor == null) {
      return '$campo é obrigatório';
    }
    if (valor < min || valor > max) {
      return '$campo deve estar entre ${min.toStringAsFixed(1)} e ${max.toStringAsFixed(1)}';
    }
    return null;
  }
  
  /// Valida se um valor inteiro é maior que zero
  static String? validarInteiroMaiorQueZero(int? valor, String campo) {
    if (valor == null || valor <= 0) {
      return '$campo deve ser maior que zero';
    }
    return null;
  }
  
  /// Valida se uma string não está vazia
  static String? validarNaoVazio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return '$campo é obrigatório';
    }
    return null;
  }
  
  /// Valida se uma data não é nula
  static String? validarData(DateTime? data, String campo) {
    if (data == null) {
      return '$campo é obrigatório';
    }
    return null;
  }
  
  /// Valida velocidade para aplicação terrestre
  static String? validarVelocidadeTerrestre(double? velocidadeKmh) {
    if (velocidadeKmh == null) {
      return 'Velocidade é obrigatória';
    }
    if (!PrescricaoFormulas.isVelocidadeValidaTerrestre(velocidadeKmh)) {
      return 'Velocidade deve estar entre 3 e 18 km/h para aplicação terrestre';
    }
    return null;
  }
  
  /// Valida velocidade para aplicação aérea
  static String? validarVelocidadeAerea(double? velocidadeKmh) {
    if (velocidadeKmh == null) {
      return 'Velocidade é obrigatória';
    }
    if (!PrescricaoFormulas.isVelocidadeValidaAerea(velocidadeKmh)) {
      return 'Velocidade deve estar entre 80 e 200 km/h para aplicação aérea';
    }
    return null;
  }
  
  /// Valida velocidade para aplicação com drone
  static String? validarVelocidadeDrone(double? velocidadeKmh) {
    if (velocidadeKmh == null) {
      return 'Velocidade é obrigatória';
    }
    if (!PrescricaoFormulas.isVelocidadeValidaDrone(velocidadeKmh)) {
      return 'Velocidade deve estar entre 10 e 50 km/h para aplicação com drone';
    }
    return null;
  }
  
  /// Valida velocidade baseada no tipo de aplicação
  static String? validarVelocidadePorTipo(double? velocidadeKmh, String tipoAplicacao) {
    switch (tipoAplicacao.toLowerCase()) {
      case 'terrestre':
        return validarVelocidadeTerrestre(velocidadeKmh);
      case 'aérea':
      case 'aerea':
        return validarVelocidadeAerea(velocidadeKmh);
      case 'drone':
        return validarVelocidadeDrone(velocidadeKmh);
      default:
        return 'Tipo de aplicação inválido';
    }
  }
  
  /// Valida volume de calda por hectare
  static String? validarVolumeLHa(double? volumeLHa) {
    if (volumeLHa == null) {
      return 'Volume de calda é obrigatório';
    }
    if (volumeLHa <= 0) {
      return 'Volume de calda deve ser maior que zero';
    }
    if (volumeLHa > 1000) {
      return 'Volume de calda muito alto (máximo 1000 L/ha)';
    }
    return null;
  }
  
  /// Valida capacidade do tanque
  static String? validarCapacidadeTanque(double? capacidadeTanqueL) {
    if (capacidadeTanqueL == null) {
      return 'Capacidade do tanque é obrigatória';
    }
    if (capacidadeTanqueL <= 0) {
      return 'Capacidade do tanque deve ser maior que zero';
    }
    if (capacidadeTanqueL > 50000) {
      return 'Capacidade do tanque muito alta (máximo 50.000 L)';
    }
    return null;
  }
  
  /// Valida volume de segurança
  static String? validarVolumeSeguranca(double? volumeSegurancaL, double? capacidadeTanqueL) {
    if (volumeSegurancaL == null) {
      return null; // Volume de segurança é opcional
    }
    if (volumeSegurancaL < 0) {
      return 'Volume de segurança não pode ser negativo';
    }
    if (capacidadeTanqueL != null && volumeSegurancaL >= capacidadeTanqueL) {
      return 'Volume de segurança deve ser menor que a capacidade do tanque';
    }
    return null;
  }
  
  /// Valida área de trabalho
  static String? validarAreaTrabalho(double? areaTrabalhoHa, double? areaTalhaoHa) {
    if (areaTrabalhoHa == null) {
      return 'Área de trabalho é obrigatória';
    }
    if (areaTrabalhoHa <= 0) {
      return 'Área de trabalho deve ser maior que zero';
    }
    if (areaTalhaoHa != null && areaTrabalhoHa > areaTalhaoHa) {
      return 'Área de trabalho não pode ser maior que a área do talhão';
    }
    return null;
  }
  
  /// Valida número de bicos ativos
  static String? validarBicosAtivos(int? bicosAtivos) {
    if (bicosAtivos == null) {
      return 'Número de bicos é obrigatório';
    }
    if (bicosAtivos <= 0) {
      return 'Número de bicos deve ser maior que zero';
    }
    if (bicosAtivos > 100) {
      return 'Número de bicos muito alto (máximo 100)';
    }
    return null;
  }
  
  /// Valida espaçamento entre bicos
  static String? validarEspacamentoBicos(double? espacamentoM) {
    if (espacamentoM == null) {
      return 'Espaçamento entre bicos é obrigatório';
    }
    if (espacamentoM <= 0) {
      return 'Espaçamento entre bicos deve ser maior que zero';
    }
    if (espacamentoM > 2) {
      return 'Espaçamento entre bicos muito alto (máximo 2 m)';
    }
    return null;
  }
  
  /// Valida largura da barra
  static String? validarLarguraBarra(double? larguraM) {
    if (larguraM == null) {
      return 'Largura da barra é obrigatória';
    }
    if (larguraM <= 0) {
      return 'Largura da barra deve ser maior que zero';
    }
    if (larguraM > 50) {
      return 'Largura da barra muito alta (máximo 50 m)';
    }
    return null;
  }
  
  /// Valida vazão por bico
  static String? validarVazaoBico(double? vazaoBicoLMin) {
    if (vazaoBicoLMin == null) {
      return 'Vazão por bico é obrigatória';
    }
    if (vazaoBicoLMin <= 0) {
      return 'Vazão por bico deve ser maior que zero';
    }
    if (vazaoBicoLMin > 10) {
      return 'Vazão por bico muito alta (máximo 10 L/min)';
    }
    return null;
  }
  
  /// Valida vazão total
  static String? validarVazaoTotal(double? vazaoTotalLMin) {
    if (vazaoTotalLMin == null) {
      return 'Vazão total é obrigatória';
    }
    if (vazaoTotalLMin <= 0) {
      return 'Vazão total deve ser maior que zero';
    }
    if (vazaoTotalLMin > 1000) {
      return 'Vazão total muito alta (máximo 1000 L/min)';
    }
    return null;
  }
  
  /// Valida dose por hectare
  static String? validarDosePorHa(double? dosePorHa, String unidade) {
    if (dosePorHa == null) {
      return 'Dose por hectare é obrigatória';
    }
    if (dosePorHa <= 0) {
      return 'Dose por hectare deve ser maior que zero';
    }
    
    // Validações específicas por unidade
    switch (unidade.toLowerCase()) {
      case 'l/ha':
        if (dosePorHa > 100) {
          return 'Dose muito alta (máximo 100 L/ha)';
        }
        break;
      case 'kg/ha':
        if (dosePorHa > 50) {
          return 'Dose muito alta (máximo 50 kg/ha)';
        }
        break;
      case 'g/ha':
        if (dosePorHa > 50000) {
          return 'Dose muito alta (máximo 50.000 g/ha)';
        }
        break;
      case 'ml/ha':
        if (dosePorHa > 100000) {
          return 'Dose muito alta (máximo 100.000 mL/ha)';
        }
        break;
    }
    
    return null;
  }
  
  /// Valida percentual de adjuvante
  static String? validarPercentualAdjuvante(double? percentualVv) {
    if (percentualVv == null) {
      return null; // Percentual é opcional
    }
    if (percentualVv < 0) {
      return 'Percentual não pode ser negativo';
    }
    if (percentualVv > 10) {
      return 'Percentual muito alto (máximo 10%)';
    }
    return null;
  }
  
  /// Valida densidade do produto
  static String? validarDensidade(double? densidade) {
    if (densidade == null) {
      return null; // Densidade é opcional
    }
    if (densidade <= 0) {
      return 'Densidade deve ser maior que zero';
    }
    if (densidade > 3) {
      return 'Densidade muito alta (máximo 3 kg/L)';
    }
    return null;
  }
  
  /// Valida custo unitário
  static String? validarCustoUnitario(double? custoUnitario) {
    if (custoUnitario == null) {
      return null; // Custo é opcional
    }
    if (custoUnitario < 0) {
      return 'Custo não pode ser negativo';
    }
    if (custoUnitario > 10000) {
      return 'Custo muito alto (máximo R\$ 10.000,00)';
    }
    return null;
  }
  
  /// Valida se há estoque suficiente
  static String? validarEstoqueSuficiente({
    required double estoqueDisponivel,
    required double quantidadeNecessaria,
    required String produtoNome,
  }) {
    if (!PrescricaoFormulas.isEstoqueSuficiente(
      estoqueDisponivel: estoqueDisponivel,
      quantidadeNecessaria: quantidadeNecessaria,
    )) {
      return 'Estoque insuficiente para $produtoNome (disponível: ${estoqueDisponivel.toStringAsFixed(2)}, necessário: ${quantidadeNecessaria.toStringAsFixed(2)})';
    }
    return null;
  }
  
  /// Valida se o estoque está baixo
  static String? validarEstoqueBaixo({
    required double estoqueDisponivel,
    required double quantidadeNecessaria,
    required String produtoNome,
  }) {
    if (PrescricaoFormulas.isEstoqueBaixo(
      estoqueDisponivel: estoqueDisponivel,
      quantidadeNecessaria: quantidadeNecessaria,
    )) {
      final margemSeguranca = PrescricaoFormulas.calcularMargemSegurancaEstoque(quantidadeNecessaria);
      return 'Estoque baixo para $produtoNome (recomendado: ${margemSeguranca.toStringAsFixed(2)})';
    }
    return null;
  }
  
  /// Valida diferença de calibração
  static String? validarDiferencaCalibracao({
    required double volumeAlvoLHa,
    required double volumeCalculadoLHa,
  }) {
    final diferenca = PrescricaoFormulas.calcularDiferencaCalibracao(
      volumeAlvoLHa: volumeAlvoLHa,
      volumeCalculadoLHa: volumeCalculadoLHa,
    );
    
    if (!PrescricaoFormulas.isCalibracaoAceitavel(diferenca)) {
      return 'Diferença de calibração muito alta (${diferenca.toStringAsFixed(1)}% > 3%). Verifique os parâmetros.';
    }
    return null;
  }
  
  /// Valida se a prescrição está pronta para cálculo
  static List<String> validarPrescricaoParaCalculo({
    required bool talhaoSelecionado,
    required double volumeLHa,
    required double capacidadeTanqueL,
    required double areaTrabalhoHa,
    required int numeroProdutos,
    required String tipoAplicacao,
    double? velocidadeKmh,
    double? larguraM,
    double? vazaoTotalLMin,
  }) {
    final erros = <String>[];
    
    if (!talhaoSelecionado) {
      erros.add('Selecione um talhão');
    }
    
    if (volumeLHa <= 0) {
      erros.add('Volume de calda deve ser maior que zero');
    }
    
    if (capacidadeTanqueL <= 0) {
      erros.add('Capacidade do tanque deve ser maior que zero');
    }
    
    if (areaTrabalhoHa <= 0) {
      erros.add('Área de trabalho deve ser maior que zero');
    }
    
    if (numeroProdutos == 0) {
      erros.add('Adicione pelo menos um produto');
    }
    
    // Validações específicas por tipo de aplicação
    switch (tipoAplicacao.toLowerCase()) {
      case 'terrestre':
        if (velocidadeKmh == null || velocidadeKmh <= 0) {
          erros.add('Velocidade é obrigatória para aplicação terrestre');
        }
        if (larguraM == null || larguraM <= 0) {
          erros.add('Largura da barra é obrigatória para aplicação terrestre');
        }
        if (vazaoTotalLMin == null || vazaoTotalLMin <= 0) {
          erros.add('Vazão total é obrigatória para aplicação terrestre');
        }
        break;
      case 'aérea':
      case 'aerea':
        if (velocidadeKmh == null || velocidadeKmh <= 0) {
          erros.add('Velocidade é obrigatória para aplicação aérea');
        }
        if (larguraM == null || larguraM <= 0) {
          erros.add('Faixa de aplicação é obrigatória para aplicação aérea');
        }
        if (vazaoTotalLMin == null || vazaoTotalLMin <= 0) {
          erros.add('Vazão total é obrigatória para aplicação aérea');
        }
        break;
      case 'drone':
        if (velocidadeKmh == null || velocidadeKmh <= 0) {
          erros.add('Velocidade é obrigatória para aplicação com drone');
        }
        if (larguraM == null || larguraM <= 0) {
          erros.add('Largura efetiva é obrigatória para aplicação com drone');
        }
        if (vazaoTotalLMin == null || vazaoTotalLMin <= 0) {
          erros.add('Vazão total é obrigatória para aplicação com drone');
        }
        break;
    }
    
    return erros;
  }
  
  /// Valida se a prescrição pode ser finalizada
  static List<String> validarPrescricaoParaFinalizacao({
    required bool calculoRealizado,
    required List<String> problemasEstoque,
    required double? diferencaCalibracao,
  }) {
    final erros = <String>[];
    
    if (!calculoRealizado) {
      erros.add('Calcule a prescrição antes de finalizar');
    }
    
    if (problemasEstoque.isNotEmpty) {
      erros.addAll(problemasEstoque);
    }
    
    if (diferencaCalibracao != null && diferencaCalibracao > 3) {
      erros.add('Diferença de calibração muito alta (${diferencaCalibracao.toStringAsFixed(1)}%). Ajuste os parâmetros.');
    }
    
    return erros;
  }
}
