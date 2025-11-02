import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Métodos auxiliares para o serviço de relatórios em PDF
class PdfReportHelpers {
  /// Constrói o cabeçalho do relatório
  static pw.Widget buildReportHeader({
    required String title,
    required pw.ImageProvider logo,
    required DateTime date,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Data: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          pw.Image(
            logo,
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }

  /// Constrói o rodapé do relatório
  static pw.Widget buildReportFooter({
    required int pageNumber,
    required int pageCount,
    required pw.Font font,
  }) {
    return pw.Footer(
      margin: const pw.EdgeInsets.only(top: 16),
      title: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FORTSMART AGRO',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),
          ),
          pw.Text(
            'Página $pageNumber de $pageCount',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o título de uma seção
  static pw.Widget buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: 1,
          ),
        ),
      ),
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Constrói uma tabela de informações
  static pw.Widget buildInfoTable(List<Map<String, String>> data, pw.Font font) {
    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: data.map((item) {
        final entry = item.entries.first;
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                '${entry.key}:',
                style: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                entry.value,
                style: pw.TextStyle(
                  font: font,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Constrói uma grade de imagens
  static pw.Widget buildImageGrid(List<Uint8List> images) {
    final int columns = 2;
    final List<List<Uint8List>> rows = [];
    
    for (var i = 0; i < images.length; i += columns) {
      final end = (i + columns < images.length) ? i + columns : images.length;
      rows.add(images.sublist(i, end));
    }
    
    return pw.Column(
      children: rows.map((rowImages) {
        return pw.Row(
          children: rowImages.map((img) {
            return pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Image(
                  pw.MemoryImage(img),
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Constrói o rodapé com QR code e assinatura
  static pw.Widget buildFooterWithQrAndSignature({
    required String qrData,
    required Uint8List? signature,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'QR Code de Verificação',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 80,
                height: 80,
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (signature != null) ...[
                pw.Image(
                  pw.MemoryImage(signature),
                  height: 60,
                ),
                pw.SizedBox(height: 4),
              ],
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text(
                'Assinatura do Responsável',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Container(),
        ),
      ],
    );
  }

  /// Carrega a imagem do logo
  static Future<pw.ImageProvider> loadLogoImage() async {
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    return pw.MemoryImage(logoData.buffer.asUint8List());
  }

  /// Salva o PDF em um arquivo
  static Future<File> savePdf(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
