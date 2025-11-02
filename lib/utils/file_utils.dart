import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Classe utilitária para operações com arquivos
class FileUtils {
  /// Obtém o diretório de documentos do aplicativo
  Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Obtém o diretório temporário do aplicativo
  Future<Directory> getAppTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }
  
  /// Cria um diretório se ele não existir
  Future<Directory> createDirectoryIfNotExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }
    return directory;
  }
  
  /// Verifica se um arquivo existe
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
  
  /// Deleta um arquivo se ele existir
  Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Obtém o tamanho de um arquivo em bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// Copia um arquivo para outro local
  Future<File> copyFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    return await sourceFile.copy(destinationPath);
  }
  
  /// Renomeia um arquivo
  Future<File> renameFile(String oldPath, String newPath) async {
    final file = File(oldPath);
    return await file.rename(newPath);
  }
  
  /// Lista todos os arquivos em um diretório
  Future<List<FileSystemEntity>> listFiles(String dirPath, {bool recursive = false}) async {
    final directory = Directory(dirPath);
    final entities = await directory.list(recursive: recursive).toList();
    return entities.where((entity) => entity is File).toList();
  }
  
  /// Obtém a extensão de um arquivo
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  /// Obtém o nome do arquivo sem a extensão
  String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  /// Obtém o nome do arquivo com a extensão
  String getFileName(String filePath) {
    return path.basename(filePath);
  }
}
