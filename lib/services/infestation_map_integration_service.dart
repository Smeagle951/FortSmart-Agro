import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'modules_integration_service.dart';
import 'organism_catalog_integration_service.dart';

/// Serviço de integração para o Mapa de Infestação
/// Utiliza dados integrados dos módulos de Monitoramento e Catálogo de Organismos
class InfestationMapIntegrationService {
  final AppDatabase _database = AppDatabase();
  final ModulesIntegrationService _modulesIntegration = ModulesIntegrationService();
  final OrganismCatalogIntegrationService _catalogIntegration = OrganismCatalogIntegrationService();
  
  static const String _tableName = 'infestation_map_data';

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      final db = await _database.database;
      
      // Tabela para dados do mapa de infestação
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          talhao_nome TEXT NOT NULL,
          cultura_nome TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          organismo_nome TEXT NOT NULL,
          organismo_tipo TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          quantidade_detectada REAL NOT NULL,
          unidade_medida TEXT NOT NULL,
          nivel_intensidade TEXT NOT NULL,
          cor_mapa TEXT NOT NULL,
          data_monitoramento TEXT NOT NULL,
          monitoring_id TEXT NOT NULL,
          monitoring_point_id TEXT NOT NULL,
          secoes_afetadas TEXT,
          observacoes TEXT,
          confiabilidade REAL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Índices para performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_map_talhao 
        ON $_tableName(talhao_id, data_monitoramento)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_map_organismo 
        ON $_tableName(organismo_id, nivel_intensidade)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_map_location 
        ON $_tableName(latitude, longitude)
      ''');

      Logger.info('✅ InfestationMapIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar InfestationMapIntegrationService: $e');
      rethrow;
    }
  }

  /// Processa dados de monitoramento para o mapa de infestação
  Future<Map<String, dynamic>> processMonitoringForMap(List<Map<String, dynamic>> monitoringData) async {
    try {
      Logger.info('🔄 Processando ${monitoringData.length} registros para mapa de infestação');
      
      // 1. Processar dados através do serviço de integração de módulos
      final integratedData = await _modulesIntegration.processMonitoringData(
        _createMockMonitoring(monitoringData)
      );
      
      // 2. Atualizar catálogo com dados de monitoramento
      await _catalogIntegration.updateCatalogWithMonitoringData(monitoringData);
      
      // 3. Salvar dados específicos do mapa
      await _saveMapData(integratedData['organismos_processados'] as List<Map<String, dynamic>>);
      
      // 4. Gerar dados para visualização no mapa
      final mapData = await _generateMapVisualizationData(integratedData);
      
      Logger.info('✅ Dados processados para mapa: ${mapData['total_pontos']} pontos');
      return mapData;
      
    } catch (e) {
      Logger.error('❌ Erro ao processar dados para mapa: $e');
      rethrow;
    }
  }

  /// Cria um objeto Monitoring mock para compatibilidade
  dynamic _createMockMonitoring(List<Map<String, dynamic>> monitoringData) {
    if (monitoringData.isEmpty) return null;
    
    final firstData = monitoringData.first;
    return {
      'id': firstData['monitoring_id'] ?? 'mock_monitoring',
      'plotId': int.tryParse(firstData['talhao_id']?.toString() ?? '0') ?? 0,
      'plotName': firstData['talhao_nome'] ?? 'Talhão Mock',
      'cropName': firstData['cultura'] ?? 'Cultura Mock',
      'date': DateTime.tryParse(firstData['data_monitoramento']?.toString() ?? '') ?? DateTime.now(),
      'points': monitoringData.map((data) => _createMockMonitoringPoint(data)).toList(),
    };
  }

  /// Cria um objeto MonitoringPoint mock para compatibilidade
  dynamic _createMockMonitoringPoint(Map<String, dynamic> data) {
    return {
      'id': data['monitoring_point_id'] ?? 'mock_point',
      'latitude': data['latitude'] ?? 0.0,
      'longitude': data['longitude'] ?? 0.0,
      'occurrences': [_createMockOccurrence(data)],
    };
  }

  /// Cria um objeto Occurrence mock para compatibilidade
  dynamic _createMockOccurrence(Map<String, dynamic> data) {
    return {
      'name': data['organismo_nome'] ?? 'Organismo Mock',
      'type': data['organismo_tipo'] ?? 'praga',
      'infestationIndex': data['quantidade_detectada'] ?? 0.0,
      'affectedSections': data['secoes_afetadas'] ?? [],
      'notes': data['observacoes'],
    };
  }

  /// Salva dados específicos do mapa
  Future<void> _saveMapData(List<Map<String, dynamic>> organismsData) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toIso8601String();
      
      for (final organism in organismsData) {
        await db.insert(
          _tableName,
          {
            'id': '${organism['monitoring_id']}_${organism['monitoring_point_id']}_${organism['organismo_id']}',
            'talhao_id': organism['talhao_id'],
            'talhao_nome': organism['talhao_nome'],
            'cultura_nome': organism['cultura'],
            'organismo_id': organism['organismo_id'],
            'organismo_nome': organism['organismo_nome'],
            'organismo_tipo': organism['organismo_tipo'],
            'latitude': organism['latitude'],
            'longitude': organism['longitude'],
            'quantidade_detectada': organism['quantidade_detectada'],
            'unidade_medida': organism['unidade_medida'],
            'nivel_intensidade': organism['nivel_intensidade'],
            'cor_mapa': organism['cor_mapa'],
            'data_monitoramento': organism['data_monitoramento'],
            'monitoring_id': organism['monitoring_id'],
            'monitoring_point_id': organism['monitoring_point_id'],
            'secoes_afetadas': jsonEncode(organism['secoes_afetadas']),
            'observacoes': organism['observacoes'],
            'confiabilidade': organism['confiabilidade'] ?? 0.0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      Logger.info('✅ Dados do mapa salvos: ${organismsData.length} registros');
    } catch (e) {
      Logger.error('❌ Erro ao salvar dados do mapa: $e');
    }
  }

  /// Gera dados para visualização no mapa
  Future<Map<String, dynamic>> _generateMapVisualizationData(Map<String, dynamic> integratedData) async {
    try {
      final organismsData = integratedData['organismos_processados'] as List;
      
      // Agrupar por talhão
      final byTalhao = <String, List<Map<String, dynamic>>>{};
      for (final organism in organismsData) {
        final talhaoId = organism['talhao_id'] as String;
        byTalhao.putIfAbsent(talhaoId, () => []).add(organism);
      }
      
      // Gerar dados para cada talhão
      final talhoesData = <Map<String, dynamic>>[];
      for (final entry in byTalhao.entries) {
        final talhaoData = await _generateTalhaoMapData(entry.key, entry.value);
        talhoesData.add(talhaoData);
      }
      
      return {
        'total_talhoes': talhoesData.length,
        'total_pontos': organismsData.length,
        'total_organismos': organismsData.map((o) => o['organismo_id']).toSet().length,
        'talhoes': talhoesData,
        'alertas': integratedData['alertas_gerados'] ?? [],
        'estatisticas_gerais': await _generateGeneralStatistics(organismsData.cast<Map<String, dynamic>>()),
        'data_atualizacao': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de visualização: $e');
      return {'erro': e.toString()};
    }
  }

  /// Gera dados do mapa para um talhão específico
  Future<Map<String, dynamic>> _generateTalhaoMapData(String talhaoId, List<Map<String, dynamic>> organismsData) async {
    try {
      if (organismsData.isEmpty) {
        return {
          'talhao_id': talhaoId,
          'talhao_nome': 'Talhão Desconhecido',
          'total_pontos': 0,
          'total_organismos': 0,
          'nivel_geral': 'BAIXO',
          'cor_geral': '#4CAF50',
          'pontos': [],
          'organismos': [],
        };
      }
      
      final firstData = organismsData.first;
      final talhaoNome = firstData['talhao_nome'] as String;
      
      // Calcular nível geral do talhão
      final nivelGeral = _calculateTalhaoGeneralLevel(organismsData);
      final corGeral = _getMapColorForLevel(nivelGeral);
      
      // Agrupar por organismo
      final byOrganism = <String, List<Map<String, dynamic>>>{};
      for (final organism in organismsData) {
        final organismId = organism['organismo_id'] as String;
        byOrganism.putIfAbsent(organismId, () => []).add(organism);
      }
      
      // Gerar dados dos organismos
      final organismosData = <Map<String, dynamic>>[];
      for (final entry in byOrganism.entries) {
        final organismData = _generateOrganismMapData(entry.key, entry.value);
        organismosData.add(organismData);
      }
      
      // Ordenar organismos por severidade
      organismosData.sort((a, b) {
        final levelOrder = {'CRITICO': 4, 'ALTO': 3, 'MODERADO': 2, 'BAIXO': 1};
        final aLevel = levelOrder[a['nivel_mais_comum']] ?? 0;
        final bLevel = levelOrder[b['nivel_mais_comum']] ?? 0;
        return bLevel.compareTo(aLevel);
      });
      
      return {
        'talhao_id': talhaoId,
        'talhao_nome': talhaoNome,
        'total_pontos': organismsData.length,
        'total_organismos': organismosData.length,
        'nivel_geral': nivelGeral,
        'cor_geral': corGeral,
        'pontos': organismsData.map((o) => {
          'latitude': o['latitude'],
          'longitude': o['longitude'],
          'organismo': o['organismo_nome'],
          'nivel': o['nivel_intensidade'],
          'cor': o['cor_mapa'],
          'quantidade': o['quantidade_detectada'],
          'unidade': o['unidade_medida'],
        }).toList(),
        'organismos': organismosData,
        'estatisticas': {
          'nivel_baixo': organismsData.where((o) => o['nivel_intensidade'] == 'BAIXO').length,
          'nivel_moderado': organismsData.where((o) => o['nivel_intensidade'] == 'MODERADO').length,
          'nivel_alto': organismsData.where((o) => o['nivel_intensidade'] == 'ALTO').length,
          'nivel_critico': organismsData.where((o) => o['nivel_intensidade'] == 'CRITICO').length,
        },
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados do talhão: $e');
      return {'talhao_id': talhaoId, 'erro': e.toString()};
    }
  }

  /// Calcula nível geral do talhão
  String _calculateTalhaoGeneralLevel(List<Map<String, dynamic>> organismsData) {
    if (organismsData.isEmpty) return 'BAIXO';
    
    // Contar níveis
    final levelCounts = <String, int>{};
    for (final organism in organismsData) {
      final level = organism['nivel_intensidade'] as String;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }
    
    // Determinar nível predominante
    final total = organismsData.length;
    final criticoPercent = (levelCounts['CRITICO'] ?? 0) / total;
    final altoPercent = (levelCounts['ALTO'] ?? 0) / total;
    final moderadoPercent = (levelCounts['MODERADO'] ?? 0) / total;
    
    if (criticoPercent > 0.2) return 'CRITICO';
    if (altoPercent > 0.3) return 'ALTO';
    if (moderadoPercent > 0.4) return 'MODERADO';
    return 'BAIXO';
  }

  /// Gera dados do mapa para um organismo específico
  Map<String, dynamic> _generateOrganismMapData(String organismId, List<Map<String, dynamic>> organismData) {
    if (organismData.isEmpty) {
      return {
        'organismo_id': organismId,
        'organismo_nome': 'Organismo Desconhecido',
        'total_pontos': 0,
        'nivel_mais_comum': 'BAIXO',
        'cor_mais_comum': '#4CAF50',
        'media_quantidade': 0.0,
        'max_quantidade': 0.0,
        'pontos': [],
      };
    }
    
    final firstData = organismData.first;
    final organismNome = firstData['organismo_nome'] as String;
    
    // Calcular estatísticas
    final quantidades = organismData.map((o) => (o['quantidade_detectada'] as num).toDouble()).toList();
    final niveis = organismData.map((o) => o['nivel_intensidade'] as String).toList();
    
    final mediaQuantidade = quantidades.reduce((a, b) => a + b) / quantidades.length;
    final maxQuantidade = quantidades.reduce((a, b) => a > b ? a : b);
    
    // Determinar nível mais comum
    final nivelCounts = <String, int>{};
    for (final nivel in niveis) {
      nivelCounts[nivel] = (nivelCounts[nivel] ?? 0) + 1;
    }
    final nivelMaisComum = nivelCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final corMaisComum = _getMapColorForLevel(nivelMaisComum);
    
    return {
      'organismo_id': organismId,
      'organismo_nome': organismNome,
      'total_pontos': organismData.length,
      'nivel_mais_comum': nivelMaisComum,
      'cor_mais_comum': corMaisComum,
      'media_quantidade': mediaQuantidade,
      'max_quantidade': maxQuantidade,
      'pontos': organismData.map((o) => {
        'latitude': o['latitude'],
        'longitude': o['longitude'],
        'nivel': o['nivel_intensidade'],
        'cor': o['cor_mapa'],
        'quantidade': o['quantidade_detectada'],
        'unidade': o['unidade_medida'],
        'data': o['data_monitoramento'],
      }).toList(),
    };
  }

  /// Gera estatísticas gerais
  Future<Map<String, dynamic>> _generateGeneralStatistics(List<Map<String, dynamic>> organismsData) async {
    try {
      if (organismsData.isEmpty) {
        return {
          'total_organismos': 0,
          'total_pontos': 0,
          'nivel_geral': 'BAIXO',
          'organismos_por_nivel': {},
          'organismos_por_tipo': {},
        };
      }
      
      // Contar por nível
      final nivelCounts = <String, int>{};
      final tipoCounts = <String, int>{};
      
      for (final organism in organismsData) {
        final nivel = organism['nivel_intensidade'] as String;
        final tipo = organism['organismo_tipo'] as String;
        
        nivelCounts[nivel] = (nivelCounts[nivel] ?? 0) + 1;
        tipoCounts[tipo] = (tipoCounts[tipo] ?? 0) + 1;
      }
      
      // Determinar nível geral
      final total = organismsData.length;
      final criticoPercent = (nivelCounts['CRITICO'] ?? 0) / total;
      final altoPercent = (nivelCounts['ALTO'] ?? 0) / total;
      final moderadoPercent = (nivelCounts['MODERADO'] ?? 0) / total;
      
      String nivelGeral = 'BAIXO';
      if (criticoPercent > 0.1) nivelGeral = 'CRITICO';
      else if (altoPercent > 0.2) nivelGeral = 'ALTO';
      else if (moderadoPercent > 0.3) nivelGeral = 'MODERADO';
      
      return {
        'total_organismos': organismsData.map((o) => o['organismo_id']).toSet().length,
        'total_pontos': organismsData.length,
        'nivel_geral': nivelGeral,
        'organismos_por_nivel': nivelCounts,
        'organismos_por_tipo': tipoCounts,
        'percentual_por_nivel': {
          'BAIXO': ((nivelCounts['BAIXO'] ?? 0) / total * 100).toStringAsFixed(1),
          'MODERADO': ((nivelCounts['MODERADO'] ?? 0) / total * 100).toStringAsFixed(1),
          'ALTO': ((nivelCounts['ALTO'] ?? 0) / total * 100).toStringAsFixed(1),
          'CRITICO': ((nivelCounts['CRITICO'] ?? 0) / total * 100).toStringAsFixed(1),
        },
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar estatísticas gerais: $e');
      return {'erro': e.toString()};
    }
  }

  /// Determina cor do mapa baseada no nível
  String _getMapColorForLevel(String level) {
    switch (level) {
      case 'BAIXO':
        return '#4CAF50'; // Verde
      case 'MODERADO':
        return '#FFC107'; // Amarelo
      case 'ALTO':
        return '#FF9800'; // Laranja
      case 'CRITICO':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Obtém dados do mapa para visualização
  Future<Map<String, dynamic>> getMapData({
    String? talhaoId,
    String? organismoId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final db = await _database.database;
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (fromDate != null) {
        whereClause += ' AND data_monitoramento >= ?';
        whereArgs.add(fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        whereClause += ' AND data_monitoramento <= ?';
        whereArgs.add(toDate.toIso8601String());
      }
      
      final results = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_monitoramento DESC',
      );
      
      // Processar dados para o mapa
      return await _generateMapVisualizationData({
        'organismos_processados': results,
        'alertas_gerados': [],
      });
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados do mapa: $e');
      return {'erro': e.toString()};
    }
  }

  /// Obtém alertas de infestação
  Future<List<Map<String, dynamic>>> getInfestationAlerts({
    String? talhaoId,
    String? nivel,
    int limit = 50,
  }) async {
    try {
      final db = await _database.database;
      
      String whereClause = 'nivel_intensidade IN (?, ?)';
      List<dynamic> whereArgs = ['ALTO', 'CRITICO'];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (nivel != null) {
        whereClause = 'nivel_intensidade = ?';
        whereArgs = [nivel];
        if (talhaoId != null) {
          whereClause += ' AND talhao_id = ?';
          whereArgs.add(talhaoId);
        }
      }
      
      final results = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_monitoramento DESC',
        limit: limit,
      );
      
      return results.map((row) => {
        'id': row['id'],
        'talhao_id': row['talhao_id'],
        'talhao_nome': row['talhao_nome'],
        'organismo_nome': row['organismo_nome'],
        'nivel': row['nivel_intensidade'],
        'cor': row['cor_mapa'],
        'quantidade': row['quantidade_detectada'],
        'unidade': row['unidade_medida'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'data': row['data_monitoramento'],
        'descricao': 'Nível ${row['nivel_intensidade']} detectado para ${row['organismo_nome']} (${row['quantidade_detectada']} ${row['unidade_medida']})',
      }).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter alertas: $e');
      return [];
    }
  }

  /// Limpa dados antigos
  Future<void> cleanOldData({int daysOld = 60}) async {
    try {
      final db = await _database.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final deleted = await db.delete(
        _tableName,
        where: 'created_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('✅ Dados antigos do mapa limpos: $deleted registros removidos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados antigos do mapa: $e');
    }
  }
}
