import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/experimento_talhao_model.dart';
import '../../models/subarea_experimento_model.dart';
import '../../models/drawing_polygon_model.dart';
import 'subarea_dao.dart';

class ExperimentoDao {
  static const String _tableName = 'experimentos';
  final SubareaDao _subareaDao = SubareaDao();

  // Inserir experimento
  Future<String> inserirExperimento(Experimento experimento) async {
    final db = await AppDatabase.instance.database;
    
    final experimentoMap = experimento.toMap();
    await db.insert(_tableName, experimentoMap);
    
    // Inserir subáreas associadas
    for (final subarea in experimento.subareas) {
      await _subareaDao.inserirSubarea(subarea);
    }
    
    return experimento.id;
  }

  // Atualizar experimento
  Future<int> atualizarExperimento(Experimento experimento) async {
    final db = await AppDatabase.instance.database;
    
    final experimentoMap = experimento.toMap();
    experimentoMap['atualizado_em'] = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      experimentoMap,
      where: 'id = ?',
      whereArgs: [experimento.id],
    );
  }

  // Remover experimento
  Future<int> removerExperimento(String id) async {
    final db = await AppDatabase.instance.database;
    
    // Remover subáreas associadas
    final subareas = await _subareaDao.buscarPorTalhao(int.parse(id.split('_').last));
    for (final subarea in subareas) {
      if (subarea.id != null) {
        await _subareaDao.removerSubarea(subarea.id!);
      }
    }
    
    // Remover experimento
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar experimento por ID
  Future<Experimento?> buscarPorId(String id) async {
    final db = await AppDatabase.instance.database;
    
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    // Buscar subáreas associadas
    final talhaoId = result.first['talhao_id'] as String;
    final subareas = await _subareaDao.buscarPorTalhao(int.parse(talhaoId));
    
    return Experimento.fromMap(result.first, subareas: subareas);
  }

  // Buscar experimentos por talhão
  Future<List<Experimento>> buscarPorTalhao(String talhaoId) async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'criado_em DESC',
    );
    
    final experimentos = <Experimento>[];
    for (final result in results) {
      final subareas = await _subareaDao.buscarPorTalhao(int.parse(talhaoId));
      experimentos.add(Experimento.fromMap(result, subareas: subareas));
    }
    
    return experimentos;
  }

  // Buscar todos os experimentos ativos
  Future<List<Experimento>> buscarTodosAtivos() async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: ['ativo'],
      orderBy: 'criado_em DESC',
    );
    
    final experimentos = <Experimento>[];
    for (final result in results) {
      final talhaoId = result['talhao_id'] as String;
      final subareas = await _subareaDao.buscarPorTalhao(int.parse(talhaoId));
      experimentos.add(Experimento.fromMap(result, subareas: subareas));
    }
    
    return experimentos;
  }

  // Buscar experimentos por status
  Future<List<Experimento>> buscarPorStatus(String status) async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'criado_em DESC',
    );
    
    final experimentos = <Experimento>[];
    for (final result in results) {
      final talhaoId = result['talhao_id'] as String;
      final subareas = await _subareaDao.buscarPorTalhao(int.parse(talhaoId));
      experimentos.add(Experimento.fromMap(result, subareas: subareas));
    }
    
    return experimentos;
  }

  // Buscar experimentos por cultura
  Future<List<Experimento>> buscarPorCultura(String cultura) async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      where: 'cultura = ?',
      whereArgs: [cultura],
      orderBy: 'criado_em DESC',
    );
    
    final experimentos = <Experimento>[];
    for (final result in results) {
      final talhaoId = result['talhao_id'] as String;
      final subareas = await _subareaDao.buscarPorTalhao(int.parse(talhaoId));
      experimentos.add(Experimento.fromMap(result, subareas: subareas));
    }
    
    return experimentos;
  }

  // Verificar se nome existe
  Future<bool> nomeExiste(String nome, {String? excludeId}) async {
    final db = await AppDatabase.instance.database;
    
    String whereClause = 'nome = ?';
    List<dynamic> whereArgs = [nome];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isNotEmpty;
  }

  // Obter estatísticas dos experimentos
  Future<Map<String, dynamic>> obterEstatisticas() async {
    final db = await AppDatabase.instance.database;
    
    // Total de experimentos
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $_tableName');
    final total = totalResult.first['total'] as int;
    
    // Experimentos ativos
    final ativosResult = await db.rawQuery(
      'SELECT COUNT(*) as ativos FROM $_tableName WHERE status = ?',
      ['ativo']
    );
    final ativos = ativosResult.first['ativos'] as int;
    
    // Experimentos concluídos
    final concluidosResult = await db.rawQuery(
      'SELECT COUNT(*) as concluidos FROM $_tableName WHERE status = ?',
      ['concluido']
    );
    final concluidos = concluidosResult.first['concluidos'] as int;
    
    // Experimentos cancelados
    final canceladosResult = await db.rawQuery(
      'SELECT COUNT(*) as cancelados FROM $_tableName WHERE status = ?',
      ['cancelado']
    );
    final cancelados = canceladosResult.first['cancelados'] as int;
    
    return {
      'total': total,
      'ativos': ativos,
      'concluidos': concluidos,
      'cancelados': cancelados,
    };
  }
}
