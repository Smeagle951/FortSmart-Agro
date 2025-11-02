import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/logger.dart';

class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  factory PdfReportService() => _instance;
  PdfReportService._internal();

  /// Gera relatório premium de aplicações em PDF
  Future<String> gerarRelatorioPremium({
    required List<Map<String, dynamic>> aplicacoes,
    required Map<String, dynamic> resumoCustos,
    required List<Map<String, dynamic>> custosPorTalhao,
    required List<Map<String, dynamic>> produtosMaisUtilizados,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoFiltro,
  }) async {
    try {
      Logger.info('📄 Gerando relatório premium PDF...');

      final pdf = pw.Document();
      
      // Página 1: Capa
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildCapa(context, dataInicio, dataFim),
        ),
      );

      // Página 2: Resumo Executivo
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildResumoExecutivo(context, resumoCustos),
        ),
      );

      // Páginas 3+: Aplicações Detalhadas
      for (int i = 0; i < aplicacoes.length; i += 2) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => _buildAplicacoesDetalhadas(
              context, 
              aplicacoes.skip(i).take(2).toList(),
            ),
          ),
        );
      }

      // Página: Custos por Talhão
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildCustosPorTalhao(context, custosPorTalhao),
        ),
      );

      // Página: Produtos Mais Utilizados
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildProdutosMaisUtilizados(context, produtosMaisUtilizados),
        ),
      );

      // Página: Assinaturas
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildAssinaturas(context),
        ),
      );

      // Salvar PDF
      final output = await getTemporaryDirectory();
      final fileName = 'Relatorio_Aplicacoes_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      Logger.info('✅ Relatório PDF gerado com sucesso: ${file.path}');
      return file.path;
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório PDF: $e');
      rethrow;
    }
  }

  /// Constrói a capa do relatório
  pw.Widget _buildCapa(pw.Context context, DateTime dataInicio, DateTime dataFim) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.green, PdfColors.lightGreen],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'FORT SMART AGRO',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'RELATÓRIO PREMIUM DE APLICAÇÕES',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Período: ${_formatDate(dataInicio)} a ${_formatDate(dataFim)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Gerado em: ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o resumo executivo
  pw.Widget _buildResumoExecutivo(pw.Context context, Map<String, dynamic> resumoCustos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: pw.Text(
            'RESUMO EXECUTIVO',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        
        // Métricas principais
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard(
                'Custo Total',
                'R\$ ${(resumoCustos['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                PdfColors.green,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildMetricCard(
                'Total de Aplicações',
                '${resumoCustos['totalAplicacoes'] ?? 0}',
                PdfColors.blue,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard(
                'Custo Médio/ha',
                'R\$ ${(resumoCustos['custoPorHectare'] ?? 0.0).toStringAsFixed(2)}',
                PdfColors.orange,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildMetricCard(
                'Área Total',
                '${(resumoCustos['areaTotal'] ?? 0.0).toStringAsFixed(2)} ha',
                PdfColors.purple,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        
        // Descrição
        pw.Text(
          'Este relatório apresenta um resumo completo das aplicações realizadas no período especificado, '
          'incluindo custos detalhados, produtos utilizados e análise por talhão. '
          'Os dados foram coletados automaticamente do sistema de gestão de custos FortSmart Agro.',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Constrói aplicações detalhadas
  pw.Widget _buildAplicacoesDetalhadas(pw.Context context, List<Map<String, dynamic>> aplicacoes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: pw.Text(
            'APLICAÇÕES DETALHADAS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        
        ...aplicacoes.map((aplicacao) => _buildAplicacaoCard(context, aplicacao)),
      ],
    );
  }

  /// Constrói card de aplicação individual
  pw.Widget _buildAplicacaoCard(pw.Context context, Map<String, dynamic> aplicacao) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Cabeçalho da aplicação
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Aplicação: ${aplicacao['talhaoNome'] ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
              pw.Text(
                'R\$ ${(aplicacao['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          
          // Detalhes da aplicação
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Data: ${_formatDate(aplicacao['dataAplicacao'])}'),
                    pw.Text('Operador: ${aplicacao['operador'] ?? 'N/A'}'),
                    pw.Text('Equipamento: ${aplicacao['equipamento'] ?? 'N/A'}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Área: ${(aplicacao['areaHa'] ?? 0.0).toStringAsFixed(2)} ha'),
                    pw.Text('Custo/ha: R\$ ${(aplicacao['custoPorHectare'] ?? 0.0).toStringAsFixed(2)}'),
                    pw.Text('Produtos: ${(aplicacao['produtos'] as List?)?.length ?? 0}'),
                  ],
                ),
              ),
            ],
          ),
          
          // Produtos utilizados
          if (aplicacao['produtos'] != null && (aplicacao['produtos'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Produtos Utilizados:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            ...(aplicacao['produtos'] as List).map((produto) => pw.Text(
              '• ${produto['nome'] ?? 'N/A'}: ${produto['quantidade']?.toStringAsFixed(2) ?? '0'} ${produto['unidade'] ?? ''} - R\$ ${(produto['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10),
            )),
          ],
        ],
      ),
    );
  }

  /// Constrói custos por talhão
  pw.Widget _buildCustosPorTalhao(pw.Context context, List<Map<String, dynamic>> custosPorTalhao) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: pw.Text(
            'CUSTOS POR TALHÃO',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        
        if (custosPorTalhao.isEmpty)
          pw.Text('Nenhum dado disponível para o período selecionado.')
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Talhão',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Área (ha)',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Custo Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // Dados
              ...custosPorTalhao.map((talhao) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(talhao['talhaoNome'] ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${(talhao['areaHa'] ?? 0.0).toStringAsFixed(2)}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('R\$ ${(talhao['custoTotal'] ?? 0.0).toStringAsFixed(2)}'),
                  ),
                ],
              )),
            ],
          ),
      ],
    );
  }

  /// Constrói produtos mais utilizados
  pw.Widget _buildProdutosMaisUtilizados(pw.Context context, List<Map<String, dynamic>> produtos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: pw.Text(
            'PRODUTOS MAIS UTILIZADOS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        
        if (produtos.isEmpty)
          pw.Text('Nenhum produto utilizado no período selecionado.')
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Produto',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Aplicações',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Custo Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // Dados
              ...produtos.take(10).map((produto) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(produto['produtoNome'] ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${produto['aplicacoes'] ?? 0}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('R\$ ${(produto['custoTotal'] ?? 0.0).toStringAsFixed(2)}'),
                  ),
                ],
              )),
            ],
          ),
      ],
    );
  }

  /// Constrói página de assinaturas
  pw.Widget _buildAssinaturas(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          child: pw.Text(
            'ASSINATURAS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ),
        pw.SizedBox(height: 40),
        
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Responsável Técnico',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Nome e CREA'),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Operador',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Nome'),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 40),
        
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Fiscalização',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Nome (opcional)'),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Data',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(_formatDate(DateTime.now())),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói card de métrica
  pw.Widget _buildMetricCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Formata data para exibição
  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      } catch (e) {
        return date;
      }
    } else if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return date.toString();
  }

  /// Compartilha o relatório PDF
  Future<void> compartilharRelatorio(String filePath) async {
    try {
      Logger.info('📤 Compartilhando relatório PDF...');
      await Share.shareXFiles([XFile(filePath)], text: 'Relatório Premium de Aplicações - FortSmart Agro');
      Logger.info('✅ Relatório compartilhado com sucesso!');
    } catch (e) {
      Logger.error('❌ Erro ao compartilhar relatório: $e');
      rethrow;
    }
  }
}
