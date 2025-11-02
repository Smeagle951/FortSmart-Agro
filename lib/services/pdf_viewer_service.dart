import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/flutter_pdfview.dart';

class PdfViewerService {
  /// Abre um PDF a partir de um caminho de arquivo
  Future<Widget> openPdf(BuildContext context, String filePath) async {
    if (await File(filePath).exists()) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Visualizador de PDF'),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () => sharePdf(filePath),
            ),
          ],
        ),
        body: PDFView(
          filePath: filePath,
          onPageChanged: (page) {
            // Página alterada
          },
          onViewCreated: (success) {
            // Visualizador criado
          },
          onError: (error) {
            // Erro ao carregar PDF
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao carregar PDF: $error')),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Text('Arquivo PDF não encontrado'),
      );
    }
  }

  /// Compartilha um arquivo PDF
  Future<void> sharePdf(String filePath) async {
    try {
      final fileName = p.basename(filePath);
      // Implementar compartilhamento do PDF usando um plugin como share_plus
      print('Compartilhando PDF: $fileName');
      // TODO: Implementar compartilhamento real quando o plugin estiver disponível
    } catch (e) {
      print('Erro ao compartilhar PDF: $e');
    }
  }

  /// Copia um PDF para o diretório da aplicação e retorna o caminho
  Future<String?> copyPdfToAppDir(String sourcePath, {String? customFileName}) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = customFileName ?? p.basename(sourcePath);
      final targetPath = '${appDir.path}/pdfs/$fileName';

      // Cria o diretório se não existir
      final targetDir = Directory('${appDir.path}/pdfs');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Copia o arquivo
      await file.copy(targetPath);
      return targetPath;
    } catch (e) {
      print('Erro ao copiar PDF: $e');
      return null;
    }
  }

  /// Exclui um PDF pelo caminho
  Future<bool> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao excluir PDF: $e');
      return false;
    }
  }

}
