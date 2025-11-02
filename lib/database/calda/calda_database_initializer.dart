import 'calda_database.dart';

/// Inicializador do banco de dados do módulo Calda
class CaldaDatabaseInitializer {
  static bool _isInitialized = false;

  /// Inicializa o banco de dados do módulo Calda
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializa o banco de dados
      await CaldaDatabase.database;
      _isInitialized = true;
      print('✅ Banco de dados Calda inicializado com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar banco de dados Calda: $e');
      rethrow;
    }
  }

  /// Verifica se o banco está inicializado
  static bool get isInitialized => _isInitialized;

  /// Fecha o banco de dados
  static Future<void> close() async {
    await CaldaDatabase.close();
    _isInitialized = false;
  }

  /// Deleta o banco de dados (para testes)
  static Future<void> deleteDatabase() async {
    await CaldaDatabase.deleteDatabase();
    _isInitialized = false;
  }
}
