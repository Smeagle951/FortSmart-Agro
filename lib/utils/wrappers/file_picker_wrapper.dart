import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Wrapper para seleção de arquivos que não depende do plugin file_picker
class FilePickerWrapper {
  static final ImagePicker _imagePicker = ImagePicker();
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Obtém a chave do Navigator para ser usada no MaterialApp
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Seleciona um único arquivo
  static Future<File?> pickSingleFile({
    String type = 'any',
    List<String>? allowedExtensions,
  }) async {
    if (_navigatorKey.currentContext == null) {
      return null;
    }

    // Se o tipo for imagem, usamos o image_picker
    if (type == 'image') {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
      return null;
    }

    // Para outros tipos, mostramos um diálogo explicando a limitação
    final result = await showDialog<bool>(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Seleção de arquivos'),
        content: const Text(
          'Devido a limitações técnicas, apenas a seleção de imagens é suportada nesta versão do aplicativo. '
          'Deseja selecionar uma imagem?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Selecionar imagem'),
          ),
        ],
      ),
    );

    if (result == true) {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
    }

    return null;
  }

  /// Seleciona múltiplos arquivos
  static Future<List<File>> pickMultipleFiles({
    String type = 'any',
    List<String>? allowedExtensions,
  }) async {
    if (_navigatorKey.currentContext == null) {
      return [];
    }

    // Para qualquer tipo, mostramos um diálogo explicando a limitação
    final result = await showDialog<bool>(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Seleção de múltiplos arquivos'),
        content: const Text(
          'Devido a limitações técnicas, a seleção de múltiplos arquivos não é suportada nesta versão do aplicativo. '
          'Você pode selecionar um arquivo por vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Selecionar um arquivo'),
          ),
        ],
      ),
    );

    if (result == true) {
      final file = await pickSingleFile(type: type, allowedExtensions: allowedExtensions);
      if (file != null) {
        return [file];
      }
    }

    return [];
  }

  /// Seleciona um diretório
  static Future<String?> pickDirectory() async {
    if (_navigatorKey.currentContext == null) {
      return null;
    }

    // Mostramos um diálogo explicando a limitação
    await showDialog<void>(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Seleção de diretório'),
        content: const Text(
          'Devido a limitações técnicas, a seleção de diretórios não é suportada nesta versão do aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return null;
  }

  /// Salva um arquivo
  static Future<String?> saveFile({
    required String fileName,
    List<String>? allowedExtensions,
  }) async {
    if (_navigatorKey.currentContext == null) {
      return null;
    }

    // Mostramos um diálogo explicando a limitação
    await showDialog<void>(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Salvar arquivo'),
        content: const Text(
          'Devido a limitações técnicas, salvar arquivos não é suportado nesta versão do aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return null;
  }

  /// Seleciona uma imagem (método estático)
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _imagePicker.pickImage(source: source);
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Seleciona uma imagem a partir de um contexto
  Future<XFile?> pickImageWithContext({BuildContext? context, ImageSource source = ImageSource.gallery}) async {
    try {
      // Se o contexto for fornecido, mostra um diálogo para escolher entre câmera e galeria
      if (context != null) {
        // Mostra um diálogo para escolher entre câmera e galeria
        final ImageSource? selectedSource = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Selecionar imagem'),
              content: const Text('Escolha a fonte da imagem:'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
                  child: const Text('Câmera'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, ImageSource.gallery),
                  child: const Text('Galeria'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );

        if (selectedSource == null) {
          return null;
        }

        return await _imagePicker.pickImage(source: selectedSource);
      }
      
      // Se não houver contexto, usa a fonte fornecida
      return await _imagePicker.pickImage(source: source);
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }
}
