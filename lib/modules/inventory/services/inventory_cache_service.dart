import 'dart:async';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/crop.dart' as app_crop;
import '../../../services/data_cache_service.dart';

/// Serviço de cache para o módulo de estoque
/// Armazena produtos, transações e outras informações em memória para reduzir consultas ao banco de dados
class InventoryCacheService {
  // Singleton
  static final InventoryCacheService _instance = InventoryCacheService._internal();
  factory InventoryCacheService() => _instance;
  InventoryCacheService._internal();

  // Cache de produtos no estoque
  List<InventoryProductModel>? _inventoryProducts;
  DateTime? _inventoryProductsLastUpdate;

  // Cache de transações de estoque
  List<InventoryTransactionModel>? _inventoryTransactions;
  DateTime? _inventoryTransactionsLastUpdate;

  // Cache de produtos agrícolas
  List<AgriculturalProduct>? _agriculturalProducts;
  DateTime? _agriculturalProductsLastUpdate;

  // Cache de culturas
  List<app_crop.Crop>? _crops;
  DateTime? _cropsLastUpdate;

  // Cache de produtos com estoque baixo
  List<InventoryProductModel>? _lowStockProducts;
  DateTime? _lowStockProductsLastUpdate;

  // Cache de produtos com estoque crítico
  List<InventoryProductModel>? _criticalStockProducts;
  DateTime? _criticalStockProductsLastUpdate;

  // Cache de produtos próximos do vencimento
  List<InventoryProductModel>? _nearExpirationProducts;
  DateTime? _nearExpirationProductsLastUpdate;

  // Cache de produtos vencidos
  List<InventoryProductModel>? _expiredProducts;
  DateTime? _expiredProductsLastUpdate;

  // Tempo de expiração do cache (5 minutos)
  final Duration _cacheExpiration = Duration(minutes: 5);

  /// Verifica se o cache expirou
  bool _isCacheExpired(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > _cacheExpiration;
  }

  /// Limpa todo o cache
  void clearCache() {
    _inventoryProducts = null;
    _inventoryProductsLastUpdate = null;
    _inventoryTransactions = null;
    _inventoryTransactionsLastUpdate = null;
    _agriculturalProducts = null;
    _agriculturalProductsLastUpdate = null;
    _crops = null;
    _cropsLastUpdate = null;
    _lowStockProducts = null;
    _lowStockProductsLastUpdate = null;
    _criticalStockProducts = null;
    _criticalStockProductsLastUpdate = null;
    _nearExpirationProducts = null;
    _nearExpirationProductsLastUpdate = null;
    _expiredProducts = null;
    _expiredProductsLastUpdate = null;
  }
  
  /// Alias para clearCache - limpa todo o cache
  void clearAll() {
    clearCache();
  }
  
  /// Limpa o cache de produtos do inventário
  void clearInventoryProducts() {
    _inventoryProducts = null;
    _inventoryProductsLastUpdate = null;
    _lowStockProducts = null;
    _lowStockProductsLastUpdate = null;
    _criticalStockProducts = null;
    _criticalStockProductsLastUpdate = null;
    _nearExpirationProducts = null;
    _nearExpirationProductsLastUpdate = null;
    _expiredProducts = null;
    _expiredProductsLastUpdate = null;
  }
  
  /// Limpa o cache de transações do inventário
  void clearInventoryTransactions() {
    _inventoryTransactions = null;
    _inventoryTransactionsLastUpdate = null;
  }
  
  /// Limpa o cache de produtos agrícolas
  void clearAgriculturalProducts() {
    _agriculturalProducts = null;
    _agriculturalProductsLastUpdate = null;
  }
  
  /// Limpa o cache de culturas
  void clearCrops() {
    _crops = null;
    _cropsLastUpdate = null;
  }
  
  /// Retorna a instância do DataCacheService
  DataCacheService getDataCacheService() {
    return DataCacheService();
  }

  /// Armazena produtos no cache
  void setInventoryProducts(List<InventoryProductModel> products) {
    _inventoryProducts = products;
    _inventoryProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos do cache
  List<InventoryProductModel>? getInventoryProducts() {
    if (_isCacheExpired(_inventoryProductsLastUpdate)) {
      return null;
    }
    return _inventoryProducts;
  }

  /// Armazena transações no cache
  void setInventoryTransactions(List<InventoryTransactionModel> transactions) {
    _inventoryTransactions = transactions;
    _inventoryTransactionsLastUpdate = DateTime.now();
  }

  /// Obtém transações do cache
  List<InventoryTransactionModel>? getInventoryTransactions() {
    if (_isCacheExpired(_inventoryTransactionsLastUpdate)) {
      return null;
    }
    return _inventoryTransactions;
  }

  /// Armazena produtos agrícolas no cache
  void setAgriculturalProducts(List<AgriculturalProduct> products) {
    _agriculturalProducts = products;
    _agriculturalProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos agrícolas do cache
  List<AgriculturalProduct>? getAgriculturalProducts() {
    if (_isCacheExpired(_agriculturalProductsLastUpdate)) {
      return null;
    }
    return _agriculturalProducts;
  }

  /// Armazena culturas no cache
  void setCrops(List<app_crop.Crop> crops) {
    _crops = crops;
    _cropsLastUpdate = DateTime.now();
  }

  /// Obtém culturas do cache
  List<app_crop.Crop>? getCrops() {
    if (_isCacheExpired(_cropsLastUpdate)) {
      return null;
    }
    return _crops;
  }

  /// Armazena produtos com estoque baixo no cache
  void setLowStockProducts(List<InventoryProductModel> products) {
    _lowStockProducts = products;
    _lowStockProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos com estoque baixo do cache
  List<InventoryProductModel>? getLowStockProducts() {
    if (_isCacheExpired(_lowStockProductsLastUpdate)) {
      return null;
    }
    return _lowStockProducts;
  }

  /// Armazena produtos com estoque crítico no cache
  void setCriticalStockProducts(List<InventoryProductModel> products) {
    _criticalStockProducts = products;
    _criticalStockProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos com estoque crítico do cache
  List<InventoryProductModel>? getCriticalStockProducts() {
    if (_isCacheExpired(_criticalStockProductsLastUpdate)) {
      return null;
    }
    return _criticalStockProducts;
  }

  /// Armazena produtos próximos do vencimento no cache
  void setNearExpirationProducts(List<InventoryProductModel> products) {
    _nearExpirationProducts = products;
    _nearExpirationProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos próximos do vencimento do cache
  List<InventoryProductModel>? getNearExpirationProducts() {
    if (_isCacheExpired(_nearExpirationProductsLastUpdate)) {
      return null;
    }
    return _nearExpirationProducts;
  }

  /// Armazena produtos vencidos no cache
  void setExpiredProducts(List<InventoryProductModel> products) {
    _expiredProducts = products;
    _expiredProductsLastUpdate = DateTime.now();
  }

  /// Obtém produtos vencidos do cache
  List<InventoryProductModel>? getExpiredProducts() {
    if (_isCacheExpired(_expiredProductsLastUpdate)) {
      return null;
    }
    return _expiredProducts;
  }

  /// Adiciona um produto ao cache
  void addInventoryProduct(InventoryProductModel product) {
    if (_inventoryProducts != null) {
      // Remover produto existente com o mesmo ID, se houver
      _inventoryProducts!.removeWhere((p) => p.id == product.id);
      // Adicionar o novo produto
      _inventoryProducts!.add(product);
      _inventoryProductsLastUpdate = DateTime.now();
    }
    
    // Atualizar caches específicos
    _updateSpecificCaches(product);
  }

  /// Atualiza um produto no cache
  void updateInventoryProduct(InventoryProductModel product) {
    if (_inventoryProducts != null) {
      // Remover produto existente com o mesmo ID
      _inventoryProducts!.removeWhere((p) => p.id == product.id);
      // Adicionar o produto atualizado
      _inventoryProducts!.add(product);
      _inventoryProductsLastUpdate = DateTime.now();
    }
    
    // Atualizar caches específicos
    _updateSpecificCaches(product);
  }

  /// Remove um produto do cache
  void removeInventoryProduct(String productId) {
    if (_inventoryProducts != null) {
      _inventoryProducts!.removeWhere((p) => p.id == productId);
      _inventoryProductsLastUpdate = DateTime.now();
    }
    
    // Atualizar caches específicos
    if (_lowStockProducts != null) {
      _lowStockProducts!.removeWhere((p) => p.id == productId);
    }
    
    if (_criticalStockProducts != null) {
      _criticalStockProducts!.removeWhere((p) => p.id == productId);
    }
    
    if (_nearExpirationProducts != null) {
      _nearExpirationProducts!.removeWhere((p) => p.id == productId);
    }
    
    if (_expiredProducts != null) {
      _expiredProducts!.removeWhere((p) => p.id == productId);
    }
  }

  /// Adiciona uma transação ao cache
  void addInventoryTransaction(InventoryTransactionModel transaction) {
    if (_inventoryTransactions != null) {
      _inventoryTransactions!.add(transaction);
      _inventoryTransactionsLastUpdate = DateTime.now();
    }
  }

  /// Atualiza uma transação no cache
  void updateInventoryTransaction(InventoryTransactionModel transaction) {
    if (_inventoryTransactions != null) {
      // Remover transação existente com o mesmo ID
      _inventoryTransactions!.removeWhere((t) => t.id == transaction.id);
      // Adicionar a transação atualizada
      _inventoryTransactions!.add(transaction);
      _inventoryTransactionsLastUpdate = DateTime.now();
    }
  }

  /// Remove uma transação do cache
  void removeInventoryTransaction(String transactionId) {
    if (_inventoryTransactions != null) {
      _inventoryTransactions!.removeWhere((t) => t.id == transactionId);
      _inventoryTransactionsLastUpdate = DateTime.now();
    }
  }

  /// Atualiza caches específicos com base no produto
  void _updateSpecificCaches(InventoryProductModel product) {
    // Atualizar cache de produtos com estoque baixo
    if (_lowStockProducts != null) {
      if (product.isStockLow) {
        // Adicionar ou atualizar no cache de estoque baixo
        _lowStockProducts!.removeWhere((p) => p.id == product.id);
        _lowStockProducts!.add(product);
      } else {
        // Remover do cache de estoque baixo
        _lowStockProducts!.removeWhere((p) => p.id == product.id);
      }
    }
    
    // Atualizar cache de produtos com estoque crítico
    if (_criticalStockProducts != null) {
      if (product.isStockCritical) {
        // Adicionar ou atualizar no cache de estoque crítico
        _criticalStockProducts!.removeWhere((p) => p.id == product.id);
        _criticalStockProducts!.add(product);
      } else {
        // Remover do cache de estoque crítico
        _criticalStockProducts!.removeWhere((p) => p.id == product.id);
      }
    }
    
    // Atualizar cache de produtos próximos do vencimento
    if (_nearExpirationProducts != null) {
      if (product.isNearExpiration) {
        // Adicionar ou atualizar no cache de próximos do vencimento
        _nearExpirationProducts!.removeWhere((p) => p.id == product.id);
        _nearExpirationProducts!.add(product);
      } else {
        // Remover do cache de próximos do vencimento
        _nearExpirationProducts!.removeWhere((p) => p.id == product.id);
      }
    }
    
    // Atualizar cache de produtos vencidos
    if (_expiredProducts != null) {
      if (product.isExpired) {
        // Adicionar ou atualizar no cache de vencidos
        _expiredProducts!.removeWhere((p) => p.id == product.id);
        _expiredProducts!.add(product);
      } else {
        // Remover do cache de vencidos
        _expiredProducts!.removeWhere((p) => p.id == product.id);
      }
    }
  }
}
