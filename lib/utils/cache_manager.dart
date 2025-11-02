import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'logger.dart';

/// Classe para gerenciamento de cache do aplicativo
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  final TaggedLogger _logger = TaggedLogger('CacheManager');
  
  /// Diretório base para o cache
  late Directory _cacheDir;
  
  /// Diretório para cache de imagens
  late Directory _imageCache;
  
  /// Diretório para cache de documentos
  late Directory _documentCache;
  
  /// Diretório para cache temporário
  late Directory _tempCache;

  /// Construtor de fábrica para o singleton
  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  /// Inicializa o gerenciador de cache
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'cache'));
      
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }
      
      _imageCache = Directory(path.join(_cacheDir.path, 'images'));
      if (!await _imageCache.exists()) {
        await _imageCache.create(recursive: true);
      }
      
      _documentCache = Directory(path.join(_cacheDir.path, 'documents'));
      if (!await _documentCache.exists()) {
        await _documentCache.create(recursive: true);
      }
      
      _tempCache = Directory(path.join(_cacheDir.path, 'temp'));
      if (!await _tempCache.exists()) {
        await _tempCache.create(recursive: true);
      }
      
      _logger.info('Cache inicializado: ${_cacheDir.path}');
    } catch (e) {
      _logger.severe('Erro ao inicializar cache: $e');
      rethrow;
    }
  }

  /// Retorna o diretório de cache de imagens
  Directory get imageCache => _imageCache;

  /// Retorna o diretório de cache de documentos
  Directory get documentCache => _documentCache;

  /// Retorna o diretório de cache temporário
  Directory get tempCache => _tempCache;

  /// Limpa o cache de imagens
  Future<int> clearImageCache() async {
    return _clearDirectory(_imageCache);
  }

  /// Limpa o cache de documentos
  Future<int> clearDocumentCache() async {
    return _clearDirectory(_documentCache);
  }

  /// Limpa o cache temporário
  Future<int> clearTempCache() async {
    return _clearDirectory(_tempCache);
  }

  /// Limpa todo o cache
  Future<int> clearAllCache() async {
    int count = 0;
    count += await clearImageCache();
    count += await clearDocumentCache();
    count += await clearTempCache();
    return count;
  }

  /// Limpa um diretório específico
  Future<int> _clearDirectory(Directory directory) async {
    try {
      int count = 0;
      if (await directory.exists()) {
        final entities = await directory.list().toList();
        for (var entity in entities) {
          if (entity is File) {
            await entity.delete();
            count++;
          } else if (entity is Directory) {
            count += await _clearDirectory(entity);
            await entity.delete();
          }
        }
      }
      _logger.info('Limpeza de cache concluída: ${directory.path}, $count arquivos removidos');
      return count;
    } catch (e) {
      _logger.severe('Erro ao limpar diretório ${directory.path}: $e');
      return 0;
    }
  }

  /// Retorna o tamanho total do cache em bytes
  Future<int> getCacheSize() async {
    int size = 0;
    size += await _getDirectorySize(_imageCache);
    size += await _getDirectorySize(_documentCache);
    size += await _getDirectorySize(_tempCache);
    return size;
  }

  /// Retorna o tamanho de um diretório específico em bytes
  Future<int> _getDirectorySize(Directory directory) async {
    try {
      int size = 0;
      if (await directory.exists()) {
        final entities = await directory.list(recursive: true).toList();
        for (var entity in entities) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
      return size;
    } catch (e) {
      _logger.severe('Erro ao calcular tamanho do diretório ${directory.path}: $e');
      return 0;
    }
  }

  /// Salva um arquivo no cache de imagens
  Future<File> cacheImage(File file, String fileName) async {
    final targetPath = path.join(_imageCache.path, fileName);
    return await file.copy(targetPath);
  }

  /// Salva um arquivo no cache de documentos
  Future<File> cacheDocument(File file, String fileName) async {
    final targetPath = path.join(_documentCache.path, fileName);
    return await file.copy(targetPath);
  }

  /// Salva um arquivo no cache temporário
  Future<File> cacheTemp(File file, String fileName) async {
    final targetPath = path.join(_tempCache.path, fileName);
    return await file.copy(targetPath);
  }

  /// Verifica se um arquivo existe no cache de imagens
  Future<bool> imageExists(String fileName) async {
    final filePath = path.join(_imageCache.path, fileName);
    return await File(filePath).exists();
  }

  /// Verifica se um arquivo existe no cache de documentos
  Future<bool> documentExists(String fileName) async {
    final filePath = path.join(_documentCache.path, fileName);
    return await File(filePath).exists();
  }

  /// Obtém um arquivo do cache de imagens
  Future<File?> getImage(String fileName) async {
    final filePath = path.join(_imageCache.path, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Obtém um arquivo do cache de documentos
  Future<File?> getDocument(String fileName) async {
    final filePath = path.join(_documentCache.path, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Remove um arquivo do cache de imagens
  Future<bool> removeImage(String fileName) async {
    try {
      final filePath = path.join(_imageCache.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Erro ao remover imagem do cache: $e');
      return false;
    }
  }

  /// Remove um arquivo do cache de documentos
  Future<bool> removeDocument(String fileName) async {
    try {
      final filePath = path.join(_documentCache.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Erro ao remover documento do cache: $e');
      return false;
    }
  }
}
