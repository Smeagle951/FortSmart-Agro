import 'package:sqflite/sqflite.dart';
import '../../utils/logger.dart';

/// Classe para gerenciar a tabela de plantios
class PlantingsTable {
  static const String tableName = 'plantings';
  
  /// Cria a tabela de plantios
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        property_id TEXT NOT NULL,
        plot_id TEXT NOT NULL,
        planting_date TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        variety TEXT,
        seed_quantity REAL,
        seed_unit TEXT,
        spacing_between_rows REAL,
        spacing_between_plants REAL,
        planting_depth REAL,
        fertilizer_used TEXT,
        fertilizer_quantity REAL,
        fertilizer_unit TEXT,
        soil_preparation_method TEXT,
        planting_method TEXT,
        expected_harvest_date TEXT,
        notes TEXT,
        user_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        sync_date TEXT,
        sync_error TEXT,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
    
    // Criar índices para melhorar a performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_property ON $tableName (property_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_plot ON $tableName (plot_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_date ON $tableName (planting_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_sync ON $tableName (sync_status)');
    
    Logger.info('Tabela $tableName criada com sucesso');
  }
  
  /// Verifica se a tabela existe e tem a estrutura correta
  static Future<bool> checkTableStructure(Database db) async {
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
      );
      
      if (tables.isEmpty) {
        Logger.warning('Tabela $tableName não existe');
        return false;
      }
      
      // Verificar as colunas da tabela
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      
      // Lista de colunas esperadas
      final expectedColumns = [
        'id', 'property_id', 'plot_id', 'planting_date', 'crop_type',
        'variety', 'seed_quantity', 'seed_unit', 'spacing_between_rows',
        'spacing_between_plants', 'planting_depth', 'fertilizer_used',
        'fertilizer_quantity', 'fertilizer_unit', 'soil_preparation_method',
        'planting_method', 'expected_harvest_date', 'notes', 'user_id',
        'created_at', 'updated_at', 'sync_status', 'sync_date', 'sync_error'
      ];
      
      // Verificar se todas as colunas esperadas existem
      final columnNames = columns.map((c) => c['name'] as String).toList();
      for (final column in expectedColumns) {
        if (!columnNames.contains(column)) {
          Logger.warning('Coluna $column não encontrada na tabela $tableName');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      Logger.severe('Erro ao verificar estrutura da tabela $tableName: $e');
      return false;
    }
  }
  
  /// Repara a tabela (recria se necessário)
  static Future<void> repairTable(Database db) async {
    try {
      // Verificar se a tabela existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
      ).then((result) => result.isNotEmpty);
      
      if (tableExists) {
        // Renomear a tabela atual
        await db.execute('ALTER TABLE $tableName RENAME TO ${tableName}_old');
      }
      
      // Criar a nova tabela
      await createTable(db);
      
      if (tableExists) {
        // Tentar migrar os dados
        try {
          // Lista de colunas que existem na tabela antiga
          final columns = await db.rawQuery('PRAGMA table_info(${tableName}_old)');
          final columnNames = columns.map((c) => c['name'] as String).toList();
          
          // Criar uma lista de colunas comuns entre a tabela antiga e a nova
          final expectedColumns = [
            'id', 'property_id', 'plot_id', 'planting_date', 'crop_type',
            'variety', 'seed_quantity', 'seed_unit', 'spacing_between_rows',
            'spacing_between_plants', 'planting_depth', 'fertilizer_used',
            'fertilizer_quantity', 'fertilizer_unit', 'soil_preparation_method',
            'planting_method', 'expected_harvest_date', 'notes', 'user_id',
            'created_at', 'updated_at', 'sync_status', 'sync_date', 'sync_error'
          ];
          
          final commonColumns = columnNames.where((col) => expectedColumns.contains(col)).toList();
          
          // Migrar os dados
          if (commonColumns.isNotEmpty) {
            final columnsString = commonColumns.join(', ');
            await db.execute('''
              INSERT INTO $tableName ($columnsString)
              SELECT $columnsString FROM ${tableName}_old
            ''');
            
            // Registrar quantos registros foram migrados
            final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName').then(
              (result) => result.first['count'] as int
            );
            
            Logger.info('Migrados $count registros para a tabela $tableName');
          }
          
          // Remover a tabela antiga
          await db.execute('DROP TABLE ${tableName}_old');
        } catch (e) {
          Logger.severe('Erro ao migrar dados para a tabela $tableName: $e');
          // Se falhar na migração, pelo menos a tabela nova já foi criada
        }
      }
      
      Logger.info('Tabela $tableName reparada com sucesso');
    } catch (e) {
      Logger.severe('Erro ao reparar tabela $tableName: $e');
      rethrow;
    }
  }
}
