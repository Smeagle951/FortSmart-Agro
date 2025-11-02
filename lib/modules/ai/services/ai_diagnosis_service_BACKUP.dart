import '../models/ai_diagnosis_result.dart';
import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository.dart';
import '../../../utils/logger.dart';

/// Serviço principal de diagnóstico de IA
class AIDiagnosisService {
  final AIOrganismRepository _organismRepository = AIOrganismRepository();

  /// Diagnóstico por sintomas
  Future<List<AIDiagnosisResult>> diagnoseBySymptoms({
    required List<String> symptoms,
    required String cropName,
    double confidenceThreshold = 0.3,
  }) async {
    try {
      Logger.info('🔍 Iniciando diagnóstico por sintomas');
      Logger.info('📋 Sintomas: $symptoms');
      Logger.info('🌾 Cultura: $cropName');

      // Buscar organismos que afetam a cultura
      final organisms = await _organismRepository.getOrganismsByCrop(cropName);
      
      if (organisms.isEmpty) {
        Logger.warning('⚠️ Nenhum organismo encontrado para a cultura: $cropName');
        return [];
      }

      final results = <AIDiagnosisResult>[];
      
      for (final organism in organisms) {
        final confidence = _calculateSymptomConfidence(symptoms, organism.symptoms);
        
        if (confidence >= confidenceThreshold) {
          results.add(AIDiagnosisResult(
            id: DateTime.now().millisecondsSinceEpoch,
            organismName: organism.name,
            scientificName: organism.scientificName,
            cropName: cropName,
            confidence: confidence,
            symptoms: organism.symptoms,
            managementStrategies: organism.managementStrategies,
            description: organism.description,
            imageUrl: organism.imageUrl,
            diagnosisDate: DateTime.now(),
            diagnosisMethod: 'symptoms',
            metadata: {
              'organismType': organism.type,
              'severity': organism.severity,
              'matchedSymptoms': _findMatchedSymptoms(symptoms, organism.symptoms),
            },
          ));
        }
      }

      // Ordenar por confiança (maior primeiro)
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      Logger.info('✅ Diagnóstico concluído: ${results.length} resultados');
      return results;

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por sintomas: $e');
      return [];
    }
  }

  /// Diagnóstico por imagem (simulado)
  Future<List<AIDiagnosisResult>> diagnoseByImage({
    required String imagePath,
    required String cropName,
    double confidenceThreshold = 0.5,
  }) async {
    try {
      Logger.info('🖼️ Iniciando diagnóstico por imagem');
      Logger.info('📁 Imagem: $imagePath');
      Logger.info('🌾 Cultura: $cropName');

      // TODO: Implementar reconhecimento de imagem real
      // Por enquanto, simula o resultado
      await Future.delayed(const Duration(seconds: 2));

      final organisms = await _organismRepository.getOrganismsByCrop(cropName);
      
      if (organisms.isEmpty) {
        return [];
      }

      // Simula resultado baseado no primeiro organismo encontrado
      final organism = organisms.first;
      
      return [
        AIDiagnosisResult(
          id: DateTime.now().millisecondsSinceEpoch,
          organismName: organism.name,
          scientificName: organism.scientificName,
          cropName: cropName,
          confidence: 0.85, // Simulado
          symptoms: organism.symptoms,
          managementStrategies: organism.managementStrategies,
          description: organism.description,
          imageUrl: organism.imageUrl,
          diagnosisDate: DateTime.now(),
          diagnosisMethod: 'image',
          metadata: {
            'organismType': organism.type,
            'severity': organism.severity,
            'imagePath': imagePath,
          },
        ),
      ];

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

  /// Obtém estatísticas de diagnóstico
  Future<Map<String, dynamic>> getDiagnosisStats() async {
    try {
      final organisms = await _organismRepository.getAllOrganisms();
      
      final pestCount = organisms.where((o) => o.type == 'pest').length;
      final diseaseCount = organisms.where((o) => o.type == 'disease').length;
      
      return {
        'totalOrganisms': organisms.length,
        'pests': pestCount,
        'diseases': diseaseCount,
        'crops': organisms.expand((o) => o.crops).toSet().length,
      };

    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
