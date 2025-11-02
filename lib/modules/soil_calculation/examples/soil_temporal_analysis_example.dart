import '../models/soil_compaction_point_model.dart';
import '../services/soil_temporal_analysis_service.dart';

/// Exemplo de uso do serviço de análises temporais
class SoilTemporalAnalysisExample {
  
  /// Exemplo de cálculo de tendência entre safras
  static void exemploCalculoTendencia() {
    // Dados simulados - Safra 2024
    final pontos2024 = [
      SoilCompactionPointModel(
        id: 1,
        pointCode: 'C-001',
        talhaoId: 1,
        dataColeta: DateTime(2024, 3, 15),
        latitude: -23.5505,
        longitude: -46.6333,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.8, // Alta compactação
      ),
      SoilCompactionPointModel(
        id: 2,
        pointCode: 'C-002',
        talhaoId: 1,
        dataColeta: DateTime(2024, 3, 15),
        latitude: -23.5510,
        longitude: -46.6340,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 1.2, // Baixa compactação
      ),
      SoilCompactionPointModel(
        id: 3,
        pointCode: 'C-003',
        talhaoId: 1,
        dataColeta: DateTime(2024, 3, 15),
        latitude: -23.5500,
        longitude: -46.6325,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.1, // Compactação moderada
      ),
    ];

    // Dados simulados - Safra 2025
    final pontos2025 = [
      SoilCompactionPointModel(
        id: 4,
        pointCode: 'C-001',
        talhaoId: 1,
        dataColeta: DateTime(2025, 3, 15),
        latitude: -23.5505,
        longitude: -46.6333,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.2, // Melhorou (era 2.8)
      ),
      SoilCompactionPointModel(
        id: 5,
        pointCode: 'C-002',
        talhaoId: 1,
        dataColeta: DateTime(2025, 3, 15),
        latitude: -23.5510,
        longitude: -46.6340,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 1.8, // Piorou (era 1.2)
      ),
      SoilCompactionPointModel(
        id: 6,
        pointCode: 'C-003',
        talhaoId: 1,
        dataColeta: DateTime(2025, 3, 15),
        latitude: -23.5500,
        longitude: -46.6325,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.0, // Manteve-se similar (era 2.1)
      ),
    ];

    // Calcula tendência
    final tendencia = SoilTemporalAnalysisService.calcularTendencia(
      pontosAtuais: pontos2025,
      pontosAnteriores: pontos2024,
    );

    print('=== ANÁLISE DE TENDÊNCIA ===');
    print('Tendência Geral: ${tendencia['tendencia_geral']}');
    print('Score: ${tendencia['score_tendencia']}');
    print('Melhorou: ${tendencia['melhorou']} pontos');
    print('Piorou: ${tendencia['piorou']} pontos');
    print('Igual: ${tendencia['igual']} pontos');
    print('Variação: ${tendencia['variacao_percentual']}%');
    print('Interpretação: ${tendencia['interpretacao']}');
  }

  /// Exemplo de geração de evolução por safra
  static void exemploEvolucaoPorSafra() {
    // Dados simulados para múltiplas safras
    final dadosPorSafra = {
      2022: [
        SoilCompactionPointModel(
          id: 1,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2022, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 3.2, // Muito alta
        ),
        SoilCompactionPointModel(
          id: 2,
          pointCode: 'C-002',
          talhaoId: 1,
          dataColeta: DateTime(2022, 3, 15),
          latitude: -23.5510,
          longitude: -46.6340,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.8, // Alta
        ),
      ],
      2023: [
        SoilCompactionPointModel(
          id: 3,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2023, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.9, // Melhorou um pouco
        ),
        SoilCompactionPointModel(
          id: 4,
          pointCode: 'C-002',
          talhaoId: 1,
          dataColeta: DateTime(2023, 3, 15),
          latitude: -23.5510,
          longitude: -46.6340,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.5, // Melhorou
        ),
      ],
      2024: [
        SoilCompactionPointModel(
          id: 5,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2024, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.3, // Melhorou mais
        ),
        SoilCompactionPointModel(
          id: 6,
          pointCode: 'C-002',
          talhaoId: 1,
          dataColeta: DateTime(2024, 3, 15),
          latitude: -23.5510,
          longitude: -46.6340,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 1.8, // Melhorou significativamente
        ),
      ],
    };

    // Gera evolução
    final evolucao = SoilTemporalAnalysisService.gerarEvolucaoPorSafra(
      dadosPorSafra: dadosPorSafra,
    );

    print('=== EVOLUÇÃO POR SAFRA ===');
    print('Total de safras: ${evolucao['safras'].length}');
    
    for (var safra in evolucao['safras']) {
      print('\nSafra ${safra['ano']}:');
      print('  Média: ${safra['media_compactacao'].toStringAsFixed(2)} MPa');
      print('  Classificação: ${safra['classificacao']}');
      print('  Áreas Críticas: ${safra['areas_criticas']}');
      print('  Áreas Adequadas: ${safra['areas_adequadas']}');
    }

    print('\n=== TENDÊNCIAS ENTRE SAFRAS ===');
    for (var tendencia in evolucao['tendencias']) {
      print('${tendencia['de_safra']} → ${tendencia['para_safra']}:');
      print('  Tendência: ${tendencia['tendencia']}');
      print('  Variação: ${tendencia['variacao_percentual'].toStringAsFixed(1)}%');
      print('  Melhorou: ${tendencia['melhorou']} | Piorou: ${tendencia['piorou']} | Igual: ${tendencia['igual']}');
    }
  }

  /// Exemplo de mapa de calor temporal
  static void exemploMapaCalorTemporal() {
    // Dados simulados com múltiplas medições no mesmo local
    final pontos = [
      SoilCompactionPointModel(
        id: 1,
        pointCode: 'C-001',
        talhaoId: 1,
        dataColeta: DateTime(2024, 1, 15),
        latitude: -23.5505,
        longitude: -46.6333,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.8,
      ),
      SoilCompactionPointModel(
        id: 2,
        pointCode: 'C-001',
        talhaoId: 1,
        dataColeta: DateTime(2024, 2, 15),
        latitude: -23.5505,
        longitude: -46.6333,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.5, // Melhorou
      ),
      SoilCompactionPointModel(
        id: 3,
        pointCode: 'C-001',
        talhaoId: 1,
        dataColeta: DateTime(2024, 3, 15),
        latitude: -23.5505,
        longitude: -46.6333,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.2, // Melhorou mais
      ),
      SoilCompactionPointModel(
        id: 4,
        pointCode: 'C-002',
        talhaoId: 1,
        dataColeta: DateTime(2024, 1, 15),
        latitude: -23.5510,
        longitude: -46.6340,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 1.5,
      ),
      SoilCompactionPointModel(
        id: 5,
        pointCode: 'C-002',
        talhaoId: 1,
        dataColeta: DateTime(2024, 2, 15),
        latitude: -23.5510,
        longitude: -46.6340,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 1.8, // Piorou
      ),
      SoilCompactionPointModel(
        id: 6,
        pointCode: 'C-002',
        talhaoId: 1,
        dataColeta: DateTime(2024, 3, 15),
        latitude: -23.5510,
        longitude: -46.6340,
        profundidadeInicio: 0,
        profundidadeFim: 20,
        penetrometria: 2.0, // Piorou mais
      ),
    ];

    // Gera mapa de calor
    final mapaCalor = SoilTemporalAnalysisService.gerarMapaCalorTemporal(
      pontos: pontos,
      safraId: 2024,
    );

    print('=== MAPA DE CALOR TEMPORAL ===');
    print('Safra: ${mapaCalor['safra_id']}');
    print('Total de localizações: ${mapaCalor['total_localizacoes']}');
    
    final estatisticas = mapaCalor['estatisticas'];
    print('Melhorou: ${estatisticas['melhorou']} localizações');
    print('Piorou: ${estatisticas['piorou']} localizações');
    print('Estável: ${estatisticas['estavel']} localizações');
    print('Variação média: ${estatisticas['variacao_media'].toStringAsFixed(1)}%');

    print('\n=== DADOS DO MAPA ===');
    final dadosMapa = mapaCalor['dados_mapa'] as Map<String, dynamic>;
    dadosMapa.forEach((chave, dados) {
      print('Localização: $chave');
      print('  Tendência: ${dados['tendencia']}');
      print('  Variação: ${dados['variacao_percentual'].toStringAsFixed(1)}%');
      print('  Cor: ${dados['cor']}');
      print('  Intensidade: ${dados['intensidade'].toStringAsFixed(1)}');
    });
  }

  /// Exemplo de dados para gráfico de evolução
  static void exemploDadosGraficoEvolucao() {
    final dadosPorSafra = {
      2022: [
        SoilCompactionPointModel(
          id: 1,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2022, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 3.0,
        ),
      ],
      2023: [
        SoilCompactionPointModel(
          id: 2,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2023, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.5,
        ),
      ],
      2024: [
        SoilCompactionPointModel(
          id: 3,
          pointCode: 'C-001',
          talhaoId: 1,
          dataColeta: DateTime(2024, 3, 15),
          latitude: -23.5505,
          longitude: -46.6333,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.0,
        ),
      ],
    };

    // Gera dados para gráfico
    final dadosGrafico = SoilTemporalAnalysisService.gerarDadosGraficoEvolucao(
      dadosPorSafra: dadosPorSafra,
    );

    print('=== DADOS PARA GRÁFICO ===');
    print('Título: ${dadosGrafico['titulo']}');
    print('Subtítulo: ${dadosGrafico['subtitulo']}');
    print('Labels: ${dadosGrafico['labels']}');
    
    final series = dadosGrafico['series'] as Map<String, List<double>>;
    print('Série Média: ${series['media']}');
    print('Série Mínimo: ${series['minimo']}');
    print('Série Máximo: ${series['maximo']}');
    print('Série Áreas Críticas: ${series['areas_criticas']}');
  }

  /// Executa todos os exemplos
  static void executarTodosExemplos() {
    print('🚜 EXEMPLOS DE ANÁLISES TEMPORAIS - FORTSMART AGRO\n');
    
    exemploCalculoTendencia();
    print('\n' + '='*50 + '\n');
    
    exemploEvolucaoPorSafra();
    print('\n' + '='*50 + '\n');
    
    exemploMapaCalorTemporal();
    print('\n' + '='*50 + '\n');
    
    exemploDadosGraficoEvolucao();
    
    print('\n✅ Todos os exemplos executados com sucesso!');
  }
}
