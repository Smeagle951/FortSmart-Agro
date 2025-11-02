import '../models/ai_diagnosis_result.dart';
import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository_integrated.dart';
import '../../../utils/logger.dart';
import '../../../services/diagnosis_feedback_service.dart';

/// Serviço de diagnóstico de IA INTEGRADO com aprendizado
/// Usa JSONs ricos + Feedback offline para melhorar precisão
class AIDiagnosisServiceIntegrated {
  final AIOrganismRepositoryIntegrated _organismRepository = AIOrganismRepositoryIntegrated();
  final DiagnosisFeedbackService _feedbackService = DiagnosisFeedbackService();

  /// Diagnóstico por sintomas COM APRENDIZADO OFFLINE
  Future<List<AIDiagnosisResult>> diagnoseBySymptoms({
    required List<String> symptoms,
    required String cropName,
    double confidenceThreshold = 0.3,
    String? farmId,
  }) async {
    try {
      Logger.info('🔍 Iniciando diagnóstico inteligente por sintomas');
      Logger.info('📋 Sintomas: $symptoms');
      Logger.info('🌾 Cultura: $cropName');

      // 1. Buscar organismos da cultura (do JSON)
      final organisms = await _organismRepository.getOrganismsByCrop(cropName);
      
      if (organisms.isEmpty) {
        Logger.warning('⚠️ Nenhum organismo encontrado para a cultura: $cropName');
        return [];
      }
      
      Logger.info('📚 ${organisms.length} organismos encontrados no catálogo JSON');

      // 2. NOVO: Buscar histórico de feedback para ajustar confiança (OFFLINE)
      final stats = await _feedbackService.getCropStats(
        farmId ?? 'default_farm',
        cropName,
      );
      
      final historicalAccuracy = stats.containsKey('accuracy') && !stats.containsKey('noData')
          ? (double.tryParse(stats['accuracy'] as String? ?? '75') ?? 75) / 100
          : 0.75;
      
      Logger.info('📊 Acurácia histórica da IA para $cropName: ${(historicalAccuracy * 100).toStringAsFixed(1)}%');

      final results = <AIDiagnosisResult>[];
      
      for (final organism in organisms) {
        // 3. Calcular confiança baseada em sintomas
        var confidence = _calculateSymptomConfidence(symptoms, organism.symptoms);
        
        // 4. NOVO: Ajustar confiança baseado em feedback histórico
        confidence = _adjustConfidenceByFeedback(
          baseConfidence: confidence,
          organismName: organism.name,
          cropName: cropName,
          historicalAccuracy: historicalAccuracy,
          organism: organism,
        );
        
        if (confidence >= confidenceThreshold) {
          // 5. Calcular severidade prevista (do JSON + feedback)
          final predictedSeverity = _calculatePredictedSeverity(organism);
          
          results.add(AIDiagnosisResult(
            id: DateTime.now().millisecondsSinceEpoch + results.length,
            organismName: organism.name,
            scientificName: organism.scientificName,
            cropName: cropName,
            confidence: confidence, // CONFIANÇA AJUSTADA!
            symptoms: organism.symptoms,
            managementStrategies: organism.managementStrategies,
            description: organism.description,
            imageUrl: organism.imageUrl,
            diagnosisDate: DateTime.now(),
            diagnosisMethod: 'symptoms',
            metadata: {
              'organismType': organism.type,
              'severity': predictedSeverity,
              'matchedSymptoms': _findMatchedSymptoms(symptoms, organism.symptoms),
              'historicalAccuracy': historicalAccuracy,
              'confidenceAdjusted': true,
              'dataSource': 'json_rich',
              'learningEnabled': true,
              'feedbackCount': organism.characteristics['feedbackCount'] ?? 0,
            },
          ));
        }
      }

      // Ordenar por confiança ajustada (maior primeiro)
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      Logger.info('✅ Diagnóstico concluído: ${results.length} resultados');
      if (results.isNotEmpty) {
        Logger.info('   🏆 Melhor match: ${results.first.organismName} (${(results.first.confidence * 100).toStringAsFixed(1)}%)');
      }
      
      return results;

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por sintomas: $e');
      return [];
    }
  }

  /// NOVO: Ajusta confiança baseado em feedback histórico
  double _adjustConfidenceByFeedback({
    required double baseConfidence,
    required String organismName,
    required String cropName,
    required double historicalAccuracy,
    required AIOrganismData organism,
  }) {
    try {
      // Se organismo tem dados de feedback, usar eles
      if (organism.characteristics.containsKey('accuracy')) {
        final organismAccuracy = organism.characteristics['accuracy'] as double;
        
        Logger.info('   🎯 $organismName: acurácia específica ${(organismAccuracy * 100).toStringAsFixed(1)}%');
        
        // Ajustar confiança baseado na acurácia do organismo
        final adjustment = (organismAccuracy - 0.75) * 0.2; // Max ±20%
        return (baseConfidence + adjustment).clamp(0.0, 1.0);
      }
      
      // Caso contrário, usar acurácia geral da cultura
      final adjustment = (historicalAccuracy - 0.75) * 0.15; // Max ±15%
      return (baseConfidence + adjustment).clamp(0.0, 1.0);
      
    } catch (e) {
      // Em caso de erro, retornar confiança base
      return baseConfidence;
    }
  }

  /// Calcula severidade prevista (do JSON + feedback)
  double _calculatePredictedSeverity(AIOrganismData organism) {
    // Se tem severidade real do feedback, usar ela
    if (organism.characteristics.containsKey('realSeverity')) {
      return organism.characteristics['realSeverity'] as double;
    }
    
    // Caso contrário, usar severidade do JSON
    return organism.severity * 100;
  }

  /// Diagnóstico por imagem (preparado para ML futuro)
  Future<List<AIDiagnosisResult>> diagnoseByImage({
    required String imagePath,
    required String cropName,
    double confidenceThreshold = 0.5,
    String? farmId,
  }) async {
    try {
      Logger.info('🖼️ Iniciando diagnóstico por imagem');
      Logger.info('📁 Imagem: $imagePath');
      Logger.info('🌾 Cultura: $cropName');

      // TODO: Implementar reconhecimento de imagem real com TensorFlow Lite
      // Por enquanto, retornar lista vazia
      Logger.warning('⚠️ Reconhecimento de imagem ainda não implementado');
      
      return [];

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por imagem: $e');
      return [];
    }
  }

  /// Calcula confiança baseada na similaridade de sintomas
  double _calculateSymptomConfidence(List<String> inputSymptoms, List<String> organismSymptoms) {
    if (organismSymptoms.isEmpty) return 0.0;
    
    int matches = 0;
    for (final symptom in inputSymptoms) {
      for (final organismSymptom in organismSymptoms) {
        if (_symptomsMatch(symptom, organismSymptom)) {
          matches++;
          break;
        }
      }
    }
    
    // Confiança baseada na proporção de sintomas que casam
    return matches / organismSymptoms.length;
  }

  /// Verifica se dois sintomas são similares
  bool _symptomsMatch(String symptom1, String symptom2) {
    final normalized1 = _normalizeSymptom(symptom1);
    final normalized2 = _normalizeSymptom(symptom2);
    
    return normalized1.contains(normalized2) || normalized2.contains(normalized1);
  }

  /// Normaliza sintoma para comparação
  String _normalizeSymptom(String symptom) {
    return symptom.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  /// Encontra sintomas que correspondem
  List<String> _findMatchedSymptoms(List<String> inputSymptoms, List<String> organismSymptoms) {
    final matches = <String>[];
    
    for (final symptom in inputSymptoms) {
      for (final organismSymptom in organismSymptoms) {
        if (_symptomsMatch(symptom, organismSymptom)) {
          matches.add(organismSymptom);
          break;
        }
      }
    }
    
    return matches;
  }

  /// Busca organismos por nome ou sintoma
  Future<List<AIOrganismData>> searchOrganisms(String query) async {
    try {
      Logger.info('🔍 Buscando organismos: $query');
      
      final organisms = await _organismRepository.getAllOrganisms();
      
      return organisms.where((organism) {
        final normalizedQuery = query.toLowerCase();
        
        return organism.name.toLowerCase().contains(normalizedQuery) ||
               organism.scientificName.toLowerCase().contains(normalizedQuery) ||
               organism.symptoms.any((symptom) => 
                   symptom.toLowerCase().contains(normalizedQuery)) ||
               organism.keywords.any((keyword) => 
                   keyword.toLowerCase().contains(normalizedQuery));
      }).toList();

    } catch (e) {
      Logger.error('❌ Erro na busca de organismos: $e');
      return [];
    }
  }

  /// Obtém estatísticas de diagnóstico COM dados de aprendizado
  Future<Map<String, dynamic>> getDiagnosisStats() async {
    try {
      final organisms = await _organismRepository.getAllOrganisms();
      
      final pestCount = organisms.where((o) => o.type == 'pest').length;
      final diseaseCount = organisms.where((o) => o.type == 'disease').length;
      final enrichedCount = organisms.where((o) => 
        o.characteristics.containsKey('feedbackCount')
      ).length;
      
      return {
        'totalOrganisms': organisms.length,
        'pests': pestCount,
        'diseases': diseaseCount,
        'crops': organisms.expand((o) => o.crops).toSet().length,
        'dataSource': 'json_files',
        'enrichedWithFeedback': enrichedCount,
        'enrichmentRate': (enrichedCount / organisms.length * 100).toStringAsFixed(1),
      };

    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
}

