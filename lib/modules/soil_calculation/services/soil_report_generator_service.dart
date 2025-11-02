import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../models/soil_compaction_point_model.dart';
import '../models/soil_diagnostic_model.dart';
import '../models/soil_laboratory_sample_model.dart';
import '../models/soil_report_template_model.dart';
import '../widgets/soil_compaction_pie_chart.dart';
import '../services/soil_analysis_service.dart';
import '../services/soil_temporal_analysis_service.dart';
import '../services/soil_smart_engine.dart';
import '../services/soil_map_generator_service.dart';
import '../services/widget_to_image_service.dart';

/// Serviço para geração de relatórios premium de compactação do solo
class SoilReportGeneratorService {
  
  /// Gera relatório premium em PDF
  static Future<String> gerarRelatorioPremium({
    required int talhaoId,
    required String nomeTalhao,
    required String nomeFazenda,
    required String nomeResponsavel,
    required double areaHectares,
    required LatLng centroTalhao,
    required int safraId,
    required DateTime dataColeta,
    required String operador,
    required List<SoilCompactionPointModel> pontos,
    List<SoilDiagnosticModel>? diagnosticos,
    List<SoilLaboratorySampleModel>? amostrasLaboratoriais,
    required List<LatLng> polygonCoordinates,
    String? logoFazendaPath,
    SoilReportTemplateModel? template,
  }) async {
    try {
      // Usa template padrão se não fornecido
      final templateFinal = template ?? SoilReportTemplateModel.templatePadrao(
        nomeFazenda: nomeFazenda,
        logoFazendaPath: logoFazendaPath,
      );
      
      // Calcula estatísticas
      final estatisticas = _calcularEstatisticasCompletas(pontos);
      final distribuicaoNiveis = _calcularDistribuicaoNiveis(pontos);
      final recomendacoes = _gerarRecomendacoesCompletas(pontos, diagnosticos, amostrasLaboratoriais);
      
      // Gera mapa real
      String? mapaPath;
      try {
        mapaPath = await SoilMapGeneratorService.gerarMapaCompactacao(
          pontos: pontos,
          polygonCoordinates: polygonCoordinates,
          nomeTalhao: nomeTalhao,
          distribuicaoNiveis: distribuicaoNiveis,
        );
      } catch (e) {
        print('Erro ao gerar mapa: $e');
        // Continua sem mapa se houver erro
      }
      
      // Gera gráfico de pizza
      String? graficoPath;
      try {
        graficoPath = await _gerarGraficoPizza(distribuicaoNiveis, nomeTalhao);
      } catch (e) {
        print('Erro ao gerar gráfico: $e');
        // Continua sem gráfico se houver erro
      }
      
      // Cria documento PDF
      final pdf = pw.Document();
      
      // Página 1: Capa
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildCapa(
            nomeFazenda: nomeFazenda,
            nomeTalhao: nomeTalhao,
            safraId: safraId,
            dataColeta: dataColeta,
            logoFazendaPath: logoFazendaPath,
          ),
        ),
      );
      
      // Página 2: Sumário
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildSumario(),
        ),
      );
      
      // Página 3: Resumo Executivo
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildResumoExecutivo(
            estatisticas: estatisticas,
            distribuicaoNiveis: distribuicaoNiveis,
            areaHectares: areaHectares,
            totalPontos: pontos.length,
          ),
        ),
      );
      
      // Página 4: Informações da Propriedade
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildInformacoesPropriedade(
            nomeFazenda: nomeFazenda,
            nomeResponsavel: nomeResponsavel,
            nomeTalhao: nomeTalhao,
            areaHectares: areaHectares,
            centroTalhao: centroTalhao,
            safraId: safraId,
            dataColeta: dataColeta,
            operador: operador,
          ),
        ),
      );
      
      // Página 5: Metodologia
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildMetodologia(
            totalPontos: pontos.length,
            areaHectares: areaHectares,
          ),
        ),
      );
      
      // Página 6: Mapa de Compactação
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildMapaCompactacao(
            pontos: pontos,
            polygonCoordinates: polygonCoordinates,
            distribuicaoNiveis: distribuicaoNiveis,
            mapaPath: mapaPath,
          ),
        ),
      );
      
      // Página 7: Tabela de Pontos
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildTabelaPontos(pontos),
        ),
      );
      
      // Página 8: Análises Estatísticas
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildAnalisesEstatisticas(
            estatisticas: estatisticas,
            distribuicaoNiveis: distribuicaoNiveis,
            graficoPath: graficoPath,
          ),
        ),
      );
      
      // Página 9: Diagnósticos
      if (diagnosticos != null && diagnosticos.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => _buildDiagnosticos(diagnosticos),
          ),
        );
      }
      
      // Página 10: Recomendações
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildRecomendacoes(recomendacoes),
        ),
      );
      
      // Página 11: Plano de Ação
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildPlanoAcao(recomendacoes),
        ),
      );
      
      // Salva PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Relatorio_Compactacao_${nomeTalhao}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      return filePath;
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  /// Constrói a capa do relatório
  static pw.Widget _buildCapa({
    required String nomeFazenda,
    required String nomeTalhao,
    required int safraId,
    required DateTime dataColeta,
    String? logoFazendaPath,
  }) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [PdfColors.green100, PdfColors.blue100],
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // Logo FortSmart
          pw.Container(
            width: 200,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'FortSmart',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Título Principal
          pw.Text(
            'RELATÓRIO PREMIUM',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          
          pw.SizedBox(height: 10),
          
          pw.Text(
            'COMPACTAÇÃO E DIAGNÓSTICO DO SOLO',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Informações
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  blurRadius: 10,
                  offset: const PdfPoint(0, 5),
                ),
              ],
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Fazenda: $nomeFazenda',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Talhão: $nomeTalhao',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Safra: $safraId',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Data: ${_formatarData(dataColeta)}',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          pw.Spacer(),
          
          // Rodapé
          pw.Text(
            'Versão 3.0 • FortSmart Agro • ${_formatarData(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o sumário
  static pw.Widget _buildSumario() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SUMÁRIO',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Text('1. Resumo Executivo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('2. Informações da Propriedade', style: pw.TextStyle(fontSize: 14)),
        pw.Text('3. Metodologia de Coleta', style: pw.TextStyle(fontSize: 14)),
        pw.Text('4. Mapa de Compactação', style: pw.TextStyle(fontSize: 14)),
        pw.Text('5. Tabela de Pontos', style: pw.TextStyle(fontSize: 14)),
        pw.Text('6. Análises Estatísticas e Gráficos', style: pw.TextStyle(fontSize: 14)),
        pw.Text('7. Diagnósticos por Ponto', style: pw.TextStyle(fontSize: 14)),
        pw.Text('8. Recomendações Agronômicas', style: pw.TextStyle(fontSize: 14)),
        pw.Text('9. Plano de Ação Sugerido', style: pw.TextStyle(fontSize: 14)),
        pw.Text('10. Anexos', style: pw.TextStyle(fontSize: 14)),
      ],
    );
  }

  /// Constrói o resumo executivo
  static pw.Widget _buildResumoExecutivo({
    required Map<String, dynamic> estatisticas,
    required Map<String, int> distribuicaoNiveis,
    required double areaHectares,
    required int totalPontos,
  }) {
    final media = estatisticas['media'] as double;
    final classificacao = _classificarTalhao(media);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. RESUMO EXECUTIVO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Parágrafo resumo
        pw.Text(
          'O presente relatório apresenta a análise de compactação do solo do talhão selecionado, '
          'totalizando ${areaHectares.toStringAsFixed(1)} hectares e ${totalPontos} pontos de coleta. '
          'A compactação média observada foi de ${media.toStringAsFixed(2)} MPa, '
          'classificando o talhão como $classificacao. '
          'Recomenda-se intervenção ${_getRecomendacaoResumo(classificacao)}.',
          style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
        ),
        
        pw.SizedBox(height: 30),
        
        // Cards de indicadores
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildCardIndicador('Área (ha)', areaHectares.toStringAsFixed(1), PdfColors.blue),
            _buildCardIndicador('Nº Pontos', totalPontos.toString(), PdfColors.green),
            _buildCardIndicador('Média (MPa)', media.toStringAsFixed(2), PdfColors.orange),
            _buildCardIndicador('Pontos Críticos', distribuicaoNiveis['Crítico']?.toString() ?? '0', PdfColors.red),
          ],
        ),
      ],
    );
  }

  /// Constrói informações da propriedade
  static pw.Widget _buildInformacoesPropriedade({
    required String nomeFazenda,
    required String nomeResponsavel,
    required String nomeTalhao,
    required double areaHectares,
    required LatLng centroTalhao,
    required int safraId,
    required DateTime dataColeta,
    required String operador,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '2. INFORMAÇÕES DA PROPRIEDADE',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Table(
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            _buildLinhaTabela('Fazenda:', nomeFazenda),
            _buildLinhaTabela('Responsável:', nomeResponsavel),
            _buildLinhaTabela('Talhão:', '$nomeTalhao — Área: ${areaHectares.toStringAsFixed(1)} ha'),
            _buildLinhaTabela('Coordenadas:', '${centroTalhao.latitude.toStringAsFixed(6)}, ${centroTalhao.longitude.toStringAsFixed(6)}'),
            _buildLinhaTabela('Safra:', safraId.toString()),
            _buildLinhaTabela('Data Coleta:', _formatarData(dataColeta)),
            _buildLinhaTabela('Operador:', operador),
          ],
        ),
      ],
    );
  }

  /// Constrói metodologia
  static pw.Widget _buildMetodologia({
    required int totalPontos,
    required double areaHectares,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '3. METODOLOGIA DE COLETA',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Text(
          '• Geração de Pontos: Automática a cada 10 hectares (${totalPontos} pontos gerados)',
          style: pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '• Método de Amostragem: Penetrometria com instrumento digital / profundidades 0–20 cm e 20–40 cm',
          style: pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '• GPS: Geolocalização via dispositivo móvel (precisão média: 3-5 m)',
          style: pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '• Observações Metodológicas: Coleta realizada em condições adequadas de umidade do solo',
          style: pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Constrói mapa de compactação
  static pw.Widget _buildMapaCompactacao({
    required List<SoilCompactionPointModel> pontos,
    required List<LatLng> polygonCoordinates,
    required Map<String, int> distribuicaoNiveis,
    String? mapaPath,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '4. MAPA DE COMPACTAÇÃO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Mapa real ou placeholder
        if (mapaPath != null && File(mapaPath).existsSync())
          pw.Image(
            pw.MemoryImage(File(mapaPath).readAsBytesSync()),
            width: double.infinity,
            height: 300,
            fit: pw.BoxFit.cover,
          )
        else
          pw.Container(
            width: double.infinity,
            height: 300,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Center(
              child: pw.Text(
                'MAPA DE COMPACTAÇÃO\n(Erro ao gerar imagem)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(color: PdfColors.grey600),
              ),
            ),
          ),
        
        pw.SizedBox(height: 20),
        
        // Legenda
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildItemLegenda('Solo Solto', PdfColors.green, distribuicaoNiveis['Solo Solto'] ?? 0),
            _buildItemLegenda('Moderado', PdfColors.yellow, distribuicaoNiveis['Moderado'] ?? 0),
            _buildItemLegenda('Alto', PdfColors.orange, distribuicaoNiveis['Alto'] ?? 0),
            _buildItemLegenda('Crítico', PdfColors.red, distribuicaoNiveis['Crítico'] ?? 0),
          ],
        ),
      ],
    );
  }

  /// Constrói tabela de pontos
  static pw.Widget _buildTabelaPontos(List<SoilCompactionPointModel> pontos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '5. DADOS DOS PONTOS',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FixedColumnWidth(50),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(80),
            4: const pw.FixedColumnWidth(60),
            5: const pw.FixedColumnWidth(60),
            6: const pw.FixedColumnWidth(60),
            7: const pw.FixedColumnWidth(60),
            8: const pw.FixedColumnWidth(60),
            9: const pw.FixedColumnWidth(60),
            10: const pw.FlexColumnWidth(1),
          },
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Código', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Lat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Lon', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Prof. (cm)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Penetr. (MPa)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Umidade (%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Textura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Estrutura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Nível', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Observações', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            
            // Dados
            ...pontos.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final ponto = entry.value;
              final nivel = ponto.penetrometria != null ? ponto.calcularNivelCompactacao() : 'N/A';
              
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(index.toString(), style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.pointCode, style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.latitude.toStringAsFixed(4), style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.longitude.toStringAsFixed(4), style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('${ponto.profundidadeInicio}-${ponto.profundidadeFim}', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.penetrometria?.toStringAsFixed(2) ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.umidade?.toStringAsFixed(1) ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.textura ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.estrutura ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(nivel, style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(ponto.observacoes ?? '', style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Constrói análises estatísticas
  static pw.Widget _buildAnalisesEstatisticas({
    required Map<String, dynamic> estatisticas,
    required Map<String, int> distribuicaoNiveis,
    String? graficoPath,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '6. ANÁLISE DE COMPACTAÇÃO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Text(
          'Distribuição de níveis de compactação',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        
        pw.SizedBox(height: 20),
        
        // Gráfico de pizza real ou placeholder
        if (graficoPath != null && File(graficoPath).existsSync())
          pw.Image(
            pw.MemoryImage(File(graficoPath).readAsBytesSync()),
            width: 200,
            height: 200,
            fit: pw.BoxFit.cover,
          )
        else
          pw.Container(
            width: 200,
            height: 200,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'GRÁFICO DE PIZZA\n(Erro ao gerar gráfico)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
              ),
            ),
          ),
        
        pw.SizedBox(height: 20),
        
        // Estatísticas
        pw.Table(
          columnWidths: {
            0: const pw.FixedColumnWidth(120),
            1: const pw.FixedColumnWidth(80),
          },
          children: [
            _buildLinhaTabela('Média:', '${estatisticas['media'].toStringAsFixed(2)} MPa'),
            _buildLinhaTabela('Mínimo:', '${estatisticas['minimo'].toStringAsFixed(2)} MPa'),
            _buildLinhaTabela('Máximo:', '${estatisticas['maximo'].toStringAsFixed(2)} MPa'),
            _buildLinhaTabela('Desvio Padrão:', '${estatisticas['desvio_padrao'].toStringAsFixed(2)} MPa'),
            _buildLinhaTabela('CV (%):', '${estatisticas['coeficiente_variacao'].toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  /// Constrói diagnósticos
  static pw.Widget _buildDiagnosticos(List<SoilDiagnosticModel> diagnosticos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '7. DIAGNÓSTICOS POR PONTO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        ...diagnosticos.map((diagnostico) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ponto ${diagnostico.pointId} - ${diagnostico.tipoDiagnostico}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Severidade: ${diagnostico.severidade}', style: const pw.TextStyle(fontSize: 10)),
              if (diagnostico.profundidadeAfetada != null)
                pw.Text('Profundidade: ${diagnostico.profundidadeAfetada}', style: const pw.TextStyle(fontSize: 10)),
              if (diagnostico.culturaImpactada != null)
                pw.Text('Cultura: ${diagnostico.culturaImpactada}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// Constrói recomendações
  static pw.Widget _buildRecomendacoes(List<String> recomendacoes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '8. RECOMENDAÇÕES',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        ...recomendacoes.map((recomendacao) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(recomendacao, style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// Constrói plano de ação
  static pw.Widget _buildPlanoAcao(List<String> recomendacoes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '9. PLANO DE AÇÃO SUGERIDO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(100),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(80),
          },
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Período', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Ação', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Prioridade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Responsável', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            
            // Ações
            _buildLinhaPlanoAcao('Imediato', 'Subsolagem em áreas críticas', 'Alta', 'Técnico'),
            _buildLinhaPlanoAcao('1-3 meses', 'Implementar plantas de cobertura', 'Média', 'Fazendeiro'),
            _buildLinhaPlanoAcao('3-6 meses', 'Monitoramento pós-intervenção', 'Média', 'Técnico'),
            _buildLinhaPlanoAcao('6-12 meses', 'Avaliação de resultados', 'Baixa', 'Agrônomo'),
          ],
        ),
      ],
    );
  }

  // Métodos auxiliares

  static pw.Widget _buildCardIndicador(String titulo, String valor, PdfColor cor) {
    return pw.Container(
      width: 80,
      height: 60,
      decoration: pw.BoxDecoration(
        color: cor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildLinhaTabela(String label, String valor) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(valor, style: const pw.TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  static pw.TableRow _buildLinhaPlanoAcao(String periodo, String acao, String prioridade, String responsavel) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(periodo, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(acao, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(prioridade, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(responsavel, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  static pw.Widget _buildItemLegenda(String label, PdfColor cor, int quantidade) {
    return pw.Column(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: cor,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text('($quantidade)', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static Map<String, dynamic> _calcularEstatisticasCompletas(List<SoilCompactionPointModel> pontos) {
    return SoilAnalysisService.calcularEstatisticas(pontos);
  }

  static Map<String, int> _calcularDistribuicaoNiveis(List<SoilCompactionPointModel> pontos) {
    final distribuicao = SoilAnalysisService.calcularDistribuicaoPercentual(pontos);
    // Converte de double para int (percentual para contagem)
    return {
      'Solto': (distribuicao['Solto'] ?? 0.0 * pontos.length / 100).round(),
      'Moderado': (distribuicao['Moderado'] ?? 0.0 * pontos.length / 100).round(),
      'Alto': (distribuicao['Alto'] ?? 0.0 * pontos.length / 100).round(),
      'Crítico': (distribuicao['Crítico'] ?? 0.0 * pontos.length / 100).round(),
    };
  }

  static Future<String> _gerarGraficoPizza(Map<String, int> distribuicao, String nomeTalhao) async {
    try {
      // Cria o widget do gráfico
      final chartWidget = SoilCompactionPieChart(
        distribuicaoNiveis: distribuicao,
        size: 300,
        showLegend: true,
        showCenterText: true,
      );

      // Converte widget para imagem usando o novo serviço
      final imageBytes = await WidgetToImageService.widgetToImageWithSize(
        chartWidget,
        width: 400,
        height: 300,
        pixelRatio: 2.0, // Alta resolução
      );
      
      // Salva a imagem
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/grafico_pizza_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      
      return file.path;
    } catch (e) {
      print('Erro ao gerar gráfico pizza: $e');
      return '';
    }
  }

  static List<String> _gerarRecomendacoesCompletas(
    List<SoilCompactionPointModel> pontos,
    List<SoilDiagnosticModel>? diagnosticos,
    List<SoilLaboratorySampleModel>? amostras,
  ) {
    final recomendacoes = <String>[];
    
    // Recomendações baseadas na compactação
    final estatisticas = SoilAnalysisService.calcularEstatisticas(pontos);
    final media = estatisticas['media'] as double;
    
    if (media > 2.5) {
      recomendacoes.add('Subsolagem na entrelinha (35-40 cm de profundidade)');
      recomendacoes.add('Evitar tráfego de máquinas em solo úmido');
    } else if (media > 2.0) {
      recomendacoes.add('Uso de plantas de cobertura');
      recomendacoes.add('Reduzir tráfego de máquinas');
    }
    
    recomendacoes.add('Calibrar pressão de pneus');
    recomendacoes.add('Implementar plantio direto controlado');
    
    return recomendacoes;
  }

  static String _classificarTalhao(double media) {
    if (media < 1.5) return 'Adequado';
    if (media < 2.0) return 'Moderado';
    if (media < 2.5) return 'Alto';
    return 'Crítico';
  }

  static String _getRecomendacaoResumo(String classificacao) {
    switch (classificacao) {
      case 'Adequado':
        return 'manutenção das práticas atuais';
      case 'Moderado':
        return 'implementação de práticas conservacionistas';
      case 'Alto':
        return 'intervenção preventiva';
      case 'Crítico':
        return 'intervenção urgente';
      default:
        return 'avaliação adicional';
    }
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// Gera gráfico de pizza como imagem
}
