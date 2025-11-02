import '../database/models/crop.dart';
import '../database/models/pest.dart';
import '../database/models/disease.dart';
import '../database/models/weed.dart';
import '../repositories/crop_repository.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../repositories/agricultural_product_repository.dart';
import '../models/agricultural_product.dart';
import '../utils/logger.dart';

class CropService {
  final CropRepository _cropRepository;
  final CropDao _cropDao;
  final PestDao _pestDao;
  final DiseaseDao _diseaseDao;
  final WeedDao _weedDao;
  final AgriculturalProductRepository _agriculturalProductRepository;

  CropService({
    CropRepository? cropRepository,
    CropDao? cropDao,
    PestDao? pestDao,
    DiseaseDao? diseaseDao,
    WeedDao? weedDao,
    AgriculturalProductRepository? agriculturalProductRepository,
  }) : 
       _cropRepository = cropRepository ?? CropRepository(),
       _cropDao = cropDao ?? CropDao(),
       _pestDao = pestDao ?? PestDao(),
       _diseaseDao = diseaseDao ?? DiseaseDao(),
       _weedDao = weedDao ?? WeedDao(),
       _agriculturalProductRepository = agriculturalProductRepository ?? AgriculturalProductRepository();

  // Inicializar dados padrão
  Future<void> initializeDefaultData() async {
    try {
      Logger.info('🔄 Inicializando dados padrão do módulo de culturas...');
      
      // Inicializar tabelas
      // await _cropDao.initialize();
      // await _pestDao.initialize();
      // await _diseaseDao.initialize();
      // await _weedDao.initialize();
      
      // Inserir dados padrão
      await _cropDao.insertDefaultCrops();
      await _pestDao.insertDefaultPests();
      await _diseaseDao.insertDefaultDiseases();
      await _weedDao.insertDefaultWeeds();
      
      Logger.info('✅ Dados padrão inicializados com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar dados padrão: $e');
      rethrow;
    }
  }

  // Métodos para Culturas
  Future<List<Crop>> getAllCrops() async {
    try {
      Logger.info('🔄 Carregando todas as culturas...');
      
      // Primeiro, garantir que as culturas padrão existem
      await _ensureDefaultCropsExist();
      
      // Tentar obter culturas do repositório principal primeiro
      final crops = await _cropRepository.getAllCrops();
      Logger.info('📊 Culturas carregadas do CropRepository: ${crops.length}');
      
      // Se encontrou culturas, retornar
      if (crops.isNotEmpty) {
        return crops;
      }
      
      // Se não encontrou culturas, tentar buscar do repositório de produtos agrícolas
      Logger.info('🔄 Nenhuma cultura encontrada no CropRepository, tentando AgriculturalProductRepository');
      return await _getFromAgriculturalProducts();
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas do CropRepository: $e');
      // Em caso de erro, tentar buscar do repositório de produtos agrícolas
      return await _getFromAgriculturalProducts();
    }
  }

  // Método auxiliar para buscar culturas do repositório de produtos agrícolas
  Future<List<Crop>> _getFromAgriculturalProducts() async {
    try {
      // Buscar produtos do tipo semente (culturas)
      final products = await _agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
      Logger.info('📊 Produtos agrícolas (sementes) carregados: ${products.length}');
      
      // Converter produtos para culturas
      final crops = products.map((product) => Crop(
        id: int.tryParse(product.id) ?? 0,
        name: product.name,
        description: product.notes ?? 'Cultura importada do módulo de Produtos Agrícolas',
        // syncStatus: product.isSynced ? 1 : 0,
        // remoteId: product.parentId,
        scientificName: product.activeIngredient, // Usando activeIngredient como substituto para scientificName
      )).toList();
      
      return crops;
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas do AgriculturalProductRepository: $e');
      return [];
    }
  }

  // Obter uma cultura pelo ID
  Future<Crop?> getCropById(int id) async {
    try {
      Logger.info('🔄 Buscando cultura por ID: $id');
      
      // Primeiro, garantir que as culturas padrão existem
      await _ensureDefaultCropsExist();
      
      // Tentar buscar do repositório principal primeiro
      final crop = await _cropRepository.getById(id);
      
      // Se encontrou, retornar
      if (crop != null) {
        Logger.info('✅ Cultura encontrada no CropRepository: ${crop.name}');
        return crop;
      }
      
      // Se não encontrou, tentar buscar do repositório de produtos agrícolas
      Logger.info('🔄 Cultura não encontrada no CropRepository, tentando AgriculturalProductRepository');
      return await _getProductById(id.toString());
    } catch (e) {
      Logger.error('❌ Erro ao buscar cultura por ID no CropRepository: $e');
      // Em caso de erro, tentar buscar do repositório de produtos agrícolas
      return await _getProductById(id.toString());
    }
  }

  // Método auxiliar para buscar um produto agrícola pelo ID e convertê-lo para cultura
  Future<Crop?> _getProductById(String id) async {
    try {
      final product = await _agriculturalProductRepository.getById(id);
      
      // Se encontrou e é do tipo semente, converter para cultura
      if (product != null && product.type == ProductType.seed) {
        Logger.info('✅ Produto agrícola encontrado e convertido para cultura: ${product.name}');
        return Crop(
          id: int.tryParse(product.id) ?? 0,
          name: product.name,
          description: product.notes ?? 'Cultura importada do módulo de Produtos Agrícolas',
          // syncStatus: product.isSynced ? 1 : 0,
          // remoteId: product.parentId,
          scientificName: product.activeIngredient,
        );
      }
      
      Logger.warning('⚠️ Produto agrícola não encontrado ou não é do tipo semente');
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar produto agrícola por ID: $e');
      return null;
    }
  }

  // Garantir que as culturas padrão existem
  Future<void> _ensureDefaultCropsExist() async {
    try {
      Logger.info('🔄 Verificando se as culturas padrão existem...');
      
      // Verificar se há culturas no banco
      final crops = await _cropRepository.getAllCrops();
      
      if (crops.isEmpty) {
        Logger.info('⚠️ Nenhuma cultura encontrada, inserindo culturas padrão...');
        await _cropDao.insertDefaultCrops();
        Logger.info('✅ Culturas padrão inseridas com sucesso');
      } else {
        Logger.info('✅ ${crops.length} culturas já existem no banco');
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar culturas padrão: $e');
      // Tentar inserir culturas padrão mesmo com erro
      try {
        await _cropDao.insertDefaultCrops();
        Logger.info('✅ Culturas padrão inseridas após erro');
      } catch (e2) {
        Logger.error('❌ Erro ao inserir culturas padrão: $e2');
      }
    }
  }

  // Verificar se uma cultura existe e criar se necessário
  Future<bool> _ensureCropExists(int cropId) async {
    try {
      Logger.info('🔄 Verificando se a cultura $cropId existe...');
      
      // Primeiro, garantir que as culturas padrão existem
      await _ensureDefaultCropsExist();
      
      // Tentar buscar a cultura
      final crops = await getAllCrops();
      final cropExists = crops.any((c) => c.id == cropId);
      
      if (!cropExists) {
        Logger.warning('⚠️ Cultura $cropId não encontrada, criando cultura padrão...');
        
        // Criar uma cultura padrão
        final defaultCrop =         Crop(
          id: cropId,
          name: 'Cultura $cropId',
          description: 'Cultura criada automaticamente',
          // syncStatus: 0,
        );
        
        final result = await _cropRepository.insertCrop(defaultCrop);
        if (result > 0) {
          Logger.info('✅ Cultura padrão criada com sucesso: $cropId');
          return true;
        } else {
          Logger.error('❌ Erro ao criar cultura padrão: $cropId');
          return false;
        }
      } else {
        Logger.info('✅ Cultura $cropId já existe no banco');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Erro ao garantir existência da cultura: $e');
      return false;
    }
  }

  Future<int> saveCrop(Crop crop) async {
    if ((crop.id ?? 0) > 0) {
      return await _cropRepository.updateCrop(crop);
    } else {
      return await _cropRepository.insertCrop(crop);
    }
  }

  Future<int> deleteCrop(int id) async {
    return await _cropRepository.deleteCrop(id);
  }

  // Métodos para Pragas
  Future<List<Pest>> getAllPests() async {
    return await _cropRepository.getAllPests();
  }

  Future<List<Pest>> getPestsByCropId(int cropId) async {
    return await _cropRepository.getPestsByCropId(cropId);
  }

  Future<Pest?> getPestById(int id) async {
    return await _cropRepository.getPestById(id);
  }

  Future<int> savePest(Pest pest) async {
    if ((pest.id ?? 0) > 0) {
      return await _cropRepository.updatePest(pest);
    } else {
      return await _cropRepository.insertPest(pest);
    }
  }

  Future<int> deletePest(int id) async {
    return await _cropRepository.deletePest(id);
  }

  // Métodos para Doenças
  Future<List<Disease>> getAllDiseases() async {
    return await _cropRepository.getAllDiseases();
  }

  Future<List<Disease>> getDiseasesByCropId(int cropId) async {
    return await _cropRepository.getDiseasesByCropId(cropId);
  }

  Future<Disease?> getDiseaseById(int id) async {
    return await _cropRepository.getDiseaseById(id);
  }

  Future<int> saveDisease(Disease disease) async {
    if ((disease.id ?? 0) > 0) {
      return await _cropRepository.updateDisease(disease);
    } else {
      return await _cropRepository.insertDisease(disease);
    }
  }

  Future<int> deleteDisease(int id) async {
    return await _cropRepository.deleteDisease(id);
  }

  // Métodos para Plantas Daninhas
  Future<List<Weed>> getAllWeeds() async {
    return await _cropRepository.getAllWeeds();
  }

  Future<List<Weed>> getWeedsByCropId(int cropId) async {
    return await _cropRepository.getWeedsByCropId(cropId);
  }

  Future<Weed?> getWeedById(int id) async {
    return await _cropRepository.getWeedById(id);
  }

  Future<int> saveWeed(Weed weed) async {
    if ((weed.id ?? 0) > 0) {
      return await _cropRepository.updateWeed(weed);
    } else {
      return await _cropRepository.insertWeed(weed);
    }
  }

  Future<int> deleteWeed(int id) async {
    return await _cropRepository.deleteWeed(id);
  }

  // Métodos para adicionar organismos
  Future<String?> addPest(int cropId, String name, String description) async {
    try {
      Logger.info('🔄 Iniciando adição de praga: $name para cultura: $cropId');
      Logger.info('📋 Parâmetros: cropId=$cropId, name=$name, description=$description');
      
      // Verificar se o cropId é válido (aceitar 0 como válido)
      if (cropId < 0) {
        Logger.error('❌ Erro: cropId é inválido (negativo)');
        return null;
      }
      
      // Garantir que a cultura existe
      final cropExists = await _ensureCropExists(cropId);
      if (!cropExists) {
        Logger.error('❌ Erro: Não foi possível garantir a existência da cultura $cropId');
        return null;
      }

      final pest = Pest(
        id: 0, // Será gerado automaticamente
        name: name,
        scientificName: name, // Usando o nome como nome científico por padrão
        description: description,
        cropId: cropId,
        // syncStatus: 0, // Não sincronizado
        // remoteId: null,
      );

      Logger.info('📋 Objeto Pest criado: ${pest.toMap()}');

      final pestId = await savePest(pest);
      Logger.info('💾 Resultado do savePest: $pestId');
      
      if (pestId > 0) {
        Logger.info('✅ Praga adicionada com sucesso: $name (ID: $pestId)');
        return pestId.toString();
      } else {
        Logger.error('❌ Erro ao salvar praga: $name (ID retornado: $pestId)');
        return null;
      }
    } catch (e) {
      Logger.error('❌ Erro ao adicionar praga: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<String?> addDisease(int cropId, String name, String description) async {
    try {
      Logger.info('🔄 Iniciando adição de doença: $name para cultura: $cropId');
      Logger.info('📋 Parâmetros: cropId=$cropId, name=$name, description=$description');
      
      // Verificar se o cropId é válido (aceitar 0 como válido)
      if (cropId < 0) {
        Logger.error('❌ Erro: cropId é inválido (negativo)');
        return null;
      }
      
      // Garantir que a cultura existe
      final cropExists = await _ensureCropExists(cropId);
      if (!cropExists) {
        Logger.error('❌ Erro: Não foi possível garantir a existência da cultura $cropId');
        return null;
      }

      final disease = Disease(
        id: 0, // Será gerado automaticamente
        name: name,
        scientificName: name, // Usando o nome como nome científico por padrão
        description: description,
        cropId: cropId,
        // syncStatus: 0, // Não sincronizado
        // remoteId: null,
      );

      Logger.info('📋 Objeto Disease criado: ${disease.toMap()}');

      final diseaseId = await saveDisease(disease);
      Logger.info('💾 Resultado do saveDisease: $diseaseId');
      
      if (diseaseId > 0) {
        Logger.info('✅ Doença adicionada com sucesso: $name (ID: $diseaseId)');
        return diseaseId.toString();
      } else {
        Logger.error('❌ Erro ao salvar doença: $name (ID retornado: $diseaseId)');
        return null;
      }
    } catch (e) {
      Logger.error('❌ Erro ao adicionar doença: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<String?> addWeed(int cropId, String name, String description) async {
    try {
      Logger.info('🔄 Iniciando adição de planta daninha: $name para cultura: $cropId');
      Logger.info('📋 Parâmetros: cropId=$cropId, name=$name, description=$description');
      
      // Verificar se o cropId é válido (aceitar 0 como válido)
      if (cropId < 0) {
        Logger.error('❌ Erro: cropId é inválido (negativo)');
        return null;
      }
      
      // Garantir que a cultura existe
      final cropExists = await _ensureCropExists(cropId);
      if (!cropExists) {
        Logger.error('❌ Erro: Não foi possível garantir a existência da cultura $cropId');
        return null;
      }

      final weed = Weed(
        id: 0, // Será gerado automaticamente
        name: name,
        scientificName: name, // Usando o nome como nome científico por padrão
        description: description,
        cropId: cropId,
        // syncStatus: 0, // Não sincronizado
        remoteId: null,
      );

      Logger.info('📋 Objeto Weed criado: ${weed.toMap()}');

      final weedId = await saveWeed(weed);
      Logger.info('💾 Resultado do saveWeed: $weedId');
      
      if (weedId > 0) {
        Logger.info('✅ Planta daninha adicionada com sucesso: $name (ID: $weedId)');
        return weedId.toString();
      } else {
        Logger.error('❌ Erro ao salvar planta daninha: $name (ID retornado: $weedId)');
        return null;
      }
    } catch (e) {
      Logger.error('❌ Erro ao adicionar planta daninha: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Métodos de atualização
  Future<bool> updatePest(Pest pest) async {
    try {
      final result = await savePest(pest);
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar praga: $e');
      return false;
    }
  }

  Future<bool> updateDisease(Disease disease) async {
    try {
      final result = await saveDisease(disease);
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar doença: $e');
      return false;
    }
  }

  Future<bool> updateWeed(Weed weed) async {
    try {
      final result = await saveWeed(weed);
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar planta daninha: $e');
      return false;
    }
  }
  
  /// Obtém variedades por ID da cultura
  Future<List<dynamic>> getVarietiesByCropId(int cropId) async {
    // Implementação temporária - retorna lista vazia
    return [];
  }
}
