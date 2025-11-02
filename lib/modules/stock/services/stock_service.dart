import '../models/stock_model.dart';
import '../models/stock_product_model.dart';
import '../repositories/stock_repository.dart';
import '../repositories/stock_product_repository.dart';
import 'package:uuid/uuid.dart';

class StockService {
  final StockRepository _repository = StockRepository();
  final StockProductRepository _productRepository = StockProductRepository();
  // Fazenda padrão para movimentações de estoque (pode ser alterado para usar a fazenda atual do usuário)
  final String _defaultFarm = 'Fazenda Principal';

  Future<void> saveStock(StockModel model) async {
    await _repository.insert(model);
  }

  Future<List<StockModel>> getHistory() async {
    return await _repository.getAll();
  }

  Future<List<StockModel>> getUnsynced() async {
    return await _repository.getUnsynced();
  }

  Future<void> deleteStock(String id) async {
    await _repository.delete(id);
  }
  
  /// Deduz uma quantidade de um produto do estoque
  /// 
  /// [productId] - ID do produto
  /// [quantity] - Quantidade a ser deduzida
  /// [unit] - Unidade de medida
  /// [description] - Descrição da movimentação
  Future<void> deductFromStock({
    required String productId,
    required double quantity,
    required String unit,
    String description = 'Saída de estoque',
  }) async {
    try {
      // Criar um modelo de movimentação de estoque (saída)
      final stockModel = StockModel(
        id: const Uuid().v4(),
        dateTime: DateTime.now(),
        farm: _defaultFarm,
        product: productId,
        quantity: -quantity, // Valor negativo para indicar saída
        unit: unit,
        operationType: 'SAÍDA',
        notes: description,
        isSynced: false,
      );
      
      // Salvar a movimentação
      await saveStock(stockModel);
      
      print('Produto deduzido do estoque: $productId, quantidade: $quantity $unit');
    } catch (e) {
      print('Erro ao deduzir produto do estoque: $e');
      throw Exception('Falha ao deduzir produto do estoque: $e');
    }
  }
  
  /// Obtém a quantidade disponível em estoque de um produto
  /// 
  /// [productId] - ID do produto
  /// Retorna a quantidade disponível (pode ser negativa se houver mais saídas que entradas)
  Future<double> getAvailableStock(String productId) async {
    try {
      // Buscar todas as movimentações do produto
      final movements = await _repository.getByProductId(productId);
      
      // Calcular o saldo (soma de todas as movimentações)
      double balance = 0;
      for (var movement in movements) {
        balance += movement.quantity;
      }
      
      return balance;
    } catch (e) {
      print('Erro ao obter estoque disponível: $e');
      throw Exception('Falha ao obter estoque disponível: $e');
    }
  }

  /// Obtém um produto específico do estoque
  Future<StockProduct?> getStockProduct(String productId) async {
    try {
      return await _productRepository.getById(productId);
    } catch (e) {
      print('Erro ao obter produto do estoque: $e');
      throw Exception('Falha ao obter produto do estoque: $e');
    }
  }

  /// Obtém todos os produtos do estoque
  Future<List<StockProduct>> getAllStockProducts() async {
    try {
      return await _productRepository.getAll();
    } catch (e) {
      print('Erro ao obter produtos do estoque: $e');
      throw Exception('Falha ao obter produtos do estoque: $e');
    }
  }

  /// Obtém todos os produtos do estoque (alias para compatibilidade)
  Future<List<StockProduct>> getAllProducts() async {
    return await getAllStockProducts();
  }

  /// Adiciona um novo produto ao estoque
  Future<void> addProduct(StockProduct product) async {
    try {
      await _productRepository.insert(product);
    } catch (e) {
      print('Erro ao adicionar produto: $e');
      throw Exception('Falha ao adicionar produto: $e');
    }
  }

  /// Atualiza um produto existente
  Future<void> updateProduct(StockProduct product) async {
    try {
      await _productRepository.update(product);
    } catch (e) {
      print('Erro ao atualizar produto: $e');
      throw Exception('Falha ao atualizar produto: $e');
    }
  }

  /// Remove um produto do estoque
  Future<void> deleteProduct(String productId) async {
    try {
      await _productRepository.delete(productId);
    } catch (e) {
      print('Erro ao deletar produto: $e');
      throw Exception('Falha ao deletar produto: $e');
    }
  }

  /// Atualiza a quantidade de um produto no estoque
  Future<void> updateStockQuantity(String productId, double newQuantity) async {
    try {
      final product = await _productRepository.getById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(availableQuantity: newQuantity);
        await _productRepository.update(updatedProduct);
      }
    } catch (e) {
      print('Erro ao atualizar quantidade do produto: $e');
      throw Exception('Falha ao atualizar quantidade do produto: $e');
    }
  }

  /// Testa o sistema de armazenamento
  Future<bool> testarArmazenamento() async {
    try {
      print('🧪 TESTE: Iniciando teste de armazenamento...');
      
      // Testar SharedPreferences
      final storageOk = await _productRepository.testarStorage();
      if (!storageOk) {
        print('❌ TESTE: Falha no SharedPreferences');
        return false;
      }
      
      // Testar inserção de produto
      final testProduct = StockProduct(
        name: 'Produto Teste',
        category: 'Teste',
        unit: 'kg',
        availableQuantity: 10.0,
        unitValue: 5.0,
      );
      
      await _productRepository.insert(testProduct);
      print('✅ TESTE: Produto inserido com sucesso');
      
      // Testar busca
      final produtos = await _productRepository.getAll();
      print('✅ TESTE: ${produtos.length} produtos encontrados');
      
      // Limpar produto de teste
      await _productRepository.delete(testProduct.id);
      print('✅ TESTE: Produto de teste removido');
      
      print('✅ TESTE: Sistema de armazenamento funcionando corretamente');
      return true;
      
    } catch (e) {
      print('❌ TESTE: Erro no sistema de armazenamento: $e');
      return false;
    }
  }

  /// Limpa dados de exemplo do estoque
  Future<void> limparDadosExemplo() async {
    try {
      print('🧹 Limpando dados de exemplo do estoque...');
      await _productRepository.limparDadosExemplo();
      print('✅ Dados de exemplo removidos com sucesso');
    } catch (e) {
      print('❌ Erro ao limpar dados de exemplo: $e');
      throw Exception('Falha ao limpar dados de exemplo: $e');
    }
  }
}
