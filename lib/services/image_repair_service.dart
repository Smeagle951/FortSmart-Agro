import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import '../utils/config.dart';

/// Serviço responsável por verificar e reparar imagens antes do upload
class ImageRepairService {
  /// Verifica se a imagem é válida e pode ser processada
  Future<Map<String, dynamic>> validateImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return {
          'isValid': false,
          'error': 'Arquivo não encontrado',
          'canRepair': false,
        };
      }

      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        return {
          'isValid': false,
          'error': 'Arquivo vazio',
          'canRepair': false,
        };
      }

      // Verificar se o tamanho está dentro do limite
      final fileSizeKB = bytes.length / 1024;
      final isOversize = fileSizeKB > Config.maxUploadImageSizeKB;

      // Tentar decodificar a imagem para verificar se está corrompida
      try {
        final decodedImage = await compute(_decodeImage, bytes);
        if (decodedImage == null) {
          return {
            'isValid': false,
            'error': 'Imagem corrompida ou formato não suportado',
            'canRepair': false,
          };
        }

        return {
          'isValid': !isOversize,
          'error': isOversize ? 'Imagem muito grande' : null,
          'canRepair': isOversize,
          'width': decodedImage.width,
          'height': decodedImage.height,
          'format': _getImageFormat(bytes),
          'sizeKB': fileSizeKB,
        };
      } catch (e) {
        return {
          'isValid': false,
          'error': 'Erro ao processar imagem: $e',
          'canRepair': false,
        };
      }
    } catch (e) {
      Logger.error('Erro ao validar imagem: $e');
      return {
        'isValid': false,
        'error': 'Erro ao validar imagem: $e',
        'canRepair': false,
      };
    }
  }

  /// Repara uma imagem para que ela possa ser enviada
  /// Pode redimensionar, comprimir ou converter o formato
  Future<Map<String, dynamic>> repairImage(File imageFile) async {
    try {
      final validationResult = await validateImage(imageFile);
      if (validationResult['isValid']) {
        return {
          'success': true,
          'repairedFile': imageFile,
          'message': 'Imagem já está em conformidade',
          'changes': [],
        };
      }

      if (!validationResult['canRepair']) {
        return {
          'success': false,
          'error': validationResult['error'],
          'message': 'Não é possível reparar esta imagem',
        };
      }

      final bytes = await imageFile.readAsBytes();
      final decodedImage = await compute(_decodeImage, bytes);
      
      if (decodedImage == null) {
        return {
          'success': false,
          'error': 'Não foi possível decodificar a imagem',
          'message': 'Imagem corrompida ou formato não suportado',
        };
      }

      final changes = <String>[];
      var processedImage = decodedImage;

      // Redimensionar se necessário
      final maxDimension = Config.maxImageDimension;
      if (decodedImage.width > maxDimension || decodedImage.height > maxDimension) {
        processedImage = _resizeImage(decodedImage, maxDimension);
        changes.add('Redimensionada para máximo de ${maxDimension}px');
      }

      // Comprimir a imagem
      final quality = Config.imageQuality;
      final compressedBytes = await compute(
        _encodeJpg, 
        {'image': processedImage, 'quality': quality}
      );
      changes.add('Comprimida com qualidade $quality%');

      // Verificar se o tamanho está dentro do limite após compressão
      final compressedSizeKB = compressedBytes.length / 1024;
      if (compressedSizeKB > Config.maxUploadImageSizeKB) {
        // Se ainda estiver muito grande, comprimir mais
        final lowerQuality = (quality * 0.8).round(); // 20% menos qualidade
        final moreCompressedBytes = await compute(
          _encodeJpg, 
          {'image': processedImage, 'quality': lowerQuality}
        );
        changes.add('Compressão adicional com qualidade $lowerQuality%');
        
        // Salvar a imagem reparada
        final repairedFile = await _saveRepairedImage(imageFile, moreCompressedBytes);
        return {
          'success': true,
          'repairedFile': repairedFile,
          'message': 'Imagem reparada com sucesso',
          'changes': changes,
          'originalSizeKB': validationResult['sizeKB'],
          'newSizeKB': moreCompressedBytes.length / 1024,
        };
      } else {
        // Salvar a imagem reparada
        final repairedFile = await _saveRepairedImage(imageFile, compressedBytes);
        return {
          'success': true,
          'repairedFile': repairedFile,
          'message': 'Imagem reparada com sucesso',
          'changes': changes,
          'originalSizeKB': validationResult['sizeKB'],
          'newSizeKB': compressedSizeKB,
        };
      }
    } catch (e) {
      Logger.error('Erro ao reparar imagem: $e');
      return {
        'success': false,
        'error': 'Erro ao reparar imagem: $e',
        'message': 'Ocorreu um erro durante o reparo da imagem',
      };
    }
  }

  /// Salva a imagem reparada, mantendo o arquivo original
  Future<File> _saveRepairedImage(File originalFile, Uint8List bytes) async {
    final dir = originalFile.parent;
    final extension = path.extension(originalFile.path);
    final baseName = path.basenameWithoutExtension(originalFile.path);
    final repairedPath = path.join(dir.path, '${baseName}_repaired.jpg');
    
    final repairedFile = File(repairedPath);
    await repairedFile.writeAsBytes(bytes);
    return repairedFile;
  }

  /// Identifica o formato da imagem com base nos bytes
  String _getImageFormat(Uint8List bytes) {
    if (bytes.length < 12) return 'unknown';
    
    // JPEG: Começa com FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }
    
    // PNG: Começa com 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    
    // GIF: Começa com GIF87a ou GIF89a
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'gif';
    }
    
    // BMP: Começa com BM
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    
    // WebP: Começa com RIFF....WEBP
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    
    return 'unknown';
  }
}

/// Função para decodificar imagem em isolate separado
img.Image? _decodeImage(Uint8List bytes) {
  try {
    // Na versão 4.0.17, decodeImage retorna um Future<Image?>
    return img.decodeImage(bytes);
  } catch (e) {
    debugPrint('Erro ao decodificar imagem: $e');
    return null;
  }
}

/// Função para redimensionar imagem mantendo proporção
img.Image _resizeImage(img.Image image, int maxDimension) {
  if (image.width <= maxDimension && image.height <= maxDimension) {
    return image;
  }
  
  int width, height;
  if (image.width > image.height) {
    width = maxDimension;
    height = (image.height * maxDimension / image.width).round();
  } else {
    height = maxDimension;
    width = (image.width * maxDimension / image.height).round();
  }
  
  // Na versão 4.0.17, usamos o método copyResize com os mesmos parâmetros
  return img.copyResize(
    image,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
}

/// Função para codificar imagem como JPG em isolate separado
Uint8List _encodeJpg(Map<String, dynamic> params) {
  final image = params['image'] as img.Image;
  final quality = params['quality'] as int;
  // Na versão 4.0.17, encodeJpg retorna diretamente um Uint8List
  return img.encodeJpg(image, quality: quality);
}
