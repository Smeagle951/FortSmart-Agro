import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

/// 📊 Serviço de Geração de Relatórios Completos de Plantio
/// 
/// Gera relatórios PDF elegantes e profissionais com:
/// - Dados básicos do plantio
/// - População real do estande
/// - Eficiência e CV%
/// - Evolução fenológica
/// - Gráficos e visualizações
/// - Compartilhamento via WhatsApp

class PlantingCompleteReportService {
  static const String _tag = 'PlantingCompleteReportService';

  /// Gera PDF completo do plantio
  Future<File> gerarPDFCompleto(Map<String, dynamic> dadosCompletos) async {
    try {
      Logger.info('$_tag: 📄 Iniciando geração de PDF completo...');

      final pdf = pw.Document();
      
      // Adicionar páginas
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildCabecalho(dadosCompletos),
              pw.SizedBox(height: 24),
              _buildDadosBasicos(dadosCompletos),
              pw.SizedBox(height: 20),
              _buildSecaoPopulacao(dadosCompletos),
              pw.SizedBox(height: 20),
              _buildSecaoEstande(dadosCompletos),
              pw.SizedBox(height: 20),
              _buildSecaoCV(dadosCompletos),
              pw.SizedBox(height: 20),
              _buildSecaoFenologia(dadosCompletos),
              pw.SizedBox(height: 24),
              _buildRodape(dadosCompletos),
            ];
          },
        ),
      );

      // Salvar PDF
      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/relatorio_plantio_${dadosCompletos['id']}_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      Logger.info('$_tag: ✅ PDF gerado: ${file.path}');
      return file;

    } catch (e, stack) {
      Logger.error('$_tag: ❌ Erro ao gerar PDF: $e');
      Logger.error('Stack: $stack');
      rethrow;
    }
  }

  /// Cabeçalho do PDF
  pw.Widget _buildCabecalho(Map<String, dynamic> dados) {
    final talhaoNome = dados['talhao_nome'] ?? 'Talhão não identificado';
    final culturaId = dados['cultura_id'] ?? 'Cultura não identificada';
    final dataPlantio = DateTime.parse(dados['data_plantio']);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.green500, PdfColors.green400],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'FORTSMART',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'RELATÓRIO AGRONÔMICO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Detalhamento Completo de Plantio',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.white),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Talhão', talhaoNome, PdfColors.white),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildInfoItem('Cultura', culturaId, PdfColors.white),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildInfoItem(
                  'Data Plantio', 
                  DateFormat('dd/MM/yyyy').format(dataPlantio),
                  PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de informação (helper)
  pw.Widget _buildInfoItem(String label, String value, PdfColor textColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: textColor.isLight ? PdfColors.grey300 : PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Dados Básicos do Plantio
  pw.Widget _buildDadosBasicos(Map<String, dynamic> dados) {
    final variedadeId = dados['variedade_id'] ?? 'Não definida';
    final diasPlantio = dados['dias_apos_plantio'] ?? 0;
    final plantio = dados['plantio'] as Map<String, dynamic>? ?? {};
    
    // Limpar observações removendo o caminho da imagem
    String observacoesRaw = plantio['observacoes']?.toString() ?? '';
    final observacoes = observacoesRaw
        .replaceAll(RegExp(r'\s*\|\s*Foto:\s*[^\|]+'), '') // Remove "| Foto: caminho"
        .replaceAll(RegExp(r'Foto:\s*[^\|]+\s*\|\s*'), '') // Remove "Foto: caminho |"
        .replaceAll(RegExp(r'Foto:\s*.+'), '') // Remove qualquer "Foto: ..."
        .trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'Dados Básicos do Plantio',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildDataItem('Variedade', variedadeId, PdfColors.purple),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildDataItem('Dias Após Plantio', '$diasPlantio dias', PdfColors.orange),
              ),
            ],
          ),
          if (observacoes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observações:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    observacoes,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Adicionar imagem se disponível
          ...() {
            // Buscar imagem em múltiplos locais
            String? imagemPath = plantio['observacoes_imagem_path'] ?? 
                                 plantio['foto_observacao'] ?? 
                                 plantio['imagem_path'] ?? 
                                 plantio['foto'];
            
            // Se não encontrou, tentar extrair das observações usando regex
            if ((imagemPath == null || imagemPath.isEmpty) && observacoes.isNotEmpty) {
              final regexImagem = RegExp(r'Foto:\s*(.+?)(?:\||$)');
              final matchImagem = regexImagem.firstMatch(observacoes);
              if (matchImagem != null) {
                imagemPath = matchImagem.group(1)?.trim();
              }
            }
            
            // Também tentar buscar em dados completos
            if ((imagemPath == null || imagemPath.isEmpty) && dados.containsKey('plantio')) {
              final plantioBase = dados['plantio'] as Map<String, dynamic>?;
              imagemPath = plantioBase?['foto_observacao'] ?? 
                          plantioBase?['imagem_path'] ?? 
                          plantioBase?['foto'];
            }
            
            if (imagemPath != null && imagemPath.toString().trim().isNotEmpty) {
              final path = imagemPath.toString().trim();
              
              // Validar se é um caminho válido (não um ID de documento)
              if (!path.contains('DOC-') && path.length > 10 && (path.contains('/') || path.contains('\\'))) {
                return [
                  pw.SizedBox(height: 12),
                  _buildImagemObservacao(path),
                ];
              }
            }
            return <pw.Widget>[];
          }(),
        ],
      ),
    );
  }

  /// Item de dado (helper)
  pw.Widget _buildDataItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Seção de População
  pw.Widget _buildSecaoPopulacao(Map<String, dynamic> dados) {
    final metricas = dados['metricas_calculadas'] as Map<String, dynamic>? ?? {};
    final populacaoFinal = metricas['populacao_final'] ?? 0;
    final populacaoTipo = metricas['populacao_tipo'] ?? 'DESCONHECIDO';
    final eficiencia = metricas['eficiencia_plantio'];
    
    final isReal = populacaoTipo == 'REAL_ESTANDE';
    final corFundo = isReal ? PdfColors.green50 : PdfColors.orange50;
    final corTexto = isReal ? PdfColors.green900 : PdfColors.orange900;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: corFundo,
        border: pw.Border.all(color: isReal ? PdfColors.green300 : PdfColors.orange300, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isReal ? 'População Real (Estande)' : 'População Planejada',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${_formatPopulation(populacaoFinal)} plantas/ha',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                ],
              ),
              if (isReal && eficiencia != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _getEficienciaColor(eficiencia),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Eficiência',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${eficiencia.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
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

  /// Seção de Dados do Estande
  pw.Widget _buildSecaoEstande(Map<String, dynamic> dados) {
    final estande = dados['estande'] as Map<String, dynamic>? ?? {};
    final temDados = estande['tem_dados'] == true;

    if (!temDados) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Estande de Plantas não registrado',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Dados do Estande de Plantas',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildDataItem(
                  'Plantas Contadas',
                  '${estande['plantas_contadas'] ?? 0}',
                  PdfColors.blue,
                ),
              ),
              pw.Expanded(
                child: _buildDataItem(
                  'Metros Avaliados',
                  '${estande['metros_avaliados']?.toStringAsFixed(1) ?? '0.0'} m',
                  PdfColors.blue,
                ),
              ),
              pw.Expanded(
                child: _buildDataItem(
                  'Plantas/Metro',
                  '${estande['plantas_por_metro']?.toStringAsFixed(1) ?? '0.0'}',
                  PdfColors.green,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildDataItem(
                  'População Real',
                  '${_formatPopulation(estande['populacao_real'] ?? 0)} plantas/ha',
                  PdfColors.green,
                ),
              ),
              pw.Expanded(
                child: _buildDataItem(
                  'Eficiência',
                  '${estande['eficiencia_percentual']?.toStringAsFixed(1) ?? '0.0'}%',
                  PdfColors.green,
                ),
              ),
              pw.Expanded(
                child: _buildDataItem(
                  'Data Avaliação',
                  estande['data_avaliacao'] != null 
                      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(estande['data_avaliacao']))
                      : 'N/A',
                  PdfColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seção de CV%
  pw.Widget _buildSecaoCV(Map<String, dynamic> dados) {
    final cv = dados['cv_uniformidade'] as Map<String, dynamic>? ?? {};
    final temDados = cv['tem_dados'] == true;

    if (!temDados) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'CV% não calculado',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
      );
    }

    final coeficiente = cv['coeficiente_variacao'] ?? 0.0;
    final classificacao = cv['classificacao'] ?? 'N/A';
    final corClassificacao = _getClassificacaoColor(classificacao);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Coeficiente de Variação (CV%)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${coeficiente.toStringAsFixed(2)}%',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: corClassificacao,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        classificacao.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: corClassificacao,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDataItem(
                      'Desvio Padrão',
                      '${cv['desvio_padrao']?.toStringAsFixed(2) ?? '0.00'} cm',
                      PdfColors.grey,
                    ),
                    pw.SizedBox(height: 8),
                    _buildDataItem(
                      'Média de Espaçamento',
                      '${cv['media_espacamento']?.toStringAsFixed(1) ?? '0.0'} cm',
                      PdfColors.grey,
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

  /// Seção de Evolução Fenológica
  pw.Widget _buildSecaoFenologia(Map<String, dynamic> dados) {
    final fenologia = dados['evolucao_fenologica'] as Map<String, dynamic>? ?? {};
    final temDados = fenologia['tem_dados'] == true;
    final totalRegistros = fenologia['total_registros'] ?? 0;

    if (!temDados) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Nenhum registro fenológico encontrado',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
      );
    }

    final ultimoRegistro = fenologia['ultimo_registro'] as Map<String, dynamic>? ?? {};
    final dae = ultimoRegistro['dias_apos_emergencia'] ?? 0;
    final altura = ultimoRegistro['altura_cm'] ?? 0.0;
    final estagio = ultimoRegistro['estagio_fenologico'] ?? 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Evolução Fenológica',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total de $totalRegistros avaliações realizadas',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Última Avaliação:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildDataItem('DAE', '$dae dias', PdfColors.purple),
                    ),
                    pw.Expanded(
                      child: _buildDataItem('Altura', '${altura.toStringAsFixed(1)} cm', PdfColors.purple),
                    ),
                    pw.Expanded(
                      child: _buildDataItem('Estágio', estagio, PdfColors.purple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Resumo do Talhão
  pw.Widget _buildResumoTalhaoPDF(Map<String, dynamic> dados) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildResumoItem('Talhão', dados['talhao_nome'] ?? 'N/A'),
          _buildResumoItem('Cultura', dados['cultura_id'] ?? 'N/A'),
          _buildResumoItem('Variedade', dados['variedade_id'] ?? 'N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildResumoItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ],
    );
  }

  /// Resultados Principais
  pw.Widget _buildResultadosPrincipaisPDF(Map<String, dynamic> dados) {
    final metricas = dados['metricas_calculadas'] as Map<String, dynamic>? ?? {};
    final completude = metricas['completude_dados'] ?? 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Qualidade dos Dados',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildProgressBar('Completude dos Dados', completude),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildStatusChip('Estande', metricas['tem_estande'] == true),
              pw.SizedBox(width: 8),
              _buildStatusChip('CV%', metricas['tem_cv'] == true),
              pw.SizedBox(width: 8),
              _buildStatusChip('Fenologia', metricas['tem_fenologia'] == true),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra de progresso
  pw.Widget _buildProgressBar(String label, int percentual) {
    final cor = percentual >= 80 
        ? PdfColors.green 
        : percentual >= 50 
            ? PdfColors.orange 
            : PdfColors.red;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              '$percentual%',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Stack(
          children: [
            pw.Container(
              height: 8,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
            pw.Container(
              height: 8,
              width: (percentual / 100) * 200, // Largura proporcional (assumindo 200px de largura total)
              decoration: pw.BoxDecoration(
                color: cor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Chip de status
  pw.Widget _buildStatusChip(String label, bool ativo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: ativo ? PdfColors.green100 : PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: ativo ? PdfColors.green900 : PdfColors.grey700,
        ),
      ),
    );
  }

  /// Análise Automática
  pw.Widget _buildAnaliseAutomaticaPDF(Map<String, dynamic> dados) {
    final statusQualidade = dados['status_qualidade'] as Map<String, dynamic>? ?? {};
    final mensagem = statusQualidade['mensagem'] ?? 'Análise não disponível';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        border: pw.Border.all(color: PdfColors.indigo300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'Análise Inteligente',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            mensagem,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Gráficos (placeholder - pode ser expandido)
  pw.Widget _buildGraficosPDF(Map<String, dynamic> dados) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Análise Gráfica',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Gráficos de evolução e comparativos serão exibidos aqui',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Rodapé do PDF
  pw.Widget _buildRodape(Map<String, dynamic> dados) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FortSmart Agro',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Sistema Integrado de Gestão Agrícola',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Relatório ID: ${dados['id'].toString().substring(0, 8)}...',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Este relatório contém dados rastreáveis e verificáveis através do sistema FortSmart Agro',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget para exibir imagem das observações
  pw.Widget _buildImagemObservacao(String imagePath) {
    try {
      Logger.info('$_tag: Tentando carregar imagem: $imagePath');
      
      // Verificar se é um caminho válido (não apenas um identificador)
      if (imagePath.contains('DOC-') || imagePath.length < 10) {
        Logger.warning('$_tag: Caminho de imagem parece ser inválido: $imagePath');
        return pw.Container();
      }
      
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        Logger.warning('$_tag: Arquivo de imagem não existe: $imagePath');
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            'Imagem não encontrada no dispositivo',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        );
      }

      final imageBytes = imageFile.readAsBytesSync();
      if (imageBytes.isEmpty) {
        Logger.warning('$_tag: Arquivo de imagem está vazio: $imagePath');
        return pw.Container();
      }
      
      // Redimensionar imagem para otimizar no PDF (máximo 400x400px equivalente)
      final image = pw.MemoryImage(imageBytes);
      
      Logger.info('$_tag: Imagem carregada com sucesso: ${imageBytes.length} bytes');

      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue300, width: 2),
          borderRadius: pw.BorderRadius.circular(8),
          color: PdfColors.grey100,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Foto Anexada:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Container(
                constraints: const pw.BoxConstraints(
                  maxHeight: 80,
                  maxWidth: 120,
                ),
                child: pw.Image(
                  image, 
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Toque para ampliar',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      Logger.error('$_tag: Erro ao carregar imagem: $e');
      Logger.error('Stack: $stack');
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Erro ao carregar imagem: ${e.toString()}',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.red,
          ),
        ),
      );
    }
  }

  /// Compartilhar via WhatsApp
  Future<void> compartilharViaWhatsApp(Map<String, dynamic> dadosCompletos) async {
    try {
      Logger.info('$_tag: 📱 Compartilhando via WhatsApp...');

      final texto = _gerarTextoWhatsApp(dadosCompletos);
      
      // Tentar múltiplas URLs do WhatsApp
      final urls = [
        'https://wa.me/?text=${Uri.encodeComponent(texto)}',
        'whatsapp://send?text=${Uri.encodeComponent(texto)}',
        'https://api.whatsapp.com/send?text=${Uri.encodeComponent(texto)}',
      ];
      
      bool sucesso = false;
      for (final url in urls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            Logger.info('$_tag: ✅ WhatsApp aberto com sucesso via: $url');
            sucesso = true;
            break;
          }
        } catch (e) {
          Logger.warning('$_tag: Falha ao tentar URL: $url - $e');
          continue;
        }
      }
      
      if (!sucesso) {
        // Fallback: usar share_plus como alternativa
        Logger.info('$_tag: Tentando compartilhamento alternativo...');
        await Share.share(texto, subject: 'Relatório Agronômico FortSmart');
        Logger.info('$_tag: ✅ Compartilhamento alternativo realizado');
      }

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao compartilhar via WhatsApp: $e');
      rethrow;
    }
  }

  /// Gerar texto formatado para WhatsApp
  String _gerarTextoWhatsApp(Map<String, dynamic> dados) {
    final talhaoNome = dados['talhao_nome'] ?? 'N/A';
    final culturaId = dados['cultura_id'] ?? 'N/A';
    final variedadeId = dados['variedade_id'] ?? 'N/A';
    final dataPlantio = DateFormat('dd/MM/yyyy').format(DateTime.parse(dados['data_plantio']));
    final diasPlantio = dados['dias_apos_plantio'] ?? 0;
    
    final metricas = dados['metricas_calculadas'] as Map<String, dynamic>? ?? {};
    final populacaoFinal = metricas['populacao_final'] ?? 0;
    final populacaoTipo = metricas['populacao_tipo'] ?? 'DESCONHECIDO';
    final eficiencia = metricas['eficiencia_plantio'];
    
    final estande = dados['estande'] as Map<String, dynamic>? ?? {};
    final temEstande = estande['tem_dados'] == true;
    
    final cv = dados['cv_uniformidade'] as Map<String, dynamic>? ?? {};
    final temCV = cv['tem_dados'] == true;
    
    final buffer = StringBuffer();
    
    buffer.writeln('🌾 *RELATÓRIO AGRONÔMICO - FORTSMART*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('📍 *Talhão:* $talhaoNome');
    buffer.writeln('🌱 *Cultura:* $culturaId');
    buffer.writeln('🌿 *Variedade:* $variedadeId');
    buffer.writeln('📅 *Data do Plantio:* $dataPlantio ($diasPlantio dias atrás)');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 *POPULAÇÃO*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    
    if (populacaoTipo == 'REAL_ESTANDE') {
      buffer.writeln('✅ *População Real:* ${_formatPopulation(populacaoFinal)} plantas/ha');
      if (eficiencia != null) {
        buffer.writeln('📈 *Eficiência:* ${eficiencia.toStringAsFixed(1)}%');
      }
    } else {
      buffer.writeln('⚠️ *População Planejada:* ${_formatPopulation(populacaoFinal)} plantas/ha');
      buffer.writeln('_Estande ainda não registrado_');
    }
    
    buffer.writeln('');
    
    if (temEstande) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🌱 *ESTANDE DE PLANTAS*');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('• Plantas contadas: ${estande['plantas_contadas']}');
      buffer.writeln('• Metros avaliados: ${estande['metros_avaliados']?.toStringAsFixed(1)} m');
      buffer.writeln('• Plantas/metro: ${estande['plantas_por_metro']?.toStringAsFixed(1)}');
      buffer.writeln('• População: ${_formatPopulation(estande['populacao_real'] ?? 0)} plantas/ha');
      buffer.writeln('• Eficiência: ${estande['eficiencia_percentual']?.toStringAsFixed(1)}%');
      buffer.writeln('');
    }
    
    if (temCV) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('📐 *COEFICIENTE DE VARIAÇÃO*');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('• CV%: ${cv['coeficiente_variacao']?.toStringAsFixed(2)}%');
      buffer.writeln('• Classificação: ${(cv['classificacao'] ?? 'N/A').toString().toUpperCase()}');
      buffer.writeln('• Desvio padrão: ${cv['desvio_padrao']?.toStringAsFixed(2)} cm');
      buffer.writeln('');
    }
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('_Relatório gerado pelo FortSmart Agro_');
    buffer.writeln('_${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}_');
    
    return buffer.toString();
  }

  /// Compartilhar PDF via WhatsApp
  Future<void> compartilharPDFViaWhatsApp(Map<String, dynamic> dadosCompletos) async {
    try {
      Logger.info('$_tag: 📱 Gerando e compartilhando PDF via WhatsApp...');

      // Gerar PDF
      final pdfFile = await gerarPDFCompleto(dadosCompletos);
      
      // Compartilhar arquivo
      final result = await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: '📊 Relatório Agronômico - FortSmart\n\n'
              'Talhão: ${dadosCompletos['talhao_nome']}\n'
              'Cultura: ${dadosCompletos['cultura_id']}',
      );

      Logger.info('$_tag: ✅ Compartilhamento concluído: ${result.status}');

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao compartilhar PDF: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  String _formatPopulation(num population) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}k';
    }
    return population.toStringAsFixed(0);
  }

  PdfColor _getEficienciaColor(double eficiencia) {
    if (eficiencia >= 90) return PdfColors.green;
    if (eficiencia >= 75) return PdfColors.lightGreen;
    if (eficiencia >= 60) return PdfColors.orange;
    return PdfColors.red;
  }

  PdfColor _getClassificacaoColor(String classificacao) {
    switch (classificacao.toLowerCase()) {
      case 'excelente':
        return PdfColors.green;
      case 'bom':
        return PdfColors.lightGreen;
      case 'moderado':
        return PdfColors.orange;
      case 'ruim':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
}

