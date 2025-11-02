import 'package:sqflite/sqflite.dart';
import '../models/calibragem_disco_model.dart';
import '../../services/database_service.dart';

/// Repositório para gerenciar operações de banco de dados para calibragem por disco (vácuo)
class CalibragemDiscoRepository {
  late Database db;
  static const String tableName = 'calibragem_disco';

  CalibragemDiscoRepository() {
    _initDb();
  }

  /// Inicializa o banco de dados
  Future<void> _initDb() async {
    db = await DatabaseService().database;
    await _createTable();
  }

  /// Cria a tabela se não existir
  Future<void> _createTable() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        furos_disco INTEGER NOT NULL,
        engrenagem_motora INTEGER NOT NULL,
        engrenagem_movida INTEGER NOT NULL,
        espacamento_cm REAL NOT NULL,
        linhas_plantadeira INTEGER NOT NULL,
        populacao_desejada REAL,
        relacao REAL,
        sementes_metro REAL,
        populacao_estimativa REAL,
        diferenca_populacao REAL,
        status TEXT,
        data TEXT DEFAULT CURRENT_TIMESTAMP,
        talhao_id TEXT
      )
    ''');
  }

  /// Insere uma nova calibragem no banco de dados
  Future<int> insert(CalibragemDiscoModel calibragem) async {
    return await db.insert(
      tableName,
      calibragem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza uma calibragem existente
  Future<int> update(CalibragemDiscoModel calibragem) async {
    return await db.update(
      tableName,
      calibragem.toMap(),
      where: 'id = ?',
      whereArgs: [calibragem.id],
    );
  }

  /// Exclui uma calibragem
  Future<int> delete(int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém uma calibragem pelo ID
  Future<CalibragemDiscoModel?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CalibragemDiscoModel.fromMap(maps.first);
    }
    return null;
  }

  /// Obtém todas as calibragens
  Future<List<CalibragemDiscoModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'data DESC');
    return List.generate(maps.length, (i) {
      return CalibragemDiscoModel.fromMap(maps[i]);
    });
  }

  /// Obtém calibragens por talhão
  Future<List<CalibragemDiscoModel>> getByTalhao(String talhaoId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) {
      return CalibragemDiscoModel.fromMap(maps[i]);
    });
  }
}
