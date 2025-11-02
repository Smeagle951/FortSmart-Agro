import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/app_database.dart';
import '../models/fertilizer_calibration.dart';
import '../utils/logger.dart';

/// Repositório para gerenciar calibrações de fertilizantes
class FertilizerCalibrationRepository {
  final AppDatabase _database = AppDatabase();
  
  static const String tableName = 'fertilizer_calibrations';

  /// Inicializa a tabela no banco de dados com garantia de criação
  Future<void> initialize() async {
    try {
      Logger.info('🔧 Inicializando repositório de calibração de fertilizantes...');
      
      final db = await _database.database;
      
      // Verifica se a tabela já existe
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      
      if (tables.isEmpty) {
        Logger.warning('⚠️ Tabela de calibração de fertilizantes não encontrada. Criando...');
        await _createTable(db);
        Logger.info('✅ Tabela de calibração de fertilizantes criada com sucesso');
      } else {
        Logger.info('✅ Tabela de calibração de fertilizantes já existe');
      }
      
      // Verifica a integridade da tabela
      await _verifyTableIntegrity(db);
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar repositório de calibração: $e');
      
      // Tenta recriar a tabela em caso de erro
      try {
        Logger.warning('🔄 Tentando recriar tabela de calibração...');
        final db = await _database.database;
        await _createTable(db);
        Logger.info('✅ Tabela recriada com sucesso após erro');
      } catch (recreateError) {
        Logger.error('❌ Falha ao recriar tabela: $recreateError');
        throw Exception('Não foi possível inicializar o repositório de calibração: $recreateError');
      }
    }
  }

  /// Cria a tabela de calibração de fertilizantes
  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        fertilizer_name TEXT NOT NULL,
        granulometry REAL NOT NULL,
        expected_width REAL,
        spacing REAL NOT NULL,
        weights TEXT NOT NULL,
        operator TEXT NOT NULL,
        machine TEXT,
        distribution_system TEXT,
        small_paddle_value REAL,
        large_paddle_value REAL,
        rpm REAL,
        speed REAL,
        density REAL,
        distance_traveled REAL,
        collection_time REAL,
        collection_type TEXT,
        desired_rate REAL,
        real_application_rate REAL,
        error_percentage REAL,
        error_status TEXT,
        coefficient_of_variation REAL,
        cv_status TEXT,
        real_width REAL,
        width_status TEXT,
        average_weight REAL,
        standard_deviation REAL,
        effective_range_indices TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Criar índices para melhor performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_date ON $tableName (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_operator ON $tableName (operator)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_machine ON $tableName (machine)');
  }

  /// Verifica a integridade da tabela
  Future<void> _verifyTableIntegrity(Database db) async {
    try {
      // Verifica se a tabela tem a estrutura correta
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      final requiredColumns = {
        'id', 'fertilizer_name', 'granulometry', 'spacing', 'weights',
        'operator', 'date', 'coefficient_of_variation', 'cv_status',
        'real_width', 'width_status', 'average_weight', 'standard_deviation'
      };
      
      final missingColumns = requiredColumns.difference(columnNames);
      if (missingColumns.isNotEmpty) {
        Logger.warning('⚠️ Colunas ausentes na tabela: $missingColumns');
        Logger.info('🔄 Recriando tabela com estrutura completa...');
        await db.execute('DROP TABLE IF EXISTS $tableName');
        await _createTable(db);
        Logger.info('✅ Tabela recriada com estrutura completa');
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar integridade da tabela: $e');
    }
  }

  /// Salva uma calibração com verificação de integridade
  Future<void> save(FertilizerCalibration calibration) async {
    try {
      // Garante que o repositório está inicializado
      await initialize();
      
      final db = await _database.database;
      
      // Verificar e corrigir schema da tabela se necessário
      await _ensureTableSchema(db);
      
      final result = await db.insert(
        tableName,
        calibration.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Calibração salva com sucesso. ID: ${calibration.id}');
    } catch (e) {
      Logger.error('❌ Erro ao salvar calibração: $e');
      
      // Se erro for de coluna faltante, tentar corrigir e salvar novamente
      if (e.toString().contains('no column named')) {
        Logger.info('🔧 Tentando corrigir schema da tabela...');
        try {
          await _fixTableSchema();
          final db = await _database.database;
          await db.insert(
            tableName,
            calibration.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          Logger.info('✅ Calibração salva após correção do schema');
          return;
        } catch (fixError) {
          Logger.error('❌ Erro ao corrigir schema: $fixError');
        }
      }
      
      throw Exception('Falha ao salvar calibração: $e');
    }
  }

  /// Garante que a tabela tenha o schema correto
  Future<void> _ensureTableSchema(Database db) async {
    try {
      // Verificar se as colunas necessárias existem
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      // Adicionar colunas faltantes
      if (!columnNames.contains('collection_time')) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN collection_time REAL');
        Logger.info('✅ Coluna collection_time adicionada');
      }
      
      if (!columnNames.contains('collection_type')) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN collection_type TEXT');
        Logger.info('✅ Coluna collection_type adicionada');
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar schema: $e');
    }
  }

  /// Corrige o schema da tabela forçadamente
  Future<void> _fixTableSchema() async {
    try {
      final db = await _database.database;
      
      // Tentar adicionar colunas faltantes
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN collection_time REAL');
        Logger.info('✅ Coluna collection_time adicionada');
      } catch (e) {
        Logger.info('ℹ️ Coluna collection_time já existe ou erro: $e');
      }
      
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN collection_type TEXT');
        Logger.info('✅ Coluna collection_type adicionada');
      } catch (e) {
        Logger.info('ℹ️ Coluna collection_type já existe ou erro: $e');
      }
    } catch (e) {
      Logger.error('❌ Erro ao corrigir schema: $e');
      rethrow;
    }
  }

  /// Obtém todas as calibrações
  Future<List<FertilizerCalibration>> getAll() async {
    try {
      // Garante que o repositório está inicializado
      await initialize();
      
      final db = await _database.database;
      
      final result = await db.query(
        tableName,
        orderBy: 'date DESC',
      );
      
      Logger.info('✅ ${result.length} calibrações carregadas');
      return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar calibrações: $e');
      return [];
    }
  }

  /// Obtém uma calibração por ID
  Future<FertilizerCalibration?> getById(String id) async {
    try {
      // Garante que o repositório está inicializado
      await initialize();
      
      final db = await _database.database;
      
      final result = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) {
        Logger.warning('⚠️ Calibração com ID $id não encontrada');
        return null;
      }
      
      Logger.info('✅ Calibração com ID $id carregada');
      return FertilizerCalibration.fromMap(result.first);
    } catch (e) {
      Logger.error('❌ Erro ao carregar calibração por ID: $e');
      return null;
    }
  }

  /// Obtém calibrações por fertilizante
  Future<List<FertilizerCalibration>> getByFertilizer(String fertilizerName) async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'fertilizer_name = ?',
      whereArgs: [fertilizerName],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }

  /// Obtém calibrações por operador
  Future<List<FertilizerCalibration>> getByOperator(String operator) async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'operator = ?',
      whereArgs: [operator],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }

  /// Obtém calibrações por período
  Future<List<FertilizerCalibration>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }

  /// Obtém estatísticas das calibrações
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _database.database;
    
    // Total de calibrações
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $tableName');
    final total = totalResult.first['total'] as int;
    
    // Média do CV
    final cvResult = await db.rawQuery('SELECT AVG(coefficient_of_variation) as avg_cv FROM $tableName');
    final avgCV = (cvResult.first['avg_cv'] as num?)?.toDouble() ?? 0.0;
    
    // Distribuição por status do CV
    final cvStatusResult = await db.rawQuery('''
      SELECT cv_status, COUNT(*) as count 
      FROM $tableName 
      GROUP BY cv_status
    ''');
    
    final cvStatusDistribution = <String, int>{};
    for (final row in cvStatusResult) {
      cvStatusDistribution[row['cv_status'] as String] = row['count'] as int;
    }
    
    // Fertilizantes mais usados
    final fertilizerResult = await db.rawQuery('''
      SELECT fertilizer_name, COUNT(*) as count 
      FROM $tableName 
      GROUP BY fertilizer_name 
      ORDER BY count DESC 
      LIMIT 5
    ''');
    
    final topFertilizers = <String, int>{};
    for (final row in fertilizerResult) {
      topFertilizers[row['fertilizer_name'] as String] = row['count'] as int;
    }
    
    return {
      'total': total,
      'averageCV': avgCV,
      'cvStatusDistribution': cvStatusDistribution,
      'topFertilizers': topFertilizers,
    };
  }

  /// Deleta uma calibração
  Future<void> delete(String id) async {
    final db = await _database.database;
    
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deleta todas as calibrações
  Future<void> deleteAll() async {
    final db = await _database.database;
    
    await db.delete(tableName);
  }

  /// Busca calibrações por texto
  Future<List<FertilizerCalibration>> search(String query) async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'fertilizer_name LIKE ? OR operator LIKE ? OR machine LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }

  /// Obtém calibrações com CV crítico
  Future<List<FertilizerCalibration>> getCriticalCalibrations() async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'cv_status = ?',
      whereArgs: ['Crítico'],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }

  /// Obtém calibrações com faixa incompleta
  Future<List<FertilizerCalibration>> getIncompleteWidthCalibrations() async {
    final db = await _database.database;
    
    final result = await db.query(
      tableName,
      where: 'width_status = ?',
      whereArgs: ['Incompleta'],
      orderBy: 'date DESC',
    );
    
    return result.map((row) => FertilizerCalibration.fromMap(row)).toList();
  }
} 