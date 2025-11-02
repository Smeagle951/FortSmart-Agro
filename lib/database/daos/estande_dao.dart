import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';

class EstandeDao {
  final AppDatabase _database = AppDatabase.instance;

  // Inserir avaliação de estande
  Future<void> inserirEstande({
    required String id,
    required String plantioId,
    required DateTime dataAvaliacao,
    required double comprimentoAmostradoM,
    required int linhasAmostradas,
    required int plantasContadas,
    int? dae,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('estande_avaliacao', {
      'id': id,
      'plantio_id': plantioId,
      'data_avaliacao': dataAvaliacao.toIso8601String(),
      'comprimento_amostrado_m': comprimentoAmostradoM,
      'linhas_amostradas': linhasAmostradas,
      'plantas_contadas': plantasContadas,
      'dae': dae,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  // Buscar avaliações por plantio
  Future<List<Map<String, dynamic>>> buscarAvaliacoesPlantio(String plantioId) async {
    final db = await _database.database;
    
    final rows = await db.query(
      'estande_avaliacao',
      where: 'plantio_id = ? AND deleted_at IS NULL',
      whereArgs: [plantioId],
      orderBy: 'data_avaliacao DESC',
    );
    
    return rows;
  }

  // Buscar DAE mais recente por plantio
  Future<int?> buscarDaeMaisRecente(String plantioId) async {
    final db = await _database.database;
    
    final result = await db.rawQuery(
      '''
      SELECT dae FROM estande_avaliacao
      WHERE plantio_id = ? AND deleted_at IS NULL AND dae IS NOT NULL
      ORDER BY date(data_avaliacao) DESC
      LIMIT 1
      ''',
      [plantioId],
    );
    
    if (result.isNotEmpty && result.first['dae'] != null) {
      return (result.first['dae'] as num).toInt();
    }
    
    return null;
  }

  // Calcular DAE automaticamente
  int? calcularDae({
    required double comprimentoAmostradoM,
    required int linhasAmostradas,
    required int plantasContadas,
  }) {
    if (comprimentoAmostradoM <= 0 || linhasAmostradas <= 0) {
      return null;
    }
    
    // DAE = (plantas contadas / (comprimento * linhas)) * 10.000
    final areaAmostrada = comprimentoAmostradoM * linhasAmostradas;
    if (areaAmostrada <= 0) return null;
    
    final plantasPorMetroQuadrado = plantasContadas / areaAmostrada;
    final dae = (plantasPorMetroQuadrado * 10000).round();
    
    return dae;
  }

  // Atualizar avaliação
  Future<void> atualizarEstande({
    required String id,
    required DateTime dataAvaliacao,
    required double comprimentoAmostradoM,
    required int linhasAmostradas,
    required int plantasContadas,
    int? dae,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'estande_avaliacao',
      {
        'data_avaliacao': dataAvaliacao.toIso8601String(),
        'comprimento_amostrado_m': comprimentoAmostradoM,
        'linhas_amostradas': linhasAmostradas,
        'plantas_contadas': plantasContadas,
        'dae': dae,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deletar avaliação (soft delete)
  Future<void> deletarEstande(String id) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'estande_avaliacao',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar estatísticas de estande por plantio
  Future<Map<String, dynamic>> buscarEstatisticasEstande(String plantioId) async {
    final db = await _database.database;
    
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_avaliacoes,
        AVG(dae) as dae_medio,
        MIN(dae) as dae_minimo,
        MAX(dae) as dae_maximo,
        AVG(plantas_contadas) as plantas_contadas_medio
      FROM estande_avaliacao
      WHERE plantio_id = ? AND deleted_at IS NULL
      ''',
      [plantioId],
    );
    
    return result.first;
  }

  // Buscar histórico de avaliações
  Future<List<Map<String, dynamic>>> buscarHistoricoAvaliacoes({
    String? plantioId,
    DateTime? dataIni,
    DateTime? dataFim,
  }) async {
    final db = await _database.database;
    
    String whereClause = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];
    
    if (plantioId != null) {
      whereClause += ' AND plantio_id = ?';
      whereArgs.add(plantioId);
    }
    
    if (dataIni != null) {
      whereClause += ' AND date(data_avaliacao) >= date(?)';
      whereArgs.add(dataIni.toIso8601String());
    }
    
    if (dataFim != null) {
      whereClause += ' AND date(data_avaliacao) <= date(?)';
      whereArgs.add(dataFim.toIso8601String());
    }
    
    final rows = await db.query(
      'estande_avaliacao',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'data_avaliacao DESC',
    );
    
    return rows;
  }

  // Verificar se plantio tem avaliações
  Future<bool> verificarPlantioComAvaliacoes(String plantioId) async {
    final db = await _database.database;
    
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM estande_avaliacao
      WHERE plantio_id = ? AND deleted_at IS NULL
      ''',
      [plantioId],
    );
    
    return (result.first['total'] as int) > 0;
  }
}
