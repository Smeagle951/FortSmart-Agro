import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/calibragem_adubo_model.dart';

class CalibragemAduboRepository {
  // Expor o banco de dados para uso em outros repositórios
  late final Database db;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final String _tableName = 'calibragem_adubo';
  
  CalibragemAduboRepository() {
    _initDb();
  }
  
  Future<void> _initDb() async {
    db = await _databaseHelper.database;
  }

  // Método para criar a tabela no banco de dados
  Future<void> criarTabela(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome_fertilizante TEXT,
        distancia REAL NOT NULL,
        linhas INTEGER NOT NULL,
        peso_coletado REAL NOT NULL,
        espacamento REAL NOT NULL,
        meta_kg_ha REAL NOT NULL,
        kg_por_metro REAL NOT NULL,
        kg_por_hectare REAL NOT NULL,
        diferenca_meta REAL NOT NULL,
        talhao_id TEXT,
        cultura_id TEXT,
        data_registro TEXT NOT NULL
      )
    ''');
  }

  // Método para salvar uma calibragem no banco de dados
  Future<int> salvar(CalibragemAduboModel calibragem) async {
    final db = await _databaseHelper.database;
    
    // Converter o modelo para Map
    final map = calibragem.toMap();
    
    try {
      // Verificar se já existe uma calibragem com esse ID
      final existingId = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
      
      if (existingId.isNotEmpty) {
        // Atualizar calibragem existente
        return await db.update(
          _tableName,
          map,
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } else {
        // Inserir nova calibragem
        return await db.insert(_tableName, map);
      }
    } catch (e) {
      print('Erro ao salvar calibragem: $e');
      return 0;
    }
  }

  // Método para buscar todas as calibragens
  Future<List<CalibragemAduboModel>> buscarTodos() async {
    final db = await _databaseHelper.database;
    
    final result = await db.query(_tableName, orderBy: 'data_registro DESC');
    
    return result.map((map) => CalibragemAduboModel.fromMap(map)).toList();
  }

  // Método para buscar calibragens por talhão
  Future<List<CalibragemAduboModel>> buscarPorTalhao(String talhaoId) async {
    final db = await _databaseHelper.database;
    
    final result = await db.query(
      _tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_registro DESC',
    );
    
    return result.map((map) => CalibragemAduboModel.fromMap(map)).toList();
  }

  // Método para buscar calibragens por cultura
  Future<List<CalibragemAduboModel>> buscarPorCultura(String culturaId) async {
    final db = await _databaseHelper.database;
    
    final result = await db.query(
      _tableName,
      where: 'cultura_id = ?',
      whereArgs: [culturaId],
      orderBy: 'data_registro DESC',
    );
    
    return result.map((map) => CalibragemAduboModel.fromMap(map)).toList();
  }

  // Método para excluir uma calibragem
  Future<int> excluir(String id) async {
    final db = await _databaseHelper.database;
    
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
