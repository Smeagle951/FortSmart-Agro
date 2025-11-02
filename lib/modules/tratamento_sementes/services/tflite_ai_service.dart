import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/germination_test_model.dart';
import '../utils/vigor_calculator.dart';
import '../utils/germination_professional_calculator.dart';
import 'germination_ai_integration_service.dart';
import '../../../utils/logger.dart';

/// Serviço de IA 100% Offline - Dart Puro
/// NÃO requer Python, TensorFlow, servidor ou internet
/// Baseado em cálculos matemáticos puros em Dart
class TFLiteAIService {
  static Map<String, dynamic>? _modelData;
  static bool _isInitialized = false;
  
  // Configurações do modelo (JSON puro, sem Python!)
  static const String _modelPath = 'assets/models/flutter_model.json';
  static const int _inputSize = 13; // Número de features de entrada
  static const int _outputSize = 4; // Número de saídas (regressão + classificação)
  
  /// Inicializa o modelo de IA offline
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        Logger.info('🤖 Modelo de IA já inicializado');
        return true;
      }
      
      Logger.info('🤖 Inicializando modelo de IA FortSmart...');
      
      // Carregar modelo JSON dos assets
      final modelJson = await rootBundle.loadString(_modelPath);
      _modelData = json.decode(modelJson);
      
      if (_modelData == null) {
        Logger.error('❌ Falha ao carregar modelo de IA');
        return false;
      }
      
      _isInitialized = true;
      Logger.info('✅ Modelo de IA FortSmart inicializado com sucesso');
      Logger.info('📊 Versão do modelo: ${_modelData!['version']}');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar modelo de IA: $e');
      return false;
    }
  }
  
  /// Libera recursos do modelo
  static void dispose() {
    _modelData = null;
    _isInitialized = false;
    Logger.info('🔄 Recursos do modelo de IA liberados');
  }
  
  /// Analisa dados de germinação usando IA offline
  static Future<GerminationAIPrediction?> analyzeGermination(Map<String, dynamic> data) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          Logger.error('❌ Falha ao inicializar modelo de IA');
          return null;
        }
      }
      
      Logger.info('🤖 Analisando dados com IA FortSmart...');
      
      // Preparar dados de entrada
      final inputData = _prepareInputData(data);
      if (inputData == null) {
        Logger.error('❌ Falha ao preparar dados de entrada');
        return null;
      }
      
      // Executar inferência
      final output = _runInference(inputData);
      if (output == null) {
        Logger.error('❌ Falha na inferência do modelo');
        return null;
      }
      
      // Processar resultados
      final prediction = _processOutput(output, data);
      
      Logger.info('✅ Análise de IA concluída');
      return prediction;
      
    } catch (e) {
      Logger.error('❌ Erro na análise de IA: $e');
      return null;
    }
  }
  
  /// Prepara dados de entrada para o modelo
  static List<double>? _prepareInputData(Map<String, dynamic> data) {
    try {
      final registros = data['subtestes'][0]['registros'] as List;
      if (registros.isEmpty) return null;
      
      final registro = registros[0] as Map<String, dynamic>;
      
      // Extrair features do registro
      final germinadas = (registro['germinadas'] ?? 0).toDouble();
      final naoGerminadas = (registro['nao_germinadas'] ?? 0).toDouble();
      final total = germinadas + naoGerminadas;
      
      if (total == 0) return null;
      
      final dia = (registro['dia'] ?? 1).toDouble();
      final sementesTotais = (registro['sementes_totais'] ?? total).toDouble();
      final manchas = (registro['manchas'] ?? 0).toDouble();
      final podridao = (registro['podridao'] ?? 0).toDouble();
      final cotiledonesAmarelados = (registro['cotiledones_amarelados'] ?? 0).toDouble();
      final umidade = (registro['umidade'] ?? 60.0).toDouble();
      final temperatura = (registro['temperatura'] ?? 25.0).toDouble();
      final diasEmergencia = (registro['dias_emergencia'] ?? 4.0).toDouble();
      final loteIdadeMeses = (registro['lote_idade_meses'] ?? 6.0).toDouble();
      
      // Calcular features derivadas
      final taxaGerminacaoDiaria = germinadas / dia;
      final indiceSanidade = 1 - (manchas + podridao) / sementesTotais;
      
      // Calcular VIGOR científico (cálculo simples offline)
      final vigorCalculado = germinadas / (dia * sementesTotais);
      
      // Se fornecido manualmente, usar o fornecido; senão, usar o calculado
      final vigor = (registro['vigor'] ?? vigorCalculado).toDouble();
      
      final pureza = (registro['pureza'] ?? 95.0).toDouble();
      
      // Normalizar features usando scaler do modelo
      final scalerMean = List<double>.from(_modelData!['scaler_mean']);
      final scalerScale = List<double>.from(_modelData!['scaler_scale']);
      
      final features = [
        dia,
        sementesTotais,
        manchas,
        podridao,
        cotiledonesAmarelados,
        umidade,
        temperatura,
        diasEmergencia,
        loteIdadeMeses,
        taxaGerminacaoDiaria,
        indiceSanidade,
        vigor,
        pureza / 100.0,
      ];
      
      // Aplicar normalização
      final normalizedFeatures = <double>[];
      for (int i = 0; i < features.length; i++) {
        final normalized = (features[i] - scalerMean[i]) / scalerScale[i];
        normalizedFeatures.add(normalized);
      }
      
      return normalizedFeatures;
      
    } catch (e) {
      Logger.error('❌ Erro ao preparar dados de entrada: $e');
      return null;
    }
  }
  
  /// Executa inferência no modelo
  static List<double>? _runInference(List<double> inputData) {
    try {
      if (_modelData == null) return null;
      
      // Obter pesos do modelo
      final regWeights = List<double>.from(_modelData!['regression_weights']);
      final clsWeights = List<double>.from(_modelData!['classification_weights']);
      
      // Calcular regressão (percentual de germinação)
      double regression = 0.0;
      for (int i = 0; i < inputData.length; i++) {
        regression += inputData[i] * regWeights[i];
      }
      regression = (regression * 50) + 50; // Desnormalizar para 0-100%
      regression = regression.clamp(0.0, 100.0);
      
      // Calcular classificação
      double classification = 0.0;
      for (int i = 0; i < inputData.length; i++) {
        classification += inputData[i] * clsWeights[i];
      }
      classification = (classification + 1) / 2; // Normalizar para 0-1
      
      // Calcular vigor (baseado na regressão e features)
      final vigor = (regression / 100.0) * 0.7 + (inputData[11] * 0.3); // vigor feature
      
      // Calcular pureza (baseado na regressão e features)
      final pureza = (regression / 100.0) * 0.6 + (inputData[12] * 0.4); // pureza feature
      
      return [regression, classification, vigor, pureza];
      
    } catch (e) {
      Logger.error('❌ Erro na inferência: $e');
      return null;
    }
  }
  
  /// Processa saída do modelo e cria predição
  static GerminationAIPrediction _processOutput(List<double> output, Map<String, dynamic> data) {
    // Extrair resultados
    final regressionPrediction = output[0];      // Percentual de germinação
    final classificationScore = output[1];       // Score de classificação
    final vigorScore = output[2];                // Score de vigor
    final purezaScore = output[3];               // Score de pureza
    
    // Determinar classificação baseada no score
    String classificationPrediction;
    double classificationProbability;
    
    if (classificationScore >= 0.8) {
      classificationPrediction = 'Excelente';
      classificationProbability = 0.95;
    } else if (classificationScore >= 0.6) {
      classificationPrediction = 'Boa';
      classificationProbability = 0.85;
    } else if (classificationScore >= 0.4) {
      classificationPrediction = 'Regular';
      classificationProbability = 0.75;
    } else {
      classificationPrediction = 'Ruim';
      classificationProbability = 0.65;
    }
    
    // Gerar recomendações
    final recomendacoes = _generateRecommendations(
      regressionPrediction,
      classificationPrediction,
      vigorScore,
      purezaScore,
      data,
    );
    
    // Determinar confiança
    final confidence = _calculateConfidence(regressionPrediction, classificationProbability);
    
    return GerminationAIPrediction(
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
      regressionPrediction: regressionPrediction,
      classificationPrediction: classificationPrediction,
      classificationProbability: classificationProbability,
      vigorScore: vigorScore,
      purezaScore: purezaScore,
      recommendations: recomendacoes,
      confidence: confidence,
      isComplete: true,
      timestamp: DateTime.now(),
      classificacao: classificationPrediction,
      percentualPrevisto: regressionPrediction,
      recomendacoes: recomendacoes.join('; '),
    );
  }
  
  /// Gera recomendações baseadas na análise
  static List<String> _generateRecommendations(
    double percentual,
    String classificacao,
    double vigor,
    double pureza,
    Map<String, dynamic> data,
  ) {
    final recomendacoes = <String>[];
    
    // Recomendações baseadas no percentual
    if (percentual < 70) {
      recomendacoes.add('Germinação baixa - verificar qualidade das sementes');
      recomendacoes.add('Considerar tratamento adicional das sementes');
      recomendacoes.add('Ajustar condições ambientais (temperatura/umidade)');
    } else if (percentual < 80) {
      recomendacoes.add('Germinação regular - monitorar desenvolvimento');
      recomendacoes.add('Verificar condições ambientais');
    } else {
      recomendacoes.add('Germinação excelente - manter condições atuais');
    }
    
    // Recomendações baseadas na classificação
    switch (classificacao) {
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
    if (vigor < 0.5) {
      recomendacoes.add('Vigor baixo - considerar tratamento de sementes');
      recomendacoes.add('Verificar armazenamento das sementes');
    } else if (vigor > 0.8) {
      recomendacoes.add('Vigor excelente - sementes de alta qualidade');
    }
    
    // Recomendações baseadas na pureza
    if (pureza < 0.95) {
      recomendacoes.add('Pureza abaixo do ideal - verificar limpeza');
      recomendacoes.add('Considerar limpeza adicional das sementes');
    }
    
    return recomendacoes;
  }
  
  /// Calcula nível de confiança da predição
  static String _calculateConfidence(double percentual, double probability) {
    if (percentual > 90 && probability > 0.9) {
      return 'Muito Alta';
    } else if (percentual > 80 && probability > 0.8) {
      return 'Alta';
    } else if (percentual > 70 && probability > 0.7) {
      return 'Média';
    } else {
      return 'Baixa';
    }
  }
  
  /// Verifica se o modelo está disponível
  static bool isModelAvailable() {
    return _isInitialized && _modelData != null;
  }
  
  /// Obtém informações do modelo
  static Map<String, dynamic> getModelInfo() {
    return {
      'initialized': _isInitialized,
      'model_path': _modelPath,
      'input_size': _inputSize,
      'output_size': _outputSize,
      'model_available': _modelData != null,
      'version': _modelData?['version'] ?? 'unknown',
    };
  }
}
