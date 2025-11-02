import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/new_culture_model.dart';
import '../database/app_database.dart';
import 'weed_data_service.dart';

/// Serviço para carregar as 12 culturas dos arquivos JSON
class NewCultureService {
  final AppDatabase _database = AppDatabase();
  
  /// Carrega todas as 12 culturas dos arquivos JSON
  Future<List<NewCulture>> loadAllCultures() async {
    try {
      print('🌱 Iniciando carregamento das 12 culturas...');
      
      final List<NewCulture> cultures = [];
      
      // Lista das 12 culturas com suas cores
      final cultureConfigs = [
        {'file': 'organismos_soja.json', 'name': 'Soja', 'color': Colors.green},
        {'file': 'organismos_milho.json', 'name': 'Milho', 'color': Colors.yellow},
        {'file': 'organismos_algodao.json', 'name': 'Algodão', 'color': const Color(0xFFE1F5FE)}, // Azul claro
        {'file': 'organismos_feijao.json', 'name': 'Feijão', 'color': Colors.brown},
        {'file': 'organismos_girassol.json', 'name': 'Girassol', 'color': Colors.orange},
        {'file': 'organismos_arroz.json', 'name': 'Arroz', 'color': Colors.blue},
        {'file': 'organismos_sorgo.json', 'name': 'Sorgo', 'color': Colors.purple},
        {'file': 'organismos_trigo.json', 'name': 'Trigo', 'color': Colors.amber},
        {'file': 'organismos_aveia.json', 'name': 'Aveia', 'color': Colors.teal},
        {'file': 'organismos_gergelim.json', 'name': 'Gergelim', 'color': Colors.indigo},
        {'file': 'organismos_cana_acucar.json', 'name': 'Cana-de-açúcar', 'color': Colors.lime},
        {'file': 'organismos_tomate.json', 'name': 'Tomate', 'color': Colors.red},
      ];
      
      for (final config in cultureConfigs) {
        try {
          print('📄 Carregando ${config['file']}...');
          final culture = await _loadCultureFromFile(
            config['file'] as String,
            config['name'] as String,
            config['color'] as Color,
          );
          
          if (culture != null) {
            cultures.add(culture);
            print('✅ ${culture.name} carregada: ${culture.pests.length} pragas, ${culture.diseases.length} doenças, ${culture.weeds.length} plantas daninhas');
          }
        } catch (e) {
          print('❌ Erro ao carregar ${config['file']}: $e');
        }
      }
      
      print('🎉 Carregamento concluído! ${cultures.length} culturas carregadas');
      return cultures;
      
    } catch (e) {
      print('❌ Erro geral ao carregar culturas: $e');
      rethrow;
    }
  }
  
  /// Carrega uma cultura específica de um arquivo JSON
  Future<NewCulture?> _loadCultureFromFile(String fileName, String cultureName, Color color) async {
    try {
      // Carregar arquivo JSON
      final jsonString = await rootBundle.loadString('assets/data/$fileName');
      final jsonData = json.decode(jsonString);
      
      final cultura = jsonData['cultura'] ?? cultureName;
      final nomeCientifico = jsonData['nome_cientifico'] ?? '';
      final organismos = jsonData['organismos'] ?? [];
      
      // Separar organismos por categoria
      final List<Organism> pests = [];
      final List<Organism> diseases = [];
      final List<Organism> weeds = [];
      
      for (final organismo in organismos) {
        try {
          final organism = Organism.fromJson(organismo);
          
          // Determinar categoria baseada no tipo ou categoria
          final tipo = organismo['tipo']?.toString().toUpperCase() ?? '';
          final categoria = organismo['categoria']?.toString() ?? '';
          
          if (tipo == 'PRAGA' || categoria.toLowerCase().contains('praga')) {
            pests.add(organism);
          } else if (tipo == 'DOENÇA' || categoria.toLowerCase().contains('doença')) {
            diseases.add(organism);
          } else if (tipo == 'PLANTA_DANINHA' || categoria.toLowerCase().contains('planta daninha')) {
            weeds.add(organism);
          }
        } catch (e) {
          print('⚠️ Erro ao processar organismo: $e');
        }
      }
      
      // Carregar variedades e plantas daninhas do banco de dados
      final cultureId = _generateId(cultura);
      print('🔍 Carregando dados adicionais para cultura $cultura (ID: $cultureId)');
      
      final varieties = await _loadVarietiesForCulture(cultureId);
      print('📊 Variedades carregadas: ${varieties.length}');
      
      final additionalWeeds = await _loadWeedsForCulture(cultureId);
      print('🌿 Plantas daninhas adicionais: ${additionalWeeds.length}');
      
      // Combinar plantas daninhas do JSON com as do banco
      final allWeeds = [...weeds, ...additionalWeeds];
      print('🌿 Total de plantas daninhas: ${allWeeds.length}');
      
      // Criar cultura
      final culture = NewCulture(
        id: cultureId,
        name: cultura,
        scientificName: nomeCientifico,
        description: 'Cultura carregada do arquivo $fileName',
        color: color,
        pests: pests,
        diseases: diseases,
        weeds: allWeeds,
        varieties: varieties,
      );
      
      print('✅ Cultura $cultura criada com ${varieties.length} variedades e ${allWeeds.length} plantas daninhas');
      
      return culture;
      
    } catch (e) {
      print('❌ Erro ao carregar $fileName: $e');
      return null;
    }
  }
  
  /// Carrega variedades para uma cultura específica
  /// SOLUÇÃO SIMPLIFICADA: Busca direto sem depender da tabela crops
  Future<List<Variety>> _loadVarietiesForCulture(String cultureId) async {
    try {
      print('🔍 [SIMPLE] Buscando variedades para cultura: $cultureId');
      
      final db = await _database.database;
      
      // Buscar TODAS as variedades
      final allVarieties = await db.query('crop_varieties');
      print('📊 [SIMPLE] Total de variedades no banco: ${allVarieties.length}');
      
           // Mapeamento completo e robusto para todas as culturas
           final idMap = {
             // Culturas principais
             'soja': '10',
             'milho': '2',
             'algodao': '3',
             'algodão': '3',
             'feijao': '4',
             'feijão': '4',
             'girassol': '5',
             'arroz': '14',
             'sorgo': '16',
             'trigo': '13',
             'aveia': '11',
             'gergelim': '12',
             'cana-de-acucar': '15',
             'cana_acucar': '15',
             'tomate': '17',
             
             // Variações de nomes
             'SOJA': '10',
             'MILHO': '2',
             'ALGODAO': '3',
             'ALGODÃO': '3',
             'FEIJAO': '4',
             'FEIJÃO': '4',
             'GIRASSOL': '5',
             'ARROZ': '14',
             'SORGO': '16',
             'TRIGO': '13',
             'AVEIA': '11',
             'GERGELIM': '12',
             'CANA-DE-ACUCAR': '15',
             'CANA_ACUCAR': '15',
             'TOMATE': '17',
           };
      
      final targetId = idMap[cultureId];
      
      if (targetId == null) {
        print('⚠️ [SIMPLE] ID não mapeado para cultura: $cultureId');
        return [];
      }
      
      // Filtrar variedades manualmente
      final filtered = allVarieties.where((v) => v['cropId'].toString() == targetId).toList();
      
      print('✅ [SIMPLE] Encontradas ${filtered.length} variedades para $cultureId (ID: $targetId)');
      
      if (filtered.isNotEmpty) {
        print('📝 [SIMPLE] Variedades:');
        for (final map in filtered) {
          print('   - ${map['name']} (cropId: ${map['cropId']})');
        }
      }
      
      return filtered.map((map) => Variety(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        cycleDays: map['cycleDays'] as int?,
        notes: map['notes']?.toString() ?? '',
      )).toList();
    } catch (e) {
      print('❌ [SIMPLE] Erro ao carregar variedades para $cultureId: $e');
      return [];
    }
  }
  
  /// Carrega plantas daninhas para uma cultura específica
  Future<List<Organism>> _loadWeedsForCulture(String cultureId) async {
    try {
      // Usar o WeedDataService para carregar plantas daninhas
      final weedDataService = WeedDataService();
      return await weedDataService.loadWeedsForCrop(cultureId);
    } catch (e) {
      print('⚠️ Erro ao carregar plantas daninhas para $cultureId: $e');
      return [];
    }
  }
  
  /// Gera um ID único para a cultura
  String _generateId(String cultureName) {
    return cultureName.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('õ', 'o')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }
  
  /// Obtém estatísticas das culturas
  Map<String, int> getStatistics(List<NewCulture> cultures) {
    int totalPests = 0;
    int totalDiseases = 0;
    int totalWeeds = 0;
    int totalVarieties = 0;
    
    for (final culture in cultures) {
      totalPests += culture.pests.length;
      totalDiseases += culture.diseases.length;
      totalWeeds += culture.weeds.length;
      totalVarieties += culture.varieties.length;
    }
    
    return {
      'cultures': cultures.length,
      'pests': totalPests,
      'diseases': totalDiseases,
      'weeds': totalWeeds,
      'varieties': totalVarieties,
    };
  }

  /// Atualiza uma cultura existente
  Future<void> updateCulture(NewCulture culture) async {
    try {
      print('🔄 Atualizando cultura: ${culture.name}');
      
      // Salvar no banco de dados real
      final db = await _database.database;
      
      // Atualizar dados da cultura
      await db.update(
        'culturas',
        {
          'name': culture.name,
          'scientific_name': culture.scientificName,
          'description': culture.description,
          'color_value': culture.color.value.toRadixString(16).substring(2),
        },
        where: 'id = ?',
        whereArgs: [culture.id],
      );
      
      print('✅ Cultura ${culture.name} atualizada com sucesso no banco de dados');
    } catch (e) {
      print('❌ Erro ao atualizar cultura ${culture.name}: $e');
      rethrow;
    }
  }

  /// Deleta uma cultura
  Future<void> deleteCulture(String cultureId) async {
    try {
      print('🗑️ Deletando cultura ID: $cultureId');
      
      // Deletar do banco de dados real
      final db = await _database.database;
      
      // Primeiro, deletar organismos relacionados
      await db.delete(
        'organismos',
        where: 'cultura_id = ?',
        whereArgs: [cultureId],
      );
      
      // Depois, deletar a cultura
      final result = await db.delete(
        'culturas',
        where: 'id = ?',
        whereArgs: [cultureId],
      );
      
      if (result > 0) {
        print('✅ Cultura $cultureId deletada com sucesso do banco de dados');
      } else {
        print('⚠️ Cultura $cultureId não encontrada no banco de dados');
      }
    } catch (e) {
      print('❌ Erro ao deletar cultura $cultureId: $e');
      rethrow;
    }
  }
}
