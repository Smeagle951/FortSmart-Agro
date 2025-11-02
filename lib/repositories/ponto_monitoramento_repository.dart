import 'package:sqflite/sqflite.dart';
import '../models/ponto_monitoramento_model.dart';

class PontoMonitoramentoRepository {
  final Database _database;

  PontoMonitoramentoRepository(this._database);

  Future<void> createTable() async {
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS pontos_monitoramento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        ordem INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        data_hora_inicio TEXT,
        data_hora_fim TEXT,
        observacoes_gerais TEXT,
        sincronizado INTEGER DEFAULT 0,
        server_id TEXT,
        FOREIGN KEY (talhao_id) REFERENCES talhoes (id)
      )
    ''');
  }

  Future<int> insert(PontoMonitoramentoModel ponto) async {
    return await _database.insert('pontos_monitoramento', ponto.toMap());
  }

  Future<List<PontoMonitoramentoModel>> getByTalhaoId(int talhaoId) async {
    final maps = await _database.query(
      'pontos_monitoramento',
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'ordem ASC',
    );
    
    return maps.map((map) => PontoMonitoramentoModel.fromMap(map)).toList();
  }

  Future<PontoMonitoramentoModel?> getById(int id) async {
    final maps = await _database.query(
      'pontos_monitoramento',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return PontoMonitoramentoModel.fromMap(maps.first);
  }

  Future<void> updateEndTime(int pontoId, DateTime endTime) async {
    await _database.update(
      'pontos_monitoramento',
      {'data_hora_fim': endTime.toIso8601String()},
      where: 'id = ?',
      whereArgs: [pontoId],
    );
  }

  Future<void> updateObservacoes(int pontoId, String? observacoes) async {
    await _database.update(
      'pontos_monitoramento',
      {'observacoes_gerais': observacoes},
      where: 'id = ?',
      whereArgs: [pontoId],
    );
  }

  Future<void> startPoint(int pontoId) async {
    await _database.update(
      'pontos_monitoramento',
      {'data_hora_inicio': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [pontoId],
    );
  }

  Future<void> update(PontoMonitoramentoModel ponto) async {
    await _database.update(
      'pontos_monitoramento',
      ponto.toMap(),
      where: 'id = ?',
      whereArgs: [ponto.id],
    );
  }

  Future<List<PontoMonitoramentoModel>> fetchUnsynced({int limit = 20}) async {
    final maps = await _database.query(
      'pontos_monitoramento',
      where: 'sincronizado = 0',
      orderBy: 'ordem ASC',
      limit: limit,
    );
    
    return maps.map((map) => PontoMonitoramentoModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(int id, {String? serverId}) async {
    await _database.update(
      'pontos_monitoramento',
      {
        'sincronizado': 1,
        'server_id': serverId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await _database.delete(
      'pontos_monitoramento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
