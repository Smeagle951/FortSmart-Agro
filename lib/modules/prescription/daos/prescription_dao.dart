import 'package:sqflite/sqflite.dart';
import '../models/prescription_model.dart';
import '../../../database/app_database.dart';

class PrescriptionDao {
  static const String tableName = 'prescriptions';
  static const String bicosTableName = 'bicos_pulverizacao';

  /// Cria a tabela de prescrições
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        area_talhao REAL NOT NULL,
        tipo_aplicacao TEXT NOT NULL,
        equipamento TEXT,
        capacidade_tanque REAL NOT NULL,
        vazao_por_hectare REAL NOT NULL,
        dose_fracionada INTEGER NOT NULL,
        bico_selecionado TEXT,
        vazao_bico REAL NOT NULL,
        pressao_bico REAL NOT NULL,
        produtos TEXT NOT NULL,
        data_prescricao TEXT NOT NULL,
        operador TEXT NOT NULL,
        observacoes TEXT,
        status TEXT NOT NULL,
        volume_total_calda REAL NOT NULL,
        numero_tanques INTEGER NOT NULL,
        custo_total REAL NOT NULL,
        custo_por_hectare REAL NOT NULL,
        anexos TEXT,
        data_execucao TEXT,
        operador_execucao TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $bicosTableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        codigo TEXT NOT NULL,
        vazao_l_min REAL NOT NULL,
        pressao_bar REAL NOT NULL,
        cor TEXT NOT NULL,
        descricao TEXT NOT NULL,
        ativo INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Insere uma nova prescrição
  Future<String> insert(PrescriptionModel prescription) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final data = prescription.toMap()
      ..addAll({
        'created_at': now,
        'updated_at': now,
      });

    await db.insert(tableName, data);
    return prescription.id;
  }

  /// Atualiza uma prescrição existente
  Future<bool> update(PrescriptionModel prescription) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final data = prescription.toMap()
      ..addAll({
        'updated_at': now,
      });

    final result = await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [prescription.id],
    );

    return result > 0;
  }

  /// Busca uma prescrição por ID
  Future<PrescriptionModel?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PrescriptionModel.fromMap(maps.first);
  }

  /// Busca todas as prescrições
  Future<List<PrescriptionModel>> getAll() async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'data_prescricao DESC',
    );

    return maps.map((map) => PrescriptionModel.fromMap(map)).toList();
  }

  /// Busca prescrições por talhão
  Future<List<PrescriptionModel>> getByTalhao(String talhaoId) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_prescricao DESC',
    );

    return maps.map((map) => PrescriptionModel.fromMap(map)).toList();
  }

  /// Busca prescrições por status
  Future<List<PrescriptionModel>> getByStatus(StatusPrescricao status) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'data_prescricao DESC',
    );

    return maps.map((map) => PrescriptionModel.fromMap(map)).toList();
  }

  /// Busca prescrições por período
  Future<List<PrescriptionModel>> getByPeriod({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
    StatusPrescricao? status,
  }) async {
    final db = await AppDatabase.instance.database;
    
    String whereClause = 'data_prescricao BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      dataInicio.toIso8601String(),
      dataFim.toIso8601String(),
    ];

    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'data_prescricao DESC',
    );

    return maps.map((map) => PrescriptionModel.fromMap(map)).toList();
  }

  /// Deleta uma prescrição
  Future<bool> delete(String id) async {
    final db = await AppDatabase.instance.database;
    
    final result = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    return result > 0;
  }

  /// Atualiza o status de uma prescrição
  Future<bool> updateStatus(String id, StatusPrescricao status) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final result = await db.update(
      tableName,
      {
        'status': status.name,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return result > 0;
  }

  /// Marca prescrição como executada
  Future<bool> markAsExecuted(String id, String operadorExecucao) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final result = await db.update(
      tableName,
      {
        'status': StatusPrescricao.executada.name,
        'data_execucao': now,
        'operador_execucao': operadorExecucao,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return result > 0;
  }

  /// Busca estatísticas de prescrições
  Future<Map<String, dynamic>> getStatistics({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? talhaoId,
  }) async {
    final db = await AppDatabase.instance.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      whereClause += ' AND data_prescricao BETWEEN ? AND ?';
      whereArgs.addAll([dataInicio.toIso8601String(), dataFim.toIso8601String()]);
    }

    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }

    // Total de prescrições
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    final total = totalResult.first['total'] as int;

    // Prescrições por status
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM $tableName 
      WHERE $whereClause 
      GROUP BY status
    ''', whereArgs);

    // Custo total
    final custoResult = await db.rawQuery(
      'SELECT SUM(custo_total) as total FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    final custoTotal = custoResult.first['total'] as double? ?? 0.0;

    // Área total
    final areaResult = await db.rawQuery(
      'SELECT SUM(area_talhao) as total FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    final areaTotal = areaResult.first['total'] as double? ?? 0.0;

    return {
      'total_prescricoes': total,
      'custo_total': custoTotal,
      'area_total': areaTotal,
      'prescricoes_por_status': Map.fromEntries(
        statusResult.map((row) => MapEntry(
          row['status'] as String,
          row['count'] as int,
        )),
      ),
    };
  }

  // ===== OPERAÇÕES COM BICOS =====

  /// Insere um novo bico
  Future<String> insertBico(BicoPulverizacao bico) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final data = bico.toMap()
      ..addAll({
        'created_at': now,
        'updated_at': now,
      });

    await db.insert(bicosTableName, data);
    return bico.id;
  }

  /// Busca todos os bicos ativos
  Future<List<BicoPulverizacao>> getAllBicos() async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      bicosTableName,
      where: 'ativo = 1',
      orderBy: 'nome ASC',
    );

    return maps.map((map) => BicoPulverizacao.fromMap(map)).toList();
  }

  /// Busca bico por ID
  Future<BicoPulverizacao?> getBicoById(String id) async {
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      bicosTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return BicoPulverizacao.fromMap(maps.first);
  }

  /// Atualiza um bico
  Future<bool> updateBico(BicoPulverizacao bico) async {
    final db = await AppDatabase.instance.database;
    
    final now = DateTime.now().toIso8601String();
    final data = bico.toMap()
      ..addAll({
        'updated_at': now,
      });

    final result = await db.update(
      bicosTableName,
      data,
      where: 'id = ?',
      whereArgs: [bico.id],
    );

    return result > 0;
  }

  /// Deleta um bico
  Future<bool> deleteBico(String id) async {
    final db = await AppDatabase.instance.database;
    
    final result = await db.delete(
      bicosTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    return result > 0;
  }

  /// Inicializa dados padrão de bicos
  Future<void> initializeDefaultBicos() async {
    final bicos = [
      BicoPulverizacao(
        id: 'bico_001',
        nome: 'Bico Leque 110°',
        codigo: '110-02',
        vazaoLMin: 0.8,
        pressaoBar: 2.0,
        cor: 'Azul',
        descricao: 'Bico leque padrão para herbicidas',
        ativo: true,
      ),
      BicoPulverizacao(
        id: 'bico_002',
        nome: 'Bico Leque 80°',
        codigo: '080-03',
        vazaoLMin: 1.2,
        pressaoBar: 2.5,
        cor: 'Verde',
        descricao: 'Bico leque para fungicidas',
        ativo: true,
      ),
      BicoPulverizacao(
        id: 'bico_003',
        nome: 'Bico Cone 80°',
        codigo: 'CONE-04',
        vazaoLMin: 1.5,
        pressaoBar: 3.0,
        cor: 'Vermelho',
        descricao: 'Bico cone para inseticidas',
        ativo: true,
      ),
      BicoPulverizacao(
        id: 'bico_004',
        nome: 'Bico Leque 110°',
        codigo: '110-05',
        vazaoLMin: 2.0,
        pressaoBar: 2.0,
        cor: 'Amarelo',
        descricao: 'Bico leque para fertilizantes',
        ativo: true,
      ),
    ];

    for (final bico in bicos) {
      await insertBico(bico);
    }
  }
}
