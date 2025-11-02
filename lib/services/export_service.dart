import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../utils/logger.dart';

/// Enum para tipos de exportação
enum ExportFormat {
  pdf,
  excel,
  csv,
  json
}

/// Configuração de exportação
class ExportConfig {
  final String fileName;
  final ExportFormat format;
  final Map<String, dynamic> data;
  final String? title;
  final String? subtitle;
  final List<String>? columns;
  final List<Map<String, dynamic>>? rows;

  ExportConfig({
    required this.fileName,
    required this.format,
    required this.data,
    this.title,
    this.subtitle,
    this.columns,
    this.rows,
  });
}

/// Serviço para exportação de dados em múltiplos formatos
class ExportService {
  static const String _tag = 'ExportService';

  // Cores do tema FORTSMART
  static const PdfColor primaryColor = PdfColor(0.16, 0.31, 0.24); // #2A4F3D
  static const PdfColor secondaryColor = PdfColor(0.27, 0.53, 0.31); // #468750
  static const PdfColor accentColor = PdfColor(0.95, 0.76, 0.06); // #F3C20F
  static const PdfColor textColor = PdfColor(0.13, 0.13, 0.13); // #212121
  static const PdfColor lightTextColor = PdfColor(0.40, 0.40, 0.40); // #666666

  /// Exporta dados no formato especificado
  Future<String> exportData(ExportConfig config) async {
    Logger.info('$_tag: Exportando dados em formato ${config.format.name}');
    
    try {
      switch (config.format) {
        case ExportFormat.pdf:
          return await _exportToPdf(config);
        case ExportFormat.excel:
          return await _exportToExcel(config);
        case ExportFormat.csv:
          return await _exportToCsv(config);
        case ExportFormat.json:
          return await _exportToJson(config);
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao exportar dados: $e');
      rethrow;
    }
  }

  /// Exporta para PDF
  Future<String> _exportToPdf(ExportConfig config) async {
    final pdf = pw.Document();
    
    // Carrega fontes
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPdfHeader(config, font),
            pw.SizedBox(height: 20),
            _buildPdfContent(config, font),
            pw.SizedBox(height: 20),
            _buildPdfFooter(font),
          ];
        },
      ),
    );

    // Salva o arquivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${config.fileName}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    Logger.info('$_tag: PDF salvo em: ${file.path}');
    return file.path;
  }

  /// Exporta para Excel (CSV com formatação)
  Future<String> _exportToExcel(ExportConfig config) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${config.fileName}.csv';
    final file = File('${directory.path}/$fileName');
    
    final csvData = _buildCsvData(config);
    await file.writeAsString(csvData);
    
    Logger.info('$_tag: Excel (CSV) salvo em: ${file.path}');
    return file.path;
  }

  /// Exporta para CSV
  Future<String> _exportToCsv(ExportConfig config) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${config.fileName}.csv';
    final file = File('${directory.path}/$fileName');
    
    final csvData = _buildCsvData(config);
    await file.writeAsString(csvData);
    
    Logger.info('$_tag: CSV salvo em: ${file.path}');
    return file.path;
  }

  /// Exporta para JSON
  Future<String> _exportToJson(ExportConfig config) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${config.fileName}.json';
    final file = File('${directory.path}/$fileName');
    
    final jsonData = _buildJsonData(config);
    await file.writeAsString(jsonData);
    
    Logger.info('$_tag: JSON salvo em: ${file.path}');
    return file.path;
  }

  /// Constrói dados CSV
  String _buildCsvData(ExportConfig config) {
    final csvData = <List<dynamic>>[];
    
    // Cabeçalho
    if (config.title != null) {
      csvData.add([config.title]);
      if (config.subtitle != null) {
        csvData.add([config.subtitle]);
      }
      csvData.add([]); // Linha vazia
    }
    
    // Cabeçalho das colunas
    if (config.columns != null && config.columns!.isNotEmpty) {
      csvData.add(config.columns!);
    }
    
    // Dados
    if (config.rows != null) {
      for (final row in config.rows!) {
        final csvRow = <dynamic>[];
        for (final column in config.columns ?? []) {
          csvRow.add(row[column]?.toString() ?? '');
        }
        csvData.add(csvRow);
      }
    }
    
    return const ListToCsvConverter().convert(csvData);
  }

  /// Constrói dados JSON
  String _buildJsonData(ExportConfig config) {
    final jsonData = <String, dynamic>{
      'metadata': {
        'title': config.title,
        'subtitle': config.subtitle,
        'exportedAt': DateTime.now().toIso8601String(),
        'format': config.format.name,
      },
      'data': config.data,
    };
    
    if (config.rows != null) {
      jsonData['rows'] = config.rows;
    }
    
    return jsonData.toString();
  }

  /// Cabeçalho do PDF
  pw.Widget _buildPdfHeader(ExportConfig config, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (config.title != null) ...[
            pw.Text(
              config.title!,
              style: pw.TextStyle(
                font: font,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          if (config.subtitle != null) ...[
            pw.Text(
              config.subtitle!,
              style: pw.TextStyle(
                font: font,
                fontSize: 16,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            'Exportado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Conteúdo do PDF
  pw.Widget _buildPdfContent(ExportConfig config, pw.Font font) {
    if (config.rows == null || config.rows!.isEmpty) {
      return pw.Text(
        'Nenhum dado disponível para exportação.',
        style: pw.TextStyle(font: font, fontSize: 12),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: _buildColumnWidths(config.columns?.length ?? 0),
      children: [
        // Cabeçalho da tabela
        if (config.columns != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: config.columns!.map((column) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                column,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
        // Dados da tabela
        ...config.rows!.map((row) => pw.TableRow(
          children: (config.columns ?? []).map((column) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              row[column]?.toString() ?? '',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          )).toList(),
        )).toList(),
      ],
    );
  }

  /// Rodapé do PDF
  pw.Widget _buildPdfFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Relatório gerado pelo FortSmart Agro',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Constrói larguras das colunas
  Map<int, pw.TableColumnWidth> _buildColumnWidths(int columnCount) {
    final widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < columnCount; i++) {
      widths[i] = const pw.FlexColumnWidth(1);
    }
    return widths;
  }

  /// Compartilha arquivo exportado
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      Logger.error('$_tag: Erro ao compartilhar arquivo: $e');
      rethrow;
    }
  }

  /// Obtém informações do arquivo
  Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      
      return {
        'path': filePath,
        'name': file.path.split('/').last,
        'size': stat.size,
        'modified': stat.modified,
        'exists': await file.exists(),
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao obter informações do arquivo: $e');
      return {};
    }
  }

  /// Lista arquivos exportados
  Future<List<Map<String, dynamic>>> listExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();
      
      return files.where((file) {
        final name = file.path.split('/').last.toLowerCase();
        return name.endsWith('.pdf') || 
               name.endsWith('.csv') || 
               name.endsWith('.json');
      }).map((file) async {
        final stat = await file.stat();
        return {
          'path': file.path,
          'name': file.path.split('/').last,
          'size': stat.size,
          'modified': stat.modified,
        };
      }).map((future) => future).toList();
    } catch (e) {
      Logger.error('$_tag: Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Remove arquivo exportado
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.info('$_tag: Arquivo removido: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('$_tag: Erro ao remover arquivo: $e');
      return false;
    }
  }
}
