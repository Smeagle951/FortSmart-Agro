import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PlotHistoryPdfService {
  // Gerar relatório de histórico de talhão
  Future<Uint8List> gerarRelatorioPdf({
    required String talhaoNome,
    required int ano,
    required List<Map<String, dynamic>> registros,
    required Map<String, dynamic>? analiseSolo,
    required Map<String, dynamic>? analiseSoloAnterior,
    required Map<String, dynamic>? produtividade,
    required List<Map<String, dynamic>> historicoProducao,
    required Map<String, Map<String, dynamic>> mediasInsumos,
    required Map<String, Map<String, dynamic>> mediasIndicadoresSolo,
    required Map<String, double> mediaProdutividadePorCultura,
  }) async {
    // Inicializar o documento PDF
    final pdf = pw.Document();
    
    // Criar tema do documento
    pw.ThemeData theme;
    
    try {
      // Tentar carregar fontes personalizadas
      final fontRegular = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
      final fontBold = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
      final fontItalic = await rootBundle.load("assets/fonts/OpenSans-Italic.ttf");
      
      final ttfRegular = pw.Font.ttf(fontRegular);
      final ttfBold = pw.Font.ttf(fontBold);
      final ttfItalic = pw.Font.ttf(fontItalic);
      
      theme = pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
        italic: ttfItalic,
      );
    } catch (e) {
      // Usar fontes padrão se não conseguir carregar as personalizadas
      print('Aviso: Usando fontes padrão do PDF devido a erro: $e');
      theme = pw.ThemeData(
        defaultTextStyle: pw.TextStyle(font: pw.Font.helvetica()),
      );
    }
    
    // Adicionar páginas ao PDF
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildHeader(talhaoNome, ano),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => [
          _buildTitulo(talhaoNome, ano),
          pw.SizedBox(height: 20),
          _buildResumoOperacional(registros),
          pw.SizedBox(height: 20),
          _buildAnaliseTecnica(analiseSolo, analiseSoloAnterior, ano),
          pw.SizedBox(height: 20),
          _buildProdutividade(produtividade, historicoProducao, ano),
          pw.SizedBox(height: 20),
          _buildIndicadores(mediasInsumos, mediasIndicadoresSolo, mediaProdutividadePorCultura),
        ],
      ),
    );
    
    return pdf.save();
  }

  // Construir cabeçalho
  pw.Widget _buildHeader(String talhaoNome, int ano) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey)),
      ),
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Histórico de Talhão',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // Construir rodapé
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey)),
      ),
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado por FortSmartAgro',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // Construir título
  pw.Widget _buildTitulo(String talhaoNome, int ano) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Histórico e Registros de Talhão',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Talhão: $talhaoNome',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Ano: $ano',
          style: const pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }

  // Construir seção de resumo operacional
  pw.Widget _buildResumoOperacional(List<Map<String, dynamic>> registros) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSecaoTitulo('Resumo Operacional'),
        pw.SizedBox(height: 10),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            verticalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
          ),
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              children: [
                _buildCelulaTabela('Data', header: true),
                _buildCelulaTabela('Tipo', header: true),
                _buildCelulaTabela('Descrição', header: true),
                _buildCelulaTabela('Quantidade', header: true),
              ],
            ),
            // Dados da tabela
            ...registros.map((registro) {
              final data = DateTime.parse(registro['data']);
              final dataFormatada = DateFormat('dd/MM/yyyy').format(data);
              
              return pw.TableRow(
                children: [
                  _buildCelulaTabela(dataFormatada),
                  _buildCelulaTabela(registro['tipo_registro']),
                  _buildCelulaTabela(registro['descricao']),
                  _buildCelulaTabela(
                    registro['quantidade'] != null 
                        ? '${registro['quantidade']} ${registro['unidade'] ?? ''}'
                        : '-',
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Widget auxiliar para criar célula de tabela
  pw.Widget _buildCelulaTabela(String texto, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
  
  // Título de seção
  pw.Widget _buildSecaoTitulo(String titulo) {
    return pw.Container(
      color: PdfColors.green800,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // Construir seção de análise técnica
  pw.Widget _buildAnaliseTecnica(Map<String, dynamic>? analiseSolo, Map<String, dynamic>? analiseSoloAnterior, int ano) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSecaoTitulo('Análise Técnica'),
        pw.SizedBox(height: 10),
        pw.Text('Análise de Solo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              children: [
                _buildCelulaTabela('Indicador', header: true),
                _buildCelulaTabela('${ano - 1}', header: true),
                _buildCelulaTabela('$ano', header: true),
              ],
            ),
            // Linhas da tabela
            pw.TableRow(
              children: [
                _buildCelulaTabela('pH'),
                _buildCelulaTabela(analiseSoloAnterior?['ph']?.toString() ?? '-'),
                _buildCelulaTabela(analiseSolo?['ph']?.toString() ?? '-'),
              ],
            ),
            pw.TableRow(
              children: [
                _buildCelulaTabela('V%'),
                _buildCelulaTabela(analiseSoloAnterior != null 
                    ? '${analiseSoloAnterior['v_porcentagem']}%' 
                    : '-'),
                _buildCelulaTabela(analiseSolo != null 
                    ? '${analiseSolo['v_porcentagem']}%' 
                    : '-'),
              ],
            ),
            pw.TableRow(
              children: [
                _buildCelulaTabela('Fósforo'),
                _buildCelulaTabela(analiseSoloAnterior?['fosforo']?.toString() ?? '-'),
                _buildCelulaTabela(analiseSolo?['fosforo']?.toString() ?? '-'),
              ],
            ),
            pw.TableRow(
              children: [
                _buildCelulaTabela('Potássio'),
                _buildCelulaTabela(analiseSoloAnterior?['potassio']?.toString() ?? '-'),
                _buildCelulaTabela(analiseSolo?['potassio']?.toString() ?? '-'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        analiseSolo != null
            ? pw.Text(
                'Análise realizada em: ${analiseSolo['data'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(analiseSolo['data'])) : "Data não informada"}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              )
            : pw.Text(
                'Nenhuma análise de solo registrada para o ano $ano',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
      ],
    );
  }

  // Construir seção de produtividade
  pw.Widget _buildProdutividade(Map<String, dynamic>? produtividade, List<Map<String, dynamic>> historicoProducao, int ano) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSecaoTitulo('Produtividade'),
        pw.SizedBox(height: 10),
        produtividade != null
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Produção $ano: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${produtividade['produtividade']} ${produtividade['unidade']}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Cultura: ${produtividade['cultura_id'] ?? 'Não informada'}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Data da colheita: ${produtividade['data_colheita'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(produtividade['data_colheita'])) : "Data não informada"}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              )
            : pw.Text(
                'Nenhum registro de produtividade para o ano $ano',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
        pw.SizedBox(height: 15),
        pw.Text('Histórico de Produção', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        historicoProducao.isEmpty
            ? pw.Text(
                'Nenhum histórico de produção registrado',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              )
            : pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                ),
                children: [
                  // Cabeçalho da tabela
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      _buildCelulaTabela('Ano', header: true),
                      _buildCelulaTabela('Cultura', header: true),
                      _buildCelulaTabela('Produtividade', header: true),
                    ],
                  ),
                  // Dados da tabela
                  ...historicoProducao.map((producao) {
                    final dataColheita = DateTime.parse(producao['data_colheita']);
                    return pw.TableRow(
                      children: [
                        _buildCelulaTabela(dataColheita.year.toString()),
                        _buildCelulaTabela(producao['cultura_id']?.toString() ?? '-'),
                        _buildCelulaTabela(
                          '${producao['produtividade']} ${producao['unidade']}',
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
      ],
    );
  }

  // Construir seção de indicadores
  pw.Widget _buildIndicadores(
    Map<String, Map<String, dynamic>> mediasInsumos,
    Map<String, Map<String, dynamic>> mediasIndicadoresSolo,
    Map<String, double> mediaProdutividadePorCultura,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSecaoTitulo('Indicadores e Médias'),
        pw.SizedBox(height: 10),
        
        // Média de consumo de insumos
        pw.Text('Média de Consumo de Insumos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        mediasInsumos.isEmpty
            ? pw.Text(
                'Nenhuma média de consumo de insumos registrada',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              )
            : pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                ),
                children: [
                  // Cabeçalho da tabela
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      _buildCelulaTabela('Insumo', header: true),
                      _buildCelulaTabela('Média', header: true),
                      _buildCelulaTabela('Período', header: true),
                    ],
                  ),
                  // Dados da tabela
                  ...mediasInsumos.entries.map((entry) {
                    return pw.TableRow(
                      children: [
                        _buildCelulaTabela(entry.key),
                        _buildCelulaTabela(
                          '${entry.value['media']} ${entry.value['unidade']}',
                        ),
                        _buildCelulaTabela(entry.value['periodo']),
                      ],
                    );
                  }).toList(),
                ],
              ),
        pw.SizedBox(height: 15),
        
        // Média de produtividade por cultura
        pw.Text('Média de Produtividade por Cultura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        mediaProdutividadePorCultura.isEmpty
            ? pw.Text(
                'Nenhuma média de produtividade por cultura registrada',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              )
            : pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                ),
                children: [
                  // Cabeçalho da tabela
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      _buildCelulaTabela('Cultura', header: true),
                      _buildCelulaTabela('Média', header: true),
                    ],
                  ),
                  // Dados da tabela
                  ...mediaProdutividadePorCultura.entries.map((entry) {
                    return pw.TableRow(
                      children: [
                        _buildCelulaTabela(entry.key),
                        _buildCelulaTabela('${entry.value} sc/ha'),
                      ],
                    );
                  }).toList(),
                ],
              ),
        pw.SizedBox(height: 15),
        
        // Média dos indicadores de solo
        pw.Text('Média dos Indicadores de Solo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        mediasIndicadoresSolo.isEmpty
            ? pw.Text(
                'Nenhuma média de indicadores de solo registrada',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              )
            : pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                ),
                children: [
                  // Cabeçalho da tabela
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      _buildCelulaTabela('Indicador', header: true),
                      _buildCelulaTabela('Valor Médio', header: true),
                      _buildCelulaTabela('Período', header: true),
                    ],
                  ),
                  // Dados da tabela
                  ...mediasIndicadoresSolo.entries.map((entry) {
                    return pw.TableRow(
                      children: [
                        _buildCelulaTabela(entry.key),
                        _buildCelulaTabela(entry.value['valor'].toString()),
                        _buildCelulaTabela(entry.value['periodo']),
                      ],
                    );
                  }).toList(),
                ],
              ),
      ],
    );
  }
  
  // Método para salvar o PDF no dispositivo e abrir para visualização/compartilhamento
  Future<String> salvarEAbrirPdf(Uint8List pdfBytes, String talhaoNome, int ano) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final nomeArquivo = 'Historico_${talhaoNome.replaceAll(' ', '_')}_$ano.pdf';
      final file = File('${dir.path}/$nomeArquivo');
      await file.writeAsBytes(pdfBytes);
      
      // Usar o plugin printing para visualizar/compartilhar o PDF
      // await Printing.sharePdf(bytes: pdfBytes, filename: nomeArquivo);
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar PDF: $e');
    }
  }
}
