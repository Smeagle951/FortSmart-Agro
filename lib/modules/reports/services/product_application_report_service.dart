import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

import '../models/product_application_report_model.dart';
import '../../../modules/product_application/models/product_application_model.dart' as models;
import '../../../modules/product_application/services/product_application_service.dart';

/// Serviço para geração de relatórios de aplicação de produtos
class ProductApplicationReportService {
  final ProductApplicationService _applicationService;

  ProductApplicationReportService(this._applicationService);

  /// Gera um relatório de gasto de produtos por aplicação em PDF
  Future<File> generateApplicationReportPdf({
    required String farmName,
    DateTime? startDate,
    DateTime? endDate,
    String? cropName,
    String? fieldName,
    String? productName,
    String? responsiblePerson,
  }) async {
    // Obter aplicações
    final applications = await _applicationService.getAllApplications();
    
    // Criar modelo de relatório
    final reportModel = ProductApplicationReportModel(
      startDate: startDate,
      endDate: endDate,
      cropName: cropName,
      fieldName: fieldName,
      productName: productName,
      responsiblePerson: responsiblePerson,
      applications: applications,
      farmName: farmName,
    );
    
    // Filtrar aplicações
    final filteredApplications = reportModel.filteredApplications;
    
    // Criar documento PDF
    final pdf = pw.Document();
    
    // Adicionar página ao PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(reportModel),
            _buildFilters(reportModel),
            _buildApplicationsTable(filteredApplications),
            _buildFooter(reportModel),
          ];
        },
      ),
    );
    
    // Salvar o PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_aplicacao_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Exporta o relatório de aplicação para Excel
  Future<File> exportApplicationReportToExcel({
    required String farmName,
    DateTime? startDate,
    DateTime? endDate,
    String? cropName,
    String? fieldName,
    String? productName,
    String? responsiblePerson,
  }) async {
    // Obter aplicações
    final applications = await _applicationService.getAllApplications();
    
    // Criar modelo de relatório
    final reportModel = ProductApplicationReportModel(
      startDate: startDate,
      endDate: endDate,
      cropName: cropName,
      fieldName: fieldName,
      productName: productName,
      responsiblePerson: responsiblePerson,
      applications: applications,
      farmName: farmName,
    );
    
    // Filtrar aplicações
    final filteredApplications = reportModel.filteredApplications;
    
    // Criar arquivo Excel
    final excel = Excel.createExcel();
    final sheet = excel['Relatório de Aplicações'];
    
    // Adicionar cabeçalho
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Relatório de Gasto de Estoque por Aplicação';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Fazenda: ${reportModel.farmName}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(reportModel.generationDate)}';
    
    // Adicionar cabeçalhos da tabela
    final headers = [
      'Nome do Produto', 'Tipo', 'Dose por Hectare', 'Quantidade Total', 
      'Tipo de Aplicação', 'Volume da Calda', 'Nº de Voos/Tanques',
      'Data da Aplicação', 'Talhão', 'Cultura', 'Responsável Técnico'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5)).value = headers[i];
    }
    
    // Adicionar dados das aplicações
    int rowIndex = 6;
    for (final application in filteredApplications) {
      if (application.products != null) {
        for (final product in application.products!) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = product.productName ?? 'Sem nome';
          // Tipo de produto não disponível no modelo ApplicationProductModel
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 'N/A';
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = '${product.dosePerHectare ?? 0} ${product.unitOfMeasure ?? 'un'}';
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = '${product.totalDose ?? 0} ${product.unitOfMeasure ?? 'un'}';
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = application.applicationType;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = application.totalSyrupVolume;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = application.numberOfTanks;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = application.applicationDate != null ? DateFormat('dd/MM/yyyy').format(application.applicationDate!) : 'Data não informada';
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = application.plotName;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = application.cropName;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = application.responsibleName;
          
          rowIndex++;
        }
      }
    }
    
    // Salvar o arquivo Excel
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_aplicacao_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    
    return file;
  }

  // Métodos privados para construir as partes do PDF
  
  pw.Widget _buildHeader(ProductApplicationReportModel reportModel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Relatório de Gasto de Estoque por Aplicação',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Fazenda: ${reportModel.farmName}'),
        pw.Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(reportModel.generationDate)}'),
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  pw.Widget _buildFilters(ProductApplicationReportModel reportModel) {
    final List<String> filters = [];
    
    if (reportModel.startDate != null && reportModel.endDate != null) {
      filters.add('Período: ${DateFormat('dd/MM/yyyy').format(reportModel.startDate!)} a ${DateFormat('dd/MM/yyyy').format(reportModel.endDate!)}');
    } else if (reportModel.startDate != null) {
      filters.add('A partir de: ${DateFormat('dd/MM/yyyy').format(reportModel.startDate!)}');
    } else if (reportModel.endDate != null) {
      filters.add('Até: ${DateFormat('dd/MM/yyyy').format(reportModel.endDate!)}');
    }
    
    if (reportModel.cropName != null && reportModel.cropName!.isNotEmpty) {
      filters.add('Cultura: ${reportModel.cropName}');
    }
    
    if (reportModel.fieldName != null && reportModel.fieldName!.isNotEmpty) {
      filters.add('Talhão: ${reportModel.fieldName}');
    }
    
    if (reportModel.productName != null && reportModel.productName!.isNotEmpty) {
      filters.add('Produto: ${reportModel.productName}');
    }
    
    if (reportModel.responsiblePerson != null && reportModel.responsiblePerson!.isNotEmpty) {
      filters.add('Responsável: ${reportModel.responsiblePerson}');
    }
    
    if (filters.isEmpty) {
      return pw.SizedBox();
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Filtros aplicados:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...filters.map((filter) => pw.Text('• $filter')),
        pw.SizedBox(height: 16),
      ],
    );
  }
  
  pw.Widget _buildApplicationsTable(List<models.ProductApplicationModel> applications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < applications.length; i++) ...[
          _buildApplicationSection(applications[i], i + 1),
          if (i < applications.length - 1) pw.SizedBox(height: 20),
        ],
      ],
    );
  }
  
  pw.Widget _buildApplicationSection(models.ProductApplicationModel application, int index) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Aplicação #$index - ${application.applicationDate != null ? DateFormat('dd/MM/yyyy').format(application.applicationDate!) : 'Data não informada'}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildTableHeader('Talhão: ${application.plotName}'),
        _buildTableHeader('Cultura: ${application.cropName}'),
        pw.Text('Tipo de Aplicação: ${application.applicationType == models.ApplicationType.foliar ? 'Foliar' : application.applicationType == models.ApplicationType.solo ? 'Solo' : application.applicationType == models.ApplicationType.semente ? 'Semente' : 'Outro'}'),
        _buildTableHeader('Responsável: ${application.responsibleName}'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Nome do Produto
            1: const pw.FlexColumnWidth(2), // Tipo
            2: const pw.FlexColumnWidth(2), // Dose por Hectare
            3: const pw.FlexColumnWidth(2), // Quantidade Total
            4: const pw.FlexColumnWidth(2), // Custo
          },
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Nome do Produto', isHeader: true),
                _buildTableCell('Tipo', isHeader: true),
                _buildTableCell('Dose/ha', isHeader: true),
                _buildTableCell('Quantidade', isHeader: true),
                _buildTableCell('Custo Total', isHeader: true),
              ],
            ),
            // Dados dos produtos
            ...(application.products ?? []).map((product) => pw.TableRow(
              children: [
                _buildTableCell(product.productName ?? 'Sem nome'),
                _buildTableCell('N/A'), // Tipo de produto não disponível no modelo
                _buildTableCell('${product.dosePerHectare ?? 0} ${product.unitOfMeasure ?? 'un'}'),
                _buildTableCell('${product.totalDose ?? 0} ${product.unitOfMeasure ?? 'un'}'),
                _buildTableCell('R\$ ${((product.totalDose ?? 0) * 0.0).toStringAsFixed(2)}'), // Preço não disponível no modelo
              ],
            )),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Volume da Calda: ${application.totalSyrupVolume ?? 0} L',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
        pw.Text(
          'Nº de ${(application.applicationType ?? models.ApplicationType.solo) == models.ApplicationType.foliar ? 'Aplicações' : 'Tanques'}: ${application.numberOfTanks ?? 0}',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }
  
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  pw.Widget _buildTableHeader(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    );
  }
  
  pw.Widget _buildFooter(ProductApplicationReportModel reportModel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Custo total das aplicações: R\$ ${reportModel.totalApplicationCost.toStringAsFixed(2)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 40),
        pw.Center(
          child: pw.Text(
            'FortSmart Agro - Sistema de Gestão Agrícola',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    );
  }
}
