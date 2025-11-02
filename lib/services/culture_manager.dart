import 'package:fortsmart_agro/models/cultura_model.dart';
import 'package:fortsmart_agro/services/cultura_talhao_service.dart';
import 'package:fortsmart_agro/services/culture_import_service.dart';
import 'package:fortsmart_agro/services/cultura_service.dart';
import 'package:fortsmart_agro/repositories/crop_repository.dart';

/// Manager centralizado para carregamento de culturas
class CultureManager {
  static final CultureManager _instance = CultureManager._internal();
  factory CultureManager() => _instance;
  CultureManager._internal();

  final CulturaTalhaoService _culturaTalhaoService = CulturaTalhaoService();
  final CultureImportService _cultureImportService = CultureImportService();
  final CulturaService _culturaService = CulturaService();
  final CropRepository _cropRepository = CropRepository();

  /// Carrega culturas tentando múltiplas fontes na ordem de prioridade
  Future<List<CulturaModel>> loadCultures() async {
    try {
      // Tentar CulturaTalhaoService primeiro
      final talhaoCultures = await _culturaTalhaoService.getCulturas();
      if (talhaoCultures.isNotEmpty) {
        return _normalizeCultures(talhaoCultures);
      }

      // Tentar CultureImportService
      final importCultures = await _cultureImportService.getCultures();
      if (importCultures.isNotEmpty) {
        return _normalizeCultures(importCultures);
      }

      // Tentar CulturaService
      final culturaCultures = await _culturaService.getCulturas();
      if (culturaCultures.isNotEmpty) {
        return _normalizeCultures(culturaCultures);
      }

      // Fallback para CropRepository
      final cropCultures = await _cropRepository.getAllCrops();
      return _normalizeCultures(cropCultures);
    } catch (e) {
      // Em caso de erro, retornar lista vazia
      return [];
    }
  }

  /// Normaliza lista de culturas para formato padrão
  List<CulturaModel> _normalizeCultures(List<dynamic> cultures) {
    return cultures.map((culture) {
      if (culture is CulturaModel) {
        return culture;
      } else if (culture is Map<String, dynamic>) {
        return CulturaModel.fromMap(culture);
      } else {
        // Converter outros tipos para CulturaModel
        return CulturaModel(
          id: culture.id?.toString() ?? '',
          nome: culture.name ?? culture.nome ?? 'Cultura Desconhecida',
          cor: _getColorForCulture(culture.name ?? culture.nome ?? ''),
          icone: _getIconForCulture(culture.name ?? culture.nome ?? ''),
        );
      }
    }).toList();
  }

  /// Obtém cor padrão para uma cultura
  String _getColorForCulture(String cultureName) {
    final colorMap = {
      'Soja': '#4CAF50',
      'Milho': '#FFEB3B',
      'Algodão': '#E0E0E0', // Cinza claro
      'Café': '#8D6E63',
      'Cana-de-açúcar': '#FF9800',
      'Arroz': '#2196F3',
      'Feijão': '#F44336',
      'Trigo': '#FFC107',
      'Girassol': '#FF9800',
      'Sorgo': '#9C27B0',
    };
    
    return colorMap[cultureName] ?? '#4CAF50'; // Verde padrão
  }

  /// Obtém ícone padrão para uma cultura
  String _getIconForCulture(String cultureName) {
    final iconMap = {
      'Soja': '🌱',
      'Milho': '🌽',
      'Algodão': '☁️',
      'Café': '☕',
      'Cana-de-açúcar': '🎋',
      'Arroz': '🌾',
      'Feijão': '🫘',
      'Trigo': '🌾',
      'Girassol': '🌻',
      'Sorgo': '🌾',
    };
    
    return iconMap[cultureName] ?? '🌱'; // Planta padrão
  }

  /// Busca cultura por nome
  Future<CulturaModel?> findCultureByName(String name) async {
    final cultures = await loadCultures();
    try {
      return cultures.firstWhere((culture) => 
        culture.nome.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// Obtém culturas mais utilizadas
  Future<List<CulturaModel>> getPopularCultures() async {
    final cultures = await loadCultures();
    // Retornar as primeiras 10 culturas (pode ser melhorado com estatísticas)
    return cultures.take(10).toList();
  }
}
