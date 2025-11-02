import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../migrations/add_fazenda_id_to_agricultural_products.dart';

/// Serviço para executar migrações do banco de dados
class MigrationService {
  /// Executa todas as migrações necessárias
  static Future<void> runMigrations(Database db) async {
    debugPrint('Iniciando execução de migrações do banco de dados...');
    
    try {
      // Executa a migração para adicionar a coluna fazendaId à tabela agricultural_products
      await AddFazendaIdToAgriculturalProductsMigration.migrate(db);
      
      // Adicione outras migrações aqui conforme necessário
      
      debugPrint('Migrações do banco de dados concluídas com sucesso.');
    } catch (e) {
      debugPrint('Erro ao executar migrações do banco de dados: $e');
      // Não lança exceção para não interromper a inicialização do aplicativo
    }
  }
}
