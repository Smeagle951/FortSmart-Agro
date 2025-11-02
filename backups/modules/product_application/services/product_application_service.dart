import 'dart:async';
import '../models/product_application_model.dart';
import '../models/application_target_model.dart';
import '../repositories/product_application_repository.dart';
import '../repositories/application_target_repository.dart';
import '../services/product_application_cache_service.dart';
import '../../../modules/stock/services/stock_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../database/models/crop.dart';

class ProductApplicationService {
  final ProductApplicationRepository _applicationRepository = ProductApplicationRepository();
  final ApplicationTargetRepository _targetRepository = ApplicationTargetRepository();
  final StockService _stockService = StockService();
  final DataCacheService _dataCacheService = DataCacheService();
  final ProductApplicationCacheService _cacheService = ProductApplicationCacheService();
  
  // Inicializar o serviço
  Future<void> init() async {
    await _applicationRepository.initTable();
    await _targetRepository.initTable();
  }
  
  // Obter uma aplicação pelo ID
  Future<ProductApplicationModel?> getApplicationById(String id) async {
    // Verificar primeiro no cache
    final cachedApplication = _cacheService.getCachedApplication(id);
    if (cachedApplication != null) {
      return cachedApplication;
    }
    
    final application = await _applicationRepository.getById(id);
    
    if (application != null) {
      // Salvar no cache para futuras consultas
      _cacheService.cacheApplication(application);
    }
    
    return application;
  }
  
  // Listar todas as aplicações
  Future<List<ProductApplicationModel>> getAllApplications() async {
    final applications = await _applicationRepository.getAll();
    
    // Armazenar todas as aplicações no cache para uso futuro
    for (var application in applications) {
      _cacheService.cacheApplication(application);
    }
    
    return applications;
  }
  
  // Listar aplicações por talhão
  Future<List<ProductApplicationModel>> getApplicationsByPlot(String plotId) async {
    return await _applicationRepository.getByPlot(plotId);
  }
  
  // Listar aplicações por cultura
  Future<List<ProductApplicationModel>> getApplicationsByCrop(String cropId) async {
    return await _applicationRepository.getByCrop(cropId);
  }
  
  // Listar aplicações por período
  Future<List<ProductApplicationModel>> getApplicationsByDateRange(DateTime start, DateTime end) async {
    return await _applicationRepository.getByDateRange(start, end);
  }
  
  // Listar aplicações por tipo (terrestre/aérea)
  Future<List<ProductApplicationModel>> getApplicationsByType(ApplicationType type) async {
    return await _applicationRepository.getByType(type);
  }
  
  // Obter estatísticas de aplicação por talhão
  Future<Map<String, dynamic>> getApplicationStatsByPlot(String plotId) async {
    return await _applicationRepository.getStatsByPlot(plotId);
  }
  
  // Salvar uma aplicação (nova ou existente)
  Future<String> saveApplication(ProductApplicationModel application, {bool deductFromStock = false}) async {
    try {
      // Verificar se é uma nova aplicação ou atualização
      final existing = application.id.isNotEmpty 
          ? await _applicationRepository.getById(application.id)
          : null;
      
      String applicationId;
      
      if (existing == null) {
        // Nova aplicação
        applicationId = await _applicationRepository.insert(application);
      } else {
        // Atualização de aplicação existente
        await _applicationRepository.update(application);
        applicationId = application.id;
      }
      
      // Deduzir produtos do estoque se solicitado
      if (deductFromStock) {
        await _deductProductsFromStock(application);
      }
      
      return applicationId;
    } catch (e) {
      print('Erro ao salvar aplicação: $e');
      throw Exception('Falha ao salvar aplicação: $e');
    }
  }
  
  // Criar uma nova aplicação
  Future<String> createApplication(ProductApplicationModel application) async {
    final id = await _applicationRepository.insert(application);
    
    // Atualizar o cache com a nova aplicação
    _cacheService.cacheApplication(application);
    
    return id;
  }
  
  // Excluir uma aplicação
  Future<bool> deleteApplication(String id) async {
    try {
      await _applicationRepository.delete(id);
      
      // Remover do cache
      _cacheService.removeCachedApplication(id);
      
      return true;
    } catch (e) {
      print('Erro ao excluir aplicação: $e');
      return false;
    }
  }
  
  // Deduzir produtos do estoque
  Future<void> _deductProductsFromStock(ProductApplicationModel application) async {
    try {
      for (var product in application.products) {
        await _stockService.deductFromStock(
          productId: product.productId,
          quantity: product.totalDose,
          unit: product.unit,
          description: 'Aplicação em ${application.plotName} - ${application.applicationDate.toString().substring(0, 10)}',
        );
      }
      
      print('Produtos deduzidos do estoque com sucesso');
    } catch (e) {
      print('Erro ao deduzir produtos do estoque: $e');
      throw Exception('Falha ao deduzir produtos do estoque: $e');
    }
  }
  
  // Obter um alvo pelo ID
  Future<ApplicationTargetModel?> getTargetById(String id) async {
    return await _targetRepository.getById(id);
  }
  
  // Listar todos os alvos
  Future<List<ApplicationTargetModel>> getAllTargets() async {
    return await _targetRepository.getAll();
  }
  
  // Listar alvos por tipo (praga, doença ou planta daninha)
  Future<List<ApplicationTargetModel>> getTargetsByType(TargetType type) async {
    return await _targetRepository.getByType(type);
  }
  
  // Buscar alvos por nome (pesquisa parcial)
  Future<List<ApplicationTargetModel>> searchTargetsByName(String query) async {
    return await _targetRepository.searchByName(query);
  }
  
  // Salvar um alvo (novo ou existente)
  Future<String> saveTarget(ApplicationTargetModel target) async {
    try {
      // Verificar se é um novo alvo ou atualização
      final existing = target.id.isNotEmpty 
          ? await _targetRepository.getById(target.id)
          : null;
      
      if (existing == null) {
        // Novo alvo
        return await _targetRepository.insert(target);
      } else {
        // Atualização de alvo existente
        await _targetRepository.update(target);
        return target.id;
      }
    } catch (e) {
      print('Erro ao salvar alvo: $e');
      throw Exception('Falha ao salvar alvo: $e');
    }
  }
  
  // Excluir um alvo
  Future<bool> deleteTarget(String id) async {
    try {
      final result = await _targetRepository.delete(id);
      return result > 0;
    } catch (e) {
      print('Erro ao excluir alvo: $e');
      throw Exception('Falha ao excluir alvo: $e');
    }
  }
  
  // Calcular o volume de calda total
  double calculateTotalSyrupVolume(double area, double syrupVolumePerHectare) {
    return area * syrupVolumePerHectare;
  }
  
  // Calcular o número de tanques necessários
  int calculateNumberOfTanks(double totalSyrupVolume, double equipmentCapacity) {
    if (equipmentCapacity <= 0) return 0;
    return (totalSyrupVolume / equipmentCapacity).ceil();
  }
  
  // Calcular a dose total de um produto
  double calculateTotalDose(double dosePerHectare, double area) {
    return dosePerHectare * area;
  }
  
  // Calcular a quantidade de produto por tanque
  double calculateProductPerTank(double totalDose, int numberOfTanks) {
    if (numberOfTanks <= 0) return 0;
    return totalDose / numberOfTanks;
  }
  
  // Validar se há estoque suficiente para todos os produtos
  Future<Map<String, dynamic>> validateStockAvailability(List<ApplicationProductModel> products) async {
    final Map<String, dynamic> result = {
      'isValid': true,
      'insufficientProducts': <Map<String, dynamic>>[],
    };
    
    for (var product in products) {
      final stockAvailable = await _stockService.getAvailableStock(product.productId);
      
      if (stockAvailable < product.totalDose) {
        result['isValid'] = false;
        result['insufficientProducts'].add({
          'productId': product.productId,
          'productName': product.productName,
          'required': product.totalDose,
          'available': stockAvailable,
          'unit': product.unit,
        });
      }
    }
    
    return result;
  }
  
  // Obter informações do talhão pelo ID
  Future<Map<String, dynamic>> getPlotInfo(String plotId) async {
    try {
      final talhao = await _dataCacheService.getTalhaoById(plotId);
      
      if (talhao == null) {
        throw Exception('Talhão não encontrado');
      }
      
      return {
        'id': talhao.id,
        'name': talhao.nome,
        'area': talhao.area,
        'cropId': talhao.culturaId,
        'cropName': talhao.cultura,
        'safra': talhao.safraAtualPeriodo,
      };
    } catch (e) {
      print('Erro ao obter informações do talhão: $e');
      throw Exception('Falha ao obter informações do talhão: $e');
    }
  }
  
  // Obter informações de uma cultura
  Future<Map<String, dynamic>?> getCropInfo(String cropId) async {
    try {
      // Tentar obter do cache primeiro para melhorar desempenho
      final crops = await _cacheService.getAvailableCrops();
      final cachedCrop = crops.firstWhere(
        (crop) => crop['id'] == cropId,
        orElse: () => <String, dynamic>{},
      );
      
      if (cachedCrop.isNotEmpty) {
        return cachedCrop;
      }
      
      // Se não estiver no cache, buscar do serviço de dados
      final allCrops = await _dataCacheService.getCulturas();
      final crop = allCrops.firstWhere(
        (c) => c.id.toString() == cropId,
        orElse: () => Crop(id: 0, name: 'Desconhecida', description: '', syncStatus: 0, remoteId: null),
      );
      
      if (crop.id == 0) return null;
      
      final cropInfo = {
        'id': crop.id.toString(),
        'name': crop.name,
        'type': crop.description.toString(),
      };
      
      return cropInfo;
    } catch (e) {
      print('Erro ao obter informações da cultura: $e');
      return null;
    }
  }
}
