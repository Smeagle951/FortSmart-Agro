import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Serviço para carregar e gerenciar padrões de CV% por cultura
class PlantingCVStandardsService {
  static const String _tag = 'PlantingCVStandardsService';
  static const String _assetPath = 'assets/data/planting_cv_standards.json';
  
  static Map<String, dynamic>? _standardsData;
  static List<Map<String, dynamic>>? _culturas;

  /// Carrega os padrões de CV% do arquivo JSON
  static Future<void> loadStandards() async {
    try {
      Logger.info('$_tag: Carregando padrões de CV%...');
      
      final String jsonString = await rootBundle.loadString(_assetPath);
      _standardsData = json.decode(jsonString);
      _culturas = List<Map<String, dynamic>>.from(_standardsData!['cv_standards']['culturas']);
      
      Logger.info('$_tag: ✅ Padrões de CV% carregados: ${_culturas!.length} culturas');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao carregar padrões de CV%: $e');
      rethrow;
    }
  }

  /// Obtém os padrões de CV% para uma cultura específica
  static Map<String, dynamic>? getStandardsForCrop(String culturaNome) {
    if (_culturas == null) {
      Logger.warning('$_tag: Padrões não carregados. Execute loadStandards() primeiro.');
      return null;
    }

    try {
      final cultura = _culturas!.firstWhere(
        (c) => c['nome'].toString().toLowerCase() == culturaNome.toLowerCase(),
        orElse: () => {},
      );

      if (cultura.isEmpty) {
        Logger.warning('$_tag: Cultura não encontrada: $culturaNome');
        return null;
      }

      return cultura;
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar padrões para $culturaNome: $e');
      return null;
    }
  }

  /// Obtém o CV% ideal para uma cultura
  static double? getIdealCV(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['cv_ideal']?.toDouble();
  }

  /// Obtém o CV% aceitável para uma cultura
  static double? getAcceptableCV(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['cv_aceitavel']?.toDouble();
  }

  /// Obtém o CV% ruim para uma cultura
  static double? getBadCV(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['cv_ruim']?.toDouble();
  }

  /// Obtém a população ideal para uma cultura
  static double? getIdealPopulation(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['populacao_ideal']?.toDouble();
  }

  /// Obtém o espaçamento padrão entre linhas para uma cultura
  static double? getStandardRowSpacing(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['espacamento_linhas_padrao']?.toDouble();
  }

  /// Obtém as observações para uma cultura
  static String? getObservations(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['observacoes']?.toString();
  }

  /// Obtém os fatores de influência para uma cultura
  static List<String>? getInfluenceFactors(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    if (standards?['fatores_influencia'] != null) {
      return List<String>.from(standards!['fatores_influencia']);
    }
    return null;
  }

  /// Obtém o impacto de CV% alto para uma cultura
  static Map<String, dynamic>? getHighCVImpact(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    return standards?['impacto_cv_alto'];
  }

  /// Classifica um CV% baseado nos padrões da cultura
  static String classifyCV(double cvPercentual, String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    if (standards == null) {
      return 'desconhecido';
    }

    final cvIdeal = standards['cv_ideal']?.toDouble() ?? 15.0;
    final cvAceitavel = standards['cv_aceitavel']?.toDouble() ?? 25.0;

    if (cvPercentual < cvIdeal) {
      return 'excelente';
    } else if (cvPercentual <= cvAceitavel) {
      return 'bom';
    } else {
      return 'ruim';
    }
  }

  /// Obtém informações de classificação
  static Map<String, dynamic>? getClassificationInfo(String classificacao) {
    if (_standardsData == null) return null;
    
    final classificacoes = _standardsData!['cv_standards']['classificacoes'];
    return classificacoes[classificacao];
  }

  /// Obtém a cor da classificação
  static String? getClassificationColor(String classificacao) {
    final info = getClassificationInfo(classificacao);
    return info?['cor']?.toString();
  }

  /// Obtém o ícone da classificação
  static String? getClassificationIcon(String classificacao) {
    final info = getClassificationInfo(classificacao);
    return info?['icone']?.toString();
  }

  /// Obtém a descrição da classificação
  static String? getClassificationDescription(String classificacao) {
    final info = getClassificationInfo(classificacao);
    return info?['descricao']?.toString();
  }

  /// Obtém recomendações para uma classificação
  static List<String>? getClassificationRecommendations(String classificacao) {
    final info = getClassificationInfo(classificacao);
    if (info?['recomendacoes'] != null) {
      return List<String>.from(info!['recomendacoes']);
    }
    return null;
  }

  /// Obtém informações sobre fatores de impacto
  static Map<String, dynamic>? getImpactFactors() {
    if (_standardsData == null) return null;
    return _standardsData!['cv_standards']['fatores_impacto'];
  }

  /// Obtém informações sobre equipamentos
  static Map<String, dynamic>? getEquipmentInfo() {
    if (_standardsData == null) return null;
    return _standardsData!['cv_standards']['equipamentos'];
  }

  /// Obtém informações sobre monitoramento
  static Map<String, dynamic>? getMonitoringInfo() {
    if (_standardsData == null) return null;
    return _standardsData!['cv_standards']['monitoramento'];
  }

  /// Obtém todas as culturas disponíveis
  static List<String> getAllCrops() {
    if (_culturas == null) return [];
    return _culturas!.map((c) => c['nome'].toString()).toList();
  }

  /// Verifica se uma cultura tem padrões definidos
  static bool hasStandards(String culturaNome) {
    return getStandardsForCrop(culturaNome) != null;
  }

  /// Obtém resumo completo dos padrões para uma cultura
  static Map<String, dynamic>? getCompleteStandards(String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    if (standards == null) return null;

    return {
      'cultura': culturaNome,
      'cv_ideal': standards['cv_ideal'],
      'cv_aceitavel': standards['cv_aceitavel'],
      'cv_ruim': standards['cv_ruim'],
      'populacao_ideal': standards['populacao_ideal'],
      'populacao_minima': standards['populacao_minima'],
      'populacao_maxima': standards['populacao_maxima'],
      'espacamento_linhas_padrao': standards['espacamento_linhas_padrao'],
      'observacoes': standards['observacoes'],
      'fatores_influencia': standards['fatores_influencia'],
      'impacto_cv_alto': standards['impacto_cv_alto'],
    };
  }

  /// Calcula score de qualidade baseado no CV%
  static double calculateQualityScore(double cvPercentual, String culturaNome) {
    final standards = getStandardsForCrop(culturaNome);
    if (standards == null) return 0.0;

    final cvIdeal = standards['cv_ideal']?.toDouble() ?? 15.0;
    final cvAceitavel = standards['cv_aceitavel']?.toDouble() ?? 25.0;

    if (cvPercentual <= cvIdeal) {
      return 100.0; // Excelente
    } else if (cvPercentual <= cvAceitavel) {
      // Interpolação linear entre 100 e 70
      final ratio = (cvAceitavel - cvPercentual) / (cvAceitavel - cvIdeal);
      return 70.0 + (30.0 * ratio);
    } else {
      // Interpolação linear entre 70 e 0
      final ratio = (cvPercentual - cvAceitavel) / (cvAceitavel);
      return 70.0 - (70.0 * ratio).clamp(0.0, 70.0);
    }
  }
}
