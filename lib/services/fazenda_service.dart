import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/fazenda_model.dart';
import 'package:latlong2/latlong.dart';

/// Serviço para gerenciar fazendas
class FazendaService {
  final AppDatabase _database = AppDatabase();
  final String fazendasTable = 'fazendas';

  /// Garante que a tabela de fazendas existe
  Future<void> _ensureTableExists() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $fazendasTable (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        endereco TEXT,
        cidade TEXT,
        estado TEXT,
        pais TEXT,
        area REAL,
        latitude REAL,
        longitude REAL,
        proprietario TEXT,
        contato TEXT,
        observacoes TEXT,
        dataCriacao TEXT,
        dataAtualizacao TEXT
      )
    ''');
  }

  /// Insere uma nova fazenda no banco de dados
  Future<void> inserir(FazendaModel fazenda) async {
    await _ensureTableExists();
    final db = await _database.database;
    await db.insert(
      fazendasTable,
      fazenda.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza uma fazenda existente no banco de dados
  Future<void> atualizar(FazendaModel fazenda) async {
    await _ensureTableExists();
    final db = await _database.database;
    await db.update(
      fazendasTable,
      fazenda.toMap(),
      where: 'id = ?',
      whereArgs: [fazenda.id],
    );
  }

  /// Exclui uma fazenda do banco de dados
  Future<void> excluir(String id) async {
    await _ensureTableExists();
    final db = await _database.database;
    await db.delete(
      fazendasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém uma fazenda pelo ID
  Future<FazendaModel?> obterPorId(String id) async {
    await _ensureTableExists();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      fazendasTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final map = maps.first;
    
    // Cria a localização se os campos de latitude e longitude existirem
    LatLng? localizacao;
    if (map['latitude'] != null && map['longitude'] != null) {
      localizacao = LatLng(map['latitude'], map['longitude']);
    }
    
    return FazendaModel.fromMap(map);
  }

  /// Lista todas as fazendas
  Future<List<FazendaModel>> listarTodas() async {
    await _ensureTableExists();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(fazendasTable);

    return List.generate(maps.length, (i) {
      return FazendaModel.fromMap(maps[i]);
    });
  }

  /// Busca fazendas por nome
  Future<List<FazendaModel>> buscarPorNome(String termo) async {
    await _ensureTableExists();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      fazendasTable,
      where: 'nome LIKE ?',
      whereArgs: ['%$termo%'],
    );

    return List.generate(maps.length, (i) {
      return FazendaModel.fromMap(maps[i]);
    });
  }

  /// Calcula a área total de todas as fazendas
  Future<double> calcularAreaTotal() async {
    final fazendas = await listarTodas();
    double areaTotal = 0;
    
    for (final fazenda in fazendas) {
      if (fazenda.area != null) {
        areaTotal += fazenda.area!;
      }
    }
    
    return areaTotal;
  }

  /// Obtém o número total de fazendas
  Future<int> contarFazendas() async {
    await _ensureTableExists();
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $fazendasTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
