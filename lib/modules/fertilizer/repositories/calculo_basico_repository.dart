import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/calculo_basico_model.dart';

/// Repositório para gerenciar operações de banco de dados para cálculos básicos de calibração
class CalculoBasicoRepository {
  static const String _tableName = 'calculo_basico_calibracao';

  /// Cria a tabela se não existir
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        data_calibragem TEXT NOT NULL,
        equipamento TEXT NOT NULL,
        operador TEXT NOT NULL,
        fertilizante TEXT NOT NULL,
        velocidade_trator REAL NOT NULL,
        largura_trabalho REAL NOT NULL,
        abertura_comporta REAL NOT NULL,
        tipo_coleta TEXT NOT NULL,
        tempo_coletado REAL,
        distancia_percorrida REAL,
        volume_coletado REAL NOT NULL,
        unidade_volume TEXT NOT NULL,
        meta_aplicacao REAL,
        densidade REAL,
        area_percorrida REAL,
        area_hectares REAL,
        taxa_aplicada_l REAL,
        taxa_aplicada_kg REAL,
        sacas_ha REAL,
        diferenca_meta REAL,
        erro_porcentagem REAL,
        status_calibragem TEXT,
        sugestao_ajuste TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Salva uma calibração no banco de dados
  Future<String> salvarCalibracao(CalculoBasicoModel calibracao) async {
    final db = await AppDatabase.instance.database;
    
    final calibracaoComId = calibracao.copyWith(
      id: calibracao.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    await db.insert(
      _tableName,
      calibracaoComId.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return calibracaoComId.id!;
  }

  /// Busca todas as calibrações
  Future<List<CalculoBasicoModel>> buscarTodasCalibracoes() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }

  /// Busca calibrações por equipamento
  Future<List<CalculoBasicoModel>> buscarCalibracoesPorEquipamento(String equipamento) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'equipamento = ?',
      whereArgs: [equipamento],
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }

  /// Busca calibrações por operador
  Future<List<CalculoBasicoModel>> buscarCalibracoesPorOperador(String operador) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'operador = ?',
      whereArgs: [operador],
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }

  /// Busca calibrações por fertilizante
  Future<List<CalculoBasicoModel>> buscarCalibracoesPorFertilizante(String fertilizante) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'fertilizante = ?',
      whereArgs: [fertilizante],
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }

  /// Busca uma calibração por ID
  Future<CalculoBasicoModel?> buscarCalibracaoPorId(String id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CalculoBasicoModel.fromMap(maps.first);
  }

  /// Atualiza uma calibração existente
  Future<void> atualizarCalibracao(CalculoBasicoModel calibracao) async {
    if (calibracao.id == null) {
      throw Exception('ID da calibração é obrigatório para atualização');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _tableName,
      {
        ...calibracao.toMap(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [calibracao.id],
    );
  }

  /// Remove uma calibração
  Future<void> removerCalibracao(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca estatísticas das calibrações
  Future<Map<String, dynamic>> buscarEstatisticas() async {
    final db = await AppDatabase.instance.database;
    
    // Total de calibrações
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $_tableName');
    final total = totalResult.first['total'] as int;

    // Calibrações por status
    final statusResult = await db.rawQuery('''
      SELECT status_calibragem, COUNT(*) as count 
      FROM $_tableName 
      WHERE status_calibragem IS NOT NULL 
      GROUP BY status_calibragem
    ''');
    
    final statusCounts = <String, int>{};
    for (final row in statusResult) {
      statusCounts[row['status_calibragem'] as String] = row['count'] as int;
    }

    // Equipamentos mais utilizados
    final equipamentosResult = await db.rawQuery('''
      SELECT equipamento, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY equipamento 
      ORDER BY count DESC 
      LIMIT 5
    ''');
    
    final equipamentosPopulares = <String, int>{};
    for (final row in equipamentosResult) {
      equipamentosPopulares[row['equipamento'] as String] = row['count'] as int;
    }

    // Taxa média de aplicação
    final taxaMediaResult = await db.rawQuery('''
      SELECT AVG(taxa_aplicada_kg) as taxaMediaKg, AVG(taxa_aplicada_l) as taxaMediaL
      FROM $_tableName 
      WHERE taxa_aplicada_kg IS NOT NULL OR taxa_aplicada_l IS NOT NULL
    ''');
    
    final taxaMedia = taxaMediaResult.first;

    return {
      'total': total,
      'statusCounts': statusCounts,
      'equipamentosPopulares': equipamentosPopulares,
      'taxaMediaKg': taxaMedia['taxaMediaKg'] as double? ?? 0.0,
      'taxaMediaL': taxaMedia['taxaMediaL'] as double? ?? 0.0,
    };
  }

  /// Busca calibrações em um período
  Future<List<CalculoBasicoModel>> buscarCalibracoesPorPeriodo(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'data_calibragem >= ? AND data_calibragem <= ?',
      whereArgs: [
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
      ],
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }

  /// Busca calibrações com filtros múltiplos
  Future<List<CalculoBasicoModel>> buscarCalibracoesComFiltros({
    String? equipamento,
    String? operador,
    String? fertilizante,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? statusCalibragem,
  }) async {
    final db = await AppDatabase.instance.database;
    
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (equipamento != null && equipamento.isNotEmpty) {
      whereConditions.add('equipamento LIKE ?');
      whereArgs.add('%$equipamento%');
    }

    if (operador != null && operador.isNotEmpty) {
      whereConditions.add('operador LIKE ?');
      whereArgs.add('%$operador%');
    }

    if (fertilizante != null && fertilizante.isNotEmpty) {
      whereConditions.add('fertilizante LIKE ?');
      whereArgs.add('%$fertilizante%');
    }

    if (dataInicio != null) {
      whereConditions.add('data_calibragem >= ?');
      whereArgs.add(dataInicio.toIso8601String());
    }

    if (dataFim != null) {
      whereConditions.add('data_calibragem <= ?');
      whereArgs.add(dataFim.toIso8601String());
    }

    if (statusCalibragem != null && statusCalibragem.isNotEmpty) {
      whereConditions.add('status_calibragem = ?');
      whereArgs.add(statusCalibragem);
    }

    final whereClause = whereConditions.isNotEmpty 
        ? whereConditions.join(' AND ')
        : null;

    final maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_calibragem DESC',
    );

    return maps.map((map) => CalculoBasicoModel.fromMap(map)).toList();
  }
}
