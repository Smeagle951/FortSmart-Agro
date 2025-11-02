import 'package:flutter/foundation.dart';
import '../models/product_application_model.dart';

import '../../../models/agricultural_product.dart';
import '../../../services/data_cache_service.dart';
import '../../../repositories/agricultural_product_repository.dart';


/// Serviço de cache específico para o módulo de aplicação de produtos
/// Otimiza o uso de memória e reduz consultas ao banco de dados
class ProductApplicationCacheService {
  // Singleton pattern
  static final ProductApplicationCacheService _instance = ProductApplicationCacheService._internal();
  factory ProductApplicationCacheService() => _instance;
  ProductApplicationCacheService._internal();

  // Repositórios
  final AgriculturalProductRepository _productRepository = AgriculturalProductRepository();
  final DataCacheService _dataCacheService = DataCacheService();

  // Cache de dados
  final Map<String, AgriculturalProduct> _productsCache = {};
  final Map<String, Map<String, dynamic>> _plotsCache = {};
  final Map<String, Map<String, dynamic>> _cropsCache = {};
  
  // Cache de aplicações de produtos
  final Map<String, ProductApplicationModel> _applicationsCache = {};
  
  // Controle de expiração de cache
  DateTime _lastProductsUpdate = DateTime(1970);
  DateTime _lastPlotsUpdate = DateTime(1970);
  DateTime _lastCropsUpdate = DateTime(1970);
  
  // Tempo de expiração do cache (5 minutos)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Limpa todos os caches
  void clearAllCaches() {
    _productsCache.clear();
    _plotsCache.clear();
    _cropsCache.clear();
    _applicationsCache.clear();
    _lastProductsUpdate = DateTime(1970);
    _lastPlotsUpdate = DateTime(1970);
    _lastCropsUpdate = DateTime(1970);
    debugPrint('ProductApplicationCacheService: Todos os caches foram limpos');
  }

  /// Obtém um produto agrícola pelo ID, priorizando o cache
  Future<AgriculturalProduct?> getProductById(String id) async {
    // Verificar se o produto está no cache
    if (_productsCache.containsKey(id)) {
      return _productsCache[id];
    }
    
    // Se não estiver no cache, buscar do repositório
    final product = await _productRepository.getById(id);
    if (product != null) {
      _productsCache[id] = product;
    }
    
    return product;
  }

  /// Obtém todos os produtos agrícolas disponíveis, priorizando o cache
  Future<List<AgriculturalProduct>> getAvailableProducts() async {
    final now = DateTime.now();
    
    // Verificar se o cache expirou
    if (now.difference(_lastProductsUpdate) > _cacheExpiration || _productsCache.isEmpty) {
      debugPrint('ProductApplicationCacheService: Atualizando cache de produtos');
      
      // Buscar produtos do repositório
      final products = await _productRepository.getAll();
      
      // Atualizar cache
      _productsCache.clear();
      for (var product in products) {
        _productsCache[product.id] = product;
      }
      
      _lastProductsUpdate = now;
    }
    
    return _productsCache.values.toList();
  }

  /// Obtém produtos filtrados por tipo, priorizando o cache
  Future<List<AgriculturalProduct>> getProductsByType(ProductType type) async {
    final allProducts = await getAvailableProducts();
    return allProducts.where((product) => product.type == type).toList();
  }

  /// Obtém talhões disponíveis para aplicação de produtos, priorizando o cache
  Future<List<Map<String, dynamic>>> getAvailablePlots() async {
    final now = DateTime.now();
    
    // Verificar se o cache expirou
    if (now.difference(_lastPlotsUpdate) > _cacheExpiration || _plotsCache.isEmpty) {
      debugPrint('ProductApplicationCacheService: Atualizando cache de talhões');
      
      // Usar o DataCacheService para obter os talhões
      final plots = await _dataCacheService.getTalhoes();
      
      // Converter para o formato esperado e atualizar cache
      _plotsCache.clear();
      for (var plot in plots) {
        final plotData = {
          'id': plot.id.toString(),
          'name': plot.nome,
          'area': plot.area,
        };
        _plotsCache[plot.id.toString()] = plotData;
      }
      
      _lastPlotsUpdate = now;
    }
    
    return _plotsCache.values.toList();
  }

  /// Obtém culturas disponíveis para aplicação de produtos, priorizando o cache
  Future<List<Map<String, dynamic>>> getAvailableCrops() async {
    final now = DateTime.now();
    
    // Verificar se o cache expirou
    if (now.difference(_lastCropsUpdate) > _cacheExpiration || _cropsCache.isEmpty) {
      debugPrint('ProductApplicationCacheService: Atualizando cache de culturas');
      
      // Usar o DataCacheService para obter as culturas
      final crops = await _dataCacheService.getCulturas();
      
      // Converter para o formato esperado e atualizar cache
      _cropsCache.clear();
      for (var crop in crops) {
        final cropData = {
          'id': crop.id.toString(),
          'name': crop.name,
          'type': crop.description.toString(),
        };
        _cropsCache[crop.id.toString()] = cropData;
      }
      
      _lastCropsUpdate = now;
    }
    
    return _cropsCache.values.toList();
  }

  /// Salva uma aplicação de produto no cache
  void cacheApplication(ProductApplicationModel application) {
    _applicationsCache[application.id] = application;
  }

  /// Obtém uma aplicação de produto do cache
  ProductApplicationModel? getCachedApplication(String id) {
    return _applicationsCache[id];
  }

  /// Remove uma aplicação de produto do cache
  void removeCachedApplication(String id) {
    _applicationsCache.remove(id);
  }
}
