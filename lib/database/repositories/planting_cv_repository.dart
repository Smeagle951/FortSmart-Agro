import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/planting_cv_model.dart';
import '../../utils/logger.dart';

/// Repositório para operações com registros de CV% do Plantio
class PlantingCVRepository {
  static const String _tableName = 'planting_cv';
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
            data_plantio TEXT NOT NULL,
            comprimento_linha_amostrada REAL NOT NULL,
            espacamento_entre_linhas REAL NOT NULL,
            distancias_entre_sementes TEXT NOT NULL,
            media_espacamento REAL NOT NULL,
            desvio_padrao REAL NOT NULL,
            coeficiente_variacao REAL NOT NULL,
            plantas_por_metro REAL NOT NULL,
            populacao_estimada_hectare REAL NOT NULL,
            classificacao TEXT NOT NULL,
            observacoes TEXT,
            meta_populacao_hectare REAL,
            meta_plantas_metro REAL,
            diferenca_populacao_percentual REAL,
            diferenca_plantas_metro_percentual REAL,
            status_comparacao_populacao TEXT,
            status_comparacao_plantas_metro TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            sync_status INTEGER DEFAULT 0,
            -- FOREIGN KEY (talhao_id) REFERENCES talhoes(id) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
        
        // Criar índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_talhao_id ON $_tableName (talhao_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_cultura_id ON $_tableName (cultura_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_data_plantio ON $_tableName (data_plantio)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_sync_status ON $_tableName (sync_status)');
        
        Logger.info('✅ Tabela $_tableName criada com sucesso!');
        
        // Garantir que existe pelo menos um talhão
        await _ensureTalhaoExists(db);
      }
      
      // Adicionar novos campos se não existirem (sempre executar)
      await _adicionarNovosCampos(db);
    } catch (e) {
      Logger.error('❌ Erro ao criar tabela $_tableName: $e');
      rethrow;
    }
  }

  /// Adiciona novos campos à tabela se não existirem
  Future<void> _adicionarNovosCampos(Database db) async {
    try {
      // Verificar se os novos campos já existem
      final columns = await db.rawQuery("PRAGMA table_info($_tableName)");
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      // Adicionar campos se não existirem
      if (!columnNames.contains('sugestoes')) {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN sugestoes TEXT');
        Logger.info('✅ Campo sugestoes adicionado');
      }
      
      if (!columnNames.contains('motivo_resultado')) {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN motivo_resultado TEXT');
        Logger.info('✅ Campo motivo_resultado adicionado');
      }
      
      if (!columnNames.contains('detalhes_calculo')) {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN detalhes_calculo TEXT');
        Logger.info('✅ Campo detalhes_calculo adicionado');
      }
      
      if (!columnNames.contains('metricas_detalhadas')) {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN metricas_detalhadas TEXT');
        Logger.info('✅ Campo metricas_detalhadas adicionado');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar novos campos: $e');
      // Não falhar se houver erro ao adicionar campos
    }
  }

  /// Garante que existe pelo menos um talhão no banco
  Future<void> _ensureTalhaoExists(Database db) async {
    try {
      // Verificar se a tabela talhoes existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tables.isEmpty) {
        // Criar tabela talhoes se não existir
        await db.execute('''
          CREATE TABLE IF NOT EXISTS talhoes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            idFazenda TEXT NOT NULL,
            poligonos TEXT NOT NULL,
            safras TEXT NOT NULL,
            dataCriacao TEXT NOT NULL,
            dataAtualizacao TEXT NOT NULL,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            device_id TEXT
          )
        ''');
        
        Logger.info('✅ Tabela talhoes criada!');
      }
      
      // Verificar se existe pelo menos um talhão
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM talhoes')) ?? 0;
      
      if (count == 0) {
        // Criar talhão padrão
        await db.insert('talhoes', {
          'id': 'teste-talhao-001',
          'name': 'Talhão Teste',
          'idFazenda': 'fazenda-teste',
          'poligonos': '[]',
          'safras': '[]',
          'dataCriacao': DateTime.now().toIso8601String(),
          'dataAtualizacao': DateTime.now().toIso8601String(),
          'sincronizado': 0,
        });
        
        Logger.info('✅ Talhão teste criado!');
      }
    } catch (e) {
      Logger.error('❌ Erro ao garantir talhão: $e');
    }
  }

  /// Salva um registro de CV% do plantio
  Future<String> salvar(PlantingCVModel cvModel) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      // Atualiza a data de modificação
      final cvModelAtualizado = cvModel.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Verifica se o registro já existe
      final existingRecord = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [cvModelAtualizado.id],
      );
      
      if (existingRecord.isNotEmpty) {
        // Atualiza o registro existente
        await db.update(
          _tableName,
          cvModelAtualizado.toMap(),
          where: 'id = ?',
          whereArgs: [cvModelAtualizado.id],
        );
        Logger.info('✅ CV% atualizado: ${cvModelAtualizado.id}');
      } else {
        // Insere um novo registro
        await db.insert(
          _tableName,
          cvModelAtualizado.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        Logger.info('✅ CV% inserido: ${cvModelAtualizado.id}');
      }
      
      return cvModelAtualizado.id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar CV%: $e');
      rethrow;
    }
  }

  /// Busca todos os registros de CV%
  Future<List<PlantingCVModel>> buscarTodos() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingCVModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV%: $e');
      return [];
    }
  }

  /// Busca CV% por ID
  Future<PlantingCVModel?> buscarPorId(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return PlantingCVModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV% por ID: $e');
      return null;
    }
  }

  /// Busca CV% por talhão
  Future<List<PlantingCVModel>> buscarPorTalhao(String talhaoId) async {
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
        return PlantingCVModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV% por talhão: $e');
      return [];
    }
  }

  /// Busca CV% por cultura
  Future<List<PlantingCVModel>> buscarPorCultura(String culturaId) async {
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
        return PlantingCVModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV% por cultura: $e');
      return [];
    }
  }

  /// Busca o CV% mais recente de um talhão
  Future<PlantingCVModel?> buscarMaisRecentePorTalhao(String talhaoId) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return PlantingCVModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV% mais recente: $e');
      return null;
    }
  }

  /// Exclui um registro de CV%
  Future<bool> excluir(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        Logger.info('✅ CV% excluído: $id');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao excluir CV%: $e');
      return false;
    }
  }

  /// Busca registros não sincronizados
  Future<List<PlantingCVModel>> buscarNaoSincronizados() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'sync_status = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return PlantingCVModel.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('❌ Erro ao buscar CV% não sincronizados: $e');
      return [];
    }
  }

  /// Marca registro como sincronizado
  Future<bool> marcarComoSincronizado(String id) async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final result = await db.update(
        _tableName,
        {'sync_status': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao marcar CV% como sincronizado: $e');
      return false;
    }
  }

  /// Obtém estatísticas dos CV%
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      await createTableIfNotExists();
      final db = await _appDatabase.database;
      
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $_tableName');
      final total = totalResult.first['total'] as int;
      
      final excelenteResult = await db.rawQuery(
        'SELECT COUNT(*) as excelente FROM $_tableName WHERE classificacao = ?',
        ['excelente']
      );
      final excelente = excelenteResult.first['excelente'] as int;
      
      final bomResult = await db.rawQuery(
        'SELECT COUNT(*) as bom FROM $_tableName WHERE classificacao = ?',
        ['bom']
      );
      final bom = bomResult.first['bom'] as int;
      
      final moderadoResult = await db.rawQuery(
        'SELECT COUNT(*) as moderado FROM $_tableName WHERE classificacao = ?',
        ['moderado']
      );
      final moderado = moderadoResult.first['moderado'] as int;
      
      final ruimResult = await db.rawQuery(
        'SELECT COUNT(*) as ruim FROM $_tableName WHERE classificacao = ?',
        ['ruim']
      );
      final ruim = ruimResult.first['ruim'] as int;
      
      return {
        'total': total,
        'excelente': excelente,
        'bom': bom,
        'moderado': moderado,
        'ruim': ruim,
        'percentual_excelente': total > 0 ? (excelente / total * 100) : 0.0,
        'percentual_bom': total > 0 ? (bom / total * 100) : 0.0,
        'percentual_moderado': total > 0 ? (moderado / total * 100) : 0.0,
        'percentual_ruim': total > 0 ? (ruim / total * 100) : 0.0,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de CV%: $e');
      return {
        'total': 0,
        'excelente': 0,
        'bom': 0,
        'moderado': 0,
        'ruim': 0,
        'percentual_excelente': 0.0,
        'percentual_bom': 0.0,
        'percentual_moderado': 0.0,
        'percentual_ruim': 0.0,
      };
    }
  }

  /// Insere um novo registro de CV
  Future<String> insertCvRecord(PlantingCVModel cvModel) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(_tableName, cvModel.toMap());
      Logger.info('Registro de CV inserido: ${cvModel.id}');
      return cvModel.id;
    } catch (e) {
      Logger.error('Erro ao inserir registro de CV: $e');
      rethrow;
    }
  }

  /// Obtém registros de CV por talhão
  Future<List<PlantingCVModel>> getCvRecordsByTalhao(String talhaoId) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => PlantingCVModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao obter registros de CV por talhão: $e');
      return [];
    }
  }

  /// Atualiza um registro de CV
  Future<int> updateCvRecord(PlantingCVModel cvModel) async {
    try {
      final db = await _appDatabase.database;
      final result = await db.update(
        _tableName,
        cvModel.toMap(),
        where: 'id = ?',
        whereArgs: [cvModel.id],
      );
      Logger.info('Registro de CV atualizado: ${cvModel.id}');
      return result;
    } catch (e) {
      Logger.error('Erro ao atualizar registro de CV: $e');
      rethrow;
    }
  }

  /// Remove um registro de CV
  Future<int> deleteCvRecord(String cvId) async {
    try {
      final db = await _appDatabase.database;
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [cvId],
      );
      Logger.info('Registro de CV removido: $cvId');
      return result;
    } catch (e) {
      Logger.error('Erro ao remover registro de CV: $e');
      rethrow;
    }
  }
}
