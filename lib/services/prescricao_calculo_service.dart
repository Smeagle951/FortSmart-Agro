import '../models/prescricao_model.dart';
import '../utils/logger.dart';

/// Serviço para cálculos de prescrição agronômica
class PrescricaoCalculoService {
  
  /// Calcula todos os resultados da prescrição
  static PrescricaoCalculoResult calcularPrescricao(PrescricaoModel prescricao) {
    try {
      Logger.info('🔄 Iniciando cálculo da prescrição ${prescricao.id}');
      
      // Validar se a prescrição está pronta para cálculo
      if (!prescricao.isReadyForCalculation) {
        throw Exception('Prescrição não está pronta para cálculo');
      }
      
      // Calcular resultados básicos
      final resultados = _calcularResultadosBasicos(prescricao);
      
      // Calcular produtos por tanque
      final produtosCalculados = _calcularProdutosPorTanque(prescricao, resultados);
      
      // Calcular totais e custos
      final totais = _calcularTotais(prescricao, produtosCalculados);
      
      Logger.info('✅ Cálculo da prescrição concluído com sucesso');
      
      return PrescricaoCalculoResult(
        resultados: resultados,
        produtosCalculados: produtosCalculados,
        totais: totais,
        sucesso: true,
      );
    } catch (e) {
      Logger.error('❌ Erro no cálculo da prescrição: $e');
      return PrescricaoCalculoResult(
        sucesso: false,
        erro: e.toString(),
      );
    }
  }
  
  /// Calcula os resultados básicos (ha/tanque, número de tanques, etc.)
  static ResultadosCalculoModel _calcularResultadosBasicos(PrescricaoModel prescricao) {
    final capacidadeEfetivaL = prescricao.capacidadeEfetivaL;
    final volumeLHa = prescricao.volumeLHa;
    final areaTrabalhoHa = prescricao.areaTrabalhoHa;
    
    // Ha por tanque
    final haPorTanque = capacidadeEfetivaL / volumeLHa;
    
    // Número de tanques (arredondado para cima)
    final numeroTanques = (areaTrabalhoHa / haPorTanque).ceil();
    
    // Volume por tanque
    final volumePorTanqueL = capacidadeEfetivaL;
    
    // Vazão total (da calibração ou padrão)
    double vazaoTotalLMin = 0;
    if (prescricao.calibracao != null) {
      vazaoTotalLMin = prescricao.calibracao!.vazaoTotalCalculadaLMin;
    } else {
      // Vazão padrão se não houver calibração
      vazaoTotalLMin = 20.0; // L/min padrão
    }
    
    // Tempo por tanque
    final tempoPorTanqueMin = vazaoTotalLMin > 0 ? volumePorTanqueL / vazaoTotalLMin : 0;
    
    // Capacidade de campo
    double capacidadeCampoHaH = 0;
    if (prescricao.calibracao != null) {
      final calibracao = prescricao.calibracao!;
      capacidadeCampoHaH = (calibracao.velocidadeKmh * calibracao.larguraM) / 10 * calibracao.eficienciaCampo;
    }
    
    // Tempo total
    final tempoTotalH = capacidadeCampoHaH > 0 ? areaTrabalhoHa / capacidadeCampoHaH : 0;
    
    return ResultadosCalculoModel(
      haPorTanque: haPorTanque,
      numeroTanques: numeroTanques,
      volumePorTanqueL: volumePorTanqueL,
      vazaoTotalLMin: vazaoTotalLMin,
      tempoPorTanqueMin: tempoPorTanqueMin.toDouble(),
      tempoTotalH: tempoTotalH.toDouble(),
      capacidadeCampoHaH: capacidadeCampoHaH,
      eficienciaCampo: prescricao.calibracao?.eficienciaCampo ?? 0.85,
    );
  }
  
  /// Calcula as quantidades de produtos por tanque
  static List<PrescricaoProdutoModel> _calcularProdutosPorTanque(
    PrescricaoModel prescricao,
    ResultadosCalculoModel resultados,
  ) {
    final produtosCalculados = <PrescricaoProdutoModel>[];
    final haPorTanque = resultados.haPorTanque;
    final volumeCaldaPorTanqueL = resultados.volumePorTanqueL;
    final areaTrabalhoHa = prescricao.areaTrabalhoHa;
    final numeroTanques = resultados.numeroTanques;
    
    for (final produto in prescricao.produtos) {
      // Calcular quantidade total
      final quantidadeTotal = produto.calcularQuantidadeTotal(areaTrabalhoHa);
      
      // Calcular quantidade por tanque
      final quantidadePorTanque = produto.calcularQuantidadePorTanque(haPorTanque, volumeCaldaPorTanqueL);
      
      // Calcular quantidade do último tanque (se parcial)
      double quantidadeUltimoTanque = quantidadePorTanque;
      if (numeroTanques > 1) {
        final areaUltimoTanque = areaTrabalhoHa - (haPorTanque * (numeroTanques - 1));
        if (areaUltimoTanque > 0 && areaUltimoTanque < haPorTanque) {
          quantidadeUltimoTanque = produto.calcularQuantidadePorTanque(areaUltimoTanque, volumeCaldaPorTanqueL);
        }
      }
      
      // Criar produto calculado
      final produtoCalculado = produto.copyWith(
        quantidadeTotal: quantidadeTotal,
        quantidadePorTanque: quantidadePorTanque,
        quantidadeUltimoTanque: quantidadeUltimoTanque,
      );
      
      produtosCalculados.add(produtoCalculado);
    }
    
    return produtosCalculados;
  }
  
  /// Calcula os totais e custos
  static TotaisPrescricaoModel _calcularTotais(
    PrescricaoModel prescricao,
    List<PrescricaoProdutoModel> produtosCalculados,
  ) {
    final areaTrabalhoHa = prescricao.areaTrabalhoHa;
    final volumeLHa = prescricao.volumeLHa;
    
    // Calcular custos por produto
    final custosPorProduto = <String, double>{};
    double custoTotal = 0;
    
    for (final produto in produtosCalculados) {
      if (produto.custoUnitario != null && produto.quantidadeTotal != null) {
        final custoProduto = produto.custoUnitario! * produto.quantidadeTotal!;
        custosPorProduto[produto.produtoNome] = custoProduto;
        custoTotal += custoProduto;
      }
    }
    
    // Custo por hectare
    final custoPorHa = areaTrabalhoHa > 0 ? custoTotal / areaTrabalhoHa : 0;
    
    // Volume total de calda
    final volumeTotalCaldaL = areaTrabalhoHa * volumeLHa;
    
    return TotaisPrescricaoModel(
      custoPorHa: custoPorHa.toDouble(),
      custoTotal: custoTotal,
      volumeTotalCaldaL: volumeTotalCaldaL,
      custosPorProduto: custosPorProduto,
    );
  }
  
  /// Valida a calibração e retorna diferença percentual
  static double validarCalibracao(PrescricaoModel prescricao) {
    if (prescricao.calibracao == null) return 0;
    
    final volumeAlvo = prescricao.volumeLHa;
    final volumeCalculado = prescricao.calibracao!.calcularVolumeTeoricoLHa();
    
    if (volumeAlvo <= 0) return 0;
    
    final diferenca = ((volumeCalculado - volumeAlvo) / volumeAlvo) * 100;
    return diferenca.abs();
  }
  
  /// Verifica se há problemas de estoque
  static List<String> verificarProblemasEstoque(List<PrescricaoProdutoModel> produtos) {
    final problemas = <String>[];
    
    for (final produto in produtos) {
      if (!produto.temEstoqueSuficiente) {
        problemas.add('${produto.produtoNome}: Estoque insuficiente');
      }
    }
    
    return problemas;
  }
  
  /// Calcula a vazão por bico necessária para um volume alvo
  static double calcularVazaoBicoNecessaria(
    double volumeAlvoLHa,
    double velocidadeKmh,
    double espacamentoM,
  ) {
    if (velocidadeKmh <= 0 || espacamentoM <= 0) return 0;
    return (volumeAlvoLHa * velocidadeKmh * espacamentoM) / 600;
  }
  
  /// Calcula o volume teórico a partir da vazão
  static double calcularVolumeTeorico(
    double vazaoTotalLMin,
    double velocidadeKmh,
    double larguraM,
  ) {
    if (vazaoTotalLMin <= 0 || velocidadeKmh <= 0 || larguraM <= 0) return 0;
    return (600 * vazaoTotalLMin) / (velocidadeKmh * larguraM);
  }
  
  /// Calcula a capacidade de campo
  static double calcularCapacidadeCampo(
    double velocidadeKmh,
    double larguraM,
    double eficienciaCampo,
  ) {
    return (velocidadeKmh * larguraM) / 10 * eficienciaCampo;
  }
  
  /// Calcula o tempo total de aplicação
  static double calcularTempoTotal(
    double areaHa,
    double capacidadeCampoHaH,
  ) {
    if (capacidadeCampoHaH <= 0) return 0;
    return areaHa / capacidadeCampoHaH;
  }
  
  /// Converte unidades de produto
  static double converterUnidade(
    double valor,
    String unidadeOrigem,
    String unidadeDestino,
    double? densidade,
  ) {
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
  
  /// Formata valores para exibição
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
}

/// Resultado do cálculo de prescrição
class PrescricaoCalculoResult {
  final bool sucesso;
  final String? erro;
  final ResultadosCalculoModel? resultados;
  final List<PrescricaoProdutoModel>? produtosCalculados;
  final TotaisPrescricaoModel? totais;
  
  PrescricaoCalculoResult({
    required this.sucesso,
    this.erro,
    this.resultados,
    this.produtosCalculados,
    this.totais,
  });
  
  /// Verifica se há problemas de estoque
  List<String> get problemasEstoque {
    if (produtosCalculados == null) return [];
    return PrescricaoCalculoService.verificarProblemasEstoque(produtosCalculados!);
  }
  
  /// Verifica se há problemas de calibração
  double? get diferencaCalibracao {
    // Esta função precisaria da prescrição original
    // Será implementada no contexto onde a prescrição está disponível
    return null;
  }
}
