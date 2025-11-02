import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/organism_catalog.dart';
import '../repositories/organism_catalog_repository.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Serviço de integração do Catálogo de Organismos com dados de monitoramento
/// Atualiza o catálogo com informações reais coletadas no campo
class OrganismCatalogIntegrationService {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogRepository _catalogRepository = OrganismCatalogRepository();
  
  static const String _tableName = 'organism_monitoring_stats';

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      final db = await _database.database;
      
      // Tabela para estatísticas de monitoramento por organismo
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          organismo_id TEXT NOT NULL,
          organismo_nome TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          cultura_nome TEXT NOT NULL,
          total_ocorrencias INTEGER DEFAULT 0,
          total_pontos_monitorados INTEGER DEFAULT 0,
          media_infestacao REAL DEFAULT 0.0,
          max_infestacao REAL DEFAULT 0.0,
          min_infestacao REAL DEFAULT 0.0,
          nivel_mais_comum TEXT DEFAULT 'BAIXO',
          ultima_ocorrencia TEXT,
          primeira_ocorrencia TEXT,
          tendencia TEXT DEFAULT 'ESTAVEL',
          confiabilidade REAL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Índices para performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_monitoring_stats_organismo 
        ON $_tableName(organismo_id, cultura_id)
      ''');
      
      Logger.info('✅ OrganismCatalogIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar OrganismCatalogIntegrationService: $e');
      rethrow;
    }
  }

  /// Atualiza estatísticas do catálogo com dados de monitoramento
  Future<void> updateCatalogWithMonitoringData(List<Map<String, dynamic>> monitoringData) async {
    try {
      Logger.info('🔄 Atualizando catálogo com ${monitoringData.length} registros de monitoramento');
      
      // Agrupar dados por organismo e cultura
      final groupedData = <String, List<Map<String, dynamic>>>{};
      
      for (final data in monitoringData) {
        final key = '${data['organismo_id']}_${data['cultura']}';
        groupedData.putIfAbsent(key, () => []).add(data);
      }
      
      // Processar cada grupo
      for (final entry in groupedData.entries) {
        await _processOrganismGroup(entry.key, entry.value);
      }
      
      Logger.info('✅ Catálogo atualizado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar catálogo: $e');
      rethrow;
    }
  }

  /// Processa um grupo de dados de um organismo específico
  Future<void> _processOrganismGroup(String key, List<Map<String, dynamic>> data) async {
    try {
      if (data.isEmpty) return;
      
      final firstData = data.first;
      final organismoId = firstData['organismo_id'] as String;
      final organismoNome = firstData['organismo_nome'] as String;
      final culturaId = firstData['cultura_id'] as String;
      final culturaNome = firstData['cultura'] as String;
      
      // Calcular estatísticas
      final stats = _calculateOrganismStatistics(data);
      
      // Salvar/atualizar estatísticas
      await _saveOrganismStatistics(
        organismoId: organismoId,
        organismoNome: organismoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        stats: stats,
      );
      
      // Atualizar catálogo principal se necessário
      await _updateMainCatalogIfNeeded(organismoId, stats);
      
    } catch (e) {
      Logger.error('❌ Erro ao processar grupo de organismo: $e');
    }
  }

  /// Calcula estatísticas para um organismo
  Map<String, dynamic> _calculateOrganismStatistics(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {
        'total_ocorrencias': 0,
        'total_pontos_monitorados': 0,
        'media_infestacao': 0.0,
        'max_infestacao': 0.0,
        'min_infestacao': 0.0,
        'nivel_mais_comum': 'BAIXO',
        'tendencia': 'ESTAVEL',
        'confiabilidade': 0.0,
      };
    }
    
    // Extrair quantidades de infestação
    final quantidades = data.map((d) => (d['quantidade_detectada'] as num).toDouble()).toList();
    final niveis = data.map((d) => d['nivel_intensidade'] as String).toList();
    final datas = data.map((d) => DateTime.parse(d['data_monitoramento'] as String)).toList();
    
    // Calcular estatísticas básicas
    final totalOcorrencias = data.length;
    final totalPontos = data.map((d) => d['monitoring_point_id']).toSet().length;
    final mediaInfestacao = quantidades.reduce((a, b) => a + b) / quantidades.length;
    final maxInfestacao = quantidades.reduce((a, b) => a > b ? a : b);
    final minInfestacao = quantidades.reduce((a, b) => a < b ? a : b);
    
    // Determinar nível mais comum
    final nivelCounts = <String, int>{};
    for (final nivel in niveis) {
      nivelCounts[nivel] = (nivelCounts[nivel] ?? 0) + 1;
    }
    final nivelMaisComum = nivelCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Calcular tendência
    final tendencia = _calculateTrend(quantidades, datas);
    
    // Calcular confiabilidade (baseada na consistência dos dados)
    final confiabilidade = _calculateReliability(quantidades, niveis);
    
    return {
      'total_ocorrencias': totalOcorrencias,
      'total_pontos_monitorados': totalPontos,
      'media_infestacao': mediaInfestacao,
      'max_infestacao': maxInfestacao,
      'min_infestacao': minInfestacao,
      'nivel_mais_comum': nivelMaisComum,
      'tendencia': tendencia,
      'confiabilidade': confiabilidade,
      'ultima_ocorrencia': datas.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
      'primeira_ocorrencia': datas.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }

  /// Calcula tendência dos dados
  String _calculateTrend(List<double> quantidades, List<DateTime> datas) {
    if (quantidades.length < 2) return 'ESTAVEL';
    
    // Ordenar por data
    final sortedData = List.generate(quantidades.length, (i) => {
      'quantidade': quantidades[i],
      'data': datas[i],
    });
    sortedData.sort((a, b) => (a['data'] as DateTime).compareTo(b['data'] as DateTime));
    
    // Calcular tendência simples
    final firstHalf = sortedData.take(sortedData.length ~/ 2).map((d) => d['quantidade'] as double).toList();
    final secondHalf = sortedData.skip(sortedData.length ~/ 2).map((d) => d['quantidade'] as double).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final diff = secondAvg - firstAvg;
    final percentDiff = (diff / firstAvg) * 100;
    
    if (percentDiff > 20) return 'CRESCENTE';
    if (percentDiff < -20) return 'DECRESCENTE';
    return 'ESTAVEL';
  }

  /// Calcula confiabilidade dos dados
  double _calculateReliability(List<double> quantidades, List<String> niveis) {
    if (quantidades.isEmpty) return 0.0;
    
    // Fator 1: Consistência dos níveis (quanto mais consistente, maior a confiabilidade)
    final nivelCounts = <String, int>{};
    for (final nivel in niveis) {
      nivelCounts[nivel] = (nivelCounts[nivel] ?? 0) + 1;
    }
    final maxNivelCount = nivelCounts.values.reduce((a, b) => a > b ? a : b);
    final nivelConsistency = maxNivelCount / niveis.length;
    
    // Fator 2: Variabilidade das quantidades (menor variabilidade = maior confiabilidade)
    final media = quantidades.reduce((a, b) => a + b) / quantidades.length;
    final variancia = quantidades.map((q) => (q - media) * (q - media)).reduce((a, b) => a + b) / quantidades.length;
    final desvioPadrao = sqrt(variancia);
    final coeficienteVariacao = desvioPadrao / media;
    final variabilidade = 1.0 - (coeficienteVariacao / 2.0).clamp(0.0, 1.0);
    
    // Fator 3: Quantidade de dados (mais dados = maior confiabilidade)
    final quantidadeDados = (quantidades.length / 10.0).clamp(0.0, 1.0);
    
    // Média ponderada dos fatores
    final confiabilidade = (nivelConsistency * 0.4 + variabilidade * 0.4 + quantidadeDados * 0.2);
    
    return confiabilidade.clamp(0.0, 1.0);
  }

  /// Salva estatísticas do organismo
  Future<void> _saveOrganismStatistics({
    required String organismoId,
    required String organismoNome,
    required String culturaId,
    required String culturaNome,
    required Map<String, dynamic> stats,
  }) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toIso8601String();
      
      await db.insert(
        _tableName,
        {
          'id': '${organismoId}_$culturaId',
          'organismo_id': organismoId,
          'organismo_nome': organismoNome,
          'cultura_id': culturaId,
          'cultura_nome': culturaNome,
          'total_ocorrencias': stats['total_ocorrencias'],
          'total_pontos_monitorados': stats['total_pontos_monitorados'],
          'media_infestacao': stats['media_infestacao'],
          'max_infestacao': stats['max_infestacao'],
          'min_infestacao': stats['min_infestacao'],
          'nivel_mais_comum': stats['nivel_mais_comum'],
          'ultima_ocorrencia': stats['ultima_ocorrencia'],
          'primeira_ocorrencia': stats['primeira_ocorrencia'],
          'tendencia': stats['tendencia'],
          'confiabilidade': stats['confiabilidade'],
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar estatísticas do organismo: $e');
    }
  }

  /// Atualiza catálogo principal se necessário
  Future<void> _updateMainCatalogIfNeeded(String organismoId, Map<String, dynamic> stats) async {
    try {
      // Buscar organismo no catálogo principal
      final organism = await _catalogRepository.getById(organismoId);
      if (organism == null) return;
      
      // Verificar se precisa atualizar limiares baseado nos dados reais
      final shouldUpdate = _shouldUpdateThresholds(organism, stats);
      
      if (shouldUpdate) {
        final newThresholds = _calculateNewThresholds(organism, stats);
        
        // Criar organismo atualizado
        final updatedOrganism = organism.copyWith(
          lowLimit: newThresholds['low_limit'],
          mediumLimit: newThresholds['medium_limit'],
          highLimit: newThresholds['high_limit'],
          updatedAt: DateTime.now(),
        );
        
        // Salvar no catálogo
        await _catalogRepository.update(updatedOrganism);
        
        Logger.info('✅ Catálogo atualizado para organismo: $organismoId');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao atualizar catálogo principal: $e');
    }
  }

  /// Verifica se deve atualizar limiares
  bool _shouldUpdateThresholds(OrganismCatalog organism, Map<String, dynamic> stats) {
    // Atualizar se:
    // 1. Confiabilidade dos dados é alta (> 0.7)
    // 2. Há dados suficientes (> 10 ocorrências)
    // 3. A média real difere significativamente dos limiares atuais
    
    final confiabilidade = stats['confiabilidade'] as double;
    final totalOcorrencias = stats['total_ocorrencias'] as int;
    final mediaInfestacao = stats['media_infestacao'] as double;
    
    if (confiabilidade < 0.7 || totalOcorrencias < 10) return false;
    
    // Verificar se a média difere significativamente dos limiares atuais
    final diffFromLow = (mediaInfestacao - organism.lowLimit).abs() / organism.lowLimit;
    final diffFromMedium = (mediaInfestacao - organism.mediumLimit).abs() / organism.mediumLimit;
    
    return diffFromLow > 0.3 || diffFromMedium > 0.3;
  }

  /// Calcula novos limiares baseado nos dados reais
  Map<String, int> _calculateNewThresholds(OrganismCatalog organism, Map<String, dynamic> stats) {
    final mediaInfestacao = stats['media_infestacao'] as double;
    final maxInfestacao = stats['max_infestacao'] as double;
    final minInfestacao = stats['min_infestacao'] as double;
    
    // Calcular novos limiares baseados na distribuição real dos dados
    final lowLimit = (minInfestacao + mediaInfestacao * 0.3).round();
    final mediumLimit = (mediaInfestacao * 0.7).round();
    final highLimit = (mediaInfestacao * 1.2).round();
    
    return {
      'low_limit': lowLimit.clamp(1, 100),
      'medium_limit': mediumLimit.clamp(lowLimit + 1, 100),
      'high_limit': highLimit.clamp(mediumLimit + 1, 100),
    };
  }

  /// Obtém estatísticas de um organismo específico
  Future<Map<String, dynamic>?> getOrganismStatistics(String organismoId, String culturaId) async {
    try {
      final db = await _database.database;
      
      final results = await db.query(
        _tableName,
        where: 'organismo_id = ? AND cultura_id = ?',
        whereArgs: [organismoId, culturaId],
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      
      return results.first;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do organismo: $e');
      return null;
    }
  }

  /// Obtém todos os organismos com estatísticas
  Future<List<Map<String, dynamic>>> getAllOrganismsWithStatistics() async {
    try {
      final db = await _database.database;
      
      final results = await db.query(
        _tableName,
        orderBy: 'total_ocorrencias DESC, confiabilidade DESC',
      );
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos com estatísticas: $e');
      return [];
    }
  }

  /// Obtém organismos mais problemáticos
  Future<List<Map<String, dynamic>>> getMostProblematicOrganisms({int limit = 10}) async {
    try {
      final db = await _database.database;
      
      final results = await db.rawQuery('''
        SELECT 
          organismo_id,
          organismo_nome,
          cultura_nome,
          total_ocorrencias,
          media_infestacao,
          nivel_mais_comum,
          tendencia,
          confiabilidade
        FROM $_tableName 
        WHERE nivel_mais_comum IN ('ALTO', 'CRITICO')
        ORDER BY 
          CASE nivel_mais_comum 
            WHEN 'CRITICO' THEN 4
            WHEN 'ALTO' THEN 3
            WHEN 'MODERADO' THEN 2
            ELSE 1
          END DESC,
          media_infestacao DESC,
          total_ocorrencias DESC
        LIMIT ?
      ''', [limit]);
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos mais problemáticos: $e');
      return [];
    }
  }

  /// Obtém tendências por cultura
  Future<Map<String, dynamic>> getTrendsByCrop() async {
    try {
      final db = await _database.database;
      
      final results = await db.rawQuery('''
        SELECT 
          cultura_nome,
          COUNT(*) as total_organismos,
          AVG(media_infestacao) as media_geral_infestacao,
          COUNT(CASE WHEN tendencia = 'CRESCENTE' THEN 1 END) as tendencia_crescente,
          COUNT(CASE WHEN tendencia = 'DECRESCENTE' THEN 1 END) as tendencia_decrescente,
          COUNT(CASE WHEN tendencia = 'ESTAVEL' THEN 1 END) as tendencia_estavel,
          COUNT(CASE WHEN nivel_mais_comum IN ('ALTO', 'CRITICO') THEN 1 END) as organismos_problematicos
        FROM $_tableName 
        GROUP BY cultura_nome
        ORDER BY media_geral_infestacao DESC
      ''');
      
      return {
        'tendencias_por_cultura': results,
        'total_culturas': results.length,
        'data_atualizacao': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter tendências por cultura: $e');
      return {'erro': e.toString()};
    }
  }

  /// Limpa dados antigos
  Future<void> cleanOldData({int daysOld = 90}) async {
    try {
      final db = await _database.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final deleted = await db.delete(
        _tableName,
        where: 'updated_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('✅ Dados antigos limpos: $deleted registros removidos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados antigos: $e');
    }
  }
}
