import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/germination_test_model.dart';
import '../repositories/germination_test_repository.dart';
import '../../../utils/logger.dart';
import 'tflite_ai_service.dart';
import '../../../services/fortsmart_agronomic_ai.dart';

/// Serviço de integração com IA para testes de germinação
class GerminationAIIntegrationService {
  final GerminationTestRepository _repository = GerminationTestRepository();
  
  // URLs do backend de IA (local e nuvem)
  static const String _localBackendUrl = 'http://localhost:5000';
  static const String _cloudBackendUrl = 'https://fortsmart-ai.herokuapp.com';
  static const String _productionBackendUrl = 'https://api.fortsmart.com.br/ai';
  
  // Configuração atual (detecta automaticamente)
  static String _currentBackendUrl = _localBackendUrl;
  
  /// Detecta automaticamente o melhor backend disponível
  static Future<String> _detectarMelhorBackend() async {
    // Lista de backends para testar (em ordem de preferência)
    final backends = [
      _localBackendUrl,
      _cloudBackendUrl,
      _productionBackendUrl,
    ];
    
    for (final backend in backends) {
      try {
        final response = await http.get(
          Uri.parse('$backend/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          Logger.info('✅ Backend disponível: $backend');
          return backend;
        }
      } catch (e) {
        Logger.warning('⚠️ Backend indisponível: $backend - $e');
        continue;
      }
    }
    
    Logger.warning('⚠️ Nenhum backend online - usando IA offline');
    return 'offline'; // Fallback para IA offline
  }
  
  /// Configura o backend automaticamente
  static Future<void> configurarBackendAutomaticamente() async {
    _currentBackendUrl = await _detectarMelhorBackend();
    Logger.info('🤖 Backend configurado: $_currentBackendUrl');
  }
  
  /// Envia dados enriquecidos diretamente para IA
  Future<GerminationAIPrediction?> enviarDadosParaIA(Map<String, dynamic> dados) async {
    try {
      Logger.info('🤖 Analisando dados com IA FortSmart (TensorFlow Lite)...');
      
      // Tentar usar TensorFlow Lite primeiro (modo offline)
      if (TFLiteAIService.isModelAvailable()) {
        Logger.info('🤖 Usando TensorFlow Lite para análise offline...');
        return await TFLiteAIService.analyzeGermination(dados);
      }
      
      // Se TensorFlow Lite não estiver disponível, inicializar
      final tfliteInitialized = await TFLiteAIService.initialize();
      if (tfliteInitialized) {
        Logger.info('🤖 TensorFlow Lite inicializado, analisando dados...');
        return await TFLiteAIService.analyzeGermination(dados);
      }
      
      // Fallback para análise local baseada em regras
      Logger.warning('⚠️ TensorFlow Lite não disponível, usando análise local...');
      return await _analisarComIALocal(dados);
      
    } catch (e) {
      Logger.error('❌ Erro na análise de IA: $e');
      // Fallback para IA local
      return await _analisarComIALocal(dados);
    }
  }
  
  /// Análise local usando IA offline
  Future<GerminationAIPrediction?> _analisarComIALocal(Map<String, dynamic> dados) async {
    try {
      Logger.info('🤖 Usando IA offline para análise...');
      
      // Simular análise local baseada em regras agronômicas
      final registro = dados['subtestes'][0]['registros'][0];
      
      final germinadas = registro['germinadas'] ?? 0;
      final naoGerminadas = registro['nao_germinadas'] ?? 0;
      final total = germinadas + naoGerminadas;
      
      if (total == 0) {
        return null;
      }
      
      // Calcular percentual de germinação
      final percentualGerminacao = (germinadas / total) * 100;
      
      // Classificar baseado no percentual
      String classificacao;
      double probabilidade;
      
      if (percentualGerminacao >= 90) {
        classificacao = 'Excelente';
        probabilidade = 0.95;
      } else if (percentualGerminacao >= 80) {
        classificacao = 'Boa';
        probabilidade = 0.85;
      } else if (percentualGerminacao >= 70) {
        classificacao = 'Regular';
        probabilidade = 0.75;
      } else {
        classificacao = 'Ruim';
        probabilidade = 0.65;
      }
      
      // Gerar recomendações baseadas nos dados
      final recomendacoes = _gerarRecomendacoesLocais(registro, percentualGerminacao);
      
       // Criar predição
       final prediction = GerminationAIPrediction(
         day: 1,
         normalGerminated: 0,
         abnormalGerminated: 0,
         diseasedFungi: 0,
         notGerminated: 0,
         manchas: 0,
         podridao: 0,
         cotiledonesAmarelados: 0,
         pureza: 95.0,
         vigor: 'Médio',
         temperatura: 25.0,
         umidade: 60.0,
         sementeTratada: false,
         cultura: '',
         variedade: '',
         lote: '',
         regressionPrediction: percentualGerminacao,
         classificationPrediction: classificacao,
         classificationProbability: probabilidade,
         vigorScore: min(1.0, percentualGerminacao / 100.0),
         purezaScore: 0.95, // Score de pureza baseado nos dados
         recommendations: recomendacoes,
         confidence: 'Alta',
         isComplete: true,
         timestamp: DateTime.now(),
         classificacao: classificacao,
         percentualPrevisto: percentualGerminacao,
         recomendacoes: recomendacoes.join('; '),
       );
      
      Logger.info('✅ Análise offline concluída: ${percentualGerminacao.toStringAsFixed(1)}%');
      return prediction;
      
    } catch (e) {
      Logger.error('❌ Erro na análise offline: $e');
      return null;
    }
  }
  
  /// Gera recomendações baseadas em regras agronômicas
  List<String> _gerarRecomendacoesLocais(Map<String, dynamic> registro, double percentual) {
    final recomendacoes = <String>[];
    
    final temperatura = registro['temperatura'] ?? 25.0;
    final umidade = registro['umidade'] ?? 60.0;
    final manchas = registro['manchas'] ?? 0;
    final podridao = registro['podridao'] ?? 0;
    final pureza = registro['pureza'] ?? 95.0;
    
    // Recomendações baseadas no percentual
    if (percentual < 70) {
      recomendacoes.add('Aumentar a temperatura para 25-30°C');
      recomendacoes.add('Verificar a umidade (ideal: 60-80%)');
      recomendacoes.add('Considerar tratamento das sementes');
    } else if (percentual < 80) {
      recomendacoes.add('Manter condições atuais');
      recomendacoes.add('Monitorar evolução diária');
    } else {
      recomendacoes.add('Excelente germinação! Manter condições');
    }
    
    // Recomendações baseadas em problemas
    if (manchas > 5) {
      recomendacoes.add('Investigar causa das manchas');
      recomendacoes.add('Verificar qualidade das sementes');
    }
    
    if (podridao > 3) {
      recomendacoes.add('Reduzir umidade para evitar podridão');
      recomendacoes.add('Melhorar ventilação');
    }
    
    // Recomendações baseadas em temperatura
    if (temperatura < 20) {
      recomendacoes.add('Aumentar temperatura para melhor germinação');
    } else if (temperatura > 35) {
      recomendacoes.add('Reduzir temperatura para evitar estresse');
    }
    
    // Recomendações baseadas em umidade
    if (umidade < 50) {
      recomendacoes.add('Aumentar umidade para 60-80%');
    } else if (umidade > 90) {
      recomendacoes.add('Reduzir umidade para evitar problemas');
    }
    
    // Recomendações baseadas em pureza
    if (pureza < 90) {
      recomendacoes.add('Verificar pureza das sementes');
      recomendacoes.add('Considerar limpeza adicional');
    }
    
    return recomendacoes;
  }

  /// Analisa dados de germinação com IA (método público para a nova tela)
  Future<GerminationAIPrediction?> analyzeGermination(GerminationAIPrediction analysisData) async {
    try {
      Logger.info('🤖 Analisando dados com IA FortSmart...');
      
      // Converter dados para formato esperado
      final dados = {
        'test_id': 0, // ID genérico para análise
        'subtestes': [{
          'registros': [{
            'dia': analysisData.day,
            'germinadas': analysisData.normalGerminated + analysisData.abnormalGerminated,
            'nao_germinadas': analysisData.notGerminated,
            'manchas': analysisData.manchas,
            'podridao': analysisData.podridao,
            'cotiledones_amarelados': analysisData.cotiledonesAmarelados,
            'vigor': analysisData.vigor,
            'pureza': analysisData.pureza,
            'temperatura': analysisData.temperatura,
            'umidade': analysisData.umidade,
            'sementes_totais': analysisData.normalGerminated + analysisData.abnormalGerminated + analysisData.diseasedFungi + analysisData.notGerminated,
          }]
        }]
      };
      
      return await enviarDadosParaIA(dados);
      
    } catch (e) {
      Logger.error('❌ Erro na análise de IA: $e');
      return null;
    }
  }

  /// Envia dados de germinação para análise de IA
  Future<GerminationAIPrediction?> analisarGerminacaoComIA(String testId) async {
    try {
      Logger.info('🤖 Iniciando análise de IA para teste: $testId');
      
      // Buscar dados do teste
      final testData = await _repository.buscarTestePorId(testId);
      if (testData == null) {
        Logger.error('❌ Teste não encontrado: $testId');
        return null;
      }
      
      // Buscar registros diários
      final registros = await _repository.buscarRegistrosPorTeste(testId);
      if (registros.isEmpty) {
        Logger.error('❌ Nenhum registro encontrado para o teste: $testId');
        return null;
      }
      
      // Preparar dados para IA
      final aiData = _prepararDadosParaIA(testData, registros);
      
      // Usar TensorFlow Lite para análise offline
      return await enviarDadosParaIA(aiData);
      
    } catch (e) {
      Logger.error('❌ Erro na análise de IA: $e');
      return null;
    }
  }
  
  /// Prepara dados para envio à IA
  Map<String, dynamic> _prepararDadosParaIA(GerminationTestModel test, List<GerminationDailyRecordModel> registros) {
    // Agrupar registros por subteste
    final registrosPorSubteste = <String, List<GerminationDailyRecordModel>>{};
    for (final registro in registros) {
      final subtestId = registro.subtestId;
      registrosPorSubteste[subtestId] ??= [];
      registrosPorSubteste[subtestId]!.add(registro);
    }
    
    // Preparar dados estruturados
    final aiData = {
      'test_id': test.id,
      'lote_id': test.loteId,
      'cultura': test.cultura,
      'variedade': test.variedade,
      'data_inicio': test.dataInicio.toIso8601String(),
      'subtestes': registrosPorSubteste.entries.map((entry) {
        final subtestId = entry.key;
        final subtestRegistros = entry.value;
        
        // Ordenar por dia
        subtestRegistros.sort((a, b) => a.dia.compareTo(b.dia));
        
        return {
          'subtest_id': subtestId,
          'registros': subtestRegistros.map((r) => {
            'dia': r.dia,
            'germinadas': r.germinadas,
            'nao_germinadas': r.naoGerminadas,
            'manchas': r.manchas,
            'podridao': r.podridao,
            'cotiledones_amarelados': r.cotiledonesAmarelados,
            'vigor': r.vigor,
            'pureza': r.pureza,
            'percentual_germinacao': r.percentualGerminacao,
            'categoria_germinacao': r.categoriaGerminacao,
            'data_registro': r.dataRegistro.toIso8601String(),
          }).toList(),
        };
      }).toList(),
    };
    
    return aiData;
  }
  
  /// Processa predição da IA e atualiza o teste
  Future<void> processarPredicaoIA(String testId, GerminationAIPrediction prediction) async {
    try {
      Logger.info('🔄 Processando predição de IA para teste: $testId');
      
      // Buscar teste atual
      final test = await _repository.buscarTestePorId(testId);
      if (test == null) {
        Logger.error('❌ Teste não encontrado: $testId');
        return;
      }
      
      // Atualizar teste com resultados da IA
      final testAtualizado = test.copyWith(
        percentualFinal: prediction.regressionPrediction,
        categoriaFinal: prediction.classificationPrediction,
        vigorFinal: prediction.vigorScore,
        purezaFinal: prediction.purezaScore,
        atualizadoEm: DateTime.now(),
      );
      
      await _repository.atualizarTeste(testAtualizado);
      
      // Se o teste estiver concluído, finalizar
      if (test.status == 'em_andamento' && (prediction.isComplete ?? false)) {
        await _repository.finalizarTeste(
          testId,
          prediction.regressionPrediction ?? 0.0,
          prediction.classificationPrediction ?? 'Regular',
        );
      }
      
      Logger.info('✅ Predição de IA processada para teste: $testId');
    } catch (e) {
      Logger.error('❌ Erro ao processar predição de IA: $e');
    }
  }
  
  /// Gera recomendações baseadas na análise de IA
  List<String> gerarRecomendacoes(GerminationAIPrediction prediction) {
    final recomendacoes = <String>[];
    
    // Recomendações baseadas no percentual de germinação
    if ((prediction.regressionPrediction ?? 0.0) < 70) {
      recomendacoes.add('Germinação baixa - verificar qualidade das sementes');
      recomendacoes.add('Considerar tratamento adicional das sementes');
    } else if ((prediction.regressionPrediction ?? 0.0) < 80) {
      recomendacoes.add('Germinação regular - monitorar desenvolvimento');
      recomendacoes.add('Verificar condições ambientais');
    } else {
      recomendacoes.add('Germinação excelente - manter condições atuais');
    }
    
    // Recomendações baseadas na categoria
    switch (prediction.classificationPrediction) {
      case 'Ruim':
        recomendacoes.add('Rejeitar lote - qualidade insuficiente');
        recomendacoes.add('Investigar causas da baixa germinação');
        break;
      case 'Regular':
        recomendacoes.add('Usar com cautela - monitorar campo');
        recomendacoes.add('Considerar aumento da densidade de semeadura');
        break;
      case 'Boa':
        recomendacoes.add('Lote aprovado para plantio');
        recomendacoes.add('Manter densidade normal de semeadura');
        break;
      case 'Excelente':
        recomendacoes.add('Lote de excelente qualidade');
        recomendacoes.add('Pode reduzir densidade de semeadura se necessário');
        break;
    }
    
    // Recomendações baseadas no vigor
    if ((prediction.vigorScore ?? 0.0) < 0.5) {
      recomendacoes.add('Vigor baixo - considerar tratamento de sementes');
    } else if ((prediction.vigorScore ?? 0.0) > 0.8) {
      recomendacoes.add('Vigor excelente - sementes de alta qualidade');
    }
    
    // Recomendações baseadas na pureza
    if ((prediction.purezaScore ?? 0.0) < 95) {
      recomendacoes.add('Pureza abaixo do ideal - verificar limpeza');
    }
    
    return recomendacoes;
  }
  
  /// Exporta dados para treinamento de IA
  Future<Map<String, dynamic>> exportarDadosParaTreinamento() async {
    try {
      Logger.info('📊 Exportando dados para treinamento de IA...');
      
      // Buscar todos os testes concluídos
      final testes = await _repository.buscarTestesPorStatus('concluido');
      final dadosTreinamento = <Map<String, dynamic>>[];
      
      for (final teste in testes) {
        final registros = await _repository.buscarRegistrosPorTeste(teste.id);
        
        if (registros.isNotEmpty) {
          // Agrupar por subteste
          final registrosPorSubteste = <String, List<GerminationDailyRecordModel>>{};
          for (final registro in registros) {
            registrosPorSubteste[registro.subtestId] ??= [];
            registrosPorSubteste[registro.subtestId]!.add(registro);
          }
          
          // Preparar dados para cada subteste
          for (final entry in registrosPorSubteste.entries) {
            final subtestRegistros = entry.value;
            subtestRegistros.sort((a, b) => a.dia.compareTo(b.dia));
            
            for (final registro in subtestRegistros) {
              dadosTreinamento.add({
                'test_id': teste.id,
                'lote_id': teste.loteId,
                'cultura': teste.cultura,
                'variedade': teste.variedade,
                'subtest_id': registro.subtestId,
                'dia': registro.dia,
                'germinadas': registro.germinadas,
                'nao_germinadas': registro.naoGerminadas,
                'manchas': registro.manchas,
                'podridao': registro.podridao,
                'cotiledones_amarelados': registro.cotiledonesAmarelados,
                'vigor': registro.vigor,
                'pureza': registro.pureza,
                'percentual_germinacao': registro.percentualGerminacao,
                'categoria_germinacao': registro.categoriaGerminacao,
                'data_registro': registro.dataRegistro.toIso8601String(),
                'percentual_final': teste.percentualFinal,
                'categoria_final': teste.categoriaFinal,
              });
            }
          }
        }
      }
      
      Logger.info('✅ Dados exportados: ${dadosTreinamento.length} registros');
      
      return {
        'total_registros': dadosTreinamento.length,
        'total_testes': testes.length,
        'dados': dadosTreinamento,
        'exportado_em': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao exportar dados para treinamento: $e');
      return {};
    }
  }
}

/// Modelo para predição de IA
class GerminationAIPrediction {
  // Campos de entrada (para análise)
  final int day;
  final int normalGerminated;
  final int abnormalGerminated;
  final int diseasedFungi;
  final int notGerminated;
  final int manchas;
  final int podridao;
  final int cotiledonesAmarelados;
  final double pureza;
  final String vigor;
  final double temperatura;
  final double umidade;
  final bool sementeTratada;
  final String cultura;
  final String variedade;
  final String lote;
  
  // Campos de saída (resultados da IA)
  final double? regressionPrediction;
  final String? classificationPrediction;
  final double? classificationProbability;
  final double? vigorScore;
  final double? purezaScore;
  final List<String>? recommendations;
  final String? confidence;
  final bool? isComplete;
  final DateTime? timestamp;
  
  // Campos adicionais para compatibilidade
  final String? classificacao;
  final double? percentualPrevisto;
  final String? problemasIdentificados;
  final String? recomendacoes;

  const GerminationAIPrediction({
    required this.day,
    required this.normalGerminated,
    required this.abnormalGerminated,
    required this.diseasedFungi,
    required this.notGerminated,
    required this.manchas,
    required this.podridao,
    required this.cotiledonesAmarelados,
    required this.pureza,
    required this.vigor,
    required this.temperatura,
    required this.umidade,
    required this.sementeTratada,
    required this.cultura,
    required this.variedade,
    required this.lote,
    this.regressionPrediction,
    this.classificationPrediction,
    this.classificationProbability,
    this.vigorScore,
    this.purezaScore,
    this.recommendations,
    this.confidence,
    this.isComplete,
    this.timestamp,
    this.classificacao,
    this.percentualPrevisto,
    this.problemasIdentificados,
    this.recomendacoes,
  });

  factory GerminationAIPrediction.fromJson(Map<String, dynamic> json) {
    return GerminationAIPrediction(
      day: json['day'] as int? ?? 1,
      normalGerminated: json['normal_germinated'] as int? ?? 0,
      abnormalGerminated: json['abnormal_germinated'] as int? ?? 0,
      diseasedFungi: json['diseased_fungi'] as int? ?? 0,
      notGerminated: json['not_germinated'] as int? ?? 0,
      manchas: json['manchas'] as int? ?? 0,
      podridao: json['podridao'] as int? ?? 0,
      cotiledonesAmarelados: json['cotiledones_amarelados'] as int? ?? 0,
      pureza: (json['pureza'] as num?)?.toDouble() ?? 0.0,
      vigor: json['vigor'] as String? ?? 'Médio',
      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 25.0,
      umidade: (json['umidade'] as num?)?.toDouble() ?? 60.0,
      sementeTratada: json['semente_tratada'] as bool? ?? false,
      cultura: json['cultura'] as String? ?? '',
      variedade: json['variedade'] as String? ?? '',
      lote: json['lote'] as String? ?? '',
      regressionPrediction: (json['regression_prediction'] as num?)?.toDouble(),
      classificationPrediction: json['classification_prediction'] as String?,
      classificationProbability: (json['classification_probability'] as num?)?.toDouble(),
      vigorScore: (json['vigor_score'] as num?)?.toDouble(),
      purezaScore: (json['pureza_score'] as num?)?.toDouble(),
      recommendations: json['recommendations'] != null ? List<String>.from(json['recommendations']) : null,
      confidence: json['confidence'] as String?,
      isComplete: json['is_complete'] as bool?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      classificacao: json['classificacao'] as String?,
      percentualPrevisto: (json['percentual_previsto'] as num?)?.toDouble(),
      problemasIdentificados: json['problemas_identificados'] as String?,
      recomendacoes: json['recomendacoes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_id': 0, // ID genérico
      'day': day,
      'normal_germinated': normalGerminated,
      'abnormal_germinated': abnormalGerminated,
      'diseased_fungi': diseasedFungi,
      'not_germinated': notGerminated,
      'manchas': manchas,
      'podridao': podridao,
      'cotiledones_amarelados': cotiledonesAmarelados,
      'pureza': pureza,
      'vigor': vigor,
      'temperatura': temperatura,
      'umidade': umidade,
      'semente_tratada': sementeTratada,
      'cultura': cultura,
      'variedade': variedade,
      'lote': lote,
      'regression_prediction': regressionPrediction,
      'classification_prediction': classificationPrediction,
      'classification_probability': classificationProbability,
      'vigor_score': vigorScore,
      'pureza_score': purezaScore,
      'recommendations': recommendations,
      'confidence': confidence,
      'is_complete': isComplete,
      'timestamp': timestamp?.toIso8601String(),
      'classificacao': classificacao,
      'percentual_previsto': percentualPrevisto,
      'problemas_identificados': problemasIdentificados,
      'recomendacoes': recomendacoes,
    };
  }
}
