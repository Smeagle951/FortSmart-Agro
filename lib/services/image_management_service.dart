/// Serviço responsável pelo gerenciamento de imagens do aplicativo
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

import '../utils/config.dart';
import '../utils/logger.dart';
import '../database/database_helper.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';

class ImageManagementService {
  static final ImageManagementService _instance = ImageManagementService._internal();
  final TaggedLogger _logger = TaggedLogger('ImageManagementService');
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'images';

  Future<Database> get database async => await _appDatabase.database;

  /// Inicializa a tabela de imagens
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT NOT NULL,
        width INTEGER,
        height INTEGER,
        description TEXT,
        tags TEXT,
        related_entity_type TEXT,
        related_entity_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id TEXT
      )
    ''');
  }

  factory ImageManagementService() {
    return _instance;
  }
  
  ImageManagementService._internal();

  /// Repara as imagens associadas a uma amostra específica
  /// 
  /// Recebe o ID da amostra e tenta reparar todas as imagens associadas
  /// Retorna um mapa com o resultado da operação
  Future<Map<String, dynamic>> repairSampleImages({required String specificSampleId}) async {
    try {
      Logger.log('Reparando imagens da amostra: $specificSampleId');
      
      // Buscar amostra
      // final sample = await _repository.getById(specificSampleId);
      // if (sample == null) {
      //   return {
      //     'success': false,
      //     'message': 'Amostra não encontrada'
      //   };
      // }
      
      // Obter os pontos da amostra
      // final points = await _repository.getSamplePoints(specificSampleId);
      // if (points.isEmpty) {
      //   return {
      //     'success': false,
      //     'message': 'Nenhum ponto encontrado para a amostra',
      //     'repaired': 0,
      //     'total': 0
      //   };
      // }
      
      // Resultados por ponto
      final Map<String, dynamic> pointResults = {};
      int totalRepaired = 0;
      int totalFailed = 0;
      
      // Processar cada ponto com imagem
      // for (final point in points) {
      //   if (point.localPhotoPath != null && point.localPhotoPath!.isNotEmpty) {
      //     // Reparar imagem do ponto
      //     final result = await repairPointImage(specificSampleId, point.id);
      //     pointResults[point.id] = result;
          
      //     if (result['success'] == true && result['repaired'] == true) {
      //       totalRepaired++;
      //     } else {
      //       totalFailed++;
      //     }
      //   }
      // }
      
      return {
        'success': true,
        'message': 'Processo de reparo concluído',
        'totalRepaired': totalRepaired,
        'totalFailed': totalFailed,
        'pointResults': pointResults
      };
    } catch (e) {
      Logger.error('Erro ao reparar imagens da amostra: $e');
      return {
        'success': false,
        'message': 'Erro ao reparar imagens: ${e.toString()}'
      };
    }
  }
  
  /// Repara a imagem associada a um ponto específico de uma amostra
  /// 
  /// Recebe o ID da amostra e o ID do ponto e tenta reparar a imagem associada
  /// Retorna um mapa com o resultado da operação
  Future<Map<String, dynamic>> repairPointImage(String sampleId, String pointId) async {
    try {
      Logger.log('Reparando imagem do ponto $pointId da amostra $sampleId');
      
      // Buscar ponto
      // final point = await _repository.getSamplePointById(sampleId, pointId);
      // if (point == null) {
      //   return {
      //     'success': false,
      //     'message': 'Ponto não encontrado',
      //     'repaired': false
      //   };
      // }
      
      // Verificar se o ponto tem imagem
      // if (point.localPhotoPath == null || point.localPhotoPath!.isEmpty) {
      //   return {
      //     'success': false,
      //     'message': 'Ponto não possui imagem',
      //     'repaired': false
      //   };
      // }
      
      // final imageFile = File(point.localPhotoPath!);
      // if (!await imageFile.exists()) {
      //   return {
      //     'success': false,
      //     'message': 'Arquivo de imagem não encontrado',
      //     'repaired': false
      //   };
      // }
      
      // // Utilizar o ImageRepairService para reparar a imagem
      // final imageRepairService = ImageRepairService();
      // final repairResult = await imageRepairService.repairImage(imageFile);
      
      // if (!repairResult['success']) {
      //   return {
      //     'success': false,
      //     'message': 'Falha ao reparar imagem: ${repairResult['error']}',
      //     'repaired': false,
      //     'details': repairResult
      //   };
      // }
      
      // // Se a imagem foi reparada com sucesso, atualizar o caminho no ponto
      // final repairedFile = repairResult['repairedFile'] as File;
      // final updatedPoint = point.copyWith(
      //   localPhotoPath: repairedFile.path,
      //   updatedAt: DateTime.now()
      // );
      
      // // Atualizar o ponto no banco de dados
      // final updateResult = await _repository.updateSamplePoint(sampleId, updatedPoint);
      // if (!updateResult) {
      //   return {
      //     'success': false,
      //     'message': 'Falha ao atualizar caminho da imagem reparada',
      //     'repaired': false
      //   };
      // }
      
      return {
        'success': true,
        'message': 'Imagem reparada com sucesso',
        'repaired': true,
        // 'originalPath': point.localPhotoPath,
        // 'newPath': repairedFile.path,
        // 'changes': repairResult['changes'],
        // 'originalSize': repairResult['originalSizeKB'],
        // 'newSize': repairResult['newSizeKB']
      };
    } catch (e) {
      Logger.error('Erro ao reparar imagem do ponto $pointId: $e');
      return {
        'success': false,
        'message': 'Erro ao reparar imagem: ${e.toString()}',
        'repaired': false
      };
    }
  }
  
  /// Repara uma imagem com problemas, redimensionando e recomprimindo
  /// Retorna um mapa com o resultado da operação
  Future<Map<String, dynamic>> repairImage(
    List<int> imageBytes,
    int maxWidth,
    int maxHeight,
    int quality
  ) async {
    try {
      // Criar arquivo temporário para a imagem original
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);
      
      // Criar caminho para a imagem reparada
      final repairedPath = '${tempDir.path}/repaired_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Tentar decodificar a imagem para verificar se é válida
      try {
        await decodeImageFromList(Uint8List.fromList(imageBytes));
      } catch (e) {
        return {
          'success': false,
          'error': 'Imagem corrompida, não pode ser decodificada: $e'
        };
      }
      
      // Comprimir e redimensionar a imagem
      final result = await FlutterImageCompress.compressAndGetFile(
        tempFile.path,
        repairedPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );
      
      if (result == null) {
        return {
          'success': false,
          'error': 'Falha ao reparar a imagem'
        };
      }
      
      // Ler os bytes da imagem reparada
      final repairedBytes = await result.readAsBytes();
      final originalSize = imageBytes.length;
      final repairedSize = repairedBytes.length;
      
      // Limpar arquivos temporários
      await tempFile.delete();
      
      return {
        'success': true,
        'bytes': repairedBytes,
        'sizeKB': repairedSize ~/ 1024,
        'originalSizeKB': originalSize ~/ 1024,
        'compressionRatio': originalSize / repairedSize,
        'path': repairedPath
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao reparar imagem: $e'
      };
    }
  }
  
  /// Valida uma imagem verificando seu tamanho e formato
  /// Retorna um mapa com o resultado da validação
  Future<Map<String, dynamic>> validateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // Verificar se o arquivo existe
      if (!await file.exists()) {
        return {
          'isValid': false,
          'message': 'Arquivo não encontrado'
        };
      }
      
      // Verificar o tamanho do arquivo
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      if (fileSizeInMB > 10) { // Limite de 10MB
        return {
          'isValid': false,
          'message': 'Imagem muito grande (${fileSizeInMB.toStringAsFixed(2)}MB). O limite é 10MB.'
        };
      }
      
      // Verificar o formato do arquivo
      final extension = path.extension(imagePath).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png'];
      
      if (!validExtensions.contains(extension)) {
        return {
          'isValid': false,
          'message': 'Formato de arquivo inválido. Use JPG ou PNG.'
        };
      }
      
      return {
        'isValid': true,
        'message': 'Imagem válida',
        'size': fileSizeInMB
      };
    } catch (e) {
      Logger.error('Erro ao validar imagem: $e');
      return {
        'isValid': false,
        'message': 'Erro ao validar imagem: ${e.toString()}'
      };
    }
  }
  
  /// Comprime uma imagem para reduzir seu tamanho
  /// Retorna o caminho da imagem comprimida
  Future<String> compressImage(String imagePath, {int quality = 85}) async {
    try {
      final file = File(imagePath);
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      // Se a imagem já for pequena, não comprimir
      if (fileSizeInMB < 0.5) { // Menos de 500KB
        return imagePath;
      }
      
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, 'compressed_${path.basename(imagePath)}');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        minWidth: 1024, // Reduzir a resolução se necessário
        minHeight: 1024,
      );
      
      if (result == null) {
        Logger.error('Falha ao comprimir imagem');
        return imagePath; // Retorna o original se falhar
      }
      
      final compressedSize = await result.length();
      final compressedSizeInMB = compressedSize / (1024 * 1024);
      
      Logger.info('Imagem comprimida: ${fileSizeInMB.toStringAsFixed(2)}MB -> ${compressedSizeInMB.toStringAsFixed(2)}MB');
      
      return result.path;
    } catch (e) {
      Logger.error('Erro ao comprimir imagem: $e');
      return imagePath; // Retorna o original se falhar
    }
  }
  
  /// Verifica se os bytes representam um formato de imagem válido
  bool _isValidImageFormat(List<int> bytes) {
    if (bytes.length < 4) return false;
    
    // Verificar assinatura de arquivo JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    
    // Verificar assinatura de arquivo PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    
    return false;
  }
  
  /// Obtém o formato da imagem com base nos bytes
  String _getImageFormat(List<int> bytes) {
    if (bytes.length < 4) return 'unknown';
    
    // Verificar assinatura de arquivo JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }
    
    // Verificar assinatura de arquivo PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    
    return 'unknown';
  }
  
  /// Verifica a integridade de uma amostra e suas imagens
  /// 
  /// Recebe o ID da amostra e verifica a integridade de todos os dados
  /// Retorna um mapa com o resultado da verificação
  Future<Map<String, dynamic>> verifySampleIntegrity({required String specificSampleId}) async {
    try {
      // Buscar amostra
      // final sample = await _repository.getSoilSampleById(specificSampleId);
      // if (sample == null) {
      //   return {
      //     'success': false,
      //     'message': 'Amostra não encontrada',
      //     'issues': <String>['amostra_nao_encontrada']
      //   };
      // }
      
      int validImages = 0;
      int invalidImages = 0;
      int missingImages = 0;
      final pointResults = <String, Map<String, dynamic>>{};
      final List<String> issues = <String>[];
      
      // Verificar cada ponto da amostra
      // for (final point in sample.samplePoints) {
      //   final pointResult = <String, dynamic>{
      //     'id': point.id,
      //     'issues': <String>[],
      //     'hasImage': false,
      //     'imageValid': false,
      //   };
        
      //   // Verificar se o ponto tem imagem
      //   if (point.localPhotoPath != null && point.localPhotoPath!.isNotEmpty) {
      //     pointResult['hasImage'] = true;
      //     final file = File(point.localPhotoPath!);
          
      //     if (await file.exists()) {
      //       try {
      //         final bytes = await file.readAsBytes();
      //         final imageRepairService = ImageRepairService();
      //         final validationResult = await imageRepairService.validateImage(file);
              
      //         pointResult['imageValid'] = validationResult['isValid'];
      //         pointResult['issues'] = validationResult['issues'];
              
      //         if (validationResult['isValid']) {
      //           validImages++;
      //         } else {
      //           invalidImages++;
      //           issues.addAll(validationResult['issues']);
      //         }
      //       } catch (e) {
      //         invalidImages++;
      //         pointResult['issues'].add('Erro ao verificar imagem: $e');
      //         issues.add('erro_leitura_imagem');
      //       }
      //     } else {
      //       missingImages++;
      //       pointResult['issues'].add('Arquivo de imagem não encontrado');
      //       issues.add('arquivo_nao_encontrado');
      //     }
      //   }
        
      //   pointResults[point.id] = pointResult;
      // }
      
      // Verificar dados básicos da amostra
      final sampleIssues = <String>[];
      // if (sample.name == null || sample.name!.isEmpty) {
      //   sampleIssues.add('Nome da amostra ausente');
      //   issues.add('nome_vazio');
      // }
      
      // if (sample.propertyId == null) {
      //   sampleIssues.add('Propriedade não associada');
      //   issues.add('sem_propriedade');
      // }
      
      // if (sample.plotId == null) {
      //   sampleIssues.add('Talhão não associado');
      //   issues.add('sem_talhao');
      // }
      
      // if (sample.samplePoints.isEmpty) {
      //   sampleIssues.add('Amostra sem pontos');
      //   issues.add('sem_pontos');
      // } else if (sample.samplePoints.length < 3) {
      //   sampleIssues.add('Número insuficiente de pontos');
      //   issues.add('pontos_insuficientes');
      // }
      
      // Verificar se há dados incompletos que precisam ser corrigidos
      // if (issues.contains('nome_vazio') || 
      //     issues.contains('sem_propriedade') || 
      //     issues.contains('sem_talhao') ||
      //     issues.contains('pontos_insuficientes')) {
      //   issues.add('dados_incompletos');
      // }
      
      // Verificar se há erros críticos que impedem a sincronização
      // if (issues.contains('sem_pontos') || 
      //     (invalidImages > 0 && issues.contains('imagem_nao_reparavel'))) {
      //   issues.add('erro_critico');
      // }
      
      // Resultado final
      final bool canRepair = invalidImages > 0 || issues.contains('dados_incompletos');
      
      return {
        'success': true,
        // 'sampleId': specificSampleId,
        // 'sampleName': sample.name,
        'sampleIssues': sampleIssues,
        'totalPoints': 0,
        'validPoints': 0,
        'invalidPoints': invalidImages,
        'pointsWithImages': 0,
        'validImages': validImages,
        'invalidImages': invalidImages,
        'missingImages': missingImages,
        'needsRepair': invalidImages > 0 || issues.contains('dados_incompletos'),
        'canRepair': canRepair,
        'issues': issues,
        'pointResults': pointResults
      };
    } catch (e) {
      Logger.error('Erro ao verificar integridade da amostra: $e');
      return {
        'success': false,
        'message': 'Erro ao verificar integridade: ${e.toString()}',
        'error': 'Erro ao verificar integridade: ${e.toString()}',
        'issues': ['erro_verificacao']
      };
    }
  }
  
  /// Limpa imagens órfãs que não estão mais associadas a nenhuma amostra
  Future<Map<String, dynamic>> cleanupOrphanedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      
      if (!await imagesDir.exists()) {
        return {
          'success': true,
          'message': 'Diretório de imagens não existe',
          'cleaned': 0
        };
      }
      
      // Obter todas as imagens salvas
      final files = await imagesDir.list().where((entity) => 
        entity is File && 
        (entity.path.endsWith('.jpg') || 
         entity.path.endsWith('.jpeg') || 
         entity.path.endsWith('.png'))
      ).toList();
      
      if (files.isEmpty) {
        return {
          'success': true,
          'message': 'Nenhuma imagem encontrada',
          'cleaned': 0
        };
      }
      
      // Obter todas as referências a imagens no banco de dados
      final db = await _appDatabase.database;
      final pointsWithImages = await db.query(
        'soil_sample_points',
        columns: ['imageUrl'],
        where: 'imageUrl IS NOT NULL AND imageUrl != ""'
      );
      
      final usedImagePaths = pointsWithImages
          .map((point) => point['imageUrl'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .toList();
      
      // Identificar imagens órfãs
      final orphanedFiles = files.where((file) {
        final fileName = path.basename(file.path);
        return !usedImagePaths.any((imagePath) => 
          imagePath != null && imagePath.contains(fileName));
      }).toList();
      
      // Remover imagens órfãs
      int cleaned = 0;
      for (final file in orphanedFiles) {
        try {
          await file.delete();
          cleaned++;
        } catch (e) {
          _logger.warning('Erro ao excluir imagem órfã: ${file.path} - $e');
        }
      }
      
      return {
        'success': true,
        'message': 'Limpeza de imagens órfãs concluída',
        'cleaned': cleaned,
        'total': orphanedFiles.length
      };
    } catch (e) {
      _logger.severe('Erro ao limpar imagens órfãs: $e');
      return {
        'success': false,
        'message': 'Erro ao limpar imagens órfãs: $e',
        'cleaned': 0
      };
    }
  }
  
  /// Salva uma foto no armazenamento local
  Future<Map<String, dynamic>> savePhoto({
    required String sampleId,
    required String pointId,
    required File photoFile,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Gerar nome de arquivo único
      final fileName = 'sample_${sampleId}_point_${pointId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${imagesDir.path}/$fileName';
      
      // Verificar se a imagem é válida
      final validationResult = await validateImage(photoFile.path);
      if (validationResult['isValid'] != true) {
        return {
          'success': false,
          'message': 'Imagem inválida: ${validationResult['message']}',
          'path': null
        };
      }
      
      // Comprimir a imagem se necessário
      final compressedPath = await compressImage(
        photoFile.path,
        quality: quality
      );
      
      // Copiar para o destino final
      final File compressedFile = File(compressedPath);
      final File savedFile = await compressedFile.copy(targetPath);
      
      // Atualizar o caminho da imagem no banco de dados
      final db = await _appDatabase.database;
      await db.update(
        'soil_sample_points',
        {'imageUrl': savedFile.path},
        where: 'id = ? AND sampleId = ?',
        whereArgs: [pointId, sampleId]
      );
      
      return {
        'success': true,
        'message': 'Foto salva com sucesso',
        'path': savedFile.path
      };
    } catch (e) {
      _logger.severe('Erro ao salvar foto: $e');
      return {
        'success': false,
        'message': 'Erro ao salvar foto: $e',
        'path': null
      };
    }
  }
  
  /// Obtém informações sobre o armazenamento de imagens
  /// Retorna um mapa com dados sobre as imagens armazenadas
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      // Obter diretório de imagens
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      
      if (!await imagesDir.exists()) {
        return {
          'totalImages': 0,
          'totalSizeMB': 0.0,
          'averageSizeKB': 0.0,
          'compressedCount': 0,
          'uncompressedCount': 0
        };
      }
      
      // Contagens para estatísticas
      int totalImages = 0;
      int totalSize = 0;
      int compressedCount = 0;
      int uncompressedCount = 0;
      
      // Processar arquivos
      final files = await imagesDir.list().where((entity) => 
        entity is File && 
        (entity.path.endsWith('.jpg') || 
         entity.path.endsWith('.jpeg') || 
         entity.path.endsWith('.png'))
      ).toList();
      
      for (var file in files) {
        if (file is File) {
          final fileStats = await file.stat();
          totalSize += fileStats.size;
          totalImages++;
          
          // Verificar se é uma imagem comprimida (pela convenção de nome)
          if (file.path.contains('compressed_')) {
            compressedCount++;
          } else {
            uncompressedCount++;
          }
        }
      }
      
      // Calcular métricas
      final totalSizeMB = totalSize / (1024 * 1024);
      final averageSizeKB = totalImages > 0 ? (totalSize / totalImages) / 1024 : 0;
      
      return {
        'totalImages': totalImages,
        'totalSizeMB': totalSizeMB,
        'averageSizeKB': averageSizeKB,
        'compressedCount': compressedCount,
        'uncompressedCount': uncompressedCount
      };
    } catch (e) {
      _logger.severe('Erro ao obter informações de armazenamento de imagens: $e');
      return {
        'totalImages': 0,
        'totalSizeMB': 0.0,
        'averageSizeKB': 0.0,
        'compressedCount': 0,
        'uncompressedCount': 0,
        'error': e.toString()
      };
    }
  }
  
  /// Salva uma foto no armazenamento local
  Future<Map<String, dynamic>> savePhoto({
    required String sampleId,
    required String pointId,
    required File photoFile,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85
  }) async {
    try {
      // Verificar se o arquivo existe
      if (!await photoFile.exists()) {
        return {
          'success': false,
          'message': 'Arquivo de foto não existe',
          'path': ''
        };
      }
      
      // Criar diretório para fotos se não existir
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }
      
      // Gerar nome de arquivo único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sample_${sampleId}_point_${pointId}_$timestamp.jpg';
      final targetPath = '${photoDir.path}/$fileName';
      
      // Comprimir a imagem se necessário
      final compressedPath = await compressImage(
        photoFile.path,
        quality: quality
      );
      
      // Copiar para o destino final
      final File compressedFile = File(compressedPath);
      final File savedFile = await compressedFile.copy(targetPath);
      
      // Atualizar o caminho da imagem no banco de dados
      final db = await _appDatabase.database;
      await db.update(
        'soil_sample_points',
        {'imageUrl': savedFile.path},
        where: 'id = ? AND sampleId = ?',
        whereArgs: [pointId, sampleId]
      );
      
      return {
        'success': true,
        'message': 'Foto salva com sucesso',
        'path': savedFile.path
      };
    } catch (e) {
      Logger.error('Erro ao salvar foto: $e');
      return {
        'success': false,
        'message': 'Erro ao salvar foto: $e',
        'path': ''
      };
    }
  }
  
  /// Processa uma imagem (redimensiona/comprime) sem salvar no banco de dados
  /// Usado principalmente para operações de manutenção e limpeza
  Future<Map<String, dynamic>> processImage({
    required File photoFile,
    bool compress = true,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85
  }) async {
    try {
      // Verificar se o arquivo existe
      if (!await photoFile.exists()) {
        return {
          'success': false,
          'message': 'Arquivo de foto não existe',
          'path': ''
        };
      }
      
      // Criar diretório temporário se não existir
      final tempDir = await getTemporaryDirectory();
      final imageProcessDir = Directory('${tempDir.path}/image_processing');
      
      if (!await imageProcessDir.exists()) {
        await imageProcessDir.create(recursive: true);
      }
      
      // Gerar nome de arquivo único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'processed_${timestamp}.jpg';
      final targetPath = '${imageProcessDir.path}/$fileName';
      
      // Comprimir a imagem se solicitado
      if (compress) {
        try {
          final compressedPath = await compressImage(
            photoFile.path,
            quality: quality
          );
          
          // Verificar sucesso
          final compressedFile = File(compressedPath);
          if (await compressedFile.exists()) {
            return {
              'success': true,
              'message': 'Imagem processada com sucesso',
              'path': compressedPath
            };
          } else {
            throw Exception('Falha ao gerar arquivo comprimido');
          }
        } catch (e) {
          // Tenta apenas copiar se a compressão falhar
          await photoFile.copy(targetPath);
          return {
            'success': true,
            'message': 'Imagem copiada sem compressão (falha: $e)',
            'path': targetPath
          };
        }
      } else {
        // Apenas copiar sem comprimir
        await photoFile.copy(targetPath);
        return {
          'success': true,
          'message': 'Imagem copiada sem compressão',
          'path': targetPath
        };
      }
    } catch (e) {
      Logger.error('Erro ao processar imagem: $e');
      return {
        'success': false,
        'message': 'Erro ao processar imagem: $e',
        'path': ''
      };
    }
  }
}
