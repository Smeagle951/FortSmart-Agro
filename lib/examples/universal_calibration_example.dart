import '../services/universal_calibration_service.dart';

/// Exemplo de uso do serviço universal de calibração
class UniversalCalibrationExample {
  
  /// Exemplo com Jan Lancer 1350
  static void exemploJanLancer1350() {
    print('=== EXEMPLO: Jan Lancer 1350 ===');
    
    // Dados reais que o usuário inseriria:
    // - Tempo: 45 segundos
    // - Largura: 30.0 m (padrão da máquina)
    // - Velocidade: 12 km/h
    // - Valor coletado: 15.5 kg
    // - Taxa desejada: 180 kg/ha
    
    try {
      // Validar dados primeiro
      final validacao = UniversalCalibrationService.validarDados(
        tipoMaquina: 'jan_lancer_1350',
        tempoSegundos: 45.0,
        larguraFaixa: 30.0,
        velocidadeKmh: 12.0,
        valorColetadoKg: 15.5,
        taxaDesejadaKgHa: 180.0,
      );
      
      print('Validação dos dados:');
      print('  Válido: ${validacao['valido']}');
      print('  Alertas: ${validacao['alertas']}');
      print('  Avisos: ${validacao['avisos']}');
      print('  Taxa esperada: ${validacao['taxa_esperada']} kg/ha');
      print('  Modelo: ${validacao['modelo_maquina']}');
      print('');
      
      if (!validacao['valido']) {
        print('❌ Dados inválidos - não é possível calcular');
        return;
      }
      
      // Calcular resultado
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: 'jan_lancer_1350',
        tempoSegundos: 45.0,
        larguraFaixa: 30.0,
        velocidadeKmh: 12.0,
        valorColetadoKg: 15.5,
        taxaDesejadaKgHa: 180.0,
        aberturaAtual: 60.0, // 60% de abertura
      );
      
      print('Resultado da calibração Jan Lancer 1350:');
      print('  Máquina: ${resultado.modeloMaquina}');
      print('  Sistema: ${resultado.infoMaquina['sistema']}');
      print('  Distância percorrida: ${resultado.distanciaPercorrida} m');
      print('  Área coberta: ${resultado.areaCoberta} m²');
      print('  Área em hectares: ${resultado.areaHectares} ha');
      print('  Taxa real aplicada: ${resultado.taxaRealAplicada} kg/ha');
      print('  Erro percentual: ${resultado.erroPercentual}%');
      print('  Status: ${resultado.statusTolerancia}');
      print('  Recomendação: ${resultado.recomendacaoAjuste}');
      print('  Abertura sugerida: ${resultado.aberturaSugerida}%');
      print('  Precisa recalibrar: ${resultado.precisaRecalibrar}');
      
    } catch (e) {
      print('❌ Erro no cálculo: $e');
    }
  }
  
  /// Exemplo com Stara Tornado 1300 (dados da imagem)
  static void exemploStaraTornado1300() {
    print('\n=== EXEMPLO: Stara Tornado 1300 (Dados da Imagem) ===');
    
    // Dados da imagem fornecida:
    // - Tempo: 30 segundos
    // - Largura: 27.0 m
    // - Velocidade: 8 km/h
    // - Valor coletado: 25 kg
    // - Taxa desejada: 140 kg/ha
    
    try {
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: 'stara_tornado_1300',
        tempoSegundos: 30.0,
        larguraFaixa: 27.0,
        velocidadeKmh: 8.0,
        valorColetadoKg: 25.0,
        taxaDesejadaKgHa: 140.0,
        aberturaAtual: 50.0,
      );
      
      print('Resultado com dados da imagem:');
      print('  Máquina: ${resultado.modeloMaquina}');
      print('  Distância percorrida: ${resultado.distanciaPercorrida} m');
      print('  Área coberta: ${resultado.areaCoberta} m²');
      print('  Área em hectares: ${resultado.areaHectares} ha');
      print('  Taxa real aplicada: ${resultado.taxaRealAplicada} kg/ha');
      print('  Erro percentual: ${resultado.erroPercentual}%');
      print('  Status: ${resultado.statusTolerancia}');
      print('  Recomendação: ${resultado.recomendacaoAjuste}');
      print('  Abertura sugerida: ${resultado.aberturaSugerida}%');
      print('  Precisa recalibrar: ${resultado.precisaRecalibrar}');
      
    } catch (e) {
      print('❌ Erro no cálculo: $e');
    }
  }
  
  /// Exemplo com Kuhn Accura 1200
  static void exemploKuhnAccura1200() {
    print('\n=== EXEMPLO: Kuhn Accura 1200 ===');
    
    try {
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: 'kuhn_accura_1200',
        tempoSegundos: 60.0,
        larguraFaixa: 24.0,
        velocidadeKmh: 10.0,
        valorColetadoKg: 12.0,
        taxaDesejadaKgHa: 150.0,
        aberturaAtual: 55.0,
      );
      
      print('Resultado Kuhn Accura 1200:');
      print('  Máquina: ${resultado.modeloMaquina}');
      print('  Sistema: ${resultado.infoMaquina['sistema']}');
      print('  Distância percorrida: ${resultado.distanciaPercorrida} m');
      print('  Área coberta: ${resultado.areaCoberta} m²');
      print('  Área em hectares: ${resultado.areaHectares} ha');
      print('  Taxa real aplicada: ${resultado.taxaRealAplicada} kg/ha');
      print('  Erro percentual: ${resultado.erroPercentual}%');
      print('  Status: ${resultado.statusTolerancia}');
      print('  Recomendação: ${resultado.recomendacaoAjuste}');
      print('  Abertura sugerida: ${resultado.aberturaSugerida}%');
      print('  Precisa recalibrar: ${resultado.precisaRecalibrar}');
      
    } catch (e) {
      print('❌ Erro no cálculo: $e');
    }
  }
  
  /// Exemplo com máquina personalizada
  static void exemploMaquinaPersonalizada() {
    print('\n=== EXEMPLO: Máquina Personalizada ===');
    
    try {
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: 'personalizada',
        tempoSegundos: 40.0,
        larguraFaixa: 28.0, // Largura definida pelo usuário
        velocidadeKmh: 9.0,
        valorColetadoKg: 18.0,
        taxaDesejadaKgHa: 200.0,
        aberturaAtual: 65.0,
      );
      
      print('Resultado Máquina Personalizada:');
      print('  Máquina: ${resultado.modeloMaquina}');
      print('  Sistema: ${resultado.infoMaquina['sistema']}');
      print('  Distância percorrida: ${resultado.distanciaPercorrida} m');
      print('  Área coberta: ${resultado.areaCoberta} m²');
      print('  Área em hectares: ${resultado.areaHectares} ha');
      print('  Taxa real aplicada: ${resultado.taxaRealAplicada} kg/ha');
      print('  Erro percentual: ${resultado.erroPercentual}%');
      print('  Status: ${resultado.statusTolerancia}');
      print('  Recomendação: ${resultado.recomendacaoAjuste}');
      print('  Abertura sugerida: ${resultado.aberturaSugerida}%');
      print('  Precisa recalibrar: ${resultado.precisaRecalibrar}');
      
    } catch (e) {
      print('❌ Erro no cálculo: $e');
    }
  }
  
  /// Lista todas as máquinas disponíveis
  static void listarMaquinasDisponiveis() {
    print('\n=== MÁQUINAS DISPONÍVEIS ===');
    
    final maquinas = UniversalCalibrationService.listarMaquinasDisponiveis();
    
    for (final maquina in maquinas) {
      print('• ${maquina['modelo']}');
      print('  - Tipo: ${maquina['tipo']}');
      print('  - Sistema: ${maquina['sistema']}');
      print('  - Largura padrão: ${maquina['largura_padrao']}m');
      print('');
    }
  }
  
  /// Executa todos os exemplos
  static void executarTodosExemplos() {
    print('🚜 EXEMPLOS DE CALIBRAÇÃO UNIVERSAL 🚜\n');
    
    listarMaquinasDisponiveis();
    exemploJanLancer1350();
    exemploStaraTornado1300();
    exemploKuhnAccura1200();
    exemploMaquinaPersonalizada();
    
    print('\n✅ Todos os exemplos executados!');
  }
}
