import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/migrations/create_lista_plantio_complete_system.dart';

/// Serviço para verificar e corrigir problemas no banco de dados do módulo de plantio
class PlantioDatabaseFixService {
  static final PlantioDatabaseFixService _instance = PlantioDatabaseFixService._internal();
  
  factory PlantioDatabaseFixService() {
    return _instance;
  }
  
  PlantioDatabaseFixService._internal();

  /// Verifica se o sistema de lista de plantio está funcionando
  Future<bool> verificarSistemaPlantio() async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar se a view principal existe
      final viewCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='view' AND name='vw_lista_plantio'"
      );
      
      if (viewCheck.isNotEmpty) {
        print('✅ View vw_lista_plantio encontrada');
        
        // Testar se a view está funcionando
        try {
          await db.rawQuery('SELECT * FROM vw_lista_plantio LIMIT 1');
          print('✅ View vw_lista_plantio funcionando corretamente');
          return true;
        } catch (e) {
          print('❌ View vw_lista_plantio com erro: $e');
          return false;
        }
      } else {
        print('❌ View vw_lista_plantio não encontrada');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao verificar sistema de plantio: $e');
      return false;
    }
  }

  /// Corrige automaticamente problemas no banco de dados
  Future<bool> corrigirBancoPlantio() async {
    try {
      print('🔄 Iniciando correção automática do banco de plantio...');
      
      final db = await AppDatabase.instance.database;
      
      // Verificar se as tabelas base existem
      final tabelasNecessarias = [
        'plantio',
        'estoque_produto', 
        'estoque_lote',
        'apontamento_estoque',
        'estande_avaliacao'
      ];
      
      for (final tabela in tabelasNecessarias) {
        final tableCheck = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?", 
          [tabela]
        );
        
        if (tableCheck.isEmpty) {
          print('⚠️ Tabela $tabela não encontrada');
        } else {
          print('✅ Tabela $tabela encontrada');
        }
      }
      
      // Executar migração completa
      print('🔄 Executando migração completa do sistema de plantio...');
      await CreateListaPlantioCompleteSystem.up(db);
      
      // Verificar se a correção funcionou
      final sucesso = await verificarSistemaPlantio();
      
      if (sucesso) {
        print('✅ Correção automática concluída com sucesso!');
      } else {
        print('❌ Correção automática falhou');
      }
      
      return sucesso;
    } catch (e) {
      print('❌ Erro durante correção automática: $e');
      return false;
    }
  }

  /// Verifica e corrige se necessário
  Future<bool> verificarECorrigir() async {
    print('🔍 Verificando sistema de plantio...');
    
    final estaFuncionando = await verificarSistemaPlantio();
    
    if (estaFuncionando) {
      print('✅ Sistema de plantio funcionando corretamente');
      return true;
    } else {
      print('⚠️ Problemas detectados. Iniciando correção automática...');
      return await corrigirBancoPlantio();
    }
  }

  /// Força recriação do sistema completo
  Future<bool> recriarSistemaCompleto() async {
    try {
      print('🔄 Forçando recriação do sistema completo de plantio...');
      
      final db = await AppDatabase.instance.database;
      
      // Remover views existentes
      try {
        await db.execute('DROP VIEW IF EXISTS vw_lista_plantio');
        await db.execute('DROP VIEW IF EXISTS vw_dae');
        await db.execute('DROP VIEW IF EXISTS vw_custo_ha');
        await db.execute('DROP VIEW IF EXISTS vw_populacao_ha');
        await db.execute('DROP VIEW IF EXISTS vw_area_plantio');
        print('✅ Views antigas removidas');
      } catch (e) {
        print('⚠️ Erro ao remover views antigas: $e');
      }
      
      // Recriar sistema completo
      await CreateListaPlantioCompleteSystem.up(db);
      
      // Verificar se funcionou
      final sucesso = await verificarSistemaPlantio();
      
      if (sucesso) {
        print('✅ Sistema completo recriado com sucesso!');
      } else {
        print('❌ Falha ao recriar sistema completo');
      }
      
      return sucesso;
    } catch (e) {
      print('❌ Erro ao recriar sistema completo: $e');
      return false;
    }
  }
}
