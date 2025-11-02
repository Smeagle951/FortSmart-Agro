import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../models/product_class_model.dart';
import 'inventory_service.dart';

class InventoryReportService {
  final InventoryService _inventoryService = InventoryService();
  
  // Formatadores
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _quantityFormat = NumberFormat.decimalPattern('pt_BR');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  // Gerar relatório de histórico de transações para um produto
  Future<File> generateProductHistoryReport(InventoryProductModel product) async {
    // Obter transações do produto
    final transactions = await _inventoryService.getProductTransactions(product.id);
    
    // Criar documento PDF
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Tema do documento
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
      italic: ttf,
    );
    
    // Adicionar página de capa
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Relatório de Histórico de Produto',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  product.name,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Classe: ${ProductClassHelper.getName(product.productClass)}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Quantidade atual: ${_quantityFormat.format(product.quantity)} ${product.unit}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Data do relatório: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Adicionar página com tabela de transações
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Histórico de Transações'),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Produto: ${product.name}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Total de transações: ${transactions.length}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 15),
              _buildTransactionsTable(transactions, product.unit),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumo das movimentações:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildSummaryTable(transactions, product.unit),
            ],
          );
        },
      ),
    );
    
    // Salvar o arquivo PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/historico_${product.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  // Construir tabela de transações
  pw.Widget _buildTransactionsTable(List<InventoryTransactionModel> transactions, String unit) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        // Cabeçalho da tabela
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Data', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Quantidade', isHeader: true),
            _buildTableCell('Observações', isHeader: true),
          ],
        ),
        // Linhas de dados
        ...transactions.map((transaction) {
          String typeText;
          
          switch (transaction.type) {
            case TransactionType.entry:
              typeText = 'Entrada';
              break;
            case TransactionType.manual:
              typeText = 'Saída Manual';
              break;
            case TransactionType.application:
              typeText = 'Aplicação';
              break;
            case TransactionType.adjustment:
              typeText = 'Ajuste';
              break;
            default:
              typeText = 'Desconhecido';
          }
          
          String notes = '';
          if (transaction.notes != null && transaction.notes!.isNotEmpty) {
            notes = transaction.notes!;
          }
          if (transaction.applicationId != null && transaction.applicationId!.isNotEmpty) {
            if (notes.isNotEmpty) notes += '\n';
            notes += 'ID Aplicação: ${transaction.applicationId}';
          }
          
          return pw.TableRow(
            children: [
              _buildTableCell(_dateFormat.format(transaction.date)),
              _buildTableCell(typeText),
              _buildTableCell(
                '${transaction.isEntry ? '+' : '-'} ${_quantityFormat.format(transaction.quantity)} $unit',
              ),
              _buildTableCell(notes.isEmpty ? '-' : notes),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  // Construir tabela de resumo
  pw.Widget _buildSummaryTable(List<InventoryTransactionModel> transactions, String unit) {
    // Calcular totais
    double totalEntries = 0;
    double totalExits = 0;
    int entryCount = 0;
    int exitCount = 0;
    
    for (var transaction in transactions) {
      if (transaction.isEntry) {
        totalEntries += transaction.quantity;
        entryCount++;
      } else {
        totalExits += transaction.quantity;
        exitCount++;
      }
    }
    
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Quantidade', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Entradas
        pw.TableRow(
          children: [
            _buildTableCell('Entradas'),
            _buildTableCell('$entryCount'),
            _buildTableCell('${_quantityFormat.format(totalEntries)} $unit'),
          ],
        ),
        // Saídas
        pw.TableRow(
          children: [
            _buildTableCell('Saídas'),
            _buildTableCell('$exitCount'),
            _buildTableCell('${_quantityFormat.format(totalExits)} $unit'),
          ],
        ),
        // Balanço
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _buildTableCell('Balanço', isBold: true),
            _buildTableCell('${transactions.length}', isBold: true),
            _buildTableCell('${_quantityFormat.format(totalEntries - totalExits)} $unit', isBold: true),
          ],
        ),
      ],
    );
  }
  
  // Método auxiliar para criar células da tabela
  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
  
  // Gerar relatório de estoque atual
  Future<File> generateCurrentStockReport(List<InventoryProductModel> products) async {
    // Criar documento PDF
    final pdf = pw.Document();
    
    // Carregar fonte
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Tema do documento
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
      italic: ttf,
    );
    
    // Agrupar produtos por classe
    final Map<ProductClass, List<InventoryProductModel>> productsByClass = {};
    
    for (var product in products) {
      if (!productsByClass.containsKey(product.productClass)) {
        productsByClass[product.productClass] = [];
      }
      productsByClass[product.productClass]!.add(product);
    }
    
    // Adicionar página de capa
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Relatório de Estoque',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'FortSmart Agro',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total de produtos: ${products.length}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Data do relatório: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Adicionar páginas para cada classe de produto
    productsByClass.forEach((productClass, classProducts) {
      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Classe: ${ProductClassHelper.getName(productClass)}'),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total de produtos: ${classProducts.length}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 15),
                _buildProductsTable(classProducts),
              ],
            );
          },
        ),
      );
    });
    
    // Salvar o arquivo PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/estoque_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  // Construir tabela de produtos
  pw.Widget _buildProductsTable(List<InventoryProductModel> products) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Cabeçalho da tabela
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Nome', isHeader: true),
            _buildTableCell('Quantidade', isHeader: true),
            _buildTableCell('Unidade', isHeader: true),
            _buildTableCell('Vencimento', isHeader: true),
          ],
        ),
        // Linhas de dados
        ...products.map((product) {
          String expirationDate = product.expirationDate != null
              ? _dateFormat.format(product.expirationDate!)
              : 'N/A';
          
          return pw.TableRow(
            children: [
              _buildTableCell(product.name),
              _buildTableCell(_quantityFormat.format(product.quantity)),
              _buildTableCell(product.unit),
              _buildTableCell(expirationDate),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  // Exportar para Excel
  Future<File> exportProductHistoryToExcel(InventoryProductModel product) async {
    // TODO: Implementar exportação para Excel
    // Esta é uma implementação básica que cria um arquivo CSV
    final transactions = await _inventoryService.getProductTransactions(product.id);
    
    // Criar conteúdo CSV
    final StringBuffer csv = StringBuffer();
    
    // Cabeçalho
    csv.writeln('Data,Tipo,Quantidade,Observações');
    
    // Linhas de dados
    for (var transaction in transactions) {
      String typeText;
      
      switch (transaction.type) {
        case TransactionType.entry:
          typeText = 'Entrada';
          break;
        case TransactionType.manual:
          typeText = 'Saída Manual';
          break;
        case TransactionType.application:
          typeText = 'Aplicação';
          break;
        case TransactionType.adjustment:
          typeText = 'Ajuste';
          break;
        default:
          typeText = 'Desconhecido';
      }
      
      String notes = '';
      if (transaction.notes != null && transaction.notes!.isNotEmpty) {
        notes = transaction.notes!.replaceAll(',', ';');
      }
      
      csv.writeln(
        '${_dateFormat.format(transaction.date)},$typeText,${transaction.isEntry ? '+' : '-'}${transaction.quantity},${notes.isEmpty ? '-' : notes}',
      );
    }
    
    // Salvar o arquivo CSV
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/historico_${product.id}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv.toString());
    
    return file;
  }
}
