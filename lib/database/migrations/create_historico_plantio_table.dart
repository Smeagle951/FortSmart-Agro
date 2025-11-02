import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela historico_plantio
class CreateHistoricoPlantioTable {
  static Future<void> createHistoricoPlantioTable(Database db) async {
    try {
      print('🔄 Criando tabela historico_plantio...');
      
      // Verificar se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='historico_plantio'"
      );
      
      if (tables.isNotEmpty) {
        print('✅ Tabela historico_plantio já existe');
        return;
      }
      
      // Criar a tabela historico_plantio
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historico_plantio (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          calculo_id TEXT,
          talhao_id TEXT NOT NULL,
          safra_id TEXT,
          cultura_id TEXT,
          tipo TEXT NOT NULL,
          data TEXT NOT NULL,
          resumo TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      print('✅ Tabela historico_plantio criada com sucesso');
      
    } catch (e) {
      print('❌ Erro ao criar tabela historico_plantio: $e');
      rethrow;
    }
  }
}