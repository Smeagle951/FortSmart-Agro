import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import 'organism_loader_service.dart';
import '../repositories/infestation_rules_repository.dart'; // ✅ NOVO

/// Serviço para calcular níveis de infestação considerando fenologia
/// Integra dados fenológicos com regras de infestação por estágio
/// ✅ PRIORIZA regras customizadas do usuário sobre JSONs padrão
class PhenologicalInfestationService {
  Map<String, dynamic>? _catalogData;
  bool _isInitialized = false;
  final OrganismLoaderService _loaderService = OrganismLoaderService();
  final InfestationRulesRepository _rulesRepository = InfestationRulesRepository(); // ✅ NOVO

  /// Inicializa o serviço carregando o catálogo
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Logger.info('🔄 Inicializando PhenologicalInfestationService...');
      
      // Tentar carregar versão customizada primeiro
      final customFile = await _getCustomCatalogFile();
      String jsonString;
      
      if (await customFile.exists()) {
        Logger.info('📄 Carregando catálogo customizado');
        jsonString = await customFile.readAsString();
      } else {
        Logger.info('📄 Carregando catálogo padrão (multi-cultura)');
        // Carregar todos os JSONs de cultura e mesclar
        jsonString = await _loadMultiCultureCatalog();
      }

      _catalogData = json.decode(jsonString) as Map<String, dynamic>;
      _isInitialized = true;
      
      Logger.info('✅ PhenologicalInfestationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar PhenologicalInfestationService: $e');
      rethrow;
    }
  }

  /// Obtém o arquivo customizado do catálogo
  Future<File> _getCustomCatalogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/organism_catalog_custom.json');
  }

  /// Carrega e mescla catálogos de todas as culturas usando organismos_*.json
  Future<String> _loadMultiCultureCatalog() async {
    try {
      final cultureIds = ['soja', 'milho', 'algodao', 'sorgo', 'girassol', 'aveia', 'trigo', 'feijao', 'arroz'];

      final Map<String, dynamic> mergedCatalog = {
        'version': '2.0',
        'last_updated': DateTime.now().toIso8601String(),
        'cultures': <String, dynamic>{},
      };

      final culturesMap = mergedCatalog['cultures'] as Map<String, dynamic>;

      for (final cultureId in cultureIds) {
        try {
          // Carregar organismos do arquivo organismos_*.json
          final cultureData = await _loaderService.loadCultureOrganisms('custom_$cultureId');
          culturesMap[cultureId] = cultureData;
          Logger.info('✅ ${cultureData['total_organisms']} organismos carregados para $cultureId');
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar $cultureId: $e');
        }
      }

      return json.encode(mergedCatalog);
    } catch (e) {
      Logger.error('❌ Erro ao mesclar catálogos: $e');
      // Fallback para Soja completa
      return await rootBundle.loadString('assets/data/organism_catalog_soja_completo_v2.json');
    }
  }

  /// Determina o nível de infestação considerando fenologia
  Future<InfestationLevel> calculateLevel({
    required String organismId,
    required String organismName,
    required double quantity, // ✅ ALTERADO: double para permitir valores decimais
    required String phenologicalStage,
    required String cropId,
  }) async {
    await initialize();
    
    try {
      Logger.info('🧮 Calculando nível: $organismName ($quantity) em $phenologicalStage');
      
      // Buscar dados do organismo
      final organismData = await _getOrganismData(cropId, organismName);
      if (organismData == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismName');
        return InfestationLevel.unknown(organismName, quantity);
      }

      // Obter thresholds para o estágio fenológico
      // ✅ AGORA É ASYNC para buscar regras customizadas do banco
      final thresholds = await _getThresholdsForStage(organismData, phenologicalStage, organismId);
      if (thresholds == null) {
        Logger.warning('⚠️ Thresholds não encontrados para estágio: $phenologicalStage');
        return InfestationLevel.unknown(organismName, quantity);
      }
      
      // ✅ LOG SE ESTÁ USANDO REGRA CUSTOMIZADA
      if (thresholds['custom'] == true) {
        Logger.info('⭐⭐ USANDO REGRA CUSTOMIZADA DO USUÁRIO!');
      }

      // Determinar nível baseado nos thresholds
      final level = _determineLevelFromThresholds(quantity, thresholds);
      
      // Verificar se é estágio crítico
      final criticalStages = (organismData['critical_stages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      final isCriticalStage = criticalStages.any((stage) => phenologicalStage.contains(stage));

      // Obter descrições
      final stageDescription = thresholds['description'] as String? ?? '';
      final damageType = thresholds['damage_type'] as String? ?? '';
      final unit = organismData['unit'] as String? ?? 'unidades';

      Logger.info('📊 Nível calculado: $level (crítico: $isCriticalStage)');

      return InfestationLevel(
        organismId: organismId,
        organismName: organismName,
        quantity: quantity,
        level: level,
        phenologicalStage: phenologicalStage,
        isCriticalStage: isCriticalStage,
        stageDescription: stageDescription,
        damageType: damageType,
        unit: unit,
        thresholds: thresholds,
      );
    } catch (e) {
      Logger.error('❌ Erro ao calcular nível: $e');
      return InfestationLevel.unknown(organismName, quantity);
    }
  }

  /// Busca dados do organismo no catálogo
  Future<Map<String, dynamic>?> _getOrganismData(String cropId, String organismName) async {
    if (_catalogData == null) return null;
    
    try {
      final cultures = _catalogData!['cultures'] as Map<String, dynamic>;
      
      // Buscar cultura (normalizar nome)
      final cultureKey = _normalizeCultureKey(cropId);
      final culture = cultures[cultureKey] as Map<String, dynamic>?;
      if (culture == null) {
        Logger.warning('Cultura não encontrada: $cultureKey');
        return null;
      }

      final organisms = culture['organisms'] as Map<String, dynamic>?;
      if (organisms == null) return null;

      final pests = organisms['pests'] as List<dynamic>? ?? [];
      
      // Buscar organismo por nome (normalizado)
      final normalizedName = organismName.toLowerCase().trim();
      for (final pest in pests) {
        final pestMap = pest as Map<String, dynamic>;
        final pestName = (pestMap['name'] as String? ?? '').toLowerCase().trim();
        if (pestName == normalizedName || pestName.contains(normalizedName)) {
          return pestMap;
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar organismo: $e');
      return null;
    }
  }

  /// Normaliza a chave da cultura
  String _normalizeCultureKey(String cropId) {
    // Mapear IDs de cultura para chaves do JSON
    final Map<String, String> cultureMap = {
      'custom_soja': 'soja',
      'soja': 'soja',
      '1': 'soja',
      'custom_milho': 'milho',
      'milho': 'milho',
      '2': 'milho',
    };
    
    return cultureMap[cropId.toLowerCase()] ?? cropId.toLowerCase();
  }

  /// Obtém thresholds para o estágio fenológico
  /// ✅ PRIORIDADE: Regras customizadas do usuário > JSON customizado > JSON padrão
  Future<Map<String, dynamic>?> _getThresholdsForStage(
    Map<String, dynamic> organismData,
    String phenologicalStage,
    String organismId,
  ) async {
    // 🎯 PRIORIDADE 1: REGRAS CUSTOMIZADAS DO USUÁRIO (banco de dados)
    try {
      final customRule = await _rulesRepository.getRuleForOrganism(organismId, null);
      if (customRule != null) {
        Logger.info('⭐ Usando REGRA CUSTOMIZADA do usuário para ${customRule.organismName}');
        
        // Converter thresholds do modelo para formato esperado
        return {
          'low': customRule.lowThreshold,
          'medium': customRule.mediumThreshold,
          'high': customRule.highThreshold,
          'critical': customRule.criticalThreshold,
          'description': 'REGRA CUSTOMIZADA (${customRule.organismName})',
          'custom': true, // ✅ Marcador para identificar regra customizada
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao buscar regra customizada: $e');
      // Continua para próximas prioridades
    }
    
    // 2️⃣ PRIORIDADE 2: Usar limiares_especificos do JSON (dados REAIS)
    final limiaresEspecificos = organismData['limiares_especificos'] as Map<String, dynamic>?;
    if (limiaresEspecificos != null && limiaresEspecificos.isNotEmpty) {
      Logger.info('✅ Usando limiares_especificos do JSON');
      
      final normalizedStage = phenologicalStage.toUpperCase().trim();
      
      // Buscar por estágio específico ou range
      for (final entry in limiaresEspecificos.entries) {
        final key = entry.key;
        if (key == normalizedStage || 
            key.contains(normalizedStage) ||
            _isStageInRange(normalizedStage, key)) {
          
          final limiarTexto = entry.value.toString();
          Logger.info('📋 Limiar encontrado para $normalizedStage: $limiarTexto');
          
          // Extrair números do texto (ex: "2 lagartas/m²" -> 2)
          return _parseThresholdFromText(limiarTexto);
        }
      }
    }
    
    // 2️⃣ PRIORIDADE 2: USAR niveis_infestacao do JSON (dados REAIS)
    final niveisInfestacao = organismData['niveis_infestacao'] as Map<String, dynamic>?;
    if (niveisInfestacao != null && niveisInfestacao.isNotEmpty) {
      Logger.info('✅ Usando niveis_infestacao do JSON (Prioridade 2)');
      
      // ✅ THRESHOLDS AJUSTADOS PARA MONITORAMENTO DE CAMPO (valores menores)
      // Padrão anterior era muito alto (2, 5, 8, 12)
      // Novo padrão mais sensível para detecção precoce
      final baixoJSON = _extractNumber(niveisInfestacao['baixo']) ?? 2;
      final medioJSON = _extractNumber(niveisInfestacao['medio']) ?? 5;
      final altoJSON = _extractNumber(niveisInfestacao['alto']) ?? 8;
      final criticoJSON = _extractNumber(niveisInfestacao['critico']) ?? 12;
      
      // ✅ AJUSTE: Dividir por 2 para tornar mais sensível
      // Exemplo: se JSON diz "5", usamos 2.5 na prática
      // ⚠️ NOTA: Regras customizadas do usuário (Prioridade 1) não são ajustadas!
      final baixo = (baixoJSON / 2.0).clamp(0.5, double.infinity);
      final medio = (medioJSON / 2.0).clamp(1.0, double.infinity);
      final alto = (altoJSON / 2.0).clamp(2.0, double.infinity);
      final critico = (criticoJSON / 2.0).clamp(3.0, double.infinity);
      
      Logger.info('📊 Thresholds AJUSTADOS do JSON:');
      Logger.info('   Baixo ≤ ${baixo.toStringAsFixed(1)} (JSON: $baixoJSON)');
      Logger.info('   Médio ≤ ${medio.toStringAsFixed(1)} (JSON: $medioJSON)');
      Logger.info('   Alto ≤ ${alto.toStringAsFixed(1)} (JSON: $altoJSON)');
      Logger.info('   Crítico > ${alto.toStringAsFixed(1)} (JSON: $criticoJSON)');
      
      return {
        'low': baixo,
        'medium': medio,
        'high': alto,
        'critical': critico,
        'description': 'Níveis AJUSTADOS do JSON (${organismData['nome']})',
        'custom': false, // Não é regra customizada
      };
    }
    
    // 3️⃣ PRIORIDADE 3: phenological_thresholds gerados automaticamente
    final thresholds = organismData['phenological_thresholds'] as Map<String, dynamic>?;
    if (thresholds == null) {
      Logger.warning('⚠️ Nenhum threshold encontrado no JSON, usando valores padrão AJUSTADOS (Prioridade 3)');
      // ✅ VALORES PADRÃO MAIS SENSÍVEIS (antes: 2, 5, 8, 12)
      return {
        'low': 0.5,
        'medium': 1.5,
        'high': 3.0,
        'critical': 5.0,
        'description': 'Valores padrão AJUSTADOS (JSON incompleto)',
        'custom': false,
      };
    }

    // Normalizar estágio (ex: "R5" → buscar "R5-R6")
    final normalizedStage = phenologicalStage.toUpperCase().trim();
    
    // Busca exata
    if (thresholds.containsKey(normalizedStage)) {
      return thresholds[normalizedStage] as Map<String, dynamic>?;
    }

    // Busca por range (ex: R5 está em R5-R6)
    for (final entry in thresholds.entries) {
      final key = entry.key;
      if (_isStageInRange(normalizedStage, key)) {
        return entry.value as Map<String, dynamic>?;
      }
    }

    // 4️⃣ PRIORIDADE 4 (FALLBACK): Retornar valores base AJUSTADOS dos niveis_infestacao
    final baixoBase = _extractNumber(niveisInfestacao?['baixo']) ?? 2;
    final medioBase = _extractNumber(niveisInfestacao?['medio']) ?? 5;
    final altoBase = _extractNumber(niveisInfestacao?['alto']) ?? 8;
    final criticoBase = _extractNumber(niveisInfestacao?['critico']) ?? 12;
    
    Logger.info('📊 Usando thresholds base AJUSTADOS (Prioridade 4 - Fallback)');
    
    return {
      'low': (baixoBase / 2.0).clamp(0.5, double.infinity),
      'medium': (medioBase / 2.0).clamp(1.0, double.infinity),
      'high': (altoBase / 2.0).clamp(2.0, double.infinity),
      'critical': (criticoBase / 2.0).clamp(3.0, double.infinity),
      'description': 'Thresholds base AJUSTADOS do JSON (Fallback)',
      'custom': false,
    };
  }
  
  /// Verifica se um estágio está dentro de um range (ex: V3 está em V1-V6)
  bool _isStageInRange(String stage, String range) {
    if (!range.contains('-')) return false;
    
    final parts = range.split('-');
    if (parts.length != 2) return false;
    
    final start = parts[0].trim();
    final end = parts[1].trim();
    
    return stage == start || stage == end || range.contains(stage);
  }
  
  /// Extrai thresholds de texto descritivo
  Map<String, dynamic> _parseThresholdFromText(String text) {
    // Ex: "2 lagartas/m² ou 30% de desfolha" -> retorna 2 como threshold
    final number = _extractNumber(text) ?? 2;
    
    return {
      'low': (number * 0.5).round(),
      'medium': number,
      'high': (number * 1.5).round(),
      'critical': number * 2,
      'description': text,
    };
  }
  
  /// Extrai número de string (ex: "1-2" -> 2, ">10" -> 10)
  int? _extractNumber(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    
    // Procurar por padrão como ">8" ou "1-2" ou "3-5"
    final match = RegExp(r'>?(\d+)[-–]?(\d+)?').firstMatch(str);
    if (match != null) {
      // Se tem range (1-2), pegar o maior número
      if (match.group(2) != null) {
        return int.tryParse(match.group(2)!);
      }
      // Senão, pegar o primeiro número
      return int.tryParse(match.group(1) ?? '0');
    }
    
    // Fallback: procurar qualquer número
    final simpleMatch = RegExp(r'(\d+)').firstMatch(str);
    return simpleMatch != null ? int.tryParse(simpleMatch.group(1) ?? '0') : null;
  }

  /// Determina o nível baseado nos thresholds
  String _determineLevelFromThresholds(double quantity, Map<String, dynamic> thresholds) { // ✅ ALTERADO: double
    final low = (thresholds['low'] as num?)?.toDouble() ?? 0.0;
    final medium = (thresholds['medium'] as num?)?.toDouble() ?? 1.0;
    final high = (thresholds['high'] as num?)?.toDouble() ?? 3.0;
    final critical = (thresholds['critical'] as num?)?.toDouble() ?? 5.0;
    
    // ✅ LOGS DETALHADOS PARA DEBUG
    Logger.info('🔍 [DEBUG] Comparando thresholds:');
    Logger.info('   Quantidade: $quantity');
    Logger.info('   Baixo ≤ $low');
    Logger.info('   Médio ≤ $medium');
    Logger.info('   Alto ≤ $high');
    Logger.info('   Crítico > $high');

    Logger.info('🔢 Comparando quantidade=$quantity com thresholds: Baixo≤$low, Médio≤$medium, Alto≤$high, Crítico>$high');
    
    String nivel;
    if (quantity <= low) {
      nivel = 'BAIXO';
    } else if (quantity <= medium) {
      nivel = 'MÉDIO';
    } else if (quantity <= high) {
      nivel = 'ALTO';
    } else {
      nivel = 'CRÍTICO';
    }
    
    // ✅ LOG DO RESULTADO
    Logger.info('   ➡️ NÍVEL DETERMINADO: $nivel');
    
    return nivel;
  }

  /// ✅ NOVO: Calcula nível usando PADRÃO MIP (Manejo Integrado de Pragas)
  Future<TalhaoInfestationResult> calculateTalhaoLevelMIP({
    required List<MonitoringPointData> points,
    required String phenologicalStage,
    required String cropId,
    required int totalPontosMapeados, // ✅ Total de pontos GPS monitorados
  }) async {
    await initialize();
    
    try {
      Logger.info('🧮 [MIP] Calculando nível do talhão usando PADRÃO MIP');
      Logger.info('🧮 [MIP] Total de ocorrências: ${points.length}');
      Logger.info('🧮 [MIP] Total de pontos mapeados: $totalPontosMapeados');
      
      // PADRÃO MIP: Agrupar por organismo
      final byOrganism = <String, List<MonitoringPointData>>{};
      for (final point in points) {
        byOrganism.putIfAbsent(point.organismName, () => []).add(point);
      }

      // Calcular nível para cada organismo
      final results = <OrganismInfestationResult>[];
      
      for (final entry in byOrganism.entries) {
        final organismName = entry.key;
        final organismOccurrences = entry.value;
        
        // 📊 PADRÃO MIP - FÓRMULAS AGRONÔMICAS REAIS
        
        // 1️⃣ QUANTIDADE TOTAL: Somar todas as ocorrências
        final totalQuantity = organismOccurrences.fold<int>(0, (sum, p) => sum + p.quantity);
        
        // 2️⃣ NÚMERO DE OCORRÊNCIAS (amostras)
        final numeroOcorrencias = organismOccurrences.length;
        
        // 3️⃣ MÉDIA POR AMOSTRA = Total / Número de ocorrências
        // Exemplo: 3 ocorrências de 4 Torraozinho = 12 / 3 = 4 unidades/amostra
        final avgQuantity = numeroOcorrencias > 0 ? totalQuantity / numeroOcorrencias : 0.0;
        
        // 4️⃣ FREQUÊNCIA = (Pontos com infestação / Total de pontos mapeados) × 100
        // Considerar que cada ocorrência pode ser de um ponto diferente
        // Mas como não temos point_id aqui, assumir que temos 'numeroOcorrencias' pontos distintos
        final pontosComInfestacao = numeroOcorrencias; // Cada ocorrência = 1 ponto
        final frequency = totalPontosMapeados > 0
            ? (pontosComInfestacao / totalPontosMapeados) * 100
            : 0.0;
        
        // 5️⃣ ÍNDICE DE INFESTAÇÃO = (Frequência × Média) / 100
        final indice = (frequency * avgQuantity) / 100;
        
        Logger.info('📊 [MIP] $organismName:');
        Logger.info('   • Ocorrências: $numeroOcorrencias');
        Logger.info('   • Total encontrado: $totalQuantity organismos');
        Logger.info('   • Média/amostra: ${avgQuantity.toStringAsFixed(2)} unidades');
        Logger.info('   • Pontos c/ infestação: $pontosComInfestacao');
        Logger.info('   • Frequência: ${frequency.toStringAsFixed(1)}% ($pontosComInfestacao/$totalPontosMapeados)');
        Logger.info('   • Índice: ${indice.toStringAsFixed(2)}');
        
        // 6️⃣ DETERMINAR NÍVEL usando thresholds fenológicos
        final level = await calculateLevel(
          organismId: organismOccurrences.first.organismId,
          organismName: organismName,
          quantity: avgQuantity, // ✅ Usar MÉDIA para comparar com thresholds
          phenologicalStage: phenologicalStage,
          cropId: cropId,
        );
        
        results.add(OrganismInfestationResult(
          organismName: organismName,
          level: level,
          pointCount: pontosComInfestacao, // ✅ Pontos com infestação
          totalPoints: totalPontosMapeados, // ✅ Total de pontos mapeados
          frequency: frequency, // ✅ Frequência correta
          totalQuantity: totalQuantity, // ✅ TOTAL encontrado
          avgQuantity: avgQuantity, // ✅ MÉDIA por amostra
        ));
      }

      // Ordenar por índice (maior risco primeiro)
      results.sort((a, b) {
        final indiceA = (a.frequency * a.avgQuantity) / 100;
        final indiceB = (b.frequency * b.avgQuantity) / 100;
        return indiceB.compareTo(indiceA);
      });

      // Determinar nível geral do talhão
      final generalLevel = results.isEmpty ? 'BAIXO' : results.first.level.level;
      final hasActionRequired = results.any((r) => 
        r.level.isCriticalStage && (r.level.level == 'ALTO' || r.level.level == 'CRÍTICO')
      );

      Logger.info('📊 [MIP] Nível geral do talhão: $generalLevel');
      Logger.info('📊 [MIP] Organismos processados: ${results.length}');

      return TalhaoInfestationResult(
        phenologicalStage: phenologicalStage,
        generalLevel: generalLevel,
        organisms: results,
        actionRequired: hasActionRequired,
      );
    } catch (e) {
      Logger.error('❌ [MIP] Erro ao calcular nível do talhão: $e');
      return TalhaoInfestationResult(
        phenologicalStage: phenologicalStage,
        generalLevel: 'BAIXO',
        organisms: [],
        actionRequired: false,
      );
    }
  }

  /// Calcula nível agregado para múltiplos pontos de monitoramento (MÉTODO LEGADO)
  Future<TalhaoInfestationResult> calculateTalhaoLevel({
    required List<MonitoringPointData> points,
    required String phenologicalStage,
    required String cropId,
  }) async {
    await initialize();
    
    try {
      Logger.info('🧮 Calculando nível do talhão: ${points.length} pontos');
      
      // Agrupar por organismo
      final byOrganism = <String, List<MonitoringPointData>>{};
      for (final point in points) {
        byOrganism.putIfAbsent(point.organismName, () => []).add(point);
      }

      // Calcular nível para cada organismo
      final results = <OrganismInfestationResult>[];
      
      for (final entry in byOrganism.entries) {
        final organismName = entry.key;
        final organismPoints = entry.value;
        
        // ✅ CÁLCULO AGRONÔMICO CORRETO
        // Padrão MIP: Soma total de organismos / Número de amostras (ocorrências)
        // Exemplo: 3 ocorrências de 4 Torraozinho cada → Total = 12 / 3 = 4 unidades/ponto
        
        final totalQuantity = organismPoints.fold<int>(0, (sum, p) => sum + p.quantity);
        
        // ✅ TOTAL DE OCORRÊNCIAS (cada item em organismPoints é uma ocorrência)
        final numeroOcorrencias = organismPoints.length;
        
        // ✅ TOTAL DE PONTOS MONITORADOS: buscar do contexto geral (todos organismos)
        // Agrupar points por organismName para saber quantos pontos únicos foram monitorados
        final pontosUnicosSet = <String>{};
        for (final p in points) {
          pontosUnicosSet.add('${p.organismName}_${p.quantity}'); // Identificador único por ocorrência
        }
        // Como cada MonitoringPointData agora representa uma ocorrência real,
        // o total de pontos é o número de ocorrências deste organismo
        final totalPontosMonitorados = numeroOcorrencias;
        
        // MÉDIA POR PONTO = Total de organismos / Número de ocorrências
        // ✅ MANTÉM VALOR DECIMAL para precisão agronômica
        final avgQuantity = numeroOcorrencias > 0 ? totalQuantity / numeroOcorrencias : 0.0;
        
        // CÁLCULO DE FREQUÊNCIA
        // Frequência = 100% (já que todos os points aqui são deste organismo)
        // Para frequência real entre organismos, deve ser calculado externamente
        final frequency = 100.0; // Todos os pontos neste agrupamento têm este organismo
        
        Logger.info('📊 $organismName:');
        Logger.info('   • Número de ocorrências: $numeroOcorrencias');
        Logger.info('   • Total encontrado: $totalQuantity organismos');
        Logger.info('   • Média por ocorrência: ${avgQuantity.toStringAsFixed(2)} unidades/ocorrência');
        Logger.info('   • Frequência interna: ${frequency.toStringAsFixed(1)}%');
        
        // Calcular nível considerando fenologia
        final level = await calculateLevel(
          organismId: organismPoints.first.organismId,
          organismName: organismName,
          quantity: avgQuantity,
          phenologicalStage: phenologicalStage,
          cropId: cropId,
        );
        
        results.add(OrganismInfestationResult(
          organismName: organismName,
          level: level,
          pointCount: numeroOcorrencias, // ✅ Número de ocorrências registradas
          totalPoints: totalPontosMonitorados,
          frequency: frequency,
          totalQuantity: totalQuantity, // ✅ TOTAL encontrado
          avgQuantity: avgQuantity, // ✅ MÉDIA por ponto
        ));
      }

      // Ordenar por prioridade (críticos primeiro, depois por nível e frequência)
      results.sort((a, b) {
        // 1. Estágios críticos primeiro
        if (a.level.isCriticalStage != b.level.isCriticalStage) {
          return a.level.isCriticalStage ? -1 : 1;
        }
        // 2. Nível mais alto primeiro
        final levelCompare = _compareLevels(a.level.level, b.level.level);
        if (levelCompare != 0) return levelCompare;
        // 3. Maior frequência primeiro
        return b.frequency.compareTo(a.frequency);
      });

      // Determinar nível geral do talhão
      final generalLevel = results.isEmpty ? 'BAIXO' : results.first.level.level;
      final hasActionRequired = results.any((r) => 
        r.level.isCriticalStage && (r.level.level == 'ALTO' || r.level.level == 'CRÍTICO')
      );

      Logger.info('📊 Nível geral do talhão: $generalLevel');

      return TalhaoInfestationResult(
        phenologicalStage: phenologicalStage,
        generalLevel: generalLevel,
        organisms: results,
        actionRequired: hasActionRequired,
      );
    } catch (e) {
      Logger.error('❌ Erro ao calcular nível do talhão: $e');
      return TalhaoInfestationResult(
        phenologicalStage: phenologicalStage,
        generalLevel: 'BAIXO',
        organisms: [],
        actionRequired: false,
      );
    }
  }

  /// Compara níveis de infestação
  int _compareLevels(String levelA, String levelB) {
    const levelOrder = {'CRÍTICO': 3, 'ALTO': 2, 'MÉDIO': 1, 'BAIXO': 0};
    final orderA = levelOrder[levelA] ?? 0;
    final orderB = levelOrder[levelB] ?? 0;
    return orderB.compareTo(orderA); // Ordem decrescente
  }
}

/// Resultado do cálculo de infestação para um organismo
class InfestationLevel {
  final String organismId;
  final String organismName;
  final double quantity; // ✅ ALTERADO: double para permitir 1.33, 2.67, etc.
  final String level; // BAIXO, MÉDIO, ALTO, CRÍTICO
  final String phenologicalStage;
  final bool isCriticalStage;
  final String stageDescription;
  final String damageType;
  final String unit;
  final Map<String, dynamic> thresholds;

  InfestationLevel({
    required this.organismId,
    required this.organismName,
    required this.quantity,
    required this.level,
    required this.phenologicalStage,
    required this.isCriticalStage,
    required this.stageDescription,
    required this.damageType,
    required this.unit,
    required this.thresholds,
  });

  /// Cria um nível desconhecido
  factory InfestationLevel.unknown(String organismName, double quantity) { // ✅ ALTERADO: double
    return InfestationLevel(
      organismId: 'unknown',
      organismName: organismName,
      quantity: quantity,
      level: 'BAIXO',
      phenologicalStage: 'UNKNOWN',
      isCriticalStage: false,
      stageDescription: 'Dados insuficientes',
      damageType: '',
      unit: 'unidades',
      thresholds: {},
    );
  }

  @override
  String toString() {
    return 'InfestationLevel($organismName: $quantity $unit = $level em $phenologicalStage)';
  }
}

/// Dados de um ponto de monitoramento
class MonitoringPointData {
  final String organismId;
  final String organismName;
  final int quantity;

  MonitoringPointData({
    required this.organismId,
    required this.organismName,
    required this.quantity,
  });
}

/// Resultado do cálculo para um organismo no talhão
class OrganismInfestationResult {
  final String organismName;
  final InfestationLevel level;
  final int pointCount;
  final int totalPoints;
  final double frequency;
  final int totalQuantity; // ✅ TOTAL de organismos encontrados
  final double avgQuantity; // ✅ MÉDIA por ponto

  OrganismInfestationResult({
    required this.organismName,
    required this.level,
    required this.pointCount,
    required this.totalPoints,
    required this.frequency,
    required this.totalQuantity,
    required this.avgQuantity,
  });
}

/// Resultado do cálculo de infestação do talhão
class TalhaoInfestationResult {
  final String phenologicalStage;
  final String generalLevel;
  final List<OrganismInfestationResult> organisms;
  final bool actionRequired;
  final bool hasMonitoringData; // ✅ NOVO: Indica se TEM dados de monitoramento
  final bool hasPhenologicalData; // ✅ NOVO: Indica se TEM dados fenológicos reais
  final List<Map<String, dynamic>>? rawOrganisms; // ✅ NOVO: Dados brutos para fallback

  TalhaoInfestationResult({
    required this.phenologicalStage,
    required this.generalLevel,
    required this.organisms,
    required this.actionRequired,
    this.hasMonitoringData = false,
    this.hasPhenologicalData = false,
    this.rawOrganisms,
  });
}

