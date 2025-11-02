import '../models/enhanced_ai_organism_data.dart';
import '../models/ai_diagnosis_result.dart';
import 'ai_catalog_migration_service.dart';
import '../../../utils/logger.dart';

/// Serviço expandido de diagnóstico de IA com dados ricos do catálogo
class EnhancedAIDiagnosisService {
  final AICatalogMigrationService _migrationService = AICatalogMigrationService();
  List<EnhancedAIOrganismData> _cachedOrganisms = [];
  bool _isCacheLoaded = false;

  /// Inicializa o serviço carregando dados do catálogo
  Future<void> initialize() async {
    if (!_isCacheLoaded) {
      try {
        Logger.info('🔄 Inicializando serviço de diagnóstico expandido...');
        _cachedOrganisms = await _migrationService.migrateAllOrganisms();
        _isCacheLoaded = true;
        Logger.info('✅ Serviço inicializado: ${_cachedOrganisms.length} organismos carregados');
      } catch (e) {
        Logger.error('❌ Erro ao inicializar serviço: $e');
      }
    }
  }

  /// Diagnóstico ultra-avançado por sintomas com dados expandidos
  Future<List<AIDiagnosisResult>> diagnoseBySymptomsEnhanced({
    required List<String> symptoms,
    required String cropName,
    double confidenceThreshold = 0.3,
    String? phenology,
    double? temperature,
    double? humidity,
  }) async {
    try {
      await initialize();
      Logger.info('🔍 Iniciando diagnóstico expandido por sintomas');
      Logger.info('📋 Sintomas: $symptoms');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('🌡️ Temperatura: $temperature°C');
      Logger.info('💧 Umidade: $humidity%');

      // Filtra organismos por cultura
      final cropOrganisms = _cachedOrganisms.where((o) => 
          o.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase())).toList();
      
      if (cropOrganisms.isEmpty) {
        Logger.warning('⚠️ Nenhum organismo encontrado para a cultura: $cropName');
        return [];
      }

      final results = <AIDiagnosisResult>[];
      
      for (final organism in cropOrganisms) {
        final confidence = _calculateEnhancedSymptomConfidence(
          symptoms, 
          organism.symptoms,
          organism.partesAfetadas,
        );
        
        if (confidence >= confidenceThreshold) {
          // Predição de severidade se condições disponíveis
          String? predictedSeverity;
          if (temperature != null && humidity != null) {
            predictedSeverity = organism.predictSeverity(
              temperature: temperature,
              humidity: humidity,
              organismCount: 10, // Valor simulado
            );
          }

          // Diagnóstico por fase se disponível
          final phaseDiagnosis = _diagnoseByPhase(organism, symptoms, phenology);

          results.add(AIDiagnosisResult(
            id: DateTime.now().millisecondsSinceEpoch,
            organismName: organism.name,
            scientificName: organism.scientificName,
            cropName: cropName,
            confidence: confidence,
            symptoms: organism.symptoms,
            managementStrategies: _getEnhancedManagementStrategies(organism, predictedSeverity),
            description: _buildEnhancedDescription(organism, predictedSeverity, phaseDiagnosis),
            imageUrl: organism.imageUrl,
            diagnosisDate: DateTime.now(),
            diagnosisMethod: 'enhanced_symptoms',
            metadata: {
              'organismType': organism.type,
              'severity': organism.severity,
              'matchedSymptoms': _findMatchedSymptoms(symptoms, organism.symptoms),
              'predictedSeverity': predictedSeverity,
              'phaseDiagnosis': phaseDiagnosis?.toMap(),
              'fases': organism.fases.map((f) => f.toMap()).toList(),
              'severidadeDetalhada': organism.severidadeDetalhada.map((k, v) => MapEntry(k, v.toMap())),
              'condicoesFavoraveis': organism.condicoesFavoraveis.toMap(),
              'limiaresAcao': organism.limiaresAcao.toMap(),
              'danoEconomico': organism.danoEconomico.toMap(),
              'fenologia': organism.fenologia,
              'partesAfetadas': organism.partesAfetadas,
              'manejoIntegrado': organism.manejoIntegrado.toMap(),
              'observacoes': organism.observacoes,
              'icone': organism.icone,
              'categoria': organism.categoria,
              'nivelAcao': organism.nivelAcao,
            },
          ));
        }
      }

      // Ordenar por confiança (maior primeiro)
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      Logger.info('✅ Diagnóstico expandido concluído: ${results.length} resultados');
      return results;

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico expandido: $e');
      return [];
    }
  }

  /// Diagnóstico por fase de desenvolvimento
  Future<List<AIDiagnosisResult>> diagnoseByPhaseAndSize({
    required String imagePath,
    required double organismSizeMM,
    required String cropName,
    required String phenology,
    double confidenceThreshold = 0.5,
  }) async {
    try {
      await initialize();
      Logger.info('🔬 Iniciando diagnóstico por fase e tamanho');
      Logger.info('📏 Tamanho: ${organismSizeMM}mm');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('📅 Fenologia: $phenology');

      final cropOrganisms = _cachedOrganisms.where((o) => 
          o.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase())).toList();
      
      if (cropOrganisms.isEmpty) {
        return [];
      }

      final results = <AIDiagnosisResult>[];
      
      for (final organism in cropOrganisms) {
        // Diagnóstico por tamanho
        final phaseDiagnosis = organism.diagnoseBySize(organismSizeMM);
        
        if (phaseDiagnosis != null) {
          final confidence = _calculatePhaseConfidence(phaseDiagnosis, organismSizeMM);
          
          if (confidence >= confidenceThreshold) {
            results.add(AIDiagnosisResult(
              id: DateTime.now().millisecondsSinceEpoch,
              organismName: organism.name,
              scientificName: organism.scientificName,
              cropName: cropName,
              confidence: confidence,
              symptoms: _getPhaseSymptoms(phaseDiagnosis),
              managementStrategies: _getPhaseManagementStrategies(organism, phaseDiagnosis),
              description: _buildPhaseDescription(organism, phaseDiagnosis),
              imageUrl: organism.imageUrl,
              diagnosisDate: DateTime.now(),
              diagnosisMethod: 'phase_size',
              metadata: {
                'organismType': organism.type,
                'phaseDiagnosis': phaseDiagnosis.toMap(),
                'organismSizeMM': organismSizeMM,
                'phenology': phenology,
                'fases': organism.fases.map((f) => f.toMap()).toList(),
                'severidadeDetalhada': organism.severidadeDetalhada.map((k, v) => MapEntry(k, v.toMap())),
                'condicoesFavoraveis': organism.condicoesFavoraveis.toMap(),
                'limiaresAcao': organism.limiaresAcao.toMap(),
                'danoEconomico': organism.danoEconomico.toMap(),
                'fenologia': organism.fenologia,
                'partesAfetadas': organism.partesAfetadas,
                'manejoIntegrado': organism.manejoIntegrado.toMap(),
                'observacoes': organism.observacoes,
                'icone': organism.icone,
                'categoria': organism.categoria,
                'nivelAcao': organism.nivelAcao,
              },
            ));
          }
        }
      }

      // Ordenar por confiança
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      Logger.info('✅ Diagnóstico por fase concluído: ${results.length} resultados');
      return results;

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por fase: $e');
      return [];
    }
  }

  /// Predição de severidade baseada em condições ambientais
  Future<Map<String, dynamic>> predictSeverityByConditions({
    required String organismName,
    required String cropName,
    required double temperature,
    required double humidity,
    required int organismCount,
  }) async {
    try {
      await initialize();
      Logger.info('🔮 Iniciando predição de severidade');
      Logger.info('🦠 Organismo: $organismName');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('🌡️ Temperatura: $temperature°C');
      Logger.info('💧 Umidade: $humidity%');
      Logger.info('🔢 Contagem: $organismCount');

      final organism = _cachedOrganisms.firstWhere(
        (o) => o.name.toLowerCase().contains(organismName.toLowerCase()) &&
               o.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase()),
        orElse: () => throw Exception('Organismo não encontrado'),
      );

      final predictedSeverity = organism.predictSeverity(
        temperature: temperature,
        humidity: humidity,
        organismCount: organismCount,
      );

      final recommendation = organism.getRecommendation(predictedSeverity);
      final productivityLoss = organism.getEstimatedProductivityLoss(predictedSeverity);
      final alertColor = organism.getAlertColor(predictedSeverity);

      final result = {
        'organismName': organism.name,
        'scientificName': organism.scientificName,
        'cropName': cropName,
        'predictedSeverity': predictedSeverity,
        'recommendation': recommendation,
        'productivityLoss': productivityLoss,
        'alertColor': alertColor,
        'conditions': {
          'temperature': temperature,
          'humidity': humidity,
          'organismCount': organismCount,
        },
        'favorableConditions': organism.condicoesFavoraveis.isFavorable(temperature, humidity),
        'limiaresAcao': organism.limiaresAcao.toMap(),
        'severidadeDetalhada': organism.severidadeDetalhada.map((k, v) => MapEntry(k, v.toMap())),
        'danoEconomico': organism.danoEconomico.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      Logger.info('✅ Predição de severidade concluída: $predictedSeverity');
      return result;

    } catch (e) {
      Logger.error('❌ Erro na predição de severidade: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Análise econômica de danos
  Future<Map<String, dynamic>> analyzeEconomicImpact({
    required String organismName,
    required String cropName,
    required double plantedArea,
    required double expectedYield,
    required double cropPrice,
  }) async {
    try {
      await initialize();
      Logger.info('💰 Iniciando análise econômica');
      Logger.info('🦠 Organismo: $organismName');
      Logger.info('🌾 Cultura: $cropName');
      Logger.info('📏 Área: ${plantedArea.toStringAsFixed(2)} hectares');

      final organism = _cachedOrganisms.firstWhere(
        (o) => o.name.toLowerCase().contains(organismName.toLowerCase()) &&
               o.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase()),
        orElse: () => throw Exception('Organismo não encontrado'),
      );

      // Calcula perdas por nível de severidade
      final economicAnalysis = <String, dynamic>{};
      
      for (final entry in organism.severidadeDetalhada.entries) {
        final severity = entry.key;
        final data = entry.value;
        
        // Extrai porcentagem de perda
        final lossPercentage = _extractLossPercentage(data.perdaProdutividade);
        
        // Calcula perdas econômicas
        final expectedProduction = plantedArea * expectedYield;
        final lossProduction = expectedProduction * (lossPercentage / 100);
        final lossRevenue = lossProduction * cropPrice;
        
        economicAnalysis[severity] = {
          'severity': severity,
          'lossPercentage': lossPercentage,
          'lossProduction': lossProduction,
          'lossRevenue': lossRevenue,
          'recommendation': data.acao,
          'alertColor': data.corAlerta,
        };
      }

      final result = {
        'organismName': organism.name,
        'scientificName': organism.scientificName,
        'cropName': cropName,
        'plantedArea': plantedArea,
        'expectedYield': expectedYield,
        'cropPrice': cropPrice,
        'expectedProduction': plantedArea * expectedYield,
        'expectedRevenue': plantedArea * expectedYield * cropPrice,
        'economicAnalysis': economicAnalysis,
        'danoEconomico': organism.danoEconomico.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      Logger.info('✅ Análise econômica concluída');
      return result;

    } catch (e) {
      Logger.error('❌ Erro na análise econômica: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calcula confiança expandida baseada em sintomas e partes afetadas
  double _calculateEnhancedSymptomConfidence(
    List<String> inputSymptoms, 
    List<String> organismSymptoms,
    List<String> organismParts,
  ) {
    if (organismSymptoms.isEmpty) return 0.0;
    
    int matches = 0;
    int totalPossible = organismSymptoms.length;
    
    for (final symptom in inputSymptoms) {
      for (final organismSymptom in organismSymptoms) {
        if (_symptomsMatch(symptom, organismSymptom)) {
          matches++;
          break;
        }
      }
    }
    
    // Bonus por correspondência de partes afetadas
    double bonus = 0.0;
    if (organismParts.isNotEmpty) {
      // Simula verificação de partes afetadas
      bonus = 0.1;
    }
    
    return (matches / totalPossible + bonus).clamp(0.0, 1.0);
  }

  /// Calcula confiança baseada na fase
  double _calculatePhaseConfidence(FaseDesenvolvimento phase, double sizeMM) {
    if (phase.isSizeInRange(sizeMM)) {
      return 0.9; // Alta confiança se tamanho está na faixa
    }
    return 0.3; // Baixa confiança se não está na faixa
  }

  /// Diagnóstico por fase
  FaseDesenvolvimento? _diagnoseByPhase(
    EnhancedAIOrganismData organism, 
    List<String> symptoms, 
    String? phenology,
  ) {
    // Lógica simplificada para diagnóstico por fase
    if (organism.fases.isNotEmpty) {
      return organism.fases.first;
    }
    return null;
  }

  /// Obtém sintomas da fase
  List<String> _getPhaseSymptoms(FaseDesenvolvimento phase) {
    return [phase.danos, phase.caracteristicas];
  }

  /// Obtém estratégias de manejo da fase
  List<String> _getPhaseManagementStrategies(EnhancedAIOrganismData organism, FaseDesenvolvimento phase) {
    final strategies = <String>[];
    
    // Estratégias baseadas na fase
    if (phase.fase.toLowerCase().contains('ovo')) {
      strategies.add('Aplicação preventiva de ovicidas');
    } else if (phase.fase.toLowerCase().contains('larva') || phase.fase.toLowerCase().contains('neonata')) {
      strategies.add('Aplicação de larvicidas');
    } else if (phase.fase.toLowerCase().contains('adulta')) {
      strategies.add('Aplicação de adulticidas');
    }
    
    // Adiciona estratégias do manejo integrado
    strategies.addAll(organism.manejoIntegrado.quimico);
    strategies.addAll(organism.manejoIntegrado.biologico);
    strategies.addAll(organism.manejoIntegrado.cultural);
    
    return strategies;
  }

  /// Obtém estratégias de manejo expandidas
  List<String> _getEnhancedManagementStrategies(EnhancedAIOrganismData organism, String? severity) {
    final strategies = <String>[];
    
    // Estratégias baseadas na severidade
    if (severity != null && organism.severidadeDetalhada.containsKey(severity)) {
      final severidade = organism.severidadeDetalhada[severity]!;
      strategies.add(severidade.acao);
    }
    
    // Adiciona estratégias do manejo integrado
    strategies.addAll(organism.manejoIntegrado.quimico);
    strategies.addAll(organism.manejoIntegrado.biologico);
    strategies.addAll(organism.manejoIntegrado.cultural);
    
    return strategies;
  }

  /// Constrói descrição expandida
  String _buildEnhancedDescription(
    EnhancedAIOrganismData organism, 
    String? predictedSeverity,
    FaseDesenvolvimento? phaseDiagnosis,
  ) {
    final parts = <String>[];
    
    parts.add(organism.description);
    
    if (predictedSeverity != null) {
      parts.add('Severidade Predita: $predictedSeverity');
    }
    
    if (phaseDiagnosis != null) {
      parts.add('Fase Identificada: ${phaseDiagnosis.fase}');
      parts.add('Características: ${phaseDiagnosis.caracteristicas}');
    }
    
    if (organism.danoEconomico.descricao.isNotEmpty) {
      parts.add('Danos Econômicos: ${organism.danoEconomico.descricao}');
    }
    
    if (organism.observacoes.isNotEmpty) {
      parts.add('Observações: ${organism.observacoes.join(', ')}');
    }
    
    return parts.join('\n\n');
  }

  /// Constrói descrição da fase
  String _buildPhaseDescription(EnhancedAIOrganismData organism, FaseDesenvolvimento phase) {
    final parts = <String>[];
    
    parts.add('Fase: ${phase.fase}');
    parts.add('Tamanho: ${phase.tamanhoMM}mm');
    parts.add('Danos: ${phase.danos}');
    parts.add('Duração: ${phase.duracaoDias} dias');
    parts.add('Características: ${phase.caracteristicas}');
    
    if (organism.danoEconomico.descricao.isNotEmpty) {
      parts.add('Danos Econômicos: ${organism.danoEconomico.descricao}');
    }
    
    return parts.join('\n');
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

  /// Extrai porcentagem de perda de uma string
  double _extractLossPercentage(String lossString) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regex.firstMatch(lossString);
    return double.tryParse(match?.group(1) ?? '0') ?? 0.0;
  }

  /// Obtém estatísticas expandidas
  Future<Map<String, dynamic>> getEnhancedStats() async {
    try {
      await initialize();
      
      final Map<String, int> organismsByType = {};
      final Map<String, int> organismsByCrop = {};
      final Map<String, int> organismsByCategory = {};
      
      for (var organism in _cachedOrganisms) {
        // Conta por tipo
        organismsByType[organism.type] = (organismsByType[organism.type] ?? 0) + 1;
        
        // Conta por cultura
        for (final crop in organism.crops) {
          organismsByCrop[crop] = (organismsByCrop[crop] ?? 0) + 1;
        }
        
        // Conta por categoria
        organismsByCategory[organism.categoria] = (organismsByCategory[organism.categoria] ?? 0) + 1;
      }
      
      return {
        'totalOrganisms': _cachedOrganisms.length,
        'byType': organismsByType,
        'byCrop': organismsByCrop,
        'byCategory': organismsByCategory,
        'culturesCount': organismsByCrop.length,
        'hasEnhancedData': _cachedOrganisms.any((o) => o.fases.isNotEmpty),
        'hasSeverityData': _cachedOrganisms.any((o) => o.severidadeDetalhada.isNotEmpty),
        'hasPhaseData': _cachedOrganisms.any((o) => o.fases.isNotEmpty),
        'hasEconomicData': _cachedOrganisms.any((o) => o.danoEconomico.descricao.isNotEmpty),
      };

    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas expandidas: $e');
      return {};
    }
  }
}
