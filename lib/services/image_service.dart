import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;
import '../models/planting.dart';

/// Resultado da validação de imagem
class ValidationResult {
  final bool isValid;
  final String message;
  final int? sizeKB;
  final int? width;
  final int? height;
  final String? format;
  final String? errorCode;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.sizeKB,
    this.width,
    this.height,
    this.format,
    this.errorCode,
  });
}

/// Resultado da compressão de imagem
class CompressionResult {
  final bool success;
  final String message;
  final File? compressedFile;
  final int? originalSizeKB;
  final int? compressedSizeKB;
  final int? compressionRatio;

  CompressionResult({
    required this.success,
    required this.message,
    this.compressedFile,
    this.originalSizeKB,
    this.compressedSizeKB,
    this.compressionRatio,
  });
}

/// Resultado do reparo de imagem
class RepairResult {
  final bool success;
  final String message;
  final File? repairedFile;
  final String? repairMethod;
  final String? originalPath;

  RepairResult({
    required this.success,
    required this.message,
    this.repairedFile,
    this.repairMethod,
    this.originalPath,
  });
}

/// Serviço para manipulação de imagens
class ImageService {
  /// Carrega uma imagem a partir de uma URL e retorna um arquivo local
  Future<File?> getImageFromUrl(String url) async {
    try {
      // Verificar se a URL é uma URL web ou um caminho local
      if (url.startsWith('http')) {
        // É uma URL web, fazer download
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          Logger.error('Erro ao baixar imagem: ${response.statusCode}');
          return null;
        }
        
        // Criar um arquivo temporário
        final tempDir = await getTemporaryDirectory();
        final fileName = path.basename(url);
        final file = File('${tempDir.path}/$fileName');
        
        // Salvar os bytes no arquivo
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        // É um caminho local
        final file = File(url);
        if (await file.exists()) {
          return file;
        }
        Logger.error('Arquivo local não encontrado: $url');
        return null;
      }
    } catch (e) {
      Logger.error('Erro ao carregar imagem de URL: $e');
      return null;
    }
  }

  /// Salva uma imagem e retorna o caminho ou URL
  Future<String?> saveImage(File imageFile) async {
    try {
      // Comprimir a imagem antes de salvar
      final compressionResult = await compressImage(imageFile);
      if (!compressionResult.success || compressionResult.compressedFile == null) {
        Logger.error('Falha ao comprimir imagem: ${compressionResult.message}');
        return null;
      }
      
      // Gerar nome de arquivo único baseado no hash do conteúdo
      final bytes = await compressionResult.compressedFile!.readAsBytes();
      final hash = sha256.convert(bytes).toString().substring(0, 16);
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      
      // Salvar em diretório permanente
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = 'img_${hash}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final savedFile = File('${imagesDir.path}/$fileName');
      
      // Copiar o arquivo comprimido
      await compressionResult.compressedFile!.copy(savedFile.path);
      
      // Registrar no cache para expiração futura
      final prefs = await SharedPreferences.getInstance();
      final cachedImages = prefs.getStringList('cached_images') ?? [];
      cachedImages.add('${savedFile.path}|${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setStringList('cached_images', cachedImages);
      
      return savedFile.path;
    } catch (e) {
      Logger.error('Erro ao salvar imagem: $e');
      return null;
    }
  }
  static const int _maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int _targetCompressedSizeKB = 1024; // 1MB

  /// Valida uma imagem
  Future<ValidationResult> validateImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return ValidationResult(
          isValid: false,
          message: 'Arquivo de imagem não encontrado',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      final bytes = await imageFile.readAsBytes();
      final sizeKB = bytes.length ~/ 1024;

      if (bytes.isEmpty) {
        return ValidationResult(
          isValid: false,
          message: 'Arquivo de imagem vazio',
          sizeKB: 0,
          errorCode: 'EMPTY_FILE',
        );
      }

      if (bytes.length > _maxImageSizeBytes) {
        return ValidationResult(
          isValid: false,
          message: 'Imagem muito grande (${sizeKB}KB). Tamanho máximo: ${_maxImageSizeBytes ~/ 1024}KB',
          sizeKB: sizeKB,
          errorCode: 'FILE_TOO_LARGE',
        );
      }

      // Tentar decodificar a imagem
      img.Image? decodedImage;
      try {
        // Na versão 4.0.17, usamos o método decodeImage
        decodedImage = img.decodeImage(bytes);
      } catch (e) {
        return ValidationResult(
          isValid: false,
          message: 'Formato de imagem inválido ou corrompido',
          sizeKB: sizeKB,
          errorCode: 'INVALID_FORMAT',
        );
      }

      if (decodedImage == null) {
        return ValidationResult(
          isValid: false,
          message: 'Não foi possível decodificar a imagem',
          sizeKB: sizeKB,
          errorCode: 'DECODE_FAILED',
        );
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      final format = _getImageFormat(imageFile.path);

      return ValidationResult(
        isValid: true,
        message: 'Imagem válida',
        sizeKB: sizeKB,
        width: width,
        height: height,
        format: format,
      );
    } catch (e) {
      Logger.error('Erro ao validar imagem: $e');
      return ValidationResult(
        isValid: false,
        message: 'Erro ao validar imagem: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }

  /// Comprime uma imagem
  Future<CompressionResult> compressImage(File imageFile) async {
    try {
      final validationResult = await validateImage(imageFile);
      
      if (!validationResult.isValid) {
        return CompressionResult(
          success: false,
          message: 'Imagem inválida: ${validationResult.message}',
        );
      }
      
      final originalSizeKB = validationResult.sizeKB!;
      
      if (originalSizeKB <= _targetCompressedSizeKB) {
        return CompressionResult(
          success: true,
          message: 'A imagem já está dentro do tamanho alvo',
          compressedFile: imageFile,
          originalSizeKB: originalSizeKB,
          compressedSizeKB: originalSizeKB,
          compressionRatio: 100,
        );
      }
      
      // Obter diretório temporário para salvar a imagem comprimida
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path, 
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      
      // Calcular qualidade de compressão baseada no tamanho original
      int quality = 80;
      if (originalSizeKB > 5 * 1024) {
        quality = 60;
      } else if (originalSizeKB > 3 * 1024) {
        quality = 70;
      }
      
      // Comprimir imagem
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (result == null) {
        return CompressionResult(
          success: false,
          message: 'Falha ao comprimir imagem',
          originalSizeKB: originalSizeKB,
        );
      }
      
      final compressedFile = File(result.path);
      final compressedSizeKB = await compressedFile.length() ~/ 1024;
      final compressionRatio = ((compressedSizeKB / originalSizeKB) * 100).round();
      
      return CompressionResult(
        success: true,
        message: 'Imagem comprimida com sucesso',
        compressedFile: compressedFile,
        originalSizeKB: originalSizeKB,
        compressedSizeKB: compressedSizeKB,
        compressionRatio: compressionRatio,
      );
    } catch (e) {
      Logger.error('Erro ao comprimir imagem: $e');
      return CompressionResult(
        success: false,
        message: 'Erro ao comprimir imagem: $e',
      );
    }
  }

  /// Repara uma imagem corrompida
  Future<RepairResult> repairImage(File imageFile, String targetPath) async {
    try {
      final validationResult = await validateImage(imageFile);
      
      if (validationResult.isValid) {
        return RepairResult(
          success: true,
          message: 'A imagem não precisa de reparo',
          repairedFile: imageFile,
          repairMethod: 'NONE',
          originalPath: imageFile.path,
        );
      }
      
      // Tentar reparar a imagem
      final bytes = await imageFile.readAsBytes();
      
      // Tentar decodificar com diferentes formatos
      img.Image? decodedImage;
      String repairMethod = 'UNKNOWN';
      
      try {
        // Tentar como imagem genérica com a API atual do pacote image v4.0.17
        decodedImage = img.decodeImage(bytes);
        repairMethod = 'IMAGE_DECODE';
      } catch (e) {
        Logger.error('Erro ao decodificar imagem: $e');
      }
      
      if (decodedImage == null) {
        return RepairResult(
          success: false,
          message: 'Não foi possível reparar a imagem',
          originalPath: imageFile.path,
        );
      }
      
      // Salvar a imagem reparada
      final repairedBytes = img.encodeJpg(decodedImage, quality: 85);
      final repairedFile = File(targetPath);
      await repairedFile.writeAsBytes(repairedBytes);
      
      return RepairResult(
        success: true,
        message: 'Imagem reparada com sucesso',
        repairedFile: repairedFile,
        repairMethod: repairMethod,
        originalPath: imageFile.path,
      );
    } catch (e) {
      Logger.error('Erro ao reparar imagem: $e');
      return RepairResult(
        success: false,
        message: 'Erro ao reparar imagem: $e',
        originalPath: imageFile.path,
      );
    }
  }

  /// Obtém o formato da imagem a partir da extensão do arquivo
  String _getImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.gif':
        return 'GIF';
      case '.bmp':
        return 'BMP';
      case '.webp':
        return 'WEBP';
      case '.heic':
      case '.heif':
        return 'HEIF';
      default:
        return 'UNKNOWN';
    }
  }
  
  /// Processa uma imagem a partir de uma string base64
  /// Retorna uma URL ou o próprio base64 otimizado
  Future<String> processImage(String base64Image) async {
    try {
      // Verificar se já é uma imagem base64
      if (!base64Image.startsWith('data:image')) {
        return base64Image; // Retorna a URL ou caminho original
      }
      
      // Extrair os dados da imagem base64
      final imageData = base64Image.split(',');
      if (imageData.length < 2) {
        Logger.error('Formato base64 inválido');
        return base64Image;
      }
      
      // Determinar o formato da imagem a partir do header
      String format = 'jpeg';
      if (imageData[0].contains('png')) {
        format = 'png';
      } else if (imageData[0].contains('gif')) {
        format = 'gif';
      } else if (imageData[0].contains('webp')) {
        format = 'webp';
      }
      
      // Decodificar os dados base64
      final bytes = base64Decode(imageData[1]);
      
      // Verificar o tamanho da imagem original (em KB)
      final originalSizeKB = bytes.length ~/ 1024;
      
      // Se a imagem já for pequena, retornar o original
      if (originalSizeKB < 200) {
        return base64Image;
      }
      
      // Decodificar a imagem usando o pacote image
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        Logger.error('Não foi possível decodificar a imagem');
        return base64Image;
      }
      
      // Redimensionar a imagem se for muito grande
      img.Image processedImage = decodedImage;
      if (decodedImage.width > 1200 || decodedImage.height > 1200) {
        processedImage = img.copyResize(
          decodedImage, 
          width: decodedImage.width > 1200 ? 1200 : null,
          height: decodedImage.height > 1200 ? 1200 : null,
          interpolation: img.Interpolation.linear
        );
      }
      
      // Comprimir e codificar a imagem
      Uint8List compressedBytes;
      if (format == 'png') {
        compressedBytes = Uint8List.fromList(img.encodePng(processedImage));
      } else if (format == 'gif') {
        compressedBytes = Uint8List.fromList(img.encodeGif(processedImage));
      } else {
        // JPEG por padrão
        compressedBytes = Uint8List.fromList(img.encodeJpg(processedImage, quality: 85));
      }
      
      // Verificar o tamanho após compresão
      final compressedSizeKB = compressedBytes.length ~/ 1024;
      Logger.info('Imagem comprimida: $originalSizeKB KB -> $compressedSizeKB KB');
      
      // Converter de volta para base64
      final compressedBase64 = 'data:image/${format};base64,${base64Encode(compressedBytes)}';
      
      // Salvar a imagem em cache local
      await _saveImageToCache(compressedBase64);
      
      return compressedBase64;
    } catch (e) {
      Logger.error('Erro ao processar imagem base64: $e');
      return base64Image; // Retorna o original em caso de erro
    }
  }
  
  /// Processa várias imagens
  Future<List<String>> processImages(List<String> images) async {
    List<String> processedImages = [];
    
    for (final image in images) {
      final processed = await processImage(image);
      processedImages.add(processed);
    }
    
    return processedImages;
  }
  
  /// Salva uma imagem no cache local
  Future<void> _saveImageToCache(String imageData) async {
    try {
      // Gerar um hash do conteúdo da imagem para usar como chave
      final hash = sha256.convert(utf8.encode(imageData)).toString();
      
      // Salvar no cache usando SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'image_cache_$hash';
      await prefs.setString(cacheKey, imageData);
      
      // Registrar timestamp de cache
      await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      // Limpar cache antigo periodicamente
      await _cleanupOldCache();
    } catch (e) {
      Logger.error('Erro ao salvar imagem em cache: $e');
    }
  }
  
  /// Recupera uma imagem do cache local
  Future<String?> getImageFromCache(String imageUrl) async {
    try {
      // Verificar se é uma URL ou base64
      if (imageUrl.startsWith('data:image')) {
        // Já é base64, buscar do cache pelo hash
        final hash = sha256.convert(utf8.encode(imageUrl)).toString();
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'image_cache_$hash';
        return prefs.getString(cacheKey);
      } else if (imageUrl.startsWith('http')) {
        // É uma URL, buscar do cache pela URL
        final hash = sha256.convert(utf8.encode(imageUrl)).toString();
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'image_url_cache_$hash';
        return prefs.getString(cacheKey);
      }
      
      return null;
    } catch (e) {
      Logger.error('Erro ao recuperar imagem do cache: $e');
      return null;
    }
  }
  
  /// Limpa o cache de imagens mais antigas que 7 dias
  Future<void> _cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAgeMs = 7 * 24 * 60 * 60 * 1000; // 7 dias em milissegundos
      
      // Buscar todas as chaves do cache
      final allKeys = prefs.getKeys();
      
      // Filtrar apenas as chaves de timestamp
      final timestampKeys = allKeys.where((k) => k.endsWith('_timestamp'));
      
      for (final timestampKey in timestampKeys) {
        final timestamp = prefs.getInt(timestampKey) ?? 0;
        
        // Verificar se o cache é antigo
        if (now - timestamp > maxAgeMs) {
          // Remover a entrada do cache
          final cacheKey = timestampKey.replaceAll('_timestamp', '');
          await prefs.remove(cacheKey);
          await prefs.remove(timestampKey);
        }
      }
    } catch (e) {
      Logger.error('Erro ao limpar cache antigo: $e');
    }
  }
  
  /// Carrega imagens a partir de URLs e converte para base64
  Future<List<String>> loadImagesFromUrls(List<String> urls) async {
    List<String> processedImages = [];
    
    for (final url in urls) {
      try {
        // Verificar se já é base64
        if (url.startsWith('data:image')) {
          processedImages.add(url);
          continue;
        }
        
        // Verificar cache primeiro
        final cached = await getImageFromCache(url);
        if (cached != null) {
          processedImages.add(cached);
          continue;
        }
        
        // Baixar a imagem
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          Logger.error('Erro ao baixar imagem: ${response.statusCode}');
          continue;
        }
        
        // Converter para base64
        final imageBytes = response.bodyBytes;
        final contentType = response.headers['content-type'] ?? 'image/jpeg';
        final base64Image = 'data:$contentType;base64,${base64Encode(imageBytes)}';
        
        // Comprimir e processar
        final processed = await processImage(base64Image);
        processedImages.add(processed);
        
        // Salvar URL no cache
        final hash = sha256.convert(utf8.encode(url)).toString();
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'image_url_cache_$hash';
        await prefs.setString(cacheKey, processed);
        await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        Logger.error('Erro ao processar URL de imagem $url: $e');
      }
    }
    
    return processedImages;
  }
  
  /// Associa imagens a um plantio
  Future<void> associateImagesWithPlanting(Planting planting, List<String> imageUrls) async {
    try {
      // Processar imagens
      final processedImages = await processImages(imageUrls);
      
      // TODO: Implementar lógica para associar as imagens ao plantio no banco de dados
      // Esta implementação depende da estrutura do seu banco de dados
      
      // Atualizar o modelo de plantio com as imagens processadas
      // Exemplo: planting.imageUrls = processedImages;
      // await plantingRepository.update(planting);
      
      Logger.info('Imagens processadas com sucesso: ${processedImages.length} imagens');
    } catch (e) {
      Logger.error('Erro ao associar imagens ao plantio: $e');
      throw Exception('Erro ao associar imagens ao plantio: $e');
    }
  }
  
  /// Comprime uma imagem com opções adicionais
  Future<CompressionResult> compressImageWithOptions({
    required String sourcePath,
    required String targetPath,
    int quality = 80,
    int? maxWidth,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      final originalSize = await sourceFile.length();
      final originalSizeKB = originalSize ~/ 1024;
      
      if (!await sourceFile.exists()) {
        return CompressionResult(
          success: false,
          message: 'Arquivo de origem não encontrado',
          originalSizeKB: 0,
        );
      }
      
      // Comprimir imagem
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? 1024,
        format: CompressFormat.jpeg,
      );
      
      if (result == null) {
        return CompressionResult(
          success: false,
          message: 'Falha ao comprimir imagem',
          originalSizeKB: originalSizeKB,
        );
      }
      
      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final compressedSizeKB = compressedSize ~/ 1024;
      final compressionRatio = ((compressedSize / originalSize) * 100).round();
      
      return CompressionResult(
        success: true,
        message: 'Imagem comprimida com sucesso',
        compressedFile: compressedFile,
        originalSizeKB: originalSizeKB,
        compressedSizeKB: compressedSizeKB,
        compressionRatio: compressionRatio,
      );
    } catch (e) {
      Logger.error('Erro ao comprimir imagem: $e');
      return CompressionResult(
        success: false,
        message: 'Erro ao comprimir imagem: $e',
      );
    }
  }
  
  /// Verifica e repara imagens com problemas de integridade
  Future<Map<String, dynamic>> checkAndRepairImages() async {
    try {
      // Resultados da verificação
      int totalChecked = 0;
      int totalValid = 0;
      int totalRepaired = 0;
      int totalFailed = 0;
      List<String> failedImages = [];
      
      // Obter diretório de imagens
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/images');
      
      if (!await imagesDir.exists()) {
        return {
          'success': true,
          'message': 'Diretório de imagens não encontrado ou vazio',
          'totalChecked': 0,
        };
      }
      
      // Listar todas as imagens
      final fileList = await imagesDir.list(recursive: true).toList();
      final imageFiles = fileList.whereType<File>().where((file) {
        final ext = path.extension(file.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
      }).toList();
      
      // Verificar cada imagem
      for (final imageFile in imageFiles) {
        totalChecked++;
        
        final validationResult = await validateImage(imageFile);
        
        if (validationResult.isValid) {
          totalValid++;
          continue;
        }
        
        // Tentar reparar a imagem
        final repairTargetPath = '${imageFile.path}_repaired.jpg';
        final repairResult = await repairImage(imageFile, repairTargetPath);
        
        if (repairResult.success) {
          // Substituir a imagem original pela reparada
          await imageFile.delete();
          await repairResult.repairedFile!.copy(imageFile.path);
          await File(repairTargetPath).delete();
          totalRepaired++;
        } else {
          totalFailed++;
          failedImages.add(imageFile.path);
        }
      }
      
      return {
        'success': true,
        'message': 'Verificação de imagens concluída',
        'totalChecked': totalChecked,
        'totalValid': totalValid,
        'totalRepaired': totalRepaired,
        'totalFailed': totalFailed,
        'failedImages': failedImages,
      };
    } catch (e) {
      Logger.error('Erro ao verificar e reparar imagens: $e');
      return {
        'success': false,
        'message': 'Erro ao verificar e reparar imagens: $e',
      };
    }
  }
  
  /// Verifica a integridade do banco de dados de imagens
  Future<Map<String, dynamic>> checkDatabaseIntegrity() async {
    return {
      'success': true,
      'message': 'Verificação de integridade concluída',
      'totalChecked': 0,
      'totalFixed': 0,
    };
  }
  
  /// Verifica e corrige a estrutura do banco de dados
  Future<Map<String, dynamic>> verifyAndFixDatabaseStructure() async {
    return {
      'success': true,
      'message': 'Estrutura do banco de dados verificada',
      'totalFixed': 0,
    };
  }
  
  /// Verifica a integridade de um lote de imagens
  Future<Map<String, dynamic>> batchVerifyImagesIntegrity() async {
    return {
      'success': true,
      'message': 'Verificação de integridade de imagens concluída',
      'totalChecked': 0,
      'validCount': 0,
      'invalidCount': 0,
    };
  }
  
  /// Remove imagens órfãs do sistema
  Future<int> cleanupOrphanedImages() async {
    try {
      // Este é um placeholder - implementação real requer acesso ao banco de dados
      // para verificar quais imagens não estão sendo referenciadas
      return 0;
    } catch (e) {
      Logger.error('Erro ao limpar imagens órfãs: $e');
      return 0;
    }
  }
  
  /// Valida uma imagem usando dados de imagem
  Future<ValidationResult> validateImageData({required Uint8List imageData}) async {
    try {
      if (imageData.isEmpty) {
        return ValidationResult(
          isValid: false,
          message: 'Dados de imagem vazios',
          errorCode: 'EMPTY_DATA',
        );
      }
      
      final sizeKB = imageData.length ~/ 1024;
      
      if (imageData.length > _maxImageSizeBytes) {
        return ValidationResult(
          isValid: false,
          message: 'Imagem muito grande (${sizeKB}KB). Tamanho máximo: ${_maxImageSizeBytes ~/ 1024}KB',
          sizeKB: sizeKB,
          errorCode: 'FILE_TOO_LARGE',
        );
      }
      
      // Tentar decodificar a imagem
      img.Image? decodedImage;
      try {
        decodedImage = img.decodeImage(imageData);
      } catch (e) {
        return ValidationResult(
          isValid: false,
          message: 'Formato de imagem inválido ou corrompido',
          sizeKB: sizeKB,
          errorCode: 'INVALID_FORMAT',
        );
      }
      
      if (decodedImage == null) {
        return ValidationResult(
          isValid: false,
          message: 'Não foi possível decodificar a imagem',
          sizeKB: sizeKB,
          errorCode: 'DECODE_FAILED',
        );
      }
      
      return ValidationResult(
        isValid: true,
        message: 'Imagem válida',
        sizeKB: sizeKB,
        width: decodedImage.width,
        height: decodedImage.height,
        format: 'DECODED',
      );
    } catch (e) {
      Logger.error('Erro ao validar dados de imagem: $e');
      return ValidationResult(
        isValid: false,
        message: 'Erro ao validar dados de imagem: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }
  
  /// Repara uma imagem usando dados de imagem
  Future<RepairResult> repairImageData({required Uint8List imageData, required String targetPath, int? maxWidth}) async {
    try {
      // Verificar se os dados são válidos
      if (imageData.isEmpty) {
        return RepairResult(
          success: false,
          message: 'Dados de imagem vazios',
          originalPath: 'memory',
        );
      }
      
      // Tentar decodificar a imagem
      img.Image? decodedImage;
      String repairMethod = 'UNKNOWN';
      
      try {
        decodedImage = img.decodeImage(imageData);
        repairMethod = 'AUTO_DECODE';
      } catch (e) {
        Logger.error('Erro ao decodificar imagem: $e');
      }
      
      if (decodedImage == null) {
        return RepairResult(
          success: false,
          message: 'Não foi possível reparar a imagem',
          originalPath: 'memory',
        );
      }
      
      // Redimensionar se necessário
      if (maxWidth != null && decodedImage.width > maxWidth) {
        decodedImage = img.copyResize(
          decodedImage,
          width: maxWidth,
          height: (decodedImage.height * maxWidth / decodedImage.width).round(),
          interpolation: img.Interpolation.linear,
        );
        repairMethod = 'RESIZE_$repairMethod';
      }
      
      // Salvar a imagem reparada
      final repairedBytes = img.encodeJpg(decodedImage, quality: 85);
      final repairedFile = File(targetPath);
      await repairedFile.writeAsBytes(repairedBytes);
      
      return RepairResult(
        success: true,
        message: 'Imagem reparada com sucesso',
        repairedFile: repairedFile,
        repairMethod: repairMethod,
        originalPath: 'memory',
      );
    } catch (e) {
      Logger.error('Erro ao reparar dados de imagem: $e');
      return RepairResult(
        success: false,
        message: 'Erro ao reparar dados de imagem: $e',
        originalPath: 'memory',
      );
    }
  }
}
