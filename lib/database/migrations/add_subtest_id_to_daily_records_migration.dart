import 'package:sqflite/sqflite.dart';

class AddSubtestIdToDailyRecordsMigration {
  static Future<void> executeMigration(Database db) async {
    print('Executando migração para adicionar coluna subtestId à tabela germination_daily_records...');
    
    // Adicionar coluna subtestId
    await _addColumn(db, 'germination_daily_records', 'subtestId', 'INTEGER');
    // Adicionar coluna diseasedBacteria
    await _addColumn(db, 'germination_daily_records', 'diseasedBacteria', 'INTEGER NOT NULL DEFAULT 0');
    // Adicionar coluna otherSeeds
    await _addColumn(db, 'germination_daily_records', 'otherSeeds', 'INTEGER NOT NULL DEFAULT 0');
    // Adicionar coluna inertMatter
    await _addColumn(db, 'germination_daily_records', 'inertMatter', 'INTEGER NOT NULL DEFAULT 0');

    print('Migração de colunas para germination_daily_records concluída.');
  }

  static Future<bool> isMigrationNeeded(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(germination_daily_records)');
    final columnNames = tableInfo.map((e) => e['name'] as String).toList();
    
    return !columnNames.contains('subtestId') ||
           !columnNames.contains('diseasedBacteria') ||
           !columnNames.contains('otherSeeds') ||
           !columnNames.contains('inertMatter');
  }

  static Future<void> _addColumn(Database db, String tableName, String columnName, String columnDefinition) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    final columnExists = tableInfo.any((element) => element['name'] == columnName);
    if (!columnExists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
      print('Coluna $columnName adicionada à tabela $tableName.');
    } else {
      print('Coluna $columnName já existe na tabela $tableName. Nenhuma ação necessária.');
    }
  }
}
