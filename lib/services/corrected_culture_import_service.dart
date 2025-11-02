import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../models/crop.dart' as app_crop;
import '../database/models/crop.dart' as db_crop;
import '../database/models/pest.dart' as db_pest;
import '../database/models/disease.dart' as db_disease;
import '../database/models/weed.dart' as db_weed;
import '../models/pest.dart';
import '../models/disease.dart';
import '../models/weed.dart';
import '../models/crop_variety.dart';
import '../repositories/crop_variety_repository.dart';
import '../utils/logger.dart';

/// Serviço corrigido para importar culturas dos arquivos JSON em lib/data/
/// Carrega TODAS as culturas sem limitações
class CorrectedCultureImportService {
  final AppDatabase _database = AppDatabase();
  final CropDao _cropDao = CropDao();
  final PestDao _pestDao = PestDao();
  final DiseaseDao _diseaseDao = DiseaseDao();
  final WeedDao _weedDao = WeedDao();
  final CropVarietyRepository _varietyRepository = CropVarietyRepository();

  /// Getter para acessar o banco de dados
  Future<Database> get database => _database.database;

  /// Carrega TODAS as culturas dos arquivos JSON em lib/data/
  Future<Map<String, dynamic>> loadAllCulturesFromLibData() async {
    try {
      Logger.info('🌱 Iniciando carregamento de TODAS as culturas dos JSONs em lib/data/...');
      
      await _database.database;
      
      // Lista de arquivos JSON de culturas em lib/data/
      final cultureFiles = [
        'organismos_soja.json',
        'organismos_milho.json', 
        'organismos_algodao.json',
        'organismos_feijao.json',
        'organismos_girassol.json',
        'organismos_arroz.json',
        'organismos_sorgo.json',
        'organismos_trigo.json',
        'organismos_aveia.json',
        'organismos_gergelim.json',
        'organismos_cana_acucar.json',
        'organismos_tomate.json',
      ];
      
      int totalCultures = 0;
      int totalPests = 0;
      int totalDiseases = 0;
      int totalWeeds = 0;
      
      // Limpar dados existentes para recriar tudo
      Logger.info('🗑️ Limpando dados existentes...');
      await _clearAllData();
      
      // Carregar cada arquivo JSON
      for (final fileName in cultureFiles) {
        try {
          Logger.info('📄 Carregando arquivo: $fileName');
          final result = await _loadCultureFromLibDataJSON(fileName);
          
          totalCultures += result['cultures_count'] ?? 0;
          totalPests += result['pests_count'] ?? 0;
          totalDiseases += result['diseases_count'] ?? 0;
          totalWeeds += result['weeds_count'] ?? 0;
          
          Logger.info('✅ $fileName carregado: ${result['cultures_count']} culturas, ${result['pests_count']} pragas, ${result['diseases_count']} doenças, ${result['weeds_count']} plantas daninhas');
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar $fileName: $e');
        }
      }
      
      Logger.info('🎉 CARREGAMENTO COMPLETO!');
      Logger.info('📊 Total final:');
      Logger.info('   - Culturas: $totalCultures');
      Logger.info('   - Pragas: $totalPests');
      Logger.info('   - Doenças: $totalDiseases');
      Logger.info('   - Plantas daninhas: $totalWeeds');
      
      return {
        'success': true,
        'total_cultures': totalCultures,
        'total_pests': totalPests,
        'total_diseases': totalDiseases,
        'total_weeds': totalWeeds,
        'message': 'Todas as culturas carregadas com sucesso!',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas dos JSONs: $e');
      return {
        'success': false,
        'error': e.toString(),
        'total_cultures': 0,
        'total_pests': 0,
        'total_diseases': 0,
        'total_weeds': 0,
      };
    }
  }

  /// Carrega uma cultura específica de um arquivo JSON em lib/data/
  Future<Map<String, dynamic>> _loadCultureFromLibDataJSON(String fileName) async {
    try {
      // Carregar arquivo JSON de lib/data/
      final jsonString = await rootBundle.loadString('lib/data/$fileName');
      final jsonData = json.decode(jsonString);
      
      final cultura = jsonData['cultura'];
      final nomeCientifico = jsonData['nome_cientifico'];
      final organismos = jsonData['organismos'] ?? [];
      
      if (cultura == null) {
        throw Exception('Dados de cultura não encontrados no arquivo $fileName');
      }
      
      // Criar cultura
      final cultureId = DateTime.now().millisecondsSinceEpoch;
      final crop = db_crop.Crop(
        id: cultureId,
        name: cultura,
        scientificName: nomeCientifico ?? '',
        family: '',
        description: 'Cultura carregada do arquivo $fileName',
        imageUrl: '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
        remoteId: null,
        isDefault: true,
      );
      
      // Inserir cultura
      final result = await _cropDao.insert(crop);
      Logger.info('✅ Cultura inserida: ${crop.name} (ID: $result)');
      
      int pestsCount = 0;
      int diseasesCount = 0;
      int weedsCount = 0;
      
      // Processar organismos
      for (final organismo in organismos) {
        try {
          final tipo = organismo['tipo']?.toString().toUpperCase() ?? '';
          final categoria = organismo['categoria']?.toString() ?? '';
          
          // Determinar se é praga, doença ou planta daninha
          if (tipo == 'PRAGA' || categoria.toLowerCase().contains('praga')) {
            final pest = db_pest.Pest(
              id: 0, // Auto-increment
              name: organismo['nome'] ?? '',
              scientificName: organismo['nome_cientifico'] ?? '',
              type: 'pest',
              cropId: result,
              cropName: crop.name,
              unit: organismo['unidade'] ?? 'unidades',
              lowLimit: _parseLimit(organismo['limiar_baixo']),
              mediumLimit: _parseLimit(organismo['limiar_medio']),
              highLimit: _parseLimit(organismo['limiar_alto']),
              description: organismo['dano_economico'] ?? '',
              monitoringMethod: organismo['metodo_monitoramento'] ?? '',
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
              syncStatus: 0,
              remoteId: null,
            );
            
            await _pestDao.insert(pest);
            pestsCount++;
            
          } else if (tipo == 'DOENÇA' || categoria.toLowerCase().contains('doença') || categoria.toLowerCase().contains('doenca')) {
            final disease = db_disease.Disease(
              id: 0, // Auto-increment
              name: organismo['nome'] ?? '',
              scientificName: organismo['nome_cientifico'] ?? '',
              type: 'disease',
              cropId: result,
              cropName: crop.name,
              unit: organismo['unidade'] ?? 'unidades',
              lowLimit: _parseLimit(organismo['limiar_baixo']),
              mediumLimit: _parseLimit(organismo['limiar_medio']),
              highLimit: _parseLimit(organismo['limiar_alto']),
              description: organismo['dano_economico'] ?? '',
              monitoringMethod: organismo['metodo_monitoramento'] ?? '',
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
              syncStatus: 0,
              remoteId: null,
            );
            
            await _diseaseDao.insert(disease);
            diseasesCount++;
            
          } else if (tipo == 'PLANTA DANINHA' || categoria.toLowerCase().contains('daninha') || categoria.toLowerCase().contains('invasora')) {
            final weed = db_weed.Weed(
              id: 0, // Auto-increment
              name: organismo['nome'] ?? '',
              scientificName: organismo['nome_cientifico'] ?? '',
              type: 'weed',
              cropId: result,
              cropName: crop.name,
              unit: organismo['unidade'] ?? 'unidades',
              lowLimit: _parseLimit(organismo['limiar_baixo']),
              mediumLimit: _parseLimit(organismo['limiar_medio']),
              highLimit: _parseLimit(organismo['limiar_alto']),
              description: organismo['dano_economico'] ?? '',
              monitoringMethod: organismo['metodo_monitoramento'] ?? '',
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
              syncStatus: 0,
              remoteId: null,
            );
            
            await _weedDao.insert(weed);
            weedsCount++;
          }
        } catch (e) {
          Logger.warning('⚠️ Erro ao processar organismo ${organismo['nome']}: $e');
        }
      }
      
      return {
        'success': true,
        'cultures_count': 1,
        'pests_count': pestsCount,
        'diseases_count': diseasesCount,
        'weeds_count': weedsCount,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar cultura de $fileName: $e');
      return {
        'success': false,
        'error': e.toString(),
        'cultures_count': 0,
        'pests_count': 0,
        'diseases_count': 0,
        'weeds_count': 0,
      };
    }
  }

  /// Converte limite para número
  double _parseLimit(dynamic limit) {
    if (limit == null) return 0.0;
    if (limit is num) return limit.toDouble();
    if (limit is String) {
      return double.tryParse(limit) ?? 0.0;
    }
    return 0.0;
  }

  /// Limpa todos os dados existentes
  Future<void> _clearAllData() async {
    try {
      final db = await _database.database;
      
      // Limpar todas as tabelas relacionadas
      await db.delete('weeds');
      await db.delete('diseases');
      await db.delete('pests');
      await db.delete('crops');
      
      Logger.info('✅ Dados existentes limpos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
    }
  }

  /// Obtém todas as culturas (sem limitação)
  Future<List<dynamic>> getAllCrops() async {
    try {
      Logger.info('📋 Carregando TODAS as culturas...');
      
      final crops = await _cropDao.getAll();
      Logger.info('✅ ${crops.length} culturas carregadas');
      
      return crops.map((crop) => {
        'id': crop.id,
        'name': crop.name,
        'scientificName': crop.scientificName,
        'description': crop.description,
        'family': crop.family,
        'imageUrl': crop.imageUrl,
        'createdAt': crop.createdAt,
        'updatedAt': crop.updatedAt,
        'isDefault': crop.isDefault,
      }).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      return [];
    }
  }

  /// Adiciona uma nova cultura (sem limitações)
  Future<int> addCrop(String name, {String? description, int? id}) async {
    try {
      Logger.info('➕ Adicionando nova cultura: $name');
      
      // Gerar ID se não fornecido
      final cropId = id ?? DateTime.now().millisecondsSinceEpoch;
      
      final crop = db_crop.Crop(
        id: cropId,
        name: name,
        scientificName: '',
        family: '',
        description: description ?? '',
        imageUrl: '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
        remoteId: null,
        isDefault: false,
      );
      
      final result = await _cropDao.insert(crop);
      Logger.info('✅ Cultura adicionada: $name (ID: $result)');
      
      return result;
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar cultura: $e');
      return -1;
    }
  }

  /// Obtém estatísticas completas
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final crops = await _cropDao.getAll();
      final pests = await _pestDao.getAll();
      final diseases = await _diseaseDao.getAll();
      final weeds = await _weedDao.getAll();
      
      return {
        'total_cultures': crops.length,
        'total_pests': pests.length,
        'total_diseases': diseases.length,
        'total_weeds': weeds.length,
        'cultures': crops.map((c) => {'id': c.id, 'name': c.name}).toList(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {
        'total_cultures': 0,
        'total_pests': 0,
        'total_diseases': 0,
        'total_weeds': 0,
        'cultures': [],
      };
    }
  }
}
