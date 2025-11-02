import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart'; // Removido - causando problemas de build
import 'package:cross_file/cross_file.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';

/// Classe para compartilhar arquivos gerados pelo aplicativo
class FileSharingService {
  /// Compartilha um arquivo com outros aplicativos
  static Future<void> shareFile(
    BuildContext context,
    String filePath, {
    String? subject,
    String? text,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        SnackbarHelper.showError(
          context,
          'Arquivo não encontrado: ${path.basename(filePath)}',
        );
        return;
      }

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Arquivo compartilhado do FortSmartAgro',
        text: text,
      );

      if (result.status == ShareResultStatus.success) {
        SnackbarHelper.showSuccess(
          context,
          'Arquivo compartilhado com sucesso',
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        SnackbarHelper.showInfo(
          context,
          'Compartilhamento cancelado',
        );
      }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Erro ao compartilhar arquivo: ${e.toString()}',
      );
    }
  }

  /// Abre um arquivo com o aplicativo padrão do sistema
  static Future<void> openFile(
    BuildContext context,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        SnackbarHelper.showError(
          context,
          'Arquivo não encontrado: ${path.basename(filePath)}',
        );
        return;
      }

      // final result = await OpenFile.open(filePath); // Removido - usando share_plus como alternativa
      await Share.shareXFiles([XFile(filePath)], text: 'Arquivo compartilhado');
      
      // Share.shareXFiles não retorna ResultType, então removemos a verificação
      // if (result.type != ResultType.done) {
      //   SnackbarHelper.showError(
      //     context,
      //     'Erro ao abrir arquivo: ${result.message}',
      //   );
      // }
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Erro ao abrir arquivo: ${e.toString()}',
      );
    }
  }

  /// Salva um arquivo na pasta de downloads do dispositivo
  static Future<String?> saveToDownloads(
    BuildContext context,
    String sourceFilePath,
    String? newFileName,
  ) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        SnackbarHelper.showError(
          context,
          'Arquivo não encontrado: ${path.basename(sourceFilePath)}',
        );
        return null;
      }

      // Determinar o nome do arquivo
      final fileName = newFileName ?? path.basename(sourceFilePath);
      
      // Obter diretório de downloads
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        SnackbarHelper.showError(
          context,
          'Não foi possível acessar a pasta de downloads',
        );
        return null;
      }
      
      // Criar caminho de destino
      final destinationPath = path.join(downloadsDir.path, fileName);
      
      // Copiar arquivo
      await sourceFile.copy(destinationPath);
      
      SnackbarHelper.showSuccess(
        context,
        'Arquivo salvo em Downloads: $fileName',
      );
      
      return destinationPath;
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'Erro ao salvar arquivo: ${e.toString()}',
      );
      return null;
    }
  }

  /// Salva um arquivo no diretório do aplicativo
  /// Retorna o caminho do arquivo salvo
  static Future<String> saveFileToAppDirectory(
    File sourceFile,
    String targetDirectory,
    String fileName,
  ) async {
    try {
      // Verificar se o arquivo existe
      if (!await sourceFile.exists()) {
        throw Exception('Arquivo de origem não encontrado');
      }
      
      // Obter o diretório de documentos do aplicativo
      final appDir = await getApplicationDocumentsDirectory();
      
      // Criar o diretório de destino se não existir
      final targetDir = Directory('${appDir.path}/$targetDirectory');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // Definir o caminho de destino
      final targetPath = '${targetDir.path}/$fileName';
      
      // Copiar o arquivo
      final savedFile = await sourceFile.copy(targetPath);
      
      return savedFile.path;
    } catch (e) {
      debugPrint('Erro ao salvar arquivo no diretório do aplicativo: $e');
      throw Exception('Erro ao salvar arquivo: $e');
    }
  }

  /// Exibe um diálogo com opções para o arquivo
  static Future<void> showFileOptionsDialog(
    BuildContext context,
    String filePath,
    String fileType,
  ) async {
    final fileName = path.basename(filePath);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Arquivo gerado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O arquivo $fileType foi gerado com sucesso:'),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('O que deseja fazer com este arquivo?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openFile(context, filePath);
            },
            child: const Text('Abrir'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              shareFile(context, filePath);
            },
            child: const Text('Compartilhar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await saveToDownloads(context, filePath, null);
            },
            child: const Text('Salvar em Downloads'),
          ),
        ],
      ),
    );
  }

  /// Obtém o diretório de downloads do dispositivo
  static Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // No Android, usar a pasta de downloads padrão
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Tentar encontrar a pasta de downloads
        final downloadsDir = Directory('${directory.path}/../Download');
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }
        
        // Se não encontrar, usar a pasta de documentos
        return directory;
      }
    }
    
    // Em outros sistemas, usar a pasta de documentos
    return await getApplicationDocumentsDirectory();
  }
} 