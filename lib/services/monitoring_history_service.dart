import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar o histórico de monitoramento
/// Mantém os dados por 7 dias e fornece funcionalidades de consulta
class MonitoringHistoryService {
  static final MonitoringHistoryService _instance = MonitoringHistoryService._internal();
  factory MonitoringHistoryService() => _instance;
  MonitoringHistoryService._internal();

  final AppDatabase _database = AppDatabase();
  static const String _tableName = 'monitoring_history';
  
  /// Expõe o database para uso em queries customizadas
  Future<Database> get database async => await _database.database;

  /// Inicializa a tabela de histórico
  Future<void> initialize() async {
    try {
      final db = await _database.database;
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          plot_id TEXT NOT NULL,
          plot_name TEXT NOT NULL,
          crop_id TEXT NOT NULL,
          crop_name TEXT NOT NULL,
          date TEXT NOT NULL,
          points_data TEXT NOT NULL,
          occurrences_data TEXT,
          severity REAL DEFAULT 0,
          technician_name TEXT,
          observations TEXT,
          created_at TEXT NOT NULL,
          expires_at TEXT NOT NULL
        )
      ''');
      
      Logger.info('✅ Tabela de histórico de monitoramento inicializada');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabela de histórico: $e');
    }
  }

  /// Salva um monitoramento no histórico
  Future<bool> saveToHistory(Monitoring monitoring) async {
    try {
      Logger.info('🔄 Salvando monitoramento no histórico: ${monitoring.id}');
      
      await initialize();
      final db = await _database.database;
      
      // Calcular data de expiração (7 dias)
      final expiresAt = DateTime.now().add(const Duration(days: 7));
      
      Logger.info('📊 Preparando dados dos pontos...');
      // Preparar dados dos pontos
      final pointsData = jsonEncode(monitoring.points.map((point) => {
        'id': point.id,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'occurrences': point.occurrences.map((occ) => {
          'name': occ.name,
          'type': occ.type.toString(),
          'infestationIndex': occ.infestationIndex,
          'notes': occ.notes,
        }).toList(),
        'observations': point.observations,
        'createdAt': point.createdAt.toIso8601String(),
      }).toList());
      
      Logger.info('📊 Preparando dados das ocorrências...');
      // Preparar dados das ocorrências
      final allOccurrences = <Map<String, dynamic>>[];
      for (final point in monitoring.points) {
        for (final occurrence in point.occurrences) {
          allOccurrences.add({
            'name': occurrence.name,
            'type': occurrence.type.toString(),
            'infestationIndex': occurrence.infestationIndex,
            'notes': occurrence.notes,
            'pointId': point.id,
            'pointLatitude': point.latitude,
            'pointLongitude': point.longitude,
          });
        }
      }
      final occurrencesData = jsonEncode(allOccurrences);
      
      // Calcular severidade média
      final severity = _calculateAverageSeverity(monitoring.points);
      
      Logger.info('💾 Inserindo no histórico...');
      // Inserir no histórico
      await db.insert(_tableName, {
        'id': '${monitoring.id}_history',
        'monitoring_id': monitoring.id,
        'plot_id': monitoring.plotId.toString(),
        'plot_name': monitoring.plotName,
        'crop_id': monitoring.cropId.toString(),
        'crop_name': monitoring.cropName,
        'date': monitoring.date.toIso8601String(),
        'points_data': pointsData,
        'occurrences_data': occurrencesData,
        'severity': severity,
        'technician_name': monitoring.technicianName,
        'observations': monitoring.observations,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });
      
      Logger.info('✅ Monitoramento salvo no histórico: ${monitoring.id}');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao salvar no histórico: $e');
      return false;
    }
  }

  /// Obtém o histórico de monitoramento dos últimos 7 dias
  Future<List<Map<String, dynamic>>> getRecentHistory({int limit = 50}) async {
    try {
      await initialize();
      final db = await _database.database;
      
      final now = DateTime.now();
      
      // Buscar da tabela principal
      final results = await db.query(
        _tableName,
        where: 'expires_at > ?',
        whereArgs: [now.toIso8601String()],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      // Buscar também da tabela de ocorrências (estrutura unificada)
      final occurrencesResults = await db.query(
        'monitoring_occurrences',
        where: 'created_at > ?',
        whereArgs: [now.subtract(const Duration(days: 7)).toIso8601String()],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      // Buscar também da tabela infestacoes_monitoramento
      final infestacaoResults = await db.query(
        'infestacoes_monitoramento',
        where: 'data_hora > ?',
        whereArgs: [now.subtract(const Duration(days: 7)).toIso8601String()],
        orderBy: 'data_hora DESC',
        limit: limit,
      );
      
      // Combinar resultados
      final allResults = <Map<String, dynamic>>[];
      
      // Adicionar resultados da tabela principal
      for (final row in results) {
        allResults.add({
          'id': row['id'],
          'monitoring_id': row['monitoring_id'],
          'plot_name': row['plot_name'],
          'crop_name': row['crop_name'],
          'date': DateTime.parse(row['date'] as String),
          'severity': (row['severity'] as num?)?.toDouble() ?? 0.0,
          'technician_name': row['technician_name'],
          'observations': row['observations'],
          'points_count': _getPointsCount(row['points_data'] as String),
          'occurrences_count': _getOccurrencesCount(row['occurrences_data'] as String),
          'created_at': DateTime.parse(row['created_at'] as String),
        });
      }
      
      // Adicionar resultados da tabela de ocorrências (estrutura unificada)
      for (final row in occurrencesResults) {
        try {
          allResults.add({
            'id': row['id'],
            'monitoring_id': row['session_id'] ?? row['id'],
            'plot_name': 'Talhão ${row['talhao_id']}',
            'crop_name': 'Cultura',
            'date': DateTime.parse(row['data_hora'] as String),
            'severity': (row['percentual'] as num?)?.toDouble() ?? 0.0,
            'technician_name': 'Técnico',
            'observations': row['observacao'] ?? '',
            'points_count': 1,
            'occurrences_count': 1,
            'created_at': DateTime.parse(row['created_at'] as String),
          });
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar ocorrência ${row['id']}: $e');
        }
      }
      
      // Adicionar resultados da tabela infestacoes_monitoramento
      for (final row in infestacaoResults) {
        try {
          allResults.add({
            'id': row['id'],
            'monitoring_id': row['id'], // Usar o próprio ID como monitoring_id
            'plot_name': 'Talhão ${row['talhao_id']}',
            'crop_name': 'Cultura',
            'date': DateTime.parse(row['data_hora'] as String),
            'severity': (row['percentual'] as num?)?.toDouble() ?? 0.0,
            'technician_name': 'Técnico',
            'observations': row['observacao'] ?? '',
            'points_count': 1,
            'occurrences_count': 1,
            'created_at': DateTime.parse(row['data_hora'] as String), // Usar data_hora como created_at
          });
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar infestação ${row['id']}: $e');
        }
      }
      
      // Ordenar por data de criação e limitar
      allResults.sort((a, b) => (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));
      return allResults.take(limit).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter histórico: $e');
      return [];
    }
  }

  /// Obtém detalhes de um monitoramento específico do histórico
  Future<Map<String, dynamic>?> getHistoryDetails(String historyId) async {
    try {
      await initialize();
      final db = await _database.database;
      
      Logger.info('🔍 Buscando detalhes do histórico: $historyId');
      
      // Primeiro, tentar buscar na tabela principal
      var results = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [historyId],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        Logger.info('✅ Encontrado na tabela principal');
        final row = results.first;
        final pointsData = jsonDecode(row['points_data'] as String) as List;
        final occurrencesData = jsonDecode(row['occurrences_data'] as String) as List;
        
        return {
          'id': row['id'],
          'monitoring_id': row['monitoring_id'],
          'plot_name': row['plot_name'],
          'crop_name': row['crop_name'],
          'date': DateTime.parse(row['date'] as String),
          'severity': row['severity'] as double,
          'technician_name': row['technician_name'],
          'observations': row['observations'],
          'points': pointsData,
          'occurrences': occurrencesData,
          'created_at': DateTime.parse(row['created_at'] as String),
        };
      }
      
      // Se não encontrou na tabela principal, buscar na tabela de ocorrências
      Logger.info('🔍 Buscando na tabela de ocorrências...');
      results = await db.query(
        'monitoring_occurrences',
        where: 'id = ?',
        whereArgs: [historyId],
        limit: 1,
      );
      
      // Se não encontrou na tabela monitoring_occurrences, buscar na tabela infestacoes_monitoramento
      if (results.isEmpty) {
        Logger.info('🔍 Buscando na tabela infestacoes_monitoramento...');
        results = await db.query(
          'infestacoes_monitoramento',
          where: 'id = ?',
          whereArgs: [historyId],
          limit: 1,
        );
      }
      
      if (results.isNotEmpty) {
        Logger.info('✅ Encontrado na tabela de ocorrências');
        final row = results.first;
        
        // Verificar se subtipo está vazio e tentar buscar do catálogo de organismos
        String subtipo = row['subtipo'] as String? ?? '';
        if (subtipo.isEmpty) {
          // Tentar buscar o nome do organismo pelo organism_id se disponível
          try {
            final organismResult = await db.query(
              'organism_catalog',
              where: 'id = ?',
              whereArgs: [row['organism_id']],
              limit: 1,
            );
            if (organismResult.isNotEmpty) {
              subtipo = organismResult.first['nome'] as String? ?? 'Organismo não identificado';
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao buscar organismo no catálogo: $e');
          }
        }
        
        // Tentar buscar o nome do organismo de diferentes campos
        if (subtipo.isEmpty && row['organismo'] != null) {
          subtipo = row['organismo'] as String;
        }
        if (subtipo.isEmpty && row['organism_name'] != null) {
          subtipo = row['organism_name'] as String;
        }
        if (subtipo.isEmpty && row['name'] != null) {
          subtipo = row['name'] as String;
        }
        if (subtipo.isEmpty) {
          subtipo = 'Infestação não identificada';
        }
        
        // Verificar se é da tabela infestacoes_monitoramento ou monitoring_occurrences
        final isInfestacaoTable = row.containsKey('talhao_id') && !row.containsKey('session_id');
        
        // Criar ocorrência única (sem duplicação)
        final occurrence = {
          'name': subtipo,
          'subtipo': subtipo,
          'type': row['tipo'],
          'tipo': row['tipo'],
          'infestationIndex': (row['percentual'] as int).toDouble(),
          'percentual': row['percentual'],
          'notes': row['observacao'] ?? '',
          'observacao': row['observacao'] ?? '',
          'pointId': isInfestacaoTable ? row['ponto_id'] : row['ponto_id'],
          'pointLatitude': row['latitude'],
          'pointLongitude': row['longitude'],
        };

        return {
          'id': row['id'],
          'monitoring_id': isInfestacaoTable ? row['id'] : (row['session_id'] ?? row['id']),
          'plot_name': 'Talhão ${row['talhao_id']}',
          'crop_name': 'Cultura',
          'date': DateTime.parse(row['data_hora'] as String),
          'severity': (row['percentual'] as int).toDouble(),
          'technician_name': 'Técnico',
          'observations': row['observacao'] ?? '',
          'points': [{
            'id': isInfestacaoTable ? row['ponto_id'] : row['ponto_id'],
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'occurrences': [occurrence], // Usar a mesma referência
            'observations': row['observacao'] ?? '',
            'createdAt': row['data_hora'],
          }],
          'occurrences': [occurrence], // Usar a mesma referência (sem duplicação)
          'created_at': DateTime.parse(isInfestacaoTable ? row['data_hora'] as String : row['created_at'] as String),
        };
      }
      
      Logger.warning('⚠️ Histórico não encontrado: $historyId');
      return null;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter detalhes do histórico: $e');
      return null;
    }
  }

  /// Obtém histórico por talhão
  Future<List<Map<String, dynamic>>> getHistoryByPlot(String plotId, {int limit = 20}) async {
    try {
      await initialize();
      final db = await _database.database;
      
      final now = DateTime.now();
      final results = await db.query(
        _tableName,
        where: 'plot_id = ? AND expires_at > ?',
        whereArgs: [plotId, now.toIso8601String()],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      return results.map((row) => {
        'id': row['id'],
        'monitoring_id': row['monitoring_id'],
        'plot_name': row['plot_name'],
        'crop_name': row['crop_name'],
        'date': DateTime.parse(row['date'] as String),
        'severity': row['severity'] as double,
        'technician_name': row['technician_name'],
        'observations': row['observations'],
        'points_count': _getPointsCount(row['points_data'] as String),
        'occurrences_count': _getOccurrencesCount(row['occurrences_data'] as String),
        'created_at': DateTime.parse(row['created_at'] as String),
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter histórico por talhão: $e');
      return [];
    }
  }

  /// Limpa registros expirados (mais de 7 dias)
  Future<int> cleanupExpiredRecords() async {
    try {
      await initialize();
      final db = await _database.database;
      
      final now = DateTime.now();
      final deleted = await db.delete(
        _tableName,
        where: 'expires_at <= ?',
        whereArgs: [now.toIso8601String()],
      );
      
      if (deleted > 0) {
        Logger.info('🧹 Removidos $deleted registros expirados do histórico');
      }
      
      return deleted;
    } catch (e) {
      Logger.error('❌ Erro ao limpar registros expirados: $e');
      return 0;
    }
  }

  /// Obtém estatísticas do histórico
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      await initialize();
      final db = await _database.database;
      
      final now = DateTime.now();
      
      // Total de registros ativos
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM $_tableName WHERE expires_at > ?',
        [now.toIso8601String()],
      );
      final total = totalResult.first['total'] as int;
      
      // Registros por talhão
      final plotStats = await db.rawQuery('''
        SELECT plot_name, COUNT(*) as count, AVG(severity) as avg_severity
        FROM $_tableName 
        WHERE expires_at > ?
        GROUP BY plot_name
        ORDER BY count DESC
      ''', [now.toIso8601String()]);
      
      // Registros por cultura
      final cropStats = await db.rawQuery('''
        SELECT crop_name, COUNT(*) as count, AVG(severity) as avg_severity
        FROM $_tableName 
        WHERE expires_at > ?
        GROUP BY crop_name
        ORDER BY count DESC
      ''', [now.toIso8601String()]);
      
      return {
        'total_records': total,
        'plot_stats': plotStats,
        'crop_stats': cropStats,
        'last_cleanup': DateTime.now(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do histórico: $e');
      return {};
    }
  }

  /// Calcula severidade média dos pontos
  double _calculateAverageSeverity(List<MonitoringPoint> points) {
    if (points.isEmpty) return 0.0;
    
    double totalSeverity = 0.0;
    int pointCount = 0;
    
    for (final point in points) {
      if (point.occurrences.isNotEmpty) {
        double pointSeverity = 0.0;
        for (final occurrence in point.occurrences) {
          pointSeverity += occurrence.infestationIndex.toDouble();
        }
        totalSeverity += pointSeverity / point.occurrences.length;
        pointCount++;
      }
    }
    
    return pointCount > 0 ? totalSeverity / pointCount : 0.0;
  }

  /// Obtém o número de pontos de um registro
  int _getPointsCount(String pointsData) {
    try {
      final points = jsonDecode(pointsData) as List;
      return points.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtém o número de ocorrências de um registro
  int _getOccurrencesCount(String occurrencesData) {
    try {
      final occurrences = jsonDecode(occurrencesData) as List;
      return occurrences.length;
    } catch (e) {
      return 0;
    }
  }

  /// Deleta um histórico de monitoramento específico
  Future<bool> deleteHistory(String historyId) async {
    try {
      Logger.info('🗑️ Deletando histórico de monitoramento: $historyId');
      
      final db = await AppDatabase.instance.database;
      
      // Verificar se o histórico existe primeiro
      final infestacaoExists = await db.query(
        'infestacoes_monitoramento',
        where: 'id = ?',
        whereArgs: [historyId],
        limit: 1,
      );
      
      final monitoringExists = await db.query(
        'monitorings',
        where: 'id = ?',
        whereArgs: [historyId],
        limit: 1,
      );
      
      if (infestacaoExists.isEmpty && monitoringExists.isEmpty) {
        Logger.warning('⚠️ Histórico não encontrado em nenhuma tabela: $historyId');
        return false;
      }
      
      Logger.info('📊 Histórico encontrado - Infestação: ${infestacaoExists.isNotEmpty}, Monitoramento: ${monitoringExists.isNotEmpty}');
      
      int totalDeleted = 0;
      
      // Deletar dados relacionados primeiro (CASCADE)
      try {
        // Deletar fotos relacionadas
        final photosDeleted = await db.delete(
          'infestacao_fotos',
          where: 'infestacao_id = ?',
          whereArgs: [historyId],
        );
        Logger.info('📸 $photosDeleted fotos deletadas');
        
        // Deletar ocorrências relacionadas
        final occurrencesDeleted = await db.delete(
          'occurrences',
          where: 'pointId IN (SELECT id FROM monitoring_points WHERE monitoringId = ?)',
          whereArgs: [historyId],
        );
        Logger.info('🐛 $occurrencesDeleted ocorrências deletadas');
        
        // Deletar pontos relacionados
        final pointsDeleted = await db.delete(
          'monitoring_points',
          where: 'monitoringId = ?',
          whereArgs: [historyId],
        );
        Logger.info('📍 $pointsDeleted pontos deletados');
        
        // Deletar alertas relacionados
        final alertsDeleted = await db.delete(
          'monitoring_alerts',
          where: 'monitoring_id = ?',
          whereArgs: [historyId],
        );
        Logger.info('🔔 $alertsDeleted alertas deletados');
        
      } catch (e) {
        Logger.warning('⚠️ Erro ao deletar dados relacionados: $e');
        // Continuar mesmo com erro nos dados relacionados
      }
      
      // Deletar registros principais
      try {
        // Deletar de infestacoes_monitoramento
        final infestacaoDeleted = await db.delete(
          'infestacoes_monitoramento',
          where: 'id = ?',
          whereArgs: [historyId],
        );
        totalDeleted += infestacaoDeleted;
        Logger.info('🗑️ $infestacaoDeleted registros deletados de infestacoes_monitoramento');
        
        // Deletar de monitorings
        final monitoringDeleted = await db.delete(
          'monitorings',
          where: 'id = ?',
          whereArgs: [historyId],
        );
        totalDeleted += monitoringDeleted;
        Logger.info('🗑️ $monitoringDeleted registros deletados de monitorings');
        
      } catch (e) {
        Logger.error('❌ Erro ao deletar registros principais: $e');
        throw e; // Re-throw para ser capturado pelo catch principal
      }
      
      if (totalDeleted > 0) {
        Logger.info('✅ Histórico deletado com sucesso: $historyId ($totalDeleted registros principais)');
        return true;
      } else {
        Logger.warning('⚠️ Nenhum registro principal foi deletado: $historyId');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao deletar histórico: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Deleta históricos expirados (mais de X dias)
  Future<int> deleteExpiredHistories({int expirationDays = 15}) async {
    try {
      Logger.info('🗑️ Deletando históricos com mais de $expirationDays dias...');
      
      final db = await AppDatabase.instance.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: expirationDays));
      final cutoffDateStr = cutoffDate.toIso8601String();
      
      // Buscar IDs expirados de infestacoes_monitoramento
      final infestacaoIds = await db.query(
        'infestacoes_monitoramento',
        columns: ['id', 'data_hora'],
        where: 'data_hora < ?',
        whereArgs: [cutoffDateStr],
      );
      
      Logger.info('📊 ${infestacaoIds.length} registros expirados em infestacoes_monitoramento');
      
      // Buscar IDs expirados de monitorings
      final monitoringIds = await db.query(
        'monitorings',
        columns: ['id', 'created_at'],
        where: 'created_at < ?',
        whereArgs: [cutoffDateStr],
      );
      
      Logger.info('📊 ${monitoringIds.length} registros expirados em monitorings');
      
      int totalDeleted = 0;
      
      // Deletar infestações expiradas
      for (final row in infestacaoIds) {
        final id = row['id'] as String;
        final dataHora = row['data_hora'] as String;
        Logger.info('🗑️ Deletando registro de $dataHora (ID: $id)');
        
        final success = await deleteHistory(id);
        if (success) totalDeleted++;
      }
      
      // Deletar monitoramentos expirados
      for (final row in monitoringIds) {
        final id = row['id'] as String;
        final createdAt = row['created_at'] as String;
        Logger.info('🗑️ Deletando registro de $createdAt (ID: $id)');
        
        final success = await deleteHistory(id);
        if (success) totalDeleted++;
      }
      
      Logger.info('✅ $totalDeleted históricos expirados deletados');
      
      return totalDeleted;
    } catch (e) {
      Logger.error('❌ Erro ao deletar históricos expirados: $e');
      return 0;
    }
  }

  /// Deleta todos os históricos de um talhão específico
  Future<int> deleteHistoriesByPlotId(String plotId) async {
    try {
      Logger.info('🗑️ Deletando todos os históricos do talhão: $plotId');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar IDs dos históricos do talhão
      final infestacaoIds = await db.query(
        'infestacoes_monitoramento',
        columns: ['id'],
        where: 'talhao_id = ?',
        whereArgs: [int.tryParse(plotId) ?? 0],
      );
      
      int totalDeleted = 0;
      
      for (final row in infestacaoIds) {
        final id = row['id'] as String;
        final success = await deleteHistory(id);
        if (success) totalDeleted++;
      }
      
      // Buscar também na tabela monitorings
      final monitoringIds = await db.query(
        'monitorings',
        columns: ['id'],
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      
      for (final row in monitoringIds) {
        final id = row['id'] as String;
        final success = await deleteHistory(id);
        if (success) totalDeleted++;
      }
      
      Logger.info('✅ $totalDeleted históricos deletados do talhão $plotId');
      return totalDeleted;
    } catch (e) {
      Logger.error('❌ Erro ao deletar históricos do talhão: $e');
      return 0;
    }
  }
}
