import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/agricultural_product.dart';
import '../repositories/agricultural_product_repository.dart';
import '../services/data_cache_service.dart';
import '../repositories/crop_repository.dart';
import '../repositories/crop_management_repository.dart';
import '../repositories/crop_variety_repository.dart';
import '../utils/shared_preferences_helper.dart';
import '../services/culture_import_service.dart';
import '../utils/cultura_colors.dart';

/// Serviço para integrar o módulo de culturas com o módulo de talhões
class CulturaTalhaoService {
  AgriculturalProductRepository? _culturaRepository;
  DataCacheService? _dataCacheService;
  CropRepository? _cropRepository;
  CropManagementRepository? _cropManagementRepository;
  CropItemRepository? _cropItemRepository;
  SharedPreferencesHelper? _prefsHelper;
  CultureImportService? _cultureImportService;
  
  /// Obtém a instância do AgriculturalProductRepository de forma lazy
  AgriculturalProductRepository get culturaRepository {
    _culturaRepository ??= AgriculturalProductRepository();
    return _culturaRepository!;
  }
  
  /// Obtém a instância do DataCacheService de forma lazy
  DataCacheService get dataCacheService {
    _dataCacheService ??= DataCacheService();
    return _dataCacheService!;
  }
  
  /// Obtém a instância do CropRepository de forma lazy
  CropRepository get cropRepository {
    _cropRepository ??= CropRepository();
    return _cropRepository!;
  }
  
  /// Obtém a instância do CropManagementRepository de forma lazy
  CropManagementRepository get cropManagementRepository {
    _cropManagementRepository ??= CropManagementRepository();
    return _cropManagementRepository!;
  }
  
  /// Obtém a instância do CropItemRepository de forma lazy
  CropItemRepository get cropItemRepository {
    _cropItemRepository ??= CropItemRepository();
    return _cropItemRepository!;
  }
  
  /// Obtém a instância do SharedPreferencesHelper de forma lazy
  SharedPreferencesHelper get prefsHelper {
    _prefsHelper ??= SharedPreferencesHelper();
    return _prefsHelper!;
  }
  
  /// Obtém a instância do CultureImportService de forma lazy
  CultureImportService get cultureImportService {
    _cultureImportService ??= CultureImportService();
    return _cultureImportService!;
  }
  
  /// Lista todas as culturas disponíveis no sistema
  Future<List<dynamic>> listarCulturas() async {
    try {
      print('🔄 Iniciando busca de culturas...');
      
      // PRIORIDADE 1: CultureImportService (módulo Culturas da Fazenda) - 12 culturas
      try {
        print('🔄 Tentando inicializar CultureImportService...');
        await cultureImportService.initialize();
        print('✅ CultureImportService inicializado');
        
        final cultureImportCrops = await cultureImportService.getAllCrops();
        print('📊 CultureImportService retornou: ${cultureImportCrops.length} culturas');
        
        if (cultureImportCrops.isNotEmpty) {
          final result = cultureImportCrops.map((crop) => {
            'id': crop['id']?.toString() ?? '0',
            'nome': crop['name'] ?? '',
            'cor': _obterCorPorNome(crop['name'] ?? ''),
            'descricao': crop['description'] ?? '',
          }).toList();
          
          print('✅ Retornando ${result.length} culturas do CultureImportService (FONTE PRINCIPAL)');
          for (var cultura in result) {
            print('  - ${cultura['nome']} (ID: ${cultura['id']})');
          }
          return result;
        }
      } catch (e) {
        print('❌ Erro ao buscar no CultureImportService: $e');
      }
      
      // FALLBACK: CropRepository (apenas 5 culturas - usado como backup)
      try {
        final cropCulturas = await cropRepository.getAllCrops();
        print('📊 CropRepository retornou: ${cropCulturas.length} culturas (FALLBACK)');
        
        if (cropCulturas.isNotEmpty) {
          final result = cropCulturas.map((crop) => {
            'id': crop.id.toString(),
            'nome': crop.name,
            'cor': _obterCorPorNome(crop.name),
            'descricao': crop.description ?? '',
          }).toList();
          
          print('✅ Retornando ${result.length} culturas do CropRepository (FALLBACK)');
          for (var cultura in result) {
            print('  - ${cultura['nome']} (ID: ${cultura['id']})');
          }
          return result;
        }
      } catch (e) {
        print('❌ Erro ao buscar no CropRepository: $e');
      }
      
      // Terceiro, fallback para o módulo de gerenciamento de culturas
      try {
        final cropManagementCulturas = await cropManagementRepository.getAll();
        print('📊 CropManagementRepository retornou: ${cropManagementCulturas.length} culturas');
        
        if (cropManagementCulturas.isNotEmpty) {
          final result = cropManagementCulturas.map((crop) => {
            'id': crop.id.toString(),
            'nome': crop.name,
            'cor': _obterCorPorNome(crop.name),
            'descricao': crop.notes ?? '',
          }).toList();
          
          print('✅ Retornando ${result.length} culturas do CropManagementRepository');
          return result;
        }
      } catch (e) {
        print('❌ Erro ao buscar no CropManagementRepository: $e');
      }
      
      // Quarto, se ainda não encontrou, usar o repositório de produtos agrícolas
      try {
        final culturas = await obterCulturasParaSelecao();
        print('📊 AgriculturalProductRepository retornou: ${culturas.length} culturas');
        
        if (culturas.isNotEmpty) {
          print('✅ Retornando ${culturas.length} culturas do AgriculturalProductRepository');
          return culturas;
        }
      } catch (e) {
        print('❌ Erro ao buscar no AgriculturalProductRepository: $e');
      }
      
      // Se nenhuma fonte retornou dados, criar culturas padrão
      print('⚠️ Nenhuma cultura encontrada, criando culturas padrão...');
      final culturasPadrao = [
        {'id': '1', 'nome': 'Gergelim', 'cor': _obterCorPorNome('Gergelim'), 'descricao': 'Cultura oleaginosa'},
        {'id': '2', 'nome': 'Soja', 'cor': _obterCorPorNome('Soja'), 'descricao': 'Glycine max'},
        {'id': '3', 'nome': 'Milho', 'cor': _obterCorPorNome('Milho'), 'descricao': 'Zea mays'},
        {'id': '4', 'nome': 'Algodão', 'cor': _obterCorPorNome('Algodão'), 'descricao': 'Gossypium hirsutum'},
        {'id': '5', 'nome': 'Feijão', 'cor': _obterCorPorNome('Feijão'), 'descricao': 'Phaseolus vulgaris'},
        {'id': '6', 'nome': 'Girassol', 'cor': _obterCorPorNome('Girassol'), 'descricao': 'Helianthus annuus'},
        {'id': '7', 'nome': 'Arroz', 'cor': _obterCorPorNome('Arroz'), 'descricao': 'Oryza sativa'},
        {'id': '8', 'nome': 'Sorgo', 'cor': _obterCorPorNome('Sorgo'), 'descricao': 'Sorghum bicolor'},
      ];
      
      print('✅ Retornando ${culturasPadrao.length} culturas padrão');
      return culturasPadrao;
    } catch (e) {
      print('❌ Erro geral ao listar culturas: $e');
      return [];
    }
  }
  
  /// Obtém o ícone personalizado de uma cultura pelo ID
  Future<Uint8List?> obterIconeCultura(String culturaId) async {
    try {
      // Verificar se existe um ícone personalizado nas preferências
      final iconeBase64 = await prefsHelper.getString('cultura_icone_$culturaId');
      if (iconeBase64 != null && iconeBase64.isNotEmpty) {
        return base64Decode(iconeBase64);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter ícone da cultura: $e');
      return null;
    }
  }
  
  /// Salva um ícone personalizado para uma cultura
  Future<bool> salvarIconeCultura(String culturaId, Uint8List iconeBytes) async {
    try {
      final iconeBase64 = base64Encode(iconeBytes);
      return await prefsHelper.setString('cultura_icone_$culturaId', iconeBase64);
    } catch (e) {
      debugPrint('Erro ao salvar ícone da cultura: $e');
      return false;
    }
  }
  
  /// Obtém a cor associada a uma cultura pelo nome
  Color _obterCorPorNome(String nome) {
    return obterCorCultura(nome);
  }
  
  /// Limpa o cache de culturas para forçar o recarregamento
  Future<void> limparCacheCulturas() async {
    try {
      debugPrint('Limpando cache de culturas...');
      dataCacheService.clearCropCache();
      debugPrint('Cache de culturas limpo com sucesso');
    } catch (e) {
      debugPrint('Erro ao limpar cache de culturas: $e');
    }
  }

  /// Retorna todas as culturas disponíveis para seleção no módulo de talhões
  /// Integrando com o módulo de Culturas e Pragas da Fazenda
  Future<List<AgriculturalProduct>> obterCulturas() async {
    try {
      debugPrint('Buscando culturas para o módulo de talhões com safras...');
      List<AgriculturalProduct> culturas = [];
      
      // 1. Primeiro tentar obter culturas do módulo Culturas e Pragas
      try {
        final cropManagementCulturas = await cropManagementRepository.getAll();
        debugPrint('Culturas encontradas no módulo Culturas e Pragas: ${cropManagementCulturas.length}');
        
        if (cropManagementCulturas.isNotEmpty) {
          // Converter do formato Crop para AgriculturalProduct
          culturas = cropManagementCulturas.map((crop) => AgriculturalProduct(
            id: crop.id,
            name: crop.name,
            type: ProductType.seed,
            tags: ['cultura', 'semente'],
            notes: crop.notes ?? '',
            manufacturer: '',
            isSynced: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            colorValue: '#4CAF50',
          )).toList();
          
          // Salvar no cache para futuras consultas
          dataCacheService.setCulturas(culturas);
          return culturas;
        }
      } catch (e) {
        debugPrint('Erro ao buscar culturas do módulo Culturas e Pragas: $e');
      }
      
      // 2. Tentar obter do cache
              final cacheDataCulturas = await dataCacheService.getCulturas();
      if (cacheDataCulturas.isNotEmpty) {
        debugPrint('Retornando ${cacheDataCulturas.length} culturas do cache');
        // Converter do formato Crop para AgriculturalProduct
        return cacheDataCulturas.map((crop) => AgriculturalProduct(
          id: crop.id.toString(),
          name: crop.name,
          type: ProductType.seed,
          tags: ['cultura', 'semente'],
          notes: crop.description,
          manufacturer: '',
          isSynced: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          colorValue: '#4CAF50',
        )).toList();
      }
      
      // 3. Se o cache estiver vazio, buscar diretamente do repositório
      debugPrint('Cache vazio, buscando culturas do repositório de produtos');
              final repositoryCulturas = await culturaRepository.getAll();
      
      // Filtrar apenas as culturas (sementes)
      final filteredCulturas = repositoryCulturas.where((product) => 
        product.type == ProductType.seed.index ||
        product.tags?.contains('cultura') == true ||
        product.tags?.contains('semente') == true
      ).toList();
      
      debugPrint('Culturas encontradas no repositório de produtos: ${filteredCulturas.length}');
      
      // Atualizar o cache com as culturas encontradas
      if (filteredCulturas.isNotEmpty) {
        dataCacheService.setCulturas(filteredCulturas);
      }
      
      print('Retornando ${filteredCulturas.length} culturas do repositório');
      return filteredCulturas;
    } catch (e) {
      print('Erro ao obter culturas: $e');
      // Fallback para o repositório direto se o cache falhar
      try {
        final allProducts = await culturaRepository.getAll();
        return allProducts.where((product) => 
          product.type == ProductType.seed.index ||
          product.tags?.contains('cultura') == true
        ).toList();
      } catch (innerError) {
        print('Erro secundário ao obter culturas: $innerError');
        return [];
      }
    }
  }
  
  /// Retorna uma cultura específica pelo ID
  Future<AgriculturalProduct?> obterCulturaPorId(String id) async {
    try {
      final culturas = await obterCulturas();
      return culturas.firstWhere((c) => c.id == id);
    } catch (e) {
      print('Erro ao obter cultura por ID: $e');
      return null;
    }
  }

  /// Obtém organismos (pragas, doenças, plantas daninhas) específicos de uma cultura
  /// Este método é usado pelo módulo de monitoramento para carregar apenas organismos relevantes
  Future<List<Map<String, dynamic>>> getOrganismsByCrop(String cropId) async {
    try {
      print('🔄 Buscando organismos para cultura ID: $cropId');
      
      // Primeiro, tentar obter do módulo Culturas da Fazenda (CropManagementRepository)
      try {
        final cropManagement = await cropManagementRepository.getById(cropId);
        if (cropManagement != null) {
          print('📊 Cultura encontrada no módulo Culturas da Fazenda: ${cropManagement.name}');
          
          // Buscar pragas, doenças e plantas daninhas específicas desta cultura
          final organisms = await _getOrganismsFromCropManagement(cropManagement);
          
          if (organisms.isNotEmpty) {
            print('✅ ${organisms.length} organismos encontrados para ${cropManagement.name}');
            for (var org in organisms) {
              print('  - ${org['nome']} (${org['tipo']})');
            }
            return organisms;
          }
        }
      } catch (e) {
        print('❌ Erro ao buscar no módulo Culturas da Fazenda: $e');
      }
      
      // Segundo, tentar obter do CultureImportService
      try {
        final cultureImport = await cultureImportService.getCropById(cropId);
        if (cultureImport != null) {
          print('📊 Cultura encontrada no CultureImportService: ${cultureImport['name'] ?? 'N/A'}');
          
          final organisms = await _getOrganismsFromCultureImport(cultureImport);
          
          if (organisms.isNotEmpty) {
            print('✅ ${organisms.length} organismos encontrados para ${cultureImport['name'] ?? 'N/A'}');
            return organisms;
          }
        }
      } catch (e) {
        print('❌ Erro ao buscar no CultureImportService: $e');
      }
      
      // Terceiro, fallback para dados padrão baseados no nome da cultura
      final cropName = await _getCropNameById(cropId);
      if (cropName != null) {
        print('📊 Usando dados padrão para cultura: $cropName');
        return _getDefaultOrganismsForCrop(cropName);
      }
      
      print('⚠️ Nenhum organismo encontrado para cultura ID: $cropId');
      return [];
      
    } catch (e) {
      print('❌ Erro ao obter organismos por cultura: $e');
      return [];
    }
  }

  /// Obtém organismos do módulo Culturas da Fazenda
  Future<List<Map<String, dynamic>>> _getOrganismsFromCropManagement(dynamic cropManagement) async {
    try {
      final organisms = <Map<String, dynamic>>[];
      
      // Buscar pragas da cultura
      final pests = await cropItemRepository.getPestsByCropId(cropManagement.id.toString());
      for (final pest in pests) {
        organisms.add({
          'id': pest.id.toString(),
          'nome': pest.name,
          'nome_cientifico': '',
          'tipo': 'praga',
          'categoria': 'Praga',
          'cultura_id': cropManagement.id.toString(),
          'cultura_nome': cropManagement.name,
          'descricao': pest.notes ?? '',
          'icone': '🐛',
          'ativo': true,
        });
      }
      
      // Buscar doenças da cultura
      final diseases = await cropItemRepository.getDiseasesByCropId(cropManagement.id.toString());
      for (final disease in diseases) {
        organisms.add({
          'id': disease.id.toString(),
          'nome': disease.name,
          'nome_cientifico': '',
          'tipo': 'doenca',
          'categoria': 'Doença',
          'cultura_id': cropManagement.id.toString(),
          'cultura_nome': cropManagement.name,
          'descricao': disease.notes ?? '',
          'icone': '🦠',
          'ativo': true,
        });
      }
      
      // Buscar plantas daninhas da cultura
      final weeds = await cropItemRepository.getWeedsByCropId(cropManagement.id.toString());
      for (final weed in weeds) {
        organisms.add({
          'id': weed.id.toString(),
          'nome': weed.name,
          'nome_cientifico': '',
          'tipo': 'daninha',
          'categoria': 'Planta Daninha',
          'cultura_id': cropManagement.id.toString(),
          'cultura_nome': cropManagement.name,
          'descricao': weed.notes ?? '',
          'icone': '🌿',
          'ativo': true,
        });
      }
      
      return organisms;
    } catch (e) {
      print('❌ Erro ao obter organismos do módulo Culturas da Fazenda: $e');
      return [];
    }
  }

  /// Obtém organismos do CultureImportService
  Future<List<Map<String, dynamic>>> _getOrganismsFromCultureImport(dynamic cultureImport) async {
    try {
      final organisms = <Map<String, dynamic>>[];
      
      // Buscar organismos associados à cultura
      final associatedOrganisms = await cultureImportService.getOrganismsByCrop(cultureImport.id.toString());
      
      for (final organism in associatedOrganisms) {
        organisms.add({
          'id': organism['id']?.toString() ?? '',
          'nome': organism['name'] ?? '',
          'nome_cientifico': organism['scientific_name'] ?? '',
          'tipo': organism['type']?.toString().toLowerCase() ?? '',
          'categoria': organism['type'] ?? '',
          'cultura_id': cultureImport.id.toString(),
          'cultura_nome': cultureImport.name,
          'descricao': '',
          'icone': _getOrganismIcon(organism['type']?.toString() ?? ''),
          'ativo': true,
        });
      }
      
      return organisms;
    } catch (e) {
      print('❌ Erro ao obter organismos do CultureImportService: $e');
      return [];
    }
  }

  /// Obtém o nome da cultura pelo ID
  Future<String?> _getCropNameById(String cropId) async {
    try {
      // Tentar no CropRepository
      final crop = await cropRepository.getCropById(int.tryParse(cropId) ?? 0);
      if (crop != null) return crop.name;
      
      // Tentar no CultureImportService
      final cultureImport = await cultureImportService.getCropById(cropId);
      if (cultureImport != null) return cultureImport['name'] ?? 'N/A';
      
      return null;
    } catch (e) {
      print('❌ Erro ao obter nome da cultura: $e');
      return null;
    }
  }

  /// Retorna organismos padrão baseados no nome da cultura
  List<Map<String, dynamic>> _getDefaultOrganismsForCrop(String cropName) {
    final cropNameLower = cropName.toLowerCase();
    
    // Organismos padrão por cultura
    final defaultOrganisms = <Map<String, dynamic>>[];
    
    if (cropNameLower.contains('soja')) {
      defaultOrganisms.addAll([
        {
          'id': 'soja_praga_1',
          'nome': 'Lagarta da Soja',
          'nome_cientifico': 'Anticarsia gemmatalis',
          'tipo': 'praga',
          'categoria': 'Lepidoptera',
          'cultura_id': 'soja',
          'cultura_nome': cropName,
          'descricao': 'Principal praga da soja',
          'icone': '🐛',
          'ativo': true,
        },
        {
          'id': 'soja_doenca_1',
          'nome': 'Ferrugem Asiática',
          'nome_cientifico': 'Phakopsora pachyrhizi',
          'tipo': 'doenca',
          'categoria': 'Fungo',
          'cultura_id': 'soja',
          'cultura_nome': cropName,
          'descricao': 'Doença fúngica da soja',
          'icone': '🦠',
          'ativo': true,
        },
      ]);
    } else if (cropNameLower.contains('milho')) {
      defaultOrganisms.addAll([
        {
          'id': 'milho_praga_1',
          'nome': 'Lagarta do Cartucho',
          'nome_cientifico': 'Spodoptera frugiperda',
          'tipo': 'praga',
          'categoria': 'Lepidoptera',
          'cultura_id': 'milho',
          'cultura_nome': cropName,
          'descricao': 'Principal praga do milho',
          'icone': '🐛',
          'ativo': true,
        },
      ]);
    } else if (cropNameLower.contains('algodao') || cropNameLower.contains('algodão')) {
      defaultOrganisms.addAll([
        {
          'id': 'algodao_praga_1',
          'nome': 'Bicudo do Algodoeiro',
          'nome_cientifico': 'Anthonomus grandis',
          'tipo': 'praga',
          'categoria': 'Coleoptera',
          'cultura_id': 'algodao',
          'cultura_nome': cropName,
          'descricao': 'Principal praga do algodão',
          'icone': '🐛',
          'ativo': true,
        },
      ]);
    }
    
    return defaultOrganisms;
  }

  /// Retorna ícone baseado no tipo de organismo
  String _getOrganismIcon(String type) {
    switch (type.toLowerCase()) {
      case 'praga':
      case 'pest':
        return '🐛';
      case 'doenca':
      case 'disease':
        return '🦠';
      case 'daninha':
      case 'weed':
        return '🌿';
      default:
        return '🔍';
    }
  }
  
  /// Retorna a cor associada a uma cultura específica
  /// Sistema de cores otimizado para contraste e visibilidade
  Color obterCorCultura(String culturaNome) {
    return CulturaColorsUtils.getColorForName(culturaNome);
  }
  
  /// Converte um AgriculturalProduct para um formato adequado para o módulo de talhões
  Map<String, dynamic> converterParaSelecao(AgriculturalProduct cultura) {
    return {
      'id': cultura.id,
      'nome': cultura.name,
      'cor': obterCorCultura(cultura.name),
    };
  }
  
  /// Retorna todas as culturas em um formato adequado para seleção no módulo de talhões
  Future<List<Map<String, dynamic>>> obterCulturasParaSelecao() async {
    final culturas = await obterCulturas();
    return culturas.map((c) => converterParaSelecao(c)).toList();
  }
  
  /// Gera uma lista de anos de safra para seleção
  List<String> gerarOpcoesSafra() {
    final DateTime now = DateTime.now();
    final int anoAtual = now.year;
    final List<String> opcoes = [];
    
    // Gerar opções para 3 anos anteriores e 3 anos futuros
    for (int i = -3; i <= 3; i++) {
      final int anoInicio = anoAtual + i;
      final int anoFim = anoInicio + 1;
      opcoes.add('$anoInicio/$anoFim');
    }
    
    return opcoes;
  }
  
  /// Retorna a safra atual sugerida com base na data atual
  String getSafraAtualSugerida() {
    final DateTime now = DateTime.now();
    final int anoAtual = now.year;
    final int anoFim = anoAtual + 1;
    return '$anoAtual/$anoFim';
  }
  
  /// Lista variedades de uma cultura específica
  Future<List<Map<String, dynamic>>> listarVariedadesPorCultura(String culturaId) async {
    try {
      print('🔄 Buscando variedades para cultura ID: $culturaId');
      
      // Primeiro, tentar buscar no módulo de Culturas da Fazenda
      try {
        print('🔄 Tentando buscar variedades no módulo de Culturas da Fazenda...');
        final allProducts = await culturaRepository.getAll();
        
        // Filtrar produtos que são variedades da cultura selecionada
        final variedades = allProducts.where((product) {
          // Verificar se é uma variedade (tem parentId) e se pertence à cultura selecionada
          return (product.parentId == culturaId || 
                  product.parentId?.toString() == culturaId) &&
                 (product.type == ProductType.seed.index ||
                  product.tags?.contains('variedade') == true ||
                  product.tags?.contains('semente') == true);
        }).toList();
        
        if (variedades.isNotEmpty) {
          final result = variedades.map((variedade) => {
            'id': variedade.id,
            'nome': variedade.name,
            'ciclo_dias': '120', // Valor padrão
            'descricao': variedade.notes ?? variedade.description ?? '',
          }).toList();
          
          print('✅ ${result.length} variedades encontradas no módulo de Culturas da Fazenda');
          for (var variedade in result) {
            print('  - ${variedade['nome']} (ID: ${variedade['id']})');
          }
          return result;
        } else {
          print('⚠️ Nenhuma variedade encontrada no módulo de Culturas da Fazenda');
        }
      } catch (e) {
        print('❌ Erro ao buscar no módulo de Culturas da Fazenda: $e');
      }
      
      // Segundo, tentar buscar no DataCacheService
      try {
        print('🔄 Tentando buscar variedades no DataCacheService...');
        final variedades = await dataCacheService.getVariedades(culturaId: culturaId);
        
        if (variedades.isNotEmpty) {
          final result = variedades.map((variedade) => {
            'id': variedade.id,
            'nome': variedade.name,
            'ciclo_dias': '120', // Valor padrão
            'descricao': variedade.notes ?? variedade.description ?? '',
          }).toList();
          
          print('✅ ${result.length} variedades encontradas no DataCacheService');
          for (var variedade in result) {
            print('  - ${variedade['nome']} (ID: ${variedade['id']})');
          }
          return result;
        } else {
          print('⚠️ Nenhuma variedade encontrada no DataCacheService');
        }
      } catch (e) {
        print('❌ Erro ao buscar no DataCacheService: $e');
      }
      
      // Terceiro, tentar buscar no CropRepository (DESABILITADO - dados incorretos)
      try {
        print('🔄 Tentando buscar variedades no CropRepository...');
        print('⚠️ CropRepository DESABILITADO - retorna dados incorretos (arroz em vez de soja)');
        // DESABILITADO: CropRepository está retornando "arroz" em vez de "BÁLSAMO" para soja
        // final crops = await cropRepository.getAllCrops();
        print('⚠️ Pulando CropRepository - dados inconsistentes detectados');
      } catch (e) {
        print('❌ Erro ao buscar no CropRepository: $e');
      }
      
      // Quarto, tentar buscar no CultureImportService (DESABILITADO - dados incorretos)
      try {
        print('🔄 Tentando buscar variedades no CultureImportService...');
        print('⚠️ CultureImportService DESABILITADO - retorna dados incorretos (arroz em vez de soja)');
        // DESABILITADO: CultureImportService está retornando "arroz" em vez de "BÁLSAMO" para soja
        // final allCrops = await cultureImportService.getAllCrops();
        print('⚠️ Pulando CultureImportService - dados inconsistentes detectados');
      } catch (e) {
        print('❌ Erro ao buscar no CultureImportService: $e');
      }
      
      // Quinto, tentar buscar no CropVarietyRepository (SOLUÇÃO DIRETA)
      try {
        print('🔄 Tentando buscar variedades no CropVarietyRepository...');
        final cropVarietyRepository = CropVarietyRepository();
        final variedades = await cropVarietyRepository.getByCropId(culturaId);
        
        if (variedades.isNotEmpty) {
          final result = variedades.map((variedade) => {
            'id': variedade.id,
            'nome': variedade.name,
            'ciclo_dias': variedade.cycleDays?.toString() ?? '120',
            'descricao': variedade.description ?? '',
          }).toList();
          
          print('✅ ${result.length} variedades encontradas no CropVarietyRepository');
          return result;
        } else {
          print('⚠️ Nenhuma variedade encontrada no CropVarietyRepository');
        }
      } catch (e) {
        print('❌ Erro ao buscar no CropVarietyRepository: $e');
      }
      
      // Se chegou até aqui, não encontrou variedades
      print('❌ Nenhuma variedade encontrada para cultura ID: $culturaId');
      return [];
      
    } catch (e) {
      print('❌ Erro geral ao buscar variedades: $e');
      return [];
    }
  }
}
