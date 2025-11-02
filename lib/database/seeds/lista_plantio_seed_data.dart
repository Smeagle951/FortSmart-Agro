import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

class ListaPlantioSeedData {
  static Future<void> inserirDadosExemplo() async {
    final db = await AppDatabase.instance.database;
    
    print('🌱 Inserindo dados de exemplo para Lista de Plantio...');
    
    try {
      await db.transaction((txn) async {
        // 1. Inserir talhões de exemplo
        await _inserirTalhoes(txn);
        
        // 2. Inserir subáreas de exemplo
        await _inserirSubareas(txn);
        
        // 3. Inserir produtos de estoque
        await _inserirProdutosEstoque(txn);
        
        // 4. Inserir lotes de estoque
        await _inserirLotesEstoque(txn);
        
        // 5. Inserir plantios de exemplo
        await _inserirPlantios(txn);
        
        // 6. Inserir apontamentos de estoque
        await _inserirApontamentosEstoque(txn);
        
        // 7. Inserir avaliações de estande
        await _inserirAvaliacoesEstande(txn);
      });
      
      print('✅ Dados de exemplo inseridos com sucesso!');
    } catch (e) {
      print('❌ Erro ao inserir dados de exemplo: $e');
    }
  }

  static Future<void> _inserirTalhoes(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    await txn.insert('talhao', {
      'id': 'talhao_001',
      'nome': 'Talhão 1 - Centro',
      'area_ha': 25.5,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    await txn.insert('talhao', {
      'id': 'talhao_002',
      'nome': 'Talhão 2 - Norte',
      'area_ha': 18.2,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    await txn.insert('talhao', {
      'id': 'talhao_003',
      'nome': 'Talhão 3 - Sul',
      'area_ha': 32.8,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirSubareas(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    await txn.insert('subarea', {
      'id': 'subarea_001',
      'talhao_id': 'talhao_001',
      'nome': 'Subárea A',
      'area_ha': 12.5,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    await txn.insert('subarea', {
      'id': 'subarea_002',
      'talhao_id': 'talhao_001',
      'nome': 'Subárea B',
      'area_ha': 13.0,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirProdutosEstoque(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    // Sementes de Soja
    await txn.insert('estoque_produto', {
      'id': 'produto_001',
      'tipo': 'semente',
      'cultura': 'Soja',
      'variedade': '58I59RSF',
      'unidade': 'saco',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    await txn.insert('estoque_produto', {
      'id': 'produto_002',
      'tipo': 'semente',
      'cultura': 'Soja',
      'variedade': 'BMX Potência RR',
      'unidade': 'saco',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Sementes de Milho
    await txn.insert('estoque_produto', {
      'id': 'produto_003',
      'tipo': 'semente',
      'cultura': 'Milho',
      'variedade': 'DKB 390 PRO3',
      'unidade': 'saco',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirLotesEstoque(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    // Lotes de Soja 58I59RSF
    await txn.insert('estoque_lote', {
      'id': 'lote_001',
      'produto_id': 'produto_001',
      'lote': 'LOTE-2024-001',
      'qntd_total': 100.0,
      'qntd_disponivel': 85.0,
      'custo_unitario': 350.00,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    await txn.insert('estoque_lote', {
      'id': 'lote_002',
      'produto_id': 'produto_001',
      'lote': 'LOTE-2024-002',
      'qntd_total': 80.0,
      'qntd_disponivel': 80.0,
      'custo_unitario': 365.00,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Lotes de Soja BMX Potência RR
    await txn.insert('estoque_lote', {
      'id': 'lote_003',
      'produto_id': 'produto_002',
      'lote': 'LOTE-2024-003',
      'qntd_total': 120.0,
      'qntd_disponivel': 95.0,
      'custo_unitario': 380.00,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Lotes de Milho DKB 390 PRO3
    await txn.insert('estoque_lote', {
      'id': 'lote_004',
      'produto_id': 'produto_003',
      'lote': 'LOTE-2024-004',
      'qntd_total': 90.0,
      'qntd_disponivel': 90.0,
      'custo_unitario': 420.00,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirPlantios(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    // Plantio 1 - Soja 58I59RSF no Talhão 1
    await txn.insert('plantio', {
      'id': 'plantio_001',
      'talhao_id': 'talhao_001',
      'subarea_id': 'subarea_001',
      'cultura': 'Soja',
      'variedade': '58I59RSF',
      'data_plantio': '2024-10-15T08:00:00.000Z',
      'espacamento_cm': 45.0,
      'populacao_por_m': 12.0,
      'observacao': 'Plantio realizado com clima favorável',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Plantio 2 - Soja BMX Potência RR no Talhão 2
    await txn.insert('plantio', {
      'id': 'plantio_002',
      'talhao_id': 'talhao_002',
      'subarea_id': null,
      'cultura': 'Soja',
      'variedade': 'BMX Potência RR',
      'data_plantio': '2024-10-18T10:30:00.000Z',
      'espacamento_cm': 50.0,
      'populacao_por_m': 11.5,
      'observacao': 'Plantio com espaçamento maior para melhor aeração',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Plantio 3 - Milho DKB 390 PRO3 no Talhão 3
    await txn.insert('plantio', {
      'id': 'plantio_003',
      'talhao_id': 'talhao_003',
      'subarea_id': null,
      'cultura': 'Milho',
      'variedade': 'DKB 390 PRO3',
      'data_plantio': '2024-10-20T14:15:00.000Z',
      'espacamento_cm': 80.0,
      'populacao_por_m': 6.5,
      'observacao': 'Plantio de milho segunda safra',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirApontamentosEstoque(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    // Apontamento para Plantio 1
    await txn.insert('apontamento_estoque', {
      'id': 'apontamento_001',
      'plantio_id': 'plantio_001',
      'lote_id': 'lote_001',
      'quantidade': 15.0,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Apontamento para Plantio 2
    await txn.insert('apontamento_estoque', {
      'id': 'apontamento_002',
      'plantio_id': 'plantio_002',
      'lote_id': 'lote_003',
      'quantidade': 18.0,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Apontamento para Plantio 3
    await txn.insert('apontamento_estoque', {
      'id': 'apontamento_003',
      'plantio_id': 'plantio_003',
      'lote_id': 'lote_004',
      'quantidade': 22.0,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  static Future<void> _inserirAvaliacoesEstande(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    
    // Avaliação para Plantio 1
    await txn.insert('estande_avaliacao', {
      'id': 'estande_001',
      'plantio_id': 'plantio_001',
      'data_avaliacao': '2024-11-05T09:00:00.000Z',
      'comprimento_amostrado_m': 10.0,
      'linhas_amostradas': 3,
      'plantas_contadas': 42,
      'dae': 14000,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Avaliação para Plantio 2
    await txn.insert('estande_avaliacao', {
      'id': 'estande_002',
      'plantio_id': 'plantio_002',
      'data_avaliacao': '2024-11-08T10:30:00.000Z',
      'comprimento_amostrado_m': 10.0,
      'linhas_amostradas': 3,
      'plantas_contadas': 38,
      'dae': 12667,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
    
    // Segunda avaliação para Plantio 1 (mais recente)
    await txn.insert('estande_avaliacao', {
      'id': 'estande_003',
      'plantio_id': 'plantio_001',
      'data_avaliacao': '2024-11-15T08:15:00.000Z',
      'comprimento_amostrado_m': 10.0,
      'linhas_amostradas': 3,
      'plantas_contadas': 45,
      'dae': 15000,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  // Método para limpar dados de exemplo (para testes)
  static Future<void> limparDadosExemplo() async {
    final db = await AppDatabase.instance.database;
    
    print('🧹 Limpando dados de exemplo...');
    
    try {
      await db.transaction((txn) async {
        await txn.delete('estande_avaliacao', where: 'id LIKE ?', whereArgs: ['estande_%']);
        await txn.delete('apontamento_estoque', where: 'id LIKE ?', whereArgs: ['apontamento_%']);
        await txn.delete('plantio', where: 'id LIKE ?', whereArgs: ['plantio_%']);
        await txn.delete('estoque_lote', where: 'id LIKE ?', whereArgs: ['lote_%']);
        await txn.delete('estoque_produto', where: 'id LIKE ?', whereArgs: ['produto_%']);
        await txn.delete('subarea', where: 'id LIKE ?', whereArgs: ['subarea_%']);
        await txn.delete('talhao', where: 'id LIKE ?', whereArgs: ['talhao_%']);
      });
      
      print('✅ Dados de exemplo removidos com sucesso!');
    } catch (e) {
      print('❌ Erro ao remover dados de exemplo: $e');
    }
  }
}
