import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/farm.dart';
import '../models/monitoring.dart';
import '../models/planting.dart';
import '../models/harvest_loss.dart';
import '../models/pesticide_application.dart';
import '../models/plot.dart';
import '../repositories/farm_repository.dart';

/// Serviço responsável pela geração de relatórios em formato PDF
/// para os diferentes módulos do sistema FORTSMART.
class ReportService {
  final FarmRepository _farmRepository = FarmRepository();
  
  // Fontes utilizadas nos relatórios
  pw.Font? _titleFont;
  pw.Font? _headingFont;
  pw.Font? _regularFont;
  pw.Font? _boldFont;
  
  // Cores do tema FORTSMART
  static const PdfColor primaryColor = PdfColor(0.16, 0.31, 0.24); // #2A4F3D
  static const PdfColor secondaryColor = PdfColor(0.27, 0.53, 0.31); // #468750
  static const PdfColor accentColor = PdfColor(0.95, 0.76, 0.06); // #F3C20F
  static const PdfColor textColor = PdfColor(0.13, 0.13, 0.13); // #212121
  static const PdfColor lightTextColor = PdfColor(0.40, 0.40, 0.40); // #666666
  
  // Inicializa o serviço carregando as fontes necessárias
  Future<void> initialize() async {
    try {
      // Carrega as fontes utilizadas nos relatórios
      final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
      final fontDataSemiBold = await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf');
      
      _regularFont = pw.Font.ttf(fontData);
      _boldFont = pw.Font.ttf(fontDataBold);
      _headingFont = pw.Font.ttf(fontDataSemiBold);
      _titleFont = pw.Font.ttf(fontDataBold);
    } catch (e) {
      print('Erro ao carregar fontes: $e');
      // Utiliza fontes padrão se não conseguir carregar as personalizadas
      _regularFont = null;
      _boldFont = null;
      _headingFont = null;
      _titleFont = null;
    }
  }
  
  /// Gera um código único para o relatório baseado no tipo e data
  String _generateReportCode(String type, DateTime date) {
    final dateFormat = DateFormat('yyyyMMdd');
    final random = (1000 + DateTime.now().millisecond) % 999;
    final formattedRandom = random.toString().padLeft(3, '0');
    
    // Formato: TIPO-AAAAMMDD-XXX
    return '${type.toUpperCase()}-${dateFormat.format(date)}-$formattedRandom';
  }
  
  /// Gera um relatório de monitoramento 
  Future<Uint8List> generateMonitoringReport(Monitoring monitoring, Plot plot, Farm farm) async {
    // Inicializa o documento PDF
    final pdf = pw.Document();
    final reportCode = _generateReportCode('MONI', monitoring.date);
    
    // Adiciona a página do relatório
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          farm: farm, 
          reportCode: reportCode, 
          reportDate: monitoring.date,
          reportTitle: 'Relatório de Monitoramento'
        ),
        footer: (context) => _buildReportFooter(farm: farm, technician: monitoring.technicianName),
        build: (context) => [
          // Seção de identificação
          _buildSectionTitle('Identificação', icon: pw.IconData(0xE88E)), // point_of_sale icon
          pw.SizedBox(height: 10),
          _buildInfoTable([
            {'label': 'Talhão', 'value': '${plot.name} - ${plot.cropName}'},
            {'label': 'Data', 'value': DateFormat('dd/MM/yyyy').format(monitoring.date)},
            {'label': 'GPS', 'value': '${monitoring.latitude}, ${monitoring.longitude}'},
            {'label': 'Técnico', 'value': '${monitoring.technicianName} - CREA ${monitoring.technicianIdentification}'},
          ]),
          
          pw.SizedBox(height: 20),
          
          // Seção de diagnóstico
          _buildSectionTitle('Diagnóstico', icon: pw.IconData(0xE3CA)), // bug_report icon
          pw.SizedBox(height: 10),
          
          // Lista de pragas encontradas
          _buildSubsectionTitle('Pragas:'),
          monitoring.pests != null ? _buildBulletList(monitoring.pests!.map((pest) => 
            '${pest['scientificName'] ?? 'Não especificado'} - ${pest['location'] ?? 'Local não especificado'} - ${pest['incidence'] ?? '0'}% de incidência'
          ).toList()) : pw.Container(),
          
          pw.SizedBox(height: 10),
          
          // Lista de doenças encontradas
          _buildSubsectionTitle('Doenças:'),
          monitoring.diseases != null ? _buildBulletList(monitoring.diseases!.map((disease) => 
            '${disease['name'] ?? 'Não especificada'} (${disease['scientificName'] ?? 'Nome científico não especificado'}) - ${disease['affectedArea'] ?? '0'}% da área'
          ).toList()) : pw.Container(),
          
          pw.SizedBox(height: 10),
          
          // Lista de plantas daninhas encontradas
          _buildSubsectionTitle('Plantas Daninhas:'),
          monitoring.weeds != null ? _buildBulletList(monitoring.weeds!.map((weed) => 
            '${weed['name'] ?? 'Não especificada'} (${weed['location'] ?? 'Local não especificado'})'
          ).toList()) : pw.Container(),
          
          pw.SizedBox(height: 20),
          
          // Seção de imagens (se disponíveis)
          _buildSectionTitle('Imagens', icon: pw.IconData(0xE3B0)), // photo_camera icon
          pw.SizedBox(height: 10),
          
          monitoring.images != null ? _buildImageGrid(monitoring.images!) : pw.Container(),
          
          pw.SizedBox(height: 20),
          
          // Resumo técnico e recomendações
          _buildSectionTitle('Resumo Técnico', icon: pw.IconData(0xE873)), // assignment icon
          pw.SizedBox(height: 10),
          
          _buildInfoBox(
            title: 'Observações',
            content: monitoring.observations ?? 'Nenhuma observação registrada',
            color: ReportService.secondaryColor
          ),
          
          pw.SizedBox(height: 10),
          
          _buildInfoBox(
            title: 'Recomendações',
            content: monitoring.recommendations ?? 'Nenhuma recomendação registrada',
            color: ReportService.accentColor
          ),
        ],
      ),
    );
    
    return pdf.save();
  }
  
  /// Métodos auxiliares para construir os componentes do relatório
  
  /// Constrói o cabeçalho padrão dos relatórios
  pw.Widget _buildReportHeader({
    required Farm farm, 
    required String reportCode, 
    required DateTime reportDate,
    required String reportTitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Logo e nome da fazenda
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  farm.name,
                  style: pw.TextStyle(
                    font: _titleFont,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  farm.ownerName ?? 'Proprietário não especificado',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
            
            // Logo FORTSMART
            pw.Text(
              'FORTSMART',
              style: pw.TextStyle(
                font: _boldFont,
                fontSize: 18,
                color: primaryColor,
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Título do relatório
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 2),
            ),
          ),
          child: pw.Text(
            reportTitle,
            style: pw.TextStyle(
              font: _titleFont,
              fontSize: 24,
              color: primaryColor,
            ),
          ),
        ),
        
        pw.SizedBox(height: 10),
        
        // Código e data do relatório
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Código: $reportCode | Data: ${DateFormat('dd/MM/yyyy').format(reportDate)}',
              style: pw.TextStyle(
                font: _regularFont,
                fontSize: 10,
                color: lightTextColor,
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  /// Constrói o rodapé padrão dos relatórios
  pw.Widget _buildReportFooter({required Farm farm, String? technician}) {
    return pw.Column(
      children: [
        pw.Divider(color: primaryColor),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Assinatura do técnico
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  technician ?? 'Técnico Responsável',
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Container(
                  width: 150,
                  height: 1,
                  margin: const pw.EdgeInsets.only(top: 15),
                  color: textColor,
                ),
                pw.Text(
                  'Assinatura',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 8,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
            
            // Informações do sistema
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Relatório gerado via FortSmart – Gestão Agrícola Inteligente',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 8,
                    color: lightTextColor,
                  ),
                ),
                pw.Text(
                  farm.website ?? 'www.fortsmartagro.com.br',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 8,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  // Método auxiliar para criar título de seção
  pw.Widget _buildSectionTitle(String title, {pw.IconData? icon}) {
    return pw.Row(
      children: [
        if (icon != null) ...[
          pw.Icon(icon, color: primaryColor, size: 18),
          pw.SizedBox(width: 5),
        ],
        pw.Text(
          title,
          style: pw.TextStyle(
            font: _headingFont,
            fontSize: 16, 
            color: primaryColor,
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(left: 10),
            height: 1, 
            color: primaryColor,
          ),
        ),
      ],
    );
  }
  
  // Método auxiliar para criar subtítulo
  pw.Widget _buildSubsectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: _boldFont,
        fontSize: 14,
        color: textColor,
      ),
    );
  }
  
  // Método auxiliar para criar tabela de informações
  pw.Widget _buildInfoTable(List<Map<String, String>> data) {
    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor(0.9, 0.9, 0.9), width: 1),
      ),
      children: data.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: pw.Text(
                row['label'] ?? '',
                style: pw.TextStyle(
                  font: _boldFont,
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: pw.Text(
                row['value'] ?? '',
                style: pw.TextStyle(
                  font: _regularFont,
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  // Método auxiliar para criar lista com marcadores
  pw.Widget _buildBulletList(List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 4,
                height: 4,
                margin: const pw.EdgeInsets.only(top: 4, right: 5, left: 5),
                decoration: pw.BoxDecoration(
                  color: secondaryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  item,
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Método auxiliar para criar grid de imagens
  pw.Widget _buildImageGrid(List<String> imagePaths) {
    if (imagePaths.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: lightTextColor),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Center(
          child: pw.Text(
            'Sem imagens disponíveis',
            style: pw.TextStyle(
              font: _regularFont,
              fontSize: 12,
              color: lightTextColor,
            ),
          ),
        ),
      );
    }
    
    // Implementar grid de imagens quando disponíveis
    // Será necessário carregar as imagens do sistema de arquivos
    return pw.Container();
  }
  
  // Método auxiliar para criar caixa de informações
  pw.Widget _buildInfoBox({
    required String title,
    required String content,
    required PdfColor color,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: _boldFont,
                fontSize: 12,
                color: PdfColor(1, 1, 1),
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              content,
              style: pw.TextStyle(
                font: _regularFont,
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Métodos para compartilhar e salvar os relatórios
  
  /// Compartilha o relatório gerado
  Future<void> shareReport(Uint8List reportBytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(reportBytes);
      await Share.share('Relatório FORTSMART', subject: 'Relatório FORTSMART');
    } catch (e) {
      print('Erro ao compartilhar relatório: $e');
      rethrow;
    }
  }
  
  /// Salva o relatório no sistema de arquivos
  Future<String> saveReport(Uint8List reportBytes, String fileName) async {
    try {
      final downloadsDir = await getExternalStorageDirectory();
      final reportDir = Directory('${downloadsDir?.path}/FORTSMART/Relatórios');
      
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }
      
      final filePath = '${reportDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(reportBytes);
      
      return filePath;
    } catch (e) {
      print('Erro ao salvar relatório: $e');
      rethrow;
    }
  }
  
  /// Imprime o relatório
  Future<void> printReport(Uint8List reportBytes) async {
    try {
      // await Printing.layoutPdf(
      //   onLayout: (_) async => reportBytes,
      // );
    } catch (e) {
      print('Erro ao imprimir relatório: $e');
      rethrow;
    }
  }
}
