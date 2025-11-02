import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../models/farm.dart';
import '../models/planting.dart';
import '../models/monitoring.dart';
import '../models/pesticide_application.dart';
import '../models/harvest_loss.dart';
import '../models/inventory_movement.dart';
import '../utils/logger.dart';

/// Configuração para relatório consolidado
class ConsolidatedReportConfig {
  final DateTime startDate;
  final DateTime endDate;
  final String farm;
  final String season;
  final bool includePlanting;
  final bool includeMonitoring;
  final bool includeApplications;
  final bool includeHarvest;
  final bool includeInventory;
  final bool includeCosts;

  ConsolidatedReportConfig({
    required this.startDate,
    required this.endDate,
    required this.farm,
    required this.season,
    this.includePlanting = true,
    this.includeMonitoring = true,
    this.includeApplications = true,
    this.includeHarvest = true,
    this.includeInventory = true,
    this.includeCosts = true,
  });
}

/// Serviço para geração de relatório consolidado da safra
class ConsolidatedReportService {
  static const String _tag = 'ConsolidatedReportService';
  final AppDatabase _database = AppDatabase();

  // Cores do tema FORTSMART
  static const PdfColor primaryColor = PdfColor(0.16, 0.31, 0.24); // #2A4F3D
  static const PdfColor secondaryColor = PdfColor(0.27, 0.53, 0.31); // #468750
  static const PdfColor accentColor = PdfColor(0.95, 0.76, 0.06); // #F3C20F
  static const PdfColor textColor = PdfColor(0.13, 0.13, 0.13); // #212121
  static const PdfColor lightTextColor = PdfColor(0.40, 0.40, 0.40); // #666666

  /// Obtém fazendas disponíveis
  Future<List<String>> getAvailableFarms() async {
    try {
      final db = await _database.database;
      final result = await db.query('farms', columns: ['name']);
      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      Logger.error('$_tag: Erro ao obter fazendas: $e');
      return [];
    }
  }

  /// Obtém safras disponíveis
  Future<List<String>> getAvailableSeasons() async {
    try {
      final db = await _database.database;
      final result = await db.query('plantings', columns: ['season'], distinct: true);
      return result.map((row) => row['season'] as String).toList();
    } catch (e) {
      Logger.error('$_tag: Erro ao obter safras: $e');
      return [];
    }
  }

  /// Gera relatório consolidado
  Future<String> generateConsolidatedReport(ConsolidatedReportConfig config) async {
    Logger.info('$_tag: Gerando relatório consolidado para ${config.farm} - ${config.season}');
    
    try {
      final data = await _collectReportData(config);
      final pdf = await _generatePdfReport(data, config);
      
      // Salva o arquivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'relatorio_consolidado_${config.farm}_${config.season}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      Logger.info('$_tag: Relatório salvo em: ${file.path}');
      return file.path;
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Coleta dados para o relatório
  Future<Map<String, dynamic>> _collectReportData(ConsolidatedReportConfig config) async {
    final db = await _database.database;
    final data = <String, dynamic>{};

    // Dados básicos
    data['config'] = config;
    data['generatedAt'] = DateTime.now();

    // Dados de plantio
    if (config.includePlanting) {
      data['planting'] = await _getPlantingData(db, config);
    }

    // Dados de monitoramento
    if (config.includeMonitoring) {
      data['monitoring'] = await _getMonitoringData(db, config);
    }

    // Dados de aplicações
    if (config.includeApplications) {
      data['applications'] = await _getApplicationData(db, config);
    }

    // Dados de colheita
    if (config.includeHarvest) {
      data['harvest'] = await _getHarvestData(db, config);
    }

    // Dados de estoque
    if (config.includeInventory) {
      data['inventory'] = await _getInventoryData(db, config);
    }

    // Dados de custos
    if (config.includeCosts) {
      data['costs'] = await _getCostData(db, config);
    }

    return data;
  }

  /// Dados de plantio
  Future<Map<String, dynamic>> _getPlantingData(dynamic db, ConsolidatedReportConfig config) async {
    final result = await db.query(
      'plantings',
      where: 'farm = ? AND season = ? AND date BETWEEN ? AND ?',
      whereArgs: [config.farm, config.season, config.startDate.millisecondsSinceEpoch, config.endDate.millisecondsSinceEpoch],
    );

    return {
      'totalPlantings': result.length,
      'totalArea': result.fold<double>(0, (sum, row) => sum + (row['area'] as double)),
      'plantings': result,
    };
  }

  /// Dados de monitoramento
  Future<Map<String, dynamic>> _getMonitoringData(dynamic db, ConsolidatedReportConfig config) async {
    final result = await db.query(
      'monitoring_sessions',
      where: 'farm = ? AND date BETWEEN ? AND ?',
      whereArgs: [config.farm, config.startDate.millisecondsSinceEpoch, config.endDate.millisecondsSinceEpoch],
    );

    return {
      'totalSessions': result.length,
      'sessions': result,
    };
  }

  /// Dados de aplicações
  Future<Map<String, dynamic>> _getApplicationData(dynamic db, ConsolidatedReportConfig config) async {
    final result = await db.query(
      'pesticide_applications',
      where: 'farm = ? AND application_date BETWEEN ? AND ?',
      whereArgs: [config.farm, config.startDate.millisecondsSinceEpoch, config.endDate.millisecondsSinceEpoch],
    );

    return {
      'totalApplications': result.length,
      'applications': result,
    };
  }

  /// Dados de colheita
  Future<Map<String, dynamic>> _getHarvestData(dynamic db, ConsolidatedReportConfig config) async {
    final result = await db.query(
      'harvest_losses',
      where: 'farm = ? AND harvest_date BETWEEN ? AND ?',
      whereArgs: [config.farm, config.startDate.millisecondsSinceEpoch, config.endDate.millisecondsSinceEpoch],
    );

    return {
      'totalHarvests': result.length,
      'harvests': result,
    };
  }

  /// Dados de estoque
  Future<Map<String, dynamic>> _getInventoryData(dynamic db, ConsolidatedReportConfig config) async {
    final result = await db.query(
      'inventory_movements',
      where: 'farm = ? AND date BETWEEN ? AND ?',
      whereArgs: [config.farm, config.startDate.millisecondsSinceEpoch, config.endDate.millisecondsSinceEpoch],
    );

    return {
      'totalMovements': result.length,
      'movements': result,
    };
  }

  /// Dados de custos
  Future<Map<String, dynamic>> _getCostData(dynamic db, ConsolidatedReportConfig config) async {
    // Implementar consulta de custos quando o módulo estiver disponível
    return {
      'totalCosts': 0.0,
      'costs': [],
    };
  }

  /// Gera PDF do relatório
  Future<pw.Document> _generatePdfReport(Map<String, dynamic> data, ConsolidatedReportConfig config) async {
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
            _buildHeader(data, font),
            pw.SizedBox(height: 20),
            _buildSummary(data, font),
            pw.SizedBox(height: 20),
            if (config.includePlanting) ..._buildPlantingSection(data, font),
            if (config.includeMonitoring) ..._buildMonitoringSection(data, font),
            if (config.includeApplications) ..._buildApplicationSection(data, font),
            if (config.includeHarvest) ..._buildHarvestSection(data, font),
            if (config.includeInventory) ..._buildInventorySection(data, font),
            if (config.includeCosts) ..._buildCostSection(data, font),
            pw.SizedBox(height: 20),
            _buildFooter(font),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Cabeçalho do relatório
  pw.Widget _buildHeader(Map<String, dynamic> data, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RELATÓRIO CONSOLIDADO DA SAFRA',
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fazenda: ${data['config'].farm} | Safra: ${data['config'].season}',
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Período: ${DateFormat('dd/MM/yyyy').format(data['config'].startDate)} - ${DateFormat('dd/MM/yyyy').format(data['config'].endDate)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Resumo executivo
  pw.Widget _buildSummary(Map<String, dynamic> data, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMO EXECUTIVO',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Este relatório consolidado apresenta uma visão completa das operações realizadas na fazenda durante o período especificado.',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Seção de plantio
  List<pw.Widget> _buildPlantingSection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('planting')) return [];
    
    final planting = data['planting'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'PLANTIO',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de plantios: ${planting['totalPlantings']}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
      pw.Text(
        'Área total plantada: ${planting['totalArea'].toStringAsFixed(2)} hectares',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Seção de monitoramento
  List<pw.Widget> _buildMonitoringSection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('monitoring')) return [];
    
    final monitoring = data['monitoring'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'MONITORAMENTO',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de sessões: ${monitoring['totalSessions']}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Seção de aplicações
  List<pw.Widget> _buildApplicationSection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('applications')) return [];
    
    final applications = data['applications'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'APLICAÇÕES',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de aplicações: ${applications['totalApplications']}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Seção de colheita
  List<pw.Widget> _buildHarvestSection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('harvest')) return [];
    
    final harvest = data['harvest'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'COLHEITA',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de colheitas: ${harvest['totalHarvests']}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Seção de estoque
  List<pw.Widget> _buildInventorySection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('inventory')) return [];
    
    final inventory = data['inventory'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'ESTOQUE',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de movimentações: ${inventory['totalMovements']}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Seção de custos
  List<pw.Widget> _buildCostSection(Map<String, dynamic> data, pw.Font font) {
    if (!data.containsKey('costs')) return [];
    
    final costs = data['costs'] as Map<String, dynamic>;
    
    return [
      pw.SizedBox(height: 16),
      pw.Text(
        'CUSTOS',
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Total de custos: R\$ ${costs['totalCosts'].toStringAsFixed(2)}',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    ];
  }

  /// Rodapé do relatório
  pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Relatório gerado pelo FortSmart Agro',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Data de geração: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
