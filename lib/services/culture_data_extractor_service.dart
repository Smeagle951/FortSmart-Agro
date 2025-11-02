import 'dart:convert';
import 'package:flutter/services.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../database/models/crop.dart' as db_crop;
import '../models/pest.dart';
import '../models/disease.dart';
import '../models/weed.dart';
import '../utils/logger.dart';

/// Serviço para extrair dados dos JSONs e criar culturas diretamente no banco
class CultureDataExtractorService {
  final CropDao _cropDao = CropDao();
  final PestDao _pestDao = PestDao();
  final DiseaseDao _diseaseDao = DiseaseDao();
  final WeedDao _weedDao = WeedDao();

  /// Lista de plantas daninhas comuns por cultura (criadas como agronomo)
  static const Map<String, List<Map<String, String>>> _commonWeeds = {
    'soja': [
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Buva', 'scientificName': 'Conyza bonariensis'},
      {'name': 'Capim-amargoso', 'scientificName': 'Digitaria insularis'},
      {'name': 'Capim-pé-de-galinha', 'scientificName': 'Eleusine indica'},
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
      {'name': 'Cordas-de-viola', 'scientificName': 'Ipomoea spp.'},
      {'name': 'Trapoeraba', 'scientificName': 'Commelina benghalensis'},
      {'name': 'Leiteiro', 'scientificName': 'Euphorbia heterophylla'},
    ],
    'milho': [
      {'name': 'Sorgo-de-alepo', 'scientificName': 'Sorghum halepense'},
      {'name': 'Capim-pé-de-galinha', 'scientificName': 'Eleusine indica'},
      {'name': 'Capim-amargoso', 'scientificName': 'Digitaria insularis'},
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
      {'name': 'Cordas-de-viola', 'scientificName': 'Ipomoea spp.'},
      {'name': 'Trapoeraba', 'scientificName': 'Commelina benghalensis'},
    ],
    'algodao': [
      {'name': 'Cordas-de-viola', 'scientificName': 'Ipomoea spp.'},
      {'name': 'Trapoeraba', 'scientificName': 'Commelina benghalensis'},
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Buva', 'scientificName': 'Conyza bonariensis'},
      {'name': 'Capim-amargoso', 'scientificName': 'Digitaria insularis'},
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
      {'name': 'Leiteiro', 'scientificName': 'Euphorbia heterophylla'},
      {'name': 'Capim-colchão', 'scientificName': 'Digitaria horizontalis'},
    ],
    'feijao': [
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
      {'name': 'Capim-pé-de-galinha', 'scientificName': 'Eleusine indica'},
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Cordas-de-viola', 'scientificName': 'Ipomoea spp.'},
      {'name': 'Trapoeraba', 'scientificName': 'Commelina benghalensis'},
    ],
    'girassol': [
      {'name': 'Cordas-de-viola', 'scientificName': 'Ipomoea spp.'},
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
      {'name': 'Capim-pé-de-galinha', 'scientificName': 'Eleusine indica'},
      {'name': 'Trapoeraba', 'scientificName': 'Commelina benghalensis'},
    ],
    'arroz': [
      {'name': 'Capim-arroz', 'scientificName': 'Echinochloa spp.'},
      {'name': 'Alface-d\'água', 'scientificName': 'Pistia stratiotes'},
      {'name': 'Aguapé', 'scientificName': 'Eichhornia crassipes'},
      {'name': 'Capim-colonião', 'scientificName': 'Panicum maximum'},
    ],
    'sorgo': [
      {'name': 'Sorgo-de-alepo', 'scientificName': 'Sorghum halepense'},
      {'name': 'Capim-pé-de-galinha', 'scientificName': 'Eleusine indica'},
      {'name': 'Capim-amargoso', 'scientificName': 'Digitaria insularis'},
      {'name': 'Caruru', 'scientificName': 'Amaranthus hybridus'},
      {'name': 'Picão-preto', 'scientificName': 'Bidens pilosa'},
    ],
  };

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      await _cropDao.initialize();
      // await _pestDao.initialize();
      // await _diseaseDao.initialize();
      // await _weedDao.initialize();
      Logger.info('✅ CultureDataExtractorService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar CultureDataExtractorService: $e');
      rethrow;
    }
  }

  /// Extrai dados dos JSONs e cria culturas completas no banco
  Future<Map<String, dynamic>> extractAndCreateAllCultures() async {
    try {
      Logger.info('🔄 Iniciando extração e criação de culturas...');
      
      // Lista de arquivos JSON disponíveis
      final jsonFiles = [
        'lib/data/organismos_soja.json',
        'lib/data/organismos_milho.json',
        'lib/data/organismos_algodao.json',
        'lib/data/organismos_feijao.json',
        'lib/data/organismos_girassol.json',
        'lib/data/organismos_arroz.json',
        'lib/data/organismos_sorgo.json',
        'lib/data/organismos_gergelim.json',
        'lib/data/organismos_cana_acucar.json',
        'lib/data/organismos_tomate.json',
        'lib/data/organismos_trigo.json',
        'lib/data/organismos_aveia.json',
      ];

      int totalCrops = 0;
      int totalPests = 0;
      int totalDiseases = 0;
      int totalWeeds = 0;

      // Limpar dados existentes
      await _clearExistingData();

      // Processar cada arquivo JSON
      for (final jsonFile in jsonFiles) {
        try {
          final result = await _processJsonFile(jsonFile);
          totalCrops += (result['crops'] as int?) ?? 0;
          totalPests += (result['pests'] as int?) ?? 0;
          totalDiseases += (result['diseases'] as int?) ?? 0;
          totalWeeds += (result['weeds'] as int?) ?? 0;
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar $jsonFile: $e');
        }
      }

      Logger.info('✅ Extração concluída - Culturas: $totalCrops, Pragas: $totalPests, Doenças: $totalDiseases, Plantas daninhas: $totalWeeds');

      return {
        'success': true,
        'total_crops': totalCrops,
        'total_pests': totalPests,
        'total_diseases': totalDiseases,
        'total_weeds': totalWeeds,
      };
    } catch (e) {
      Logger.error('❌ Erro na extração de culturas: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Processa um arquivo JSON específico
  Future<Map<String, int>> _processJsonFile(String jsonFile) async {
    try {
      // Carregar arquivo JSON
      final jsonString = await rootBundle.loadString(jsonFile);
      final jsonData = json.decode(jsonString);

      final cultureName = jsonData['cultura'] as String;
      final scientificName = jsonData['nome_cientifico'] as String;
      final organisms = jsonData['organismos'] as List;

      Logger.info('🔄 Processando cultura: $cultureName');

      // Criar cultura no banco
      final cropId = await _createCrop(cultureName, scientificName);

      int pestCount = 0;
      int diseaseCount = 0;
      int weedCount = 0;

      // Processar organismos
      for (final organism in organisms) {
        final name = organism['nome'] as String;
        final scientificNameOrg = organism['nome_cientifico'] as String;
        final category = organism['categoria'] as String;
        final symptoms = organism['sintomas'] as List<dynamic>;
        final symptomsText = symptoms.join('; ');

        if (category == 'Praga') {
          await _createPest(cropId, name, scientificNameOrg, symptomsText);
          pestCount++;
        } else if (category == 'Doença') {
          await _createDisease(cropId, name, scientificNameOrg, symptomsText);
          diseaseCount++;
        }
      }

      // Criar plantas daninhas comuns para esta cultura
      final cultureKey = _getCultureKey(cultureName);
      if (_commonWeeds.containsKey(cultureKey)) {
        for (final weedData in _commonWeeds[cultureKey]!) {
          await _createWeed(cropId, weedData['name']!, weedData['scientificName']!);
          weedCount++;
        }
      }

      Logger.info('✅ $cultureName - Pragas: $pestCount, Doenças: $diseaseCount, Plantas daninhas: $weedCount');

      return {
        'crops': 1,
        'pests': pestCount,
        'diseases': diseaseCount,
        'weeds': weedCount,
      };
    } catch (e) {
      Logger.error('❌ Erro ao processar arquivo $jsonFile: $e');
      return {'crops': 0, 'pests': 0, 'diseases': 0, 'weeds': 0};
    }
  }

  /// Cria uma cultura no banco
  Future<int> _createCrop(String name, String scientificName) async {
    try {
      final crop = db_crop.Crop(
        id: 0, // Auto-increment
        name: name,
        description: '$scientificName - Cultura para produção agrícola',
        scientificName: scientificName,
        // family: _getFamilyFromScientificName(scientificName),
        // createdAt: DateTime.now(),
        // updatedAt: DateTime.now(),
      );

      final cropId = await _cropDao.insert(crop);
      Logger.info('✅ Cultura criada: $name (ID: $cropId)');
      return cropId;
    } catch (e) {
      Logger.error('❌ Erro ao criar cultura $name: $e');
      rethrow;
    }
  }

  /// Cria uma praga no banco
  Future<int> _createPest(int cropId, String name, String scientificName, String symptoms) async {
    try {
      final pest = Pest(
        // id: null, // Auto-increment
        name: name,
        scientificName: scientificName,
        cropIds: [cropId],
        description: 'Praga da cultura - Sintomas: $symptoms',
        symptoms: symptoms,
        controlMethods: _getDefaultControlMethods().join(', '),
        // lifecycle: 'Ciclo de vida da praga',
        // damageLevel: 'Médio',
        // seasonality: 'Todo o ano',
        // monitoringMethod: 'Observação visual',
        // threshold: '1-2 indivíduos por planta',
        // createdAt: DateTime.now(),
        // updatedAt: DateTime.now(),
      );

      final pestId = await _pestDao.insert(pest.toDbModel());
      Logger.info('✅ Praga criada: $name para cultura ID $cropId');
      return pestId;
    } catch (e) {
      Logger.error('❌ Erro ao criar praga $name: $e');
      rethrow;
    }
  }

  /// Cria uma doença no banco
  Future<int> _createDisease(int cropId, String name, String scientificName, String symptoms) async {
    try {
      final disease = Disease(
        // id: null, // Auto-increment
        name: name,
        scientificName: scientificName,
        cropIds: [cropId],
        description: 'Doença da cultura - Sintomas: $symptoms',
        symptoms: symptoms,
        controlMethods: _getDefaultControlMethods().join(', '),
        // lifecycle: 'Ciclo da doença',
        // damageLevel: 'Médio',
        // seasonality: 'Períodos úmidos',
        // monitoringMethod: 'Observação visual',
        // threshold: 'Primeiros sintomas',
        // createdAt: DateTime.now(),
        // updatedAt: DateTime.now(),
      );

      final diseaseId = await _diseaseDao.insert(disease.toDbModel());
      Logger.info('✅ Doença criada: $name para cultura ID $cropId');
      return diseaseId;
    } catch (e) {
      Logger.error('❌ Erro ao criar doença $name: $e');
      rethrow;
    }
  }

  /// Cria uma planta daninha no banco
  Future<int> _createWeed(int cropId, String name, String scientificName) async {
    try {
      final weed = Weed(
        // id: null, // Auto-increment
        name: name,
        scientificName: scientificName,
        cropIds: [cropId],
        description: 'Planta daninha comum da cultura',
        controlMethods: _getDefaultControlMethods().join(', '),
        // lifecycle: 'Anual/Perene',
        // damageLevel: 'Alto',
        // seasonality: 'Todo o ano',
        // monitoringMethod: 'Observação visual',
        // threshold: '1-2 plantas por m²',
        // createdAt: DateTime.now(),
        // updatedAt: DateTime.now(),
      );

      final weedId = await _weedDao.insert(weed.toDbModel());
      Logger.info('✅ Planta daninha criada: $name para cultura ID $cropId');
      return weedId;
    } catch (e) {
      Logger.error('❌ Erro ao criar planta daninha $name: $e');
      rethrow;
    }
  }

  /// Limpa dados existentes
  Future<void> _clearExistingData() async {
    try {
      Logger.info('🧹 Limpando dados existentes...');
      // await _weedDao.clearAll();
      // await _diseaseDao.clearAll();
      // await _pestDao.clearAll();
      // await _cropDao.clearAll();
      Logger.info('✅ Dados limpos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Converte nome da cultura para chave
  String _getCultureKey(String cultureName) {
    return cultureName.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('õ', 'o');
  }

  /// Obtém família botânica do nome científico
  String _getFamilyFromScientificName(String scientificName) {
    final families = {
      'Glycine max': 'Fabaceae',
      'Zea mays': 'Poaceae',
      'Gossypium hirsutum': 'Malvaceae',
      'Phaseolus vulgaris': 'Fabaceae',
      'Helianthus annuus': 'Asteraceae',
      'Oryza sativa': 'Poaceae',
      'Sorghum bicolor': 'Poaceae',
      'Sesamum indicum': 'Pedaliaceae',
      'Saccharum officinarum': 'Poaceae',
      'Solanum lycopersicum': 'Solanaceae',
      'Triticum aestivum': 'Poaceae',
      'Avena sativa': 'Poaceae',
    };

    return families[scientificName] ?? 'Desconhecida';
  }

  /// Métodos de controle padrão
  List<String> _getDefaultControlMethods() {
    return [
      'Controle químico',
      'Controle biológico',
      'Controle cultural',
      'Controle mecânico',
    ];
  }

  /// Verifica se os dados foram criados corretamente
  Future<Map<String, dynamic>> verifyData() async {
    try {
      final crops = await _cropDao.getAll();
      final pests = await _pestDao.getAll();
      final diseases = await _diseaseDao.getAll();
      final weeds = await _weedDao.getAll();

      return {
        'success': true,
        'crops_count': crops.length,
        'pests_count': pests.length,
        'diseases_count': diseases.length,
        'weeds_count': weeds.length,
        'crops': crops.map((c) => {'id': c.id, 'name': c.name}).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Atualiza uma variedade existente
  Future<void> updateVariety(dynamic variety) async {
    try {
      // final db = await _databaseService.database;
      // await db.update(
      //   'crop_varieties',
      //   {
      //     'name': variety.name,
      //     'company': variety.company,
      //     'description': variety.description,
      //     'cycle_days': variety.cycleDays,
      //     'characteristics': variety.characteristics,
      //     'yield_value': variety.yieldValue,
      //     'updated_at': DateTime.now().toIso8601String(),
      //   },
      //   where: 'id = ?',
      //   whereArgs: [variety.id],
      // );
    } catch (e) {
      throw Exception('Erro ao atualizar variedade: $e');
    }
  }

  /// Exclui uma variedade
  Future<void> deleteVariety(int varietyId) async {
    try {
      // final db = await _databaseService.database;
      // await db.delete(
      //   'crop_varieties',
      //   where: 'id = ?',
      //   whereArgs: [varietyId],
      // );
    } catch (e) {
      throw Exception('Erro ao excluir variedade: $e');
    }
  }
}
