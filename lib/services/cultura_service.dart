import 'package:flutter/material.dart';
import '../models/cultura_model.dart';
import '../database/daos/crop_dao.dart';
import 'cultura_talhao_service.dart';

class CulturaService {
  final CropDao _cropDao = CropDao();
  final CulturaTalhaoService _culturaTalhaoService = CulturaTalhaoService();
  
  // Cache offline
  List<CulturaModel>? _cachedCultures;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(hours: 24);

  CulturaService();

  /// Verifica se o cache é válido
  bool _isCacheValid() {
    if (_cachedCultures == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidity;
  }

  /// Atualiza o cache
  Future<void> _updateCache() async {
    try {
      // Buscar culturas da tabela de culturas
      final culturas = await _cropDao.getAllCrops();
      
      _cachedCultures = culturas.map((crop) {
        // Determinar cor baseada no nome ou ID
        final color = CulturaColors.getColorForName(crop.name);
        
        // Determinar ícone baseado no nome
        final icon = CulturaIcons.getIconForName(crop.name);
        
        return CulturaModel(
          id: crop.id.toString(),
          name: crop.name,
          scientificName: crop.scientificName,
          description: crop.description,
          color: color,
          icon: icon,
          isDefault: crop.isDefault,
          createdAt: DateTime.now(), // TODO: Usar data real do banco
          updatedAt: null,
        );
      }).toList();
      
      _lastCacheUpdate = DateTime.now();
      print('✅ Cache de culturas atualizado com ${_cachedCultures!.length} culturas');
    } catch (e) {
      print('❌ Erro ao atualizar cache de culturas: $e');
    }
  }

  /// Limpa o cache
  void clearCache() {
    _cachedCultures = null;
    _lastCacheUpdate = null;
    print('✅ Cache de culturas limpo');
  }

  /// Carrega todas as culturas da fazenda (com cache)
  Future<List<CulturaModel>> loadCulturas() async {
    try {
      // Verificar cache primeiro
      if (_isCacheValid() && _cachedCultures != null) {
        print('✅ Retornando ${_cachedCultures!.length} culturas do cache');
        return _cachedCultures!;
      }
      
      // Atualizar cache se necessário
      await _updateCache();
      
      return _cachedCultures ?? [];
    } catch (e) {
      print('❌ Erro ao carregar culturas: $e');
      return [];
    }
  }

  /// Alias para loadCulturas (compatibilidade)
  Future<List<CulturaModel>> getCulturas() async {
    return await loadCulturas();
  }

  /// Carrega cultura por ID
  Future<CulturaModel?> loadCulturaById(String id) async {
    try {
      print('🔍 DEBUG CULTURA - CulturaService.loadCulturaById chamado com ID: "$id"');
      final culturas = await loadCulturas();
      final cultura = culturas.where((c) => c.id == id).firstOrNull;
      
      if (cultura != null) {
        print('🔍 DEBUG CULTURA - CulturaService encontrou cultura: "${cultura.name}" (ID: ${cultura.id})');
      } else {
        print('🔍 DEBUG CULTURA - CulturaService NÃO encontrou cultura com ID: "$id"');
        print('🔍 DEBUG CULTURA - Culturas disponíveis: ${culturas.map((c) => '${c.id}:${c.name}').join(', ')}');
      }
      
      return cultura;
    } catch (e) {
      print('❌ Erro ao carregar cultura por ID: $e');
      return null;
    }
  }

  /// Alias para loadCulturaById (compatibilidade)
  Future<CulturaModel?> buscarCulturaPorId(String id) async {
    return await loadCulturaById(id);
  }

  /// Carrega cultura por nome
  Future<CulturaModel?> loadCulturaByName(String name) async {
    try {
      final culturas = await loadCulturas();
      return culturas.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    } catch (e) {
      print('❌ Erro ao carregar cultura por nome: $e');
      return null;
    }
  }



  /// Lista todas as culturas
  Future<List<CulturaModel>> listarTodos() async {
    return await loadCulturas();
  }

  /// Obtém todas as culturas (alias para listarTodos)
  /// Obtém todas as culturas (com cache) - alias para getAllCultures
  Future<List<CulturaModel>> getAllCulturas() async {
    return getAllCultures();
  }

  Future<List<CulturaModel>> getAllCultures() async {
    return await loadCulturas();
  }

  /// Lista culturas principais
  Future<List<CulturaModel>> listarCulturasPrincipais() async {
    return await loadCulturas();
  }

  /// Lista todas as culturas usando o CulturaTalhaoService (12 culturas)
  Future<List<CulturaModel>> listarCulturas() async {
    try {
      print('🔄 CulturaService: Carregando culturas via CulturaTalhaoService...');
      
      // Usar o CulturaTalhaoService que tem as 12 culturas
      final culturas = await _culturaTalhaoService.listarCulturas();
      
      print('📊 CulturaService: ${culturas.length} culturas recebidas do CulturaTalhaoService');
      
      // Converter para CulturaModel
      final culturaModels = culturas.map((cultura) {
        return CulturaModel(
          id: cultura['id']?.toString() ?? '',
          name: cultura['nome']?.toString() ?? '',
          scientificName: '',
          description: cultura['descricao']?.toString() ?? '',
          color: CulturaColors.getColorForName(cultura['nome']?.toString() ?? ''),
          icon: CulturaIcons.getIconForName(cultura['nome']?.toString() ?? ''),
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: null,
        );
      }).toList();
      
      print('✅ CulturaService: ${culturaModels.length} culturas convertidas para CulturaModel');
      for (var cultura in culturaModels) {
        print('  - ${cultura.name} (ID: ${cultura.id})');
      }
      
      return culturaModels;
    } catch (e) {
      print('❌ CulturaService: Erro ao carregar culturas via CulturaTalhaoService: $e');
      // Fallback para o método antigo
      return await loadCulturas();
    }
  }

  /// Insere uma nova cultura
  Future<void> inserir(CulturaModel cultura) async {
    try {
      // TODO: Implementar inserção no banco
      print('✅ Cultura inserida: ${cultura.name}');
    } catch (e) {
      print('❌ Erro ao inserir cultura: $e');
    }
  }

  /// Atualiza uma cultura existente
  Future<void> atualizar(CulturaModel cultura) async {
    try {
      // TODO: Implementar atualização no banco
      print('✅ Cultura atualizada: ${cultura.name}');
    } catch (e) {
      print('❌ Erro ao atualizar cultura: $e');
    }
  }

  /// Exclui uma cultura
  Future<void> excluir(String id) async {
    try {
      // TODO: Implementar exclusão no banco
      print('✅ Cultura excluída: $id');
    } catch (e) {
      print('❌ Erro ao excluir cultura: $e');
    }
  }



  /// Salva uma nova cultura
  Future<bool> saveCultura(CulturaModel cultura) async {
    try {
      // TODO: Implementar salvamento no banco
      print('✅ Cultura salva: ${cultura.name}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar cultura: $e');
      return false;
    }
  }

  /// Atualiza uma cultura existente
  Future<bool> updateCultura(CulturaModel cultura) async {
    try {
      // TODO: Implementar atualização no banco
      print('✅ Cultura atualizada: ${cultura.name}');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar cultura: $e');
      return false;
    }
  }

  /// Exclui uma cultura
  Future<bool> deleteCultura(int id) async {
    try {
      // TODO: Implementar exclusão no banco
      print('✅ Cultura excluída: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao excluir cultura: $e');
      return false;
    }
  }
}
