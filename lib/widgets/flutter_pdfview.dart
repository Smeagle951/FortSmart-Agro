import 'dart:io';
import 'package:flutter/material.dart';

/// Um widget simples para visualização de PDF
/// Esta é uma implementação temporária até que o plugin flutter_pdfview seja corretamente configurado
class PDFView extends StatelessWidget {
  final String filePath;
  final bool fitPolicy;
  final PageController? pageController;
  final Function(int)? onPageChanged;
  final Function(bool)? onViewCreated;
  final Function(String)? onError;
  final int? defaultPage;

  const PDFView({
    Key? key,
    required this.filePath,
    this.fitPolicy = true,
    this.pageController,
    this.onPageChanged,
    this.onViewCreated,
    this.onError,
    this.defaultPage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    
    if (!file.existsSync()) {
      if (onError != null) {
        onError!('Arquivo não encontrado: $filePath');
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Arquivo PDF não encontrado',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              filePath,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Implementação temporária - exibe apenas uma mensagem informando que o PDF está disponível
    if (onViewCreated != null) {
      onViewCreated!(true);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Visualizador de PDF',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Arquivo disponível em:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              filePath,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.open_in_new),
            label: Text('Abrir com aplicativo externo'),
            onPressed: () {
              // Aqui você pode implementar a abertura do PDF com um aplicativo externo
              // usando o plugin open_file ou url_launcher
            },
          ),
        ],
      ),
    );
  }
}

/// Enum para políticas de ajuste de PDF
class FitPolicy {
  static const bool WIDTH = true;
  static const bool HEIGHT = false;
  static const bool BOTH = true;
}
