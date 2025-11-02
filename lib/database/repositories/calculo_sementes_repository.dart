import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/calculo_sementes_model.dart';

class CalculoSementesRepository {
  // Expor o banco de dados para uso em outros repositórios
  Database? _db;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final String _tableName = 'calculo_sementes';
  
  CalculoSementesRepository() {
    _initDb();
  }
  
  Future<void> _initDb() async {
    _db = await _databaseHelper.database;
  }
  
  // Getter para acessar o banco de dados com segurança
  Future<Database> get db async {
    if (_db == null) {
      _db = await _databaseHelper.database;
    }
    return _db!;
  }

  // Método para criar a tabela no banco de dados
  Future<void> criarTabela(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        id_talhao TEXT,
        id_safra TEXT,
        id_plantio TEXT,
        espacamento_cm REAL,
        populacao_desejada INTEGER,
        germinacao_percent REAL,
        pureza_percent REAL,
        sementes_por_metro REAL,
        sementes_por_hectare REAL,
        peso_mil_sementes REAL,
        total_sementes INTEGER,
        total_kg REAL,
        origem_calculo TEXT,
        data_criacao TEXT
      )
    ''');
  }

  // Método para salvar um cálculo de sementes
  Future<bool> salvar(CalculoSementesModel calculo) async {
    try {
      final database = await db;
      
      // Verificar se já existe um registro com este ID
      final existente = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [calculo.id],
      );
      
      if (existente.isNotEmpty) {
        // Atualizar registro existente
        await database.update(
          _tableName,
          calculo.toMap(),
          where: 'id = ?',
          whereArgs: [calculo.id],
        );
      } else {
        // Inserir novo registro
        await database.insert(_tableName, calculo.toMap());
      }
      
      return true;
    } catch (e) {
      print('Erro ao salvar cálculo de sementes: $e');
      return false;
    }
  }

  // Método para buscar um cálculo pelo ID
  Future<CalculoSementesModel?> buscarPorId(String id) async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> maps = await database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return CalculoSementesModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar cálculo de sementes: $e');
      return null;
    }
  }

  // Método para listar todos os cálculos
  Future<List<CalculoSementesModel>> listarTodos() async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> maps = await database.query(
        _tableName,
        orderBy: 'data_criacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalculoSementesModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar cálculos de sementes: $e');
      return [];
    }
  }

  // Método para listar cálculos por talhão
  Future<List<CalculoSementesModel>> listarPorTalhao(String talhaoId) async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> maps = await database.query(
        _tableName,
        where: 'id_talhao = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_criacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalculoSementesModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar cálculos por talhão: $e');
      return [];
    }
  }

  // Método para excluir um cálculo
  Future<bool> excluir(String id) async {
    try {
      final database = await db;
      await database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Erro ao excluir cálculo de sementes: $e');
      return false;
    }
  }
}
