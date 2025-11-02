import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Utilitário para geração e manipulação de PDFs
class PdfHelper {
  /// Cria um documento PDF básico com cabeçalho, conteúdo e rodapé
  static Future<pw.Document> createBasicDocument({
    required String title,
    required String subtitle,
    required List<pw.Widget> content,
    String? logoPath,
    String? footerText,
  }) async {
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Carregar logo se fornecida
    pw.MemoryImage? logo;
    if (logoPath != null) {
      final logoData = await rootBundle.load(logoPath);
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          margin: pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              logo != null
                  ? pw.Image(logo, width: 60)
                  : pw.Container(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                footerText ?? 'FORTSMARTAGRO - Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Página ${context.page} de ${context.pagesCount}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => content,
      ),
    );
    
    return pdf;
  }
  
  /// Salva um documento PDF no dispositivo e retorna o caminho do arquivo
  static Future<String> savePdf(pw.Document pdf, String fileName) async {
    try {
      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/fortsmartagro';
      
      // Criar diretório se não existir
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Adicionar timestamp para evitar sobrescrever arquivos
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '$path/${fileName}_$timestamp.pdf';
      
      // Salvar arquivo
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      print('PDF salvo em: $filePath');
      return filePath;
    } catch (e) {
      print('Erro ao salvar PDF: $e');
      throw Exception('Não foi possível salvar o PDF: $e');
    }
  }
  
  /// Cria um PDF de relatório simples
  static Future<String> createSimpleReport({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> data,
    List<String>? columns,
    String? logoPath,
    String? fileName,
  }) async {
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Definir colunas
    final tableColumns = columns ?? (data.isNotEmpty ? data.first.keys.toList() : []);
    
    // Criar conteúdo
    final content = [
      pw.Table.fromTextArray(
        border: null,
        headers: tableColumns,
        data: data.map((item) => 
          tableColumns.map((col) => item[col]?.toString() ?? '').toList()
        ).toList(),
        headerStyle: pw.TextStyle(
          font: ttf,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        cellHeight: 30,
        cellAlignments: {
          for (var i = 0; i < tableColumns.length; i++)
            i: pw.Alignment.centerLeft,
        },
      ),
    ];
    
    // Criar documento
    final document = await createBasicDocument(
      title: title,
      subtitle: subtitle,
      content: content,
      logoPath: logoPath,
    );
    
    // Salvar documento
    final outputFileName = fileName ?? title.replaceAll(' ', '_').toLowerCase();
    return await savePdf(document, outputFileName);
  }
}
