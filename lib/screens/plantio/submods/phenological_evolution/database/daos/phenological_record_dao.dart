/// 💾 DAO: Registro Fenológico
/// 
/// Data Access Object para persistência de registros fenológicos
/// no banco de dados SQLite local.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:sqflite/sqflite.dart';
import '../../models/phenological_record_model.dart';

class PhenologicalRecordDAO {
  final Database database;

  PhenologicalRecordDAO(this.database);

  /// Nome da tabela
  static const String tableName = 'phenological_records';

  /// Script de criação da tabela (CORRIGIDO: snake_case + novos campos v2)
  static const String createTableScript = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      data_registro TEXT NOT NULL,
      dias_apos_emergencia INTEGER NOT NULL,
      altura_cm REAL,
      numero_folhas INTEGER,
      numero_folhas_trifolioladas INTEGER,
      diametro_colmo_mm REAL,
      numero_nos INTEGER,
      espacamento_entre_nos_cm REAL,
      numero_ramos_vegetativos INTEGER,
      numero_ramos_reprodutivos INTEGER,
      altura_primeiro_ramo_frutifero_cm REAL,
      numero_botoes_florais INTEGER,
      numero_macas_capulhos INTEGER,
      numero_afilhos INTEGER,
      comprimento_panicula_cm REAL,
      insercao_espiga_cm REAL,
      comprimento_espiga_cm REAL,
      numero_fileiras_graos INTEGER,
      vagens_planta REAL,
      espigas_planta REAL,
      comprimento_vagens_cm REAL,
      graos_vagem REAL,
      estande_plantas REAL,
      percentual_falhas REAL,
      percentual_sanidade REAL,
      sintomas_observados TEXT,
      presenca_pragas INTEGER,
      presenca_doencas INTEGER,
      estagio_fenologico TEXT,
      descricao_estagio TEXT,
      fotos TEXT,
      observacoes TEXT,
      latitude REAL,
      longitude REAL,
      responsavel TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  /// Inserir novo registro
  Future<void> inserir(PhenologicalRecordModel record) async {
    await database.insert(
      tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualizar registro existente
  Future<void> atualizar(PhenologicalRecordModel record) async {
    await database.update(
      tableName,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Deletar registro
  Future<void> deletar(String id) async {
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Buscar registro por ID
  Future<PhenologicalRecordModel?> buscarPorId(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PhenologicalRecordModel.fromMap(maps.first);
  }

  /// Listar todos os registros de um talhão
  Future<List<PhenologicalRecordModel>> listarPorTalhao(String talhaoId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_registro DESC',
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Listar registros por talhão e cultura
  Future<List<PhenologicalRecordModel>> listarPorTalhaoECultura(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ?',
      whereArgs: [talhaoId, culturaId],
      orderBy: 'data_registro DESC',
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Listar registros ordenados por data (para curvas de crescimento)
  Future<List<PhenologicalRecordModel>> listarOrdenadoPorData(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ?',
      whereArgs: [talhaoId, culturaId],
      orderBy: 'data_registro ASC', // Ordem crescente para gráficos
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Buscar último registro de um talhão/cultura
  Future<PhenologicalRecordModel?> buscarUltimoRegistro(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ?',
      whereArgs: [talhaoId, culturaId],
      orderBy: 'data_registro DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PhenologicalRecordModel.fromMap(maps.first);
  }

  /// Buscar registros em um intervalo de datas
  Future<List<PhenologicalRecordModel>> listarPorPeriodo(
    String talhaoId,
    String culturaId,
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ? AND data_registro BETWEEN ? AND ?',
      whereArgs: [
        talhaoId,
        culturaId,
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
      ],
      orderBy: 'data_registro ASC',
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Contar registros de um talhão/cultura
  Future<int> contarRegistros(String talhaoId, String culturaId) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE talhao_id = ? AND cultura_id = ?',
      [talhaoId, culturaId],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Buscar registros com alertas (sanidade < 80% ou presença de pragas/doenças)
  Future<List<PhenologicalRecordModel>> listarComProblemas(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ? AND '
             '(percentual_sanidade < 80 OR presenca_pragas = 1 OR presenca_doencas = 1)',
      whereArgs: [talhaoId, culturaId],
      orderBy: 'data_registro DESC',
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Calcular média de altura por período
  Future<double?> calcularMediaAltura(
    String talhaoId,
    String culturaId,
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    final result = await database.rawQuery(
      'SELECT AVG(altura_cm) as media FROM $tableName '
      'WHERE talhao_id = ? AND cultura_id = ? '
      'AND data_registro BETWEEN ? AND ? '
      'AND altura_cm IS NOT NULL',
      [
        talhaoId,
        culturaId,
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
      ],
    );

    if (result.isEmpty) return null;
    return (result.first['media'] as num?)?.toDouble();
  }

  /// Buscar todos os registros (para debug)
  Future<List<PhenologicalRecordModel>> listarTodos() async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      orderBy: 'data_registro DESC',
    );

    return maps.map((map) => PhenologicalRecordModel.fromMap(map)).toList();
  }

  /// Limpar todos os registros de um talhão/cultura
  Future<void> limparRegistros(String talhaoId, String culturaId) async {
    await database.delete(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ?',
      whereArgs: [talhaoId, culturaId],
    );
  }
}

