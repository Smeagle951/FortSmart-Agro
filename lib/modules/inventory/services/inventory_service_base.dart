import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../repositories/inventory_product_repository.dart';
import '../repositories/inventory_transaction_repository.dart';
import './inventory_cache_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../utils/logger.dart';

/// Serviço principal para gerenciamento de estoque
class InventoryServiceBase {
  final InventoryProductRepository _productRepository = InventoryProductRepository();
  final InventoryTransactionRepository _transactionRepository = InventoryTransactionRepository();
  final InventoryCacheService _cacheService = InventoryCacheService();
  final DataCacheService _dataCacheService = DataCacheService();

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      await _productRepository.createTable();
      await _transactionRepository.createTable();
      Logger.info('Serviço de inventário inicializado com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de inventário: $e');
      rethrow;
    }
  }

  /// Inicializa as tabelas no banco de dados
  Future<void> initTables() async {
    try {
      await _productRepository.createTable();
      await _transactionRepository.createTable();
      Logger.info('Tabelas de inventário inicializadas com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar tabelas de inventário: $e');
      rethrow;
    }
  }

  /// Obtém produtos paginados
  Future<List<InventoryProductModel>> getProductsPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      return await _productRepository.getPaginated(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      Logger.error('Erro ao obter produtos paginados: $e');
      return [];
    }
  }

  /// Obtém produtos filtrados
  Future<List<InventoryProductModel>> getProductsFiltered({
    String? categoryFilter,
    String? classFilter,
    String? searchQuery,
    bool? lowStockOnly,
    bool? nearExpirationOnly,
  }) async {
    try {
      return await _productRepository.getFiltered(
        categoryFilter: categoryFilter,
        classFilter: classFilter,
        searchQuery: searchQuery,
        lowStockOnly: lowStockOnly,
        nearExpirationOnly: nearExpirationOnly,
      );
    } catch (e) {
      Logger.error('Erro ao obter produtos filtrados: $e');
      return [];
    }
  }

  /// Obtém a contagem total de produtos
  Future<int> getProductsCount() async {
    try {
      final products = await _productRepository.getAll();
      return products.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem de produtos: $e');
      return 0;
    }
  }

  /// Obtém a contagem de produtos com filtros
  Future<int> getFilteredProductsCount({
    String? categoryFilter,
    String? classFilter,
    String? searchQuery,
    bool? lowStockOnly,
    bool? nearExpirationOnly,
  }) async {
    try {
      final products = await _productRepository.getFiltered(
        categoryFilter: categoryFilter,
        classFilter: classFilter,
        searchQuery: searchQuery,
        lowStockOnly: lowStockOnly,
        nearExpirationOnly: nearExpirationOnly,
      );
      return products.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem filtrada de produtos: $e');
      return 0;
    }
  }
}
