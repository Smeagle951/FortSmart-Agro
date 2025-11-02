import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Serviço para gerar PDF premium de prescrição agronômica
class PrescricaoPdfService {
  
  // Paleta de cores FortSmart Premium
  static const PdfColor corFundo = PdfColor.fromInt(0xFFF9FAFB); // Branco gelo
  static const PdfColor corCabecalho = PdfColor.fromInt(0xFF0F4C5C); // Azul petróleo
  static const PdfColor corDestaque = PdfColor.fromInt(0xFFC8A951); // Dourado suave
  static const PdfColor corTexto = PdfColor.fromInt(0xFF2E2E2E); // Cinza grafite
  static const PdfColor corSeparador = PdfColor.fromInt(0xFFE5E5E5); // Cinza claro
  
  /// Gera PDF premium da prescrição (versão otimizada - 3 páginas)
  static Future<File> gerarPdfPrescricao({
    required Map<String, dynamic> dadosPrescricao,
    required Map<String, dynamic> resumoOperacional,
    required String nomeFazenda,
    required String nomeTecnico,
    required String creaTecnico,
  }) async {
    final pdf = pw.Document();
    
    // Adicionar apenas 3 páginas essenciais
    pdf.addPage(_criarCapa(dadosPrescricao, nomeFazenda, nomeTecnico));
    pdf.addPage(_criarPaginaDadosEProdutos(dadosPrescricao, resumoOperacional));
    pdf.addPage(_criarPaginaResumoEAssinatura(dadosPrescricao, resumoOperacional, nomeTecnico, creaTecnico));
    
    // Salvar arquivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/prescricao_fortsmart_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Gera PDF padronizado seguindo o modelo FortSmart
  static Future<File> gerarPdfPadronizado({
    required Map<String, dynamic> dadosPrescricao,
    required Map<String, dynamic> resumoOperacional,
    required String nomeFazenda,
    required String nomeTecnico,
    required String creaTecnico,
    required List<Map<String, dynamic>> produtos,
  }) async {
    final pdf = pw.Document();
    
    // Página única com layout padronizado
    pdf.addPage(_criarPaginaPadronizada(
      dadosPrescricao, 
      resumoOperacional, 
      nomeFazenda, 
      nomeTecnico, 
      creaTecnico, 
      produtos
    ));
    
    // Salvar arquivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_prescricao_fortsmart_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Gera PDF consolidado com múltiplas prescrições
  static Future<File> gerarPdfConsolidado({
    required List<Map<String, dynamic>> prescricoes,
    required String nomeFazenda,
    required String nomeTecnico,
    required String creaTecnico,
  }) async {
    final pdf = pw.Document();
    
    // Página 1: Capa consolidada
    pdf.addPage(_criarCapaConsolidada(prescricoes, nomeFazenda, nomeTecnico));
    
    // Páginas 2+: Uma página por prescrição
    for (int i = 0; i < prescricoes.length; i++) {
      final prescricao = prescricoes[i];
      pdf.addPage(_criarPaginaPrescricaoIndividual(
        prescricao['dados'],
        prescricao['resumo'],
        i + 1,
        prescricao['talhao'],
      ));
    }
    
    // Última página: Resumo consolidado e assinatura
    pdf.addPage(_criarPaginaResumoConsolidado(prescricoes, nomeTecnico, creaTecnico));
    
    // Salvar arquivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/prescricoes_consolidadas_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Cria página padronizada seguindo o modelo FortSmart
  static pw.Page _criarPaginaPadronizada(
    Map<String, dynamic> dadosPrescricao,
    Map<String, dynamic> resumoOperacional,
    String nomeFazenda,
    String nomeTecnico,
    String creaTecnico,
    List<Map<String, dynamic>> produtos,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            _criarCabecalhoSimples(),
            
            pw.SizedBox(height: 25),
            
            // Informações principais
            _criarInformacoesPrincipais(dadosPrescricao, nomeFazenda, nomeTecnico, creaTecnico),
            
            pw.SizedBox(height: 25),
            
            // Dados da aplicação
            _criarDadosAplicacaoSimples(dadosPrescricao, resumoOperacional),
            
            pw.SizedBox(height: 25),
            
            // Produtos da prescrição
            _criarTabelaProdutosSimples(produtos),
            
            pw.SizedBox(height: 25),
            
            // Resumo operacional
            _criarResumoOperacionalSimples(resumoOperacional),
            
            pw.SizedBox(height: 25),
            
            // Observações técnicas
            _criarObservacoesTecnicasSimples(),
            
            pw.Spacer(),
            
            // Assinatura
            _criarAssinaturaSimples(nomeTecnico, creaTecnico),
          ],
        ),
      ),
    );
  }

  /// Cria cabeçalho simples
  static pw.Widget _criarCabecalhoSimples() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo FortSmart
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: corCabecalho,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
          ),
          child: pw.Center(
            child: pw.Text(
              'F',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'FortSmart',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Prescrição Agronômica de Aplicação',
          style: pw.TextStyle(
            fontSize: 16,
            color: corTexto,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: corSeparador, thickness: 2),
      ],
    );
  }

  /// Cria informações principais
  static pw.Widget _criarInformacoesPrincipais(Map<String, dynamic> dados, String nomeFazenda, String nomeTecnico, String creaTecnico) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Informações Principais',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(
              child: _criarItemInfo('Fazenda:', nomeFazenda),
            ),
            pw.Expanded(
              child: _criarItemInfo('Talhão:', dados['talhao'] ?? 'N/A'),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _criarItemInfo('Cultura:', dados['cultura'] ?? 'Não definida'),
            ),
            pw.Expanded(
              child: _criarItemInfo('Data:', dados['data'] ?? DateTime.now().toString().split(' ')[0]),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _criarItemInfo('Técnico Responsável:', nomeTecnico),
            ),
            pw.Expanded(
              child: _criarItemInfo('CREA:', creaTecnico),
            ),
          ],
        ),
      ],
    );
  }

  /// Cria item de informação
  static pw.Widget _criarItemInfo(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: corTexto,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: corTexto,
            ),
          ),
        ),
      ],
    );
  }

  /// Cria dados da aplicação simples
  static pw.Widget _criarDadosAplicacaoSimples(Map<String, dynamic> dados, Map<String, dynamic> resumo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dados da Aplicação',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(child: _criarItemInfo('Área total:', '${dados['area'] ?? 0.0} ha')),
            pw.Expanded(child: _criarItemInfo('Tipo de aplicação:', dados['tipoAplicacao'] ?? 'Terrestre')),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(child: _criarItemInfo('Capacidade do tanque:', '${dados['capacidadeTanque'] ?? 0} L')),
            pw.Expanded(child: _criarItemInfo('Vazão de aplicação:', '${dados['vazaoPorHectare'] ?? 0} L/ha')),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(child: _criarItemInfo('Volume de calda por tanque:', '${resumo['volumePorTanque'] ?? 0} L')),
            pw.Expanded(child: _criarItemInfo('Número de tanques necessários:', '${resumo['numeroTanques'] ?? 0}')),
          ],
        ),
        pw.SizedBox(height: 10),
        _criarItemInfo('Velocidade de trabalho:', '${dados['velocidade'] ?? '8.0'} km/h'),
      ],
    );
  }

  /// Cria tabela de produtos simples
  static pw.Widget _criarTabelaProdutosSimples(List<Map<String, dynamic>> produtos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Produtos da Prescrição',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: corSeparador),
          columnWidths: {
            0: const pw.FixedColumnWidth(100),
            1: const pw.FixedColumnWidth(60),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FixedColumnWidth(70),
            4: const pw.FixedColumnWidth(80),
            5: const pw.FixedColumnWidth(60),
          },
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: pw.BoxDecoration(color: corCabecalho),
              children: [
                _criarCelulaTabela('Produto', PdfColors.white, true),
                _criarCelulaTabela('Dose/ha', PdfColors.white, true),
                _criarCelulaTabela('Qtde/Tanque', PdfColors.white, true),
                _criarCelulaTabela('Qtde Total', PdfColors.white, true),
                _criarCelulaTabela('Classe Toxicológica', PdfColors.white, true),
                _criarCelulaTabela('Carência (dias)', PdfColors.white, true),
              ],
            ),
            // Dados dos produtos
            ...produtos.map((produto) => pw.TableRow(
              children: [
                _criarCelulaTabela(produto['nome'] ?? 'N/A', corTexto),
                _criarCelulaTabela('${produto['dose'] ?? 0} ${produto['unidade'] ?? 'L'}', corTexto),
                _criarCelulaTabela('${produto['quantidadeTanque'] ?? 0} ${produto['unidade'] ?? 'L'}', corTexto),
                _criarCelulaTabela('${produto['quantidadeTotal'] ?? 0} ${produto['unidade'] ?? 'L'}', corTexto),
                _criarCelulaTabela(produto['classeToxicologica'] ?? 'Classe II', corTexto),
                _criarCelulaTabela('${produto['carencia'] ?? 0}', corTexto),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  /// Cria célula da tabela
  static pw.Widget _criarCelulaTabela(String texto, PdfColor cor, [bool isHeader = false]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          color: cor,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }


  /// Cria resumo operacional simples
  static pw.Widget _criarResumoOperacionalSimples(Map<String, dynamic> resumo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumo Operacional',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(child: _criarItemInfo('Área total aplicada:', '${resumo['areaTotal'] ?? 0.0} ha')),
            pw.Expanded(child: _criarItemInfo('Consumo total de calda:', '${resumo['consumoTotal'] ?? 0} L')),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(child: _criarItemInfo('Hectares por tanque:', '${resumo['haPorTanque'] ?? 0} ha')),
            pw.Expanded(child: _criarItemInfo('Tanques utilizados:', '${resumo['tanquesUtilizados'] ?? 0}')),
          ],
        ),
        pw.SizedBox(height: 10),
        _criarItemInfo('Eficiência:', '${resumo['eficiencia'] ?? 0}%'),
      ],
    );
  }

  /// Cria observações técnicas simples
  static pw.Widget _criarObservacoesTecnicasSimples() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Observações Técnicas',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: corCabecalho,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: corSeparador),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Campo aberto para observações adicionais do Eng. Agrônomo.',
              style: pw.TextStyle(
                fontSize: 11,
                color: corTexto,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Cria assinatura simples
  static pw.Widget _criarAssinaturaSimples(String nomeTecnico, String creaTecnico) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: corSeparador, thickness: 1),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Nome e assinatura do Eng. Agrônomo',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: corCabecalho,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    nomeTecnico,
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: corTexto,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'CREA: $creaTecnico',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: corTexto,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              width: 150,
              height: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: corSeparador),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Assinatura',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: corTexto,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Cria a capa do PDF
  static pw.Page _criarCapa(
    Map<String, dynamic> dadosPrescricao,
    String nomeFazenda,
    String nomeTecnico,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: corFundo,
        ),
        child: pw.Column(
          children: [
            // Espaçamento superior
            pw.SizedBox(height: 80),
            
            // Logo FortSmart (simulado)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corCabecalho,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Text(
                'FORT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Título principal
            pw.Text(
              'Prescrição Agronômica',
              style: pw.TextStyle(
                color: corCabecalho,
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.Text(
              'de Aplicação',
              style: pw.TextStyle(
                color: corCabecalho,
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Linha dourada
            pw.Container(
              height: 2,
              width: 200,
              color: corDestaque,
            ),
            
            pw.SizedBox(height: 60),
            
            // Informações principais
            _buildInfoCapa('Fazenda', nomeFazenda),
            _buildInfoCapa('Talhão', dadosPrescricao['talhao'] ?? 'N/A'),
            _buildInfoCapa('Data', _formatarData(dadosPrescricao['data'])),
            _buildInfoCapa('Técnico', nomeTecnico),
            
            pw.Spacer(),
            
            // QR Code
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                '📱 Abra no FortSmart',
                style: pw.TextStyle(
                  color: corTexto,
                  fontSize: 12,
                ),
              ),
            ),
            
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// Cria página consolidada de dados e produtos
  static pw.Page _criarPaginaDadosEProdutos(
    Map<String, dynamic> dadosPrescricao,
    Map<String, dynamic> resumoOperacional,
  ) {
    final produtos = resumoOperacional['produtos'] as List<dynamic>? ?? [];
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTituloSecao('2. Dados da Aplicação e Produtos'),
            
            pw.SizedBox(height: 20),
            
            // Grid compacto de informações
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Talhão',
                    dadosPrescricao['talhao'] ?? 'N/A',
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Área',
                    '${resumoOperacional['areaTotal']?.toStringAsFixed(2)} ha',
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Tipo',
                    resumoOperacional['tipoMaquina'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Capacidade',
                    '${resumoOperacional['capacidadeTanque']?.toStringAsFixed(0)} L',
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Vazão',
                    '${resumoOperacional['vazaoPorHectare']?.toStringAsFixed(0)} L/ha',
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildCardInfoCompacto(
                    'Tanques',
                    '${resumoOperacional['numeroTanques']}',
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 25),
            
            // Tabela de produtos compacta
            pw.Text(
              'Produtos da Prescrição',
              style: pw.TextStyle(
                color: corCabecalho,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            if (produtos.isNotEmpty) ...[
              _buildTabelaProdutosCompacta(produtos),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: corSeparador,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Nenhum produto selecionado',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            
            pw.SizedBox(height: 20),
            
            // Resumo financeiro compacto
            _buildResumoFinanceiroCompacto(resumoOperacional),
          ],
        ),
      ),
    );
  }
  
  /// Cria página de produtos
  static pw.Page _criarPaginaProdutos(Map<String, dynamic> resumoOperacional) {
    final produtos = resumoOperacional['produtos'] as List<dynamic>? ?? [];
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTituloSecao('2. Resumo Técnico dos Produtos'),
            
            pw.SizedBox(height: 30),
            
            // Tabela de produtos
            if (produtos.isNotEmpty) ...[
              _buildTabelaProdutos(produtos),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(40),
                decoration: pw.BoxDecoration(
                  color: corSeparador,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Nenhum produto selecionado',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 16,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            
            pw.SizedBox(height: 30),
            
            // Resumo financeiro
            _buildResumoFinanceiro(resumoOperacional),
          ],
        ),
      ),
    );
  }
  
  /// Cria página consolidada de resumo e assinatura
  static pw.Page _criarPaginaResumoEAssinatura(
    Map<String, dynamic> dadosPrescricao,
    Map<String, dynamic> resumoOperacional,
    String nomeTecnico,
    String creaTecnico,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTituloSecao('3. Resumo Operacional e Assinatura'),
            
            pw.SizedBox(height: 20),
            
            // Resumo operacional compacto
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corSeparador,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: corCabecalho, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📌 Resumo da Operação',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  
                  pw.SizedBox(height: 15),
                  
                  _buildInfoOperacionalCompacto('Área total', '${resumoOperacional['areaTotal']?.toStringAsFixed(2)} ha'),
                  _buildInfoOperacionalCompacto('Vazão', '${resumoOperacional['vazaoPorHectare']?.toStringAsFixed(0)} L/ha'),
                  _buildInfoOperacionalCompacto('Ha por tanque', '${resumoOperacional['hectaresPorTanque']?.toStringAsFixed(1)} ha'),
                  _buildInfoOperacionalCompacto('Tanques necessários', '${resumoOperacional['numeroTanques']}'),
                  
                  if (resumoOperacional['volumeResidual'] != null && resumoOperacional['volumeResidual'] > 0)
                    _buildInfoOperacionalCompacto('Volume residual', '${resumoOperacional['volumeResidual']?.toStringAsFixed(1)} L'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Observações técnicas compactas
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: corSeparador, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observações Técnicas',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '• Verificar condições climáticas • Calibrar bicos • Utilizar EPIs • Respeitar carência',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Campo para observações do engenheiro
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border(
                  left: pw.BorderSide(color: corCabecalho, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observações do Eng. Agrônomo:',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: corSeparador),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        dadosPrescricao['observacoes'] ?? 'Campo para observações técnicas...',
                        style: pw.TextStyle(
                          color: corTexto,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Assinatura compacta
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: corSeparador, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 1,
                    color: corDestaque,
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  pw.Text(
                    'Eng. Agrônomo',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  
                  pw.Text(
                    nomeTecnico,
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 12,
                    ),
                  ),
                  
                  pw.Text(
                    'CREA: $creaTecnico',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 10,
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // Campo para assinatura
                  pw.Container(
                    height: 40,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: corSeparador),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Assinatura',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF808080),
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Cria página de observações e assinatura
  static pw.Page _criarPaginaObservacoes(
    Map<String, dynamic> dadosPrescricao,
    String nomeTecnico,
    String creaTecnico,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTituloSecao('4. Observações Técnicas'),
            
            pw.SizedBox(height: 30),
            
            // Campo para observações
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border(
                  left: pw.BorderSide(color: corCabecalho, width: 3),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observações do Engenheiro Agrônomo:',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: corSeparador),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        dadosPrescricao['observacoes'] ?? 'Campo em branco para observações técnicas...',
                        style: pw.TextStyle(
                          color: corTexto,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Assinatura
            pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: corSeparador, width: 1),
              ),
              child: pw.Column(
                children: [
                  // Linha dourada
                  pw.Container(
                    height: 1,
                    color: corDestaque,
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  pw.Text(
                    'Eng. Agrônomo',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  
                  pw.SizedBox(height: 5),
                  
                  pw.Text(
                    nomeTecnico,
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 14,
                    ),
                  ),
                  
                  pw.Text(
                    'CREA: $creaTecnico',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 12,
                    ),
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  // Campo para assinatura
                  pw.Container(
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: corSeparador),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Assinatura',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF808080),
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widgets auxiliares
  static pw.Widget _buildInfoCapa(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTituloSecao(String titulo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
        color: corCabecalho,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
  
  static pw.Widget _buildCardInfo(String label, String value, IconData icon) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: corFundo,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: corSeparador, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTabelaProdutos(List<dynamic> produtos) {
    return pw.Table(
      border: pw.TableBorder.all(color: corSeparador, width: 1),
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(color: corCabecalho),
          children: [
            _buildCelulaTabela('Produto', isHeader: true),
            _buildCelulaTabela('Dose/ha', isHeader: true),
            _buildCelulaTabela('Unidade', isHeader: true),
            _buildCelulaTabela('Qtde/Tanque', isHeader: true),
            _buildCelulaTabela('Qtde Total', isHeader: true),
          ],
        ),
        // Dados
        ...produtos.map((produto) => pw.TableRow(
          children: [
            _buildCelulaTabela(produto['nome'] ?? 'N/A'),
            _buildCelulaTabela(produto['dosePorHectare']?.toStringAsFixed(2) ?? '0'),
            _buildCelulaTabela(produto['unidade'] ?? 'N/A'),
            _buildCelulaTabela(produto['quantidadePorTanque']?.toStringAsFixed(2) ?? '0'),
            _buildCelulaTabela(produto['quantidadeTotal']?.toStringAsFixed(2) ?? '0'),
          ],
        )).toList(),
      ],
    );
  }
  
  static pw.Widget _buildCelulaTabela(String texto, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: isHeader ? PdfColors.white : corTexto,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  static pw.Widget _buildResumoFinanceiro(Map<String, dynamic> resumoOperacional) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F5DC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: corDestaque, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💰 Resumo Financeiro',
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoOperacional('Custo por hectare', 'R\$ ${resumoOperacional['custoPorHectare']?.toStringAsFixed(2) ?? '0,00'}'),
          _buildInfoOperacional('Custo total da operação', 'R\$ ${resumoOperacional['custoTotal']?.toStringAsFixed(2) ?? '0,00'}'),
        ],
      ),
    );
  }
  
  // Widgets auxiliares compactos
  static pw.Widget _buildCardInfoCompacto(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: corFundo,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: corSeparador, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTabelaProdutosCompacta(List<dynamic> produtos) {
    return pw.Table(
      border: pw.TableBorder.all(color: corSeparador, width: 0.5),
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(color: corCabecalho),
          children: [
            _buildCelulaTabelaCompacta('Produto', isHeader: true),
            _buildCelulaTabelaCompacta('Dose/ha', isHeader: true),
            _buildCelulaTabelaCompacta('Qtde/Tanque', isHeader: true),
            _buildCelulaTabelaCompacta('Qtde Total', isHeader: true),
          ],
        ),
        // Dados
        ...produtos.map((produto) => pw.TableRow(
          children: [
            _buildCelulaTabelaCompacta(produto['nome'] ?? 'N/A'),
            _buildCelulaTabelaCompacta('${produto['dosePorHectare']?.toStringAsFixed(2) ?? '0'} ${produto['unidade']}'),
            _buildCelulaTabelaCompacta('${produto['quantidadePorTanque']?.toStringAsFixed(2) ?? '0'} ${produto['unidade']}'),
            _buildCelulaTabelaCompacta('${produto['quantidadeTotal']?.toStringAsFixed(2) ?? '0'} ${produto['unidade']}'),
          ],
        )).toList(),
      ],
    );
  }
  
  static pw.Widget _buildCelulaTabelaCompacta(String texto, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: isHeader ? PdfColors.white : corTexto,
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  static pw.Widget _buildResumoFinanceiroCompacto(Map<String, dynamic> resumoOperacional) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F5DC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: corDestaque, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💰 Resumo Financeiro',
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoOperacionalCompacto('Custo por hectare', 'R\$ ${resumoOperacional['custoPorHectare']?.toStringAsFixed(2) ?? '0,00'}'),
          _buildInfoOperacionalCompacto('Custo total', 'R\$ ${resumoOperacional['custoTotal']?.toStringAsFixed(2) ?? '0,00'}'),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoOperacionalCompacto(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 10,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoOperacional(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: corTexto,
              fontSize: 12,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: corCabecalho,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static String _formatarData(dynamic data) {
    if (data == null) return 'N/A';
    if (data is DateTime) {
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    }
    return data.toString();
  }
  
  // Páginas para PDF consolidado
  static pw.Page _criarCapaConsolidada(
    List<Map<String, dynamic>> prescricoes,
    String nomeFazenda,
    String nomeTecnico,
  ) {
    final totalPrescricoes = prescricoes.length;
    final areaTotal = prescricoes.fold<double>(0, (sum, p) => sum + (p['resumo']['areaTotal'] ?? 0));
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          color: corFundo,
        ),
        child: pw.Column(
          children: [
            pw.SizedBox(height: 80),
            
            // Logo FortSmart
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corCabecalho,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Text(
                'FORT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Título principal
            pw.Text(
              'Prescrições Agronômicas',
              style: pw.TextStyle(
                color: corCabecalho,
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.Text(
              'Consolidadas',
              style: pw.TextStyle(
                color: corCabecalho,
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Linha dourada
            pw.Container(
              height: 2,
              width: 200,
              color: corDestaque,
            ),
            
            pw.SizedBox(height: 60),
            
            // Informações consolidadas
            _buildInfoCapa('Fazenda', nomeFazenda),
            _buildInfoCapa('Total de Prescrições', '$totalPrescricoes'),
            _buildInfoCapa('Área Total', '${areaTotal.toStringAsFixed(2)} ha'),
            _buildInfoCapa('Data', _formatarData(DateTime.now())),
            _buildInfoCapa('Técnico', nomeTecnico),
            
            pw.Spacer(),
            
            // Lista de talhões
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corSeparador,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Talhões Incluídos:',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...prescricoes.map((p) => pw.Text(
                    '• ${p['talhao']} (${p['resumo']['areaTotal']?.toStringAsFixed(2)} ha)',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 12,
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  static pw.Page _criarPaginaPrescricaoIndividual(
    Map<String, dynamic> dadosPrescricao,
    Map<String, dynamic> resumoOperacional,
    int numeroPrescricao,
    String nomeTalhao,
  ) {
    final produtos = resumoOperacional['produtos'] as List<dynamic>? ?? [];
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(30),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabeçalho da prescrição
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: corCabecalho,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Prescrição $numeroPrescricao',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    nomeTalhao,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Dados compactos
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildCardInfoCompacto('Área', '${resumoOperacional['areaTotal']?.toStringAsFixed(2)} ha'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildCardInfoCompacto('Tipo', resumoOperacional['tipoMaquina'] ?? 'N/A'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildCardInfoCompacto('Tanques', '${resumoOperacional['numeroTanques']}'),
                ),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // Produtos
            if (produtos.isNotEmpty) ...[
              pw.Text(
                'Produtos:',
                style: pw.TextStyle(
                  color: corCabecalho,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildTabelaProdutosCompacta(produtos),
            ],
            
            pw.SizedBox(height: 15),
            
            // Resumo financeiro
            _buildResumoFinanceiroCompacto(resumoOperacional),
          ],
        ),
      ),
    );
  }
  
  static pw.Page _criarPaginaResumoConsolidado(
    List<Map<String, dynamic>> prescricoes,
    String nomeTecnico,
    String creaTecnico,
  ) {
    final areaTotal = prescricoes.fold<double>(0, (sum, p) => sum + (p['resumo']['areaTotal'] ?? 0));
    final custoTotal = prescricoes.fold<double>(0, (sum, p) => sum + (p['resumo']['custoTotal'] ?? 0));
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTituloSecao('Resumo Consolidado'),
            
            pw.SizedBox(height: 20),
            
            // Resumo geral
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corSeparador,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: corCabecalho, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📊 Resumo Geral',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  
                  pw.SizedBox(height: 15),
                  
                  _buildInfoOperacionalCompacto('Total de prescrições', '${prescricoes.length}'),
                  _buildInfoOperacionalCompacto('Área total', '${areaTotal.toStringAsFixed(2)} ha'),
                  _buildInfoOperacionalCompacto('Custo total', 'R\$ ${custoTotal.toStringAsFixed(2)}'),
                  _buildInfoOperacionalCompacto('Custo médio por ha', 'R\$ ${(custoTotal / areaTotal).toStringAsFixed(2)}'),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Assinatura
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: corFundo,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: corSeparador, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 1,
                    color: corDestaque,
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  pw.Text(
                    'Eng. Agrônomo',
                    style: pw.TextStyle(
                      color: corCabecalho,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  
                  pw.Text(
                    nomeTecnico,
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 12,
                    ),
                  ),
                  
                  pw.Text(
                    'CREA: $creaTecnico',
                    style: pw.TextStyle(
                      color: corTexto,
                      fontSize: 10,
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // Campo para assinatura
                  pw.Container(
                    height: 40,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: corSeparador),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Assinatura',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF808080),
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

