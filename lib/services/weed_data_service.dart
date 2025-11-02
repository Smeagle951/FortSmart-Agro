import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/new_culture_model.dart';
import '../utils/logger.dart';

class WeedDataService {
  /// Mapeamento de IDs de cultura para arquivos JSON
  final Map<String, String> _cropFileMap = {
    'soja': 'plantas_daninhas_soja.json',
    'milho': 'plantas_daninhas_milho.json',
    'sorgo': 'plantas_daninhas_sorgo.json',
    'algodao': 'plantas_daninhas_algodao.json',
    'feijao': 'plantas_daninhas_feijao.json',
    'girassol': 'plantas_daninhas_girassol.json',
    'aveia': 'plantas_daninhas_aveia.json',
    'trigo': 'plantas_daninhas_trigo.json',
    'gergelim': 'plantas_daninhas_gergelim.json',
    'arroz': 'plantas_daninhas_arroz.json',
    'cana_acucar': 'plantas_daninhas_cana.json',
    'tomate': 'plantas_daninhas_cafe.json', // Usando café como fallback para tomate
    // Mapeamentos adicionais para compatibilidade
    'custom_soja': 'plantas_daninhas_soja.json',
    'custom_milho': 'plantas_daninhas_milho.json',
    'custom_sorgo': 'plantas_daninhas_sorgo.json',
    'custom_algodao': 'plantas_daninhas_algodao.json',
    'custom_feijao': 'plantas_daninhas_feijao.json',
    'custom_girassol': 'plantas_daninhas_girassol.json',
    'custom_aveia': 'plantas_daninhas_aveia.json',
    'custom_trigo': 'plantas_daninhas_trigo.json',
    'custom_gergelim': 'plantas_daninhas_gergelim.json',
    'custom_arroz': 'plantas_daninhas_arroz.json',
    'custom_cana': 'plantas_daninhas_cana.json',
    'custom_cafe': 'plantas_daninhas_cafe.json',
  };

  /// Carrega plantas daninhas para uma cultura específica
  Future<List<Organism>> loadWeedsForCrop(String cropId) async {
    try {
      final fileName = _cropFileMap[cropId];
      if (fileName == null) {
        Logger.warning('⚠️ Arquivo de plantas daninhas não encontrado para $cropId');
        return [];
      }

      Logger.info('🔄 Carregando plantas daninhas de: $fileName para cultura $cropId');
      
      try {
        final jsonData = await rootBundle.loadString('assets/data/$fileName');
        final data = json.decode(jsonData);
        final weedsData = data['plantas_daninhas'] as List;
        
        final weeds = weedsData.map((weedData) => Organism(
          id: weedData['id'] ?? '',
          name: weedData['nome'] ?? '',
          scientificName: weedData['nome_cientifico'] ?? '',
          category: weedData['categoria'] ?? 'Planta Daninha',
          description: weedData['observacoes'] ?? '',
          symptoms: List<String>.from(weedData['sintomas'] ?? []),
        )).toList();
        
        Logger.info('✅ ${weeds.length} plantas daninhas específicas carregadas para $cropId');
        return weeds;
      } catch (e) {
        Logger.error('❌ Erro ao carregar arquivo $fileName: $e');
        return [];
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar plantas daninhas para $cropId: $e');
      return [];
    }
  }

  /// Retorna plantas daninhas específicas para cada cultura (fallback)
  List<Organism> _getCropSpecificWeeds(String cropId) {
    // Se não encontrar arquivo específico, retorna lista vazia
    // para forçar o uso dos arquivos JSON corretos
    Logger.warning('⚠️ Nenhum arquivo específico encontrado para $cropId');
    return [];
  }

  /// Plantas daninhas genéricas (fallback final) - apenas para casos extremos
  List<Organism> _getGenericWeeds() {
    Logger.warning('⚠️ Usando plantas daninhas genéricas como último recurso');
    return [
      Organism(
        id: 'generic_caruru',
        name: 'Caruru',
        scientificName: 'Amaranthus spp.',
        category: 'Planta Daninha',
        description: 'Planta daninha comum em várias culturas',
        symptoms: ['Competição por recursos', 'Redução da produtividade'],
      ),
    ];
  }
}