import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Serviço para reset seguro do banco de dados
/// Remove apenas culturas de teste e recria com dados corretos
class DatabaseResetService {
  static const String _databaseName = 'app_database.db';
  
  /// Reset seguro - remove apenas culturas de teste
  static Future<void> safeReset() async {
    try {
      print('🔄 Iniciando reset seguro do banco...');
      
      // Obter caminho do banco
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      // Abrir banco
      final database = await openDatabase(path);
      
      // Remover APENAS culturas de teste (não quebrar dados do usuário)
      await _removeTestCultures(database);
      
      await database.close();
      
      print('✅ Reset seguro concluído!');
      print('🌾 Culturas de teste removidas');
      print('📱 Reinicie o app para ver as mudanças');
      
    } catch (e) {
      print('❌ Erro no reset seguro: $e');
      rethrow;
    }
  }
  
  /// Remove apenas culturas de teste
  static Future<void> _removeTestCultures(Database database) async {
    try {
      // Remover culturas de teste das tabelas
      final result1 = await database.delete(
        'crops',
        where: "name LIKE '%Teste%' OR name LIKE '%test%' OR name = 'Aveia'"
      );
      print('   ✅ Removidas $result1 culturas de teste da tabela crops');
      
      final result2 = await database.delete(
        'culturas',
        where: "nome LIKE '%Teste%' OR nome LIKE '%test%' OR nome = 'Aveia'"
      );
      print('   ✅ Removidas $result2 culturas de teste da tabela culturas');
      
      // Remover pragas, doenças e plantas daninhas das culturas de teste
      await database.delete(
        'pests',
        where: "cropId IN (SELECT id FROM crops WHERE name LIKE '%Teste%' OR name = 'Aveia')"
      );
      
      await database.delete(
        'diseases',
        where: "cropId IN (SELECT id FROM crops WHERE name LIKE '%Teste%' OR name = 'Aveia')"
      );
      
      await database.delete(
        'weeds',
        where: "cropId IN (SELECT id FROM crops WHERE name LIKE '%Teste%' OR name = 'Aveia')"
      );
      
      print('   ✅ Organismos das culturas de teste removidos');
      
    } catch (e) {
      print('   ⚠️ Erro ao remover culturas de teste: $e');
    }
  }
  
  /// Verifica se há culturas de teste no banco
  static Future<bool> hasTestCultures() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      final database = await openDatabase(path);
      
      final result = await database.rawQuery(
        "SELECT COUNT(*) as count FROM crops WHERE name LIKE '%Teste%' OR name LIKE '%test%' OR name = 'Aveia'"
      );
      
      await database.close();
      
      return (result.first['count'] as int) > 0;
      
    } catch (e) {
      print('❌ Erro ao verificar culturas de teste: $e');
      return false;
    }
  }
  
  /// Lista todas as culturas no banco
  static Future<List<Map<String, dynamic>>> listAllCultures() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      final database = await openDatabase(path);
      
      final result = await database.rawQuery("SELECT * FROM crops ORDER BY name");
      
      await database.close();
      
      return result;
      
    } catch (e) {
      print('❌ Erro ao listar culturas: $e');
      return [];
    }
  }
}
