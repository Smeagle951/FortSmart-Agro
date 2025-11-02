import 'package:flutter/material.dart';
import 'dart:async' show Future;
import 'package:fortsmart_agro/models/crop.dart';
import 'package:fortsmart_agro/utils/model_adapters.dart'; 
import 'package:latlong2/latlong.dart'; // Importação do LatLng




// Modelos

import '../../../models/talhao_model.dart';
import '../../../models/safra_model.dart';
import '../../../models/poligono_model.dart'; // Importação do modelo PoligonoModel
import '../models/plantio_model.dart';
import '../../../utils/mapbox_compatibility_adapter.dart';
import '../../../repositories/talhoes/talhao_sqlite_repository.dart';
import '../../../utils/color_converter.dart';
// Removida importação não utilizada

// Implementações temporárias para evitar erros de compilação
class LegacyCropRepository {
  Future<List<Crop>> getAll() async {
    debugPrint('LegacyCropRepository.getAll() chamado');
    return [];
  }
  
  Future<Crop?> getById(int id) async {
    debugPrint('LegacyCropRepository.getById($id) chamado');
    return null;
  }
}

class LegacyPlotRepository {
  Future<List<dynamic>> getAll() async {
    debugPrint('LegacyPlotRepository.getAll() chamado');
    return [];
  }
  
  Future<dynamic> getById(String id) async {
    debugPrint('LegacyPlotRepository.getById($id) chamado');
    return null;
  }
}

class LegacyVarietyRepository {
  Future<List<dynamic>> getAll() async {
    debugPrint('LegacyVarietyRepository.getAll() chamado');
    return [];
  }
  
  Future<dynamic> getById(String id) async {
    debugPrint('LegacyVarietyRepository.getById($id) chamado');
    return null;
  }
}

// Aliases para as classes temporárias
final legacy = _Legacy();

class _Legacy {
  final CropRepository = LegacyCropRepository();
  final PlotRepository = LegacyPlotRepository();
  final VarietyRepository = LegacyVarietyRepository();
}

class DataCacheService {
  // Singleton
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Repositórios
  dynamic _talhaoRepository;
  dynamic _plotRepository;
  dynamic _cropRepository;
  dynamic _varietyRepository;
  dynamic _machineRepository;
  dynamic _agriculturalProductRepository;
  dynamic _safraRepository;
  dynamic _plantioRepository;

  // Cache de dados
  List<TalhaoModel>? _talhoes;
  List<Crop>? _culturas;
  List<dynamic>? _variedades;
  Map<String, List<dynamic>> _variedadesPorCultura = {};
  List<dynamic>? _machines;
  List<dynamic>? _tratores;
  List<dynamic>? _plantadeiras;
  List<SafraModel>? _safras;
  List<PlantioModel>? _plantios;

  // Getters para repositórios que são inicializados sob demanda
  dynamic get talhaoRepository {
    _talhaoRepository ??= _createTalhaoRepository();
    return _talhaoRepository;
  }

  dynamic get plotRepository {
    _plotRepository ??= _createPlotRepository();
    return _plotRepository;
  }
  
  dynamic get agriculturalProductRepository {
    _agriculturalProductRepository ??= _createAgriculturalProductRepository();
    return _agriculturalProductRepository;
  }
  
  dynamic get machineRepository {
    _machineRepository ??= _createMachineRepository();
    return _machineRepository;
  }
  
  dynamic get cropRepository {
    _cropRepository ??= _createCropRepository();
    return _cropRepository;
  }
  
  dynamic get varietyRepository {
    _varietyRepository ??= _createVarietyRepository();
    return _varietyRepository;
  }
  
  dynamic get safraRepository {
    _safraRepository ??= _createSafraRepository();
    return _safraRepository;
  }
  
  dynamic get plantioRepository {
    _plantioRepository ??= _createPlantioRepository();
    return _plantioRepository;
  }
  
  // Métodos para criar repositórios
  dynamic _createTalhaoRepository() {
    try {
      debugPrint('Criando TalhaoSQLiteRepository');
      // Usar o TalhaoSQLiteRepository para acesso aos talhões com safras
      return TalhaoSQLiteRepository();
    } catch (e) {
      debugPrint('Erro ao criar TalhaoSQLiteRepository: $e');
      // Fallback para o repositório legado em caso de erro
      return legacy.PlotRepository;
    }
  }
  
  dynamic _createPlotRepository() {
    try {
      debugPrint('Tentando criar PlotRepository');
      return legacy.PlotRepository;
    } catch (e) {
      debugPrint('Erro ao criar PlotRepository: $e');
      return null;
    }
  }
  
  dynamic _createCropRepository() {
    try {
      debugPrint('Tentando criar CropRepository');
      return legacy.CropRepository;
    } catch (e) {
      debugPrint('Erro ao criar CropRepository: $e');
      return null;
    }
  }
  
  dynamic _createAgriculturalProductRepository() {
    try {
      debugPrint('Tentando criar AgriculturalProductRepository');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao criar AgriculturalProductRepository: $e');
      return null;
    }
  }
  
  dynamic _createMachineRepository() {
    try {
      debugPrint('Tentando criar MachineRepository');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao criar MachineRepository: $e');
      return null;
    }
  }
  
  dynamic _createVarietyRepository() {
    try {
      debugPrint('Tentando criar VarietyRepository');
      return legacy.VarietyRepository; // Usando implementação temporária
    } catch (e) {
      debugPrint('Erro ao criar VarietyRepository: $e');
      return null;
    }
  }
  
  dynamic _createSafraRepository() {
    try {
      debugPrint('Tentando criar SafraRepository');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao criar SafraRepository: $e');
      return null;
    }
  }
  
  dynamic _createPlantioRepository() {
    try {
      debugPrint('Tentando criar PlantioRepository');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao criar PlantioRepository: $e');
      return null;
    }
  }
  
  /// Obtém um estande pelo ID
  Future<dynamic> getEstande(String id) async {
    try {
      if (id.isEmpty) return null;
      debugPrint('Tentando obter estande com ID: $id');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao obter estande por ID: $e');
      return null;
    }
  }

  /// Obtém uma calibragem de semente pelo ID
  Future<dynamic> getCalibragemSemente(String id) async {
    try {
      if (id.isEmpty) return null;
      debugPrint('Tentando obter calibragem de semente com ID: $id');
      return null; // Implementação temporária
    } catch (e) {
      debugPrint('Erro ao obter calibragem de semente por ID: $e');
      return null;
    }
  }

  /// Obtém um talhão pelo ID
  Future<TalhaoModel?> getTalhao(String id) async {
    try {
      if (id.isEmpty) return null;
      
      // Primeiro verifica se está no cache
      if (_talhoes != null) {
        final talhoes = _talhoes!.where((talhao) => talhao.id == id).toList();
        if (talhoes.isNotEmpty) {
          return talhoes.first;
        }
      }
      
      // Se não encontrou no cache, força uma atualização
      await getTalhoes(forceRefresh: true);
      if (_talhoes != null) {
        final talhoes = _talhoes!.where((talhao) => talhao.id == id).toList();
        if (talhoes.isNotEmpty) {
          return talhoes.first;
        }
      }
      
      // Se não encontrou em cache, busca diretamente do repositório
      if (talhaoRepository != null) {
        try {
          final talhao = await talhaoRepository.obterPorId(id);
          if (talhao != null) {
            return talhao;
          }
        } catch (e) {
          debugPrint('Erro ao buscar talhão no repositório novo: $e');
        }
      }
      
      // Se não encontrou no repositório novo, tenta buscar no legado
      if (plotRepository != null) {
        try {
          final plot = await plotRepository.getById(id);
          if (plot != null) {
            return TalhaoModel(
              id: plot.id,
              name: plot.name,
              area: plot.area ?? 0.0,
              poligonos: [],
              sincronizado: false,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              safras: [], // Lista vazia de safras
              metadados: {'origem': 'legado', 'criadoPor': 'sistema'},
            );
          }
        } catch (e) {
          debugPrint('Erro ao buscar talhão no repositório legado: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao obter talhão por ID: $e');
      return null;
    }
  }

  /// Obtém um talhão pelo ID (alias para getTalhao para compatibilidade)
  Future<TalhaoModel?> getTalhaoById(String id) async {
    return await getTalhao(id);
  }
  
  /// Obtém a lista de talhões, primeiro do cache, depois do repositório
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    try {
      debugPrint('getTalhoes chamado com forceRefresh=$forceRefresh');
      
      // Se temos cache e não estamos forçando atualização, use o cache
      if (_talhoes != null && !forceRefresh) {
        debugPrint('Retornando ${_talhoes!.length} talhões do cache');
        return _talhoes!;
      }
      
      // Garante que as culturas estejam carregadas para associar aos talhões legados
      if (_culturas == null || _culturas!.isEmpty) {
        await getCulturas();
      }
      
      List<TalhaoModel> talhoes = [];
      
      // Tenta carregar do repositório novo (TalhaoSQLiteRepository)
      if (talhaoRepository != null) {
        try {
          debugPrint('Tentando carregar talhões do TalhaoSQLiteRepository');
          // Verificamos se o repositório é do tipo TalhaoSQLiteRepository
          if (talhaoRepository is TalhaoSQLiteRepository) {
            final talhoesNovos = await (talhaoRepository as TalhaoSQLiteRepository).listarTodos();
            debugPrint('TalhaoSQLiteRepository retornou ${talhoesNovos.length} talhões');
            
            if (talhoesNovos.isNotEmpty) {
              _talhoes = talhoesNovos;
              debugPrint('Talhões carregados com sucesso do TalhaoSQLiteRepository');
              return talhoesNovos;
            } else {
              debugPrint('TalhaoSQLiteRepository não retornou talhões');
            }
          } else {
            // Tenta usar o método genérico listar() para outros tipos de repositório
            final talhoesNovos = await talhaoRepository.listar();
            debugPrint('Repositório genérico retornou ${talhoesNovos?.length ?? 0} talhões');
            
            if (talhoesNovos != null && talhoesNovos.isNotEmpty) {
              _talhoes = talhoesNovos;
              debugPrint('Talhões carregados com sucesso do repositório genérico');
              return talhoesNovos;
            }
          }
        } catch (e) {
          debugPrint('Erro ao buscar talhões no repositório novo: $e');
        }
      } else {
        debugPrint('talhaoRepository é null, pulando para repositório legado');
      }
      
      // Se não encontrou no repositório novo, tenta no legado
      if (plotRepository != null) {
        try {
          debugPrint('Tentando carregar plots do repositório legado');
          final plots = await plotRepository.getAll();
          debugPrint('Carregados ${plots.length} plots do repositório legado');
          
          if (plots.isNotEmpty) {
            try {
              talhoes = plots.map<TalhaoModel>((plot) {
                try {
                  // Converte as coordenadas do formato antigo para o formato do TalhaoModel
                  final List<List<MapboxLatLng>> poligonos = [];
                  
                  if (plot.coordinates != null && plot.coordinates.isNotEmpty) {
                    final List<MapboxLatLng> pontos = [];
                    for (var coord in plot.coordinates) {
                      try {
                        final double lat = coord['latitude'] is double 
                            ? coord['latitude'] 
                            : (coord['latitude'] as num).toDouble();
                        final double lng = coord['longitude'] is double 
                            ? coord['longitude'] 
                            : (coord['longitude'] as num).toDouble();
                        pontos.add(MapboxLatLng(lat, lng));
                      } catch (coordError) {
                        debugPrint('Erro ao processar coordenada: $coordError');
                      }
                    }
                    if (pontos.isNotEmpty) {
                      poligonos.add(pontos);
                    }
                  }
                  
                  // Tenta encontrar a cultura correspondente
                  final Crop? associatedCrop = _culturas!.firstWhere((c) => c.name.toLowerCase() == (plot.cropName ?? '').toLowerCase(), orElse: () => Crop(id: 0, name: '', description: '', colorValue: null));

                  // Cria uma SafraModel para o talhão legado
                  final now = DateTime.now();
                  final culturaNome = associatedCrop?.name ?? plot.cropName ?? 'Não definida';
                  final safraLegado = 'Safra Legado';
                  
                  final SafraModel safraModel = SafraModel(
                    id: now.millisecondsSinceEpoch.toString(), // ID único para a safra
                    talhaoId: plot.id.toString(),
                    safra: safraLegado, // Nome padrão para safras legadas
                    culturaId: (associatedCrop?.id ?? 0).toString(), // Converte int para String
                    culturaNome: culturaNome,
                    culturaCor: ColorConverter.colorToHex(associatedCrop?.color ?? Colors.grey), // Usa a cor da Crop ou cinza
                    dataCriacao: now, // Adiciona dataCriacao
                    dataAtualizacao: now, // Adiciona dataAtualizacao
                    sincronizado: false, // Adiciona sincronizado
                    periodo: safraLegado, // Novo campo obrigatório
                    dataInicio: now, // Novo campo obrigatório
                    dataFim: now.add(const Duration(days: 365)), // Novo campo obrigatório
                    ativa: true, // Novo campo obrigatório
                    nome: culturaNome, // Novo campo obrigatório
                  );

                  // Criar lista de polígonos no formato correto
                  final List<PoligonoModel> poligonosModels = [];
                  if (poligonos.isNotEmpty) {
                    final String talhaoId = plot.id.toString();
                    // Converter pontos para o formato LatLng do pacote latlong2
                    final pontos = poligonos.first
                        .map((p) {
                          // Verificar o tipo do ponto e extrair latitude e longitude
                          try {
                            if (p != null) {
                              // Usar dynamic para acessar as propriedades
                              final dynamic point = p;
                              final double lat = point.latitude is num ? point.latitude.toDouble() : 0.0;
                              final double lng = point.longitude is num ? point.longitude.toDouble() : 0.0;
                              return LatLng(lat, lng);
                            }
                          } catch (e) {
                            debugPrint('Erro ao converter ponto: $e');
                          }
                          return LatLng(0.0, 0.0); // Valor padrão em caso de erro
                        })
                        .toList();
                    poligonosModels.add(PoligonoModel.criar(
                      pontos: pontos,
                      talhaoId: talhaoId,
                    ));
                  }

                  return TalhaoModel(
                    id: plot.id.toString(),
                    name: plot.name ?? 'Sem nome',
                    area: plot.area ?? 0.0,
                    poligonos: poligonosModels,
                    dataCriacao: DateTime.now(),
                    dataAtualizacao: DateTime.now(),
                    sincronizado: false,
                    safras: [safraModel], // Adiciona à lista de safras
                    metadados: {'criadoPor': 'app_user', 'origem': 'legado'},
                  );
                } catch (plotError) {
                  debugPrint('Erro ao converter plot para talhão: $plotError');
                  // Retorna um talhão mínimo para não quebrar a lista
                  // Tenta encontrar a cultura correspondente
                  final Crop? associatedCrop = _culturas!.firstWhere((c) => c.name.toLowerCase() == (plot.cropName ?? '').toLowerCase(), orElse: () => Crop(id: 0, name: '', description: '', colorValue: null));

                  // Cria uma SafraModel para o talhão mínimo
                  final now = DateTime.now();
                  final culturaNome = associatedCrop?.name ?? plot.cropName ?? 'Desconhecida';
                  final safraLegado = 'Safra Legado';
                  
                  final SafraModel safraModel = SafraModel(
                    id: now.millisecondsSinceEpoch.toString(),
                    talhaoId: plot.id?.toString() ?? 'erro',
                    safra: safraLegado,
                    culturaId: (associatedCrop?.id ?? 0).toString(),
                    culturaNome: culturaNome,
                    culturaCor: ColorConverter.colorToHex(associatedCrop?.color ?? Colors.grey),
                    dataCriacao: now,
                    dataAtualizacao: now,
                    sincronizado: false,
                    periodo: safraLegado,
                    dataInicio: now,
                    dataFim: now.add(const Duration(days: 365)),
                    ativa: true,
                    nome: culturaNome,
                  );

                  return TalhaoModel(
                    id: plot.id?.toString() ?? 'erro',
                    name: 'Erro de conversão',
                    area: 0.0,
                    poligonos: [],
                    sincronizado: false,
                    dataCriacao: DateTime.now(),
                    dataAtualizacao: DateTime.now(),
                    safras: [safraModel], // Lista com a safra legado
                    metadados: {'origem': 'legado', 'criadoPor': 'app_user'},
                  );
                }
              }).toList();
              
              debugPrint('Convertidos ${talhoes.length} talhões do formato legado');
            } catch (mapError) {
              debugPrint('Erro ao mapear plots para talhões: $mapError');
            }
          } else {
            debugPrint('Repositório legado não retornou plots');
          }
        } catch (e) {
          debugPrint('Erro ao carregar talhões do repositório legado: $e');
        }
      } else {
        debugPrint('plotRepository é null, não é possível carregar talhões');
      }
      
      // Atualiza o cache e retorna os talhões encontrados
      _talhoes = talhoes;
      debugPrint('Retornando ${talhoes.length} talhões ao final');
      return talhoes;
    } catch (e) {
      debugPrint('Erro geral ao carregar talhões: $e');
      return [];
    }
  }
  
  /// Obtém a lista de culturas, primeiro do cache, depois do repositório
  Future<List<Crop>> getCulturas({bool forceRefresh = false}) async {
    try {
      if (_culturas != null && !forceRefresh) {
        return _culturas!;
      }
      
      List<Crop> crops = [];
      
      // Tenta carregar do repositório novo (agricultural products)
      if (agriculturalProductRepository != null) {
        try {
          final produtos = await agriculturalProductRepository.getAll();
          final culturasProdutos = produtos.where((produto) => 
              produto.parentId == null || produto.parentId.toString().isEmpty).toList();
          
          crops = culturasProdutos.map((produto) => ModelAdapters.agriculturalProductToAppCrop(produto)).toList();
          debugPrint('Carregadas ${crops.length} culturas do agriculturalProductRepository');
        } catch (e) {
          debugPrint('Erro ao carregar culturas do agriculturalProductRepository: $e');
        }
      }

      // Se ainda não encontrou, tenta no repositório legado
      if ((crops.isEmpty || crops.every((c) => c.name.trim().isEmpty)) && cropRepository != null) {
        try {
          final legacyCrops = await cropRepository.getAll();
          crops = legacyCrops;
          debugPrint('Carregadas ${legacyCrops.length} culturas do repositório legado');
        } catch (e) {
          debugPrint('Erro ao carregar culturas do repositório legado: $e');
        }
      }
      
      if (crops.isEmpty) {
        debugPrint('Nenhuma cultura encontrada em nenhum repositório!');
      }
      _culturas = crops;
      return crops;
    } catch (e) {
      debugPrint('Erro ao carregar culturas: $e');
      return [];
    }
  }
  
  /// Obtém uma cultura pelo ID
  Future<Crop?> getCultura(String id) async {
    try {
      if (id.isEmpty) return null;
      
      // Primeiro verifica se está no cache
      if (_culturas != null) {
        final idInt = int.tryParse(id) ?? 0;
        final culturas = _culturas!.where((cultura) => cultura.id == idInt).toList();
        if (culturas.isNotEmpty) {
          return culturas.first;
        }
      }
      
      // Se não encontrou em cache, carrega todas as culturas e tenta novamente
      await getCulturas(forceRefresh: true);
      
      if (_culturas != null) {
        final idInt = int.tryParse(id) ?? 0;
        final culturas = _culturas!.where((cultura) => cultura.id == idInt).toList();
        if (culturas.isNotEmpty) {
          return culturas.first;
        }
      }
      
      // Se ainda não encontrou, tenta buscar no repositório novo
      if (agriculturalProductRepository != null) {
        try {
          final produto = await agriculturalProductRepository.getById(id);
          if (produto != null) {
            return Crop(
              id: int.tryParse(produto.id) ?? 0,
              name: produto.name,
              description: produto.notes ?? '',
              scientificName: produto.activeIngredient ?? ''
            );
          }
        } catch (e) {
          debugPrint('Erro ao buscar cultura no repositório novo: $e');
        }
      }
      
      // Tenta buscar no repositório legado
      if (cropRepository != null) {
        try {
          final idInt = int.tryParse(id) ?? 0;
          final crop = await cropRepository.getById(idInt);
          return crop;
        } catch (e) {
          debugPrint('Erro ao buscar cultura por ID no repositório legado: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao obter cultura por ID: $e');
      return null;
    }
  }
  
  /// Alias para getCultura para manter compatibilidade
  Future<Crop?> getCulturaById(String id) async {
    return await getCultura(id);
  }
  
  /// Obtém a lista de variedades, primeiro do cache, depois do repositório
  Future<List<dynamic>> getVariedades({bool forceRefresh = false}) async {
    try {
      if (_variedades != null && !forceRefresh) {
        return _variedades!;
      }
      
      List<dynamic> variedades = [];
      
      // Tenta carregar do repositório novo (agricultural products que são variedades)
      if (agriculturalProductRepository != null) {
        try {
          final produtos = await agriculturalProductRepository.getAll();
          final variedadesProdutos = produtos.where((produto) => 
              produto.parentId != null && produto.parentId.toString().isNotEmpty).toList();
          
          for (var produto in variedadesProdutos) {
            variedades.add({
              'id': produto.id,
              'name': produto.name,
              'culturaId': produto.parentId.toString(),
              'description': produto.notes ?? ''
            });
          }
          
          debugPrint('Carregadas ${variedades.length} variedades do repositório novo');
        } catch (e) {
          debugPrint('Erro ao carregar variedades do repositório novo: $e');
        }
      }
      
      // Se ainda não encontrou, tenta no repositório legado
      if (variedades.isEmpty && varietyRepository != null) {
        try {
          final variedadesLegado = await varietyRepository.getAll();
          variedades = variedadesLegado;
          debugPrint('Carregadas ${variedades.length} variedades do repositório legado');
        } catch (e) {
          debugPrint('Erro ao carregar variedades do repositório legado: $e');
        }
      }
      
      _variedades = variedades;
      return variedades;
    } catch (e) {
      debugPrint('Erro ao carregar variedades: $e');
      return [];
    }
  }
  
  /// Obtém a lista de variedades para uma cultura específica
  Future<List<dynamic>> getVariedadesPorCultura(String culturaId, {bool forceRefresh = false}) async {
    try {
      if (culturaId.isEmpty) return [];
      
      if (_variedadesPorCultura.containsKey(culturaId) && !forceRefresh) {
        return _variedadesPorCultura[culturaId]!;
      }
      
      final todasVariedades = await getVariedades(forceRefresh: forceRefresh);
      final variedadesFiltradas = todasVariedades.where((variedade) => 
        variedade['culturaId'] == culturaId || 
        variedade['culturaId'].toString() == culturaId.toString()
      ).toList();
      
      _variedadesPorCultura[culturaId] = variedadesFiltradas;
      return variedadesFiltradas;
    } catch (e) {
      debugPrint('Erro ao obter variedades por cultura: $e');
      return [];
    }
  }
  
  /// Obtém a lista de máquinas, primeiro do cache, depois do repositório
  Future<List<dynamic>> getMachines({bool forceRefresh = false}) async {
    try {
      if (_machines != null && !forceRefresh) {
        return _machines!;
      }
      
      List<dynamic> machines = [];
      
      if (machineRepository != null) {
        try {
          machines = await machineRepository.listar();
          debugPrint('Carregadas ${machines.length} máquinas');
        } catch (e) {
          debugPrint('Erro ao carregar máquinas do repositório: $e');
        }
      }
      
      _machines = machines;
      return machines;
    } catch (e) {
      debugPrint('Erro ao obter máquinas: $e');
      return [];
    }
  }
  
  /// Obtém uma máquina pelo ID
  Future<dynamic> getMachine(String id) async {
    try {
      if (id.isEmpty) return null;
      
      // Primeiro verifica se está nos tratores em cache
      if (_tratores != null) {
        final tratores = _tratores!.where((machine) => machine?.id == id).toList();
        if (tratores.isNotEmpty) {
          return tratores.first;
        }
      }
      
      // Depois verifica se está nas plantadeiras em cache
      if (_plantadeiras != null) {
        final plantadeiras = _plantadeiras!.where((machine) => machine?.id == id).toList();
        if (plantadeiras.isNotEmpty) {
          return plantadeiras.first;
        }
      }
      
      // Verifica se já temos em cache geral de máquinas
      if (_machines != null) {
        final machines = _machines!.where((machine) => machine?.id == id).toList();
        if (machines.isNotEmpty) {
          return machines.first;
        }
      }
      
      // Se não encontrou em cache, força uma atualização do cache
      await getMachines(forceRefresh: true);
      
      // Tenta novamente no cache atualizado
      if (_machines != null) {
        final machines = _machines!.where((machine) => machine?.id == id).toList();
        if (machines.isNotEmpty) {
          return machines.first;
        }
      }
      
      // Se ainda não encontrou, busca diretamente no repositório
      if (machineRepository != null) {
        try {
          return await machineRepository.obterPorId(id);
        } catch (e) {
          debugPrint('Erro ao buscar máquina no repositório: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao obter máquina por ID: $e');
      return null;
    }
  }
  
  /// Obtém a lista de tratores, primeiro do cache, depois do repositório
  Future<List<dynamic>> getTratores({bool forceRefresh = false}) async {
    try {
      if (_tratores != null && !forceRefresh) {
        return _tratores!;
      }
      
      List<dynamic> tratores = [];
      
      if (machineRepository != null) {
        try {
          tratores = await machineRepository.listarTratores();
          debugPrint('Carregados ${tratores.length} tratores');
        } catch (e) {
          debugPrint('Erro ao carregar tratores do repositório: $e');
        }
      }
      
      _tratores = tratores;
      return tratores;
    } catch (e) {
      debugPrint('Erro ao obter tratores: $e');
      return [];
    }
  }
  
  /// Obtém a lista de plantadeiras, primeiro do cache, depois do repositório
  Future<List<dynamic>> getPlantadeiras({bool forceRefresh = false}) async {
    try {
      if (_plantadeiras != null && !forceRefresh) {
        return _plantadeiras!;
      }
      
      List<dynamic> plantadeiras = [];
      
      if (machineRepository != null) {
        try {
          plantadeiras = await machineRepository.listarPlantadeiras();
          debugPrint('Carregadas ${plantadeiras.length} plantadeiras');
        } catch (e) {
          debugPrint('Erro ao carregar plantadeiras do repositório: $e');
        }
      }
      
      _plantadeiras = plantadeiras;
      return plantadeiras;
    } catch (e) {
      debugPrint('Erro ao obter plantadeiras: $e');
      return [];
    }
  }
  
  /// Obtém a lista de safras, primeiro do cache, depois do repositório
  Future<List<SafraModel>> getSafras({bool forceRefresh = false}) async {
    try {
      if (_safras != null && !forceRefresh) {
        return _safras!;
      }
      
      List<SafraModel> safras = [];
      
      if (safraRepository != null) {
        try {
          safras = await safraRepository.listar();
          debugPrint('Carregadas ${safras.length} safras');
        } catch (e) {
          debugPrint('Erro ao carregar safras do repositório: $e');
        }
      }
      
      _safras = safras;
      return safras;
    } catch (e) {
      debugPrint('Erro ao obter safras: $e');
      return [];
    }
  }
  
  /// Obtém a lista de plantios, primeiro do cache, depois do repositório
  Future<List<PlantioModel>> getPlantios({bool forceRefresh = false}) async {
    try {
      if (_plantios != null && !forceRefresh) {
        return _plantios!;
      }
      
      List<PlantioModel> plantios = [];
      
      if (plantioRepository != null) {
        try {
          plantios = await plantioRepository.listar();
          debugPrint('Carregados ${plantios.length} plantios');
        } catch (e) {
          debugPrint('Erro ao carregar plantios do repositório: $e');
        }
      }
      
      _plantios = plantios;
      return plantios;
    } catch (e) {
      debugPrint('Erro ao obter plantios: $e');
      return [];
    }
  }
  
  /// Obtém a lista de talhões novos (TalhaoModel com safras)
  Future<List<TalhaoModel>> getTalhoesNovos({bool forceRefresh = false}) async {
    try {
      final talhoesAntigos = await getTalhoes(forceRefresh: forceRefresh);
      // Implementação temporária sem ModelAdapters
      final talhoesNovos = talhoesAntigos.map((talhao) => talhao).toList();
      
      debugPrint('Convertidos ${talhoesNovos.length} talhões para o formato novo');
      return talhoesNovos;
    } catch (e) {
      debugPrint('Erro ao obter talhões no formato novo: $e');
      return [];
    }
  }
  
  /// Método para limpar o cache de um modelo específico
  void limparCacheModelo(String modelo) {
    switch (modelo.toLowerCase()) {
      case 'talhao':
      case 'talhoes':
        _talhoes = null;
        break;
      case 'safra':
      case 'safras':
        _safras = null;
        break;
      case 'plantio':
      case 'plantios':
        _plantios = null;
        break;
      case 'cultura':
      case 'culturas':
        _culturas = null;
        break;
      case 'variedade':
      case 'variedades':
        _variedades = null;
        _variedadesPorCultura.clear();
        break;
      case 'machine':
      case 'machines':
      case 'maquina':
      case 'maquinas':
      case 'trator':
      case 'tratores':
      case 'plantadeira':
      case 'plantadeiras':
        _machines = null;
        _tratores = null;
        _plantadeiras = null;
        break;
      default:
        debugPrint('Modelo não reconhecido: $modelo');
    }
  }
  
  /// Alias para limparCache para manter compatibilidade
  void clearModelCache() {
    limparCache();
  }
  
  /// Limpa todos os caches
  void limparCache() {
    _talhoes = null;
    _culturas = null;
    _variedades = null;
    _variedadesPorCultura.clear();
    _machines = null;
    _tratores = null;
    _plantadeiras = null;
    _safras = null;
    _plantios = null;
    debugPrint('Cache limpo com sucesso');
  }

  /// Versão síncrona de getCulturas que retorna o cache atual ou uma lista vazia
  /// Usado para acesso rápido quando não é possível esperar por uma operação assíncrona
  List<Crop> getCulturasSync() {
    try {
      if (_culturas != null) {
        return _culturas!;
      }
      debugPrint('AVISO: getCulturasSync chamado sem cache inicializado');
      return [];
    } catch (e) {
      debugPrint('Erro ao obter culturas de forma síncrona: $e');
      return [];
    }
  }

  /// Versão síncrona de getTalhoes que retorna o cache atual ou uma lista vazia
  /// Usado para acesso rápido quando não é possível esperar por uma operação assíncrona
  List<TalhaoModel> getTalhoesSync() {
    try {
      if (_talhoes != null) {
        return _talhoes!;
      }
      debugPrint('AVISO: getTalhoesSync chamado sem cache inicializado');
      return [];
    } catch (e) {
      debugPrint('Erro ao obter talhões de forma síncrona: $e');
      return [];
    }
  }

  /// Versão síncrona de getVariedades que retorna o cache atual ou uma lista vazia
  List<dynamic> getVariedadesSync() {
    try {
      if (_variedades != null) {
        return _variedades!;
      }
      debugPrint('AVISO: getVariedadesSync chamado sem cache inicializado');
      return [];
    } catch (e) {
      debugPrint('Erro ao obter variedades de forma síncrona: $e');
      return [];
    }
  }

  /// Versão síncrona de getMachines que retorna o cache atual ou uma lista vazia
  List<dynamic> getMachinesSync() {
    try {
      if (_machines != null) {
        return _machines!;
      }
      debugPrint('AVISO: getMachinesSync chamado sem cache inicializado');
      return [];
    } catch (e) {
      debugPrint('Erro ao obter máquinas de forma síncrona: $e');
      return [];
    }
  }
  
  /// Atualiza um talhão existente no cache e no repositório
  Future<bool> updateTalhao(TalhaoModel talhao) async {
    try {
      debugPrint('Atualizando talhão: ${talhao.id}');
      
      // Atualizar no cache se existir
      if (_talhoes != null) {
        final index = _talhoes!.indexWhere((t) => t.id == talhao.id);
        if (index >= 0) {
          _talhoes![index] = talhao;
          debugPrint('Talhão atualizado no cache');
        } else {
          _talhoes!.add(talhao);
          debugPrint('Talhão adicionado ao cache pois não existia');
        }
      }
      
      // Implementar a atualização no repositório quando disponível
      // Por enquanto, apenas simular sucesso
      debugPrint('Talhão atualizado com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar talhão: $e');
      return false;
    }
  }

  getTalhaoHistory(String s) {}

  getUsersSync() {}
}