import '../services/inventory_diagnostic_service.dart';
import '../modules/inventory/services/inventory_service.dart';
import '../modules/inventory/models/inventory_product_model.dart';
import '../utils/logger.dart';

/// Script de teste para verificar o módulo de inventário
class InventoryTestScript {
  final InventoryDiagnosticService _diagnosticService = InventoryDiagnosticService();
  final InventoryService _inventoryService = InventoryService();

  /// Executa teste completo do módulo de inventário
  Future<Map<String, dynamic>> runFullTest() async {
    Logger.info('🧪 Iniciando teste completo do módulo de inventário...');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. Executar diagnóstico
      results['diagnostic'] = await _runDiagnostic();
      
      // 2. Testar criação de produto
      results['product_creation'] = await _testProductCreation();
      
      // 3. Testar operações CRUD
      results['crud_operations'] = await _testCrudOperations();
      
      // 4. Verificar dados salvos
      results['data_verification'] = await _verifySavedData();
      
      Logger.info('✅ Teste completo do módulo de inventário finalizado');
      
    } catch (e) {
      Logger.error('❌ Erro durante teste do módulo de inventário: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Executa diagnóstico do módulo
  Future<Map<String, dynamic>> _runDiagnostic() async {
    try {
      Logger.info('🔍 Executando diagnóstico do módulo de inventário...');
      
      final diagnostic = await _diagnosticService.runFullDiagnostic();
      
      Logger.info('📊 Resultado do diagnóstico: ${diagnostic.keys.join(', ')}');
      
      return {
        'status': 'completed',
        'diagnostic': diagnostic,
        'has_issues': _checkForIssues(diagnostic),
      };
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Testa criação de produto
  Future<Map<String, dynamic>> _testProductCreation() async {
    try {
      Logger.info('🔍 Testando criação de produto...');
      
      // Criar produto de teste
      final testProduct = InventoryProductModel(
        id: 'test_product_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Produto Teste',
        description: 'Produto para teste de salvamento',
        category: 'Teste',
        class: 'Teste',
        unit: 'un',
        minStock: 0.0,
        currentStock: 1.0,
        price: 10.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Tentar salvar o produto
      final savedProduct = await _inventoryService.createProduct(testProduct);
      
      Logger.info('✅ Produto criado com sucesso: ${savedProduct.id}');
      
      return {
        'status': 'completed',
        'product_id': savedProduct.id,
        'product_name': savedProduct.name,
        'success': true,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao criar produto: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'success': false,
      };
    }
  }

  /// Testa operações CRUD
  Future<Map<String, dynamic>> _testCrudOperations() async {
    try {
      Logger.info('🔍 Testando operações CRUD...');
      
      final results = <String, dynamic>{};
      
      // Teste de leitura
      try {
        final products = await _inventoryService.getAllProducts();
        results['read_test'] = {
          'success': true,
          'count': products.length,
        };
        Logger.info('✅ Teste de leitura: ${products.length} produtos encontrados');
      } catch (e) {
        results['read_test'] = {
          'success': false,
          'error': e.toString(),
        };
        Logger.error('❌ Erro no teste de leitura: $e');
      }
      
      // Teste de atualização
      try {
        final products = await _inventoryService.getAllProducts();
        if (products.isNotEmpty) {
          final product = products.first;
          product.name = '${product.name} - Atualizado';
          product.updatedAt = DateTime.now();
          
          await _inventoryService.updateProduct(product);
          results['update_test'] = {
            'success': true,
            'product_id': product.id,
          };
          Logger.info('✅ Teste de atualização: produto ${product.id} atualizado');
        } else {
          results['update_test'] = {
            'success': false,
            'error': 'Nenhum produto encontrado para atualizar',
          };
        }
      } catch (e) {
        results['update_test'] = {
          'success': false,
          'error': e.toString(),
        };
        Logger.error('❌ Erro no teste de atualização: $e');
      }
      
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao testar operações CRUD: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica dados salvos
  Future<Map<String, dynamic>> _verifySavedData() async {
    try {
      Logger.info('🔍 Verificando dados salvos...');
      
      final products = await _inventoryService.getAllProducts();
      
      Logger.info('📊 ${products.length} produtos encontrados no banco');
      
      return {
        'status': 'completed',
        'total_products': products.length,
        'has_data': products.isNotEmpty,
        'products': products.take(5).map((p) => {
          'id': p.id,
          'name': p.name,
          'category': p.category,
          'current_stock': p.currentStock,
        }).toList(),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados salvos: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica se há problemas no diagnóstico
  bool _checkForIssues(Map<String, dynamic> diagnostic) {
    try {
      final tableStructure = diagnostic['table_structure'] as Map<String, dynamic>?;
      if (tableStructure == null) return true;
      
      // Verificar se a tabela inventory_products existe
      final inventoryProducts = tableStructure['inventory_products'] as Map<String, dynamic>?;
      if (inventoryProducts == null || !(inventoryProducts['exists'] as bool? ?? false)) {
        return true;
      }
      
      return false;
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar problemas: $e');
      return true;
    }
  }

  /// Gera relatório de teste
  String generateTestReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 RELATÓRIO DE TESTE DO MÓDULO DE INVENTÁRIO');
    buffer.writeln('=' * 60);
    buffer.writeln();
    
    // Diagnóstico
    final diagnostic = results['diagnostic'] as Map<String, dynamic>?;
    if (diagnostic != null) {
      buffer.writeln('🔍 DIAGNÓSTICO:');
      buffer.writeln('  Status: ${diagnostic['status']}');
      buffer.writeln('  Tem problemas: ${diagnostic['has_issues']}');
      buffer.writeln();
    }
    
    // Criação de produto
    final productCreation = results['product_creation'] as Map<String, dynamic>?;
    if (productCreation != null) {
      buffer.writeln('🆕 CRIAÇÃO DE PRODUTO:');
      buffer.writeln('  Status: ${productCreation['status']}');
      buffer.writeln('  Sucesso: ${productCreation['success']}');
      if (productCreation['product_id'] != null) {
        buffer.writeln('  ID do produto: ${productCreation['product_id']}');
        buffer.writeln('  Nome do produto: ${productCreation['product_name']}');
      }
      if (productCreation['error'] != null) {
        buffer.writeln('  Erro: ${productCreation['error']}');
      }
      buffer.writeln();
    }
    
    // Operações CRUD
    final crudOperations = results['crud_operations'] as Map<String, dynamic>?;
    if (crudOperations != null) {
      buffer.writeln('🔄 OPERAÇÕES CRUD:');
      
      final readTest = crudOperations['read_test'] as Map<String, dynamic>?;
      if (readTest != null) {
        buffer.writeln('  Leitura: ${readTest['success'] ? '✅' : '❌'}');
        if (readTest['count'] != null) {
          buffer.writeln('    Produtos encontrados: ${readTest['count']}');
        }
        if (readTest['error'] != null) {
          buffer.writeln('    Erro: ${readTest['error']}');
        }
      }
      
      final updateTest = crudOperations['update_test'] as Map<String, dynamic>?;
      if (updateTest != null) {
        buffer.writeln('  Atualização: ${updateTest['success'] ? '✅' : '❌'}');
        if (updateTest['error'] != null) {
          buffer.writeln('    Erro: ${updateTest['error']}');
        }
      }
      
      buffer.writeln();
    }
    
    // Verificação de dados
    final dataVerification = results['data_verification'] as Map<String, dynamic>?;
    if (dataVerification != null) {
      buffer.writeln('📈 VERIFICAÇÃO DE DADOS:');
      buffer.writeln('  Status: ${dataVerification['status']}');
      buffer.writeln('  Total de produtos: ${dataVerification['total_products']}');
      buffer.writeln('  Tem dados: ${dataVerification['has_data']}');
      buffer.writeln();
    }
    
    // Resumo geral
    buffer.writeln('📋 RESUMO GERAL:');
    final hasProductCreation = productCreation?['success'] ?? false;
    final hasData = dataVerification?['has_data'] ?? false;
    
    if (hasProductCreation && hasData) {
      buffer.writeln('  ✅ Módulo de inventário funcionando corretamente');
      buffer.writeln('  ✅ Produtos podem ser salvos e recuperados');
    } else if (hasData) {
      buffer.writeln('  ⚠️ Módulo parcialmente funcional - dados existem mas criação pode ter problemas');
    } else {
      buffer.writeln('  ❌ Módulo com problemas - produtos não estão sendo salvos');
    }
    
    return buffer.toString();
  }
}
