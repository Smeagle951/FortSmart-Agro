import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/planting_quality_report_model.dart';
import '../../utils/logger.dart';

/// Repositório para operações com histórico de relatórios de qualidade de plantio
class PlantingQualityReportRepository {
  static const String _tableName = 'planting_quality_reports';
  final AppDatabase _appDatabase = AppDatabase();

  /// Cria a tabela se não existir
  Future<void> createTableIfNotExists() async {
    try {
      final db = await _appDatabase.database;
      
      // Verifica se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );
      
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            talhao_nome TEXT NOT NULL,
            cultura_id TEXT NOT NULL,
            cultura_nome TEXT NOT NULL,
            variedade TEXT,
            safra TEXT,
            area_hectares REAL NOT NULL,
            data_plantio TEXT NOT NULL,
            data_avaliacao TEXT NOT NULL,
            executor TEXT NOT NULL,
            coeficiente_variacao REAL NOT NULL,
            classificacao_cv TEXT NOT NULL,
            plantas_por_metro REAL NOT NULL,
            populacao_estimada_hectare REAL NOT NULL,
            singulacao REAL NOT NULL,
            plantas_duplas REAL NOT NULL,
            plantas_falhadas REAL NOT NULL,
            populacao_alvo REAL NOT NULL,
            populacao_real REAL NOT NULL,
            eficacia_emergencia REAL NOT NULL,
            desvio_populacao REAL NOT NULL,
            analise_automatica TEXT NOT NULL,
            sugestoes TEXT NOT NULL,
            status_geral TEXT NOT NULL,
            app_version TEXT DEFAULT '1.0.0',
            device_info TEXT,
            mapa_poligono TEXT,
            latitude_coleta REAL,
            longitude_coleta REAL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            sync_status INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            FOREIGN KEY (talhao_id) REFERENCES talhoes(id) ON DELETE CASCADE
          )
        ''');
        
        // Criar índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_talhao_id ON $_tableName (talhao_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_cultura_id ON $_tableName (cultura_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_data_avaliacao ON $_tableName (data_avaliacao)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_created_at ON $_tableName (created_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_sync_status ON $_tableName (sync_status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_quality_reports_is_favorite ON $_tableName (is_favorite)');
        
        Logger.info('✅ Tabela $_tableName criada com sucesso!');
      }
    } catch (e) {
      Logger.error('❌ Erro ao criar tabela $_tableName: $e');
      rethrow;
    }
  }

  /// Salva um relatório no histórico
  Future<String> salvarRelatorio(PlantingQualityReportModel relatorio) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      // Atualiza a data de modificação
      final relatorioAtualizado = relatorio.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Verifica se o relatório já existe
      final existingRecord = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [relatorioAtualizado.id],
      );
      
      if (existingRecord.isNotEmpty) {
        // Atualiza o relatório existente
        await db.update(
          _tableName,
          relatorioAtualizado.toMap(),
          where: 'id = ?',
          whereArgs: [relatorioAtualizado.id],
        );
        Logger.info('✅ Relatório atualizado: ${relatorioAtualizado.id}');
      } else {
        // Insere um novo relatório
        await db.insert(
          _tableName,
          relatorioAtualizado.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        Logger.info('✅ Relatório inserido: ${relatorioAtualizado.id}');
      }
      
      return relatorioAtualizado.id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar relatório: $e');
      rethrow;
    }
  }

  /// Busca todos os relatórios
  Future<List<PlantingQualityReportModel>> buscarTodosRelatorios() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios: $e');
      return [];
    }
  }

  /// Busca relatórios por talhão
  Future<List<PlantingQualityReportModel>> buscarRelatoriosPorTalhao(String talhaoId) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios por talhão: $e');
      return [];
    }
  }

  /// Busca relatórios por cultura
  Future<List<PlantingQualityReportModel>> buscarRelatoriosPorCultura(String culturaId) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios por cultura: $e');
      return [];
    }
  }

  /// Busca relatórios favoritos
  Future<List<PlantingQualityReportModel>> buscarRelatoriosFavoritos() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios favoritos: $e');
      return [];
    }
  }

  /// Busca relatórios por período
  Future<List<PlantingQualityReportModel>> buscarRelatoriosPorPeriodo(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'data_avaliacao BETWEEN ? AND ?',
        whereArgs: [
          dataInicio.toIso8601String(),
          dataFim.toIso8601String(),
        ],
        orderBy: 'data_avaliacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios por período: $e');
      return [];
    }
  }

  /// Busca relatório por ID
  Future<PlantingQualityReportModel?> buscarRelatorioPorId(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return PlantingQualityReportModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatório por ID: $e');
      return null;
    }
  }

  /// Marca/desmarca relatório como favorito
  Future<bool> toggleFavorito(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      // Buscar status atual
      final result = await db.query(
        _tableName,
        columns: ['is_favorite'],
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) return false;
      
      final isFavorite = result.first['is_favorite'] as int;
      final newStatus = isFavorite == 1 ? 0 : 1;
      
      // Atualizar status
      final updateResult = await db.update(
        _tableName,
        {
          'is_favorite': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return updateResult > 0;
    } catch (e) {
      Logger.error('❌ Erro ao toggle favorito: $e');
      return false;
    }
  }

  /// Exclui um relatório
  Future<bool> excluirRelatorio(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        Logger.info('✅ Relatório excluído: $id');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao excluir relatório: $e');
      return false;
    }
  }

  /// Obtém estatísticas dos relatórios
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $_tableName');
      final total = totalResult.first['total'] as int;
      
      final favoritosResult = await db.rawQuery('SELECT COUNT(*) as favoritos FROM $_tableName WHERE is_favorite = 1');
      final favoritos = favoritosResult.first['favoritos'] as int;
      
      final ultimoMesResult = await db.rawQuery(
        'SELECT COUNT(*) as ultimo_mes FROM $_tableName WHERE created_at >= ?',
        [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()]
      );
      final ultimoMes = ultimoMesResult.first['ultimo_mes'] as int;
      
      // Estatísticas por status
      final altaQualidadeResult = await db.rawQuery(
        'SELECT COUNT(*) as alta_qualidade FROM $_tableName WHERE status_geral = ?',
        ['Alta qualidade']
      );
      final altaQualidade = altaQualidadeResult.first['alta_qualidade'] as int;
      
      final boaQualidadeResult = await db.rawQuery(
        'SELECT COUNT(*) as boa_qualidade FROM $_tableName WHERE status_geral = ?',
        ['Boa qualidade']
      );
      final boaQualidade = boaQualidadeResult.first['boa_qualidade'] as int;
      
      final regularResult = await db.rawQuery(
        'SELECT COUNT(*) as regular FROM $_tableName WHERE status_geral = ?',
        ['Regular']
      );
      final regular = regularResult.first['regular'] as int;
      
      final atencaoResult = await db.rawQuery(
        'SELECT COUNT(*) as atencao FROM $_tableName WHERE status_geral = ?',
        ['Atenção']
      );
      final atencao = atencaoResult.first['atencao'] as int;
      
      return {
        'total': total,
        'favoritos': favoritos,
        'ultimo_mes': ultimoMes,
        'alta_qualidade': altaQualidade,
        'boa_qualidade': boaQualidade,
        'regular': regular,
        'atencao': atencao,
        'percentual_alta_qualidade': total > 0 ? (altaQualidade / total * 100) : 0.0,
        'percentual_boa_qualidade': total > 0 ? (boaQualidade / total * 100) : 0.0,
        'percentual_regular': total > 0 ? (regular / total * 100) : 0.0,
        'percentual_atencao': total > 0 ? (atencao / total * 100) : 0.0,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'favoritos': 0,
        'ultimo_mes': 0,
        'alta_qualidade': 0,
        'boa_qualidade': 0,
        'regular': 0,
        'atencao': 0,
        'percentual_alta_qualidade': 0.0,
        'percentual_boa_qualidade': 0.0,
        'percentual_regular': 0.0,
        'percentual_atencao': 0.0,
      };
    }
  }

  /// Busca relatórios com filtros
  Future<List<PlantingQualityReportModel>> buscarRelatoriosComFiltros({
    String? talhaoId,
    String? culturaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? statusGeral,
    bool? apenasFavoritos,
    int? limite,
  }) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      // Construir cláusula WHERE dinamicamente
      if (talhaoId != null) {
        whereClause += 'talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (culturaId != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'cultura_id = ?';
        whereArgs.add(culturaId);
      }
      
      if (dataInicio != null && dataFim != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'data_avaliacao BETWEEN ? AND ?';
        whereArgs.addAll([dataInicio.toIso8601String(), dataFim.toIso8601String()]);
      }
      
      if (statusGeral != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'status_geral = ?';
        whereArgs.add(statusGeral);
      }
      
      if (apenasFavoritos == true) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'is_favorite = 1';
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limite,
      );
      
      return List.generate(maps.length, (i) {
        return PlantingQualityReportModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar relatórios com filtros: $e');
      return [];
    }
  }
}
