import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Serviço para carregar organismos dos arquivos organismos_*.json
/// e adicionar thresholds fenológicos automaticamente
/// ✅ PRIORIZA arquivo customizado da fazenda
class OrganismLoaderService {
  /// Carrega todos os organismos de uma cultura
  /// ✅ PRIORIDADE: organism_catalog_custom.json → organismos_*.json
  Future<Map<String, dynamic>> loadCultureOrganisms(String cultureId) async {
    try {
      final cultureMap = {
        'custom_soja': 'soja',
        'custom_milho': 'milho',
        'custom_algodao': 'algodao',
        'custom_sorgo': 'sorgo',
        'custom_girassol': 'girassol',
        'custom_aveia': 'aveia',
        'custom_trigo': 'trigo',
        'custom_feijao': 'feijao',
        'custom_arroz': 'arroz',
        'soja': 'soja',
        'milho': 'milho',
        'algodao': 'algodao',
      };

      final cultureName = cultureMap[cultureId] ?? cultureId;
      
      // 1️⃣ VERIFICAR ARQUIVO CUSTOMIZADO PRIMEIRO
      final customData = await _loadFromCustomFile(cultureName);
      if (customData != null) {
        Logger.info('✅ Usando dados CUSTOMIZADOS para: $cultureName');
        return customData;
      }
      
      // 2️⃣ CARREGAR JSONs PADRÃO
      final filePath = 'assets/data/organismos_$cultureName.json';
      Logger.info('📂 Carregando organismos padrão de: $filePath');
      final jsonString = await rootBundle.loadString(filePath);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final organisms = data['organismos'] as List<dynamic>? ?? [];
      Logger.info('✅ ${organisms.length} organismos carregados para $cultureName');

      return {
        'culture': cultureName,
        'culture_id': cultureId,
        'total_organisms': organisms.length,
        'organisms': _processOrganisms(organisms),
      };
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos: $e');
      return {'organisms': {'pests': [], 'diseases': [], 'weeds': []}};
    }
  }

  /// Processa organismos e adiciona thresholds fenológicos
  Map<String, List<Map<String, dynamic>>> _processOrganisms(List<dynamic> organisms) {
    final processed = {
      'pests': <Map<String, dynamic>>[],
      'diseases': <Map<String, dynamic>>[],
      'weeds': <Map<String, dynamic>>[],
    };

    for (final org in organisms) {
      final orgMap = org as Map<String, dynamic>;
      final category = (orgMap['categoria'] as String? ?? '').toLowerCase();

      // Adicionar thresholds fenológicos automaticamente
      orgMap['phenological_thresholds'] = _generateThresholds(orgMap);

      if (category.contains('praga') || category == 'pest') {
        processed['pests']!.add(orgMap);
      } else if (category.contains('doen') || category.contains('disease')) {
        processed['diseases']!.add(orgMap);
      } else if (category.contains('daninha') || category.contains('weed')) {
        processed['weeds']!.add(orgMap);
      }
    }

    return processed;
  }

  /// Gera thresholds fenológicos baseado nos níveis existentes
  Map<String, dynamic> _generateThresholds(Map<String, dynamic> organism) {
    final niveis = organism['niveis_infestacao'] as Map<String, dynamic>?;
    final limiares = organism['limiares_especificos'] as Map<String, dynamic>?;
    final name = organism['nome'] as String? ?? '';

    // Se já tem thresholds fenológicos, retorna
    if (organism['phenological_thresholds'] != null) {
      return organism['phenological_thresholds'] as Map<String, dynamic>;
    }

    // Extrair valores base dos níveis de infestação
    final baseLow = _extractNumber(niveis?['baixo']) ?? 2;
    final baseMedium = _extractNumber(niveis?['medio']) ?? 5;
    final baseHigh = _extractNumber(niveis?['alto']) ?? 8;
    final baseCritical = _extractNumber(niveis?['critico']) ?? 12;

    // Gerar thresholds por tipo de organismo
    if (name.contains('percevejo') || name.contains('Percevejo')) {
      return _generatePestThresholds(baseLow, baseMedium, baseHigh, baseCritical, isPestOnGrain: true);
    } else if (name.contains('lagarta') || name.contains('Lagarta')) {
      return _generatePestThresholds(baseLow, baseMedium, baseHigh, baseCritical, isDefoliator: true);
    } else if (name.contains('bicudo') || name.contains('Bicudo')) {
      return _generateCriticalPestThresholds(baseLow, baseMedium, baseHigh, baseCritical);
    } else {
      return _generateGenericThresholds(baseLow, baseMedium, baseHigh, baseCritical);
    }
  }

  /// Thresholds para pragas de grão (percevejos, torrãozinho)
  Map<String, dynamic> _generatePestThresholds(int low, int medium, int high, int critical, {bool isPestOnGrain = false, bool isDefoliator = false}) {
    if (isPestOnGrain) {
      return {
        'V1-V3': {'low': low * 2, 'medium': medium * 2, 'high': high * 2, 'critical': critical * 2, 'damage_potential': 30},
        'V4-V6': {'low': (low * 1.5).round(), 'medium': (medium * 1.5).round(), 'high': (high * 1.5).round(), 'critical': (critical * 1.5).round(), 'damage_potential': 50},
        'R1-R2': {'low': low, 'medium': medium, 'high': high, 'critical': critical, 'damage_potential': 70},
        'R3-R4': {'low': (low * 0.7).round(), 'medium': (medium * 0.7).round(), 'high': (high * 0.7).round(), 'critical': (critical * 0.7).round(), 'damage_potential': 85},
        'R5-R6': {'low': 0, 'medium': low, 'high': medium, 'critical': high, 'damage_potential': 95},
        'R7-R8': {'low': low, 'medium': medium, 'high': high, 'critical': critical, 'damage_potential': 40},
      };
    } else if (isDefoliator) {
      return {
        'V1-V3': {'low': (low * 0.5).round(), 'medium': (medium * 0.5).round(), 'high': (high * 0.5).round(), 'critical': high, 'damage_potential': 90},
        'V4-V6': {'low': low, 'medium': medium, 'high': high, 'critical': critical, 'damage_potential': 60},
        'R1-R4': {'low': (low * 1.2).round(), 'medium': (medium * 1.2).round(), 'high': (high * 1.2).round(), 'critical': (critical * 1.2).round(), 'damage_potential': 50},
        'R5-R8': {'low': low * 2, 'medium': medium * 2, 'high': high * 2, 'critical': critical * 2, 'damage_potential': 30},
      };
    }
    return {};
  }

  /// Thresholds para pragas críticas (bicudo, lagarta-rosada)
  Map<String, dynamic> _generateCriticalPestThresholds(int low, int medium, int high, int critical) {
    return {
      'V1-V3': {'low': low, 'medium': medium, 'high': high, 'critical': critical, 'damage_potential': 50},
      'B1-B2': {'low': (low * 0.5).round(), 'medium': low, 'high': medium, 'critical': high, 'damage_potential': 90},
      'B3-B4': {'low': 0, 'medium': (low * 0.5).round(), 'high': low, 'critical': medium, 'damage_potential': 95},
      'F1-F3': {'low': 0, 'medium': (low * 0.5).round(), 'high': low, 'critical': (medium * 0.8).round(), 'damage_potential': 95},
      'A1': {'low': low, 'medium': medium, 'high': high, 'critical': critical, 'damage_potential': 30},
    };
  }

  /// Thresholds genéricos
  Map<String, dynamic> _generateGenericThresholds(int low, int medium, int high, int critical) {
    return {
      'early': {'low': low, 'medium': medium, 'high': high, 'critical': critical},
      'mid': {'low': (low * 0.8).round(), 'medium': (medium * 0.8).round(), 'high': (high * 0.8).round(), 'critical': (critical * 0.8).round()},
      'late': {'low': low, 'medium': medium, 'high': high, 'critical': critical},
    };
  }

  /// Extrai número de string (ex: "1-2" -> 2, ">10" -> 10)
  int? _extractNumber(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return match != null ? int.tryParse(match.group(1) ?? '0') : null;
  }
  
  /// 🔧 CARREGA DO ARQUIVO CUSTOMIZADO DA FAZENDA
  Future<Map<String, dynamic>?> _loadFromCustomFile(String cultureName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/organism_catalog_custom.json');
      
      if (!await customFile.exists()) {
        Logger.info('📄 Arquivo customizado não existe, usando padrão');
        return null; // ✅ Retorna null para carregar padrão
      }
      
      final jsonString = await customFile.readAsString();
      final catalogData = json.decode(jsonString) as Map<String, dynamic>;
      
      final cultures = catalogData['cultures'] as Map<String, dynamic>?;
      if (cultures == null) {
        Logger.warning('⚠️ Estrutura inválida no arquivo customizado');
        return null;
      }
      
      final cultureData = cultures[cultureName] as Map<String, dynamic>?;
      if (cultureData == null) {
        Logger.info('📄 Cultura $cultureName não encontrada no customizado, usando padrão');
        return null; // ✅ Retorna null para carregar padrão
      }
      
      Logger.info('✅ Dados customizados encontrados para: $cultureName');
      
      // Retornar no mesmo formato que loadCultureOrganisms espera
      return {
        'culture': cultureName,
        'culture_id': 'custom_$cultureName',
        'total_organisms': (cultureData['total_organisms'] as int?) ?? 0,
        'organisms': cultureData['organisms'] ?? {'pests': [], 'diseases': [], 'weeds': []},
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar customizado: $e');
      return null; // ✅ Em caso de erro, retorna null para carregar padrão
    }
  }
}

