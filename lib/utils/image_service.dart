import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// Serviço para manipulação de imagens
class ImageService {
  /// Redimensiona uma imagem para as dimensões especificadas
  Future<File> resizeImage(File imageFile, int width, int height) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Não foi possível decodificar a imagem');
    }
    
    final resizedImage = img.copyResize(image, width: width, height: height);
    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
    
    final resizedFile = File(imageFile.path.replaceFirst('.', '_resized.'));
    await resizedFile.writeAsBytes(resizedBytes);
    
    return resizedFile;
  }
  
  /// Comprime uma imagem para reduzir seu tamanho
  Future<File> compressImage(File imageFile, int quality) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Não foi possível decodificar a imagem');
    }
    
    final compressedBytes = img.encodeJpg(image, quality: quality);
    
    final compressedFile = File(imageFile.path.replaceFirst('.', '_compressed.'));
    await compressedFile.writeAsBytes(compressedBytes);
    
    return compressedFile;
  }
  
  /// Comprime e salva uma imagem em um caminho específico
  Future<String> compressAndSaveImage(File imageFile, String folderName, {int quality = 85}) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Não foi possível decodificar a imagem');
    }
    
    final compressedBytes = img.encodeJpg(image, quality: quality);
    
    // Criar um caminho de arquivo baseado no timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.jpg';
    
    // Obter o diretório de documentos do aplicativo
    final appDocDir = Directory(await _getAppDocumentsPath());
    final folderDir = Directory('${appDocDir.path}/$folderName');
    
    // Garantir que o diretório exista
    if (!await folderDir.exists()) {
      await folderDir.create(recursive: true);
    }
    
    final outputPath = '${folderDir.path}/$fileName';
    
    final compressedFile = File(outputPath);
    await compressedFile.writeAsBytes(compressedBytes);
    
    return outputPath;
  }
  
  /// Obtém o caminho do diretório de documentos do aplicativo
  Future<String> _getAppDocumentsPath() async {
    try {
      final directory = await Directory.systemTemp.createTemp();
      return directory.path;
    } catch (e) {
      // Fallback para um diretório temporário
      return Directory.systemTemp.path;
    }
  }
  
  /// Converte uma imagem para base64
  Future<String> imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }
  
  /// Salva uma imagem sem compressão
  Future<String> saveImage(File imageFile, String folderName) async {
    // Criar um caminho de arquivo baseado no timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.jpg';
    
    // Obter o diretório de documentos do aplicativo
    final appDocDir = Directory(await _getAppDocumentsPath());
    final folderDir = Directory('${appDocDir.path}/$folderName');
    
    // Garantir que o diretório exista
    if (!await folderDir.exists()) {
      await folderDir.create(recursive: true);
    }
    
    final outputPath = '${folderDir.path}/$fileName';
    
    // Copiar o arquivo para o novo caminho
    await imageFile.copy(outputPath);
    
    return outputPath;
  }
  
  /// Converte base64 para uma imagem
  Future<File> base64ToImage(String base64String, String outputPath) async {
    final bytes = base64Decode(base64String);
    final file = File(outputPath);
    
    // Garantir que o diretório exista
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    await file.writeAsBytes(bytes);
    return file;
  }
  
  /// Converte bytes para uma imagem
  Future<File> bytesToImage(Uint8List bytes, String outputPath) async {
    final file = File(outputPath);
    
    // Garantir que o diretório exista
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    await file.writeAsBytes(bytes);
    return file;
  }
}

// Funções auxiliares para codificação/decodificação base64
String base64Encode(List<int> bytes) {
  return base64.encode(bytes);
}

List<int> base64Decode(String base64String) {
  return base64.decode(base64String);
}
