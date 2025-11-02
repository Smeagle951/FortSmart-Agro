import 'package:sqflite/sqflite.dart';
import '../models/plantio_model.dart';
import '../models/lista_plantio_item.dart';
import '../../database/app_database.dart';

class PlantioDao {
  final AppDatabase _database = AppDatabase.instance;

  // Inserir novo plantio
  Future<void> inserirPlantio(Plantio plantio) async {
    // ✅ Sem validações de população/espaçamento - dados vêm do Estande!
    final db = await _database.database;
    await db.insert('plantio', plantio.toMap());
  }

  // Atualizar plantio existente
  Future<void> atualizarPlantio(Plantio plantio) async {
    // ✅ Sem validações de população/espaçamento - dados vêm do Estande!
    final db = await _database.database;
    await db.update(
      'plantio',
      plantio.toMap(),
      where: 'id = ?',
      whereArgs: [plantio.id],
    );
  }

  // Soft delete de plantio
  Future<void> deletarPlantio(String plantioId) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'plantio',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [plantioId],
    );
  }

  // Buscar plantio por ID
  Future<Plantio?> buscarPlantioPorId(String plantioId) async {
    final db = await _database.database;
    final rows = await db.query(
      'plantio',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [plantioId],
    );
    
    if (rows.isEmpty) return null;
    return Plantio.fromMap(rows.first);
  }

  // Listar todos os plantios (sem filtros)
  Future<List<Plantio>> listarTodosPlantios() async {
    final db = await _database.database;
    final rows = await db.query(
      'plantio',
      where: 'deleted_at IS NULL',
      orderBy: 'data_plantio DESC',
    );
    
    return rows.map((row) => Plantio.fromMap(row)).toList();
  }

  // Listar plantios com filtros
  Future<List<Plantio>> listarPlantiosComFiltros({
    String? cultura,
    String? talhaoId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    final db = await _database.database;
    
    String whereClause = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];
    
    if (cultura != null) {
      whereClause += ' AND cultura = ?';
      whereArgs.add(cultura);
    }
    
    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (dataIni != null) {
      whereClause += ' AND date(data_plantio) >= date(?)';
      whereArgs.add(dataIni.toIso8601String());
    }
    
    if (dataFim != null) {
      whereClause += ' AND date(data_plantio) <= date(?)';
      whereArgs.add(dataFim.toIso8601String());
    }
    
    final rows = await db.query(
      'plantio',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'data_plantio DESC',
    );
    
    return rows.map((row) => Plantio.fromMap(row)).toList();
  }

  // Listar itens da lista de plantio (view consolidada)
  Future<List<ListaPlantioItem>> listarListaPlantio({
    String? cultura,
    String? talhaoId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    final db = await _database.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (cultura != null) {
      whereClause += ' AND cultura = ?';
      whereArgs.add(cultura);
    }
    
    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (dataIni != null) {
      whereClause += ' AND date(data_plantio) >= date(?)';
      whereArgs.add(dataIni.toIso8601String());
    }
    
    if (dataFim != null) {
      whereClause += ' AND date(data_plantio) <= date(?)';
      whereArgs.add(dataFim.toIso8601String());
    }
    
    final rows = await db.rawQuery(
      '''
      SELECT id, variedade, cultura, talhao_nome, subarea_nome, data_plantio,
             populacao_por_m, populacao_ha, espacamento_cm, custo_ha, dae
      FROM vw_lista_plantio
      WHERE $whereClause
      ORDER BY date(data_plantio) DESC
      ''',
      whereArgs,
    );
    
    return rows.map((row) => ListaPlantioItem.fromMap(row)).toList();
  }

  // Duplicar plantio
  Future<String> duplicarPlantio(String plantioId) async {
    final plantioOriginal = await buscarPlantioPorId(plantioId);
    if (plantioOriginal == null) {
      throw Exception('Plantio não encontrado');
    }
    
    final novoId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    
    final plantioDuplicado = Plantio(
      id: novoId,
      talhaoId: plantioOriginal.talhaoId,
      subareaId: plantioOriginal.subareaId,
      cultura: plantioOriginal.cultura,
      variedade: plantioOriginal.variedade,
      dataPlantio: now,
      hectares: plantioOriginal.hectares, // Copiar hectares se houver
      observacao: 'Duplicado de ${plantioOriginal.id}',
      createdAt: now,
      updatedAt: now,
    );
    
    await inserirPlantio(plantioDuplicado);
    return novoId;
  }

  // Buscar estatísticas de plantio
  Future<Map<String, dynamic>> buscarEstatisticasPlantio({
    String? cultura,
    String? talhaoId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    final db = await _database.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (cultura != null) {
      whereClause += ' AND cultura = ?';
      whereArgs.add(cultura);
    }
    
    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (dataIni != null) {
      whereClause += ' AND date(data_plantio) >= date(?)';
      whereArgs.add(dataIni.toIso8601String());
    }
    
    if (dataFim != null) {
      whereClause += ' AND date(data_plantio) <= date(?)';
      whereArgs.add(dataFim.toIso8601String());
    }
    
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_plantios,
        AVG(populacao_ha) as media_populacao_ha,
        AVG(custo_ha) as media_custo_ha,
        SUM(CASE WHEN custo_ha IS NOT NULL THEN 1 ELSE 0 END) as plantios_com_custo
      FROM vw_lista_plantio
      WHERE $whereClause
      ''',
      whereArgs,
    );
    
    return result.first;
  }

  // Verificar se talhão/subárea tem área válida
  Future<bool> verificarAreaValida(String talhaoId, String? subareaId) async {
    final db = await _database.database;
    
    if (subareaId != null) {
      final result = await db.rawQuery(
        'SELECT area_ha FROM subarea WHERE id = ? AND deleted_at IS NULL',
        [subareaId],
      );
      if (result.isNotEmpty) {
        return (result.first['area_ha'] as num) > 0;
      }
    }
    
    final result = await db.rawQuery(
      'SELECT area FROM talhao_safra WHERE id = ?',
      [talhaoId],
    );
    if (result.isNotEmpty) {
      return (result.first['area'] as num) > 0;
    }
    
    return false;
  }
}
