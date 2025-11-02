import 'dart:async';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../repositories/inventory_product_repository.dart';
import '../repositories/inventory_transaction_repository.dart';
import '../../../database/app_database.dart';
import './inventory_cache_service.dart';
import './inventory_service_base.dart';
import './inventory_service_product_operations.dart';
import './inventory_service_transactions.dart';
import './inventory_service_integration.dart';
// import '../../../services/data_cache_service.dart'; // Não utilizado diretamente neste arquivo
import '../../../models/agricultural_product.dart';
// import '../../../database/models/crop.dart' as db_crop; // Não utilizado diretamente neste arquivo
import '../../../models/crop.dart' as app_crop;
import '../../../utils/logger.dart';

/// Serviço principal para gerenciamento de estoque
/// Integra todas as funcionalidades do módulo de estoque
class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  
  factory InventoryService() {
    return _instance;
  }
  
  InventoryService._internal() {
    // Inicialização do serviço
    _initService();
  }
  
  // Instâncias dos serviços especializados
  final InventoryServiceBase _baseService = InventoryServiceBase();
  final InventoryServiceProductOperations _productOperations = InventoryServiceProductOperations();
  final InventoryServiceTransactions _transactionService = InventoryServiceTransactions();
  final InventoryServiceIntegration _integrationService = InventoryServiceIntegration();
  
  // Repositórios
  final InventoryProductRepository _productRepository = InventoryProductRepository();
  final InventoryTransactionRepository _transactionRepository = InventoryTransactionRepository();
  
  // Serviço de cache
  final InventoryCacheService _cacheService = InventoryCacheService();
  
  // Banco de dados
  final AppDatabase _appDatabase = AppDatabase();
  
  // Inicialização do serviço
  Future<void> _initService() async {
    try {
      // Inicializar tabelas no banco de dados
      await _baseService.initTables();
      
      // Verificar e criar tabela inventory_products se necessário
      await _ensureInventoryProductsTable();
      
      print('Serviço de estoque inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço de estoque: $e');
    }
  }
  
  /// Garante que a tabela inventory_products existe
  Future<void> _ensureInventoryProductsTable() async {
    try {
      final db = await _appDatabase.database;
      
      // Verificar se a tabela existe
      final result = await db.rawQuery('''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='inventory_products'
      ''');
      
      if (result.isEmpty) {
        print('🔄 Criando tabela inventory_products...');
        
        // Criar a tabela
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inventory_products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            class TEXT NOT NULL,
            unit TEXT NOT NULL,
            min_stock REAL NOT NULL DEFAULT 0,
            max_stock REAL,
            current_stock REAL NOT NULL DEFAULT 0,
            price REAL,
            supplier TEXT,
            batch_number TEXT,
            expiration_date TEXT,
            manufacturing_date TEXT,
            registration_number TEXT,
            active_ingredient TEXT,
            concentration TEXT,
            formulation TEXT,
            toxicity_class TEXT,
            application_method TEXT,
            waiting_period INTEGER,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        
        // Criar índices
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_inventory_products_name 
          ON inventory_products (name)
        ''');
        
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_inventory_products_category 
          ON inventory_products (category)
        ''');
        
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_inventory_products_class 
          ON inventory_products (class)
        ''');
        
        print('✅ Tabela inventory_products criada com sucesso');
      } else {
        print('ℹ️ Tabela inventory_products já existe');
      }
      
    } catch (e) {
      print('❌ Erro ao verificar/criar tabela inventory_products: $e');
      rethrow;
    }
  }
  
  //
  // Métodos de acesso aos produtos
  //
  
  /// Obtém todos os produtos
  Future<List<InventoryProductModel>> getAllProducts() async {
    try {
      return await _productRepository.getAll();
    } catch (e) {
      Logger.error('Erro ao obter todos os produtos: $e');
      return [];
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
    String? nameFilter,
    int? typeFilter,
    String? classFilter,
    bool? lowStockFilter,
    bool? criticalStockFilter,
    bool? expiringFilter,
    bool? expiredFilter,
    int? limit,
    int? offset,
    String? orderBy,
    bool? descending,
  }) async {
    try {
      return await _productRepository.getFiltered(
        nameFilter: nameFilter,
        typeFilter: typeFilter,
        classFilter: classFilter,
        lowStockFilter: lowStockFilter,
        criticalStockFilter: criticalStockFilter,
        expiringFilter: expiringFilter,
        expiredFilter: expiredFilter,
        limit: limit,
        offset: offset,
        orderBy: orderBy,
        descending: descending,
      );
    } catch (e) {
      Logger.error('Erro ao obter produtos filtrados: $e');
      return [];
    }
  }

  /// Obtém a contagem total de produtos
  Future<int> getProductCount() async {
    try {
      final products = await _productRepository.getAll();
      return products.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem de produtos: $e');
      return 0;
    }
  }

  /// Obtém a contagem de produtos com filtros
  Future<int> getFilteredProductCount({
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

  /// Obtém um produto pelo ID
  Future<InventoryProductModel?> getProductById(String id) async {
    try {
      return await _productRepository.getById(id);
    } catch (e) {
      Logger.error('Erro ao obter produto por ID: $e');
      return null;
    }
  }
  
  /// Obtém produtos com estoque baixo
  Future<List<InventoryProductModel>> getLowStockProducts() async {
    try {
      final products = await _productRepository.getAll();
      final lowStockProducts = products.where((p) => p.isStockLow).toList();
      return lowStockProducts;
    } catch (e) {
      Logger.error('Erro ao obter produtos com estoque baixo: $e');
      return [];
    }
  }

  /// Obtém produtos com estoque crítico
  Future<List<InventoryProductModel>> getCriticalStockProducts() async {
    try {
      final products = await _productRepository.getAll();
      final criticalStockProducts = products.where((p) => p.isStockCritical).toList();
      return criticalStockProducts;
    } catch (e) {
      Logger.error('Erro ao obter produtos com estoque crítico: $e');
      return [];
    }
  }

  /// Obtém produtos próximos do vencimento
  Future<List<InventoryProductModel>> getNearExpirationProducts() async {
    try {
      final products = await _productRepository.getAll();
      final nearExpirationProducts = products.where((p) => p.isNearExpiration).toList();
      return nearExpirationProducts;
    } catch (e) {
      Logger.error('Erro ao obter produtos próximos do vencimento: $e');
      return [];
    }
  }

  /// Obtém produtos vencidos
  Future<List<InventoryProductModel>> getExpiredProducts() async {
    try {
      final products = await _productRepository.getAll();
      final expiredProducts = products.where((p) => p.isExpired).toList();
      return expiredProducts;
    } catch (e) {
      Logger.error('Erro ao obter produtos vencidos: $e');
      return [];
    }
  }
  
  //
  // Métodos de operações com produtos
  //
  
  /// Adiciona um novo produto ao estoque
  Future<String?> addProduct(InventoryProductModel product) => _productOperations.addProduct(product);
  
  /// Atualiza um produto existente
  Future<bool> updateProduct(InventoryProductModel product) => _productOperations.updateProduct(product);
  
  /// Remove um produto do estoque
  Future<bool> deleteProduct(String id) async {
    try {
      return await _productRepository.delete(id) > 0;
    } catch (e) {
      Logger.error('Erro ao remover produto: $e');
      return false;
    }
  }

  /// Adiciona quantidade a um produto
  Future<bool> addProductQuantity(String id, double quantity, {String? notes}) async {
    try {
      final product = await _productRepository.getById(id);
      if (product != null) {
        final newQuantity = product.quantity + quantity;
        final updatedProduct = product.copyWith(quantity: newQuantity);
        await _productRepository.update(updatedProduct);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao adicionar quantidade: $e');
      return false;
    }
  }

  /// Remove quantidade de um produto
  Future<bool> removeProductQuantity(String id, double quantity, {String? notes}) async {
    try {
      final product = await _productRepository.getById(id);
      if (product != null) {
        final newQuantity = product.quantity - quantity;
        if (newQuantity >= 0) {
          final updatedProduct = product.copyWith(quantity: newQuantity);
          await _productRepository.update(updatedProduct);
          return true;
        }
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao remover quantidade: $e');
      return false;
    }
  }
  
  /// Obtém produtos agrícolas para seleção
  Future<List<AgriculturalProduct>> getAgriculturalProducts() => _productOperations.getAgriculturalProducts();
  
  /// Verifica se um produto existe no estoque pelo ID do produto agrícola
  Future<bool> productExistsByAgriculturalId(String agriculturalId) => 
    _productOperations.productExistsByAgriculturalId(agriculturalId);
  
  //
  // Métodos de transações
  //
  
  /// Obtém todas as transações de estoque
  Future<List<InventoryTransactionModel>> getAllTransactions() => _transactionService.getAllTransactions();
  
  /// Obtém transações com paginação
  Future<List<InventoryTransactionModel>> getTransactionsPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      return await _transactionRepository.getPaginated(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      Logger.error('Erro ao obter transações paginadas: $e');
      return [];
    }
  }
  
  /// Obtém transações de um produto específico
  Future<List<InventoryTransactionModel>> getTransactionsByProductId(String productId) async {
    try {
      return await _transactionRepository.getByProductId(productId);
    } catch (e) {
      Logger.error('Erro ao obter transações por produto: $e');
      return [];
    }
  }

  /// Obtém transações de um lote específico
  Future<List<InventoryTransactionModel>> getTransactionsByBatchNumber(String batchNumber) async {
    try {
      return await _transactionRepository.getByBatchNumber(batchNumber);
    } catch (e) {
      Logger.error('Erro ao obter transações por lote: $e');
      return [];
    }
  }

  /// Obtém transações de uma aplicação específica
  Future<List<InventoryTransactionModel>> getTransactionsByApplicationId(String applicationId) async {
    try {
      return await _transactionRepository.getByApplicationId(applicationId);
    } catch (e) {
      Logger.error('Erro ao obter transações por aplicação: $e');
      return [];
    }
  }

  /// Obtém transações por período
  Future<List<InventoryTransactionModel>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _transactionRepository.getByDateRange(startDate, endDate);
    } catch (e) {
      Logger.error('Erro ao obter transações por período: $e');
      return [];
    }
  }

  /// Obtém transações com filtros
  Future<List<InventoryTransactionModel>> getTransactionsFiltered({
    String? productId,
    String? transactionType,
    String? batchNumber,
    String? applicationId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
    String orderBy = 'date',
    bool descending = true,
  }) async {
    try {
      return await _transactionRepository.getFiltered(
        productId: productId,
        transactionType: transactionType,
        batchNumber: batchNumber,
        applicationId: applicationId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      Logger.error('Erro ao obter transações filtradas: $e');
      return [];
    }
  }
  
  /// Obtém transações de um produto específico
  Future<List<InventoryTransactionModel>> getProductTransactions(
    String productId, {
    int? limit,
    int? offset,
    String? orderBy,
    bool? descending,
  }) async {
    try {
      return await _transactionRepository.getByProductId(
        productId,
        limit: limit,
        offset: offset,
        orderBy: orderBy,
        descending: descending,
      );
    } catch (e) {
      Logger.error('Erro ao obter transações do produto: $e');
      return [];
    }
  }

  /// Obtém a contagem total de transações
  Future<int> getTransactionCount() async {
    try {
      final transactions = await _transactionRepository.getAll();
      return transactions.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem de transações: $e');
      return 0;
    }
  }

  /// Obtém a contagem de transações com filtros
  Future<int> getFilteredTransactionCount({
    String? productId,
    String? transactionType,
    String? batchNumber,
    String? applicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await _transactionRepository.getFiltered(
        productId: productId,
        transactionType: transactionType,
        batchNumber: batchNumber,
        applicationId: applicationId,
        startDate: startDate,
        endDate: endDate,
      );
      return transactions.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem filtrada de transações: $e');
      return 0;
    }
  }
  
  /// Gera dados para relatório de movimentação de estoque
  Future<Map<String, dynamic>> generateStockMovementReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // TODO: Implementar relatório de movimentação
      return {
        'startDate': startDate,
        'endDate': endDate,
        'totalProducts': 0,
        'items': [],
      };
    } catch (e) {
      Logger.error('Erro ao gerar relatório de movimentação: $e');
      return {
        'startDate': startDate,
        'endDate': endDate,
        'totalProducts': 0,
        'items': [],
        'error': e.toString(),
      };
    }
  }
  
  /// Gera dados para relatório de estoque atual
  Future<Map<String, dynamic>> generateCurrentStockReport({
    bool includeLowStock = true,
    bool includeCriticalStock = true,
    bool includeNearExpiration = true,
    bool includeExpired = true,
  }) async {
    try {
      // TODO: Implementar relatório de estoque atual
      return {
        'date': DateTime.now(),
        'totalProducts': 0,
        'products': [],
        'productsByType': {},
        'totalQuantityByType': {},
        'lowStockProducts': [],
        'criticalStockProducts': [],
        'nearExpirationProducts': [],
        'expiredProducts': [],
      };
    } catch (e) {
      Logger.error('Erro ao gerar relatório de estoque atual: $e');
      return {
        'date': DateTime.now(),
        'totalProducts': 0,
        'products': [],
        'productsByType': {},
        'totalQuantityByType': {},
        'lowStockProducts': [],
        'criticalStockProducts': [],
        'nearExpirationProducts': [],
        'expiredProducts': [],
        'error': e.toString(),
      };
    }
  }
  
  //
  // Métodos de integração
  //
  
  /// Obtém todas as culturas disponíveis
  Future<List<app_crop.Crop>> getAvailableCrops() => _integrationService.getAvailableCrops();
  
  /// Obtém informações de uma cultura específica
  Future<Map<String, dynamic>?> getCropInfo(String cropId) => _integrationService.getCropInfo(cropId);
  
  /// Registra uma aplicação de produto no estoque
  Future<bool> registerProductApplication(
    String productId,
    double quantity,
    String applicationId,
    String? plotId,
    String? cropId,
    {String? notes}
  ) => _integrationService.registerProductApplication(
    productId,
    quantity,
    applicationId,
    plotId,
    cropId,
    notes: notes,
  );
  
  /// Cancela uma aplicação de produto no estoque
  Future<bool> cancelProductApplication(String applicationId) => 
    _integrationService.cancelProductApplication(applicationId);
  
  /// Verifica se há estoque suficiente para uma aplicação
  Future<bool> checkStockForApplication(String productId, double quantity) => 
    _integrationService.checkStockForApplication(productId, quantity);
  
  /// Obtém informações de estoque para o módulo de aplicação
  Future<Map<String, dynamic>> getStockInfoForApplication(String productId) => 
    _integrationService.getStockInfoForApplication(productId);
  
  /// Sincroniza aplicações com o estoque
  Future<Map<String, dynamic>> syncApplicationsWithInventory() => 
    _integrationService.syncApplicationsWithInventory();
  
  /// Processa aplicações pendentes no estoque
  Future<Map<String, dynamic>> processApplicationsInInventory(List<dynamic> applications) => 
    _integrationService.processApplicationsInInventory(applications);
  
  //
  // Métodos de gerenciamento de cache
  //
  
  /// Limpa todos os caches
  void clearAllCaches() => _cacheService.clearAll();
  
  /// Limpa o cache de produtos
  void clearProductsCache() => _cacheService.clearInventoryProducts();
  
  /// Limpa o cache de transações
  void clearTransactionsCache() => _cacheService.clearInventoryTransactions();
  
  /// Limpa o cache de produtos agrícolas
  void clearAgriculturalProductsCache() => _cacheService.clearAgriculturalProducts();
  
  /// Limpa o cache de culturas
  void clearCropsCache() => _cacheService.clearCrops();
  
  /// Atualiza todos os caches
  Future<void> refreshAllCaches() async {
    try {
      // Obter dados atualizados
      final products = await _productRepository.getAll();
      final transactions = await _transactionRepository.getAll();
      final agriculturalProducts = await _cacheService.getDataCacheService().getAgriculturalProducts();
      final crops = await _cacheService.getDataCacheService().getCulturas();
      
      // Atualizar caches
      _cacheService.setInventoryProducts(products);
      _cacheService.setInventoryTransactions(transactions);
      // Armazenar produtos agrícolas diretamente no cache
      _cacheService.setAgriculturalProducts(agriculturalProducts);
      // Converter culturas do banco para o modelo do app antes de armazenar no cache
      final List<app_crop.Crop> appCrops = [];
      
      // Processar a lista de culturas
      if (crops.isNotEmpty) {
        // Determinar a estratégia de conversão com base no tipo dos objetos
        bool isAgriculturalProductList = false;
        try {
          // Tentar acessar uma propriedade específica de AgriculturalProduct
          final firstItem = crops.first;
          // Se conseguir acessar a propriedade 'notes', é provavelmente um AgriculturalProduct
          final _ = firstItem.notes;
          isAgriculturalProductList = true;
        } catch (_) {
          // Se falhar, não é um AgriculturalProduct
          isAgriculturalProductList = false;
        }
        
        if (isAgriculturalProductList) {
          // Se for AgriculturalProduct, converter para app_crop.Crop
          for (var product in crops) {
            try {
              final appCrop = app_crop.Crop(
                id: int.tryParse(product.id) ?? 0,
                name: product.name,
                description: product.notes ?? '',
                scientificName: '',
                colorValue: product.colorValue != null ? int.tryParse(product.colorValue ?? '') : null,
              );
              appCrops.add(appCrop);
            } catch (e) {
              print('Erro ao converter produto agrícola para cultura: $e');
            }
          }
        } else {
          // Tentar usar o método estático fromDbModelList
          try {
            // Aqui assumimos que crops é uma lista de db_crop.Crop
            for (var dbCrop in crops) {
              try {
                final appCrop = app_crop.Crop(
                  id: dbCrop.id is int ? (dbCrop.id as int) : (int.tryParse(dbCrop.id.toString()) ?? 0),
                  name: dbCrop.name,
                  description: dbCrop.description ?? '',
                  isSynced: dbCrop.isSynced == true,
                );
                appCrops.add(appCrop);
              } catch (e) {
                print('Erro ao converter cultura individual: $e');
              }
            }
          } catch (e) {
            print('Erro ao converter culturas: $e');
          }
        }
      }
      _cacheService.setCrops(appCrops);
      
      // Atualizar caches específicos
      final lowStockProducts = products.where((p) => p.isStockLow).toList();
      final criticalStockProducts = products.where((p) => p.isStockCritical).toList();
      final nearExpirationProducts = products.where((p) => p.isNearExpiration).toList();
      final expiredProducts = products.where((p) => p.isExpired).toList();
      
      _cacheService.setLowStockProducts(lowStockProducts);
      _cacheService.setCriticalStockProducts(criticalStockProducts);
      _cacheService.setNearExpirationProducts(nearExpirationProducts);
      _cacheService.setExpiredProducts(expiredProducts);
      
      print('Todos os caches atualizados com sucesso');
    } catch (e) {
      print('Erro ao atualizar caches: $e');
    }
  }

  getTransactions(String id) {}
}
