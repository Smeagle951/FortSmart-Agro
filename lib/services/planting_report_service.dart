import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/planting.dart';
import '../models/plot.dart';
import '../models/farm.dart';
import '../services/plantio_service.dart';
import '../utils/logger.dart';

/// Serviço especializado para geração de relatórios de plantio
/// Inclui análises de calibração, densidade e produtividade
class PlantingReportService {
  static const String _tag = 'PlantingReportService';
  
  // Fontes para PDF
  pw.Font? _titleFont;
  pw.Font? _headingFont;
  pw.Font? _regularFont;
  pw.Font? _boldFont;
  
  // Cores do tema FortSmart
  static const PdfColor primaryColor = PdfColor(0.16, 0.31, 0.24); // #2A4F3D
  static const PdfColor secondaryColor = PdfColor(0.27, 0.53, 0.31); // #468750
  static const PdfColor accentColor = PdfColor(0.95, 0.76, 0.06); // #F3C20F
  static const PdfColor textColor = PdfColor(0.13, 0.13, 0.13); // #212121
  static const PdfColor lightTextColor = PdfColor(0.40, 0.40, 0.40); // #666666

  /// Inicializa o serviço carregando as fontes necessárias
  Future<void> initialize() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
      final fontDataSemiBold = await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf');
      
      _regularFont = pw.Font.ttf(fontData);
      _boldFont = pw.Font.ttf(fontDataBold);
      _headingFont = pw.Font.ttf(fontDataSemiBold);
      _titleFont = pw.Font.ttf(fontDataBold);
      
      Logger.info('$_tag: Fontes carregadas com sucesso');
    } catch (e) {
      Logger.warning('$_tag: Erro ao carregar fontes: $e');
      _regularFont = null;
      _boldFont = null;
      _headingFont = null;
      _titleFont = null;
    }
  }

  /// Gera relatório completo de plantio em PDF
  Future<String> generatePlantingReport({
    required List<Planting> plantings,
    required Farm farm,
    Plot? plot,
    String? technicianName,
    bool includeCalibrationDetails = true,
    bool includeProductivityAnalysis = true,
  }) async {
    try {
      await initialize();
      
      // Gerar PDF
      final pdf = pw.Document();
      final reportCode = _generateReportCode('PLANT', DateTime.now());
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildReportHeader(
            farmName: farm.name,
            reportCode: reportCode,
            reportDate: DateTime.now(),
            reportTitle: 'Relatório de Operações de Plantio'
          ),
          footer: (context) => _buildReportFooter(
            farmName: farm.name,
            technician: technicianName ?? 'Técnico Responsável'
          ),
          build: (context) => [
            // Seção de resumo executivo
            _buildSectionTitle('Resumo Executivo', icon: pw.IconData(0xE88E)),
            pw.SizedBox(height: 10),
            _buildExecutiveSummary(plantings, farm, plot),
            
            pw.SizedBox(height: 20),
            
            // Seção de dados de plantio
            _buildSectionTitle('Dados de Plantio', icon: pw.IconData(0xE3CA)),
            pw.SizedBox(height: 10),
            _buildPlantingDataTable(plantings),
            
            pw.SizedBox(height: 20),
            
            // Seção de análise de calibração
            if (includeCalibrationDetails) ...[
              _buildSectionTitle('Análise de Calibração', icon: pw.IconData(0xE3B0)),
              pw.SizedBox(height: 10),
              _buildCalibrationAnalysis(plantings),
              
              pw.SizedBox(height: 20),
            ],
            
            // Seção de análise de produtividade
            if (includeProductivityAnalysis) ...[
              _buildSectionTitle('Análise de Produtividade', icon: pw.IconData(0xE873)),
              pw.SizedBox(height: 10),
              _buildProductivityAnalysis(plantings),
              
              pw.SizedBox(height: 20),
            ],
            
            // Seção de recomendações
            _buildSectionTitle('Recomendações Técnicas', icon: pw.IconData(0xE88E)),
            pw.SizedBox(height: 10),
            _buildTechnicalRecommendations(plantings),
            
            pw.SizedBox(height: 20),
            
            // Seção de conformidade
            _buildSectionTitle('Conformidade e Qualidade', icon: pw.IconData(0xE873)),
            pw.SizedBox(height: 10),
            _buildComplianceSection(plantings),
          ],
        ),
      );
      
      // Salvar arquivo
      final bytes = pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Relatorio_Plantio_${farm.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await bytes);
      
      Logger.info('$_tag: Relatório de plantio gerado: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Gera relatório de análise de densidade de plantio
  Future<String> generateDensityAnalysisReport({
    required List<Planting> plantings,
    required Farm farm,
    String? technicianName,
  }) async {
    try {
      await initialize();
      
      // Gerar PDF
      final pdf = pw.Document();
      final reportCode = _generateReportCode('DENS', DateTime.now());
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildReportHeader(
            farmName: farm.name,
            reportCode: reportCode,
            reportDate: DateTime.now(),
            reportTitle: 'Análise de Densidade de Plantio'
          ),
          footer: (context) => _buildReportFooter(
            farmName: farm.name,
            technician: technicianName ?? 'Técnico Responsável'
          ),
          build: (context) => [
            // Seção de análise de densidade
            _buildSectionTitle('Análise de Densidade', icon: pw.IconData(0xE88E)),
            pw.SizedBox(height: 10),
            _buildDensityAnalysisTable(plantings),
            
            pw.SizedBox(height: 20),
            
            // Seção de recomendações de densidade
            _buildSectionTitle('Recomendações de Densidade', icon: pw.IconData(0xE3CA)),
            pw.SizedBox(height: 10),
            _buildDensityRecommendations(plantings),
            
            pw.SizedBox(height: 20),
            
            // Seção de impacto na produtividade
            _buildSectionTitle('Impacto na Produtividade', icon: pw.IconData(0xE3B0)),
            pw.SizedBox(height: 10),
            _buildProductivityImpact(plantings),
          ],
        ),
      );
      
      // Salvar arquivo
      final bytes = pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Analise_Densidade_${farm.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await bytes);
      
      Logger.info('$_tag: Relatório de densidade gerado: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório de densidade: $e');
      rethrow;
    }
  }

  /// Exporta dados de plantio para CSV
  Future<String> exportPlantingDataToCsv({
    required List<Planting> plantings,
    String? fileName,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // Cabeçalho CSV
      buffer.writeln('ID,Data,Safra,Cultura,Variedade,Talhão,'
          'Área (ha),Densidade (pl/ha),Espaçamento (m),'
          'Profundidade (cm),População,Status,Observações');
      
      // Dados dos plantios
      for (final planting in plantings) {
        buffer.writeln('${planting.id},'
            '${DateFormat('dd/MM/yyyy').format(planting.date)},'
            '${planting.season},'
            '${planting.crop},'
            '${planting.variety},'
            '${planting.plotId},'
            '${planting.area?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'},'
            '${planting.population?.toStringAsFixed(0) ?? '0'},'
            '${planting.spacing?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'},'
            '${planting.depth?.toStringAsFixed(1).replaceAll('.', ',') ?? '0,0'},'
            '${planting.population?.toStringAsFixed(0) ?? '0'},'
            '${planting.status},'
            '${planting.notes?.replaceAll(',', ';') ?? ''}');
      }
      
      // Salvar arquivo CSV
      final directory = await getApplicationDocumentsDirectory();
      final finalFileName = fileName ?? 'Dados_Plantio_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$finalFileName');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      
      Logger.info('$_tag: Dados exportados para CSV: ${file.path}');
      return file.path;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao exportar dados CSV: $e');
      rethrow;
    }
  }

  /// Métodos auxiliares para construção do PDF

  pw.Widget _buildReportHeader({
    required String farmName,
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
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  farmName,
                  style: pw.TextStyle(
                    font: _titleFont,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  'Sistema FortSmart Agro',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
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
      ],
    );
  }

  pw.Widget _buildReportFooter({required String farmName, required String technician}) {
    return pw.Column(
      children: [
        pw.Divider(color: primaryColor),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  technician,
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
                  'www.fortsmartagro.com.br',
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

  pw.Widget _buildExecutiveSummary(List<Planting> plantings, Farm farm, Plot? plot) {
    final totalArea = plantings.map((p) => p.area ?? 0.0).reduce((a, b) => a + b);
    final avgDensity = plantings.map((p) => p.population ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    final completedPlantings = plantings.where((p) => p.status == 'completed').length;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          title: 'Resumo das Operações',
          content: 'Total de plantios: ${plantings.length}\n'
                  'Plantios concluídos: $completedPlantings\n'
                  'Área total plantada: ${totalArea.toStringAsFixed(2).replaceAll('.', ',')} ha\n'
                  'Densidade média: ${avgDensity.toStringAsFixed(0).replaceAll('.', ',')} plantas/ha',
          color: primaryColor,
        ),
      ],
    );
  }

  pw.Widget _buildPlantingDataTable(List<Planting> plantings) {
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor(0.95, 0.95, 0.95)),
        children: [
          _buildTableCell('Data', isHeader: true),
          _buildTableCell('Safra', isHeader: true),
          _buildTableCell('Cultura', isHeader: true),
          _buildTableCell('Variedade', isHeader: true),
          _buildTableCell('Área (ha)', isHeader: true),
          _buildTableCell('Densidade', isHeader: true),
          _buildTableCell('Status', isHeader: true),
        ],
      ),
    ];
    
    for (final planting in plantings) {
      tableRows.add(
        pw.TableRow(
          children: [
            _buildTableCell(DateFormat('dd/MM/yyyy').format(planting.date)),
            _buildTableCell(planting.season),
            _buildTableCell(planting.crop),
            _buildTableCell(planting.variety ?? ''),
            _buildTableCell('${planting.area?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}'),
            _buildTableCell('${planting.population?.toStringAsFixed(0).replaceAll('.', ',') ?? '0'}'),
            _buildTableCell(_getStatusDisplayName(planting.status)),
          ],
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor(0.9, 0.9, 0.9)),
      children: tableRows,
    );
  }

  pw.Widget _buildCalibrationAnalysis(List<Planting> plantings) {
    final calibrations = plantings.where((p) => p.calibrationId != null).length;
    final avgSpacing = plantings.map((p) => p.spacing ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    final avgDepth = plantings.map((p) => p.depth ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          title: 'Análise de Calibração',
          content: 'Plantios calibrados: $calibrations de ${plantings.length}\n'
                  'Espaçamento médio: ${avgSpacing.toStringAsFixed(2).replaceAll('.', ',')} m\n'
                  'Profundidade média: ${avgDepth.toStringAsFixed(1).replaceAll('.', ',')} cm',
          color: secondaryColor,
        ),
      ],
    );
  }

  pw.Widget _buildProductivityAnalysis(List<Planting> plantings) {
    final cultures = plantings.map((p) => p.crop).toSet();
    final analysis = <String>[];
    
    for (final culture in cultures) {
      final culturePlantings = plantings.where((p) => p.crop == culture).toList();
      final avgDensity = culturePlantings.map((p) => p.population ?? 0.0).reduce((a, b) => a + b) / culturePlantings.length;
      final totalArea = culturePlantings.map((p) => p.area ?? 0.0).reduce((a, b) => a + b);
      
      analysis.add('$culture: ${culturePlantings.length} plantios, '
                  '${totalArea?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'} ha, '
                  'densidade média ${avgDensity.toStringAsFixed(0).replaceAll('.', ',')} plantas/ha');
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          title: 'Análise por Cultura',
          content: analysis.join('\n'),
          color: primaryColor,
        ),
      ],
    );
  }

  pw.Widget _buildTechnicalRecommendations(List<Planting> plantings) {
    final recommendations = <String>[];
    
    // Análise de densidade
    final avgDensity = plantings.map((p) => p.population ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    if (avgDensity < 40000) {
      recommendations.add('• Considere aumentar a densidade de plantio para otimizar a produtividade');
    } else if (avgDensity > 60000) {
      recommendations.add('• Densidade elevada pode impactar o desenvolvimento das plantas');
    }
    
    // Análise de espaçamento
    final avgSpacing = plantings.map((p) => p.spacing ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    if (avgSpacing > 0.5) {
      recommendations.add('• Espaçamento adequado para boa aeração e desenvolvimento');
    } else {
      recommendations.add('• Espaçamento reduzido - monitore competição entre plantas');
    }
    
    // Análise de profundidade
    final avgDepth = plantings.map((p) => p.depth ?? 0.0).reduce((a, b) => a + b) / plantings.length;
    if (avgDepth < 2.0) {
      recommendations.add('• Profundidade adequada para boa germinação');
    } else {
      recommendations.add('• Profundidade elevada - monitore emergência das plantas');
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: recommendations.map((rec) => 
        _buildInfoBox(
          title: rec.split('•')[0].trim().isEmpty ? 'Recomendação' : rec.split('•')[0].trim(),
          content: rec.contains('•') ? rec.split('•')[1].trim() : rec,
          color: accentColor,
        ),
      ).toList(),
    );
  }

  pw.Widget _buildComplianceSection(List<Planting> plantings) {
    final completedPlantings = plantings.where((p) => p.status == 'completed').length;
    final complianceRate = (completedPlantings / plantings.length) * 100;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: complianceRate >= 80 ? secondaryColor : accentColor,
          width: 2,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            complianceRate >= 80 ? '✅ OPERAÇÕES CONFORME' : '⚠️ ATENÇÃO NECESSÁRIA',
            style: pw.TextStyle(
              font: _boldFont,
              fontSize: 14,
              color: complianceRate >= 80 ? secondaryColor : accentColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Taxa de conclusão: ${complianceRate.toStringAsFixed(1).replaceAll('.', ',')}%\n'
            'Plantios concluídos: $completedPlantings de ${plantings.length}',
            style: pw.TextStyle(
              font: _regularFont,
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos específicos para análise de densidade
  pw.Widget _buildDensityAnalysisTable(List<Planting> plantings) {
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor(0.95, 0.95, 0.95)),
        children: [
          _buildTableCell('Cultura', isHeader: true),
          _buildTableCell('Densidade (pl/ha)', isHeader: true),
          _buildTableCell('Área (ha)', isHeader: true),
          _buildTableCell('Classificação', isHeader: true),
          _buildTableCell('Recomendação', isHeader: true),
        ],
      ),
    ];
    
    final cultures = plantings.map((p) => p.crop).toSet();
    for (final culture in cultures) {
      final culturePlantings = plantings.where((p) => p.crop == culture).toList();
      final avgDensity = culturePlantings.map((p) => p.population ?? 0.0).reduce((a, b) => a + b) / culturePlantings.length;
      final totalArea = culturePlantings.map((p) => p.area ?? 0.0).reduce((a, b) => a + b);
      final classification = _getDensityClassification(avgDensity, culture);
      final recommendation = _getDensityRecommendation(avgDensity, culture);
      
      tableRows.add(
        pw.TableRow(
          children: [
            _buildTableCell(culture),
            _buildTableCell('${avgDensity.toStringAsFixed(0).replaceAll('.', ',')}'),
            _buildTableCell('${totalArea?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}'),
            _buildTableCell(classification),
            _buildTableCell(recommendation),
          ],
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor(0.9, 0.9, 0.9)),
      children: tableRows,
    );
  }

  pw.Widget _buildDensityRecommendations(List<Planting> plantings) {
    final recommendations = <String>[];
    final cultures = plantings.map((p) => p.crop).toSet();
    
    for (final culture in cultures) {
      final culturePlantings = plantings.where((p) => p.crop == culture).toList();
      final avgDensity = culturePlantings.map((p) => p.population ?? 0.0).reduce((a, b) => a + b) / culturePlantings.length;
      
      if (avgDensity < 40000) {
        recommendations.add('$culture: Densidade baixa (${avgDensity.toStringAsFixed(0).replaceAll('.', ',')} pl/ha). '
                          'Considere aumentar para 45.000-50.000 plantas/ha.');
      } else if (avgDensity > 60000) {
        recommendations.add('$culture: Densidade alta (${avgDensity.toStringAsFixed(0).replaceAll('.', ',')} pl/ha). '
                          'Considere reduzir para 45.000-50.000 plantas/ha.');
      } else {
        recommendations.add('$culture: Densidade adequada (${avgDensity.toStringAsFixed(0).replaceAll('.', ',')} pl/ha). '
                          'Mantenha os padrões atuais.');
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: recommendations.map((rec) => 
        _buildInfoBox(
          title: 'Recomendação de Densidade',
          content: rec,
          color: secondaryColor,
        ),
      ).toList(),
    );
  }

  pw.Widget _buildProductivityImpact(List<Planting> plantings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
          title: 'Impacto da Densidade na Produtividade',
          content: 'A densidade de plantio adequada é fundamental para maximizar a produtividade.\n\n'
                  '• Densidade baixa: Menor produtividade por área\n'
                  '• Densidade alta: Competição excessiva entre plantas\n'
                  '• Densidade ótima: Máxima produtividade com qualidade',
          color: primaryColor,
        ),
      ],
    );
  }

  // Métodos auxiliares
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? _boldFont : _regularFont,
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

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

  String _generateReportCode(String type, DateTime date) {
    final dateFormat = DateFormat('yyyyMMdd');
    final random = (1000 + DateTime.now().millisecond) % 999;
    final formattedRandom = random.toString().padLeft(3, '0');
    return '${type.toUpperCase()}-${dateFormat.format(date)}-$formattedRandom';
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'planned':
        return 'Planejado';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String _getDensityClassification(double density, String culture) {
    if (density < 40000) {
      return 'Baixa';
    } else if (density > 60000) {
      return 'Alta';
    } else {
      return 'Adequada';
    }
  }

  String _getDensityRecommendation(double density, String culture) {
    if (density < 40000) {
      return 'Aumentar densidade';
    } else if (density > 60000) {
      return 'Reduzir densidade';
    } else {
      return 'Manter densidade';
    }
  }

  /// Compartilha o relatório gerado
  Future<void> shareReport(String filePath) async {
    try {
      final file = File(filePath);
      await Share.shareXFiles([XFile(filePath)], text: 'Relatório de Plantio - FortSmart Agro');
      Logger.info('$_tag: Relatório compartilhado com sucesso');
    } catch (e) {
      Logger.error('$_tag: Erro ao compartilhar relatório: $e');
      rethrow;
    }
  }
}
