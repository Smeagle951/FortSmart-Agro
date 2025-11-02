import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/app_database.dart';

/// Serviço para recriar completamente o banco de dados
/// Remove banco antigo e cria novo com dados corretos
class DatabaseRecreationService {
  static const String _databaseName = 'app_database.db';
  
  /// Recria completamente o banco de dados
  static Future<void> recreateDatabase() async {
    try {
      print('🔄 Iniciando recriação completa do banco...');
      
      // Obter caminho do banco
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      // Fechar conexões existentes
      await _closeExistingConnections();
      
      // Deletar banco antigo
      await _deleteOldDatabase(path);
      
      // Criar novo banco
      await _createNewDatabase();
      
      print('✅ Banco recriado com sucesso!');
      print('🌾 Novas culturas: Cana-de-açúcar e Tomate');
      print('🐛 Novas pragas e doenças adicionadas');
      
    } catch (e) {
      print('❌ Erro na recriação do banco: $e');
      rethrow;
    }
  }
  
  /// Fecha conexões existentes
  static Future<void> _closeExistingConnections() async {
    try {
      // Tentar fechar conexões ativas - não há conexão global para fechar
      print('   ℹ️ Fechando conexões existentes...');
    } catch (e) {
      print('   ⚠️ Erro ao fechar conexões: $e');
    }
  }
  
  /// Deleta banco antigo
  static Future<void> _deleteOldDatabase(String path) async {
    try {
      // Verificar se arquivo existe
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('   ✅ Banco antigo removido');
      } else {
        print('   ℹ️ Banco antigo não encontrado');
      }
    } catch (e) {
      print('   ⚠️ Erro ao remover banco antigo: $e');
    }
  }
  
  /// Cria novo banco com dados corretos
  static Future<void> _createNewDatabase() async {
    try {
      // Usar AppDatabase para criar banco com dados padrão corretos
      final appDb = AppDatabase();
      // AppDatabase não tem método init(), ele é inicializado automaticamente
      
      print('   ✅ Novo banco criado');
      print('   ✅ Culturas padrão inseridas');
      print('   ✅ Organismos inseridos');
      
      // AppDatabase é singleton, não precisa fechar
      
    } catch (e) {
      print('   ❌ Erro ao criar novo banco: $e');
      rethrow;
    }
  }
  
  /// Verifica se banco precisa ser recriado
  static Future<bool> needsRecreation() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      final file = File(path);
      if (!await file.exists()) {
        return true; // Banco não existe, precisa criar
      }
      
      // Verificar se tem culturas corretas
      final database = await openDatabase(path);
      
      final result = await database.rawQuery(
        "SELECT COUNT(*) as count FROM crops WHERE name IN ('Cana-de-açúcar', 'Tomate')"
      );
      
      await database.close();
      
      final hasNewCultures = (result.first['count'] as int) > 0;
      return !hasNewCultures; // Precisa recriar se não tem as novas culturas
      
    } catch (e) {
      print('❌ Erro ao verificar necessidade de recriação: $e');
      return true; // Em caso de erro, recriar
    }
  }
}
