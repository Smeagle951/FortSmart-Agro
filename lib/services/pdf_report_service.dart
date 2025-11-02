import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/planting_quality_report_model.dart';
import '../utils/logger.dart';

/// Serviço para geração e compartilhamento de PDFs de relatórios
class PDFReportService {
  static const String _tag = 'PDFReportService';

  /// Gera PDF do relatório de qualidade de plantio
  Future<File> gerarPDFRelatorio(PlantingQualityReportModel relatorio) async {
    try {
      Logger.info('$_tag: Iniciando geração de PDF do relatório com template: $_templateSelecionado');

      // Verificar cache primeiro
      final arquivoCache = _obterDoCache(relatorio);
      if (arquivoCache != null) {
        Logger.info('$_tag: ✅ Retornando PDF do cache');
        return arquivoCache;
      }

      // Criar documento PDF
      final pdf = pw.Document();
    
      // Adicionar página principal baseada no template selecionado
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildCabecalhoPDF(relatorio),
              pw.SizedBox(height: 20),
              _buildResumoTalhaoPDF(relatorio),
              pw.SizedBox(height: 20),
              _buildResultadosPrincipaisPDF(relatorio),
              pw.SizedBox(height: 20),
              _buildAnaliseAutomaticaPDF(relatorio),
              pw.SizedBox(height: 20),
              // Adicionar imagem do estande se disponível
              if (relatorio.imagemEstandePath != null && relatorio.imagemEstandePath!.isNotEmpty) ...[
                _buildImagemEstandePDF(relatorio),
                pw.SizedBox(height: 20),
              ],
              _buildGraficosPDF(relatorio),
              pw.SizedBox(height: 20),
              _buildRodapePDF(relatorio),
            ];
          },
        ),
      );

      // Salvar PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/relatorio_qualidade_plantio_${relatorio.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Adicionar ao cache
      _adicionarAoCache(relatorio, file);

      Logger.info('$_tag: ✅ PDF gerado com sucesso: ${file.path}');
      return file;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao gerar PDF: $e');
      rethrow;
    }
  }

  /// Cabeçalho do PDF
  pw.Widget _buildCabecalhoPDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue600],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'FS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
              pw.Text(
                      'Relatorio FortSmart - Qualidade de Plantio',
                style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
              pw.Text(
                      'Talhão: ${relatorio.talhaoNome}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItemPDF('Área avaliada', '${relatorio.areaHectares.toStringAsFixed(2)} ha'),
              ),
              pw.Expanded(
                child: _buildInfoItemPDF('Data', _formatDate(relatorio.dataAvaliacao)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildInfoItemPDF('Executor', relatorio.executor),
        ],
        ),
      );
    }
    
  /// Item de informação do PDF
  pw.Widget _buildInfoItemPDF(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
              pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontSize: 10,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
              ),
            ],
          );
  }

  /// Resumo do talhão no PDF
  pw.Widget _buildResumoTalhaoPDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumo do Talhão',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildResumoItemPDF('Cultura', relatorio.culturaNome),
              ),
              pw.Expanded(
                child: _buildResumoItemPDF('Variedade', relatorio.variedade.isNotEmpty ? relatorio.variedade : 'Não informada'),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildResumoItemPDF('Data de plantio', _formatDate(relatorio.dataPlantio)),
              ),
              pw.Expanded(
                child: _buildResumoItemPDF('Safra', relatorio.safra.isNotEmpty ? relatorio.safra : 'Não informada'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de resumo do PDF
  pw.Widget _buildResumoItemPDF(String label, String value) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey600,
            fontSize: 10,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Resultados principais no PDF
  pw.Widget _buildResultadosPrincipaisPDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
            'Qualidade de Plantio',
                      style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildMetricaPDF('CV – Coeficiente de Variação', '${relatorio.coeficienteVariacao.toStringAsFixed(2)}%', relatorio.classificacaoCV),
          pw.SizedBox(height: 8),
          _buildMetricaPDF('Singulação', '${relatorio.singulacao.toStringAsFixed(2)}%', relatorio.singulacao >= 95 ? 'Excelente' : 'Boa'),
          pw.SizedBox(height: 8),
          _buildMetricaPDF('Plantas por hectare', '${_formatNumber(relatorio.populacaoEstimadaPorHectare)} plantas/ha', 'População estimada'),
          pw.SizedBox(height: 8),
          _buildMetricaPDF('Plantas por metro', '${relatorio.plantasPorMetro.toStringAsFixed(1)} plantas/m', 'Densidade linear'),
          pw.SizedBox(height: 8),
          _buildMetricaPDF('% Plantas duplas', '${relatorio.plantasDuplas.toStringAsFixed(2)}%', relatorio.plantasDuplas <= 3 ? 'Aceitável' : 'Atenção'),
          pw.SizedBox(height: 8),
          _buildMetricaPDF('% Plantas falhadas', '${relatorio.plantasFalhadas.toStringAsFixed(2)}%', relatorio.plantasFalhadas <= 3 ? 'Aceitável' : 'Atenção'),
        ],
      ),
    );
  }

  /// Métrica no PDF
  pw.Widget _buildMetricaPDF(String titulo, String valor, String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  titulo,
              style: pw.TextStyle(
                fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  valor,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              status,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Análise automática no PDF
  pw.Widget _buildAnaliseAutomaticaPDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Análise Automática FortSmart',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            relatorio.analiseAutomatica,
            style: pw.TextStyle(
              color: PdfColors.amber800,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 8),
              pw.Text(
            'Sugestões:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber800,
              fontSize: 11,
            ),
          ),
              pw.Text(
            relatorio.sugestoes,
            style: pw.TextStyle(
              color: PdfColors.amber700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Gráficos no PDF
  pw.Widget _buildGraficosPDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
                  pw.Text(
            'Gráficos de Análise',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Distribuição de Plantas',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  pw.Container(
                      width: 80,
                      height: 80,
                    decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.green200,
                    ),
                      child: pw.Center(
                    child: pw.Text(
                          '${(100 - relatorio.plantasDuplas - relatorio.plantasFalhadas).toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                            color: PdfColors.green800,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ),
                  ),
                ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  children: [
          pw.Text(
                      'População Alvo vs Real',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text('Alvo', style: pw.TextStyle(fontSize: 8)),
                            pw.Container(
                              width: 20,
                              height: 40,
                              color: PdfColors.blue300,
                              child: pw.Center(
                                child: pw.Text(
                                  '${(relatorio.populacaoAlvo / 1000).toStringAsFixed(0)}k',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text('Real', style: pw.TextStyle(fontSize: 8)),
                            pw.Container(
                              width: 20,
                              height: (relatorio.populacaoReal / relatorio.populacaoAlvo) * 40,
                              color: PdfColors.green400,
                              child: pw.Center(
                                child: pw.Text(
                                  '${(relatorio.populacaoReal / 1000).toStringAsFixed(0)}k',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Imagem do Estande no PDF
  pw.Widget _buildImagemEstandePDF(PlantingQualityReportModel relatorio) {
    try {
      final imagePath = relatorio.imagemEstandePath!;
      Logger.info('$_tag: Carregando imagem do estande: $imagePath');
      
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        Logger.warning('$_tag: Arquivo de imagem não encontrado: $imagePath');
        return pw.Container();
      }
      
      final imageBytes = imageFile.readAsBytesSync();
      if (imageBytes.isEmpty) {
        Logger.warning('$_tag: Arquivo de imagem vazio');
        return pw.Container();
      }
      
      final image = pw.MemoryImage(imageBytes);
      Logger.info('$_tag: Imagem carregada com sucesso (${imageBytes.length} bytes)');
      
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Imagem do Estande',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                constraints: const pw.BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 450,
                ),
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      Logger.error('$_tag: Erro ao carregar imagem do estande: $e');
      Logger.error('Stack: $stack');
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.red300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Erro ao carregar imagem do estande',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.red,
          ),
        ),
      );
    }
  }

  /// Rodapé do PDF
  pw.Widget _buildRodapePDF(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Dados registrados via FortSmart App',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Coleta em: ${_formatDateTime(relatorio.createdAt)}',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dados rastreaveis - Relatorio Premium',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 10,
            ),
          ),
        ],
        ),
      );
    }
    
  /// Compartilha PDF via WhatsApp
  Future<void> compartilharPDFViaWhatsApp(File pdfFile, PlantingQualityReportModel relatorio) async {
    try {
      Logger.info('$_tag: Iniciando compartilhamento via WhatsApp');

      // Verificar permissões
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Preparar texto para compartilhamento
      final textoCompartilhamento = '''
*Relatorio FortSmart - Qualidade de Plantio*

*Talhao:* ${relatorio.talhaoNome}
*Area:* ${relatorio.areaHectares.toStringAsFixed(2)} ha
*Data:* ${_formatDate(relatorio.dataAvaliacao)}
*Executor:* ${relatorio.executor}

*Resultados Principais:*
• CV%: ${relatorio.coeficienteVariacao.toStringAsFixed(2)}% (${relatorio.classificacaoCV})
• Singulacao: ${relatorio.singulacao.toStringAsFixed(2)}%
• Plantas/ha: ${_formatNumber(relatorio.populacaoEstimadaPorHectare)}
• Plantas/m: ${relatorio.plantasPorMetro.toStringAsFixed(1)}

*Status Geral:* ${relatorio.statusGeral}

*Gerado via FortSmart App*
*Dados rastreaveis - Relatorio Premium*
      ''';

      // Compartilhar arquivo
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: textoCompartilhamento,
        subject: 'Relatório de Qualidade de Plantio - ${relatorio.talhaoNome}',
      );

      Logger.info('$_tag: ✅ Compartilhamento via WhatsApp realizado com sucesso');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao compartilhar via WhatsApp: $e');
      rethrow;
    }
  }

  /// Compartilha PDF via outros aplicativos
  Future<void> compartilharPDF(File pdfFile, PlantingQualityReportModel relatorio) async {
    try {
      Logger.info('$_tag: Iniciando compartilhamento de PDF');

      // Preparar texto para compartilhamento
      final textoCompartilhamento = '''
Relatorio FortSmart - Qualidade de Plantio

Talhao: ${relatorio.talhaoNome}
Area: ${relatorio.areaHectares.toStringAsFixed(2)} ha
Data: ${_formatDate(relatorio.dataAvaliacao)}
Executor: ${relatorio.executor}

Resultados Principais:
• CV%: ${relatorio.coeficienteVariacao.toStringAsFixed(2)}% (${relatorio.classificacaoCV})
• Singulacao: ${relatorio.singulacao.toStringAsFixed(2)}%
• Plantas/ha: ${_formatNumber(relatorio.populacaoEstimadaPorHectare)}
• Plantas/m: ${relatorio.plantasPorMetro.toStringAsFixed(1)}

Status Geral: ${relatorio.statusGeral}

Gerado via FortSmart App
Dados rastreaveis - Relatorio Premium
      ''';

      // Compartilhar arquivo
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: textoCompartilhamento,
        subject: 'Relatório de Qualidade de Plantio - ${relatorio.talhaoNome}',
      );

      Logger.info('$_tag: ✅ Compartilhamento de PDF realizado com sucesso');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao compartilhar PDF: $e');
      rethrow;
    }
  }

  /// Formata data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formata data e hora para exibição
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} – ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formata número com separadores de milhares
  String _formatNumber(double number) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]}.');
  }

  /// Visualiza PDF em tela cheia
  Future<void> visualizarPDF(BuildContext context, PlantingQualityReportModel relatorio) async {
    try {
      Logger.info('$_tag: Iniciando visualização de PDF');

      // Gerar PDF
      final pdfFile = await gerarPDFRelatorio(relatorio);
      
      // Compartilhar PDF para visualização
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Relatório de Qualidade de Plantio - ${relatorio.talhaoNome}',
        subject: 'Relatório FortSmart - ${relatorio.culturaNome}',
      );

      Logger.info('$_tag: ✅ PDF compartilhado para visualização');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao visualizar PDF: $e');
      rethrow;
    }
  }

  /// Templates disponíveis para relatórios
  static const Map<String, String> _templates = {
    'fortsmart_padrao': 'Template FortSmart Padrão',
    'minimalista': 'Template Minimalista',
    'detalhado': 'Template Detalhado',
    'executivo': 'Template Executivo',
  };

  /// Template selecionado (padrão: fortsmart_padrao)
  String _templateSelecionado = 'fortsmart_padrao';

  /// Cache de relatórios gerados
  final Map<String, File> _cacheRelatorios = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Duração do cache em horas
  static const int _cacheDurationHours = 24;

  /// Define o template a ser usado
  void setTemplate(String template) {
    if (_templates.containsKey(template)) {
      _templateSelecionado = template;
      Logger.info('$_tag: Template alterado para: $template');
    }
  }

  /// Obtém o template atual
  String get templateAtual => _templateSelecionado;

  /// Obtém todos os templates disponíveis
  Map<String, String> get templatesDisponiveis => Map.from(_templates);

  /// Gera chave única para o cache baseada no relatório e template
  String _gerarChaveCache(PlantingQualityReportModel relatorio) {
    return '${relatorio.id}_${_templateSelecionado}';
  }

  /// Verifica se o cache é válido
  bool _isCacheValido(String chave) {
    if (!_cacheTimestamps.containsKey(chave)) return false;
    
    final timestamp = _cacheTimestamps[chave]!;
    final agora = DateTime.now();
    final diferenca = agora.difference(timestamp);
    
    return diferenca.inHours < _cacheDurationHours;
  }

  /// Obtém relatório do cache se válido
  File? _obterDoCache(PlantingQualityReportModel relatorio) {
    final chave = _gerarChaveCache(relatorio);
    
    if (_cacheRelatorios.containsKey(chave) && _isCacheValido(chave)) {
      Logger.info('$_tag: ✅ Relatório encontrado no cache: $chave');
      return _cacheRelatorios[chave];
    }
    
    // Remove do cache se expirado
    if (_cacheRelatorios.containsKey(chave)) {
      _cacheRelatorios.remove(chave);
      _cacheTimestamps.remove(chave);
      Logger.info('$_tag: 🗑️ Cache expirado removido: $chave');
    }
    
    return null;
  }

  /// Adiciona relatório ao cache
  void _adicionarAoCache(PlantingQualityReportModel relatorio, File arquivo) {
    final chave = _gerarChaveCache(relatorio);
    
    _cacheRelatorios[chave] = arquivo;
    _cacheTimestamps[chave] = DateTime.now();
    
    Logger.info('$_tag: 💾 Relatório adicionado ao cache: $chave');
  }

  /// Limpa cache expirado
  void _limparCacheExpirado() {
    final chavesExpiradas = <String>[];
    
    for (final chave in _cacheTimestamps.keys) {
      if (!_isCacheValido(chave)) {
        chavesExpiradas.add(chave);
      }
    }
    
    for (final chave in chavesExpiradas) {
      _cacheRelatorios.remove(chave);
      _cacheTimestamps.remove(chave);
    }
    
    if (chavesExpiradas.isNotEmpty) {
      Logger.info('$_tag: 🧹 Cache limpo: ${chavesExpiradas.length} itens expirados removidos');
    }
  }

  /// Limpa todo o cache
  void limparCache() {
    _cacheRelatorios.clear();
    _cacheTimestamps.clear();
    Logger.info('$_tag: 🗑️ Cache completamente limpo');
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> obterEstatisticasCache() {
    _limparCacheExpirado();
    
    return {
      'total_itens': _cacheRelatorios.length,
      'itens_validos': _cacheRelatorios.length,
      'template_atual': _templateSelecionado,
      'duracao_cache_horas': _cacheDurationHours,
    };
  }

  /// Gera relatório comparativo entre múltiplos relatórios
  Future<File> gerarRelatorioComparativo(List<PlantingQualityReportModel> relatorios) async {
    try {
      Logger.info('$_tag: Iniciando geração de relatório comparativo com ${relatorios.length} relatórios');

      final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
              _buildCabecalhoComparativo(relatorios),
            pw.SizedBox(height: 20),
              _buildTabelaComparativa(relatorios),
            pw.SizedBox(height: 20),
              _buildGraficoComparativo(relatorios),
              pw.SizedBox(height: 20),
              _buildAnaliseComparativa(relatorios),
              pw.SizedBox(height: 20),
              _buildRankingComparativo(relatorios),
            pw.SizedBox(height: 20),
              _buildRodapeComparativo(relatorios),
          ];
        },
      ),
    );
    
      // Salvar PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/relatorio_comparativo_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      Logger.info('$_tag: ✅ Relatório comparativo gerado: ${file.path}');
    return file;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao gerar relatório comparativo: $e');
      rethrow;
    }
  }

  /// Visualiza PDF com preview customizado
  Future<void> visualizarPDFComPreview(BuildContext context, PlantingQualityReportModel relatorio) async {
    try {
      Logger.info('$_tag: Iniciando visualização de PDF com preview');

      // Gerar PDF
      final pdfFile = await gerarPDFRelatorio(relatorio);
      
      // Mostrar preview customizado
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Cabeçalho do preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preview: Relatório ${relatorio.talhaoNome}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Preview do PDF (simplificado)
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'PDF Gerado com Sucesso!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Arquivo: ${pdfFile.path.split('/').last}',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Botões de ação
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await compartilharPDFViaWhatsApp(pdfFile, relatorio);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await compartilharPDF(pdfFile, relatorio);
                        },
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Compartilhar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Logger.info('$_tag: ✅ PDF preview exibido com sucesso');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao visualizar PDF com preview: $e');
      rethrow;
    }
  }

  /// Obtém margens baseadas no template
  pw.EdgeInsets _getMarginsTemplate() {
    switch (_templateSelecionado) {
      case 'minimalista':
        return const pw.EdgeInsets.all(40);
      case 'detalhado':
        return const pw.EdgeInsets.all(20);
      case 'executivo':
        return const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 25);
      default: // fortsmart_padrao
        return const pw.EdgeInsets.all(32);
    }
  }

  /// Constrói conteúdo baseado no template selecionado
  List<pw.Widget> _buildConteudoTemplate(PlantingQualityReportModel relatorio) {
    switch (_templateSelecionado) {
      case 'minimalista':
        return _buildTemplateMinimalista(relatorio);
      case 'detalhado':
        return _buildTemplateDetalhado(relatorio);
      case 'executivo':
        return _buildTemplateExecutivo(relatorio);
      default: // fortsmart_padrao
        return _buildTemplateFortSmartPadrao(relatorio);
    }
  }

  /// Template FortSmart Padrão
  List<pw.Widget> _buildTemplateFortSmartPadrao(PlantingQualityReportModel relatorio) {
          return [
      _buildCabecalhoPDF(relatorio),
      pw.SizedBox(height: 20),
      _buildResumoTalhaoPDF(relatorio),
      pw.SizedBox(height: 20),
      _buildResultadosPrincipaisPDF(relatorio),
      pw.SizedBox(height: 20),
      _buildAnaliseAutomaticaPDF(relatorio),
      pw.SizedBox(height: 20),
      _buildGraficosPDF(relatorio),
      pw.SizedBox(height: 20),
      _buildRodapePDF(relatorio),
    ];
  }

  /// Template Minimalista
  List<pw.Widget> _buildTemplateMinimalista(PlantingQualityReportModel relatorio) {
    return [
      _buildCabecalhoMinimalista(relatorio),
      pw.SizedBox(height: 30),
      _buildMetricasMinimalistas(relatorio),
      pw.SizedBox(height: 30),
      _buildAnaliseMinimalista(relatorio),
            pw.SizedBox(height: 20),
      _buildRodapeMinimalista(relatorio),
    ];
  }

  /// Template Detalhado
  List<pw.Widget> _buildTemplateDetalhado(PlantingQualityReportModel relatorio) {
    return [
      _buildCabecalhoDetalhado(relatorio),
      pw.SizedBox(height: 15),
      _buildResumoTalhaoDetalhado(relatorio),
      pw.SizedBox(height: 15),
      _buildResultadosDetalhados(relatorio),
      pw.SizedBox(height: 15),
      _buildAnaliseDetalhada(relatorio),
      pw.SizedBox(height: 15),
      _buildGraficosDetalhados(relatorio),
      pw.SizedBox(height: 15),
      _buildTabelasDetalhadas(relatorio),
      pw.SizedBox(height: 15),
      _buildRodapeDetalhado(relatorio),
    ];
  }

  /// Template Executivo
  List<pw.Widget> _buildTemplateExecutivo(PlantingQualityReportModel relatorio) {
    return [
      _buildCabecalhoExecutivo(relatorio),
      pw.SizedBox(height: 25),
      _buildResumoExecutivo(relatorio),
      pw.SizedBox(height: 25),
      _buildMetricasExecutivas(relatorio),
      pw.SizedBox(height: 25),
      _buildAnaliseExecutiva(relatorio),
            pw.SizedBox(height: 20),
      _buildRodapeExecutivo(relatorio),
    ];
  }

  // Métodos para template minimalista
  pw.Widget _buildCabecalhoMinimalista(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Relatório de Qualidade de Plantio',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${relatorio.talhaoNome} • ${DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao)}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricasMinimalistas(PlantingQualityReportModel relatorio) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricaMinimalista('CV%', '${relatorio.coeficienteVariacao.toStringAsFixed(1)}%', 'CV'),
        _buildMetricaMinimalista('Singulacao', '${relatorio.singulacao.toStringAsFixed(1)}%', 'OK'),
        _buildMetricaMinimalista('Plantas/ha', '${(relatorio.populacaoEstimadaPorHectare / 1000).toStringAsFixed(0)}k', 'PL'),
      ],
    );
  }

  pw.Widget _buildMetricaMinimalista(String titulo, String valor, String emoji) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(emoji, style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          )),
          pw.SizedBox(height: 8),
          pw.Text(titulo, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.Text(valor, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildAnaliseMinimalista(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Análise',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            relatorio.analiseAutomatica,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRodapeMinimalista(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FortSmart App',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm').format(relatorio.createdAt),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // Métodos para template detalhado
  pw.Widget _buildCabecalhoDetalhado(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
            child: pw.Text(
                'FS',
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
              ),
            ),
          ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Relatório FortSmart - Qualidade de Plantio',
              style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${relatorio.talhaoNome} • ${relatorio.culturaNome}',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
                ),
                pw.Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao)} • Executor: ${relatorio.executor}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildResumoTalhaoDetalhado(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informações do Talhão',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoDetalhada('Talhão', relatorio.talhaoNome),
              ),
              pw.Expanded(
                child: _buildInfoDetalhada('Cultura', relatorio.culturaNome),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoDetalhada('Área', '${relatorio.areaHectares.toStringAsFixed(2)} ha'),
              ),
              pw.Expanded(
                child: _buildInfoDetalhada('Data Plantio', DateFormat('dd/MM/yyyy').format(relatorio.dataPlantio)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoDetalhada(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildResultadosDetalhados(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resultados Detalhados',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _buildTabelaDetalhada(relatorio),
        ],
      ),
    );
  }

  pw.Widget _buildTabelaDetalhada(PlantingQualityReportModel relatorio) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        _buildLinhaTabela(['Métrica', 'Valor', 'Status'], isHeader: true),
        _buildLinhaTabela(['CV%', '${relatorio.coeficienteVariacao.toStringAsFixed(1)}%', relatorio.classificacaoCV]),
        _buildLinhaTabela(['Singulacao', '${relatorio.singulacao.toStringAsFixed(1)}%', 'OK']),
        _buildLinhaTabela(['Plantas/m', '${relatorio.plantasPorMetro.toStringAsFixed(1)}', 'PL']),
        _buildLinhaTabela(['Plantas/ha', '${_formatNumber(relatorio.populacaoEstimadaPorHectare)}', 'TOT']),
        _buildLinhaTabela(['Duplas', '${relatorio.plantasDuplas.toStringAsFixed(1)}%', 'ATN']),
        _buildLinhaTabela(['Falhas', '${relatorio.plantasFalhadas.toStringAsFixed(1)}%', 'ERR']),
      ],
    );
  }

  pw.TableRow _buildLinhaTabela(List<String> valores, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: valores.map((valor) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: isHeader ? 12 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      )).toList(),
    );
  }

  pw.Widget _buildAnaliseDetalhada(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
            'Análise Automática Detalhada',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
          pw.SizedBox(height: 12),
              pw.Text(
            relatorio.analiseAutomatica,
            style: const pw.TextStyle(fontSize: 12),
          ),
          if (relatorio.sugestoes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Sugestões:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '• ${relatorio.sugestoes}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildGraficosDetalhados(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Visualizações Gráficas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildGraficoSimples('Singulação', relatorio.singulacao, PdfColors.green),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildGraficoSimples('CV%', relatorio.coeficienteVariacao, PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildGraficoSimples(String titulo, double valor, PdfColor cor) {
    return pw.Container(
      height: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${valor.toStringAsFixed(1)}%',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTabelasDetalhadas(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Comparação com Metas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              _buildLinhaTabela(['Métrica', 'Meta', 'Real', 'Desvio'], isHeader: true),
              _buildLinhaTabela([
                'População/ha',
                '${_formatNumber(relatorio.populacaoAlvo)}',
                '${_formatNumber(relatorio.populacaoReal)}',
                '${_formatNumber(relatorio.desvioPopulacao)}'
              ]),
              _buildLinhaTabela([
                'Eficácia',
                '95%',
                '${relatorio.eficaciaEmergencia.toStringAsFixed(1)}%',
                '${(relatorio.eficaciaEmergencia - 95).toStringAsFixed(1)}%'
              ]),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRodapeDetalhado(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
                'FortSmart App v${relatorio.appVersion}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
                'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(relatorio.createdAt)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Relatório Premium - Dados Rastreáveis',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
  
  // Métodos para template executivo
  pw.Widget _buildCabecalhoExecutivo(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Center(
      child: pw.Text(
                    'FS',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RELATÓRIO EXECUTIVO',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Qualidade de Plantio - ${relatorio.talhaoNome}',
                      style: const pw.TextStyle(fontSize: 16, color: PdfColors.white),
                    ),
                    pw.Text(
                      '${relatorio.culturaNome} • ${DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao)}',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildResumoExecutivo(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMO EXECUTIVO',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Status Geral',
                  relatorio.statusGeral,
                  relatorio.emojiStatusGeral,
                  PdfColors.blue800,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Area Avaliada',
                  '${relatorio.areaHectares.toStringAsFixed(2)} ha',
                  'AR',
                  PdfColors.green700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Executor',
                  relatorio.executor,
                  'EX',
                  PdfColors.orange700,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Data Avaliacao',
                  DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao),
                  'DT',
                  PdfColors.purple700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildMetricaExecutiva(String titulo, String valor, String emoji, PdfColor cor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(emoji, style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(width: 8),
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricasExecutivas(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MÉTRICAS PRINCIPAIS',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'CV%',
                  '${relatorio.coeficienteVariacao.toStringAsFixed(1)}%',
                  'CV',
                  PdfColors.orange700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Singulacao',
                  '${relatorio.singulacao.toStringAsFixed(1)}%',
                  'OK',
                  PdfColors.green700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildMetricaExecutiva(
                  'Plantas/ha',
                  '${(relatorio.populacaoEstimadaPorHectare / 1000).toStringAsFixed(0)}k',
                  'PL',
                  PdfColors.blue700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAnaliseExecutiva(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANÁLISE ESTRATÉGICA',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            relatorio.analiseAutomatica,
            style: const pw.TextStyle(fontSize: 14),
          ),
          if (relatorio.sugestoes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'RECOMENDAÇÕES:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '• ${relatorio.sugestoes}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
  
  pw.Widget _buildRodapeExecutivo(PlantingQualityReportModel relatorio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FortSmart Agro Intelligence',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
              pw.Text(
            '${DateFormat('dd/MM/yyyy HH:mm').format(relatorio.createdAt)} • v${relatorio.appVersion}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Constrói cabeçalho do relatório comparativo
  pw.Widget _buildCabecalhoComparativo(List<PlantingQualityReportModel> relatorios) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RELATORIO COMPARATIVO - QUALIDADE DE PLANTIO',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Analise Comparativa de ${relatorios.length} Plantios',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Data de Geração: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Constrói tabela comparativa
  pw.Widget _buildTabelaComparativa(List<PlantingQualityReportModel> relatorios) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TABELA COMPARATIVA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Cabeçalho da tabela
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildCelulaTabela('Talhão', isHeader: true),
                  _buildCelulaTabela('CV%', isHeader: true),
                  _buildCelulaTabela('Eficiência', isHeader: true),
                  _buildCelulaTabela('Classificação', isHeader: true),
                  _buildCelulaTabela('Data', isHeader: true),
                ],
              ),
              // Dados dos relatórios
              ...relatorios.map((relatorio) => pw.TableRow(
                children: [
                  _buildCelulaTabela(relatorio.talhaoNome),
                  _buildCelulaTabela('${relatorio.coeficienteVariacao.toStringAsFixed(1)}%'),
                  _buildCelulaTabela('${relatorio.eficaciaEmergencia.toStringAsFixed(1)}%'),
                  _buildCelulaTabela(relatorio.classificacaoCV),
                  _buildCelulaTabela(DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao)),
                ],
              )).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói célula da tabela
  pw.Widget _buildCelulaTabela(String texto, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue800 : PdfColors.black,
        ),
      ),
    );
  }

  /// Constrói gráfico comparativo
  pw.Widget _buildGraficoComparativo(List<PlantingQualityReportModel> relatorios) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GRÁFICO COMPARATIVO - CV%',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildGraficoComparativoSimples(relatorios),
        ],
      ),
    );
  }

  /// Constrói gráfico comparativo simples
  pw.Widget _buildGraficoComparativoSimples(List<PlantingQualityReportModel> relatorios) {
    final maxCv = relatorios.map((r) => r.coeficienteVariacao).reduce((a, b) => a > b ? a : b);
    final barHeight = 20.0;
    final maxWidth = 200.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: relatorios.map((relatorio) {
          final barWidth = (relatorio.coeficienteVariacao / maxCv) * maxWidth;
          final cor = _getCorClassificacao(relatorio.classificacaoCV);
          
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    relatorio.talhaoNome,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: pw.BoxDecoration(
                    color: cor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '${relatorio.coeficienteVariacao.toStringAsFixed(1)}%',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Constrói análise comparativa
  pw.Widget _buildAnaliseComparativa(List<PlantingQualityReportModel> relatorios) {
    final melhorCv = relatorios.reduce((a, b) => a.coeficienteVariacao < b.coeficienteVariacao ? a : b);
    final piorCv = relatorios.reduce((a, b) => a.coeficienteVariacao > b.coeficienteVariacao ? a : b);
    final mediaCv = relatorios.map((r) => r.coeficienteVariacao).reduce((a, b) => a + b) / relatorios.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANALISE COMPARATIVA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '• Melhor CV%: ${melhorCv.talhaoNome} (${melhorCv.coeficienteVariacao.toStringAsFixed(1)}%)',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Pior CV%: ${piorCv.talhaoNome} (${piorCv.coeficienteVariacao.toStringAsFixed(1)}%)',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• CV% Médio: ${mediaCv.toStringAsFixed(1)}%',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Amplitude: ${(piorCv.coeficienteVariacao - melhorCv.coeficienteVariacao).toStringAsFixed(1)}%',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Constrói ranking comparativo
  pw.Widget _buildRankingComparativo(List<PlantingQualityReportModel> relatorios) {
    final relatoriosOrdenados = List<PlantingQualityReportModel>.from(relatorios)
      ..sort((a, b) => a.coeficienteVariacao.compareTo(b.coeficienteVariacao));

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RANKING DE QUALIDADE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...relatoriosOrdenados.asMap().entries.map((entry) {
            final index = entry.key;
            final relatorio = entry.value;
            final cor = _getCorRanking(index + 1);
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: cor,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '${index + 1}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          relatorio.talhaoNome,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                        ),
                        pw.Text(
                          'CV%: ${relatorio.coeficienteVariacao.toStringAsFixed(1)}% - ${relatorio.classificacaoCV}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Constrói rodapé comparativo
  pw.Widget _buildRodapeComparativo(List<PlantingQualityReportModel> relatorios) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACOES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Este relatório compara a qualidade de plantio entre ${relatorios.length} talhões.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            '• CV% menor indica maior uniformidade no plantio.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            '• Classificação baseada nos padrões da FortSmart Agro.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Relatório gerado automaticamente pelo FortSmart Agro - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém cor baseada na classificação
  PdfColor _getCorClassificacao(String classificacao) {
    switch (classificacao.toLowerCase()) {
      case 'excelente':
        return PdfColors.green;
      case 'bom':
        return PdfColors.blue;
      case 'regular':
        return PdfColors.orange;
      case 'ruim':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }

  /// Obtém cor baseada no ranking
  PdfColor _getCorRanking(int posicao) {
    switch (posicao) {
      case 1:
        return PdfColors.green100;
      case 2:
        return PdfColors.blue100;
      case 3:
        return PdfColors.orange100;
      default:
        return PdfColors.grey100;
    }
  }
}