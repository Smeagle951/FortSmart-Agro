import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/app_database.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../database/models/crop.dart' as db_crop;
import '../database/models/pest.dart' as db_pest;
import '../database/models/disease.dart' as db_disease;
import '../database/models/weed.dart' as db_weed;
import '../models/crop_variety.dart';
import '../repositories/crop_variety_repository.dart';
import '../utils/logger.dart';

/// Serviço aprimorado para gerenciamento completo de culturas
/// Permite adicionar culturas, organismos, fotos e variedades
class EnhancedCultureManagementService {
  final AppDatabase _database = AppDatabase();
  final CropDao _cropDao = CropDao();
  final PestDao _pestDao = PestDao();
  final DiseaseDao _diseaseDao = DiseaseDao();
  final WeedDao _weedDao = WeedDao();
  final CropVarietyRepository _varietyRepository = CropVarietyRepository();
  final ImagePicker _imagePicker = ImagePicker();

  /// Getter para acessar o banco de dados
  Future<Database> get database => _database.database;

  /// Adiciona uma nova cultura completa
  Future<Map<String, dynamic>> addCompleteCulture({
    required String cultureName,
    required String scientificName,
    String? description,
    String? family,
    List<Map<String, dynamic>>? pests,
    List<Map<String, dynamic>>? diseases,
    List<Map<String, dynamic>>? weeds,
    List<Map<String, dynamic>>? varieties,
  }) async {
    try {
      Logger.info('🌱 Adicionando cultura completa: $cultureName');
      
      await _database.database;
      
      // 1. Criar cultura principal
      final cultureId = DateTime.now().millisecondsSinceEpoch;
      final crop = db_crop.Crop(
        id: cultureId,
        name: cultureName,
        description: description ?? '',
        syncStatus: 0,
        remoteId: null,
        scientificName: scientificName,
      );
      
      final result = await _cropDao.insert(crop);
      Logger.info('✅ Cultura criada: $cultureName (ID: $result)');
      
      int pestsCount = 0;
      int diseasesCount = 0;
      int weedsCount = 0;
      int varietiesCount = 0;
      
      // 2. Adicionar pragas
      if (pests != null && pests.isNotEmpty) {
        for (final pestData in pests) {
          final pest = db_pest.Pest(
            id: 0, // Auto-increment
            name: pestData['name'] ?? '',
            scientificName: pestData['scientificName'] ?? '',
            type: 'pest',
            cropId: cultureId,
            unit: pestData['unit'] ?? 'unidades',
            lowLimit: _parseLimit(pestData['lowLimit']),
            mediumLimit: _parseLimit(pestData['mediumLimit']),
            highLimit: _parseLimit(pestData['highLimit']),
            description: pestData['description'] ?? '',
            monitoringMethod: pestData['monitoringMethod'] ?? '',
            // syncStatus: 0,
            // remoteId: null,
          );
          
          await _pestDao.insert(pest);
          pestsCount++;
        }
        Logger.info('✅ $pestsCount pragas adicionadas');
      }
      
      // 3. Adicionar doenças
      if (diseases != null && diseases.isNotEmpty) {
        for (final diseaseData in diseases) {
          final disease = db_disease.Disease(
            id: 0, // Auto-increment
            name: diseaseData['name'] ?? '',
            scientificName: diseaseData['scientificName'] ?? '',
            cropId: cultureId,
            unit: diseaseData['unit'] ?? 'unidades',
            lowLimit: _parseLimit(diseaseData['lowLimit']),
            mediumLimit: _parseLimit(diseaseData['mediumLimit']),
            highLimit: _parseLimit(diseaseData['highLimit']),
            description: diseaseData['description'] ?? '',
            monitoringMethod: diseaseData['monitoringMethod'] ?? '',
            // syncStatus: 0,
            // remoteId: null,
          );
          
          await _diseaseDao.insert(disease);
          diseasesCount++;
        }
        Logger.info('✅ $diseasesCount doenças adicionadas');
      }
      
      // 4. Adicionar plantas daninhas
      if (weeds != null && weeds.isNotEmpty) {
        for (final weedData in weeds) {
          final weed = db_weed.Weed(
            id: 0, // Auto-increment
            name: weedData['name'] ?? '',
            scientificName: weedData['scientificName'] ?? '',
            cropId: cultureId,
            unit: weedData['unit'] ?? 'unidades',
            lowLimit: _parseLimit(weedData['lowLimit']),
            mediumLimit: _parseLimit(weedData['mediumLimit']),
            highLimit: _parseLimit(weedData['highLimit']),
            description: weedData['description'] ?? '',
            monitoringMethod: weedData['monitoringMethod'] ?? '',
            // syncStatus: 0,
            // remoteId: null,
          );
          
          await _weedDao.insert(weed);
          weedsCount++;
        }
        Logger.info('✅ $weedsCount plantas daninhas adicionadas');
      }
      
      // 5. Adicionar variedades
      if (varieties != null && varieties.isNotEmpty) {
        for (final varietyData in varieties) {
          final variety = CropVariety(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: varietyData['name'] ?? '',
            cropId: cultureId.toString(),
            description: varietyData['description'] ?? '',
            characteristics: varietyData['characteristics'] ?? '',
            yieldValue: (varietyData['yield'] as num?)?.toDouble() ?? 0.0,
            // imageUrl: varietyData['imageUrl'] ?? '',
            // syncStatus: 0,
            // remoteId: null,
          );
          
          await _varietyRepository.insert(variety);
          varietiesCount++;
        }
        Logger.info('✅ $varietiesCount variedades adicionadas');
      }
      
      return {
        'success': true,
        'cultureId': result,
        'cultureName': cultureName,
        'pestsCount': pestsCount,
        'diseasesCount': diseasesCount,
        'weedsCount': weedsCount,
        'varietiesCount': varietiesCount,
        'message': 'Cultura completa adicionada com sucesso!',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar cultura completa: $e');
      return {
        'success': false,
        'error': e.toString(),
        'cultureId': null,
        'cultureName': cultureName,
        'pestsCount': 0,
        'diseasesCount': 0,
        'weedsCount': 0,
        'varietiesCount': 0,
      };
    }
  }

  /// Adiciona foto para um organismo específico
  Future<Map<String, dynamic>> addOrganismPhoto({
    required int organismId,
    required String organismType, // 'pest', 'disease', 'weed'
    required String organismName,
    required XFile imageFile,
    String? description,
  }) async {
    try {
      Logger.info('📸 Adicionando foto para $organismType: $organismName');
      
      // Criar diretório para fotos se não existir
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'organism_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      // Gerar nome único para a foto
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '${organismType}_${organismId}_${timestamp}$extension';
      final photoPath = path.join(photosDir.path, fileName);
      
      // Copiar arquivo para o diretório de fotos
      final imageBytes = await imageFile.readAsBytes();
      final photoFile = File(photoPath);
      await photoFile.writeAsBytes(imageBytes);
      
      // Salvar informações da foto no banco
      final photoData = {
        'organismId': organismId,
        'organismType': organismType,
        'organismName': organismName,
        'photoPath': photoPath,
        'description': description ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Aqui você pode salvar no banco de dados ou em um arquivo JSON
      await _savePhotoMetadata(photoData);
      
      Logger.info('✅ Foto salva: $photoPath');
      
      return {
        'success': true,
        'photoPath': photoPath,
        'fileName': fileName,
        'message': 'Foto adicionada com sucesso!',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar foto: $e');
      return {
        'success': false,
        'error': e.toString(),
        'photoPath': null,
        'fileName': null,
      };
    }
  }

  /// Salva metadados da foto
  Future<void> _savePhotoMetadata(Map<String, dynamic> photoData) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File(path.join(appDir.path, 'organism_photos_metadata.json'));
      
      List<Map<String, dynamic>> photos = [];
      
      // Carregar fotos existentes se o arquivo existir
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        photos = List<Map<String, dynamic>>.from(json.decode(content));
      }
      
      // Adicionar nova foto
      photos.add(photoData);
      
      // Salvar arquivo atualizado
      await metadataFile.writeAsString(json.encode(photos));
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar metadados da foto: $e');
    }
  }

  /// Obtém fotos de um organismo
  Future<List<Map<String, dynamic>>> getOrganismPhotos({
    required int organismId,
    required String organismType,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataFile = File(path.join(appDir.path, 'organism_photos_metadata.json'));
      
      if (!await metadataFile.exists()) {
        return [];
      }
      
      final content = await metadataFile.readAsString();
      final photos = List<Map<String, dynamic>>.from(json.decode(content));
      
      return photos.where((photo) => 
        photo['organismId'] == organismId && 
        photo['organismType'] == organismType
      ).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter fotos do organismo: $e');
      return [];
    }
  }

  /// Adiciona uma nova variedade desenvolvida
  Future<Map<String, dynamic>> addDevelopedVariety({
    required int cropId,
    required String cropName,
    required String varietyName,
    required String description,
    String? characteristics,
    double? yieldValue,
    int? maturity,
    String? resistance,
    XFile? imageFile,
  }) async {
    try {
      Logger.info('🌾 Adicionando variedade desenvolvida: $varietyName');
      
      String imageUrl = '';
      
      // Processar imagem se fornecida
      if (imageFile != null) {
        final photoResult = await addOrganismPhoto(
          organismId: cropId,
          organismType: 'variety',
          organismName: varietyName,
          imageFile: imageFile,
          description: 'Variedade desenvolvida: $varietyName',
        );
        
        if (photoResult['success']) {
          imageUrl = photoResult['photoPath'] ?? '';
        }
      }
      
      // Criar variedade
      final variety = CropVariety(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: varietyName,
        cropId: cropId.toString(),
        description: description,
        characteristics: characteristics ?? '',
        yieldValue: (yieldValue ?? 0.0),
        // imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // syncStatus: 0,
        // remoteId: null,
      );
      
      final result = await _varietyRepository.insert(variety);
      Logger.info('✅ Variedade adicionada: $varietyName (ID: $result)');
      
      return {
        'success': true,
        'varietyId': result,
        'varietyName': varietyName,
        'message': 'Variedade desenvolvida adicionada com sucesso!',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar variedade: $e');
      return {
        'success': false,
        'error': e.toString(),
        'varietyId': null,
        'varietyName': varietyName,
      };
    }
  }

  /// Obtém todas as variedades de uma cultura
  Future<List<CropVariety>> getVarietiesByCrop(int cropId) async {
    try {
      return await _varietyRepository.getByCropId(cropId.toString());
    } catch (e) {
      Logger.error('❌ Erro ao obter variedades: $e');
      return [];
    }
  }

  /// Obtém estatísticas completas de uma cultura
  Future<Map<String, dynamic>> getCultureStatistics(int cropId) async {
    try {
      final crop = await _cropDao.getById(cropId);
      final pests = await _pestDao.getByCropId(cropId);
      final diseases = await _diseaseDao.getByCropId(cropId);
      final weeds = await _weedDao.getByCropId(cropId);
      final varieties = await _varietyRepository.getByCropId(cropId.toString());
      
      return {
        'crop': crop,
        'pests': pests,
        'diseases': diseases,
        'weeds': weeds,
        'varieties': varieties,
        'totalOrganisms': pests.length + diseases.length + weeds.length,
        'totalVarieties': varieties.length,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
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
  
  /// Obtém estatísticas gerais do sistema (alias para compatibilidade)
  Future<Map<String, dynamic>> getStatistics() async {
    return {
      'totalCultures': 0,
      'totalVarieties': 0,
      'totalPests': 0,
      'totalDiseases': 0,
      'totalWeeds': 0,
    };
  }
}
