import 'package:sqflite/sqflite.dart';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';

class InfestacaoRepository {
  final Database _database;

  InfestacaoRepository(this._database);

  Future<void> createTable() async {
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS infestacoes_monitoramento (
        id TEXT PRIMARY KEY,
        talhao_id INTEGER NOT NULL,
        ponto_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipo TEXT NOT NULL,
        subtipo TEXT NOT NULL,
        nivel TEXT NOT NULL,
        percentual INTEGER NOT NULL,
        foto_paths TEXT,
        observacao TEXT,
        data_hora TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        server_id TEXT,
        last_sync_error TEXT,
        attempts_sync INTEGER DEFAULT 0,
        organismo_id TEXT,
        quantidade_bruta INTEGER,
        total_plantas_avaliadas INTEGER,
        terco_planta TEXT,
        FOREIGN KEY (talhao_id) REFERENCES talhoes (id),
        FOREIGN KEY (ponto_id) REFERENCES pontos_monitoramento (id)
      )
    ''');

    await _database.execute('''
      CREATE TABLE IF NOT EXISTS infestacao_fotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        infestacao_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        remote_url TEXT,
        uploaded INTEGER DEFAULT 0,
        uploaded_at TEXT,
        FOREIGN KEY (infestacao_id) REFERENCES infestacoes_monitoramento (id)
      )
    ''');
  }

  Future<String> insert(InfestacaoModel infestacao) async {
    await _database.insert('infestacoes_monitoramento', infestacao.toMap());
    
    // Salvar fotos na tabela separada
    for (String path in infestacao.localPhotoPaths) {
      await _database.insert('infestacao_fotos', {
        'infestacao_id': infestacao.id,
        'local_path': path,
        'uploaded': 0,
      });
    }
    
    return infestacao.id;
  }

  Future<List<InfestacaoModel>> getByPontoId(int pontoId) async {
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'ponto_id = ?',
      whereArgs: [pontoId],
      orderBy: 'data_hora DESC',
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  Future<List<InfestacaoModel>> getAll() async {
    final maps = await _database.query(
      'infestacoes_monitoramento',
      orderBy: 'data_hora DESC',
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  Future<List<InfestacaoModel>> getByTalhaoId(int talhaoId) async {
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_hora DESC',
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }


  Future<List<InfestacaoModel>> getAlertasCriticos(int talhaoId, int culturaId, int windowDays) async {
    // Como a tabela talhoes não tem cultura_id, vamos buscar apenas por talhao_id
    // e filtrar por cultura se necessário através de outras tabelas
    final maps = await _database.rawQuery('''
      SELECT i.* FROM infestacoes_monitoramento i
      WHERE i.talhao_id = ? 
        AND i.nivel = 'Crítico' 
        AND date(i.data_hora) >= date('now', '-$windowDays days')
      ORDER BY i.data_hora DESC
      LIMIT 100
    ''', [talhaoId]);
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  Future<List<InfestacaoModel>> fetchUnsynced({int limit = 20}) async {
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'sincronizado = 0 AND attempts_sync < 5',
      orderBy: 'data_hora ASC',
      limit: limit,
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id, {String? serverId}) async {
    await _database.update(
      'infestacoes_monitoramento',
      {
        'sincronizado': 1,
        'server_id': serverId,
        'last_sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setSyncError(String id, String errorMessage) async {
    await _database.update(
      'infestacoes_monitoramento',
      {
        'last_sync_error': errorMessage,
        'attempts_sync': 'attempts_sync + 1',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    // Deletar fotos primeiro
    await _database.delete(
      'infestacao_fotos',
      where: 'infestacao_id = ?',
      whereArgs: [id],
    );
    
    // Deletar infestação
    await _database.delete(
      'infestacoes_monitoramento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<InfestacaoModel?> getById(String id) async {
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return InfestacaoModel.fromMap(maps.first);
  }

  Future<void> update(InfestacaoModel infestacao) async {
    await _database.update(
      'infestacoes_monitoramento',
      infestacao.toMap(),
      where: 'id = ?',
      whereArgs: [infestacao.id],
    );
  }

  /// Busca ocorrências críticas por talhão e cultura em um período específico
  Future<List<InfestacaoModel>> getCriticalOccurrencesByTalhaoAndCultura(
    int talhaoId,
    String culturaId,
    DateTime cutoffDate,
  ) async {
    // Como a tabela infestacoes_monitoramento não tem cultura_id, vamos buscar apenas por talhao_id
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'talhao_id = ? AND nivel = ? AND data_hora >= ?',
      whereArgs: [talhaoId, 'Crítico', cutoffDate.toIso8601String()],
      orderBy: 'data_hora DESC',
      limit: 100, // Limitar para performance
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  /// Busca ocorrências por talhão e cultura
  Future<List<InfestacaoModel>> getByTalhaoAndCultura(int talhaoId, int culturaId) async {
    // Como a tabela infestacoes_monitoramento não tem cultura_id, vamos buscar apenas por talhao_id
    final maps = await _database.query(
      'infestacoes_monitoramento',
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_hora DESC',
    );
    
    return maps.map((map) => InfestacaoModel.fromMap(map)).toList();
  }

  Future<List<String>> getPhotoPaths(String infestacaoId) async {
    final maps = await _database.query(
      'infestacao_fotos',
      columns: ['local_path'],
      where: 'infestacao_id = ?',
      whereArgs: [infestacaoId],
    );
    
    return maps.map((map) => map['local_path'] as String).toList();
  }

  Future<void> markPhotoAsUploaded(String infestacaoId, String localPath, String remoteUrl) async {
    await _database.update(
      'infestacao_fotos',
      {
        'remote_url': remoteUrl,
        'uploaded': 1,
        'uploaded_at': DateTime.now().toIso8601String(),
      },
      where: 'infestacao_id = ? AND local_path = ?',
      whereArgs: [infestacaoId, localPath],
    );
  }

  /// Deleta monitoramentos com mais de 15 dias
  Future<int> deleteExpiredMonitorings({int expirationDays = 15}) async {
    try {
      // Calcular data de corte (15 dias atrás)
      final cutoffDate = DateTime.now().subtract(Duration(days: expirationDays));
      final cutoffDateStr = cutoffDate.toIso8601String();
      
      Logger.info('🗑️ Deletando monitoramentos anteriores a: $cutoffDateStr');
      
      // Buscar IDs dos monitoramentos que serão deletados
      final expiredMaps = await _database.query(
        'infestacoes_monitoramento',
        columns: ['id'],
        where: 'data_hora < ?',
        whereArgs: [cutoffDateStr],
      );
      
      final expiredIds = expiredMaps.map((m) => m['id'] as String).toList();
      Logger.info('📊 Monitoramentos expirados encontrados: ${expiredIds.length}');
      
      if (expiredIds.isEmpty) {
        Logger.info('✅ Nenhum monitoramento expirado para deletar');
        return 0;
      }
      
      // Deletar fotos primeiro
      for (final id in expiredIds) {
        await _database.delete(
          'infestacao_fotos',
          where: 'infestacao_id = ?',
          whereArgs: [id],
        );
      }
      
      // Deletar monitoramentos expirados
      final deletedCount = await _database.delete(
        'infestacoes_monitoramento',
        where: 'data_hora < ?',
        whereArgs: [cutoffDateStr],
      );
      
      Logger.info('✅ $deletedCount monitoramentos expirados deletados automaticamente');
      return deletedCount;
    } catch (e) {
      Logger.info('❌ Erro ao deletar monitoramentos expirados: $e');
      return 0;
    }
  }

  /// Deleta um monitoramento específico por ID
  Future<bool> deleteById(String id) async {
    try {
      Logger.info('🗑️ Deletando monitoramento: $id');
      
      // Deletar fotos primeiro
      final photosDeleted = await _database.delete(
        'infestacao_fotos',
        where: 'infestacao_id = ?',
        whereArgs: [id],
      );
      Logger.info('📸 $photosDeleted fotos deletadas');
      
      // Deletar monitoramento
      final deleted = await _database.delete(
        'infestacoes_monitoramento',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (deleted > 0) {
        Logger.info('✅ Monitoramento deletado com sucesso: $id');
        return true;
      } else {
        Logger.info('⚠️ Monitoramento não encontrado: $id');
        return false;
      }
    } catch (e) {
      Logger.info('❌ Erro ao deletar monitoramento: $e');
      return false;
    }
  }

  /// Deleta todos os monitoramentos de um talhão
  Future<int> deleteByTalhaoId(int talhaoId) async {
    try {
      Logger.info('🗑️ Deletando todos os monitoramentos do talhão: $talhaoId');
      
      // Buscar IDs dos monitoramentos do talhão
      final maps = await _database.query(
        'infestacoes_monitoramento',
        columns: ['id'],
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
      
      final ids = maps.map((m) => m['id'] as String).toList();
      
      // Deletar fotos de todos os monitoramentos
      for (final id in ids) {
        await _database.delete(
          'infestacao_fotos',
          where: 'infestacao_id = ?',
          whereArgs: [id],
        );
      }
      
      // Deletar monitoramentos do talhão
      final deletedCount = await _database.delete(
        'infestacoes_monitoramento',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
      
      Logger.info('✅ $deletedCount monitoramentos deletados do talhão $talhaoId');
      return deletedCount;
    } catch (e) {
      Logger.info('❌ Erro ao deletar monitoramentos do talhão: $e');
      return 0;
    }
  }
}