import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart'; // Removido - causando problemas de build
import 'package:cross_file/cross_file.dart';
import 'package:fortsmart_agro/models/pesticide_application.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/models/prescription.dart';
import 'package:fortsmart_agro/utils/date_formatter.dart';

/// Classe para geração de PDFs
class PdfGenerator {
  static final dateFormat = DateFormat('dd/MM/yyyy');
  
  /// Gera um PDF de prescrição agronômica
  static Future<bool> generatePrescriptionPdf(Prescription prescription) async {
    try {
      final pdf = pw.Document();
      
      // Carrega a logo
      final logoBytes = await _loadAsset('assets/images/logo.png');
      final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(logo, 'Prescrição Agronômica'),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            // Título da prescrição
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.green800),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    prescription.title,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: _getStatusColor(prescription.status),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      prescription.status,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Informações gerais
            _buildSectionTitle('Informações Gerais'),
            _buildInfoTable([
              ['Data de Emissão', dateFormat.format(prescription.issueDate)],
              ['Data de Validade', dateFormat.format(prescription.expiryDate)],
              ['Responsável Técnico', prescription.agronomistName],
              ['Registro Profissional', prescription.agronomistRegistration],
            ]),
            pw.SizedBox(height: 20),
            
            // Localização
            _buildSectionTitle('Localização'),
            _buildInfoTable([
              ['Fazenda', prescription.farmName],
              ['Talhão', prescription.plotName],
              ['Cultura', prescription.cropName],
            ]),
            pw.SizedBox(height: 20),
            
            // Alvos (se existirem)
            if (prescription.targetPest != null ||
                prescription.targetDisease != null ||
                prescription.targetWeed != null) ...[
              _buildSectionTitle('Alvos'),
              _buildInfoTable([
                if (prescription.targetPest != null)
                  ['Praga', prescription.targetPest!],
                if (prescription.targetDisease != null)
                  ['Doença', prescription.targetDisease!],
                if (prescription.targetWeed != null)
                  ['Planta Daninha', prescription.targetWeed!],
              ]),
              pw.SizedBox(height: 20),
            ],
            
            // Produtos recomendados
            _buildSectionTitle('Produtos Recomendados'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Cabeçalho da tabela
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _buildTableHeader('Produto'),
                    _buildTableHeader('Dosagem'),
                    _buildTableHeader('Método de Aplicação'),
                  ],
                ),
                // Linhas de produtos
                for (var product in prescription.products)
                  pw.TableRow(
                    children: [
                      _buildTableCell(product.productName),
                      _buildTableCell('${product.dosage} ${product.dosageUnit}'),
                      _buildTableCell(product.applicationMethod),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            
            // Observações dos produtos (se existirem)
            for (var product in prescription.products)
              if (product.observations != null && product.observations!.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${product.productName}: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: product.observations!),
                    ],
                  ),
                ),
              ],
            pw.SizedBox(height: 20),
            
            // Informações adicionais (se existirem)
            if (prescription.observations != null ||
                prescription.applicationConditions != null ||
                prescription.safetyInstructions != null) ...[
              _buildSectionTitle('Informações Adicionais'),
              if (prescription.observations != null) ...[
                pw.Text(
                  'Observações:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(prescription.observations!),
                pw.SizedBox(height: 10),
              ],
              if (prescription.applicationConditions != null) ...[
                pw.Text(
                  'Condições de Aplicação:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(prescription.applicationConditions!),
                pw.SizedBox(height: 10),
              ],
              if (prescription.safetyInstructions != null) ...[
                pw.Text(
                  'Instruções de Segurança:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(prescription.safetyInstructions!),
              ],
            ],
            
            // Assinatura
            pw.SizedBox(height: 40),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    prescription.agronomistName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Responsável Técnico - ${prescription.agronomistRegistration}',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      
      // Salvar o PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/prescricao_${prescription.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Abrir o PDF
              // OpenFile.open(file.path); // Removido - usando share_plus como alternativa
        await Share.shareXFiles([XFile(file.path)], text: 'Relatório PDF');
      
      return true;
    } catch (e) {
      print('Erro ao gerar PDF: $e');
      return false;
    }
  }
  
  /// Carrega um asset como bytes
  static Future<Uint8List?> _loadAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Erro ao carregar asset: $e');
      return null;
    }
  }
  
  /// Constrói o cabeçalho do PDF
  static pw.Widget _buildHeader(pw.ImageProvider? logo, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          logo != null
              ? pw.Image(logo, width: 60)
              : pw.Container(),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Data: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói o rodapé do PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FortSmartAgro - Sistema de Gestão Agrícola',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Página ${context.page} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói um título de seção
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    );
  }
  
  /// Constrói uma tabela de informações
  static pw.Widget _buildInfoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              color: PdfColors.grey100,
              child: pw.Text(
                row[0],
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(row[1]),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  /// Constrói uma célula de cabeçalho para tabela
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      // alignment: pw.Alignment.center, // alignment não é suportado em Marker no flutter_map 5.0.0
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Constrói uma célula para tabela
  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text),
    );
  }
  
  /// Retorna a cor correspondente ao status
  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return PdfColors.green700;
      case 'pendente':
        return PdfColors.orange700;
      case 'aplicada':
        return PdfColors.blue700;
      case 'cancelada':
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }
  
  /// Gera um PDF de relatório de aplicação de defensivo
  static Future<Uint8List> generatePesticideApplicationReport({
    required PesticideApplication application,
    required String plotName,
    required String cropName,
    required String productName,
    required String productFormulation,
    required double stockQuantity,
  }) async {
    final pdf = pw.Document();
    
    // Carrega a logo
    final logoBytes = await _loadAsset('assets/images/logo.png');
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    
    // Calcula valores
    final totalProductAmount = application.calculateTotalProductAmount();
    final totalMixtureVolume = application.calculateTotalMixtureVolume();
    final tanksNeeded = application.calculateTanksNeeded(2000);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(logo, 'Relatório de Aplicação'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Resto do código existente...

        ],
      ),
    );
    
    return pdf.save();
  }
}

