import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ai_organism_data.dart';
import '../../../utils/logger.dart';
import '../../../services/diagnosis_feedback_service.dart';
import '../../../models/organism_catalog.dart';
import '../../../services/organism_catalog_loader_service.dart';

/// Repositório INTEGRADO de organismos da IA
/// FONTE ÚNICA: JSONs em assets/data/
/// APRENDIZADO: Sistema de feedback offline
class AIOrganismRepositoryIntegrated {
  static final List<AIOrganismData> _organisms = [];
  static bool _initialized = false;
  
  final DiagnosisFeedbackService _feedbackService = DiagnosisFeedbackService();
  final OrganismCatalogLoaderService _loaderService = OrganismCatalogLoaderService();

  /// Inicializa o repositório carregando DOS JSONs (fonte única)
  Future<void> initialize() async {
    if (_initialized && _organisms.isNotEmpty) {
      Logger.info('✅ Repositório de IA já inicializado com ${_organisms.length} organismos');
      return;
    }

    try {
      Logger.info('🔍 Inicializando IA Agronômica com JSONs ricos...');
      
      // Limpar dados antigos
      _organisms.clear();
      
      // 1. Carregar organismos DOS JSONs (NÃO hardcode!)
      await _loadOrganismsFromJSON();
      
      // 2. Enriquecer com dados de feedback (aprendizado OFFLINE)
      await _enrichWithFeedbackData();
      
      _initialized = true;
      Logger.info('✅ IA Agronômica inicializada: ${_organisms.length} organismos');
      Logger.info('   📊 Dados carregados dos JSONs');
      Logger.info('   🎓 Enriquecidos com feedback de usuários');

    } catch (e) {
      Logger.error('❌ Erro ao inicializar repositório de IA: $e');
      _initialized = false;
    }
  }

  /// Carrega organismos DOS JSONs (fonte única de verdade)
  Future<void> _loadOrganismsFromJSON() async {
    try {
      Logger.info('📂 Carregando organismos dos JSONs...');
      
      // Lista de arquivos JSON por cultura
      final cultureFiles = [
        'organismos_soja.json',
        'organismos_milho.json',
        'organismos_algodao.json',
        'organismos_feijao.json',
        'organismos_trigo.json',
        'organismos_sorgo.json',
        'organismos_girassol.json',
        'organismos_aveia.json',
        'organismos_gergelim.json',
        'organismos_arroz.json',
        'organismos_batata.json',
        'organismos_cana_acucar.json',
        'organismos_tomate.json',
      ];
      
      int totalLoaded = 0;
      
      for (final fileName in cultureFiles) {
        try {
          final jsonString = await rootBundle.loadString('assets/data/$fileName');
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          
          final cultura = jsonData['cultura'] as String;
          final organismos = jsonData['organismos'] as List<dynamic>;
          
          for (final orgData in organismos) {
            final organism = _createAIOrganismFromJSON(orgData, cultura);
            if (organism != null) {
              _organisms.add(organism);
              totalLoaded++;
            }
          }
          
          Logger.info('   ✅ $fileName: ${organismos.length} organismos');
          
        } catch (e) {
          Logger.warning('   ⚠️ Arquivo não encontrado ou erro: $fileName');
          continue;
        }
      }
      
      Logger.info('✅ Total carregado dos JSONs: $totalLoaded organismos');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos dos JSONs: $e');
      throw e;
    }
  }

  /// Cria AIOrganismData a partir do JSON
  AIOrganismData? _createAIOrganismFromJSON(Map<String, dynamic> json, String cultura) {
    try {
      return AIOrganismData(
        id: json['id'].hashCode, // Hash do ID string para int
        name: json['nome'] as String,
        scientificName: json['nome_cientifico'] as String,
        type: (json['categoria'] as String).toLowerCase() == 'praga' ? 'pest' : 'disease',
        crops: [cultura],
        
        // Sintomas do JSON
        symptoms: List<String>.from(json['sintomas'] ?? []),
        
        // Estratégias de manejo do JSON
        managementStrategies: [
          ...List<String>.from(json['manejo_cultural'] ?? []),
          ...List<String>.from(json['manejo_biologico'] ?? []),
          ...List<String>.from(json['manejo_quimico'] ?? []),
        ],
        
        // Descrição do JSON
        description: json['dano_economico'] as String? ?? json['observacoes'] as String? ?? '',
        
        // Ícone/imagem
        imageUrl: 'assets/images/${json['categoria']?.toLowerCase()}/${json['id']}.jpg',
        
        // Características do JSON
        characteristics: {
          'partes_afetadas': json['partes_afetadas'] ?? [],
          'fenologia': json['fenologia'] ?? [],
          'nivel_acao': json['nivel_acao'] ?? '',
          'niveis_infestacao': json['niveis_infestacao'] ?? {},
          'condicoes_favoraveis': json['condicoes_favoraveis'] ?? {},
          'tamanho_mm': json['tamanho_mm'] ?? {},
          'fases_desenvolvimento': json['fases_desenvolvimento'] ?? [],
        },
        
        // Severidade calculada do JSON
        severity: _calculateSeverityFromJSON(json),
        
        // Keywords do JSON
        keywords: _extractKeywordsFromJSON(json),
        
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao criar organismo do JSON: ${json['nome']} - $e');
      return null;
    }
  }

  /// Calcula severidade a partir dos dados do JSON
  double _calculateSeverityFromJSON(Map<String, dynamic> json) {
    try {
      // Usar níveis de infestação do JSON
      final niveis = json['niveis_infestacao'] as Map<String, dynamic>?;
      if (niveis != null && niveis.containsKey('critico')) {
        // Se tem nível crítico, é severidade alta
        return 0.9;
      }
      
      // Usar dano econômico
      final dano = (json['dano_economico'] as String? ?? '').toLowerCase();
      if (dano.contains('80%') || dano.contains('70%') || dano.contains('quarentenária')) {
        return 0.9;
      } else if (dano.contains('50%') || dano.contains('40%')) {
        return 0.7;
      } else if (dano.contains('30%') || dano.contains('20%')) {
        return 0.5;
      }
      
      return 0.6; // Padrão
      
    } catch (e) {
      return 0.5;
    }
  }

  /// Extrai keywords do JSON
  List<String> _extractKeywordsFromJSON(Map<String, dynamic> json) {
    final keywords = <String>[];
    
    keywords.add(json['nome'] as String);
    keywords.add(json['nome_cientifico'] as String);
    keywords.add(json['cultura_id'] as String? ?? '');
    
    // Adicionar sintomas como keywords
    if (json['sintomas'] != null) {
      keywords.addAll(List<String>.from(json['sintomas']));
    }
    
    return keywords.map((k) => k.toLowerCase()).toList();
  }

  /// Enriquece dados da IA com feedback dos usuários (aprendizado OFFLINE)
  Future<void> _enrichWithFeedbackData() async {
    try {
      Logger.info('🎓 Enriquecendo IA com dados de feedback OFFLINE...');
      
      int enrichedCount = 0;
      
      // Para cada organismo carregado do JSON
      for (var i = 0; i < _organisms.length; i++) {
        final organism = _organisms[i];
        
        // Buscar feedbacks OFFLINE para este organismo
        final feedbacks = await _feedbackService.getFeedbacksByCrop(
          'default_farm', // TODO: Usar farmId real do Provider
          organism.crops.first,
        );
        
        // Filtrar feedbacks relevantes para este organismo
        final relevantFeedbacks = feedbacks.where((f) =>
          f.systemPredictedOrganism.toLowerCase() == organism.name.toLowerCase() ||
          f.userCorrectedOrganism?.toLowerCase() == organism.name.toLowerCase()
        ).toList();
        
        if (relevantFeedbacks.isEmpty) continue;
        
        // Calcular acurácia deste organismo baseado em feedback
        final confirmed = relevantFeedbacks.where((f) => f.userConfirmed).length;
        final totalFeedbacks = relevantFeedbacks.length;
        final accuracy = confirmed / totalFeedbacks;
        
        // Calcular severidade real média (dos feedbacks corrigidos)
        final correctedFeedbacks = relevantFeedbacks.where((f) => 
          !f.userConfirmed && f.userCorrectedSeverity != null
        ).toList();
        
        if (correctedFeedbacks.isNotEmpty) {
          final avgRealSeverity = correctedFeedbacks
              .map((f) => f.userCorrectedSeverity!)
              .reduce((a, b) => a + b) / correctedFeedbacks.length;
          
          // Ajustar severidade do organismo baseado em dados REAIS
          final adjustedSeverity = (organism.severity * 100 + avgRealSeverity) / 2 / 100;
          
          // Criar cópia enriquecida do organismo
          _organisms[i] = organism.copyWith(
            severity: adjustedSeverity,
            characteristics: {
              ...organism.characteristics,
              // Metadados de aprendizado
              'feedbackCount': totalFeedbacks,
              'accuracy': accuracy,
              'realSeverity': avgRealSeverity,
              'lastFeedbackDate': relevantFeedbacks.last.feedbackDate.toIso8601String(),
              'learningSource': 'feedback_offline',
            },
          );
          
          enrichedCount++;
          
          Logger.info('   ✅ ${organism.name}: $totalFeedbacks feedbacks, ${(accuracy * 100).toStringAsFixed(1)}% acurácia, severidade ajustada');
        }
      }
      
      Logger.info('✅ IA enriquecida: $enrichedCount organismos aprenderam com feedback');
      
    } catch (e) {
      Logger.error('❌ Erro ao enriquecer IA com feedback: $e');
      // Continuar mesmo com erro - IA funcionará com dados do JSON
    }
  }

  /// Obtém todos os organismos (do JSON + enriquecidos)
  Future<List<AIOrganismData>> getAllOrganisms() async {
    await initialize();
    return List.from(_organisms);
  }

  /// Obtém organismos por cultura
  Future<List<AIOrganismData>> getOrganismsByCrop(String cropName) async {
    await initialize();
    
    return _organisms.where((organism) {
      return organism.crops.any((crop) => 
          crop.toLowerCase() == cropName.toLowerCase());
    }).toList();
  }

  /// Obtém organismos por tipo
  Future<List<AIOrganismData>> getOrganismsByType(String type) async {
    await initialize();
    
    return _organisms.where((organism) => 
        organism.type.toLowerCase() == type.toLowerCase()).toList();
  }

  /// Busca organismos por nome ou sintoma
  Future<List<AIOrganismData>> searchOrganisms(String query) async {
    await initialize();
    
    final normalizedQuery = query.toLowerCase();
    
    return _organisms.where((organism) {
      return organism.name.toLowerCase().contains(normalizedQuery) ||
             organism.scientificName.toLowerCase().contains(normalizedQuery) ||
             organism.symptoms.any((symptom) => 
                 symptom.toLowerCase().contains(normalizedQuery)) ||
             organism.keywords.any((keyword) => 
                 keyword.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  /// Obtém organismo por ID
  Future<AIOrganismData?> getOrganismById(int id) async {
    await initialize();
    
    try {
      return _organisms.firstWhere((organism) => organism.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Recarrega e reaprende (chamar após novos feedbacks)
  Future<void> reloadAndRelearn() async {
    Logger.info('🔄 Recarregando IA com novos feedbacks...');
    _initialized = false;
    _organisms.clear();
    await initialize();
  }

  /// Obtém estatísticas do repositório
  Future<Map<String, dynamic>> getStats() async {
    await initialize();
    
    final pestCount = _organisms.where((o) => o.type == 'pest').length;
    final diseaseCount = _organisms.where((o) => o.type == 'disease').length;
    final crops = _organisms.expand((o) => o.crops).toSet();
    
    // Contar quantos foram enriquecidos com feedback
    final enrichedCount = _organisms.where((o) => 
      o.characteristics.containsKey('feedbackCount')
    ).length;
    
    return {
      'totalOrganisms': _organisms.length,
      'pests': pestCount,
      'diseases': diseaseCount,
      'crops': crops.length,
      'cropList': crops.toList(),
      'averageSeverity': _organisms.map((o) => o.severity).reduce((a, b) => a + b) / _organisms.length,
      'enrichedWithFeedback': enrichedCount,
      'enrichmentRate': (enrichedCount / _organisms.length * 100).toStringAsFixed(1),
    };
  }
}

