import 'package:sqflite/sqflite.dart';
import '../../models/calibracao_fertilizante_model.dart';
import '../app_database.dart';
import '../../utils/logger.dart';

/// Repositório para operações de calibração de fertilizantes
class CalibracaoFertilizanteRepository {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'calibragens';

  Future<Database> get database async => await _appDatabase.database;

  /// Cria a tabela de calibrações se não existir
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        data_calibracao TEXT NOT NULL,
        responsavel TEXT NOT NULL,
        pesos TEXT NOT NULL,
        distancia_coleta REAL NOT NULL,
        espacamento REAL NOT NULL,
        faixa_esperada REAL,
        granulometria REAL,
        taxa_desejada REAL,
        tipo_paleta TEXT NOT NULL,
        diametro_prato_mm REAL,
        rpm REAL,
        velocidade REAL,
        taxa_real_kg_ha REAL NOT NULL,
        coeficiente_variacao REAL NOT NULL,
        faixa_real REAL NOT NULL,
        classificacao_cv TEXT NOT NULL,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id TEXT
      )
    ''');
  }

  /// Insere uma nova calibração
  Future<String> insert(CalibracaoFertilizanteModel calibracao) async {
    try {
      final db = await database;
      
      final data = {
        ...calibracao.toMap(),
        'pesos': calibracao.pesos.join(','), // Converter lista para string
      };
      
      final id = await db.insert(tableName, data);
      Logger.info('Calibração inserida com ID: $id');
      return id.toString();
    } catch (e) {
      Logger.error('Erro ao inserir calibração: $e');
      rethrow;
    }
  }

  /// Atualiza uma calibração existente
  Future<int> update(CalibracaoFertilizanteModel calibracao) async {
    try {
      final db = await database;
      
      final data = {
        ...calibracao.toMap(),
        'pesos': calibracao.pesos.join(','), // Converter lista para string
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await db.update(
        tableName,
        data,
        where: 'id = ?',
        whereArgs: [calibracao.id],
      );
      
      Logger.info('Calibração atualizada: ${calibracao.id}');
      return result;
    } catch (e) {
      Logger.error('Erro ao atualizar calibração: $e');
      rethrow;
    }
  }

  /// Remove uma calibração
  Future<int> delete(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('Calibração removida: $id');
      return result;
    } catch (e) {
      Logger.error('Erro ao remover calibração: $e');
      rethrow;
    }
  }

  /// Busca uma calibração por ID
  Future<CalibracaoFertilizanteModel?> findById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return _mapToModel(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar calibração por ID: $e');
      return null;
    }
  }

  /// Lista todas as calibrações
  Future<List<CalibracaoFertilizanteModel>> findAll() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'data_calibracao DESC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao listar calibrações: $e');
      return [];
    }
  }

  /// Busca calibrações por período
  Future<List<CalibracaoFertilizanteModel>> findByPeriod(
    DateTime inicio, 
    DateTime fim
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'data_calibracao BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
        orderBy: 'data_calibracao DESC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações por período: $e');
      return [];
    }
  }

  /// Busca calibrações por responsável
  Future<List<CalibracaoFertilizanteModel>> findByResponsavel(String responsavel) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'responsavel LIKE ?',
        whereArgs: ['%$responsavel%'],
        orderBy: 'data_calibracao DESC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações por responsável: $e');
      return [];
    }
  }

  /// Busca calibrações por tipo de paleta
  Future<List<CalibracaoFertilizanteModel>> findByTipoPaleta(String tipoPaleta) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'tipo_paleta = ?',
        whereArgs: [tipoPaleta.toLowerCase()],
        orderBy: 'data_calibracao DESC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações por tipo de paleta: $e');
      return [];
    }
  }

  /// Busca calibrações com CV crítico
  Future<List<CalibracaoFertilizanteModel>> findCriticas() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'coeficiente_variacao > 15.0',
        orderBy: 'coeficiente_variacao DESC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações críticas: $e');
      return [];
    }
  }

  /// Conta o total de calibrações
  Future<int> count() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return result.first['count'] as int;
    } catch (e) {
      Logger.error('Erro ao contar calibrações: $e');
      return 0;
    }
  }

  /// Obtém estatísticas das calibrações
  Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final db = await database;
      
      // Total de calibrações
      final total = await count();
      
      // Média do CV
      final resultCV = await db.rawQuery(
        'SELECT AVG(coeficiente_variacao) as media_cv FROM $tableName'
      );
      final mediaCV = resultCV.first['media_cv'] as double? ?? 0.0;
      
      // Calibrações por classificação
      final resultClassificacao = await db.rawQuery('''
        SELECT classificacao_cv, COUNT(*) as count 
        FROM $tableName 
        GROUP BY classificacao_cv
      ''');
      
      final classificacoes = <String, int>{};
      for (final row in resultClassificacao) {
        classificacoes[row['classificacao_cv'] as String] = row['count'] as int;
      }
      
      // Última calibração
      final ultimaResult = await db.query(
        tableName,
        orderBy: 'data_calibracao DESC',
        limit: 1,
      );
      
      final ultimaCalibracao = ultimaResult.isNotEmpty 
          ? _mapToModel(ultimaResult.first) 
          : null;
      
      return {
        'total': total,
        'media_cv': double.parse(mediaCV.toStringAsFixed(2)),
        'classificacoes': classificacoes,
        'ultima_calibracao': ultimaCalibracao,
      };
    } catch (e) {
      Logger.error('Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'media_cv': 0.0,
        'classificacoes': {},
        'ultima_calibracao': null,
      };
    }
  }

  /// Converte Map para Model
  CalibracaoFertilizanteModel _mapToModel(Map<String, dynamic> map) {
    // Converter string de pesos de volta para lista
    final pesosString = map['pesos'] as String;
    final pesos = pesosString.split(',').map((e) => double.parse(e)).toList();
    
    return CalibracaoFertilizanteModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      dataCalibracao: DateTime.parse(map['data_calibracao']),
      responsavel: map['responsavel'] ?? '',
      pesos: pesos,
      distanciaColeta: (map['distancia_coleta'] ?? 0.0).toDouble(),
      espacamento: (map['espacamento'] ?? 0.0).toDouble(),
      faixaEsperada: map['faixa_esperada']?.toDouble(),
      granulometria: map['granulometria']?.toDouble(),
      taxaDesejada: map['taxa_desejada']?.toDouble(),
      tipoPaleta: map['tipo_paleta'] ?? 'pequena',
      diametroPratoMm: map['diametro_prato_mm']?.toDouble(),
      rpm: map['rpm']?.toDouble(),
      velocidade: map['velocidade']?.toDouble(),
      taxaRealKgHa: (map['taxa_real_kg_ha'] ?? 0.0).toDouble(),
      coeficienteVariacao: (map['coeficiente_variacao'] ?? 0.0).toDouble(),
      faixaReal: (map['faixa_real'] ?? 0.0).toDouble(),
      classificacaoCV: map['classificacao_cv'] ?? 'Desconhecido',
      observacoes: map['observacoes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'] ?? 0,
      remoteId: map['remote_id'],
    );
  }

  /// Salva uma calibração (insert ou update)
  Future<String> save(CalibracaoFertilizanteModel calibracao) async {
    if (calibracao.id == null || calibracao.id!.isEmpty) {
      // Novo registro
      return await insert(calibracao);
    } else {
      // Atualizar registro existente
      await update(calibracao);
      return calibracao.id!;
    }
  }

  /// Verifica se uma calibração existe
  Future<bool> exists(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      Logger.error('Erro ao verificar existência da calibração: $e');
      return false;
    }
  }

  /// Busca calibrações não sincronizadas
  Future<List<CalibracaoFertilizanteModel>> findNaoSincronizadas() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'sync_status = 0',
        orderBy: 'created_at ASC',
      );
      
      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações não sincronizadas: $e');
      return [];
    }
  }

  /// Marca calibração como sincronizada
  Future<int> marcarSincronizada(String id, String remoteId) async {
    try {
      final db = await database;
      final result = await db.update(
        tableName,
        {
          'sync_status': 1,
          'remote_id': remoteId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('Calibração marcada como sincronizada: $id');
      return result;
    } catch (e) {
      Logger.error('Erro ao marcar calibração como sincronizada: $e');
      rethrow;
    }
  }
}
