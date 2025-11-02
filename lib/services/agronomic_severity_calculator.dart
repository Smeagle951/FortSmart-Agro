import '../models/organism_catalog.dart';
import '../utils/enums.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Serviço especializado para cálculo de severidade baseado em critérios agronômicos
/// Implementa interpretação inteligente de níveis de infestação
class AgronomicSeverityCalculator {
  
  /// Calcula severidade baseada em critérios agronômicos reais
  /// Retorna valores numéricos (0-100) para o mapa de infestação
  /// ✅ PRIORIZA dados customizados da fazenda
  static Future<double> calculateSeverity({
    required int pointCount,
    required String organismName,
    required String cropName,
    required String cropStage,
    required String organismType,
    double? temperature,
    double? humidity,
    int? totalPlantsEvaluated,
  }) async {
    
    // 1. Obter limiares agronômicos específicos dos organismos (✅ prioriza customizado)
    final thresholds = await _getAgronomicThresholds(organismName, cropName, cropStage);
    
    // 2. Calcular densidade de infestação
    final infestationDensity = _calculateInfestationDensity(
      pointCount, 
      totalPlantsEvaluated ?? 10, // Padrão: 10 plantas por ponto
    );
    
    // 3. Aplicar fatores ambientais
    final environmentalFactor = _calculateEnvironmentalFactor(
      organismType, 
      temperature, 
      humidity,
    );
    
    // 4. Calcular severidade baseada em limiares agronômicos
    // Retorna valores numéricos (0-100) para o mapa de infestação
    final severity = _calculateAgronomicSeverity(
      infestationDensity,
      thresholds,
      environmentalFactor,
    );
    
    return severity.clamp(0.0, 100.0);
  }
  
  /// Calcula densidade de infestação (organismos por metro quadrado)
  static double _calculateInfestationDensity(int pointCount, int totalPlants) {
    // Densidade = (pontos encontrados / plantas avaliadas) * 100
    if (totalPlants == 0) return 0.0;
    return (pointCount / totalPlants) * 100;
  }
  
  /// Obtém limiares agronômicos específicos por organismo e cultura
  static Future<Map<String, dynamic>> _getAgronomicThresholds(
    String organismName, 
    String cropName, 
    String cropStage
  ) async {
    try {
      // ✅ Carregar dados (prioriza customizado)
      final organismData = await _loadOrganismData(cropName, organismName);
      if (organismData != null) {
        return _parseInfestationLevels(organismData);
      }
    } catch (e) {
      print('Erro ao carregar dados do organismo: $e');
    }
    
    // Fallback para limiares padrão
    return {
      'baixo': 2.0,
      'medio': 5.0,
      'alto': 10.0,
      'critico': 15.0,
      'fator_critico': 1.5,
    };
  }
  
  /// Carrega dados reais do organismo
  /// ✅ PRIORIZA arquivo customizado da fazenda
  static Future<Map<String, dynamic>?> _loadOrganismData(String cropName, String organismName) async {
    try {
      // 1️⃣ PRIMEIRA PRIORIDADE: Arquivo customizado
      final customData = await _loadFromCustomFile(cropName, organismName);
      if (customData != null) {
        print('✅ Usando dados CUSTOMIZADOS: $organismName');
        return customData;
      }
      
      // 2️⃣ SEGUNDA PRIORIDADE: JSONs padrão do assets
      final filePath = 'assets/data/organismos_${cropName.toLowerCase()}.json';
      final jsonString = await rootBundle.loadString(filePath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final organisms = data['organismos'] as List<dynamic>;
      
      // Buscar organismo específico
      for (final organism in organisms) {
        final org = organism as Map<String, dynamic>;
        final name = org['nome'] as String? ?? '';
        
        if (_normalizeOrganismName(name) == _normalizeOrganismName(organismName)) {
          print('✅ Usando dados PADRÃO: $organismName');
          return org;
        }
      }
      
      return null;
    } catch (e) {
      print('Erro ao carregar dados do organismo: $e');
      return null;
    }
  }
  
  /// Carrega do arquivo customizado da fazenda
  static Future<Map<String, dynamic>?> _loadFromCustomFile(String cropName, String organismName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/organism_catalog_custom.json');
      
      if (!await customFile.exists()) {
        return null;
      }
      
      final jsonString = await customFile.readAsString();
      final catalogData = json.decode(jsonString) as Map<String, dynamic>;
      
      final cultures = catalogData['cultures'] as Map<String, dynamic>?;
      if (cultures == null) return null;
      
      final cultureKey = cropName.toLowerCase();
      final cultureData = cultures[cultureKey] as Map<String, dynamic>?;
      if (cultureData == null) return null;
      
      final organisms = cultureData['organisms'] as Map<String, dynamic>?;
      if (organisms == null) return null;
      
      // Buscar em todas as categorias
      final allOrganisms = [
        ...(organisms['pests'] as List<dynamic>? ?? []),
        ...(organisms['diseases'] as List<dynamic>? ?? []),
        ...(organisms['weeds'] as List<dynamic>? ?? []),
      ];
      
      for (final org in allOrganisms) {
        final orgMap = org as Map<String, dynamic>;
        final nome = (orgMap['nome'] ?? orgMap['name'] ?? '').toString();
        
        if (_normalizeOrganismName(nome) == _normalizeOrganismName(organismName)) {
          return orgMap;
        }
      }
      
      return null;
      
    } catch (e) {
      print('Erro ao carregar do arquivo customizado: $e');
      return null;
    }
  }
  
  /// Converte apenas os níveis de infestação do organismo
  static Map<String, dynamic> _parseInfestationLevels(
    Map<String, dynamic> organismData
  ) {
    final thresholds = <String, dynamic>{};
    
    // Extrair apenas níveis de infestação
    final niveisInfestacao = organismData['niveis_infestacao'] as Map<String, dynamic>?;
    if (niveisInfestacao != null) {
      // Converter níveis de infestação em valores numéricos
      thresholds['baixo'] = _parseInfestationValue(niveisInfestacao['baixo'] as String?);
      thresholds['medio'] = _parseInfestationValue(niveisInfestacao['medio'] as String?);
      thresholds['alto'] = _parseInfestationValue(niveisInfestacao['alto'] as String?);
      thresholds['critico'] = _parseInfestationValue(niveisInfestacao['critico'] as String?);
      thresholds['fator_critico'] = 1.5;
    }
    
    // Se não encontrou níveis de infestação, usar padrão
    if (thresholds.isEmpty) {
      thresholds.addAll({
        'baixo': 2.0,
        'medio': 5.0,
        'alto': 10.0,
        'critico': 15.0,
        'fator_critico': 1.5,
      });
    }
    
    return thresholds;
  }
  
  /// Converte texto de infestação em valor numérico
  static double _parseInfestationValue(String? infestationText) {
    if (infestationText == null || infestationText.isEmpty) {
      return 0.0;
    }
    
    // Extrair números do texto (ex: "1-2 lagartas/metro" -> 1.5)
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final matches = regex.allMatches(infestationText);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => double.parse(m.group(1)!)).toList();
      
      if (values.length == 1) {
        return values.first;
      } else if (values.length == 2) {
        // Média entre dois valores (ex: "1-2" -> 1.5)
        return (values[0] + values[1]) / 2;
      } else {
        // Média de todos os valores
        return values.reduce((a, b) => a + b) / values.length;
      }
    }
    
    return 0.0;
  }
  
  /// Normaliza nome do organismo para busca
  static String _normalizeOrganismName(String name) {
    final normalized = name.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
    
    // Mapeamentos específicos
    if (normalized.contains('lagarta') && normalized.contains('spodoptera')) {
      return 'lagarta_soja';
    }
    if (normalized.contains('percevejo') && normalized.contains('marrom')) {
      return 'percevejo_marrom';
    }
    if (normalized.contains('mancha') && normalized.contains('alvo')) {
      return 'mancha_alvo';
    }
    if (normalized.contains('ferrugem')) {
      return 'ferrugem_asiatica';
    }
    if (normalized.contains('antracnose')) {
      return 'antracnose';
    }
    if (normalized.contains('buva')) {
      return 'buva';
    }
    if (normalized.contains('capim') && normalized.contains('amargoso')) {
      return 'capim_amargoso';
    }
    
    return normalized;
  }
  
  /// Calcula fator ambiental
  static double _calculateEnvironmentalFactor(
    String organismType,
    double? temperature,
    double? humidity,
  ) {
    if (temperature == null || humidity == null) return 1.0;
    
    double factor = 1.0;
    
    switch (organismType.toLowerCase()) {
      case 'praga':
        // Pragas preferem temperaturas moderadas e alta umidade
        if (temperature >= 20 && temperature <= 30 && humidity >= 60) {
          factor = 1.3; // Condições favoráveis
        } else if (temperature > 35 || humidity < 40) {
          factor = 0.7; // Condições desfavoráveis
        }
        break;
        
      case 'doença':
        // Doenças preferem alta umidade e temperaturas moderadas
        if (humidity >= 80 && temperature >= 18 && temperature <= 28) {
          factor = 1.5; // Condições muito favoráveis
        } else if (humidity < 50 || temperature > 35) {
          factor = 0.6; // Condições desfavoráveis
        }
        break;
        
      case 'daninha':
        // Plantas daninhas são mais tolerantes
        if (temperature >= 15 && temperature <= 35) {
          factor = 1.1; // Condições favoráveis
        }
        break;
    }
    
    return factor;
  }
  
  /// Calcula severidade agronômica baseada em limiares
  /// Retorna valores numéricos (0-100) para o mapa de infestação
  static double _calculateAgronomicSeverity(
    double infestationDensity,
    Map<String, dynamic> thresholds,
    double environmentalFactor,
  ) {
    final baixo = thresholds['baixo'] as double;
    final medio = thresholds['medio'] as double;
    final alto = thresholds['alto'] as double;
    final critico = thresholds['critico'] as double;
    final fatorCritico = thresholds['fator_critico'] as double;
    
    // Aplicar fator ambiental
    final adjustedDensity = infestationDensity * environmentalFactor;
    
    // Calcular severidade baseada em limiares
    // Valores numéricos para o mapa de infestação (0-100%)
    if (adjustedDensity <= baixo) {
      return (adjustedDensity / baixo) * 25; // 0-25% (Verde no mapa)
    } else if (adjustedDensity <= medio) {
      return 25 + ((adjustedDensity - baixo) / (medio - baixo)) * 25; // 25-50% (Amarelo no mapa)
    } else if (adjustedDensity <= alto) {
      return 50 + ((adjustedDensity - medio) / (alto - medio)) * 25; // 50-75% (Laranja no mapa)
    } else if (adjustedDensity <= critico) {
      return 75 + ((adjustedDensity - alto) / (critico - alto)) * 20; // 75-95% (Vermelho no mapa)
    } else {
      // Acima do limiar crítico
      return 95 + ((adjustedDensity - critico) / critico) * 5; // 95-100% (Vermelho intenso no mapa)
    }
  }
  
  /// Obtém nível de alerta baseado na severidade
  static String getAlertLevel(double severity) {
    if (severity < 25) return 'baixo';
    if (severity < 50) return 'medio';
    if (severity < 75) return 'alto';
    return 'critico';
  }
  
  /// Obtém cor do alerta
  static String getAlertColor(String alertLevel) {
    switch (alertLevel) {
      case 'baixo': return '#4CAF50'; // Verde
      case 'medio': return '#FF9800'; // Laranja
      case 'alto': return '#F44336'; // Vermelho
      case 'critico': return '#9C27B0'; // Roxo
      default: return '#757575'; // Cinza
    }
  }
  
  /// Obtém recomendação agronômica baseada na severidade
  static String getAgronomicRecommendation(double severity, String organismName) {
    if (severity < 25) {
      return 'Monitoramento contínuo recomendado. Nível baixo de infestação.';
    } else if (severity < 50) {
      return 'Atenção! Aumentar frequência de monitoramento. Considerar medidas preventivas.';
    } else if (severity < 75) {
      return 'ALERTA! Ação imediata necessária. Aplicar medidas de controle.';
    } else {
      return 'EMERGÊNCIA! Controle urgente necessário. Perdas econômicas iminentes.';
    }
  }
}
