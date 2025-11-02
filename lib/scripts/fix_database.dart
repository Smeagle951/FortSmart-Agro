import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Script para corrigir problemas de banco de dados
class DatabaseFixer {
  static Future<void> fixFertilizerCalibrationsTable() async {
    try {
      Logger.info('🔧 Iniciando correção da tabela fertilizer_calibrations...');
      
      // Obter caminho do banco
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'fortsmart_agro.db');
      
      // Abrir banco
      final db = await openDatabase(path, version: 47);
      
      // Verificar se a tabela existe
      final tableExists = await db.rawQuery('''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='fertilizer_calibrations'
      ''');
      
      if (tableExists.isNotEmpty) {
        Logger.info('📋 Tabela fertilizer_calibrations existe, verificando colunas...');
        
        // Verificar colunas da tabela
        final columns = await db.rawQuery('PRAGMA table_info(fertilizer_calibrations)');
        final columnNames = columns.map((col) => col['name'] as String).toList();
        
        Logger.info('📋 Colunas encontradas: $columnNames');
        
        // Verificar se collection_time existe
        if (!columnNames.contains('collection_time')) {
          Logger.info('⚠️ Coluna collection_time não encontrada, adicionando...');
          await db.execute('ALTER TABLE fertilizer_calibrations ADD COLUMN collection_time REAL');
          Logger.info('✅ Coluna collection_time adicionada');
        } else {
          Logger.info('✅ Coluna collection_time já existe');
        }
        
        // Verificar se collection_type existe
        if (!columnNames.contains('collection_type')) {
          Logger.info('⚠️ Coluna collection_type não encontrada, adicionando...');
          await db.execute('ALTER TABLE fertilizer_calibrations ADD COLUMN collection_type TEXT');
          Logger.info('✅ Coluna collection_type adicionada');
        } else {
          Logger.info('✅ Coluna collection_type já existe');
        }
      } else {
        Logger.info('📋 Tabela fertilizer_calibrations não existe, criando...');
        
        // Criar tabela completa
        await db.execute('''
          CREATE TABLE IF NOT EXISTS fertilizer_calibrations (
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
        
        // Criar índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_date ON fertilizer_calibrations (date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_operator ON fertilizer_calibrations (operator)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_machine ON fertilizer_calibrations (machine)');
        
        Logger.info('✅ Tabela fertilizer_calibrations criada com sucesso');
      }
      
      await db.close();
      Logger.info('✅ Correção do banco de dados concluída!');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir banco de dados: $e');
      rethrow;
    }
  }
  
  /// Testa se a tabela está funcionando corretamente
  static Future<void> testTable() async {
    try {
      Logger.info('🧪 Testando tabela fertilizer_calibrations...');
      
      final appDatabase = AppDatabase();
      final db = await appDatabase.database;
      
      // Testar inserção de dados de exemplo
      final testData = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'fertilizer_name': 'Teste',
        'granulometry': 1.0,
        'expected_width': 27.0,
        'spacing': 0.5,
        'weights': '[1.0,2.0,3.0]',
        'operator': 'Teste',
        'machine': 'Teste',
        'distribution_system': 'Teste',
        'small_paddle_value': 1.0,
        'large_paddle_value': 2.0,
        'rpm': 100.0,
        'speed': 6.0,
        'density': 1.0,
        'distance_traveled': 100.0,
        'collection_time': null, // Teste com NULL
        'collection_type': 'distance',
        'desired_rate': 200.0,
        'real_application_rate': 200.0,
        'error_percentage': 0.0,
        'error_status': 'OK',
        'coefficient_of_variation': 5.0,
        'cv_status': 'Excelente',
        'real_width': 27.0,
        'width_status': 'OK',
        'average_weight': 2.0,
        'standard_deviation': 0.5,
        'effective_range_indices': '[]',
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await db.insert('fertilizer_calibrations', testData);
      Logger.info('✅ Teste de inserção bem-sucedido. ID: $result');
      
      // Limpar dados de teste
      await db.delete('fertilizer_calibrations', where: 'id = ?', whereArgs: [testData['id']]);
      Logger.info('✅ Dados de teste removidos');
      
    } catch (e) {
      Logger.error('❌ Erro no teste da tabela: $e');
      rethrow;
    }
  }
}
