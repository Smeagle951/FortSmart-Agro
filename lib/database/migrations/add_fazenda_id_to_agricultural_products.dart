import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Migração para adicionar a coluna fazendaId à tabela agricultural_products
class AddFazendaIdToAgriculturalProductsMigration {
  static const String tableName = 'agricultural_products';
  static const String columnName = 'fazendaId';

  /// Executa a migração
  static Future<void> migrate(Database db) async {
    try {
      // Verifica se a coluna já existe
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = tableInfo.any((column) => column['name'] == columnName);

      // Se a coluna não existir, adiciona
      if (!columnExists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName TEXT');
        debugPrint('Coluna $columnName adicionada à tabela $tableName');
      } else {
        debugPrint('Coluna $columnName já existe na tabela $tableName');
      }
    } catch (e) {
      debugPrint('Erro ao adicionar coluna $columnName à tabela $tableName: $e');
      // Não lança exceção para não interromper outras migrações
    }
  }
}
