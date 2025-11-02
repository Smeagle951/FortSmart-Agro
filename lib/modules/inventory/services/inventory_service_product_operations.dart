import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/inventory_product_model.dart';
import '../repositories/inventory_product_repository.dart';
import './inventory_cache_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../models/agricultural_product.dart';
import '../../../utils/logger.dart';

/// Serviço para operações de produtos no estoque
class InventoryServiceProductOperations {
  final InventoryProductRepository _productRepository = InventoryProductRepository();
  final InventoryCacheService _cacheService = InventoryCacheService();
  final DataCacheService _dataCacheService = DataCacheService();

  /// Adiciona um novo produto ao estoque
  Future<String?> addProduct(InventoryProductModel product) async {
    try {
      Logger.info('🔄 Tentando adicionar produto: ${product.name}');
      Logger.info('📊 Dados do produto: ${product.toMap()}');
      
      final productId = await _productRepository.insert(product);
      Logger.info('✅ Produto adicionado com sucesso: ${product.name} (ID: $productId)');
      return productId.toString();
    } catch (e) {
      Logger.error('❌ Erro ao adicionar produto: $e');
      Logger.error('📊 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Atualiza um produto existente
  Future<bool> updateProduct(InventoryProductModel product) async {
    try {
      await _productRepository.update(product);
      Logger.info('Produto atualizado com sucesso: ${product.name}');
      return true;
    } catch (e) {
      Logger.error('Erro ao atualizar produto: $e');
      return false;
    }
  }

  /// Remove um produto do estoque
  Future<bool> removeProduct(String id) async {
    try {
      await _productRepository.delete(id);
      Logger.info('Produto removido com sucesso: $id');
      return true;
    } catch (e) {
      Logger.error('Erro ao remover produto: $e');
      return false;
    }
  }

  /// Atualiza a quantidade de um produto
  Future<bool> updateProductQuantity(String id, double newQuantity) async {
    try {
      final product = await _productRepository.getById(id);
      if (product != null) {
        final updatedProduct = product.copyWith(quantity: newQuantity);
        await _productRepository.update(updatedProduct);
        Logger.info('Quantidade do produto atualizada: $id -> $newQuantity');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao atualizar quantidade do produto: $e');
      return false;
    }
  }

  /// Ajusta o estoque de um produto
  Future<bool> adjustProductStock(String id, double adjustment, String reason) async {
    try {
      final product = await _productRepository.getById(id);
      if (product != null) {
        final newQuantity = product.quantity + adjustment;
        if (newQuantity >= 0) {
          final updatedProduct = product.copyWith(quantity: newQuantity);
          await _productRepository.update(updatedProduct);
          Logger.info('Estoque ajustado: $id -> $adjustment ($reason)');
          return true;
        } else {
          Logger.error('Ajuste resultaria em estoque negativo: $id');
          return false;
        }
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao ajustar estoque do produto: $e');
      return false;
    }
  }

  /// Obtém produtos agrícolas para seleção
  Future<List<AgriculturalProduct>> getAgriculturalProducts() async {
    try {
      // Verificar se há produtos agrícolas em cache
      final cachedProducts = _cacheService.getAgriculturalProducts();
      if (cachedProducts != null) {
        print('Retornando ${cachedProducts.length} produtos agrícolas do cache');
        return cachedProducts;
      }

      // Se não estiver em cache, buscar do serviço de dados
      final products = await _dataCacheService.getAgriculturalProducts();
      
      // Armazenar em cache para uso futuro
      _cacheService.setAgriculturalProducts(products);
      
      print('Retornando ${products.length} produtos agrícolas do serviço de dados');
      return products;
    } catch (e) {
      print('Erro ao obter produtos agrícolas: $e');
      return [];
    }
  }

  /// Verifica se um produto existe no estoque pelo ID do produto agrícola
  Future<bool> productExistsByAgriculturalId(String agriculturalId) async {
    try {
      final products = await getAllProducts();
      return products.any((p) => p.productId == agriculturalId);
    } catch (e) {
      print('Erro ao verificar existência de produto: $e');
      return false;
    }
  }

  /// Obtém todos os produtos do estoque
  Future<List<InventoryProductModel>> getAllProducts() async {
    try {
      // Verificar se há produtos em cache
      final cachedProducts = _cacheService.getInventoryProducts();
      if (cachedProducts != null) {
        return cachedProducts;
      }

      // Se não estiver em cache, buscar do repositório
      final products = await _productRepository.getAll();
      // Armazenar em cache para uso futuro
      _cacheService.setInventoryProducts(products);
      return products;
    } catch (e) {
      print('Erro ao obter produtos: $e');
      return [];
    }
  }
}
