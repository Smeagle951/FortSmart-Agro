import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/planting.dart';
import '../models/planter_calibration.dart';
import '../models/harvest_loss.dart';
import '../models/pesticide_application.dart';
import '../repositories/planting_repository.dart';
import '../repositories/planter_calibration_repository.dart';
import '../repositories/harvest_loss_repository.dart';
import '../repositories/pesticide_application_repository.dart';
import '../utils/date_formatter.dart';

/// Serviço para geração de relatórios de operações de campo
class FieldOperationsReportService {
  static final FieldOperationsReportService _instance = FieldOperationsReportService._internal();
  
  final PlantingRepository _plantingRepository = PlantingRepository();
  final HarvestLossRepository _harvestLossRepository = HarvestLossRepository();
  final PesticideApplicationRepository _applicationRepository = PesticideApplicationRepository();
  final PlanterCalibrationRepository _calibrationRepository = PlanterCalibrationRepository();
  
  factory FieldOperationsReportService() {
    return _instance;
  }
  
  FieldOperationsReportService._internal();
  
  /// Gera um relatório PDF para um registro de plantio
  Future<String> generatePlantingReport(String plantingId) async {
    final Planting? planting = await _plantingRepository.getById(plantingId);
    if (planting == null) {
      throw Exception('Registro de plantio não encontrado');
    }
    
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Adicionar página ao PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(ttf, 'Relatório de Plantio'),
          _buildPlantingInfo(planting, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(ttf, context),
        ],
      )
    );
    
    return await _savePdf('plantio_${plantingId}.pdf', pdf);
  }
  
  /// Gera um relatório PDF para um registro de perda na colheita
  Future<String> generateHarvestLossReport(String harvestLossId) async {
    final HarvestLoss? harvestLoss = await _harvestLossRepository.getHarvestLossById(harvestLossId);
    if (harvestLoss == null) {
      throw Exception('Registro de perda na colheita não encontrado');
    }
    
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Adicionar página ao PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(ttf, 'Relatório de Perda na Colheita'),
          _buildHarvestLossInfo(harvestLoss, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(ttf, context),
        ],
      )
    );
    
    return await _savePdf('colheita_perda_${harvestLossId}.pdf', pdf);
  }
  
  /// Gera um relatório PDF para um registro de aplicação de defensivo
  Future<String> generateApplicationReport(String applicationId) async {
    final PesticideApplication? application = await _applicationRepository.getPesticideApplicationById(applicationId);
    if (application == null) {
      throw Exception('Registro de aplicação não encontrado');
    }
    
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Adicionar página ao PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(ttf, 'Relatório de Aplicação de Defensivo'),
          _buildApplicationInfo(application, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(ttf, context),
        ],
      )
    );
    
    return await _savePdf('aplicacao_${applicationId}.pdf', pdf);
  }
  
  /// Gera um relatório PDF para um registro de calibração de plantadeira
  Future<String> generateCalibrationReport(String calibrationId) async {
    final PlanterCalibration? calibration = await _calibrationRepository.getById(calibrationId);
    if (calibration == null) {
      throw Exception('Registro de calibração não encontrado');
    }
    
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Adicionar página ao PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(ttf, 'Relatório de Calibração de Plantadeira'),
          _buildCalibrationInfo(calibration, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(ttf, context),
        ],
      )
    );
    
    return await _savePdf('calibracao_${calibrationId}.pdf', pdf);
  }
  
  // Métodos auxiliares para construir as seções do PDF
  
  pw.Widget _buildHeader(pw.Font font, String title) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 10),
          pw.Text(
            'Data do relatório: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 20),
        ],
      ),
    );
  }
  
  pw.Widget _buildPlantingInfo(Planting planting, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informações Gerais', font),
        _buildInfoRow('Cultura', planting.cropName ?? 'Não especificado', font),
        _buildInfoRow('Variedade', planting.varietyName ?? 'Não especificado', font),
        _buildInfoRow('Data de plantio', DateFormat('dd/MM/yyyy').format(planting.plantingDate), font),
        _buildInfoRow('Área plantada', '${planting.area ?? 0.0} ha', font),
        _buildInfoRow('Responsável', planting.responsible, font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Detalhes do Plantio', font),
        _buildInfoRow('Espaçamento entre linhas', '${planting.rowSpacing ?? 0.0} cm', font),
        _buildInfoRow('Plantas por metro', '${planting.plantsPerMeter.toStringAsFixed(2)}', font),
        _buildInfoRow('População estimada', '${planting.estimatedPopulation.toStringAsFixed(0)} plantas/ha', font),
        _buildInfoRow('Profundidade de plantio', '${planting.plantingDepth.toStringAsFixed(1)} cm', font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Insumos Utilizados', font),
        _buildInfoRow('Semente', '${planting.seedQuantity.toStringAsFixed(2)} kg/ha', font),
        if (planting.fertilizerName != null && planting.fertilizerQuantity != null)
          _buildInfoRow('Fertilizante', '${planting.fertilizerName} - ${planting.fertilizerQuantity} kg/ha', font),
        
        if (planting.observations != null && planting.observations!.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          _buildSectionTitle('Observações', font),
          pw.Text(
            planting.observations!,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ],
    );
  }
  
  pw.Widget _buildHarvestLossInfo(HarvestLoss harvestLoss, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informações Gerais', font),
        _buildInfoRow('Cultura', harvestLoss.cropName ?? 'Não especificado', font),
        _buildInfoRow('Data da avaliação', DateFormat('dd/MM/yyyy').format(harvestLoss.evaluationDate), font),
        _buildInfoRow('Responsável', harvestLoss.responsible, font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Dados da Amostragem', font),
        _buildInfoRow('Área da amostra', '${harvestLoss.sampleArea.toStringAsFixed(2)} m²', font),
        _buildInfoRow('Grãos por m²', '${harvestLoss.grainsPerSqm.toStringAsFixed(0)}', font),
        _buildInfoRow('Peso de mil grãos', '${harvestLoss.thousandGrainWeightG.toStringAsFixed(2)} g', font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Resultados', font),
        _buildInfoRow('Perda calculada', '${harvestLoss.lossKgPerHa.toStringAsFixed(2)} kg/ha', font),
        _buildInfoRow('Área total', '${harvestLoss.totalArea.toStringAsFixed(2)} ha', font),
        _buildInfoRow('Perda total estimada', '${(harvestLoss.lossKgPerHa * harvestLoss.totalArea).toStringAsFixed(2)} kg', font),
        if (harvestLoss.pricePerKg != null)
          _buildInfoRow('Perda financeira estimada', 'R\$ ${(harvestLoss.lossKgPerHa * harvestLoss.totalArea * harvestLoss.pricePerKg!).toStringAsFixed(2)}', font),
        
        if (harvestLoss.observations != null && harvestLoss.observations!.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          _buildSectionTitle('Observações', font),
          pw.Text(
            harvestLoss.observations!,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ],
    );
  }
  
  pw.Widget _buildApplicationInfo(PesticideApplication application, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informações Gerais', font),
        _buildInfoRow('Cultura', application.cropName ?? 'Não especificado', font),
        _buildInfoRow('Produto', application.productName ?? 'Não especificado', font),
        _buildInfoRow('Data da aplicação', DateFormat('dd/MM/yyyy').format(application.date), font),
        _buildInfoRow('Responsável', application.responsible, font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Detalhes da Aplicação', font),
        _buildInfoRow('Tipo de aplicação', application.applicationType, font),
        _buildInfoRow('Dose por hectare', '${application.dosePerHa.toStringAsFixed(2)} ${application.doseUnit ?? "L/ha"}', font),
        _buildInfoRow('Volume de calda', '${application.caldaVolumePerHa.toStringAsFixed(2)} L/ha', font),
        _buildInfoRow('Área total', '${application.totalArea ?? 0.0} ha', font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Totais Calculados', font),
        _buildInfoRow('Volume total de calda', '${application.totalCaldaVolume.toStringAsFixed(2)} L', font),
        _buildInfoRow('Quantidade total de produto', '${application.totalProductAmount.toStringAsFixed(2)} ${application.doseUnit ?? "L"}', font),
        
        if (application.temperature != null || application.humidity != null) ...[
          pw.SizedBox(height: 15),
          _buildSectionTitle('Condições Climáticas', font),
          if (application.temperature != null)
            _buildInfoRow('Temperatura', '${application.temperature}°C', font),
          if (application.humidity != null)
            _buildInfoRow('Umidade relativa', '${application.humidity}%', font),
        ],
        
        if (application.observations != null && application.observations!.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          _buildSectionTitle('Observações', font),
          pw.Text(
            application.observations!,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ],
    );
  }
  
  pw.Widget _buildCalibrationInfo(PlanterCalibration calibration, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informações Gerais', font),
        _buildInfoRow('Cultura', calibration.cropName ?? 'Não especificado', font),
        _buildInfoRow('Máquina', calibration.machineName, font),
        _buildInfoRow('Data da calibração', DateFormat('dd/MM/yyyy').format(calibration.calibrationDate), font),
        _buildInfoRow('Responsável', calibration.responsible, font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Parâmetros de Calibração', font),
        _buildInfoRow('Espaçamento entre linhas', '${calibration.rowSpacing} cm', font),
        _buildInfoRow('Plantas desejadas por metro', '${calibration.desiredPlantsPerMeter.toStringAsFixed(2)}', font),
        _buildInfoRow('Taxa de germinação', '${calibration.germinationRateValue.toStringAsFixed(1)}%', font),
        _buildInfoRow('Fator de viabilidade', '${calibration.viabilityFactorValue.toStringAsFixed(1)}%', font),
        
        pw.SizedBox(height: 15),
        _buildSectionTitle('Resultados da Calibração', font),
        _buildInfoRow('Sementes por metro', '${calibration.seedsPerMeter.toStringAsFixed(2)}', font),
        _buildInfoRow('População estimada', '${calibration.estimatedPopulation.toStringAsFixed(0)} plantas/ha', font),
        if (calibration.discType != null && calibration.discType!.isNotEmpty)
          _buildInfoRow('Disco utilizado', calibration.discType!, font),
        
        if (calibration.observations!.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          _buildSectionTitle('Observações', font),
          pw.Text(
            calibration.observations,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ],
    );
  }
  
  pw.Widget _buildSectionTitle(String title, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: font,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
  
  pw.Widget _buildInfoRow(String label, dynamic value, pw.Font font) {
    // Garantir que o valor seja uma string, mesmo que seja nulo
    final String valueStr = value?.toString() ?? 'Não informado';
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 150,
            child: pw.Text(
              label + ':',
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              valueStr,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildFooter(pw.Font font, pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'FORTSMART - Sistema de Gestão Agrícola',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.Text(
              'Página ${context.page} de ${context.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Future<String> _savePdf(String fileName, pw.Document pdf) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
