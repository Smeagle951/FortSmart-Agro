import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'logger.dart';

/// Serviço para compressão e gerenciamento de imagens
class ImageCompressionService {
  static const String _imagesFolder = 'infestacoes';
  static const int _maxImageSize = 1024; // Tamanho máximo em pixels
  static const int _compressionQuality = 85; // Qualidade de compressão (0-100)

  /// Comprime uma imagem e salva no diretório de infestações
  static Future<String?> compressAndSaveImage(File originalImage) async {
    try {
      Logger.info('🖼️ Iniciando compressão de imagem: ${originalImage.path}');
      
      // Ler a imagem original
      final bytes = await originalImage.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _maxImageSize,
        targetHeight: _maxImageSize,
      );
      
      final frame = await codec.getNextFrame();
      final compressedImage = frame.image;
      
      // Converter para bytes comprimidos
      final byteData = await compressedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        Logger.error('❌ Falha ao comprimir imagem');
        return null;
      }
      
      // Gerar nome único para o arquivo
      final uuid = const Uuid().v4();
      final fileName = 'inf_${uuid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Obter diretório de documentos
      final documentsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(documentsDir.path, _imagesFolder));
      
      // Criar diretório se não existir
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Salvar imagem comprimida
      final compressedFile = File(path.join(imagesDir.path, fileName));
      await compressedFile.writeAsBytes(byteData.buffer.asUint8List());
      
      Logger.info('✅ Imagem comprimida salva: ${compressedFile.path}');
      return compressedFile.path;
      
    } catch (e) {
      Logger.error('❌ Erro ao comprimir imagem: $e');
      return null;
    }
  }

  /// Comprime múltiplas imagens
  static Future<List<String>> compressAndSaveImages(List<File> images) async {
    final List<String> savedPaths = [];
    
    for (final image in images) {
      final savedPath = await compressAndSaveImage(image);
      if (savedPath != null) {
        savedPaths.add(savedPath);
      }
    }
    
    return savedPaths;
  }

  /// Valida se uma imagem é válida
  static Future<bool> isValidImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return false;
      
      // Verificar se é uma imagem válida tentando decodificar
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (e) {
      Logger.error('❌ Imagem inválida: $e');
      return false;
    }
  }

  /// Obtém o tamanho de um arquivo de imagem
  static Future<int> getImageFileSize(File image) async {
    try {
      return await image.length();
    } catch (e) {
      Logger.error('❌ Erro ao obter tamanho da imagem: $e');
      return 0;
    }
  }

  /// Verifica se há espaço suficiente para salvar imagens
  static Future<bool> hasEnoughSpace(List<File> images) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final freeSpace = await documentsDir.stat().then((stat) => stat.size);
      
      // Estimar tamanho total das imagens comprimidas (assumindo 70% de redução)
      int totalSize = 0;
      for (final image in images) {
        final size = await getImageFileSize(image);
        totalSize += (size * 0.7).round(); // Estimativa de compressão
      }
      
      return freeSpace > totalSize * 2; // Margem de segurança
    } catch (e) {
      Logger.error('❌ Erro ao verificar espaço: $e');
      return false;
    }
  }

  /// Remove uma imagem do armazenamento local
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        Logger.info('🗑️ Imagem removida: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao remover imagem: $e');
      return false;
    }
  }

  /// Remove múltiplas imagens
  static Future<void> deleteImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      await deleteImage(path);
    }
  }

  /// Obtém informações sobre uma imagem
  static Future<Map<String, dynamic>?> getImageInfo(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imageData = frame.image;
      
      return {
        'width': imageData.width,
        'height': imageData.height,
        'size': await getImageFileSize(image),
        'path': image.path,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter informações da imagem: $e');
      return null;
    }
  }

  /// Limpa imagens antigas (mais de 30 dias)
  static Future<int> cleanupOldImages({int daysOld = 30}) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(documentsDir.path, _imagesFolder));
      
      if (!await imagesDir.exists()) return 0;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;
      
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      
      if (deletedCount > 0) {
        Logger.info('🧹 Limpeza: $deletedCount imagens antigas removidas');
      }
      
      return deletedCount;
    } catch (e) {
      Logger.error('❌ Erro na limpeza de imagens: $e');
      return 0;
    }
  }
}
