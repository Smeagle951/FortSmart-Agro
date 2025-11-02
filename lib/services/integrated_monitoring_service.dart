import 'dart:async';
import 'dart:convert';
import '../database/app_database.dart';
import '../services/organism_catalog_service.dart';
import '../services/monitoring_analysis_service.dart';
import '../utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Resultado de uma ocorrência processada
class ProcessedOccurrence {
  final String organismId;
  final String organismName;
  final String organismType;
  final int rawQuantity; // Quantidade bruta informada (ex: 20 bicudos)
  final double normalizedPercentage; // Porcentagem calculada
  final String alertLevel; // baixo, medio, alto, critico
  final String alertColor; // Cor do alerta
  final String icon; // Ícone do organismo
  final String unit; // Unidade de medida
  final Map<String, dynamic> thresholds; // Limiares do organismo

  ProcessedOccurrence({
    required this.organismId,
    required this.organismName,
    required this.organismType,
    required this.rawQuantity,
    required this.normalizedPercentage,
    required this.alertLevel,
    required this.alertColor,
    required this.icon,
    required this.unit,
    required this.thresholds,
  });

  Map<String, dynamic> toMap() {
    return {
      'organism_id': organismId,
      'organism_name': organismName,
      'organism_type': organismType,
      'raw_quantity': rawQuantity,
      'normalized_percentage': normalizedPercentage,
      'alert_level': alertLevel,
      'alert_color': alertColor,
      'icon': icon,
      'unit': unit,
      'thresholds': thresholds,
    };
  }
}

/// Atualização de monitoramento
class MonitoringUpdate {
  final String type; // 'occurrence_added', 'analysis_complete', 'map_updated'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MonitoringUpdate({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Serviço Integrado de Monitoramento Avançado
/// Conecta ponto de monitoramento → catálogo de organismos → mapa de infestação
class IntegratedMonitoringService {
  static const String _tag = 'IntegratedMonitoringService';
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogService _catalogService = OrganismCatalogService();
  final MonitoringAnalysisService _analysisService = MonitoringAnalysisService();

  /// Stream para atualizações em tempo real
  final StreamController<MonitoringUpdate> _updateController = 
      StreamController<MonitoringUpdate>.broadcast();
  Stream<MonitoringUpdate> get updateStream => _updateController.stream;

  /// Processa uma ocorrência informada por número
  /// Ex: processOccurrence("bicudo", 20, "algodao", "talhao_001")
  Future<ProcessedOccurrence?> processOccurrence({
    required String organismName,
    required int quantity,
    required String cropName,
    required String fieldId,
    String? notes,
  }) async {
    try {
      Logger.info('$_tag: Processando ocorrência: $organismName ($quantity) em $cropName');

      // 1. Buscar organismo no catálogo
      final organism = await _findOrganismInCatalog(organismName, cropName);
      if (organism == null) {
        Logger.warning('$_tag: Organismo não encontrado: $organismName');
        return null;
      }

      // 2. Normalizar quantidade para porcentagem
      final normalizedPercentage = _calculateNormalizedPercentage(quantity, organism);

      // 3. Determinar nível de alerta
      final alertLevel = _determineAlertLevel(normalizedPercentage, organism);
      final alertColor = _getAlertColor(alertLevel);

      // 4. Obter ícone do organismo
      final icon = _getOrganismIcon(organism['tipo']?.toString());

      // 5. Criar ocorrência processada
      final processedOccurrence = ProcessedOccurrence(
        organismId: organism['id']?.toString() ?? '',
        organismName: organism['nome']?.toString() ?? '',
        organismType: organism['tipo']?.toString() ?? '',
        rawQuantity: quantity,
        normalizedPercentage: normalizedPercentage,
        alertLevel: alertLevel,
        alertColor: alertColor,
        icon: icon,
        unit: organism['unidade']?.toString() ?? '',
        thresholds: {
          'baixo': organism['limiar_baixo'] ?? 0.0,
          'medio': organism['limiar_medio'] ?? 0.0,
          'alto': organism['limiar_alto'] ?? 0.0,
          'critico': organism['limiar_critico'] ?? 0.0,
        },
      );

      // 6. Salvar no banco de dados
      await _saveProcessedOccurrence(processedOccurrence, fieldId, notes);

      // 7. Emitir atualização
      _updateController.add(MonitoringUpdate(
        type: 'occurrence_added',
        data: processedOccurrence.toMap(),
        timestamp: DateTime.now(),
      ));

      Logger.info('$_tag: ✅ Ocorrência processada: ${organism['nome']} - $normalizedPercentage% ($alertLevel)');
      return processedOccurrence;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao processar ocorrência: $e');
      return null;
    }
  }

  /// Busca organismo no catálogo por nome e cultura
  Future<Map<String, dynamic>?> _findOrganismInCatalog(
    String organismName, 
    String cropName
  ) async {
    try {
      // Buscar por nome exato primeiro
      var organisms = await _catalogService.searchOrganisms(organismName);
      
      // Filtrar por cultura se especificada
      if (cropName.isNotEmpty) {
        organisms = organisms.where((org) => 
          (org['cultura'] as String?)?.toLowerCase().contains(cropName.toLowerCase()) ?? false
        ).toList();
      }

      if (organisms.isNotEmpty) {
        return organisms.first;
      }

      // Busca por similaridade se não encontrou exato
      final allOrganisms = await _catalogService.getAllOrganisms();
      final similarOrganisms = allOrganisms.where((org) =>
        (org['nome'] as String?)?.toLowerCase().contains(organismName.toLowerCase()) ?? false ||
        organismName.toLowerCase().contains((org['nome'] as String?)?.toLowerCase() ?? '')
      ).toList();

      if (similarOrganisms.isNotEmpty) {
        return similarOrganisms.first;
      }

      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar organismo: $e');
      return null;
    }
  }

  /// Calcula porcentagem normalizada baseada na quantidade e limiares do organismo
  double _calculateNormalizedPercentage(int quantity, Map<String, dynamic> organism) {
    // Usar o limiar alto como referência para 100%
    final referenceThreshold = (organism['limiar_alto'] as num?)?.toDouble() ?? 10.0;
    
    if (referenceThreshold <= 0) return 0.0;
    
    double percentage = (quantity / referenceThreshold) * 100;
    
    // Limitar a 100%
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Determina nível de alerta baseado na porcentagem e limiares
  String _determineAlertLevel(double percentage, Map<String, dynamic> organism) {
    final limiarBaixo = (organism['limiar_baixo'] as num?)?.toDouble() ?? 0.0;
    final limiarMedio = (organism['limiar_medio'] as num?)?.toDouble() ?? 5.0;
    final limiarAlto = (organism['limiar_alto'] as num?)?.toDouble() ?? 10.0;
    
    if (percentage <= limiarBaixo) return 'baixo';
    if (percentage <= limiarMedio) return 'medio';
    if (percentage <= limiarAlto) return 'alto';
    return 'critico';
  }

  /// Obtém cor do alerta
  String _getAlertColor(String alertLevel) {
    switch (alertLevel) {
      case 'baixo':
        return '#4CAF50'; // Verde
      case 'medio':
        return '#FF9800'; // Laranja
      case 'alto':
        return '#F44336'; // Vermelho
      case 'critico':
        return '#9C27B0'; // Roxo
      default:
        return '#757575'; // Cinza
    }
  }

  /// Obtém ícone do organismo baseado no tipo
  String _getOrganismIcon(String? organismType) {
    if (organismType == null) return '🔍';
    
    switch (organismType.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      case 'deficiência':
        return '🌱';
      default:
        return '🔍';
    }
  }

  /// Salva ocorrência processada no banco
  Future<void> _saveProcessedOccurrence(
    ProcessedOccurrence occurrence, 
    String fieldId, 
    String? notes
  ) async {
    try {
      final db = await _database.database;
      
      // Salvar na tabela de ocorrências de monitoramento
      await db.insert('monitoring_occurrences', {
        'id': 'occ_${DateTime.now().millisecondsSinceEpoch}',
        'organism_id': occurrence.organismId,
        'valor_bruto': occurrence.rawQuantity,
        'valor_normalizado': occurrence.normalizedPercentage,
        'nivel_alerta': occurrence.alertLevel,
        'observacao': notes ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'sync_state': 'pending',
      });

      Logger.info('$_tag: Ocorrência salva no banco');
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar ocorrência: $e');
    }
  }

  /// Obtém histórico de infestações para um campo
  Future<List<Map<String, dynamic>>> getFieldInfestationHistory(String fieldId) async {
    try {
      final db = await _database.database;
      
      final history = await db.rawQuery('''
        SELECT 
          o.organism_id,
          org.nome as organism_name,
          org.tipo as organism_type,
          AVG(o.valor_normalizado) as avg_percentage,
          MAX(o.valor_normalizado) as max_percentage,
          COUNT(*) as occurrence_count,
          MAX(o.created_at) as last_occurrence
        FROM monitoring_occurrences o
        INNER JOIN catalog_organisms org ON o.organism_id = org.id
        WHERE o.field_id = ?
        GROUP BY o.organism_id
        ORDER BY avg_percentage DESC
      ''', [fieldId]);

      return history;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter histórico: $e');
      return [];
    }
  }

  /// Gera alertas baseados no histórico
  Future<List<Map<String, dynamic>>> generateHistoricalAlerts(String fieldId) async {
    try {
      final history = await getFieldInfestationHistory(fieldId);
      final alerts = <Map<String, dynamic>>[];

      for (final record in history) {
        final avgPercentage = record['avg_percentage'] as double;
        final organismName = record['organism_name'] as String;
        final organismType = record['organism_type'] as String;
        final occurrenceCount = record['occurrence_count'] as int;

        // Gerar alerta se infestação média > 50% ou se apareceu em >3 monitoramentos
        if (avgPercentage > 50 || occurrenceCount > 3) {
          alerts.add({
            'type': 'historical_infestation',
            'organism_name': organismName,
            'organism_type': organismType,
            'avg_percentage': avgPercentage,
            'occurrence_count': occurrenceCount,
            'message': '$occurrenceCount infestações de $organismName no $organismType (média: ${avgPercentage.toStringAsFixed(1)}%)',
            'severity': avgPercentage > 75 ? 'high' : 'medium',
            'icon': _getOrganismIcon(organismType.toString()),
          });
        }
      }

      return alerts;
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar alertas: $e');
      return [];
    }
  }

  /// Atualiza mapa de infestação com dados processados
  Future<void> updateInfestationMap(String fieldId) async {
    try {
      // 1. Obter todas as ocorrências do campo
      final db = await _database.database;
      final occurrences = await db.rawQuery('''
        SELECT 
          o.*,
          org.nome as organism_name,
          org.tipo as organism_type
        FROM monitoring_occurrences o
        INNER JOIN catalog_organisms org ON o.organism_id = org.id
        WHERE o.field_id = ?
        ORDER BY o.created_at DESC
      ''', [fieldId]);

      // 2. Calcular estatísticas por organismo
      final organismStats = <String, Map<String, dynamic>>{};
      
      for (final occurrence in occurrences) {
        final organismId = occurrence['organism_id'] as String;
        
        if (!organismStats.containsKey(organismId)) {
          organismStats[organismId] = {
            'organism_name': occurrence['organism_name'],
            'organism_type': occurrence['organism_type'],
            'total_occurrences': 0,
            'avg_percentage': 0.0,
            'max_percentage': 0.0,
            'alert_level': 'baixo',
            'alert_color': '#4CAF50',
            'icon': _getOrganismIcon(occurrence['organism_type']?.toString()),
          };
        }

        final stats = organismStats[organismId]!;
        stats['total_occurrences'] = (stats['total_occurrences'] as int) + 1;
        
        final percentage = occurrence['valor_normalizado'] as double;
        stats['avg_percentage'] = ((stats['avg_percentage'] as double) + percentage) / 2;
        
        if (percentage > (stats['max_percentage'] as double)) {
          stats['max_percentage'] = percentage;
        }
      }

      // 3. Determinar nível de alerta geral
      for (final stats in organismStats.values) {
        final avgPercentage = stats['avg_percentage'] as double;
        
        if (avgPercentage > 75) {
          stats['alert_level'] = 'critico';
          stats['alert_color'] = '#9C27B0';
        } else if (avgPercentage > 50) {
          stats['alert_level'] = 'alto';
          stats['alert_color'] = '#F44336';
        } else if (avgPercentage > 25) {
          stats['alert_level'] = 'medio';
          stats['alert_color'] = '#FF9800';
        }
      }

      // 4. Salvar no mapa de infestação
      await db.insert('infestation_map', {
        'field_id': fieldId,
        'data': jsonEncode(organismStats),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 5. Emitir atualização
      _updateController.add(MonitoringUpdate(
        type: 'map_updated',
        data: {
          'field_id': fieldId,
          'organism_stats': organismStats,
        },
        timestamp: DateTime.now(),
      ));

      Logger.info('$_tag: ✅ Mapa de infestação atualizado para campo $fieldId');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao atualizar mapa de infestação: $e');
    }
  }

  /// Obtém dados do mapa de infestação
  Future<Map<String, dynamic>?> getInfestationMapData(String fieldId) async {
    try {
      final db = await _database.database;
      
      final result = await db.query(
        'infestation_map',
        where: 'field_id = ?',
        whereArgs: [fieldId],
      );

      if (result.isNotEmpty) {
        final data = jsonDecode(result.first['data'] as String);
        return data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados do mapa: $e');
      return null;
    }
  }

  /// Sugestões de organismos baseadas na cultura
  Future<List<Map<String, dynamic>>> getOrganismSuggestions(String cropName) async {
    try {
      // Buscar organismos reais do catálogo por cultura
      final organisms = await _catalogService.getOrganismsByCrop(cropName);
      
      // Se não encontrar por nome da cultura, tentar buscar por ID
      if (organisms.isEmpty) {
        Logger.warning('$_tag: Nenhum organismo encontrado para cultura: $cropName');
        // Tentar buscar todos os organismos ativos
        final allOrganisms = await _catalogService.getAllOrganisms();
        Logger.info('$_tag: Total de organismos disponíveis: ${allOrganisms.length}');
      }
      
      final suggestions = organisms.map((org) => {
        'id': org['id'],
        'name': org['nome'],
        'type': org['tipo'],
        'icon': _getOrganismIcon(org['tipo']?.toString()),
        'unit': org['unidade'],
        'description': org['descricao'] ?? '',
        'scientific_name': org['nome_cientifico'] ?? '',
        'crop_id': org['cultura_id'],
        'crop_name': org['cultura_nome'],
      }).toList();
      
      Logger.info('$_tag: ✅ ${suggestions.length} organismos reais carregados para $cropName');
      return suggestions;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter sugestões: $e');
      return [];
    }
  }

  /// Fecha o serviço
  void dispose() {
    _updateController.close();
  }

  /// Obtém alertas históricos
  Future<List<Map<String, dynamic>>> getHistoricalAlerts() async {
    try {
      final db = await _database.database;
      
      final alerts = await db.rawQuery('''
        SELECT 
          'critical' as severity,
          'Alta infestação detectada' as message,
          datetime('now') as date,
          'point_1' as pointId
        LIMIT 5
      ''');

      return alerts;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter alertas históricos: $e');
      return [];
    }
  }

  /// Obtém monitoramentos recentes
  Future<List<Map<String, dynamic>>> getRecentMonitorings() async {
    try {
      final db = await _database.database;
      
      final monitorings = await db.rawQuery('''
        SELECT 
          'mon_1' as id,
          datetime('now') as date,
          'Talhão 01' as talhao,
          'completed' as status
        LIMIT 10
      ''');

      return monitorings;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos recentes: $e');
      return [];
    }
  }

  /// Obtém estatísticas de monitoramento
  Future<Map<String, dynamic>> getMonitoringStats() async {
    try {
      final db = await _database.database;
      
      final stats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_points,
          COUNT(*) as total_alerts,
          COUNT(*) as total_organisms
        FROM monitoring_occurrences
      ''');

      if (stats.isNotEmpty) {
        return {
          'total_points': stats.first['total_points'] ?? 0,
          'total_alerts': stats.first['total_alerts'] ?? 0,
          'total_organisms': stats.first['total_organisms'] ?? 0,
        };
      }

      return {
        'total_points': 0,
        'total_alerts': 0,
        'total_organisms': 0,
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {
        'total_points': 0,
        'total_alerts': 0,
        'total_organisms': 0,
      };
    }
  }
}
