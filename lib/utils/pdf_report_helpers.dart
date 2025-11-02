import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

/// Classe auxiliar para geração de relatórios em PDF
class PdfReportHelpers {
  /// Carrega a imagem do logo
  static Future<pw.ImageProvider?> loadLogoImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  /// Constrói uma linha de informação para o relatório
  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do relatório
  static pw.Widget buildReportHeader({
    required String title,
    required pw.ImageProvider? logo,
    required DateTime date,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 24,
                color: PdfColors.green900,
              ),
            ),
            logo != null ? pw.Image(logo, width: 100) : pw.Container(),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Data: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  /// Constrói o rodapé do relatório
  static pw.Widget buildReportFooter({
    required int pageNumber,
    required int pageCount,
    required pw.Font font,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'FortSmartAgro - Relatório gerado em ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.Text(
          'Página $pageNumber de $pageCount',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      ],
    );
  }

  /// Constrói o título de uma seção do relatório
  static pw.Widget buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 14,
          color: PdfColors.green900,
        ),
      ),
    );
  }

  /// Constrói uma tabela de informações para o relatório
  static pw.Widget buildInfoTable(List<Map<String, String>> data, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: data.map((row) {
        final entries = row.entries.toList();
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                entries[0].key,
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                entries[0].value,
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Constrói uma grade de imagens para o relatório
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
                padding: const pw.EdgeInsets.all(5),
                child: pw.Image(pw.MemoryImage(img)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Constrói o rodapé com QR Code e assinatura
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
                'Verificação Digital:',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
              pw.BarcodeWidget(
                data: qrData,
                width: 80,
                height: 80,
                barcode: pw.Barcode.qrCode(),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (signature != null) pw.Image(pw.MemoryImage(signature), height: 60),
              pw.Divider(thickness: 1),
              pw.Text(
                'Assinatura do Responsável',
                style: pw.TextStyle(font: font, fontSize: 10),
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
}
