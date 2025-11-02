import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Serviço para carregar dados detalhados de organismos dos arquivos JSON
class OrganismDetailedDataService {
  static const String _basePath = 'lib/data';
  
  /// Carrega dados detalhados de um organismo específico
  Future<Map<String, dynamic>?> getDetailedData(OrganismCatalog organism) async {
    try {
      // Determinar o arquivo baseado na cultura
      final cultureFile = _getCultureFileName(organism.cropId);
      
      // Carregar arquivo JSON da cultura
      final jsonString = await _loadCultureFile(cultureFile);
      if (jsonString == null) return null;
      
      final cultureData = json.decode(jsonString);
      final organisms = cultureData['organismos'] as List?;
      
      if (organisms == null) return null;
      
      // Encontrar o organismo específico
      final organismData = organisms.firstWhere(
        (org) => _matchesOrganism(org, organism),
        orElse: () => null,
      );
      
      if (organismData == null) return null;
      
      // Extrair dados detalhados
      return _extractDetailedData(organismData);
      
    } catch (e) {
      Logger.error('Erro ao carregar dados detalhados: $e');
      return null;
    }
  }
  
  /// Carrega dados detalhados de todos os organismos de uma cultura
  Future<List<Map<String, dynamic>>> getAllOrganismsDetailed(String cropId) async {
    try {
      final cultureFile = _getCultureFileName(cropId);
      final jsonString = await _loadCultureFile(cultureFile);
      
      if (jsonString == null) return [];
      
      final cultureData = json.decode(jsonString);
      final organisms = cultureData['organismos'] as List? ?? [];
      
      return organisms.map((org) => _extractDetailedData(org)).toList();
      
    } catch (e) {
      Logger.error('Erro ao carregar organismos detalhados: $e');
      return [];
    }
  }
  
  /// Obtém o nome do arquivo baseado na cultura
  String _getCultureFileName(String cropId) {
    final cropMap = {
      'soja': 'organismos_soja',
      'milho': 'organismos_milho',
      'trigo': 'organismos_trigo',
      'feijao': 'organismos_feijao',
      'algodao': 'organismos_algodao',
      'sorgo': 'organismos_sorgo',
      'girassol': 'organismos_girassol',
      'aveia': 'organismos_aveia',
      'gergelim': 'organismos_gergelim',
      'arroz': 'organismos_arroz',
      'tomate': 'organismos_tomate',
      'cana_acucar': 'organismos_cana_acucar',
    };
    
    return '${cropMap[cropId.toLowerCase()] ?? 'organismos_soja'}.json';
  }
  
  /// Carrega arquivo da cultura
  Future<String?> _loadCultureFile(String fileName) async {
    try {
      // Tentar carregar do sistema de arquivos primeiro
      final file = File('$_basePath/$fileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      Logger.warning('Erro ao carregar arquivo do sistema: $e');
    }
    
    try {
      // Fallback para assets
      return await rootBundle.loadString('assets/data/$fileName');
    } catch (e) {
      Logger.warning('Erro ao carregar arquivo de assets: $e');
      return null;
    }
  }
  
  /// Verifica se o organismo do JSON corresponde ao organismo do catálogo
  bool _matchesOrganism(Map<String, dynamic> jsonOrg, OrganismCatalog catalogOrg) {
    final jsonName = (jsonOrg['nome'] as String? ?? '').toLowerCase();
    final catalogName = catalogOrg.name.toLowerCase();
    
    // Verificação por nome (exato ou similar)
    if (jsonName == catalogName) return true;
    
    // Verificação por nome científico
    final jsonScientific = (jsonOrg['nome_cientifico'] as String? ?? '').toLowerCase();
    final catalogScientific = catalogOrg.scientificName.toLowerCase();
    
    if (jsonScientific.isNotEmpty && catalogScientific.isNotEmpty) {
      if (jsonScientific == catalogScientific) return true;
    }
    
    // Verificação por tipo
    final jsonType = _mapJsonTypeToEnum(jsonOrg['tipo'] as String?);
    if (jsonType == catalogOrg.type) {
      // Se o tipo é igual, considerar como match se o nome é similar
      return _isNameSimilar(jsonName, catalogName);
    }
    
    return false;
  }
  
  /// Mapeia tipo do JSON para enum
  OccurrenceType _mapJsonTypeToEnum(String? jsonType) {
    switch (jsonType?.toLowerCase()) {
      case 'praga':
      case 'pest':
        return OccurrenceType.pest;
      case 'doença':
      case 'disease':
        return OccurrenceType.disease;
      case 'planta daninha':
      case 'weed':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.pest;
    }
  }
  
  /// Verifica se os nomes são similares
  bool _isNameSimilar(String name1, String name2) {
    // Implementação simples de similaridade
    final words1 = name1.split(' ');
    final words2 = name2.split(' ');
    
    // Se alguma palavra é igual, considerar similar
    for (final word1 in words1) {
      for (final word2 in words2) {
        if (word1.length > 3 && word2.length > 3 && word1 == word2) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Extrai dados detalhados do organismo do JSON
  Map<String, dynamic> _extractDetailedData(Map<String, dynamic> organismData) {
    return {
      'id': organismData['id'],
      'nome': organismData['nome'],
      'nome_cientifico': organismData['nome_cientifico'],
      'categoria': organismData['categoria'],
      'tipo': organismData['tipo'],
      'cultura_id': organismData['cultura_id'],
      'sintomas': _extractList(organismData['sintomas']),
      'dano_economico': organismData['dano_economico'],
      'partes_afetadas': _extractList(organismData['partes_afetadas']),
      'fenologia': _extractList(organismData['fenologia']),
      'nivel_acao': organismData['nivel_acao'],
      'niveis_infestacao': organismData['niveis_infestacao'] as Map<String, dynamic>? ?? {},
      'manejo_quimico': _extractList(organismData['manejo_quimico']),
      'manejo_biologico': _extractList(organismData['manejo_biologico']),
      'manejo_cultural': _extractList(organismData['manejo_cultural']),
      'condicoes_favoraveis': _extractList(organismData['condicoes_favoraveis']),
      'fotos': _extractList(organismData['fotos']),
      'imagens': _extractList(organismData['imagens']),
      'prevencao': _extractList(organismData['prevencao']),
      'monitoramento': organismData['monitoramento'],
      'tratamento': organismData['tratamento'],
      'observacoes': organismData['observacoes'],
    };
  }
  
  /// Extrai lista de dados
  List<String> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [data.toString()];
  }
  
  /// Obtém estatísticas de uma cultura
  Future<Map<String, int>> getCultureStatistics(String cropId) async {
    try {
      final organisms = await getAllOrganismsDetailed(cropId);
      
      int pests = 0;
      int diseases = 0;
      int weeds = 0;
      
      for (final organism in organisms) {
        final type = organism['tipo'] as String? ?? '';
        switch (type.toLowerCase()) {
          case 'praga':
          case 'pest':
            pests++;
            break;
          case 'doença':
          case 'disease':
            diseases++;
            break;
          case 'planta daninha':
          case 'weed':
            weeds++;
            break;
        }
      }
      
      return {
        'total': organisms.length,
        'pests': pests,
        'diseases': diseases,
        'weeds': weeds,
      };
      
    } catch (e) {
      Logger.error('Erro ao obter estatísticas da cultura: $e');
      return {'total': 0, 'pests': 0, 'diseases': 0, 'weeds': 0};
    }
  }
  
  /// Busca organismos por sintoma
  Future<List<Map<String, dynamic>>> searchBySymptom(String symptom) async {
    try {
      final results = <Map<String, dynamic>>[];
      
      // Lista de culturas para buscar
      final cultures = ['soja', 'milho', 'trigo', 'feijao', 'algodao'];
      
      for (final culture in cultures) {
        final organisms = await getAllOrganismsDetailed(culture);
        
        for (final organism in organisms) {
          final symptoms = _extractList(organism['sintomas']);
          final symptomLower = symptom.toLowerCase();
          
          for (final orgSymptom in symptoms) {
            if (orgSymptom.toLowerCase().contains(symptomLower)) {
              results.add(organism);
              break;
            }
          }
        }
      }
      
      return results;
      
    } catch (e) {
      Logger.error('Erro na busca por sintoma: $e');
      return [];
    }
  }
}

