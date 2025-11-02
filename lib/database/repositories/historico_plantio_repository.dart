import 'package:sqflite/sqflite.dart';
import '../models/historico_plantio_model.dart';
import '../app_database.dart';

class HistoricoPlantioRepository {
  final AppDatabase _appDatabase = AppDatabase();

  // Getter para acessar o banco de dados com segurança
  Future<Database> get db async {
    return await _appDatabase.database;
  }

  Future<void> salvar(HistoricoPlantioModel historico) async {
    try {
      print('🔄 DEBUG: HistoricoPlantioRepository.salvar() iniciado');
      print('🔄 DEBUG: Dados do histórico: ${historico.toMap()}');
      
      final database = await db;
      print('🔄 DEBUG: Banco de dados obtido');
      
      // CRIAR TABELA SE NÃO EXISTIR
      await database.execute('''
        CREATE TABLE IF NOT EXISTS historico_plantio (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          calculo_id TEXT,
          talhao_id TEXT NOT NULL,
          talhao_nome TEXT,
          safra_id TEXT,
          cultura_id TEXT NOT NULL,
          tipo TEXT NOT NULL,
          data TEXT NOT NULL,
          resumo TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          sync_status INTEGER DEFAULT 0
        )
      ''');
      print('✅ DEBUG: Tabela historico_plantio verificada/criada');
      
      await database.insert('historico_plantio', historico.toMap());
      print('✅ DEBUG: Histórico inserido com sucesso na tabela historico_plantio');
    } catch (e) {
      print('❌ DEBUG: Erro no HistoricoPlantioRepository.salvar(): $e');
      print('❌ DEBUG: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<HistoricoPlantioModel>> listarPorTalhao(String talhaoId, {String? tipo}) async {
    final database = await db;
    final result = await database.query(
      'historico_plantio',
      where: 'talhao_id = ?' + (tipo != null ? ' AND tipo = ?' : ''),
      whereArgs: tipo != null ? [talhaoId, tipo] : [talhaoId],
      orderBy: 'data DESC',
    );
    return result.map((map) => HistoricoPlantioModel.fromMap(map)).toList();
  }
  
  Future<List<HistoricoPlantioModel>> listarTodos() async {
    try {
      print('🔍 DEBUG: listarTodos() chamado');
      final database = await db;
      
      // Criar tabela se não existir
      await database.execute('''
        CREATE TABLE IF NOT EXISTS historico_plantio (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          calculo_id TEXT,
          talhao_id TEXT NOT NULL,
          talhao_nome TEXT,
          safra_id TEXT,
          cultura_id TEXT NOT NULL,
          tipo TEXT NOT NULL,
          data TEXT NOT NULL,
          resumo TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          sync_status INTEGER DEFAULT 0
        )
      ''');
      
      final result = await database.query(
        'historico_plantio',
        orderBy: 'data DESC',
      );
      
      print('✅ DEBUG: ${result.length} registros encontrados na tabela historico_plantio');
      
      return result.map((map) => HistoricoPlantioModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ DEBUG: Erro em listarTodos(): $e');
      return [];
    }
  }
  
  Future<void> atualizar(HistoricoPlantioModel historico) async {
    try {
      print('🔄 Atualizando histórico ID: ${historico.id}');
      final database = await db;
      
      await database.update(
        'historico_plantio',
        historico.toMap(),
        where: 'id = ?',
        whereArgs: [historico.id],
      );
      
      print('✅ Histórico atualizado com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar histórico: $e');
      rethrow;
    }
  }
  
  Future<void> excluir(int id) async {
    try {
      print('🗑️ Excluindo histórico ID: $id');
      final database = await db;
      
      await database.delete(
        'historico_plantio',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ Histórico excluído com sucesso');
    } catch (e) {
      print('❌ Erro ao excluir histórico: $e');
      rethrow;
    }
  }
}
