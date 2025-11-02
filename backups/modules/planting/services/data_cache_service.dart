import 'dart:async';
import '../../../models/talhao_model_new.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/machine.dart';
import '../../../repositories/talhao_repository_new.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../repositories/machine_repository.dart';
import '../../../repositories/plot_repository.dart';
import '../../../repositories/crop_repository.dart';
import '../../../utils/mapbox_compatibility_adapter.dart' as mapbox;

/// Serviço para cache de dados frequentemente acessados no módulo de plantio
class DataCacheService {
  // Singleton
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Repositórios
  final _talhaoRepository = TalhaoRepository();
  final _agriculturalProductRepository = AgriculturalProductRepository();
  final _machineRepository = MachineRepository();

  // Cache de dados
  List<TalhaoModel>? _cachedTalhoes;
  List<AgriculturalProduct>? _cachedCulturas;
  List<AgriculturalProduct>? _cachedVariedades;
  List<Machine>? _cachedTratores;
  List<Machine>? _cachedPlantadeiras;

  // Timestamps para controle de validade do cache
  DateTime? _talhoesCacheTime;
  DateTime? _culturasCacheTime;
  DateTime? _variedadesCacheTime;
  DateTime? _tratoresCacheTime;
  DateTime? _plantadeirasCacheTime;

  // Duração da validade do cache (em minutos)
  final int _cacheDuration = 5; // 5 minutos

  // Métodos para verificar se o cache está válido
  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _cacheDuration;
  }

  // Métodos para obter dados com cache
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      return _cachedTalhoes!;
    }

    try {
      // Primeiro tenta buscar do repositório de talhões com safra
      List<TalhaoModel> talhoes = [];
      try {
        talhoes = await _talhaoRepository.listarTodos();
        print('Carregados ${talhoes.length} talhões do repositório de talhões com safra');
      } catch (repoError) {
        print('Erro ao carregar talhões do repositório: $repoError');
      }

      // Se não encontrou nenhum talhão, tenta buscar do repositório antigo
      if (talhoes.isEmpty) {
        try {
          // Usar o repositório antigo diretamente
          final plotRepository = PlotRepository();
          final plots = await plotRepository.getAllPlots();
          
          // Converter os plots para o formato TalhaoModel
          talhoes = plots.map((plot) => TalhaoModel(
            id: plot.id.toString(),
            nome: plot.name,
            area: plot.area ?? 0.0, // Usar 0.0 como valor padrão se area for nulo
            poligonos: [plot.coordinates?.map((coord) => 
              mapbox.MapboxLatLng(coord['latitude'] as double, coord['longitude'] as double)
            ).toList() ?? []],
            criadoEm: DateTime.tryParse(plot.createdAt) ?? DateTime.now(),
            atualizadoEm: DateTime.tryParse(plot.updatedAt) ?? DateTime.now(),
            observacoes: plot.notes ?? '',
            sincronizado: plot.isSynced == 1,
            safras: [],
            criadoPor: 'sistema',
          )).toList();
          print('Carregados ${talhoes.length} talhões do repositório antigo');
        } catch (oldRepoError) {
          print('Erro ao carregar talhões do repositório antigo: $oldRepoError');
        }
      }

      _cachedTalhoes = talhoes;
      _talhoesCacheTime = DateTime.now();
      return talhoes;
    } catch (e) {
      // Em caso de erro, retorna o cache se disponível, mesmo que expirado
      if (_cachedTalhoes != null) {
        return _cachedTalhoes!;
      }
      print('Erro ao carregar talhões: $e');
      return [];
    }
  }

  Future<List<AgriculturalProduct>> getCulturas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
      return _cachedCulturas!;
    }

    try {
      // Obter culturas (sementes) do módulo de Culturas e Pragas
      List<AgriculturalProduct> culturas = [];
      try {
        // Tentar carregar todas as culturas primeiro
        culturas = await _agriculturalProductRepository.getAll();
        
        // Filtrar apenas as do tipo semente
        culturas = culturas.where((c) => c.type == ProductType.seed).toList();
        
        // Se não encontrou nenhuma cultura do tipo semente, tenta buscar pelo índice
        if (culturas.isEmpty) {
          culturas = await _agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
        }
        
        print('Carregadas ${culturas.length} culturas do módulo Culturas e Pragas');
        
        // Adicionar cores e ícones padrão para culturas que não têm
        for (var i = 0; i < culturas.length; i++) {
          if (culturas[i].colorValue == null || culturas[i].colorValue!.isEmpty) {
            // Cores padrão para culturas comuns
            switch (culturas[i].name.toLowerCase()) {
              case 'soja':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFF3CB371'); // Verde médio mar
                break;
              case 'milho':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFFFFD700'); // Amarelo ouro
                break;
              case 'algodão':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFFF0F8FF'); // Branco azulado
                break;
              case 'trigo':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFFDAA520'); // Dourado
                break;
              case 'café':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFF8B4513'); // Marrom sela
                break;
              case 'cana':
              case 'cana-de-açúcar':
                culturas[i] = culturas[i].copyWith(colorValue: '0xFF32CD32'); // Verde lima
                break;
              default:
                // Gerar uma cor baseada no nome da cultura para consistência
                final int hashCode = culturas[i].name.hashCode;
                final String colorHex = '0xFF${(hashCode & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
                culturas[i] = culturas[i].copyWith(colorValue: colorHex);
            }
          }
          
          // Adicionar ícones padrão para culturas que não têm
          if (culturas[i].iconPath == null || culturas[i].iconPath!.isEmpty) {
            // Ícones padrão para culturas comuns
            switch (culturas[i].name.toLowerCase()) {
              case 'soja':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/soybean.png');
                break;
              case 'milho':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/corn.png');
                break;
              case 'algodão':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/cotton.png');
                break;
              case 'trigo':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/wheat.png');
                break;
              case 'café':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/coffee.png');
                break;
              case 'cana':
              case 'cana-de-açúcar':
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/sugarcane.png');
                break;
              default:
                culturas[i] = culturas[i].copyWith(iconPath: 'assets/icons/crops/default_crop.png');
            }
          }
        }
      } catch (repoError) {
        print('Erro ao carregar culturas do repositório: $repoError');
      }

      // Se não encontrou nenhuma cultura, tenta buscar do repositório antigo
      if (culturas.isEmpty) {
        try {
          // Usar o repositório antigo diretamente
          final cropRepository = CropRepository();
          final crops = await cropRepository.getAll();
          
          // Converter os crops para o formato AgriculturalProduct
          culturas = crops.map((crop) => AgriculturalProduct(
            id: crop.id.toString(),
            name: crop.name,
            type: ProductType.seed,
            notes: crop.description,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: false,
            // Adicionar cor baseada no ciclo de crescimento
            colorValue: crop.growthCycle != null && crop.growthCycle! > 0 
              ? '0xFF${((crop.growthCycle! * 1000) & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
              : '0xFF4CAF50', // Verde padrão
            // Adicionar ícone padrão
            iconPath: 'assets/icons/crops/default_crop.png',
          )).toList();
          print('Carregadas ${culturas.length} culturas do repositório antigo');
        } catch (oldRepoError) {
          print('Erro ao carregar culturas do repositório antigo: $oldRepoError');
        }
      }

      _cachedCulturas = culturas;
      _culturasCacheTime = DateTime.now();
      return culturas;
    } catch (e) {
      if (_cachedCulturas != null) {
        return _cachedCulturas!;
      }
      print('Erro ao carregar culturas: $e');
      return [];
    }
  }
  
  /// Atualiza o cache de culturas com a lista fornecida
  Future<void> setCulturas(List<AgriculturalProduct> culturas) async {
    _cachedCulturas = culturas;
    _culturasCacheTime = DateTime.now();
  }
  


  Future<List<AgriculturalProduct>> getVariedades({String? culturaId, bool forceRefresh = false}) async {
    // Para variedades, sempre atualizamos se o ID da cultura mudar
    if (!forceRefresh && _cachedVariedades != null && _isCacheValid(_variedadesCacheTime) && culturaId == null) {
      return _cachedVariedades!;
    }

    try {
      // Buscar todas as sementes
      final variedades = await _agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
      
      // Se tiver um ID de cultura, filtramos as variedades relacionadas
      List<AgriculturalProduct> filteredVariedades = variedades;
      if (culturaId != null) {
        // Filtramos as variedades que têm o parentId igual ao culturaId
        filteredVariedades = variedades.where((variedade) => 
          variedade.parentId == culturaId || 
          (variedade.tags != null && variedade.tags!.contains('cultura_$culturaId'))
        ).toList();
      }
      
      _cachedVariedades = filteredVariedades;
      _variedadesCacheTime = DateTime.now();
      return filteredVariedades;
    } catch (e) {
      if (_cachedVariedades != null) {
        return _cachedVariedades!;
      }
      rethrow;
    }
  }

  Future<List<Machine>> getTratores({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTratores != null && _isCacheValid(_tratoresCacheTime)) {
      return _cachedTratores!;
    }

    try {
      final tratores = await _machineRepository.getTractors();
      _cachedTratores = tratores;
      _tratoresCacheTime = DateTime.now();
      return tratores;
    } catch (e) {
      if (_cachedTratores != null) {
        return _cachedTratores!;
      }
      rethrow;
    }
  }

  Future<List<Machine>> getPlantadeiras({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPlantadeiras != null && _isCacheValid(_plantadeirasCacheTime)) {
      return _cachedPlantadeiras!;
    }

    try {
      final plantadeiras = await _machineRepository.getPlanters();
      _cachedPlantadeiras = plantadeiras;
      _plantadeirasCacheTime = DateTime.now();
      return plantadeiras;
    } catch (e) {
      if (_cachedPlantadeiras != null) {
        return _cachedPlantadeiras!;
      }
      rethrow;
    }
  }

  // Métodos para buscar itens individuais por ID
  Future<TalhaoModel?> getTalhaoById(String id, {bool forceRefresh = false}) async {
    final talhoes = await getTalhoes(forceRefresh: forceRefresh);
    try {
      return talhoes.firstWhere((talhao) => talhao.id == id);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
  
  Future<AgriculturalProduct?> getCulturaById(String id, {bool forceRefresh = false}) async {
    final culturas = await getCulturas(forceRefresh: forceRefresh);
    try {
      return culturas.firstWhere((cultura) => cultura.id == id);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
  
  Future<AgriculturalProduct?> getVariedadeById(String id, {bool forceRefresh = false}) async {
    // Buscar todas as variedades sem filtro de cultura
    final variedades = await _agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
    try {
      return variedades.firstWhere((variedade) => variedade.id == id);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
  
  Future<Machine?> getTratorById(String id, {bool forceRefresh = false}) async {
    final tratores = await getTratores(forceRefresh: forceRefresh);
    try {
      return tratores.firstWhere((trator) => trator.id == id);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
  
  Future<Machine?> getPlantadeiraById(String id, {bool forceRefresh = false}) async {
    final plantadeiras = await getPlantadeiras(forceRefresh: forceRefresh);
    try {
      return plantadeiras.firstWhere((plantadeira) => plantadeira.id == id);
    } catch (e) {
      return null; // Retorna null se não encontrar
    }
  }
  
  // Método para limpar todo o cache
  void clearCache() {
    _cachedTalhoes = null;
    _cachedCulturas = null;
    _cachedVariedades = null;
    _cachedTratores = null;
    _cachedPlantadeiras = null;
    
    _talhoesCacheTime = null;
    _culturasCacheTime = null;
    _variedadesCacheTime = null;
    _tratoresCacheTime = null;
    _plantadeirasCacheTime = null;
    
    print('Cache de dados limpo com sucesso. Próxima consulta buscará dados atualizados.');
  }

  // Métodos para limpar caches específicos
  void clearTalhoesCache() {
    _cachedTalhoes = null;
    _talhoesCacheTime = null;
  }

  void clearCulturasCache() {
    _cachedCulturas = null;
    _culturasCacheTime = null;
  }

  void clearVariedadesCache() {
    _cachedVariedades = null;
    _variedadesCacheTime = null;
  }

  void clearTratoresCache() {
    _cachedTratores = null;
    _tratoresCacheTime = null;
  }

  void clearPlantadeirasCache() {
    _cachedPlantadeiras = null;
    _plantadeirasCacheTime = null;
  }
}
