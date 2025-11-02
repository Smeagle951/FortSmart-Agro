import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/migrations/fix_crop_varieties_foreign_key.dart';
import '../utils/logger.dart';

/// Script para forçar a correção da tabela crop_varieties
/// Executa a migração manualmente mesmo se o banco já estiver na versão atual
Future<void> main() async {
  const String _tag = 'ForceFixCropVarieties';
  
  try {
    Logger.info('$_tag: 🔧 Forçando correção da tabela crop_varieties...');
    
    final db = await AppDatabase().database;
    
    // Executar a migração de correção
    await fixCropVarietiesForeignKey(db);
    
    Logger.info('$_tag: ✅ Correção forçada concluída!');
    print('🎉 Tabela crop_varieties corrigida com sucesso!');
    
  } catch (e) {
    Logger.error('$_tag: ❌ Erro na correção: $e');
    print('❌ Erro: $e');
    exit(1);
  }
}
