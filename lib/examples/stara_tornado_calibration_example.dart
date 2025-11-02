import '../services/stara_tornado_calibration_service.dart';

/// Exemplo de uso do serviço de calibração da Stara Tornado 1300
class StaraTornadoCalibrationExample {
  
  /// Exemplo com os dados da imagem fornecida
  static void exemploComDadosDaImagem() {
    print('=== EXEMPLO: Dados da Imagem ===');
    
    // Dados da imagem:
    // - Tempo: 30 segundos
    // - Largura: 27.0 m
    // - Velocidade: 8 km/h
    // - Valor coletado: 25 kg
    // - Taxa desejada: 140 kg/ha
    
    try {
      // Validar dados primeiro
      final validacao = StaraTornadoCalibrationService.validarDados(
        tempoSegundos: 30.0,
        larguraFaixa: 27.0,
        velocidadeKmh: 8.0,
        valorColetadoKg: 25.0,
        taxaDesejadaKgHa: 140.0,
      );
      
      print('Validação dos dados:');
      print('  Válido: ${validacao['valido']}');
      print('  Alertas: ${validacao['alertas']}');
      print('  Avisos: ${validacao['avisos']}');
      print('  Taxa esperada: ${validacao['taxa_esperada']} kg/ha');
      print('');
      
      if (!validacao['valido']) {
        print('❌ Dados inválidos - não é possível calcular');
        return;
      }
      
      // Calcular resultado
      final resultado = StaraTornadoCalibrationService.calcularCalibracao(
        tempoSegundos: 30.0,
        larguraFaixa: 27.0,
        velocidadeKmh: 8.0,
        valorColetadoKg: 25.0,
        taxaDesejadaKgHa: 140.0,
        aberturaAtual: 50.0, // 50% de abertura
      );
      
      print('Resultado da calibração:');
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
  
  /// Exemplo com dados mais realistas para Stara Tornado 1300
  static void exemploDadosRealistas() {
    print('\n=== EXEMPLO: Dados Realistas ===');
    
    // Dados mais realistas para uma Stara Tornado 1300:
    // - Tempo: 60 segundos (mais tempo para coleta)
    // - Largura: 27.0 m (padrão da máquina)
    // - Velocidade: 10 km/h (velocidade recomendada)
    // - Valor coletado: 8.5 kg (mais realista para abertura pequena)
    // - Taxa desejada: 140 kg/ha
    
    try {
      final resultado = StaraTornadoCalibrationService.calcularCalibracao(
        tempoSegundos: 60.0,
        larguraFaixa: 27.0,
        velocidadeKmh: 10.0,
        valorColetadoKg: 8.5,
        taxaDesejadaKgHa: 140.0,
        aberturaAtual: 45.0,
      );
      
      print('Resultado com dados realistas:');
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
  
  /// Exemplo demonstrando validação de dados
  static void exemploValidacao() {
    print('\n=== EXEMPLO: Validação de Dados ===');
    
    // Teste com dados problemáticos
    final casos = [
      {
        'nome': 'Velocidade muito baixa',
        'dados': {
          'tempoSegundos': 30.0,
          'larguraFaixa': 27.0,
          'velocidadeKmh': 2.0, // Muito baixa
          'valorColetadoKg': 25.0,
          'taxaDesejadaKgHa': 140.0,
        }
      },
      {
        'nome': 'Valor coletado muito alto',
        'dados': {
          'tempoSegundos': 30.0,
          'larguraFaixa': 27.0,
          'velocidadeKmh': 8.0,
          'valorColetadoKg': 100.0, // Muito alto
          'taxaDesejadaKgHa': 140.0,
        }
      },
      {
        'nome': 'Dados válidos',
        'dados': {
          'tempoSegundos': 30.0,
          'larguraFaixa': 27.0,
          'velocidadeKmh': 8.0,
          'valorColetadoKg': 8.5,
          'taxaDesejadaKgHa': 140.0,
        }
      },
    ];
    
    for (final caso in casos) {
      print('\n--- ${caso['nome']} ---');
      
      final dados = caso['dados'] as Map<String, double>;
      final validacao = StaraTornadoCalibrationService.validarDados(
        tempoSegundos: dados['tempoSegundos']!,
        larguraFaixa: dados['larguraFaixa']!,
        velocidadeKmh: dados['velocidadeKmh']!,
        valorColetadoKg: dados['valorColetadoKg']!,
        taxaDesejadaKgHa: dados['taxaDesejadaKgHa']!,
      );
      
      print('  Válido: ${validacao['valido']}');
      if (validacao['alertas'].isNotEmpty) {
        print('  Alertas: ${validacao['alertas']}');
      }
      if (validacao['avisos'].isNotEmpty) {
        print('  Avisos: ${validacao['avisos']}');
      }
      print('  Taxa esperada: ${validacao['taxa_esperada']} kg/ha');
    }
  }
  
  /// Executa todos os exemplos
  static void executarTodosExemplos() {
    print('🚜 EXEMPLOS DE CALIBRAÇÃO STARA TORNADO 1300 🚜\n');
    
    exemploComDadosDaImagem();
    exemploDadosRealistas();
    exemploValidacao();
    
    print('\n✅ Todos os exemplos executados!');
  }
}
