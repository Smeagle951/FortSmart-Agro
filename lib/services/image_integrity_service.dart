import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:image/image.dart' as img;
import '../services/image_repair_service.dart';
import '../utils/logger.dart';
import '../utils/config.dart';

/// Serviço responsável por verificar e manter a integridade das imagens no banco de dados
class ImageIntegrityService {
  final ImageRepairService _imageRepairService = ImageRepairService();
  final Database _database;
  
  ImageIntegrityService(this._database);
  
  /// Verifica a integridade de todas as imagens associadas a uma amostra
  Future<Map<String, dynamic>> verifySampleImagesIntegrity(String sampleId) async {
    try {
      // Buscar todas as imagens associadas à amostra
      final images = await _getImagesForSample(sampleId);
      
      if (images.isEmpty) {
        return {
          'success': true,
          'message': 'Nenhuma imagem encontrada para a amostra',
          'sampleId': sampleId,
          'imagesCount': 0,
          'validImages': 0,
          'invalidImages': 0,
          'missingImages': 0,
          'issues': [],
        };
      }
      
      int validCount = 0;
      int invalidCount = 0;
      int missingCount = 0;
      final issues = <Map<String, dynamic>>[];
      final validationResults = <String, Map<String, dynamic>>{};
      
      // Verificar cada imagem
      for (final image in images) {
        final imagePath = image['path'] as String;
        final imageId = image['id'] as String;
        final imageFile = File(imagePath);
        
        if (!await imageFile.exists()) {
          missingCount++;
          issues.add({
            'imageId': imageId,
            'path': imagePath,
            'issue': 'missing',
            'message': 'Arquivo de imagem não encontrado',
            'canRepair': false,
          });
          continue;
        }
        
        // Validar a imagem
        final validationResult = await _imageRepairService.validateImage(imageFile);
        validationResults[imageId] = validationResult;
        
        if (validationResult['isValid']) {
          validCount++;
        } else {
          invalidCount++;
          issues.add({
            'imageId': imageId,
            'path': imagePath,
            'issue': 'invalid',
            'message': validationResult['error'],
            'canRepair': validationResult['canRepair'],
            'details': validationResult,
          });
        }
      }
      
      return {
        'success': issues.isEmpty,
        'message': issues.isEmpty 
            ? 'Todas as imagens estão íntegras' 
            : 'Encontrados problemas em algumas imagens',
        'sampleId': sampleId,
        'imagesCount': images.length,
        'validImages': validCount,
        'invalidImages': invalidCount,
        'missingImages': missingCount,
        'issues': issues,
        'validationResults': validationResults,
      };
    } catch (e) {
      Logger.error('Erro ao verificar integridade das imagens da amostra $sampleId: $e');
      return {
        'success': false,
        'message': 'Erro ao verificar integridade das imagens: $e',
        'sampleId': sampleId,
        'error': e.toString(),
      };
    }
  }
  
  /// Repara as imagens com problemas para uma amostra
  Future<Map<String, dynamic>> repairSampleImages(String sampleId) async {
    try {
      // Verificar integridade primeiro
      final integrityResult = await verifySampleImagesIntegrity(sampleId);
      
      if (integrityResult['success']) {
        return {
          'success': true,
          'message': 'Todas as imagens estão íntegras, não é necessário reparo',
          'sampleId': sampleId,
          'repairedCount': 0,
          'failedRepairs': 0,
        };
      }
      
      final issues = integrityResult['issues'] as List<dynamic>;
      int repairedCount = 0;
      int failedRepairs = 0;
      final repairResults = <String, Map<String, dynamic>>{};
      
      // Tentar reparar cada imagem com problemas
      for (final issue in issues) {
        final imageId = issue['imageId'] as String;
        final imagePath = issue['path'] as String;
        final canRepair = issue['canRepair'] as bool;
        
        if (issue['issue'] == 'missing') {
          // Não podemos reparar imagens ausentes
          failedRepairs++;
          repairResults[imageId] = {
            'success': false,
            'message': 'Arquivo não encontrado, impossível reparar',
          };
          continue;
        }
        
        if (!canRepair) {
          // Imagem não pode ser reparada
          failedRepairs++;
          repairResults[imageId] = {
            'success': false,
            'message': 'Imagem não pode ser reparada: ${issue['message']}',
          };
          continue;
        }
        
        // Tentar reparar a imagem
        final imageFile = File(imagePath);
        final repairResult = await _imageRepairService.repairImage(imageFile);
        repairResults[imageId] = repairResult;
        
        if (repairResult['success']) {
          // Atualizar o caminho da imagem no banco de dados se necessário
          final repairedFile = repairResult['repairedFile'] as File;
          if (repairedFile.path != imagePath) {
            await _updateImagePath(imageId, repairedFile.path);
          }
          repairedCount++;
        } else {
          failedRepairs++;
        }
      }
      
      return {
        'success': failedRepairs == 0,
        'message': failedRepairs == 0 
            ? 'Todas as imagens foram reparadas com sucesso' 
            : 'Algumas imagens não puderam ser reparadas',
        'sampleId': sampleId,
        'repairedCount': repairedCount,
        'failedRepairs': failedRepairs,
        'repairResults': repairResults,
      };
    } catch (e) {
      Logger.error('Erro ao reparar imagens da amostra $sampleId: $e');
      return {
        'success': false,
        'message': 'Erro ao reparar imagens: $e',
        'sampleId': sampleId,
        'error': e.toString(),
      };
    }
  }
  
  /// Verifica e limpa imagens órfãs no sistema de arquivos
  Future<Map<String, dynamic>> cleanupOrphanedImages() async {
    try {
      // Obter todas as imagens registradas no banco de dados
      final registeredImages = await _getAllRegisteredImages();
      final registeredPaths = registeredImages.map((img) => img['path'] as String).toSet();
      
      // Listar todos os arquivos no diretório de imagens
      final imagesDir = Directory(Config.imagesPath);
      if (!await imagesDir.exists()) {
        return {
          'success': true,
          'message': 'Diretório de imagens não existe',
          'orphanedCount': 0,
          'deletedCount': 0,
        };
      }
      
      final files = await imagesDir
          .list(recursive: true)
          .where((entity) => entity is File && 
              ['.jpg', '.jpeg', '.png', '.gif'].contains(path.extension(entity.path).toLowerCase()))
          .toList();
      
      // Identificar imagens órfãs
      final orphanedFiles = <File>[];
      for (final entity in files) {
        final file = entity as File;
        if (!registeredPaths.contains(file.path)) {
          // Verificar se o arquivo é mais antigo que o período de retenção
          final stat = await file.stat();
          final fileAge = DateTime.now().difference(stat.modified);
          
          if (fileAge.inDays > Config.orphanedImageRetentionDays) {
            orphanedFiles.add(file);
          }
        }
      }
      
      // Excluir imagens órfãs
      int deletedCount = 0;
      final deletionResults = <String, bool>{};
      
      for (final file in orphanedFiles) {
        try {
          await file.delete();
          deletionResults[file.path] = true;
          deletedCount++;
        } catch (e) {
          Logger.error('Erro ao excluir imagem órfã ${file.path}: $e');
          deletionResults[file.path] = false;
        }
      }
      
      return {
        'success': true,
        'message': 'Limpeza de imagens órfãs concluída',
        'orphanedCount': orphanedFiles.length,
        'deletedCount': deletedCount,
        'deletionResults': deletionResults,
      };
    } catch (e) {
      Logger.error('Erro ao limpar imagens órfãs: $e');
      return {
        'success': false,
        'message': 'Erro ao limpar imagens órfãs: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Verifica referências a imagens inexistentes no banco de dados
  Future<Map<String, dynamic>> verifyImageReferences() async {
    try {
      // Obter todas as imagens registradas no banco de dados
      final registeredImages = await _getAllRegisteredImages();
      
      final missingFiles = <Map<String, dynamic>>[];
      final validFiles = <Map<String, dynamic>>[];
      
      // Verificar cada imagem
      for (final image in registeredImages) {
        final imagePath = image['path'] as String;
        final imageFile = File(imagePath);
        
        if (!await imageFile.exists()) {
          missingFiles.add(image);
        } else {
          validFiles.add(image);
        }
      }
      
      return {
        'success': missingFiles.isEmpty,
        'message': missingFiles.isEmpty 
            ? 'Todas as referências a imagens são válidas' 
            : 'Encontradas referências a imagens inexistentes',
        'totalImages': registeredImages.length,
        'validReferences': validFiles.length,
        'invalidReferences': missingFiles.length,
        'missingFiles': missingFiles,
      };
    } catch (e) {
      Logger.error('Erro ao verificar referências a imagens: $e');
      return {
        'success': false,
        'message': 'Erro ao verificar referências a imagens: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Limpa referências a imagens inexistentes no banco de dados
  Future<Map<String, dynamic>> cleanupInvalidImageReferences() async {
    try {
      // Verificar referências primeiro
      final verificationResult = await verifyImageReferences();
      
      if (verificationResult['success']) {
        return {
          'success': true,
          'message': 'Todas as referências a imagens são válidas, não é necessário limpeza',
          'cleanedCount': 0,
        };
      }
      
      final missingFiles = verificationResult['missingFiles'] as List<dynamic>;
      int cleanedCount = 0;
      final cleanupResults = <String, bool>{};
      
      // Remover cada referência inválida
      for (final image in missingFiles) {
        final imageId = image['id'] as String;
        final tableName = image['table'] as String;
        final columnName = image['column'] as String;
        
        try {
          await _removeImageReference(tableName, columnName, imageId);
          cleanupResults[imageId] = true;
          cleanedCount++;
        } catch (e) {
          Logger.error('Erro ao remover referência à imagem $imageId: $e');
          cleanupResults[imageId] = false;
        }
      }
      
      return {
        'success': true,
        'message': 'Limpeza de referências inválidas concluída',
        'totalInvalid': missingFiles.length,
        'cleanedCount': cleanedCount,
        'cleanupResults': cleanupResults,
      };
    } catch (e) {
      Logger.error('Erro ao limpar referências inválidas a imagens: $e');
      return {
        'success': false,
        'message': 'Erro ao limpar referências inválidas: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Obtém todas as imagens associadas a uma amostra
  Future<List<Map<String, dynamic>>> _getImagesForSample(String sampleId) async {
    // Buscar imagens da amostra
    final sampleImages = await _database.query(
      'sample_images',
      where: 'sample_id = ?',
      whereArgs: [sampleId],
    );
    
    // Buscar imagens dos pontos de monitoramento associados à amostra
    final monitoringPoints = await _database.query(
      'monitoring_points',
      where: 'sample_id = ?',
      whereArgs: [sampleId],
    );
    
    final pointImages = <Map<String, dynamic>>[];
    for (final point in monitoringPoints) {
      final pointId = point['id'] as String;
      final images = await _database.query(
        'point_images',
        where: 'point_id = ?',
        whereArgs: [pointId],
      );
      pointImages.addAll(images);
    }
    
    // Combinar todas as imagens
    final allImages = [
      ...sampleImages.map((img) => {
        ...img,
        'table': 'sample_images',
        'column': 'image_path',
      }),
      ...pointImages.map((img) => {
        ...img,
        'table': 'point_images',
        'column': 'image_path',
      }),
    ];
    
    return allImages;
  }
  
  /// Obtém todas as imagens registradas no banco de dados
  Future<List<Map<String, dynamic>>> _getAllRegisteredImages() async {
    final images = <Map<String, dynamic>>[];
    
    // Buscar imagens de amostras
    final sampleImages = await _database.query('sample_images');
    images.addAll(sampleImages.map((img) => {
      ...img,
      'table': 'sample_images',
      'column': 'image_path',
      'path': img['image_path'],
    }));
    
    // Buscar imagens de pontos
    final pointImages = await _database.query('point_images');
    images.addAll(pointImages.map((img) => {
      ...img,
      'table': 'point_images',
      'column': 'image_path',
      'path': img['image_path'],
    }));
    
    // Buscar imagens de talhões
    final plotImages = await _database.query('plot_images');
    images.addAll(plotImages.map((img) => {
      ...img,
      'table': 'plot_images',
      'column': 'image_path',
      'path': img['image_path'],
    }));
    
    // Buscar imagens de fazendas
    final farmImages = await _database.query('farm_images');
    images.addAll(farmImages.map((img) => {
      ...img,
      'table': 'farm_images',
      'column': 'image_path',
      'path': img['image_path'],
    }));
    
    return images;
  }
  
  /// Atualiza o caminho de uma imagem no banco de dados
  Future<void> _updateImagePath(String imageId, String newPath) async {
    // Primeiro, precisamos descobrir em qual tabela está a imagem
    final tables = ['sample_images', 'point_images', 'plot_images', 'farm_images'];
    
    for (final table in tables) {
      final count = Sqflite.firstIntValue(await _database.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE id = ?',
        [imageId],
      )) ?? 0;
      
      if (count > 0) {
        await _database.update(
          table,
          {'image_path': newPath},
          where: 'id = ?',
          whereArgs: [imageId],
        );
        break;
      }
    }
  }
  
  /// Remove uma referência a uma imagem do banco de dados
  Future<void> _removeImageReference(String tableName, String columnName, String imageId) async {
    // Dependendo da tabela, podemos querer definir o valor como NULL ou excluir o registro
    if (['sample_images', 'point_images', 'plot_images', 'farm_images'].contains(tableName)) {
      // Tabelas de imagens: excluir o registro
      await _database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [imageId],
      );
    } else {
      // Outras tabelas: definir o valor como NULL
      await _database.update(
        tableName,
        {columnName: null},
        where: 'id = ?',
        whereArgs: [imageId],
      );
    }
  }
  
  /// Verifica se a imagem é válida e pode ser processada
  Future<Map<String, dynamic>> validateImage(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        return {
          'isValid': false,
          'error': 'Arquivo vazio',
          'canRepair': false,
        };
      }

      // Verificar se o tamanho está dentro do limite
      final sizeKB = bytes.length / 1024;
      if (sizeKB > Config.maxUploadImageSizeKB) {
        return {
          'isValid': false,
          'error': 'Imagem muito grande (${sizeKB.toStringAsFixed(2)}KB)',
          'canRepair': true,
          'details': {
            'size': sizeKB,
            'maxSize': Config.maxUploadImageSizeKB,
          },
        };
      }

      // Tentar decodificar a imagem
      final decodedImage = await compute(_decodeImage, bytes);
      if (decodedImage == null) {
        return {
          'isValid': false,
          'error': 'Formato de imagem inválido ou corrompido',
          'canRepair': false,
        };
      }

      return {
        'isValid': true,
        'size': sizeKB,
        'width': decodedImage.width,
        'height': decodedImage.height,
        'format': _detectImageFormat(bytes),
      };
    } catch (e) {
      Logger.error('Erro ao validar imagem', e);
      return {
        'isValid': false,
        'error': 'Erro ao validar imagem: $e',
        'canRepair': false,
      };
    }
  }

  /// Detecta o formato da imagem com base nos bytes
  String _detectImageFormat(Uint8List bytes) {
    // JPEG: Começa com FF D8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpeg';
    }
    
    // PNG: Começa com 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    
    // GIF: Começa com GIF8
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'gif';
    }
    
    // WebP: Começa com RIFF....WEBP
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    
    return 'unknown';
  }
  
  /// Decodifica uma imagem a partir de bytes
  static Future<img.Image?> _decodeImage(Uint8List bytes) async {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      Logger.error('Erro ao decodificar imagem', e);
      return null;
    }
  }
}
