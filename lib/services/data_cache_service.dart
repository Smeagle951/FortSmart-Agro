import 'package:flutter/material.dart';
import '../repositories/crop_repository.dart';
import '../repositories/plot_repository.dart';
// Removido: machine_repository.dart e machine.dart - arquivos não existem
import '../models/crop_model.dart' as app_crop;
import '../models/plot.dart';
import '../repositories/agricultural_product_repository.dart';
import '../models/agricultural_product.dart';
import '../repositories/talhao_repository_v2.dart';
import '../repositories/talhoes/talhao_sqlite_repository.dart';
import '../models/talhao_model.dart';
import '../models/safra_model.dart';
// Importando o Crop do banco de dados com um alias para evitar conflitos
import '../database/models/crop.dart' as db_crop;
// ProductType está definido dentro de agricultural_product.dart
// Removido import do mapbox_gl que estava causando erro de compilação
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:convert';
import '../utils/logger.dart';
import '../utils/machine_type_extension.dart';
import '../models/poligono_model.dart';
import 'package:uuid/uuid.dart';
import 'culture_import_service.dart';

/// Serviço de cache de dados para facilitar a integração entre módulos antigos e novos
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Repositórios
  final CropRepository _cropRepository = CropRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final AgriculturalProductRepository _agriculturalProductRepository = AgriculturalProductRepository();
  final TalhaoRepositoryV2 _talhaoRepositoryV2 = TalhaoRepositoryV2();
  final TalhaoSQLiteRepository _talhaoSQLiteRepository = TalhaoSQLiteRepository();

  // Cache de dados
  List<db_crop.Crop>? _crops;
  List<Plot>? _plots;
  // Removido: List<Machine>? _machines; - arquivo machine.dart não existe
  Map<String, List<AgriculturalProduct>> _agriculturalProductsCache = {};
  List<TalhaoModel>? _talhoes;
  List<SafraModel>? _safras;

  /// Retorna todos os plantios (stub temporário)
  Future<List<dynamic>> getPlantios() async {
    // TODO: Implementar método real quando o modelo PlantioModel estiver disponível
    return [];
  }

  /// Carrega a lista de talhões
  Future<List<TalhaoModel>> getTalhoes() async {
    try {
      // Verificar se já temos cache válido
      if (_talhoes != null) {
        debugPrint('DataCacheService: Retornando talhões do cache (${_talhoes!.length} talhões)');
        return _talhoes!;
      }

      return await _carregarTalhoes();
    } catch (e) {
      debugPrint('DataCacheService: Erro geral ao carregar talhões: $e');
      return [];
    }
  }

  /// Força a recarga dos talhões (limpa o cache)
  Future<List<TalhaoModel>> recarregarTalhoes() async {
    try {
      debugPrint('DataCacheService: Forçando recarga de talhões...');
      _talhoes = null; // Limpar cache
      return await _carregarTalhoes();
    } catch (e) {
      debugPrint('DataCacheService: Erro ao recarregar talhões: $e');
      return [];
    }
  }

  /// Atualiza o cache de subáreas
  Future<void> refreshSubareas() async {
    try {
      debugPrint('DataCacheService: Atualizando cache de subáreas...');
      // Por enquanto, apenas limpa o cache para forçar recarga
      // TODO: Implementar cache específico para subáreas quando necessário
    } catch (e) {
      debugPrint('DataCacheService: Erro ao atualizar cache de subáreas: $e');
    }
  }

  /// Método interno para carregar talhões de todas as fontes
  Future<List<TalhaoModel>> _carregarTalhoes() async {
    debugPrint('DataCacheService: Carregando talhões de todas as fontes...');
    List<TalhaoModel> talhoesCarregados = [];
    
    // Primeiro tenta carregar do repositório SQLite
    try {
      final talhoesSQL = await _talhaoSQLiteRepository.listarTodos();
      debugPrint('DataCacheService: Talhões do SQLite: ${talhoesSQL.length}');
      talhoesCarregados.addAll(talhoesSQL.cast<TalhaoModel>());
    } catch (e) {
      debugPrint('DataCacheService: Erro ao carregar talhões do SQLite: $e');
    }

    // Tenta buscar do repositório V2 (mesmo que já tenha encontrado alguns)
    try {
      final talhoesV2 = await _talhaoRepositoryV2.listarTodos();
      debugPrint('DataCacheService: Talhões do V2: ${talhoesV2.length}');
      
      // Adicionar apenas os talhões que não estão na lista
      for (var talhao in talhoesV2) {
        if (!talhoesCarregados.any((t) => t.id == talhao.id)) {
          talhoesCarregados.add(talhao);
        }
      }
    } catch (e) {
      debugPrint('DataCacheService: Erro ao carregar talhões do V2: $e');
    }

    // Tenta buscar do repositório antigo (mesmo que já tenha encontrado alguns)
    try {
      final plots = await _plotRepository.getPlots();
      debugPrint('DataCacheService: Plots do repositório antigo: ${plots.length}');
      
      for (var plot in plots) {
        // Verificar se o plot já existe na lista de talhões carregados
        if (talhoesCarregados.any((t) => t.id == plot.id)) continue;
        
        // Extrair coordenadas do polygonJson se disponível
        List<latlong2.LatLng> pontos = [];
        try {
          if (plot.polygonJson != null && plot.polygonJson!.isNotEmpty) {
            final polygonData = jsonDecode(plot.polygonJson!) as List<dynamic>;
            pontos = polygonData.map((point) {
              final Map<String, dynamic> pointMap = point as Map<String, dynamic>;
              return latlong2.LatLng(
                pointMap['latitude'] is double ? pointMap['latitude'] : double.parse(pointMap['latitude'].toString()), 
                pointMap['longitude'] is double ? pointMap['longitude'] : double.parse(pointMap['longitude'].toString())
              );
            }).toList();
          } else if (plot.coordinates != null) {
            pontos = plot.coordinates!.map((point) {
              return latlong2.LatLng(
                point['latitude'] ?? 0.0, 
                point['longitude'] ?? 0.0
              );
            }).toList();
          }
        } catch (e) {
          Logger.error('Erro ao converter coordenadas do talhão: $e');
        }

        // Criar modelo de talhão com os campos corretos
        int? cropIdValue;
        if (plot.culturaId != null) {
          try {
            cropIdValue = int.parse(plot.culturaId!);
          } catch (e) {
            Logger.error('Erro ao converter culturaId para int: $e');
          }
        }
        
        final talhao = TalhaoModel(
          id: plot.id ?? const Uuid().v4(),
          name: plot.name,
          poligonos: _converterParaPoligonos(pontos),
          area: plot.area ?? 0.0,
          fazendaId: plot.farmId.toString(),
          dataCriacao: DateTime.tryParse(plot.createdAt) ?? DateTime.now(),
          dataAtualizacao: DateTime.tryParse(plot.updatedAt) ?? DateTime.now(),
          sincronizado: plot.isSynced,
          safras: [],
          culturaId: plot.culturaId, // ID da cultura como string para compatibilidade com Alertas
          cropId: cropIdValue, // ID da cultura como int para compatibilidade com código legado
        );
        
        talhoesCarregados.add(talhao);
      }
    } catch (e) {
      debugPrint('DataCacheService: Erro ao carregar plots: $e');
    }

    // Se não há talhões, criar alguns de exemplo para permitir o uso do sistema
    if (talhoesCarregados.isEmpty) {
      debugPrint('DataCacheService: Nenhum talhão encontrado. Criando talhões de exemplo...');
      await _criarTalhoesExemplo();
      talhoesCarregados = await _carregarTalhoesNovamente();
    }

    _talhoes = talhoesCarregados;
    debugPrint('DataCacheService: Total de talhões carregados: ${_talhoes!.length}');
    return _talhoes!;
  }

  /// Cria talhões de exemplo para permitir o uso do sistema
  Future<void> _criarTalhoesExemplo() async {
    try {
      debugPrint('DataCacheService: Criando talhões de exemplo...');
      
      final talhoesExemplo = [
        TalhaoModel(
          id: 'talhao_001',
          name: 'Talhão A - Soja',
          area: 25.5,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'soja',
          cropId: 1,
          poligonos: [],
        ),
        TalhaoModel(
          id: 'talhao_002',
          name: 'Talhão B - Milho',
          area: 18.3,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'milho',
          cropId: 2,
          poligonos: [],
        ),
        TalhaoModel(
          id: 'talhao_003',
          name: 'Talhão C - Algodão',
          area: 32.1,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'algodao',
          cropId: 3,
          poligonos: [],
        ),
      ];

      // Salvar no repositório SQLite
      for (final talhao in talhoesExemplo) {
        await _talhaoSQLiteRepository.salvar(talhao);
      }
      
      debugPrint('DataCacheService: ${talhoesExemplo.length} talhões de exemplo criados com sucesso');
    } catch (e) {
      debugPrint('DataCacheService: Erro ao criar talhões de exemplo: $e');
    }
  }

  /// Recarrega talhões após criar os de exemplo
  Future<List<TalhaoModel>> _carregarTalhoesNovamente() async {
    try {
      List<TalhaoModel> talhoesCarregados = [];
      
      // Carregar do SQLite novamente
      final talhoesSQL = await _talhaoSQLiteRepository.listarTodos();
      talhoesCarregados.addAll(talhoesSQL.cast<TalhaoModel>());
      
      return talhoesCarregados;
    } catch (e) {
      debugPrint('DataCacheService: Erro ao recarregar talhões: $e');
      return [];
    }
  }

  // Removido: criação de talhões de exemplo. O app deve usar apenas talhões reais do módulo Talhões.

  /// Converte uma lista de pontos para o formato de polígonos usado pelo TalhaoModel
  List<PoligonoModel> _converterParaPoligonos(List<latlong2.LatLng> pontos) {
    // Calcular área aproximada
    double area = _calcularAreaAproximada(pontos);
    double perimetro = _calcularPerimetroAproximado(pontos);
    
    // Criar um único polígono com todos os pontos
    final poligono = PoligonoModel(
      id: const Uuid().v4(),
      pontos: pontos,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      ativo: true,
      area: area,
      perimetro: perimetro,
      talhaoId: 'temp', // Será atualizado depois
    );
    
    // Retornar como uma lista de polígonos (neste caso, apenas um)
    return [poligono];
  }
  
  /// Calcula a área aproximada em hectares usando a fórmula de Gauss
  double _calcularAreaAproximada(List<latlong2.LatLng> pontos) {
    if (pontos.length < 3) return 0;
    
    // Implementação simplificada para área aproximada
    // Em uma implementação real, usaríamos uma biblioteca geoespacial
    return 1.0; // Valor padrão de 1 hectare
  }
  
  /// Calcula o perímetro aproximado em metros
  double _calcularPerimetroAproximado(List<latlong2.LatLng> pontos) {
    if (pontos.isEmpty) return 0;
    
    // Implementação simplificada para perímetro aproximado
    // Em uma implementação real, usaríamos uma biblioteca geoespacial
    return 100.0; // Valor padrão de 100 metros
  }

  /// Busca um talhão pelo ID
  Future<TalhaoModel?> getTalhao(dynamic id) async {
    try {
      // Primeiro tenta buscar do cache
      if (_talhoes != null) {
        try {
          return _talhoes!.firstWhere((talhao) => talhao.id == id);
        } catch (_) {
          // Talhão não encontrado no cache, continua buscando
        }
      }

      // Tenta buscar diretamente do repositório SQLite
      final talhao = await _talhaoSQLiteRepository.buscarPorId(id);
      if (talhao != null) {
        return talhao;
      }

      // Se não encontrou, tenta buscar do repositório V2
      return await _talhaoRepositoryV2.buscarPorId(id);
    } catch (e) {
      debugPrint('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }

  /// Adiciona uma safra a um talhão
  Future<bool> adicionarSafra({
    required int talhaoId,
    required String safra,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
  }) async {
    try {
      // Adicionar safra no repositório SQLite
      final result = await _talhaoSQLiteRepository.adicionarSafra(
        talhaoId: talhaoId,
        safra: safra,
        culturaId: culturaId,
        culturaNome: culturaNome,
        culturaCor: culturaCor,
      );

      if (result) {
        // Limpar cache para forçar recarregamento
        _talhoes = null;
      }

      return result;
    } catch (e) {
      debugPrint('Erro ao adicionar safra: $e');
      return false;
    }
  }

  /// Lista talhões por safra
  Future<List<Object>> listarTalhoesPorSafra(String safraIdOuPeriodo) async {
    try {
      return await _talhaoSQLiteRepository.listarPorSafra(safraIdOuPeriodo);
    } catch (e) {
      debugPrint('Erro ao listar talhões por safra: $e');
      return [];
    }
  }

  /// Salva um talhão
  Future<bool> salvarTalhao(TalhaoModel talhao) async {
    try {
      // Salvar no repositório SQLite
      final result = await _talhaoSQLiteRepository.salvar(talhao);

      if (result) {
        // Limpar cache para forçar recarregamento
        _talhoes = null;
      }

      return result;
    } catch (e) {
      debugPrint('Erro ao salvar talhão: $e');
      return false;
    }
  }

  /// Limpa todos os caches
  void limparCache() {
    _crops = null;
    _plots = null;
    // Removido: _machines = null; - variável não existe mais
    _agriculturalProductsCache.clear();
    _talhoes = null;

    // Limpar cache do repositório SQLite
    _talhaoSQLiteRepository.limparCache();
  }

  /// Limpa apenas o cache de talhões
  void clearPlotCache() {
    _talhoes = null;
  }
  
  /// Método alias para getAllSafras para compatibilidade com código legado
  Future<List<SafraModel>> getSafras() async {
    if (_safras != null) {
      return _safras!;
    }
    
    try {
      // Primeiro tenta buscar do repositório SQLite
      _safras = await _talhaoSQLiteRepository.listarSafras();
      
      // Se não encontrou safras no repositório SQLite, tenta buscar do repositório V2
      if (_safras!.isEmpty) {
        _safras = await _talhaoRepositoryV2.listarSafras();
      }
      
      return _safras!;
    } catch (e) {
      Logger.error('Erro ao carregar safras: $e');
      return [];
    }
  }
  
  /// Retorna todas as safras disponíveis
  Future<List<SafraModel>> getAllSafras() async {
    return await getSafras();
  }
  
  /// Exclui um talhão pelo ID
  Future<bool> excluirTalhao(int id) async {
    try {
      // Excluir do repositório SQLite
      final result = await _talhaoSQLiteRepository.excluir(id);
      
      if (result) {
        // Limpar cache para forçar recarregamento
        _talhoes = null;
      }
      
      return result;
    } catch (e) {
      Logger.error('Erro ao excluir talhão: $e');
      return false;
    }
  }
  
  /// Carrega a lista de culturas como AgriculturalProduct, com filtro opcional por fazenda
  Future<List<AgriculturalProduct>> getCulturas({String? fazendaId}) async {
    final cacheKey = fazendaId ?? 'all';

    try {
      if (_agriculturalProductsCache.containsKey(cacheKey)) {
        // Filtramos produtos do tipo semente (seed) que representam culturas
        return _agriculturalProductsCache[cacheKey]!
            .where((p) => p.type == ProductType.seed)
            .toList();
      }

      // Primeiro tenta carregar do repositório de produtos agrícolas
      List<AgriculturalProduct> products = await _agriculturalProductRepository.getAll(fazendaId: fazendaId);

      // Se não encontrou culturas e está buscando globalmente, tenta o repositório antigo
      if (products.isEmpty && fazendaId == null) {
        final crops = await _cropRepository.getCrops();
        products = crops.map((crop) {
          // Converter de Crop para AgriculturalProduct
          String colorHex = '4CAF50'; // Verde padrão
          try {
            // Tenta converter o valor da cor para hexadecimal
            colorHex = crop.cor.toRadixString(16).padLeft(8, '0').substring(2);
          } catch (e) {
            print('Erro ao converter cor: $e');
          }

          return AgriculturalProduct(
            id: crop.id.toString(),
            name: crop.name,
            type: ProductType.seed, // Usando seed como tipo para culturas
            activeIngredient: crop.description,
            colorValue: '#$colorHex',
            notes: crop.description,
            tags: [],
            parentId: crop.remoteId,
            isSynced: crop.syncStatus == 1,
            fazendaId: null, // Culturas antigas não têm fazendaId
          );
        }).toList();
      }

      _agriculturalProductsCache[cacheKey] = products;

      return products.where((p) => p.type == ProductType.seed).toList();
    } catch (e) {
      Logger.error('Erro ao carregar culturas: $e');
      return [];
    }
  }
  
  /// Carrega a lista de culturas como db_crop.Crop (para compatibilidade com código antigo)
  Future<List<db_crop.Crop>> getCulturasCrop() async {
    try {
      // Primeiro obtém as culturas como AgriculturalProduct
      final culturas = await getCulturas();
      
      // Converte cada AgriculturalProduct para db_crop.Crop
      return culturas.map((cultura) {
        // Converter cor de hexadecimal para inteiro
        int colorValue = Colors.green.value; // Valor padrão
        try {
          if (cultura.colorValue != null && cultura.colorValue!.startsWith('#')) {
            final hexColor = cultura.colorValue!.replaceFirst('#', '');
            colorValue = int.parse('FF$hexColor', radix: 16);
          }
        } catch (e) {
          Logger.error('Erro ao converter cor: $e');
        }
        
        // Converter ID de String para int
        int id = 0;
        try {
          id = int.parse(cultura.id);
        } catch (e) {
          Logger.error('Erro ao converter ID: $e');
          // Gerar um ID único baseado no hash do nome para evitar conflitos
          id = cultura.name.hashCode.abs() % 10000;
        }
        
        // Converter parentId para remoteId (se existir)
        int? remoteId;
        if (cultura.parentId != null) {
          try {
            remoteId = int.parse(cultura.parentId.toString());
          } catch (e) {
            Logger.error('Erro ao converter parentId: $e');
          }
        }
        
        return db_crop.Crop(
          id: id,
          name: cultura.name,
          description: cultura.notes ?? cultura.activeIngredient ?? '',
          syncStatus: cultura.isSynced ? 1 : 0,
          remoteId: remoteId,
        );
      }).toList();
    } catch (e) {
      Logger.error('Erro ao converter culturas para formato Crop: $e');
      return [];
    }
  }
  
  /// Carrega a lista de culturas como app_crop.Crop (para compatibilidade com interfaces de usuário)
  Future<List<app_crop.Crop>> getCulturasAppCrop() async {
    try {
      // Primeiro obtém as culturas como db_crop.Crop
      final dbCrops = await getCulturasCrop();
      
      // Converte cada db_crop.Crop para app_crop.Crop
      return dbCrops.map((dbCrop) {
        // Converter cor para formato int
        int? colorValue;
        try {
          colorValue = dbCrop.cor; // Usa o getter cor do db_crop.Crop
        } catch (e) {
          Logger.error('Erro ao obter cor: $e');
          colorValue = Colors.green.value; // Valor padrão
        }
        
        return app_crop.Crop(
          id: dbCrop.id.toString(), // ID convertido para String
          name: dbCrop.name,
          description: dbCrop.description,
          color: Color(colorValue ?? Colors.green.value), // Cor convertida para objeto Color
          createdAt: DateTime.now(), // Data de criação padrão
          updatedAt: DateTime.now(), // Data de atualização padrão
          isSynced: dbCrop.syncStatus == 1,
        );
      }).toList();
    } catch (e) {
      Logger.error('Erro ao converter culturas para formato app_crop.Crop: $e');
      return [];
    }
  }
  
  /// Carrega a lista de variedades
  Future<List<AgriculturalProduct>> getVariedades({String? culturaId}) async {
    try {
      final produtos = await getCulturas();
      
      if (culturaId != null) {
        return produtos.where((p) => p.parentId == culturaId).toList();
      }
      
      return produtos.where((p) => p.parentId != null).toList();
    } catch (e) {
      Logger.error('Erro ao carregar variedades: $e');
      return [];
    }
  }

  /// Obtém variedades por cultura (alias para compatibilidade)
  Future<List<AgriculturalProduct>> getVariedadesByCultura(String culturaId) async {
    return await getVariedades(culturaId: culturaId);
  }

  /// Obtém uma cultura pelo ID
  Future<AgriculturalProduct?> getCulturaById(String id) async {
    try {
      final culturas = await getCulturas();
      try {
        return culturas.firstWhere((cultura) => cultura.id == id);
      } catch (e) {
        Logger.error('Cultura não encontrada com ID: $id');
        return null;
      }
    } catch (e) {
      Logger.error('Erro ao buscar cultura por ID: $e');
      return null;
    }
  }

  /// Obtém uma variedade pelo ID
  Future<AgriculturalProduct?> getVariedadeById(String id) async {
    try {
      final variedades = await getVariedades();
      try {
        return variedades.firstWhere((variedade) => variedade.id == id);
      } catch (e) {
        Logger.error('Variedade não encontrada com ID: $id');
        return null;
      }
    } catch (e) {
      Logger.error('Erro ao buscar variedade por ID: $e');
      return null;
    }
  }

  /// Carrega a lista de pragas
  Future<List<dynamic>> getPragas() async {
    try {
      // Usar o CultureImportService para obter pragas
      final importService = CultureImportService();
      final pragas = await importService.getAllPests();
      return pragas;
    } catch (e) {
      Logger.error('Erro ao carregar pragas: $e');
      return [];
    }
  }

  /// Carrega a lista de doenças
  Future<List<dynamic>> getDoencas() async {
    try {
      // Usar o CultureImportService para obter doenças
      final importService = CultureImportService();
      final doencas = await importService.getAllDiseases();
      return doencas;
    } catch (e) {
      Logger.error('Erro ao carregar doenças: $e');
      return [];
    }
  }

  /// Carrega a lista de plantas daninhas
  Future<List<dynamic>> getDaninhas() async {
    try {
      // Usar o CultureImportService para obter plantas daninhas
      final importService = CultureImportService();
      final daninhas = await importService.getAllWeeds();
      return daninhas;
    } catch (e) {
      Logger.error('Erro ao carregar plantas daninhas: $e');
      return [];
    }
  }
  
  // REMOVIDO: Métodos relacionados a máquinas - arquivos machine.dart e machine_repository.dart não existem
  // Future<List<Machine>> getMachines() async { ... }
  // Future<List<Machine>> getTratores() async { ... }
  // Future<List<Machine>> getPlantadeiras() async { ... }
  // Future<Machine?> getMachine(int id) async { ... }
  
  /// Limpa o cache de culturas
  void clearCropCache() {
    _crops = null;
    _agriculturalProductsCache.clear();
    debugPrint('Cache de culturas e produtos agrícolas limpo');
  }

  void setCulturas(List<AgriculturalProduct> culturas) {
    // Este método agora define o cache para a chave 'all',
    // que é usado quando nenhum fazendaId é especificado.
    _agriculturalProductsCache['all'] = culturas;
  }
  
  /// Calcula a área total de talhões por cultura
  Future<Map<String, double>> calcularAreaPorCultura() async {
    try {
      return await _talhaoSQLiteRepository.calcularAreaPorCultura();
    } catch (e) {
      Logger.error('Erro ao calcular área por cultura: $e');
      return {};
    }
  }
  
  /// Calcula a área total de talhões
  Future<double> calcularAreaTotal() async {
    try {
      return await _talhaoSQLiteRepository.calcularAreaTotal();
    } catch (e) {
      Logger.error('Erro ao calcular área total: $e');
      return 0.0;
    }
  }

  /// Obtém produtos agrícolas do repositório
  Future<List<AgriculturalProduct>> getAgriculturalProducts() async {
    try {
      // Tentar obter do repositório de produtos agrícolas
      final repository = AgriculturalProductRepository();
      final products = await repository.getAll();
      
      if (products.isNotEmpty) {
        print('DataCacheService: Retornando ${products.length} produtos agrícolas do repositório');
        return products;
      }
      
      // Fallback: tentar converter culturas do repositório antigo
      final cropRepository = CropRepository();
      final crops = await cropRepository.getAll();
      
      // Converter Crop para AgriculturalProduct
      final convertedProducts = crops.map((crop) => _convertCropToAgriculturalProduct(crop)).toList();
      
      print('DataCacheService: Retornando ${convertedProducts.length} produtos agrícolas convertidos de culturas');
      return convertedProducts;
    } catch (e) {
      print('DataCacheService: Erro ao obter produtos agrícolas: $e');
      return [];
    }
  }
  
  /// Converte um objeto Crop para AgriculturalProduct
  AgriculturalProduct _convertCropToAgriculturalProduct(db_crop.Crop crop) {
    return AgriculturalProduct(
      id: crop.id.toString(),
      name: crop.name,
      notes: crop.description,
      type: ProductType.seed, // Considerando como semente por padrão
      colorValue: crop.cor.toString(), // Removido operador ?. desnecessário
      isSynced: crop.isSynced,
      tags: ['cultura', 'convertido'], // Adicionar tags para identificar culturas convertidas
    );
  }

  getTalhoesSync() {}

  getCulturasSync() {}

  getUsersSync() {}
}
