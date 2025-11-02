import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'snackbar_helper.dart';

/// Classe utilitária para gerenciar captura e processamento de mídia (imagens e áudio)
class MediaHelper {
  static final ImagePicker _picker = ImagePicker();
  static final Uuid _uuid = Uuid();
  
  // Diretório temporário para armazenar mídias
  static Future<Directory> get _mediaDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/monitoring_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }
  
  /// Captura uma imagem da câmera
  static Future<String?> captureImage(BuildContext context) async {
    try {
      // Verificar permissão da câmera
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context, 
            'Permissão da câmera negada. Por favor, habilite nas configurações.',
          );
        }
        return null;
      }
      
      // Capturar imagem
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image == null) return null;
      
      // Comprimir e salvar a imagem
      final compressedImagePath = await _compressAndSaveImage(image.path);
      return compressedImagePath;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context, 
          'Erro ao capturar imagem: $e',
        );
      }
      return null;
    }
  }
  
  /// Seleciona uma imagem da galeria
  static Future<String?> pickImage(BuildContext context) async {
    try {
      // Verificar permissão da galeria
      final galleryStatus = await Permission.photos.request();
      if (!galleryStatus.isGranted) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context, 
            'Permissão da galeria negada. Por favor, habilite nas configurações.',
          );
        }
        return null;
      }
      
      // Selecionar imagem
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image == null) return null;
      
      // Comprimir e salvar a imagem
      final compressedImagePath = await _compressAndSaveImage(image.path);
      return compressedImagePath;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context, 
          'Erro ao selecionar imagem: $e',
        );
      }
      return null;
    }
  }
  
  // Métodos removidos por estarem duplicados
  
  /// Mostra um diálogo para o usuário escolher entre câmera ou galeria
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    
    if (source == null) return null;
    
    try {
      // Verificar permissões baseado na fonte
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (context.mounted) {
            SnackbarHelper.showError(
              context, 
              'Permissão da câmera negada. Por favor, habilite nas configurações.',
            );
          }
          return null;
        }
      } else {
        final galleryStatus = await Permission.photos.request();
        if (!galleryStatus.isGranted) {
          if (context.mounted) {
            SnackbarHelper.showError(
              context, 
              'Permissão da galeria negada. Por favor, habilite nas configurações.',
            );
          }
          return null;
        }
      }
      
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image == null) return null;
      
      // Comprimir e salvar a imagem
      final compressedImagePath = await _compressAndSaveImage(image.path);
      return compressedImagePath;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context, 
          'Erro ao capturar imagem: $e',
        );
      }
      return null;
    }
  }
  
  // Métodos para gravação de áudio
  static Future<bool> startAudioRecording(BuildContext context) async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context,
            'Permissão de microfone negada. Por favor, habilite nas configurações.',
          );
        }
        return false;
      }
      
      // Aqui você implementaria a lógica para iniciar a gravação
      // Por enquanto, apenas simulamos o sucesso
      return true;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'Erro ao iniciar gravação: $e',
        );
      }
      return false;
    }
  }
  
  static Future<String?> stopAudioRecording() async {
    try {
      // Aqui você implementaria a lógica para parar a gravação
      // Por enquanto, apenas simulamos o retorno de um caminho de arquivo
      final mediaDir = await _mediaDir;
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final audioFile = File('${mediaDir.path}/$fileName');
      await audioFile.create();
      
      return audioFile.path;
    } catch (e) {
      developer.log('Erro ao parar gravação: $e');
      return null;
    }
  }
  
  /// Exclui um arquivo de mídia
  static Future<bool> deleteMediaFile(String? filePath) async {
    if (filePath == null) return false;
    
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Erro ao excluir arquivo: $e');
      return false;
    }
  }
  
  /// Obtém o tamanho do arquivo em formato legível
  static Future<String> getFileSize(String filePath, {int decimals = 1}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return '0 B';
      
      final bytes = await file.length();
      if (bytes <= 0) return '0 B';
      
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      int digitGroups = (log(bytes) / log(1024)).floor();
      
      return '${(bytes / pow(1024, digitGroups)).toStringAsFixed(decimals)} ${units[digitGroups]}';
    } catch (e) {
      developer.log('Erro ao obter tamanho do arquivo: $e');
      return '0 B';
    }
  }
  
  // Métodos removidos por estarem duplicados:
  // - getFileSize (linha ~329)
  // - showImageSourceDialog (linha ~343)
  
  /// Comprime e salva uma imagem em um diretório específico
  static Future<String> _compressAndSaveImage(String imagePath) async {
    try {
      developer.log('🔄 Iniciando compressão da imagem: $imagePath');
      
      // Verificar se o arquivo de origem existe
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        developer.log('❌ Arquivo de origem não existe: $imagePath');
        throw Exception('Arquivo de origem não encontrado');
      }
      
      final sourceSize = await sourceFile.length();
      developer.log('📊 Tamanho do arquivo original: ${sourceSize} bytes');
      
      // Preparar diretório para salvar a imagem
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
        developer.log('📁 Diretório de imagens criado: ${imageDir.path}');
      }
      
      // Gerar nome de arquivo único
      final fileName = '${_uuid.v4()}.jpg';
      final targetPath = '${imageDir.path}/$fileName';
      developer.log('🎯 Caminho de destino: $targetPath');
      
      // Comprimir a imagem
      developer.log('🔄 Iniciando compressão...');
      final result = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 80,
        minWidth: 1024,
        minHeight: 768,
        format: CompressFormat.jpeg,
        rotate: 0
      );
      
      // Salvar o resultado em um novo arquivo
      if (result != null) {
        developer.log('✅ Compressão concluída. Tamanho comprimido: ${result.length} bytes');
        final file = File(targetPath);
        await file.writeAsBytes(result);
        
        // Verificar se o arquivo foi salvo corretamente
        if (await file.exists()) {
          final savedSize = await file.length();
          developer.log('✅ Imagem salva com sucesso: $targetPath (${savedSize} bytes)');
          return targetPath;
        } else {
          developer.log('❌ Falha ao salvar arquivo comprimido');
          throw Exception('Arquivo não foi salvo corretamente');
        }
      } else {
        // Se a compressão falhar, copiar o arquivo original
        developer.log('⚠️ Compressão retornou null, copiando arquivo original');
        final originalFile = File(imagePath);
        final targetFile = await originalFile.copy(targetPath);
        
        if (await targetFile.exists()) {
          final copiedSize = await targetFile.length();
          developer.log('✅ Arquivo original copiado: $targetPath (${copiedSize} bytes)');
          return targetPath;
        } else {
          developer.log('❌ Falha ao copiar arquivo original');
          throw Exception('Falha ao copiar arquivo original');
        }
      }
    } catch (e, stackTrace) {
      developer.log('❌ Erro ao comprimir e salvar imagem: $e');
      developer.log('❌ Stack trace: $stackTrace');
      
      // Verificar se o arquivo original ainda existe e tem conteúdo
      try {
        final originalFile = File(imagePath);
        if (await originalFile.exists()) {
          final size = await originalFile.length();
          if (size > 0) {
            developer.log('⚠️ Retornando caminho original: $imagePath');
            return imagePath;
          }
        }
      } catch (e2) {
        developer.log('❌ Erro ao verificar arquivo original: $e2');
      }
      
      // Se tudo falhar, lançar exceção
      rethrow;
    }
  }
  
  /// Verifica se um arquivo é uma imagem válida
  static bool isValidImageFile(String filePath) {
    try {
      final extension = path.extension(filePath).toLowerCase();
      return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica se um arquivo é um áudio válido
  static bool isValidAudioFile(String filePath) {
    try {
      final extension = path.extension(filePath).toLowerCase();
      return ['.mp3', '.m4a', '.aac', '.wav', '.ogg'].contains(extension);
    } catch (e) {
      return false;
    }
  }
  
  // Métodos removidos por estarem duplicados:
  // - getFileSize (já existe uma versão mais completa acima)
  // - showImageSourceDialog (já existe uma versão mais completa acima)
}
