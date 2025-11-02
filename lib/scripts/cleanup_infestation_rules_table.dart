import '../database/app_database.dart';
import '../utils/logger.dart';

/// Script para limpar a tabela infestation_rules do banco de dados
/// Esta tabela não é mais necessária pois usamos diretamente o catálogo de organismos
void main() async {
  try {
    Logger.info('🗑️ Iniciando limpeza da tabela infestation_rules...');
    
    final database = AppDatabase();
    final db = await database.database;
    
    // Verificar se a tabela existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='infestation_rules'"
    );
    
    if (tables.isNotEmpty) {
      Logger.info('📊 Tabela infestation_rules encontrada');
      
      // Verificar quantos registros existem
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM infestation_rules');
      final recordCount = count.first['count'] as int;
      
      Logger.info('📈 Registros encontrados: $recordCount');
      
      if (recordCount > 0) {
        Logger.info('⚠️ A tabela contém dados. Removendo registros...');
        await db.delete('infestation_rules');
        Logger.info('✅ Registros removidos');
      }
      
      // Remover a tabela
      await db.execute('DROP TABLE IF EXISTS infestation_rules');
      Logger.info('✅ Tabela infestation_rules removida');
      
      // Remover índices relacionados
      await db.execute('DROP INDEX IF EXISTS idx_infestation_rules_organism');
      await db.execute('DROP INDEX IF EXISTS idx_infestation_rules_farm');
      await db.execute('DROP INDEX IF EXISTS idx_infestation_rules_field');
      await db.execute('DROP INDEX IF EXISTS idx_infestation_rules_active');
      Logger.info('✅ Índices relacionados removidos');
      
    } else {
      Logger.info('ℹ️ Tabela infestation_rules não encontrada (já foi removida)');
    }
    
    Logger.info('🎉 Limpeza concluída com sucesso!');
    Logger.info('');
    Logger.info('📝 O sistema agora usa exclusivamente o Catálogo de Organismos');
    Logger.info('   para definir limiares de infestação, eliminando duplicação');
    Logger.info('   e simplificando a manutenção.');
    
  } catch (e) {
    Logger.error('❌ Erro durante a limpeza: $e');
  }
}
