import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'notifications_wrapper.dart';
import 'permission_handler_wrapper.dart';

class FilePickerWrapper {
  final ImagePicker _picker = ImagePicker();
  final PermissionHandlerWrapper _permissionHandler = PermissionHandlerWrapper();

  Future<File?> pickImage({required ImageSource source}) async {
    try {
      // Verificar permissão
      bool hasPermission = source == ImageSource.camera
          ? await _permissionHandler.requestCameraPermission()
          : await _permissionHandler.requestStoragePermission();

      if (!hasPermission) {
        print('Permissão negada para ${source == ImageSource.camera ? 'câmera' : 'galeria'}');
        return null;
      }

      // Selecionar imagem
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  Future<String?> pickImageAndSave(BuildContext context, {bool fromCamera = true}) async {
    try {
      // Verificar permissão
      bool hasPermission = fromCamera
          ? await _permissionHandler.requestCameraPermission()
          : await _permissionHandler.requestStoragePermission();

      if (!hasPermission) {
        NotificationsWrapper().showNotification(
          context,
          title: 'Permissão Negada',
          message: fromCamera
              ? 'É necessário permitir o acesso à câmera para tirar fotos.'
              : 'É necessário permitir o acesso à galeria para selecionar imagens.',
          isError: true,
        );
        return null;
      }

      // Selecionar imagem
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return null;
      }

      // Copiar imagem para diretório da aplicação
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Gerar nome único para o arquivo
      final uuid = const Uuid().v4();
      final fileExtension = path.extension(image.path);
      final fileName = '$uuid$fileExtension';
      final savedImagePath = '${imagesDir.path}/$fileName';

      // Copiar arquivo
      final savedImage = await File(image.path).copy(savedImagePath);
      return savedImage.path;
    } catch (e) {
      NotificationsWrapper().showNotification(
        context,
        title: 'Erro',
        message: 'Erro ao selecionar imagem: $e',
        isError: true,
      );
      return null;
    }
  }

  Future<void> showImagePickerDialog(
    BuildContext context, {
    required Function(String) onImageSelected,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await pickImageAndSave(context, fromCamera: true);
                if (imagePath != null) {
                  onImageSelected(imagePath);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await pickImageAndSave(context, fromCamera: false);
                if (imagePath != null) {
                  onImageSelected(imagePath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
