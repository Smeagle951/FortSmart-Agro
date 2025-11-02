import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'logger.dart';

/// Classe utilitária para operações com imagens
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();
  
  /// Seleciona uma imagem da galeria
  static Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao selecionar imagem da galeria', e);
      return null;
    }
  }
  
  /// Captura uma imagem da câmera
  static Future<File?> captureImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao capturar imagem da câmera', e);
      return null;
    }
  }
  
  /// Redimensiona uma imagem
  static Future<File?> resizeImage(File imageFile, int maxWidth, int maxHeight, int quality) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Image image = await decodeImageFromList(bytes);
      
      // Calcula as novas dimensões mantendo a proporção
      final double ratio = image.width / image.height;
      int width = maxWidth;
      int height = (width / ratio).round();
      
      if (height > maxHeight) {
        height = maxHeight;
        width = (height * ratio).round();
      }
      
      // Cria um novo arquivo para a imagem redimensionada
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        '${_uuid.v4()}.jpg',
      );
      
      // Implementação simplificada - em uma aplicação real, 
      // você usaria um pacote como flutter_image_compress para redimensionar
      final File resizedFile = File(targetPath);
      await resizedFile.writeAsBytes(bytes);
      
      return resizedFile;
    } catch (e) {
      Logger.error('Erro ao redimensionar imagem', e);
      return null;
    }
  }
  
  /// Comprime uma imagem
  static Future<File?> compressImage(File imageFile, int quality) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      
      // Cria um novo arquivo para a imagem comprimida
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        '${_uuid.v4()}.jpg',
      );
      
      // Implementação simplificada - em uma aplicação real, 
      // você usaria um pacote como flutter_image_compress para comprimir
      final File compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(bytes);
      
      return compressedFile;
    } catch (e) {
      Logger.error('Erro ao comprimir imagem', e);
      return null;
    }
  }
  
  /// Gera um nome de arquivo único para uma imagem
  static String generateUniqueImageName() {
    return '${_uuid.v4()}.jpg';
  }
  
  /// Converte uma imagem para base64
  static Future<String?> imageToBase64(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      Logger.error('Erro ao converter imagem para base64', e);
      return null;
    }
  }
  
  /// Converte base64 para uma imagem
  static Future<File?> base64ToImage(String base64String, String fileName) async {
    try {
      final Uint8List bytes = base64Decode(base64String);
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(tempDir.path, fileName);
      
      final File imageFile = File(targetPath);
      await imageFile.writeAsBytes(bytes);
      
      return imageFile;
    } catch (e) {
      Logger.error('Erro ao converter base64 para imagem', e);
      return null;
    }
  }
}

// Funções auxiliares para codificação/decodificação base64
Uint8List base64Decode(String source) {
  return convert.base64Decode(source);
}

String base64Encode(List<int> bytes) {
  return convert.base64Encode(bytes);
}
