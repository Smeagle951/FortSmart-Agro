/// 💾 DAO: Alertas Fenológicos
/// 
/// Data Access Object para persistência de alertas fenológicos
/// no banco de dados SQLite local.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:sqflite/sqflite.dart';
import '../../models/phenological_alert_model.dart';

class PhenologicalAlertDAO {
  final Database database;

  PhenologicalAlertDAO(this.database);

  /// Nome da tabela
  static const String tableName = 'phenological_alerts';

  /// Script de criação da tabela (CORRIGIDO: snake_case)
  static const String createTableScript = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      registro_id TEXT NOT NULL,
      talhao_id TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      tipo TEXT NOT NULL,
      severidade TEXT NOT NULL,
      titulo TEXT NOT NULL,
      descricao TEXT NOT NULL,
      valor_medido REAL,
      valor_esperado REAL,
      desvio_percentual REAL,
      recomendacoes TEXT,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      resolvido_em TEXT,
      observacoes_resolucao TEXT
    )
  ''';

  /// Inserir novo alerta
  Future<void> inserir(PhenologicalAlertModel alert) async {
    await database.insert(
      tableName,
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualizar alerta existente
  Future<void> atualizar(PhenologicalAlertModel alert) async {
    await database.update(
      tableName,
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  /// Deletar alerta
  Future<void> deletar(String id) async {
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Buscar alerta por ID
  Future<PhenologicalAlertModel?> buscarPorId(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PhenologicalAlertModel.fromMap(maps.first);
  }

  /// Listar alertas ativos de um talhão
  Future<List<PhenologicalAlertModel>> listarAtivos(String talhaoId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhaoId = ? AND status = ?',
      whereArgs: [talhaoId, 'AlertStatus.ativo'],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }

  /// Listar todos os alertas de um talhão/cultura
  Future<List<PhenologicalAlertModel>> listarPorTalhaoECultura(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhaoId = ? AND culturaId = ?',
      whereArgs: [talhaoId, culturaId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }

  /// Listar alertas por severidade
  Future<List<PhenologicalAlertModel>> listarPorSeveridade(
    String talhaoId,
    AlertSeverity severidade,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhaoId = ? AND severidade = ? AND status = ?',
      whereArgs: [
        talhaoId,
        'AlertSeverity.${severidade.toString().split('.').last}',
        'AlertStatus.ativo',
      ],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }

  /// Listar alertas por tipo
  Future<List<PhenologicalAlertModel>> listarPorTipo(
    String talhaoId,
    AlertType tipo,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhaoId = ? AND tipo = ? AND status = ?',
      whereArgs: [
        talhaoId,
        'AlertType.${tipo.toString().split('.').last}',
        'AlertStatus.ativo',
      ],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }

  /// Contar alertas ativos
  Future<int> contarAtivos(String talhaoId) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName '
      'WHERE talhaoId = ? AND status = ?',
      [talhaoId, 'AlertStatus.ativo'],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Contar alertas críticos ativos
  Future<int> contarCriticos(String talhaoId) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName '
      'WHERE talhaoId = ? AND severidade = ? AND status = ?',
      [talhaoId, 'AlertSeverity.critica', 'AlertStatus.ativo'],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Resolver alerta
  Future<void> resolverAlerta(
    String id,
    String? observacoes,
  ) async {
    await database.update(
      tableName,
      {
        'status': 'AlertStatus.resolvido',
        'resolvidoEm': DateTime.now().toIso8601String(),
        'observacoesResolucao': observacoes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ignorar alerta
  Future<void> ignorarAlerta(String id, String? observacoes) async {
    await database.update(
      tableName,
      {
        'status': 'AlertStatus.ignorado',
        'resolvidoEm': DateTime.now().toIso8601String(),
        'observacoesResolucao': observacoes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Listar histórico de alertas (resolvidos + ignorados)
  Future<List<PhenologicalAlertModel>> listarHistorico(
    String talhaoId,
    String culturaId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'talhaoId = ? AND culturaId = ? AND status != ?',
      whereArgs: [talhaoId, culturaId, 'AlertStatus.ativo'],
      orderBy: 'resolvidoEm DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }

  /// Limpar alertas antigos (resolvidos há mais de 90 dias)
  Future<void> limparAntigos() async {
    final dataLimite = DateTime.now().subtract(const Duration(days: 90));
    await database.delete(
      tableName,
      where: 'status != ? AND resolvidoEm < ?',
      whereArgs: [
        'AlertStatus.ativo',
        dataLimite.toIso8601String(),
      ],
    );
  }

  /// Buscar alertas de um registro específico
  Future<List<PhenologicalAlertModel>> listarPorRegistro(
    String registroId,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'registroId = ?',
      whereArgs: [registroId],
      orderBy: 'severidade DESC',
    );

    return maps.map((map) => PhenologicalAlertModel.fromMap(map)).toList();
  }
}

