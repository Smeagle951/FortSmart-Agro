import 'package:sqflite/sqflite.dart';
import '../models/export_job_model.dart';
import '../../../database/app_database.dart';

class ExportJobDao {
  static const String tableName = 'export_jobs';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        filtros TEXT NOT NULL,
        formato TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        arquivo_path TEXT,
        data_criacao TEXT NOT NULL,
        usuario_id TEXT,
        observacoes TEXT,
        total_registros INTEGER,
        tamanho_arquivo REAL
      )
    ''');
  }

  Future<int> insert(ExportJobModel job) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(tableName, job.toMap());
  }

  Future<bool> update(ExportJobModel job) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      tableName,
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
    return count > 0;
  }

  Future<ExportJobModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExportJobModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ExportJobModel>> getAll() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ExportJobModel.fromMap(map)).toList();
  }

  Future<List<ExportJobModel>> getByTipo(String tipo) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ExportJobModel.fromMap(map)).toList();
  }

  Future<List<ExportJobModel>> getByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ExportJobModel.fromMap(map)).toList();
  }

  Future<List<ExportJobModel>> getByPeriod(DateTime inicio, DateTime fim) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableName,
      where: 'data_criacao BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data_criacao DESC',
    );
    return maps.map((map) => ExportJobModel.fromMap(map)).toList();
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

  Future<bool> updateStatus(int id, String status, {String? arquivoPath, String? observacoes}) async {
    final db = await AppDatabase.instance.database;
    final data = <String, dynamic>{
      'status': status,
    };
    if (arquivoPath != null) data['arquivo_path'] = arquivoPath;
    if (observacoes != null) data['observacoes'] = observacoes;

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
