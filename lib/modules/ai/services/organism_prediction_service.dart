import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository.dart';
import '../../../utils/logger.dart';

/// Serviço de predição de organismos e surtos
class OrganismPredictionService {
  final AIOrganismRepository _organismRepository = AIOrganismRepository();

  /// Prediz risco de surto baseado em condições climáticas
  Future<Map<String, dynamic>> predictOutbreakRisk({
    required String cropName,
    required Map<String, dynamic> weatherData,
    required String location,
  }) async {
    try {
      Logger.info('🔮 Iniciando predição de risco de surto');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('📍 Localização: $location');

      final organisms = await _organismRepository.getOrganismsByCrop(cropName);
      final predictions = <Map<String, dynamic>>[];

      for (final organism in organisms) {
        final risk = _calculateOutbreakRisk(organism, weatherData);
        
        if (risk > 0.3) { // Só retorna riscos significativos
          predictions.add({
            'organism': organism,
            'riskLevel': risk,
            'riskCategory': _getRiskCategory(risk),
            'recommendations': _getRiskRecommendations(organism, risk),
            'weatherFactors': _analyzeWeatherFactors(organism, weatherData),
          });
        }
      }

      // Ordenar por nível de risco (maior primeiro)
      predictions.sort((a, b) => (b['riskLevel'] as double).compareTo(a['riskLevel'] as double));

      final result = {
        'cropName': cropName,
        'location': location,
        'weatherData': weatherData,
        'predictions': predictions,
        'totalRisks': predictions.length,
        'highestRisk': predictions.isNotEmpty ? predictions.first['riskLevel'] : 0.0,
        'predictionDate': DateTime.now().toIso8601String(),
      };

      Logger.info('✅ Predição concluída: ${predictions.length} riscos identificados');
      return result;

    } catch (e) {
      Logger.error('❌ Erro na predição de surto: $e');
      return {};
    }
  }

  /// Prediz período ideal para aplicação de defensivos
  Future<Map<String, dynamic>> predictOptimalApplication({
    required String cropName,
    required String organismName,
    required Map<String, dynamic> weatherData,
    required DateTime currentDate,
  }) async {
    try {
      Logger.info('📅 Predizendo período ideal para aplicação');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('🐛 Organismo: $organismName');

      final organisms = await _organismRepository.searchOrganisms(organismName);
      
      if (organisms.isEmpty) {
        Logger.warning('⚠️ Organismo não encontrado: $organismName');
        return {};
      }

      final organism = organisms.first;
      final optimalPeriod = _calculateOptimalPeriod(organism, weatherData, currentDate);

      return {
        'organism': organism,
        'optimalPeriod': optimalPeriod,
        'currentConditions': _analyzeCurrentConditions(weatherData),
        'recommendations': _getApplicationRecommendations(organism, optimalPeriod),
        'weatherForecast': _generateWeatherForecast(weatherData),
      };

    } catch (e) {
      Logger.error('❌ Erro na predição de aplicação: $e');
      return {};
    }
  }

  /// Prediz eficácia de tratamentos
  Future<Map<String, dynamic>> predictTreatmentEfficacy({
    required String organismName,
    required List<String> treatments,
    required Map<String, dynamic> conditions,
  }) async {
    try {
      Logger.info('💊 Predizendo eficácia de tratamentos');
      Logger.info('🐛 Organismo: $organismName');
      Logger.info('💊 Tratamentos: $treatments');

      final organisms = await _organismRepository.searchOrganisms(organismName);
      
      if (organisms.isEmpty) {
        return {};
      }

      final organism = organisms.first;
      final efficacyPredictions = <Map<String, dynamic>>[];

      for (final treatment in treatments) {
        final efficacy = _calculateTreatmentEfficacy(organism, treatment, conditions);
        
        efficacyPredictions.add({
          'treatment': treatment,
          'efficacy': efficacy,
          'efficacyCategory': _getEfficacyCategory(efficacy),
          'factors': _analyzeEfficacyFactors(organism, treatment, conditions),
          'recommendations': _getTreatmentRecommendations(treatment, efficacy),
        });
      }

      // Ordenar por eficácia (maior primeiro)
      efficacyPredictions.sort((a, b) => (b['efficacy'] as double).compareTo(a['efficacy'] as double));

      return {
        'organism': organism,
        'predictions': efficacyPredictions,
        'bestTreatment': efficacyPredictions.isNotEmpty ? efficacyPredictions.first : null,
        'conditions': conditions,
      };

    } catch (e) {
      Logger.error('❌ Erro na predição de eficácia: $e');
      return {};
    }
  }

  /// Calcula risco de surto baseado em condições
  double _calculateOutbreakRisk(AIOrganismData organism, Map<String, dynamic> weatherData) {
    double risk = 0.0;
    
    // Fatores climáticos
    final temperature = weatherData['temperature'] ?? 25.0;
    final humidity = weatherData['humidity'] ?? 60.0;
    final rainfall = weatherData['rainfall'] ?? 0.0;
    
    // Ajuste baseado no tipo de organismo
    if (organism.type == 'pest') {
      // Pragas preferem temperaturas mais altas
      if (temperature > 25 && temperature < 35) risk += 0.3;
      if (humidity > 70) risk += 0.2;
      if (rainfall < 5) risk += 0.1; // Pouca chuva favorece pragas
    } else if (organism.type == 'disease') {
      // Doenças preferem umidade alta
      if (humidity > 80) risk += 0.4;
      if (temperature > 20 && temperature < 30) risk += 0.3;
      if (rainfall > 10) risk += 0.2; // Chuva favorece doenças
    }
    
    // Ajuste baseado na severidade do organismo
    risk += organism.severity * 0.2;
    
    return risk.clamp(0.0, 1.0);
  }

  /// Calcula período ideal para aplicação
  Map<String, dynamic> _calculateOptimalPeriod(
    AIOrganismData organism,
    Map<String, dynamic> weatherData,
    DateTime currentDate,
  ) {
    final temperature = weatherData['temperature'] ?? 25.0;
    final humidity = weatherData['humidity'] ?? 60.0;
    final windSpeed = weatherData['windSpeed'] ?? 5.0;
    
    bool isOptimal = true;
    final reasons = <String>[];
    
    // Verificar condições ideais
    if (windSpeed > 15) {
      isOptimal = false;
      reasons.add('Velocidade do vento muito alta');
    }
    
    if (humidity < 40) {
      isOptimal = false;
      reasons.add('Umidade muito baixa');
    }
    
    if (temperature < 15 || temperature > 35) {
      isOptimal = false;
      reasons.add('Temperatura fora da faixa ideal');
    }
    
    // Calcular próximas janelas ideais
    final nextWindows = _calculateNextOptimalWindows(currentDate, weatherData);
    
    return {
      'isOptimal': isOptimal,
      'reasons': reasons,
      'nextWindows': nextWindows,
      'currentConditions': {
        'temperature': temperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
      },
    };
  }

  /// Calcula eficácia de tratamento
  double _calculateTreatmentEfficacy(
    AIOrganismData organism,
    String treatment,
    Map<String, dynamic> conditions,
  ) {
    double efficacy = 0.5; // Base
    
    // Ajustes baseados no tipo de organismo
    if (organism.type == 'pest') {
      if (treatment.contains('inseticida')) efficacy += 0.3;
      if (treatment.contains('biológico')) efficacy += 0.2;
    } else if (organism.type == 'disease') {
      if (treatment.contains('fungicida')) efficacy += 0.3;
      if (treatment.contains('preventivo')) efficacy += 0.2;
    }
    
    // Ajustes baseados nas condições
    final temperature = conditions['temperature'] ?? 25.0;
    final humidity = conditions['humidity'] ?? 60.0;
    
    if (temperature > 20 && temperature < 30) efficacy += 0.1;
    if (humidity > 60 && humidity < 80) efficacy += 0.1;
    
    return efficacy.clamp(0.0, 1.0);
  }

  /// Obtém categoria de risco
  String _getRiskCategory(double risk) {
    if (risk >= 0.8) return 'Muito Alto';
    if (risk >= 0.6) return 'Alto';
    if (risk >= 0.4) return 'Médio';
    if (risk >= 0.2) return 'Baixo';
    return 'Muito Baixo';
  }

  /// Obtém categoria de eficácia
  String _getEfficacyCategory(double efficacy) {
    if (efficacy >= 0.8) return 'Muito Alta';
    if (efficacy >= 0.6) return 'Alta';
    if (efficacy >= 0.4) return 'Média';
    if (efficacy >= 0.2) return 'Baixa';
    return 'Muito Baixa';
  }

  /// Analisa fatores climáticos
  Map<String, dynamic> _analyzeWeatherFactors(AIOrganismData organism, Map<String, dynamic> weatherData) {
    final temperature = weatherData['temperature'] ?? 25.0;
    final humidity = weatherData['humidity'] ?? 60.0;
    final rainfall = weatherData['rainfall'] ?? 0.0;
    
    return {
      'temperature': {
        'value': temperature,
        'status': temperature > 20 && temperature < 30 ? 'Ideal' : 'Desfavorável',
      },
      'humidity': {
        'value': humidity,
        'status': humidity > 70 ? 'Favorável' : 'Desfavorável',
      },
      'rainfall': {
        'value': rainfall,
        'status': organism.type == 'disease' && rainfall > 10 ? 'Favorável' : 'Neutro',
      },
    };
  }

  /// Calcula próximas janelas ideais
  List<Map<String, dynamic>> _calculateNextOptimalWindows(DateTime currentDate, Map<String, dynamic> weatherData) {
    final windows = <Map<String, dynamic>>[];
    
    // Simula próximas janelas baseado no clima
    for (int i = 1; i <= 7; i++) {
      final futureDate = currentDate.add(Duration(days: i));
      final isOptimal = i % 2 == 0; // Simula janelas alternadas
      
      windows.add({
        'date': futureDate.toIso8601String(),
        'isOptimal': isOptimal,
        'reason': isOptimal ? 'Condições climáticas favoráveis' : 'Condições desfavoráveis',
      });
    }
    
    return windows;
  }

  /// Gera previsão climática
  Map<String, dynamic> _generateWeatherForecast(Map<String, dynamic> currentWeather) {
    // Simula previsão de 7 dias
    final forecast = <Map<String, dynamic>>[];
    
    for (int i = 1; i <= 7; i++) {
      forecast.add({
        'day': i,
        'temperature': (currentWeather['temperature'] ?? 25.0) + (i % 3 - 1) * 2,
        'humidity': (currentWeather['humidity'] ?? 60.0) + (i % 2 - 0.5) * 10,
        'rainfall': i % 3 == 0 ? 5.0 : 0.0,
      });
    }
    
    return {'forecast': forecast};
  }

  /// Obtém recomendações de risco
  List<String> _getRiskRecommendations(AIOrganismData organism, double risk) {
    final recommendations = <String>[];
    
    if (risk > 0.7) {
      recommendations.add('Monitoramento intensivo recomendado');
      recommendations.add('Aplicação preventiva de defensivos');
      recommendations.add('Verificar condições climáticas diariamente');
    } else if (risk > 0.5) {
      recommendations.add('Monitoramento semanal');
      recommendations.add('Preparar plano de ação');
    } else {
      recommendations.add('Monitoramento rotineiro');
    }
    
    return recommendations;
  }

  /// Obtém recomendações de aplicação
  List<String> _getApplicationRecommendations(AIOrganismData organism, Map<String, dynamic> optimalPeriod) {
    final recommendations = <String>[];
    
    if (optimalPeriod['isOptimal'] == true) {
      recommendations.add('Condições ideais para aplicação');
      recommendations.add('Aplicar defensivos conforme recomendação');
    } else {
      recommendations.add('Aguardar melhores condições climáticas');
      recommendations.addAll(optimalPeriod['reasons'] as List<String>);
    }
    
    return recommendations;
  }

  /// Obtém recomendações de tratamento
  List<String> _getTreatmentRecommendations(String treatment, double efficacy) {
    final recommendations = <String>[];
    
    if (efficacy > 0.7) {
      recommendations.add('Tratamento altamente recomendado');
      recommendations.add('Aplicar conforme instruções');
    } else if (efficacy > 0.5) {
      recommendations.add('Tratamento moderadamente eficaz');
      recommendations.add('Considerar alternativas');
    } else {
      recommendations.add('Baixa eficácia esperada');
      recommendations.add('Buscar tratamentos alternativos');
    }
    
    return recommendations;
  }

  /// Analisa condições atuais
  Map<String, dynamic> _analyzeCurrentConditions(Map<String, dynamic> weatherData) {
    return {
      'temperature': weatherData['temperature'] ?? 25.0,
      'humidity': weatherData['humidity'] ?? 60.0,
      'windSpeed': weatherData['windSpeed'] ?? 5.0,
      'rainfall': weatherData['rainfall'] ?? 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Analisa fatores de eficácia
  Map<String, dynamic> _analyzeEfficacyFactors(AIOrganismData organism, String treatment, Map<String, dynamic> conditions) {
    return {
      'organismType': organism.type,
      'organismSeverity': organism.severity,
      'treatmentType': treatment,
      'environmentalConditions': conditions,
      'analysisDate': DateTime.now().toIso8601String(),
    };
  }
}
