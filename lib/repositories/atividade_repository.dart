import 'package:sqflite/sqflite.dart';
import '../models/integration/atividade_agricola.dart';
import '../database/app_database.dart';

/// Repositório para gerenciar atividades agrícolas no banco de dados
class AtividadeRepository {
  final String _tabela = 'atividades_agricolas';

  /// Insere uma nova atividade agrícola no banco de dados
  Future<void> inserir(AtividadeAgricola atividade) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      _tabela,
      atividade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza uma atividade agrícola existente
  Future<void> atualizar(AtividadeAgricola atividade) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      _tabela,
      atividade.toMap(),
      where: 'id = ?',
      whereArgs: [atividade.id],
    );
  }

  /// Exclui uma atividade agrícola
  Future<void> excluir(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca uma atividade específica por ID
  Future<AtividadeAgricola?> obterPorId(String id) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return AtividadeAgricola.fromMap(maps.first);
  }

  /// Busca todas as atividades agrícolas
  Future<List<AtividadeAgricola>> listarTodas() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(_tabela);

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por tipo de atividade
  Future<List<AtividadeAgricola>> listarPorTipo(TipoAtividade tipo) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'tipoAtividade = ?',
      whereArgs: [tipo.name],
    );

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por talhão
  Future<List<AtividadeAgricola>> listarPorTalhao(String talhaoId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'talhaoId = ?',
      whereArgs: [talhaoId],
    );

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por safra
  Future<List<AtividadeAgricola>> listarPorSafra(String safraId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'safraId = ?',
      whereArgs: [safraId],
    );

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por cultura
  Future<List<AtividadeAgricola>> listarPorCultura(String culturaId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'culturaId = ?',
      whereArgs: [culturaId],
    );

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por contexto completo (talhão + safra + cultura)
  Future<List<AtividadeAgricola>> listarPorContexto({
    required String talhaoId,
    required String safraId,
    required String culturaId,
  }) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'talhaoId = ? AND safraId = ? AND culturaId = ?',
      whereArgs: [talhaoId, safraId, culturaId],
    );

    return List.generate(maps.length, (i) {
      return AtividadeAgricola.fromMap(maps[i]);
    });
  }

  /// Busca atividades por detalhesId (para conectar com registros específicos)
  Future<AtividadeAgricola?> obterPorDetalhesId(String detalhesId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tabela,
      where: 'detalhesId = ?',
      whereArgs: [detalhesId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return AtividadeAgricola.fromMap(maps.first);
  }
  
  /// Atualiza o ID de detalhes de uma atividade existente
  /// Útil quando o registro é criado antes do objeto relacionado
  Future<void> atualizarDetalhesId(String atividadeId, String novoDetalhesId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      _tabela,
      {'detalhesId': novoDetalhesId},
      where: 'id = ?',
      whereArgs: [atividadeId],
    );
  }
}
