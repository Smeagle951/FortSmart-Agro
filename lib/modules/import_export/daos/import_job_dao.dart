import 'package:sqflite/sqflite.dart';
import '../models/import_job_model.dart';
import '../../../database/app_database.dart';

class ImportJobDao {
  static const String tableName = 'import_jobs';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        arquivo_path TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        erros TEXT,
        data_criacao TEXT NOT NULL,
        usuario_id TEXT,
        observacoes TEXT,
        total_registros INTEGER,
        registros_processados INTEGER DEFAULT 0,
        registros_sucesso INTEGER DEFAULT 0,
        registros_erro INTEGER DEFAULT 0,
        nome_arquivo_original TEXT,
        tamanho_arquivo REAL
      )
    ''');
  }

  Future<int> insert(ImportJobModel job) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(tableName, job.toMap());
  }

  Future<bool> update(ImportJobModel job) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      tableName,
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
    return count > 0;
  }

  Future<ImportJobModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ImportJobModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ImportJobModel>> getAll() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ImportJobModel.fromMap(map)).toList();
  }

  Future<List<ImportJobModel>> getByTipo(String tipo) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ImportJobModel.fromMap(map)).toList();
  }

  Future<List<ImportJobModel>> getByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ImportJobModel.fromMap(map)).toList();
  }

  Future<List<ImportJobModel>> getByPeriod(DateTime inicio, DateTime fim) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'data_criacao BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ImportJobModel.fromMap(map)).toList();
  }

  Future<bool> delete(int id) async {
    final db = await AppDatabase.instance.database;
    final count = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<bool> updateStatus(int id, String status, {String? erros}) async {
    final db = await AppDatabase.instance.database;
    final data = <String, dynamic>{
      'status': status,
    };
    if (erros != null) data['erros'] = erros;

    final count = await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<bool> updateProgress(int id, {
    int? totalRegistros,
    int? registrosProcessados,
    int? registrosSucesso,
    int? registrosErro,
  }) async {
    final db = await AppDatabase.instance.database;
    final data = <String, dynamic>{};
    
    if (totalRegistros != null) data['total_registros'] = totalRegistros;
    if (registrosProcessados != null) data['registros_processados'] = registrosProcessados;
    if (registrosSucesso != null) data['registros_sucesso'] = registrosSucesso;
    if (registrosErro != null) data['registros_erro'] = registrosErro;

    final count = await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await AppDatabase.instance.database;
    
    // Total de jobs
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $tableName');
    final total = totalResult.first['total'] as int;

    // Jobs por status
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM $tableName 
      GROUP BY status
    ''');
    final statusCounts = <String, int>{};
    for (final row in statusResult) {
      statusCounts[row['status'] as String] = row['count'] as int;
    }

    // Jobs por tipo
    final tipoResult = await db.rawQuery('''
      SELECT tipo, COUNT(*) as count 
      FROM $tableName 
      GROUP BY tipo
    ''');
    final tipoCounts = <String, int>{};
    for (final row in tipoResult) {
      tipoCounts[row['tipo'] as String] = row['count'] as int;
    }

    // Total de registros processados
    final processadosResult = await db.rawQuery('''
      SELECT 
        SUM(registros_processados) as total_processados,
        SUM(registros_sucesso) as total_sucesso,
        SUM(registros_erro) as total_erro
      FROM $tableName
    ''');
    final processados = processadosResult.first;

    // Jobs dos últimos 30 dias
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM $tableName 
      WHERE data_criacao >= ?
    ''', [thirtyDaysAgo.toIso8601String()]);
    final recent = recentResult.first['count'] as int;

    return {
      'total': total,
      'por_status': statusCounts,
      'por_tipo': tipoCounts,
      'total_processados': processados['total_processados'] ?? 0,
      'total_sucesso': processados['total_sucesso'] ?? 0,
      'total_erro': processados['total_erro'] ?? 0,
      'ultimos_30_dias': recent,
    };
  }

  Future<void> cleanupOldJobs({int daysToKeep = 90}) async {
    final db = await AppDatabase.instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    await db.delete(
      tableName,
      where: 'data_criacao < ? AND status IN (?, ?)',
      whereArgs: [cutoffDate.toIso8601String(), 'concluido', 'erro'],
    );
  }
}
