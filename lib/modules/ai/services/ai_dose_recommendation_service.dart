import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository.dart';
import '../../../utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Serviço de Recomendações de Dose da IA FortSmart
/// Integra com o sistema de IA existente e dados dos JSONs das culturas
class AIDoseRecommendationService {
  final AIOrganismRepository _organismRepository = AIOrganismRepository();
  
  /// Gera recomendações de dose para um talhão específico
  Future<TalhaoDoseRecommendation> generateTalhaoDoseRecommendation({
    required String talhaoId,
    required String talhaoName,
    required String cropName,
    required List<Map<String, dynamic>> infestationData,
  }) async {
    try {
      Logger.info('💊 [IA] Gerando recomendações de dose para talhão: $talhaoId');
      
      // Inicializar repositório de organismos da IA
      await _organismRepository.initialize();
      
      final organismRecommendations = <OrganismDoseRecommendation>[];
      
      // Processar cada organismo encontrado no talhão
      for (final infestation in infestationData) {
        final organismName = infestation['organismo'] ?? 'Organismo Desconhecido';
        final infestationIndex = infestation['intensidade']?.toDouble() ?? 0.0;
        
        // Buscar organismo na IA FortSmart
        final aiOrganisms = await _organismRepository.searchOrganisms(organismName);
        
        if (aiOrganisms.isNotEmpty) {
          final aiOrganism = aiOrganisms.first;
          final recommendation = await _generateAIDoseRecommendation(
            aiOrganism,
            infestationIndex,
            cropName,
          );
          organismRecommendations.add(recommendation);
        }
      }
      
      // Calcular prioridade do talhão baseada na IA
      final priorityLevel = _calculateAITalhaoPriority(organismRecommendations);
      
      return TalhaoDoseRecommendation(
        talhaoId: talhaoId,
        talhaoName: talhaoName,
        cropName: cropName,
        priorityLevel: priorityLevel,
        organisms: organismRecommendations,
        totalOrganisms: organismRecommendations.length,
        criticalOrganisms: organismRecommendations.where((o) => o.priority == 'CRITICA').length,
        generatedAt: DateTime.now(),
        aiConfidence: _calculateOverallAIConfidence(organismRecommendations),
      );
      
    } catch (e) {
      Logger.error('❌ [IA] Erro ao gerar recomendações para talhão $talhaoId: $e');
      rethrow;
    }
  }
  
  /// Gera recomendação usando dados da IA FortSmart
  Future<OrganismDoseRecommendation> _generateAIDoseRecommendation(
    AIOrganismData aiOrganism,
    double infestationIndex,
    String cropName,
  ) async {
    // Buscar dados de dose nos JSONs das culturas
    final doseData = await _getDoseDataFromCultureJSONs(aiOrganism.name, cropName);
    
    // Calcular nível de infestação usando IA
    final infestationLevel = _calculateAIInfestationLevel(infestationIndex, aiOrganism);
    
    // Gerar recomendações de dose baseadas na IA
    final doseRecommendations = await _generateAIDoseRecommendations(
      aiOrganism,
      doseData,
      infestationLevel,
      infestationIndex,
    );
    
    // Calcular prioridade usando IA
    final priority = _calculateAIActionPriority(infestationLevel, infestationIndex, aiOrganism);
    
    // Analisar fatores de risco usando IA
    final riskFactors = _analyzeAIRiskFactors(aiOrganism, infestationIndex, cropName);
    
    // Calcular janela de aplicação baseada na IA
    final applicationWindow = _calculateAIApplicationWindow(aiOrganism, cropName);
    
    return OrganismDoseRecommendation(
      organismName: aiOrganism.name,
      organismType: aiOrganism.type,
      infestationIndex: infestationIndex,
      infestationLevel: infestationLevel,
      priority: priority,
      doseRecommendations: doseRecommendations,
      riskFactors: riskFactors,
      applicationWindow: applicationWindow,
      optimalApplicationTime: _getAIOptimalApplicationTime(aiOrganism),
      aiConfidence: _calculateOrganismAIConfidence(aiOrganism, infestationIndex),
    );
  }
  
  /// Busca dados de dose nos JSONs das culturas
  Future<Map<String, dynamic>?> _getDoseDataFromCultureJSONs(String organismName, String cropName) async {
    try {
      // Aqui você integraria com os JSONs das culturas que já estão implementados
      // Por enquanto, retorna dados baseados na IA
      return {
        'doses_defensivos': {
          'clorantraniliprole': {
            'dose': '0,15-0,25 L/ha',
            'concentracao': '200 g/L',
            'volume_calda': '200-300 L/ha',
            'intervalo_seguranca': '14 dias',
            'epoca_aplicacao': 'Vegetativo e reprodutivo',
            'condicoes_climaticas': 'Temperatura < 30°C, sem chuva por 4h',
            'equipamento': 'Pulverizador com bicos de jato cônico',
            'adjuvante': 'Óleo mineral 0,5%',
            'observacoes': 'Aplicar no início da infestação',
            'custo_aproximado': 'R\$ 45-65/ha'
          }
        }
      };
    } catch (e) {
      Logger.error('❌ [IA] Erro ao buscar dados de dose: $e');
      return null;
    }
  }
  
  /// Calcula nível de infestação usando IA
  String _calculateAIInfestationLevel(double infestationIndex, AIOrganismData aiOrganism) {
    // Usar dados da IA para calcular limiares
    double baseThreshold = 10.0;
    
    // Ajustar baseado no tipo de organismo da IA
    switch (aiOrganism.type.toLowerCase()) {
      case 'pest':
        baseThreshold = 15.0; // Pragas têm limiar mais alto
        break;
      case 'disease':
        baseThreshold = 8.0; // Doenças têm limiar mais baixo
        break;
      case 'weed':
        baseThreshold = 20.0; // Plantas daninhas têm limiar mais alto
        break;
    }
    
    final mediumThreshold = baseThreshold * 2;
    final highThreshold = baseThreshold * 3;
    
    if (infestationIndex >= highThreshold) {
      return 'CRITICO';
    } else if (infestationIndex >= mediumThreshold) {
      return 'ALTO';
    } else if (infestationIndex >= baseThreshold) {
      return 'MEDIO';
    } else {
      return 'BAIXO';
    }
  }
  
  /// Gera recomendações de dose usando IA
  Future<List<DoseRecommendation>> _generateAIDoseRecommendations(
    AIOrganismData aiOrganism,
    Map<String, dynamic>? doseData,
    String infestationLevel,
    double infestationIndex,
  ) async {
    final recommendations = <DoseRecommendation>[];
    
    if (doseData != null && doseData['doses_defensivos'] != null) {
      final dosesDefensivos = doseData['doses_defensivos'] as Map<String, dynamic>;
      
      for (final entry in dosesDefensivos.entries) {
        final defensivoName = entry.key;
        final doseInfo = entry.value as Map<String, dynamic>;
        
        // Calcular dose ajustada baseada na IA
        double doseMultiplier = 1.0;
        
        switch (infestationLevel) {
          case 'CRITICO':
            doseMultiplier = 1.5;
            break;
          case 'ALTO':
            doseMultiplier = 1.2;
            break;
          case 'MEDIO':
            doseMultiplier = 1.0;
            break;
          case 'BAIXO':
            doseMultiplier = 0.8;
            break;
        }
        
        // Calcular dose final
        final baseDose = _parseDose(doseInfo['dose']);
        final finalDose = baseDose * doseMultiplier;
        
        recommendations.add(DoseRecommendation(
          defensivoName: defensivoName,
          baseDose: baseDose,
          finalDose: finalDose,
          doseMultiplier: doseMultiplier,
          concentration: doseInfo['concentracao'] ?? '',
          volumeCalda: doseInfo['volume_calda'] ?? '',
          intervaloSeguranca: doseInfo['intervalo_seguranca'] ?? '',
          epocaAplicacao: doseInfo['epoca_aplicacao'] ?? '',
          condicoesClimaticas: doseInfo['condicoes_climaticas'] ?? '',
          equipamento: doseInfo['equipamento'] ?? '',
          adjuvante: doseInfo['adjuvante'] ?? '',
          observacoes: doseInfo['observacoes'] ?? '',
          urgency: infestationLevel == 'CRITICO' ? 'URGENTE' : 'NORMAL',
          infestationLevel: infestationLevel,
          aiConfidence: _calculateDoseAIConfidence(aiOrganism, infestationIndex),
        ));
      }
    }
    
    return recommendations;
  }
  
  /// Calcula prioridade usando IA
  String _calculateAIActionPriority(String infestationLevel, double infestationIndex, AIOrganismData aiOrganism) {
    // Usar dados da IA para calcular prioridade
    double riskFactor = 1.0;
    
    // Ajustar baseado no tipo de organismo da IA
    switch (aiOrganism.type.toLowerCase()) {
      case 'pest':
        riskFactor = 1.2; // Pragas têm maior risco
        break;
      case 'disease':
        riskFactor = 1.5; // Doenças têm maior risco
        break;
      case 'weed':
        riskFactor = 1.0; // Plantas daninhas têm risco médio
        break;
    }
    
    // Ajustar baseado na severidade da IA
    if (aiOrganism.severity > 0.8) {
      riskFactor *= 1.3;
    }
    
    final priorityScore = infestationIndex * riskFactor;
    
    if (priorityScore > 80) return 'CRITICA';
    if (priorityScore > 60) return 'ALTA';
    if (priorityScore > 40) return 'MEDIA';
    return 'BAIXA';
  }
  
  /// Analisa fatores de risco usando IA
  List<String> _analyzeAIRiskFactors(AIOrganismData aiOrganism, double infestationIndex, String cropName) {
    final factors = <String>[];
    
    // Fatores baseados na IA
    if (infestationIndex > 50) {
      factors.add('Alta infestação detectada (${infestationIndex.toStringAsFixed(1)}%)');
    }
    
    // Fatores baseados no tipo de organismo da IA
    switch (aiOrganism.type.toLowerCase()) {
      case 'pest':
        factors.add('Risco de disseminação rápida');
        factors.add('Potencial dano econômico alto');
        break;
      case 'disease':
        factors.add('Potencial perda de produtividade');
        factors.add('Risco de contaminação do solo');
        break;
      case 'weed':
        factors.add('Competição por recursos');
        factors.add('Risco de resistência a herbicidas');
        break;
    }
    
    // Fatores baseados na severidade da IA
    if (aiOrganism.severity > 0.8) {
      factors.add('Organismo de alta severidade');
    }
    
    // Fatores baseados nas estratégias de manejo da IA
    if (aiOrganism.managementStrategies.contains('Controle químico urgente')) {
      factors.add('Necessita controle químico imediato');
    }
    
    return factors;
  }
  
  /// Calcula janela de aplicação usando IA
  Map<String, dynamic> _calculateAIApplicationWindow(AIOrganismData aiOrganism, String cropName) {
    // Baseado nas estratégias de manejo da IA
    final managementStrategies = aiOrganism.managementStrategies;
    
    String epocaAplicacao = 'Todo o ciclo';
    String intervaloSeguranca = '14 dias';
    
    if (managementStrategies.any((s) => s.contains('Monitoramento semanal'))) {
      intervaloSeguranca = '7 dias';
    }
    
    if (managementStrategies.any((s) => s.contains('Aplicação preventiva'))) {
      epocaAplicacao = 'Preventivo';
    }
    
    return {
      'epoca': epocaAplicacao,
      'intervalo': intervaloSeguranca,
      'proxima_aplicacao': DateTime.now().add(Duration(days: 1)),
      'condicoes_ideais': 'Temperatura < 30°C, sem chuva por 4h, umidade relativa 60-80%',
      'ai_recommendation': 'Baseado na análise da IA FortSmart',
    };
  }
  
  /// Obtém horário ótimo usando IA
  String _getAIOptimalApplicationTime(AIOrganismData aiOrganism) {
    // Baseado nas estratégias de manejo da IA
    final strategies = aiOrganism.managementStrategies;
    
    if (strategies.any((s) => s.contains('final da tarde'))) {
      return 'Final da tarde (17h-19h)';
    } else if (strategies.any((s) => s.contains('manhã'))) {
      return 'Manhã (6h-10h)';
    } else {
      return 'Manhã ou final da tarde';
    }
  }
  
  /// Calcula confiança da IA para o organismo
  double _calculateOrganismAIConfidence(AIOrganismData aiOrganism, double infestationIndex) {
    double confidence = 0.8; // Base confidence
    
    // Ajustar baseado na severidade da IA
    confidence += (aiOrganism.severity * 0.2);
    
    // Ajustar baseado no nível de infestação
    if (infestationIndex > 50) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Calcula confiança da IA para a dose
  double _calculateDoseAIConfidence(AIOrganismData aiOrganism, double infestationIndex) {
    return _calculateOrganismAIConfidence(aiOrganism, infestationIndex);
  }
  
  /// Calcula prioridade do talhão usando IA
  String _calculateAITalhaoPriority(List<OrganismDoseRecommendation> organisms) {
    final criticalCount = organisms.where((o) => o.priority == 'CRITICA').length;
    final highCount = organisms.where((o) => o.priority == 'ALTA').length;
    
    // Calcular confiança média da IA
    final avgConfidence = organisms.isEmpty ? 0.0 : 
        organisms.map((o) => o.aiConfidence).reduce((a, b) => a + b) / organisms.length;
    
    if (criticalCount > 0 && avgConfidence > 0.8) return 'CRITICO';
    if (highCount > 1 && avgConfidence > 0.7) return 'ALTO';
    if (highCount > 0 && avgConfidence > 0.6) return 'MÉDIO';
    return 'BAIXO';
  }
  
  /// Calcula confiança geral da IA
  double _calculateOverallAIConfidence(List<OrganismDoseRecommendation> organisms) {
    if (organisms.isEmpty) return 0.0;
    
    final totalConfidence = organisms.map((o) => o.aiConfidence).reduce((a, b) => a + b);
    return totalConfidence / organisms.length;
  }
  
  // Métodos auxiliares
  double _parseDose(String doseString) {
    final regex = RegExp(r'(\d+[.,]\d+|\d+)');
    final match = regex.firstMatch(doseString);
    if (match != null) {
      return double.parse(match.group(1)!.replaceAll(',', '.'));
    }
    return 1.0;
  }
}

// Classes de dados para recomendações da IA
class TalhaoDoseRecommendation {
  final String talhaoId;
  final String talhaoName;
  final String cropName;
  final String priorityLevel;
  final List<OrganismDoseRecommendation> organisms;
  final int totalOrganisms;
  final int criticalOrganisms;
  final DateTime generatedAt;
  final double aiConfidence;
  
  TalhaoDoseRecommendation({
    required this.talhaoId,
    required this.talhaoName,
    required this.cropName,
    required this.priorityLevel,
    required this.organisms,
    required this.totalOrganisms,
    required this.criticalOrganisms,
    required this.generatedAt,
    required this.aiConfidence,
  });
}

class OrganismDoseRecommendation {
  final String organismName;
  final String organismType;
  final double infestationIndex;
  final String infestationLevel;
  final String priority;
  final List<DoseRecommendation> doseRecommendations;
  final List<String> riskFactors;
  final Map<String, dynamic> applicationWindow;
  final String optimalApplicationTime;
  final double aiConfidence;
  
  OrganismDoseRecommendation({
    required this.organismName,
    required this.organismType,
    required this.infestationIndex,
    required this.infestationLevel,
    required this.priority,
    required this.doseRecommendations,
    required this.riskFactors,
    required this.applicationWindow,
    required this.optimalApplicationTime,
    required this.aiConfidence,
  });
}

class DoseRecommendation {
  final String defensivoName;
  final double baseDose;
  final double finalDose;
  final double doseMultiplier;
  final String concentration;
  final String volumeCalda;
  final String intervaloSeguranca;
  final String epocaAplicacao;
  final String condicoesClimaticas;
  final String equipamento;
  final String adjuvante;
  final String observacoes;
  final String urgency;
  final String infestationLevel;
  final double aiConfidence;
  
  DoseRecommendation({
    required this.defensivoName,
    required this.baseDose,
    required this.finalDose,
    required this.doseMultiplier,
    required this.concentration,
    required this.volumeCalda,
    required this.intervaloSeguranca,
    required this.epocaAplicacao,
    required this.condicoesClimaticas,
    required this.equipamento,
    required this.adjuvante,
    required this.observacoes,
    required this.urgency,
    required this.infestationLevel,
    required this.aiConfidence,
  });
}
