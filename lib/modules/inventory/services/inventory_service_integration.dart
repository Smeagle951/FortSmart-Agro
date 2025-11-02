import 'dart:async';
import '../models/inventory_transaction_model.dart';
import '../repositories/inventory_product_repository.dart';
import '../repositories/inventory_transaction_repository.dart';
import './inventory_cache_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../database/models/crop.dart' as db_crop;
import '../../../models/crop.dart' as app_crop;
import '../../../models/agricultural_product.dart';
import '../../../modules/product_application/services/product_application_service.dart';
// Necessário para acessar InventoryProductModel no método registerProductApplication
import '../../../repositories/agricultural_product_repository.dart';
// TODO: Criar ou importar o modelo de aplicação correto
// import '../../../modules/product_application/models/application_model.dart';

/// Serviço para integração do módulo de estoque com outros módulos
/// Responsável por integração com módulo de aplicação, culturas e pragas
class InventoryServiceIntegration {
  final InventoryProductRepository _productRepository = InventoryProductRepository();
  final InventoryTransactionRepository _transactionRepository = InventoryTransactionRepository();
  final InventoryCacheService _cacheService = InventoryCacheService();
  final DataCacheService _dataCacheService = DataCacheService();
  final ProductApplicationService _applicationService = ProductApplicationService();
  
  /// Singleton para acesso global
  static final InventoryServiceIntegration _instance = InventoryServiceIntegration._internal();
  
  /// Construtor privado
  InventoryServiceIntegration._internal();
  
  /// Fábrica para acesso ao singleton
  factory InventoryServiceIntegration() {
    return _instance;
  }

  /// Obtém todas as culturas disponíveis
  Future<List<app_crop.Crop>> getAvailableCrops() async {
    try {
      // Verificar se há culturas em cache
      final cachedCrops = _cacheService.getCrops();
      if (cachedCrops != null && cachedCrops.isNotEmpty) {
        print('Retornando ${cachedCrops.length} culturas do cache');
        return cachedCrops;
      }

      // Se não estiver em cache, buscar do serviço de dados
      final dbCrops = await _dataCacheService.getCulturas();
      
      // Converter para modelo Crop do app
      final List<app_crop.Crop> appCrops = dbCrops.map((c) => _convertDbCropToAppCrop(c)).toList();
      
      // Armazenar em cache para uso futuro
      _cacheService.setCrops(appCrops);
      print('Retornando ${appCrops.length} culturas do serviço de dados');
      return appCrops;
    } catch (e) {
      print('Erro ao obter culturas: $e');
      return <app_crop.Crop>[];
    }
  }

  /// Obtém informações de uma cultura específica
  Future<Map<String, dynamic>?> getCropInfo(String cropId) async {
    try {
      // Primeiro tentar buscar do cache de culturas do app
      final appCrops = await getAvailableCrops();
      app_crop.Crop? appCultura;
      
      try {
        appCultura = appCrops.firstWhere(
          (crop) => crop.id.toString() == cropId,
        );
      } catch (e) {
        // Se não encontrar, criar uma cultura padrão
        appCultura = app_crop.Crop(
          id: 0, 
          name: 'Desconhecida', 
          description: 'Cultura não encontrada'
        );
      }
      
      // Buscar informações adicionais da cultura (pragas, doenças, etc.)
      final agriculturalProductRepository = AgriculturalProductRepository();
      final products = await agriculturalProductRepository.getAll();
      
      // Filtrar produtos relacionados à cultura (pragas, doenças, etc.)
      final relatedProducts = products.where((product) => 
        product.parentId == appCultura!.id.toString() || 
        (product.tags != null && product.tags!.any((tag) => tag.contains('crop:${appCultura?.id}'))) == true
      ).toList();
      
      return {
        'crop': {
          'id': appCultura.id,
          'name': appCultura.name,
          'scientificName': appCultura.scientificName ?? '',
          'description': appCultura.description ?? '',
        },
        'relatedProducts': relatedProducts.map((p) => {
          'id': p.id,
          'name': p.name,
          'type': p.type.toString(),
          'tags': p.tags,
        }).toList(),
      };
    } catch (e) {
      print('Erro ao obter informações da cultura: $e');
      return null;
    }
  }

  /// Método utilitário para converter Crop do banco para Crop do app
  app_crop.Crop _convertDbCropToAppCrop(dynamic dbCrop) {
    try {
      // Se já for do tipo app_crop.Crop, retornar diretamente
      if (dbCrop is app_crop.Crop) {
        return dbCrop;
      }
      
      // Se for do tipo db_crop.Crop, converter
      if (dbCrop is db_crop.Crop) {
        return app_crop.Crop(
          id: dbCrop.id,
          name: dbCrop.name,
          description: dbCrop.description,
          scientificName: dbCrop.scientificName,
          growthCycle: dbCrop.growthCycle,
          plantSpacing: dbCrop.plantSpacing,
          rowSpacing: dbCrop.rowSpacing,
          plantingDepth: dbCrop.plantingDepth,
          idealTemperature: dbCrop.idealTemperature,
          waterRequirement: dbCrop.waterRequirement,
          colorValue: dbCrop.cor,
          isSynced: dbCrop.isSynced,
        );
      }
      
      // Se for do tipo AgriculturalProduct, converter
      if (dbCrop is AgriculturalProduct) {
        return app_crop.Crop(
          id: int.tryParse(dbCrop.id) ?? 0,
          name: dbCrop.name,
          description: dbCrop.notes ?? '',
          scientificName: '',
          growthCycle: 0,
          plantSpacing: 0,
          rowSpacing: 0,
          plantingDepth: 0,
          idealTemperature: null,
          waterRequirement: null,
          colorValue: int.tryParse(dbCrop.colorValue ?? ''),
          isSynced: dbCrop.isSynced,
        );
      }
      
      // Se for um Map (dados do banco de dados)
      if (dbCrop is Map<String, dynamic>) {
        return app_crop.Crop(
          id: _parseIntSafely(dbCrop['id']) ?? 0,
          name: dbCrop['name']?.toString() ?? 'Desconhecida',
          description: dbCrop['description']?.toString() ?? '',
          scientificName: dbCrop['scientificName']?.toString() ?? dbCrop['scientific_name']?.toString(),
          growthCycle: _parseIntSafely(dbCrop['growthCycle']) ?? _parseIntSafely(dbCrop['growth_cycle']),
          plantSpacing: _parseDoubleSafely(dbCrop['plantSpacing']) ?? _parseDoubleSafely(dbCrop['plant_spacing']),
          rowSpacing: _parseDoubleSafely(dbCrop['rowSpacing']) ?? _parseDoubleSafely(dbCrop['row_spacing']),
          plantingDepth: _parseDoubleSafely(dbCrop['plantingDepth']) ?? _parseDoubleSafely(dbCrop['planting_depth']),
          idealTemperature: (_parseDoubleSafely(dbCrop['idealTemperature']) ?? _parseDoubleSafely(dbCrop['ideal_temperature']))?.toString(),
          waterRequirement: (_parseDoubleSafely(dbCrop['waterRequirement']) ?? _parseDoubleSafely(dbCrop['water_requirement']))?.toString(),
          colorValue: _parseIntSafely(dbCrop['colorValue']) ?? _parseIntSafely(dbCrop['color_value']) ?? _parseIntSafely(dbCrop['cor']),
          isSynced: _parseBoolSafely(dbCrop['isSynced']) ?? _parseBoolSafely(dbCrop['is_synced']) ?? false,
        );
      }
      
      // Caso padrão para qualquer outro tipo - criar uma cultura genérica
      return app_crop.Crop(
        id: 0,
        name: 'Desconhecida',
        description: 'Cultura não encontrada - tipo não reconhecido: ${dbCrop.runtimeType}',
        scientificName: '',
        growthCycle: 0,
        plantSpacing: 0,
        rowSpacing: 0,
        plantingDepth: 0,
        idealTemperature: null,
        waterRequirement: null,
        colorValue: null,
        isSynced: false,
      );
    } catch (e) {
      print('Erro ao converter cultura: $e');
      return app_crop.Crop(
        id: 0,
        name: 'Erro na Conversão',
        description: 'Erro ao converter cultura: $e',
      );
    }
  }

  /// Método utilitário para converter int de forma segura
  int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Método utilitário para converter double de forma segura
  double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Método utilitário para converter bool de forma segura
  bool? _parseBoolSafely(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  /// Registra uma aplicação de produto no estoque
  Future<bool> registerProductApplication(
    String productId,
    double quantity,
    String applicationId,
    String? plotId,
    String? cropId,
    {String? notes, String? batchNumber}
  ) async {
    try {
      // Obter produto atual
      final product = await _productRepository.getById(productId);
      if (product == null) {
        print('Produto não encontrado para aplicação: $productId');
        return false;
      }
      
      // Verificar se há quantidade suficiente
      if (product.quantity < quantity) {
        print('Quantidade insuficiente para aplicação: ${product.quantity} < $quantity');
        return false;
      }
      
      // Calcular nova quantidade
      final newQuantity = product.quantity - quantity;
      
      // Atualizar quantidade no repositório
      final result = await updateProductQuantity(productId, newQuantity);
      
      // Registrar transação de aplicação
      final transaction = InventoryTransactionModel(
        productId: productId,
        batchNumber: batchNumber ?? product.batchNumber,
        type: TransactionType.application,
        quantity: quantity,
        applicationId: applicationId,
        plotId: plotId,
        cropId: cropId,
        notes: notes ?? 'Aplicação de produto',
        date: DateTime.now(),
      );
      await _transactionRepository.insert(transaction);
      
      // Atualizar cache
      final updatedProduct = product.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );
      _cacheService.updateInventoryProduct(updatedProduct);
      _cacheService.addInventoryTransaction(transaction);
      
      print('Aplicação registrada com sucesso: $quantity ${product.unit} de ${product.name}');
      return result;
    } catch (e) {
      print('Erro ao registrar aplicação: $e');
      return false;
    }
  }

  /// Cancela uma aplicação de produto no estoque
  Future<bool> cancelProductApplication(String applicationId) async {
    try {
      // Obter transações da aplicação
      final transactions = await _transactionRepository.getByApplicationId(applicationId);
      if (transactions.isEmpty) {
        print('Nenhuma transação encontrada para a aplicação: $applicationId');
        return false;
      }
      
      bool allSuccess = true;
      
      // Para cada transação, reverter a quantidade no estoque
      for (var transaction in transactions) {
        // Obter produto atual
        final product = await _productRepository.getById(transaction.productId);
        if (product == null) {
          print('Produto não encontrado para reversão: ${transaction.productId}');
          allSuccess = false;
          continue;
        }
        
        // Calcular nova quantidade
        final newQuantity = product.quantity + transaction.quantity;
        
        // Atualizar quantidade no repositório
        final result = await updateProductQuantity(transaction.productId, newQuantity);
        if (!result) {
          allSuccess = false;
        }
        
        // Registrar transação de reversão
        final reversalTransaction = InventoryTransactionModel(
          productId: transaction.productId,
          batchNumber: transaction.batchNumber,
          type: TransactionType.adjustment,
          quantity: transaction.quantity,
          applicationId: applicationId,
          plotId: transaction.plotId,
          cropId: transaction.cropId,
          notes: 'Cancelamento de aplicação: ${transaction.notes}',
          date: DateTime.now(),
        );
        await _transactionRepository.insert(reversalTransaction);
        
        // Atualizar cache
        final updatedProduct = product.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
        _cacheService.updateInventoryProduct(updatedProduct);
        _cacheService.addInventoryTransaction(reversalTransaction);
        
        print('Aplicação cancelada com sucesso: ${transaction.quantity} ${product.unit} de ${product.name}');
      }
      
      return allSuccess;
    } catch (e) {
      print('Erro ao cancelar aplicação: $e');
      return false;
    }
  }

  /// Verifica se há estoque suficiente para uma aplicação
  Future<bool> checkStockForApplication(String productId, double quantity) async {
    try {
      // Obter produto atual
      final product = await _productRepository.getById(productId);
      if (product == null) {
        print('Produto não encontrado para verificação: $productId');
        return false;
      }
      
      // Verificar se há quantidade suficiente
      final hasEnoughStock = product.quantity >= quantity;
      
      print('Verificação de estoque para ${product.name}: ${product.quantity} ${product.unit} disponível, $quantity ${product.unit} necessário');
      return hasEnoughStock;
    } catch (e) {
      print('Erro ao verificar estoque para aplicação: $e');
      return false;
    }
  }

  /// Obtém informações de estoque para o módulo de aplicação
  Future<Map<String, dynamic>> getStockInfoForApplication(String productId) async {
    try {
      // Obter produto atual
      final product = await _productRepository.getById(productId);
      if (product == null) {
        print('Produto não encontrado para informações: $productId');
        return {
          'available': false,
          'message': 'Produto não encontrado no estoque',
        };
      }
      
      return {
        'available': true,
        'productId': product.id,
        'productName': product.name,
        'quantity': product.quantity,
        'unit': product.unit,
        'batchNumber': product.batchNumber,
        'expirationDate': product.expirationDate?.toIso8601String(),
        'isExpired': product.isExpired,
        'isNearExpiration': product.isNearExpiration,
        'isStockLow': product.isStockLow,
        'isStockCritical': product.isStockCritical,
      };
    } catch (e) {
      print('Erro ao obter informações de estoque: $e');
      return {
        'available': false,
        'message': 'Erro ao obter informações de estoque: $e',
      };
    }
  }

  /// Sincroniza aplicações com o estoque
  Future<Map<String, dynamic>> syncApplicationsWithInventory() async {
    try {
      // Obter todas as aplicações
      final applications = await _applicationService.getAllApplications();
      
      // Obter todas as transações de aplicação
      final applicationTransactions = await _transactionRepository.getByType('application');
      
      // Mapear transações por ID de aplicação
      final Map<String, List<InventoryTransactionModel>> transactionsByApplication = {};
      for (var transaction in applicationTransactions) {
        if (transaction.applicationId == null) continue;
        
        if (!transactionsByApplication.containsKey(transaction.applicationId!)) {
          transactionsByApplication[transaction.applicationId!] = [];
        }
        transactionsByApplication[transaction.applicationId!]!.add(transaction);
      }
      
      // Verificar aplicações sem transações de estoque
      final List<Map<String, dynamic>> applicationsWithoutTransactions = [];
      final List<Map<String, dynamic>> processedApplications = [];
      
      for (var application in applications) {
        final applicationId = application.id;
        
        if (!transactionsByApplication.containsKey(applicationId)) {
          // Aplicação sem transação de estoque
          applicationsWithoutTransactions.add({
            'applicationId': applicationId,
            'applicationDate': application.applicationDate,
            'products': application.products,
          });
        } else {
          // Aplicação com transação de estoque
          processedApplications.add({
            'applicationId': applicationId,
            'applicationDate': application.applicationDate,
            'products': application.products,
            'transactions': transactionsByApplication[applicationId],
          });
        }
      }
      
      return {
        'totalApplications': applications.length,
        'processedApplications': processedApplications.length,
        'applicationsWithoutTransactions': applicationsWithoutTransactions,
      };
    } catch (e) {
      print('Erro ao sincronizar aplicações com estoque: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Processa aplicações pendentes no estoque
  Future<Map<String, dynamic>> processApplicationsInInventory(List<dynamic> applications) async {
    try {
      final List<Map<String, dynamic>> successfulApplications = [];
      final List<Map<String, dynamic>> failedApplications = [];
      
      for (var application in applications) {
        final applicationId = application['applicationId'];
        final products = application['products'] as List<dynamic>;
        
        bool applicationSuccess = true;
        final List<Map<String, dynamic>> processedProducts = [];
        
        for (var product in products) {
          final productId = product['productId']?.toString() ?? '';
          final quantity = double.tryParse(product['quantity'].toString()) ?? 0;
          final plotId = product['plotId']?.toString();
          final cropId = product['cropId']?.toString();
          
          // Registrar aplicação no estoque
          final success = await registerProductApplication(
            productId,
            quantity,
            applicationId,
            plotId,
            cropId,
            notes: 'Aplicação sincronizada',
            batchNumber: product['batchNumber']?.toString(),
          );
          
          processedProducts.add({
            'productId': productId,
            'quantity': quantity,
            'success': success,
          });
          
          if (!success) {
            applicationSuccess = false;
          }
        }
        
        if (applicationSuccess) {
          successfulApplications.add({
            'applicationId': applicationId,
            'products': processedProducts,
          });
        } else {
          failedApplications.add({
            'applicationId': applicationId,
            'products': processedProducts,
          });
        }
      }
      
      return {
        'totalProcessed': applications.length,
        'successfulApplications': successfulApplications,
        'failedApplications': failedApplications,
      };
    } catch (e) {
      print('Erro ao processar aplicações no estoque: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Obtém estatísticas de culturas com estoque relacionado
  Future<Map<String, dynamic>> getCropStockStatistics() async {
    try {
      final crops = await getAvailableCrops();
      final List<Map<String, dynamic>> cropStats = [];
      
      for (var crop in crops) {
        // Buscar produtos relacionados à cultura
        final cropInfo = await getCropInfo(crop.id.toString());
        final relatedProducts = cropInfo?['relatedProducts'] as List<dynamic>? ?? [];
        
        // Contar aplicações da cultura
        // O método getByCropId não existe, vamos usar uma alternativa
        final allTransactions = await _transactionRepository.getAll();
        final applicationTransactions = allTransactions.where((t) => 
          t.cropId == crop.id.toString() && t.type == TransactionType.application
        ).toList();
        
        cropStats.add({
          'cropId': crop.id,
          'cropName': crop.name,
          'relatedProductsCount': relatedProducts.length,
          'applicationsCount': applicationTransactions.length,
          'totalQuantityApplied': applicationTransactions.fold<double>(
            0.0, 
            (sum, transaction) => sum + transaction.quantity
          ),
        });
      }
      
      return {
        'totalCrops': crops.length,
        'cropStatistics': cropStats,
      };
    } catch (e) {
      print('Erro ao obter estatísticas de culturas: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Valida a integridade dos dados entre culturas e estoque
  Future<Map<String, dynamic>> validateCropInventoryIntegrity() async {
    try {
      final List<Map<String, dynamic>> issues = [];
      
      // Verificar culturas sem produtos relacionados
      final crops = await getAvailableCrops();
      for (var crop in crops) {
        final cropInfo = await getCropInfo(crop.id.toString());
        final relatedProducts = cropInfo?['relatedProducts'] as List<dynamic>? ?? [];
        
        if (relatedProducts.isEmpty) {
          issues.add({
            'type': 'crop_without_products',
            'cropId': crop.id,
            'cropName': crop.name,
            'description': 'Cultura sem produtos relacionados no estoque',
          });
        }
      }
      
      // Verificar transações com culturas inexistentes
      final allTransactions = await _transactionRepository.getAll();
      final cropIds = crops.map((c) => c.id.toString()).toSet();
      
      for (var transaction in allTransactions) {
        if (transaction.cropId != null && !cropIds.contains(transaction.cropId)) {
          issues.add({
            'type': 'transaction_invalid_crop',
            'transactionId': transaction.id,
            'cropId': transaction.cropId,
            'description': 'Transação referencia cultura inexistente',
          });
        }
      }
      
      return {
        'isValid': issues.isEmpty,
        'issuesCount': issues.length,
        'issues': issues,
      };
    } catch (e) {
      print('Erro ao validar integridade: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Obtém transações de aplicação para uma cultura específica
  Future<List<InventoryTransactionModel>> getApplicationTransactionsForCrop(String cropId) async {
    try {
      final applicationTransactions = await _transactionRepository.getByType('application');
      
      // Filtrar transações que pertencem à cultura específica
      return applicationTransactions.where((transaction) => 
        transaction.cropId == cropId
      ).toList();
    } catch (e) {
      print('Erro ao obter transações de aplicação para cultura: $e');
      return [];
    }
  }

  /// Atualiza a quantidade de um produto
  Future<bool> updateProductQuantity(String productId, double newQuantity) async {
    try {
      final product = await _productRepository.getById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(quantity: newQuantity);
        await _productRepository.update(updatedProduct);
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao atualizar quantidade do produto: $e');
      return false;
    }
  }

  /// Calcula o total de produto aplicado em uma cultura
  Future<double> getTotalAppliedForCrop(String cropId) async {
    try {
      final transactions = await getApplicationTransactionsForCrop(cropId);
      double total = 0.0;
      for (var transaction in transactions) {
        total += transaction.quantity;
      }
      return total;
    } catch (e) {
      print('Erro ao calcular total aplicado para cultura: $e');
      return 0.0;
    }
  }
}