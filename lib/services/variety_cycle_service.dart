import 'package:flutter/material.dart';
import '../widgets/variety_cycle_selector.dart';
import '../repositories/crop_variety_repository.dart';
import '../models/crop_variety.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// Serviço para gerenciar variedades e ciclos de culturas
class VarietyCycleService {
  static final VarietyCycleService _instance = VarietyCycleService._internal();
  factory VarietyCycleService() => _instance;
  VarietyCycleService._internal();

  final CropVarietyRepository _cropVarietyRepository = CropVarietyRepository();
  final AppDatabase _appDatabase = AppDatabase();

  /// Obtém as variedades disponíveis para uma cultura específica do banco de dados
  Future<List<Variety>> getVarietiesForCrop(String cropId, String cropName) async {
    try {
      // Primeiro, tentar buscar do banco de dados
      final varietiesFromDb = await _getVarietiesFromDatabase(cropId);
      
      if (varietiesFromDb.isNotEmpty) {
        print('✅ ${varietiesFromDb.length} variedades encontradas no banco para cultura $cropName');
        return varietiesFromDb;
      }
      
      // Se não encontrar no banco, usar variedades padrão
      print('⚠️ Nenhuma variedade encontrada no banco para $cropName, usando variedades padrão');
      return _getDefaultVarietiesForCrop(cropName);
      
    } catch (e) {
      print('❌ Erro ao buscar variedades do banco: $e');
      // Em caso de erro, usar variedades padrão
      return _getDefaultVarietiesForCrop(cropName);
    }
  }

  /// Busca variedades no banco de dados
  Future<List<Variety>> _getVarietiesFromDatabase(String cropId) async {
    try {
      final cropVarieties = await _cropVarietyRepository.getByCropId(cropId);
      
      return cropVarieties.map((cropVariety) {
        // Determinar cor baseada no nome da variedade
        final color = _getColorForVarietyName(cropVariety.name);
        
        return Variety(
          id: cropVariety.id,
          name: cropVariety.name,
          description: cropVariety.description ?? '',
          type: _extractVarietyType(cropVariety.name),
          color: color,
        );
      }).toList();
      
    } catch (e) {
      print('❌ Erro ao buscar variedades do banco: $e');
      return [];
    }
  }

  /// Obtém variedades padrão para uma cultura (fallback)
  List<Variety> _getDefaultVarietiesForCrop(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'soja':
      case 'soybean':
        return _getSoybeanVarieties();
      case 'milho':
      case 'corn':
      case 'maize':
        return _getCornVarieties();
      case 'algodão':
      case 'cotton':
        return _getCottonVarieties();
      case 'café':
      case 'coffee':
        return _getCoffeeVarieties();
      case 'trigo':
      case 'wheat':
        return _getWheatVarieties();
      default:
        return _getDefaultVarieties();
    }
  }

  /// Extrai o tipo da variedade baseado no nome
  String _extractVarietyType(String varietyName) {
    final name = varietyName.toLowerCase();
    
    if (name.contains('rr') || name.contains('roundup')) return 'RR';
    if (name.contains('intacta') || name.contains('intact')) return 'Intacta';
    if (name.contains('bt') || name.contains('bacillus')) return 'Bt';
    if (name.contains('ht') || name.contains('herbicide')) return 'HT';
    if (name.contains('convencional') || name.contains('conventional')) return 'Convencional';
    if (name.contains('híbrida') || name.contains('hybrid')) return 'Híbrida';
    
    return 'Padrão';
  }

  /// Obtém cor para o nome da variedade
  Color _getColorForVarietyName(String varietyName) {
    final name = varietyName.toLowerCase();
    
    if (name.contains('rr') || name.contains('roundup')) return Colors.orange;
    if (name.contains('intacta') || name.contains('intact')) return Colors.blue;
    if (name.contains('bt') || name.contains('bacillus')) return Colors.purple;
    if (name.contains('ht') || name.contains('herbicide')) return Colors.green;
    if (name.contains('convencional') || name.contains('conventional')) return Colors.green;
    if (name.contains('híbrida') || name.contains('hybrid')) return Colors.blue;
    
    return Colors.grey;
  }

  /// Obtém os ciclos disponíveis
  List<Cycle> getAvailableCycles() {
    return [
      const Cycle(
        id: 'super_precoce',
        name: 'Super Precoce',
        days: 90,
        description: 'Ciclo muito rápido, ideal para regiões com restrições climáticas',
      ),
      const Cycle(
        id: 'precoce',
        name: 'Precoce',
        days: 105,
        description: 'Ciclo rápido, boa produtividade em tempo reduzido',
      ),
      const Cycle(
        id: 'medio_precoce',
        name: 'Médio Precoce',
        days: 120,
        description: 'Ciclo intermediário, equilíbrio entre produtividade e tempo',
      ),
      const Cycle(
        id: 'medio',
        name: 'Médio',
        days: 135,
        description: 'Ciclo médio, alta produtividade e estabilidade',
      ),
      const Cycle(
        id: 'medio_tardio',
        name: 'Médio Tardio',
        days: 150,
        description: 'Ciclo mais longo, máxima produtividade',
      ),
      const Cycle(
        id: 'tardio',
        name: 'Tardio',
        days: 165,
        description: 'Ciclo longo, ideal para regiões com estação favorável',
      ),
      const Cycle(
        id: 'super_tardio',
        name: 'Super Tardio',
        days: 180,
        description: 'Ciclo muito longo, máxima produtividade em condições ideais',
      ),
    ];
  }

  /// Obtém ciclos específicos para uma cultura
  List<Cycle> getCyclesForCrop(String cropId, String cropName) {
    switch (cropName.toLowerCase()) {
      case 'soja':
      case 'soybean':
        return _getSoybeanCycles();
      case 'milho':
      case 'corn':
      case 'maize':
        return _getCornCycles();
      case 'algodão':
      case 'cotton':
        return _getCottonCycles();
      case 'café':
      case 'coffee':
        return _getCoffeeCycles();
      case 'trigo':
      case 'wheat':
        return _getWheatCycles();
      default:
        return getAvailableCycles();
    }
  }

  /// Cria uma nova variedade no banco de dados
  Future<String> createVariety({
    required String cropId,
    required String name,
    required String type,
    required int cycleDays,
    String? description,
    String? company,
  }) async {
    try {
      final variety = CropVariety(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cropId: cropId,
        name: name,
        company: company,
        cycleDays: cycleDays,
        description: description ?? '',
        recommendedPopulation: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      final varietyId = await _cropVarietyRepository.insert(variety);
      print('✅ Nova variedade criada: $name (ID: $varietyId)');
      return varietyId;
      
    } catch (e) {
      print('❌ Erro ao criar variedade: $e');
      rethrow;
    }
  }

  /// Verifica se uma variedade já existe para uma cultura
  Future<bool> varietyExists(String cropId, String varietyName) async {
    try {
      final varieties = await _cropVarietyRepository.getByCropId(cropId);
      return varieties.any((v) => v.name.toLowerCase() == varietyName.toLowerCase());
    } catch (e) {
      print('❌ Erro ao verificar existência da variedade: $e');
      return false;
    }
  }

  /// Obtém combinações recomendadas de variedade e ciclo
  Future<List<VarietyCycleSelection>> getRecommendedCombinations(String cropId, String cropName) async {
    final varieties = await getVarietiesForCrop(cropId, cropName);
    final cycles = getCyclesForCrop(cropId, cropName);
    
    final List<VarietyCycleSelection> combinations = [];
    
    // Para soja, criar combinações mais específicas
    if (cropName.toLowerCase() == 'soja' || cropName.toLowerCase() == 'soybean') {
      // Soja RR com ciclos médios
      final sojaRR = varieties.firstWhere((v) => v.type == 'RR');
      final cicloMedio = cycles.firstWhere((c) => c.days == 120);
      combinations.add(VarietyCycleSelection(variety: sojaRR, cycle: cicloMedio));
      
      // Soja Intacta com ciclos mais longos
      final sojaIntacta = varieties.firstWhere((v) => v.type == 'Intacta');
      final cicloLongo = cycles.firstWhere((c) => c.days == 135);
      combinations.add(VarietyCycleSelection(variety: sojaIntacta, cycle: cicloLongo));
      
      // Soja Convencional com ciclos precoces
      final sojaConvencional = varieties.firstWhere((v) => v.type == 'Convencional');
      final cicloPrecoce = cycles.firstWhere((c) => c.days == 105);
      combinations.add(VarietyCycleSelection(variety: sojaConvencional, cycle: cicloPrecoce));
    }
    
    return combinations;
  }

  /// Valida se uma combinação de variedade e ciclo é adequada
  bool isValidCombination(Variety variety, Cycle cycle) {
    // Regras de validação baseadas na cultura e tipo
    switch (variety.type) {
      case 'RR':
        // Soja RR funciona bem com ciclos de 90 a 150 dias
        return cycle.days >= 90 && cycle.days <= 150;
      case 'Intacta':
        // Soja Intacta funciona melhor com ciclos de 120 a 180 dias
        return cycle.days >= 120 && cycle.days <= 180;
      case 'Convencional':
        // Soja Convencional funciona bem com ciclos de 90 a 135 dias
        return cycle.days >= 90 && cycle.days <= 135;
      default:
        return true; // Para outras culturas, aceitar qualquer combinação
    }
  }

  /// Obtém sugestões de ciclos para uma variedade específica
  List<Cycle> getRecommendedCyclesForVariety(Variety variety) {
    final allCycles = getAvailableCycles();
    
    return allCycles.where((cycle) {
      return isValidCombination(variety, cycle);
    }).toList();
  }

  // Métodos privados para obter variedades específicas

  List<Variety> _getSoybeanVarieties() {
    return [
      const Variety(
        id: 'soja_rr',
        name: 'Soja RR',
        description: 'Resistente ao glifosato, amplamente utilizada',
        type: 'RR',
        color: Colors.orange,
      ),
      const Variety(
        id: 'soja_intacta',
        name: 'Soja Intacta',
        description: 'Resistente a insetos e herbicidas',
        type: 'Intacta',
        color: Colors.blue,
      ),
      const Variety(
        id: 'soja_convencional',
        name: 'Soja Convencional',
        description: 'Variedade tradicional sem modificações',
        type: 'Convencional',
        color: Colors.green,
      ),
      const Variety(
        id: 'soja_bt',
        name: 'Soja Bt',
        description: 'Resistente a insetos',
        type: 'Bt',
        color: Colors.purple,
      ),
    ];
  }

  List<Variety> _getCornVarieties() {
    return [
      const Variety(
        id: 'milho_bt',
        name: 'Milho Bt',
        description: 'Resistente a insetos',
        type: 'Bt',
        color: Colors.yellow,
      ),
      const Variety(
        id: 'milho_ht',
        name: 'Milho HT',
        description: 'Resistente a herbicidas',
        type: 'HT',
        color: Colors.orange,
      ),
      const Variety(
        id: 'milho_convencional',
        name: 'Milho Convencional',
        description: 'Variedade tradicional',
        type: 'Convencional',
        color: Colors.green,
      ),
    ];
  }

  List<Variety> _getCottonVarieties() {
    return [
      const Variety(
        id: 'algodao_bt',
        name: 'Algodão Bt',
        description: 'Resistente a insetos',
        type: 'Bt',
        color: Colors.white,
      ),
      const Variety(
        id: 'algodao_convencional',
        name: 'Algodão Convencional',
        description: 'Variedade tradicional',
        type: 'Convencional',
        color: Colors.grey,
      ),
    ];
  }

  List<Variety> _getCoffeeVarieties() {
    return [
      const Variety(
        id: 'cafe_arabica',
        name: 'Café Arábica',
        description: 'Qualidade superior, aroma delicado',
        type: 'Arábica',
        color: Colors.brown,
      ),
      const Variety(
        id: 'cafe_robusta',
        name: 'Café Robusta',
        description: 'Maior resistência, teor de cafeína elevado',
        type: 'Robusta',
        color: Colors.brown,
      ),
    ];
  }

  List<Variety> _getWheatVarieties() {
    return [
      const Variety(
        id: 'trigo_branco',
        name: 'Trigo Branco',
        description: 'Para panificação',
        type: 'Branco',
        color: Colors.amber,
      ),
      const Variety(
        id: 'trigo_duro',
        name: 'Trigo Duro',
        description: 'Para massas',
        type: 'Duro',
        color: Colors.orange,
      ),
    ];
  }

  List<Variety> _getDefaultVarieties() {
    return [
      const Variety(
        id: 'convencional',
        name: 'Convencional',
        description: 'Variedade tradicional',
        type: 'Convencional',
        color: Colors.green,
      ),
      const Variety(
        id: 'hibrida',
        name: 'Híbrida',
        description: 'Variedade híbrida',
        type: 'Híbrida',
        color: Colors.blue,
      ),
    ];
  }

  // Métodos privados para obter ciclos específicos

  List<Cycle> _getSoybeanCycles() {
    return [
      const Cycle(id: 'precoce', name: 'Precoce', days: 105, description: 'Ciclo rápido'),
      const Cycle(id: 'medio_precoce', name: 'Médio Precoce', days: 120, description: 'Ciclo intermediário'),
      const Cycle(id: 'medio', name: 'Médio', days: 135, description: 'Ciclo médio'),
      const Cycle(id: 'medio_tardio', name: 'Médio Tardio', days: 150, description: 'Ciclo longo'),
      const Cycle(id: 'tardio', name: 'Tardio', days: 165, description: 'Ciclo muito longo'),
    ];
  }

  List<Cycle> _getCornCycles() {
    return [
      const Cycle(id: 'super_precoce', name: 'Super Precoce', days: 90, description: 'Ciclo muito rápido'),
      const Cycle(id: 'precoce', name: 'Precoce', days: 105, description: 'Ciclo rápido'),
      const Cycle(id: 'medio', name: 'Médio', days: 135, description: 'Ciclo médio'),
      const Cycle(id: 'tardio', name: 'Tardio', days: 165, description: 'Ciclo longo'),
    ];
  }

  List<Cycle> _getCottonCycles() {
    return [
      const Cycle(id: 'precoce', name: 'Precoce', days: 120, description: 'Ciclo rápido'),
      const Cycle(id: 'medio', name: 'Médio', days: 150, description: 'Ciclo médio'),
      const Cycle(id: 'tardio', name: 'Tardio', days: 180, description: 'Ciclo longo'),
    ];
  }

  List<Cycle> _getCoffeeCycles() {
    return [
      const Cycle(id: 'medio', name: 'Médio', days: 270, description: 'Ciclo médio'),
      const Cycle(id: 'tardio', name: 'Tardio', days: 330, description: 'Ciclo longo'),
    ];
  }

  List<Cycle> _getWheatCycles() {
    return [
      const Cycle(id: 'precoce', name: 'Precoce', days: 120, description: 'Ciclo rápido'),
      const Cycle(id: 'medio', name: 'Médio', days: 150, description: 'Ciclo médio'),
      const Cycle(id: 'tardio', name: 'Tardio', days: 180, description: 'Ciclo longo'),
    ];
  }
}
