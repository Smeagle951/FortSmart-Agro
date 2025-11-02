import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

import '../models/inventory_report_model.dart';
import '../../../modules/inventory/models/inventory_product_model.dart';
import '../../../modules/inventory/services/inventory_service.dart';

/// Serviço para geração de relatórios de estoque
class InventoryReportService {
  final InventoryService _inventoryService;

  InventoryReportService(this._inventoryService);

  /// Gera um relatório de conferência de estoque atual em PDF
  Future<File> generateStockReportPdf({
    required String farmName,
    required String responsiblePerson,
    DateTime? startDate,
    DateTime? endDate,
    String? productName,
    String? productType,
    String? supplier,
    String? batchNumber,
  }) async {
    // Obter produtos do estoque
    final products = await _inventoryService.getAllProducts();
    
    // Criar modelo de relatório
    final reportModel = InventoryStockReportModel(
      startDate: startDate,
      endDate: endDate,
      productName: productName,
      productType: productType,
      supplier: supplier,
      batchNumber: batchNumber,
      products: products,
      farmName: farmName,
      responsiblePerson: responsiblePerson,
    );
    
    // Filtrar produtos
    final filteredProducts = reportModel.filteredProducts;
    
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
            _buildProductsTable(filteredProducts),
            _buildFooter(reportModel),
          ];
        },
      ),
    );
    
    // Salvar o PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_estoque_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Exporta o relatório de estoque para Excel
  Future<File> exportStockReportToExcel({
    required String farmName,
    required String responsiblePerson,
    DateTime? startDate,
    DateTime? endDate,
    String? productName,
    String? productType,
    String? supplier,
    String? batchNumber,
  }) async {
    // Obter produtos do estoque
    final products = await _inventoryService.getAllProducts();
    
    // Criar modelo de relatório
    final reportModel = InventoryStockReportModel(
      startDate: startDate,
      endDate: endDate,
      productName: productName,
      productType: productType,
      supplier: supplier,
      batchNumber: batchNumber,
      products: products,
      farmName: farmName,
      responsiblePerson: responsiblePerson,
    );
    
    // Filtrar produtos
    final filteredProducts = reportModel.filteredProducts;
    
    // Criar arquivo Excel
    final excel = Excel.createExcel();
    final sheet = excel['Relatório de Estoque'];
    
    // Adicionar cabeçalho
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Relatório de Estoque - Conferência Atual';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Fazenda: ${reportModel.farmName}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(reportModel.generationDate)}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = 'Responsável: ${reportModel.responsiblePerson}';
    
    // Adicionar cabeçalhos da tabela
    final headers = ['Nome do Produto', 'Tipo', 'Unidade', 'Quantidade Atual', 'Vencimento', 'Lote', 'Fornecedor', 'Custo Unitário'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5)).value = headers[i];
    }
    
    // Adicionar dados dos produtos
    for (int i = 0; i < filteredProducts.length; i++) {
      final product = filteredProducts[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 6)).value = product.name;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 6)).value = product.productClass.toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 6)).value = product.unit;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 6)).value = product.quantity;
      // Formatação de data de expiração
      // Nota: Embora o modelo defina expirationDate como não-nulo, o código trata como possível nulo
      // Usando try-catch para evitar erros em tempo de execução
      try {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 6)).value = 
            DateFormat('dd/MM/yyyy').format(product.expirationDate);
      } catch (e) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 6)).value = 'N/A';
      }
      // Número do lote (não-nulo por definição do modelo)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 6)).value = 
          product.batchNumber.isNotEmpty ? product.batchNumber : 'N/A';
      // Fornecedor (possivelmente nulo)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 6)).value = 
          product.supplier?.isNotEmpty == true ? product.supplier : 'N/A';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 6)).value = product.pricePerUnit;
    }
    
    // Salvar o arquivo Excel
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_estoque_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    
    return file;
  }

  // Métodos privados para construir as partes do PDF
  
  pw.Widget _buildHeader(InventoryStockReportModel reportModel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Relatório de Estoque - Conferência Atual',
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
  
  pw.Widget _buildFilters(InventoryStockReportModel reportModel) {
    final List<String> filters = [];
    
    if (reportModel.startDate != null && reportModel.endDate != null) {
      filters.add('Período de vencimento: ${DateFormat('dd/MM/yyyy').format(reportModel.startDate!)} a ${DateFormat('dd/MM/yyyy').format(reportModel.endDate!)}');
    } else if (reportModel.startDate != null) {
      filters.add('Vencimento a partir de: ${DateFormat('dd/MM/yyyy').format(reportModel.startDate!)}');
    } else if (reportModel.endDate != null) {
      filters.add('Vencimento até: ${DateFormat('dd/MM/yyyy').format(reportModel.endDate!)}');
    }
    
    if (reportModel.productName != null && reportModel.productName!.isNotEmpty) {
      filters.add('Produto: ${reportModel.productName}');
    }
    
    if (reportModel.productType != null && reportModel.productType!.isNotEmpty) {
      filters.add('Tipo: ${reportModel.productType}');
    }
    
    if (reportModel.supplier != null && reportModel.supplier!.isNotEmpty) {
      filters.add('Fornecedor: ${reportModel.supplier}');
    }
    
    if (reportModel.batchNumber != null && reportModel.batchNumber!.isNotEmpty) {
      filters.add('Lote: ${reportModel.batchNumber}');
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
  
  pw.Widget _buildProductsTable(List<InventoryProductModel> products) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Nome do Produto
        1: const pw.FlexColumnWidth(2), // Tipo
        2: const pw.FlexColumnWidth(1), // Unidade
        3: const pw.FlexColumnWidth(1.5), // Quantidade
        4: const pw.FlexColumnWidth(2), // Vencimento
        5: const pw.FlexColumnWidth(2), // Lote
        6: const pw.FlexColumnWidth(2), // Fornecedor
        7: const pw.FlexColumnWidth(1.5), // Custo
      },
      children: [
        // Cabeçalho da tabela
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Nome do Produto', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Unidade', isHeader: true),
            _buildTableCell('Quantidade', isHeader: true),
            _buildTableCell('Vencimento', isHeader: true),
            _buildTableCell('Lote', isHeader: true),
            _buildTableCell('Fornecedor', isHeader: true),
            _buildTableCell('Custo Unit.', isHeader: true),
          ],
        ),
        // Dados dos produtos
        ...products.map((product) => pw.TableRow(
          children: [
            _buildTableCell(product.name),
            _buildTableCell(product.productClass.toString()),
            _buildTableCell(product.unit),
            _buildTableCell(product.quantity.toString()),
            _buildTableCell(product.expirationDate != null
              ? DateFormat('dd/MM/yyyy').format(product.expirationDate)
              : 'N/A'),
            _buildTableCell(product.batchNumber ?? 'N/A'),
            _buildTableCell(product.supplier ?? 'N/A'),
            _buildTableCell('R\$ ${(product.pricePerUnit ?? 0.0).toStringAsFixed(2)}'),
          ],
        )),
      ],
    );
  }
  
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
  
  pw.Widget _buildFooter(InventoryStockReportModel reportModel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Valor total do estoque: R\$ ${reportModel.totalStockValue.toStringAsFixed(2)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Responsável pela conferência: ${reportModel.responsiblePerson}'),
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
