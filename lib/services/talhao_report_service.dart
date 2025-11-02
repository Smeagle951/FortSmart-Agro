import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/talhao_model.dart';
import '../services/talhao_integration_service.dart';

/// Serviço para geração e exportação de relatórios de talhões
class TalhaoReportService {
  static final TalhaoReportService _instance = TalhaoReportService._internal();
  factory TalhaoReportService() => _instance;
  TalhaoReportService._internal();

  final TalhaoIntegrationService _integrationService = TalhaoIntegrationService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Gera um relatório PDF com a lista de talhões
  Future<File> gerarRelatorioPDF({
    String? titulo,
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    // Buscar talhões com filtros usando o serviço de integração
    final talhoes = await _integrationService.getTalhoes(
      safraFiltro: safraFiltro,
      culturaFiltro: culturaFiltro,
    );

    // Criar documento PDF
    final pdf = pw.Document();
    
    // Título do relatório
    final reportTitle = titulo ?? 'Relatório de Talhões';
    final reportDate = _dateFormat.format(DateTime.now());
    
    // Adicionar página de capa
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Data de geração: $reportDate',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Total de talhões: ${talhoes.length}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Área total: ${_calcularAreaTotal(talhoes).toStringAsFixed(2)} ha',
                  style: const pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Adicionar página com tabela de talhões
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Lista de Talhões',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Cabeçalho da tabela
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'ID',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Nome',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Safra Atual',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Área (ha)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Cultura',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Linhas de dados
                  ...talhoes.map((talhao) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(talhao.id.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(talhao.name ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(talhao.safraAtual?.safra ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(talhao.area.toStringAsFixed(2)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(talhao.safraAtual?.culturaNome ?? ''),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // Adicionar página com gráfico de área por cultura
    if (talhoes.isNotEmpty) {
      final dados = await _integrationService.getDadosConsolidados(
  safraFiltro: safraFiltro,
  culturaFiltro: culturaFiltro,
);
final areaPorCultura = dados['areaPorCultura'] as Map<String, dynamic>? ?? {};
      
      if (areaPorCultura.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Área por Cultura (ha)',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      // Cabeçalho da tabela
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              'Cultura',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              'Área (ha)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Linhas de dados
                      ...areaPorCultura.entries.map((entry) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(entry.key),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(entry.value.toStringAsFixed(2)),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
    }
    
    // Salvar o PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/talhoes_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Gera um relatório Excel com a lista de talhões
  Future<File> gerarRelatorioExcel({
    String? titulo,
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    // Buscar talhões com filtros usando o serviço de integração
    final talhoes = await _integrationService.getTalhoes(
      safraFiltro: safraFiltro,
      culturaFiltro: culturaFiltro,
    );

    // Criar planilha Excel
    final excel = Excel.createExcel();
    
    // Criar planilha de resumo
    final sheetResumo = excel['Resumo'];
    
    // Título do relatório
    final reportTitle = titulo ?? 'Relatório de Talhões';
    final reportDate = _dateFormat.format(DateTime.now());
    
    // Adicionar título e data
    sheetResumo.cell(CellIndex.indexByString('A1')).value = reportTitle;
    sheetResumo.cell(CellIndex.indexByString('A2')).value = 'Data de geração: $reportDate';
    
    // Adicionar informações gerais
    sheetResumo.cell(CellIndex.indexByString('A4')).value = 'Total de talhões:';
    sheetResumo.cell(CellIndex.indexByString('B4')).value = talhoes.length;
    
    sheetResumo.cell(CellIndex.indexByString('A5')).value = 'Área total (ha):';
    sheetResumo.cell(CellIndex.indexByString('B5')).value = _calcularAreaTotal(talhoes);
    
    // Criar planilha de talhões
    final sheetTalhoes = excel['Talhões'];
    
    // Adicionar cabeçalho
    sheetTalhoes.cell(CellIndex.indexByString('A1')).value = 'ID';
    sheetTalhoes.cell(CellIndex.indexByString('B1')).value = 'Nome';
    sheetTalhoes.cell(CellIndex.indexByString('C1')).value = 'Safra Atual';
    sheetTalhoes.cell(CellIndex.indexByString('D1')).value = 'Área (ha)';
    sheetTalhoes.cell(CellIndex.indexByString('E1')).value = 'Cultura';
    sheetTalhoes.cell(CellIndex.indexByString('F1')).value = 'Data de Criação';
    sheetTalhoes.cell(CellIndex.indexByString('G1')).value = 'Sincronizado';
    
    // Adicionar dados dos talhões
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      final row = i + 2; // +2 porque a linha 1 é o cabeçalho
      
      sheetTalhoes.cell(CellIndex.indexByString('A$row')).value = talhao.id;
      sheetTalhoes.cell(CellIndex.indexByString('B$row')).value = talhao.name;
      sheetTalhoes.cell(CellIndex.indexByString('C$row')).value = talhao.safraAtual?.safra ?? '';
      sheetTalhoes.cell(CellIndex.indexByString('D$row')).value = talhao.area;
      sheetTalhoes.cell(CellIndex.indexByString('E$row')).value = talhao.safraAtual?.culturaNome ?? '';
      sheetTalhoes.cell(CellIndex.indexByString('F$row')).value = _dateFormat.format(talhao.createdAt);
      sheetTalhoes.cell(CellIndex.indexByString('G$row')).value = talhao.syncStatus == 1 ? 'Sim' : 'Não';
    }
    
    // Criar planilha de área por cultura
    final dados = await _integrationService.getDadosConsolidados(
      safraFiltro: safraFiltro,
      culturaFiltro: culturaFiltro,
    );
    
    final areaPorCultura = dados['areaPorCultura'] as Map<String, dynamic>? ?? {};
    
    if (areaPorCultura.isNotEmpty) {
      final sheetCulturas = excel['Área por Cultura'];
      
      // Adicionar cabeçalho
      sheetCulturas.cell(CellIndex.indexByString('A1')).value = 'Cultura';
      sheetCulturas.cell(CellIndex.indexByString('B1')).value = 'Área (ha)';
      
      // Adicionar dados de área por cultura
      int row = 2;
      for (final entry in areaPorCultura.entries) {
        sheetCulturas.cell(CellIndex.indexByString('A$row')).value = entry.key;
        sheetCulturas.cell(CellIndex.indexByString('B$row')).value = entry.value;
        row++;
      }
    }
    
    // Criar planilha de histórico de safras
    final sheetHistorico = excel['Histórico de Safras'];
    
    // Adicionar cabeçalho
    sheetHistorico.cell(CellIndex.indexByString('A1')).value = 'Talhão';
    sheetHistorico.cell(CellIndex.indexByString('B1')).value = 'Safra';
    sheetHistorico.cell(CellIndex.indexByString('C1')).value = 'Cultura';
    sheetHistorico.cell(CellIndex.indexByString('D1')).value = 'Data de Registro';
    
    // Adicionar dados de histórico de safras
    int row = 2;
    for (final talhao in talhoes) {
      for (final safra in talhao.safras) {
        sheetHistorico.cell(CellIndex.indexByString('A$row')).value = talhao.name;
        sheetHistorico.cell(CellIndex.indexByString('B$row')).value = safra.safra;
        sheetHistorico.cell(CellIndex.indexByString('C$row')).value = safra.culturaNome;
        sheetHistorico.cell(CellIndex.indexByString('D$row')).value = _dateFormat.format(safra.dataCriacao);
        row++;
      }
    }
    
    // Salvar o Excel
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/talhoes_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file;
  }

  /// Compartilha um relatório PDF
  Future<void> compartilharRelatorioPDF({
    String? titulo,
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    final file = await gerarRelatorioPDF(
      titulo: titulo,
      safraFiltro: safraFiltro,
      culturaFiltro: culturaFiltro,
    );
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Relatório de Talhões',
    );
  }

  /// Compartilha um relatório Excel
  Future<void> compartilharRelatorioExcel({
    String? titulo,
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    final file = await gerarRelatorioExcel(
      titulo: titulo,
      safraFiltro: safraFiltro,
      culturaFiltro: culturaFiltro,
    );
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Relatório de Talhões',
    );
  }

  /// Calcula a área total de uma lista de talhões
  double _calcularAreaTotal(List<TalhaoModel> talhoes) {
    return talhoes.fold<double>(0.0, (total, talhao) => total + talhao.area);
  }
}
