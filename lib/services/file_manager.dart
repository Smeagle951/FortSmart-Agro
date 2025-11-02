import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FileManager {
  static final FileManager _instance = FileManager._internal();
  
  factory FileManager() {
    return _instance;
  }
  
  FileManager._internal();
  
  // Diretórios base para armazenamento de arquivos
  static const String _imagesDir = 'images';
  static const String _monitoringImagesDir = 'monitoramentos';
  static const String _propertiesImagesDir = 'propriedades';
  static const String _tempDir = 'temp';
  
  // Inicializa os diretórios necessários para o aplicativo
  Future<void> initDirectories() async {
    await _createDirectory(_imagesDir);
    await _createDirectory(path.join(_imagesDir, _monitoringImagesDir));
    await _createDirectory(path.join(_imagesDir, _propertiesImagesDir));
    await _createDirectory(_tempDir);
  }
  
  // Cria um diretório se ele não existir
  Future<Directory> _createDirectory(String dirPath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory directory = Directory(path.join(appDocDir.path, dirPath));
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }
  
  // Salva uma imagem de monitoramento e retorna o caminho relativo
  Future<String> saveMonitoringImage(File imageFile, int monitoringId) async {
    final uuid = Uuid().v4();
    final String fileName = 'monitoring_${monitoringId}_$uuid${path.extension(imageFile.path)}';
    final String relativePath = path.join(_imagesDir, _monitoringImagesDir, fileName);
    
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = path.join(appDocDir.path, relativePath);
    
    // Copia o arquivo para o destino
    await imageFile.copy(fullPath);
    
    return relativePath;
  }
  
  // Salva uma imagem de propriedade e retorna o caminho relativo
  Future<String> savePropertyImage(File imageFile, int propertyId) async {
    final uuid = Uuid().v4();
    final String fileName = 'property_${propertyId}_$uuid${path.extension(imageFile.path)}';
    final String relativePath = path.join(_imagesDir, _propertiesImagesDir, fileName);
    
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = path.join(appDocDir.path, relativePath);
    
    // Copia o arquivo para o destino
    await imageFile.copy(fullPath);
    
    return relativePath;
  }
  
  // Obtém o caminho completo a partir do caminho relativo
  Future<String> getFullPath(String relativePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, relativePath);
  }
  
  // Exclui um arquivo pelo caminho relativo
  Future<bool> deleteFile(String relativePath) async {
    try {
      final String fullPath = await getFullPath(relativePath);
      final File file = File(fullPath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao excluir arquivo: $e');
      return false;
    }
  }
  
  // Cria um arquivo temporário para uso no aplicativo
  Future<File> createTempFile(String extension) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String tempDirPath = path.join(appDocDir.path, _tempDir);
    final Directory tempDir = Directory(tempDirPath);
    
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    
    final uuid = Uuid().v4();
    final String filePath = path.join(tempDirPath, 'temp_$uuid.$extension');
    return File(filePath);
  }
  
  // Limpa arquivos temporários
  Future<int> cleanTempFiles() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String tempDirPath = path.join(appDocDir.path, _tempDir);
      final Directory tempDir = Directory(tempDirPath);
      
      if (!await tempDir.exists()) {
        return 0;
      }
      
      int count = 0;
      await for (FileSystemEntity entity in tempDir.list()) {
        if (entity is File) {
          await entity.delete();
          count++;
        }
      }
      
      return count;
    } catch (e) {
      print('Erro ao limpar arquivos temporários: $e');
      return 0;
    }
  }
}
