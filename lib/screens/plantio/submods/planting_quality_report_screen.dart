import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/planting_quality_report_model.dart';
import '../../../../utils/fortsmart_theme.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../services/pdf_report_service.dart';
import '../../../../utils/snackbar_utils.dart';
import 'widgets/planting_quality_report_widget.dart';

/// Tela para visualização de relatório de qualidade de plantio
class PlantingQualityReportScreen extends StatefulWidget {
  final PlantingQualityReportModel relatorio;

  const PlantingQualityReportScreen({
    Key? key,
    required this.relatorio,
  }) : super(key: key);

  @override
  State<PlantingQualityReportScreen> createState() => _PlantingQualityReportScreenState();
}

class _PlantingQualityReportScreenState extends State<PlantingQualityReportScreen> {
  bool _isExporting = false;
  bool _isSharing = false;
  final PDFReportService _pdfService = PDFReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Relatório de Qualidade - ${widget.relatorio.talhaoNome}',
        actions: [
          IconButton(
            icon: const Icon(Icons.design_services),
            onPressed: _mostrarSeletorTemplate,
            tooltip: 'Selecionar Template',
          ),
          IconButton(
            icon: const Icon(Icons.cached),
            onPressed: _mostrarGerenciadorCache,
            tooltip: 'Gerenciar Cache',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isSharing ? null : _compartilharRelatorio,
            tooltip: 'Compartilhar via WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportarPDF,
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do relatório
            _buildCabecalho(),
            
            const SizedBox(height: 24),
            
            // Resumo do talhão
            _buildResumoTalhao(),
            
            const SizedBox(height: 24),
            
            // Imagem do estande (se existir)
            if (widget.relatorio.imagemEstandePath != null && widget.relatorio.imagemEstandePath!.isNotEmpty)
              _buildImagemEstande(),
            
            if (widget.relatorio.imagemEstandePath != null && widget.relatorio.imagemEstandePath!.isNotEmpty)
              const SizedBox(height: 24),
            
            // Resultados principais
            _buildResultadosPrincipais(),
            
            const SizedBox(height: 24),
            
            // Análise automática
            _buildAnaliseAutomatica(),
            
            const SizedBox(height: 24),
            
            // Gráficos
            _buildGraficos(),
            
            const SizedBox(height: 24),
            
            // Rodapé
            _buildRodape(),
            
            const SizedBox(height: 32),
            
            // Botões de ação
            _buildBotoesAcao(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FortSmartTheme.primaryColor,
            FortSmartTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: FortSmartTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Relatório FortSmart – Qualidade de Plantio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🌱 ${widget.relatorio.talhaoNome}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  '📐 Área avaliada',
                  '${widget.relatorio.areaHectares.toStringAsFixed(2)} ha',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  '📅 Data',
                  DateFormat('dd/MM/yyyy').format(widget.relatorio.dataAvaliacao),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            '👨‍🌾 Executor',
            widget.relatorio.executor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResumoTalhao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Talhão',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    '🌱 Cultura',
                    widget.relatorio.culturaNome,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    '🌾 Variedade',
                    widget.relatorio.variedade.isNotEmpty ? widget.relatorio.variedade : 'Não informada',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    '📅 Data de plantio',
                    DateFormat('dd/MM/yyyy').format(widget.relatorio.dataPlantio),
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    '🌾 Safra',
                    widget.relatorio.safra.isNotEmpty ? widget.relatorio.safra : 'Não informada',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildImagemEstande() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: FortSmartTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '📷 Imagem do Estande',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.relatorio.imagemEstandePath!),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Imagem não disponível', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosPrincipais() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Qualidade de Plantio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // CV%
            _buildMetricaCard(
              'CV – Coeficiente de Variação',
              widget.relatorio.coeficienteVariacao == 0.0 || widget.relatorio.classificacaoCV == 'Não Calculado'
                  ? 'CV não calculado no plantio'
                  : '${widget.relatorio.coeficienteVariacao.toStringAsFixed(2)}%',
              widget.relatorio.coeficienteVariacao == 0.0 || widget.relatorio.classificacaoCV == 'Não Calculado'
                  ? 'ℹ️'
                  : widget.relatorio.emojiCV,
              widget.relatorio.coeficienteVariacao == 0.0 || widget.relatorio.classificacaoCV == 'Não Calculado'
                  ? 'CV não calculado'
                  : widget.relatorio.classificacaoCV,
              widget.relatorio.coeficienteVariacao == 0.0 || widget.relatorio.classificacaoCV == 'Não Calculado'
                  ? Colors.grey
                  : Color(int.parse(widget.relatorio.corCV.replaceAll('#', '0xFF'))),
            ),
            
            const SizedBox(height: 12),
            
            // Singulação
            _buildMetricaCard(
              'Singulação',
              '${widget.relatorio.singulacao.toStringAsFixed(2)}%',
              widget.relatorio.singulacao >= 95 ? '✅' : '⚠️',
              widget.relatorio.singulacao >= 95 ? 'Excelente' : 'Boa',
              Color(int.parse(widget.relatorio.corSingulacao.replaceAll('#', '0xFF'))),
            ),
            
            const SizedBox(height: 12),
            
            // Plantas por hectare
            _buildMetricaCard(
              'Plantas por hectare',
              '${NumberFormat('#,###').format(widget.relatorio.populacaoEstimadaPorHectare)} plantas/ha',
              '🌱',
              'População estimada',
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Plantas por metro
            _buildMetricaCard(
              'Plantas por metro',
              '${widget.relatorio.plantasPorMetro.toStringAsFixed(1)} plantas/m',
              '📏',
              'Densidade linear',
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Plantas duplas
            _buildMetricaCard(
              '% Plantas duplas',
              '${widget.relatorio.plantasDuplas.toStringAsFixed(2)}%',
              widget.relatorio.plantasDuplas <= 3 ? '✅' : '⚠️',
              widget.relatorio.plantasDuplas <= 3 ? 'Aceitável' : 'Atenção',
              widget.relatorio.plantasDuplas <= 3 ? Colors.green : Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Plantas falhadas
            _buildMetricaCard(
              '% Plantas falhadas',
              '${widget.relatorio.plantasFalhadas.toStringAsFixed(2)}%',
              widget.relatorio.plantasFalhadas <= 3 ? '✅' : '⚠️',
              widget.relatorio.plantasFalhadas <= 3 ? 'Aceitável' : 'Atenção',
              widget.relatorio.plantasFalhadas <= 3 ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, String emoji, String status, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnaliseAutomatica() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  '📌 Análise Automática FortSmart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                widget.relatorio.analiseAutomatica,
                style: TextStyle(
                  color: Colors.amber[800],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔎 Sugestões:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.relatorio.sugestoes,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
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

  Widget _buildGraficos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Gráficos de Análise',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Gráfico de pizza para distribuição
            _buildGraficoPizza(),
            
            const SizedBox(height: 16),
            
            // Gráfico de barras para população
            _buildGraficoBarras(),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoPizza() {
    final correto = 100 - widget.relatorio.plantasDuplas - widget.relatorio.plantasFalhadas;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribuição de Plantas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.green,
                          Colors.green,
                          Colors.orange,
                          Colors.orange,
                          Colors.red,
                          Colors.red,
                          Colors.green,
                        ],
                        stops: [
                          0.0,
                          correto / 100,
                          correto / 100,
                          (correto + widget.relatorio.plantasDuplas) / 100,
                          (correto + widget.relatorio.plantasDuplas) / 100,
                          1.0,
                          1.0,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${correto.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendaItem('Correto', correto, Colors.green),
                  _buildLegendaItem('Duplas', widget.relatorio.plantasDuplas, Colors.orange),
                  _buildLegendaItem('Falhas', widget.relatorio.plantasFalhadas, Colors.red),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendaItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${value.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'População Alvo vs Real',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Alvo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 60,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${(widget.relatorio.populacaoAlvo / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Real',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (widget.relatorio.populacaoReal / widget.relatorio.populacaoAlvo) * 60,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(widget.relatorio.corStatusPopulacao.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${(widget.relatorio.populacaoReal / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRodape() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rodapé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Dados registrados via FortSmart App',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Coleta em: ${DateFormat('dd/MM/yyyy – HH:mm').format(widget.relatorio.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Dados rastreáveis – Relatório Premium',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'WhatsApp',
                onPressed: _isSharing ? null : _compartilharRelatorio,
                icon: Icons.share,
                isOutlined: true,
                isLoading: _isSharing,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: 'Exportar PDF',
                onPressed: _isExporting ? null : _exportarPDF,
                icon: Icons.picture_as_pdf,
                isLoading: _isExporting,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Compartilhar',
                onPressed: _isSharing ? null : _compartilharPDF,
                icon: Icons.file_upload,
                isOutlined: true,
                isLoading: _isSharing,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: 'Visualizar PDF',
                onPressed: _isExporting ? null : _visualizarPDF,
                icon: Icons.visibility,
                isOutlined: true,
                isLoading: _isExporting,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _compartilharRelatorio() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Gerar PDF
      final pdfFile = await _pdfService.gerarPDFRelatorio(widget.relatorio);
      
      // Compartilhar via WhatsApp
      await _pdfService.compartilharPDFViaWhatsApp(pdfFile, widget.relatorio);
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Relatório compartilhado via WhatsApp com sucesso!'
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao compartilhar relatório: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  void _exportarPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Gerar PDF
      final pdfFile = await _pdfService.gerarPDFRelatorio(widget.relatorio);
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'PDF gerado com sucesso! Arquivo salvo em: ${pdfFile.path}'
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao gerar PDF: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _compartilharPDF() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Gerar PDF
      final pdfFile = await _pdfService.gerarPDFRelatorio(widget.relatorio);
      
      // Compartilhar PDF
      await _pdfService.compartilharPDF(pdfFile, widget.relatorio);
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'PDF compartilhado com sucesso!'
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao compartilhar PDF: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  void _visualizarPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Gerar PDF
      final pdfFile = await _pdfService.gerarPDFRelatorio(widget.relatorio);
      
      // Visualizar PDF
      await _visualizarPDFFile(pdfFile);
      
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao visualizar PDF: ${e.toString()}'
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _visualizarPDFFile(dynamic pdfFile) async {
    try {
      // Usar a nova funcionalidade de visualização com preview
      await _pdfService.visualizarPDFComPreview(context, widget.relatorio);
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao visualizar PDF: ${e.toString()}'
      );
    }
  }

  Future<void> _mostrarSeletorTemplate() async {
    final templates = _pdfService.templatesDisponiveis;
    final templateAtual = _pdfService.templateAtual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: templates.entries.map((entry) {
            final isSelected = entry.key == templateAtual;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? FortSmartTheme.primaryColor : null,
              ),
              title: Text(entry.value),
              subtitle: Text(_getTemplateDescription(entry.key)),
              onTap: () {
                _pdfService.setTemplate(entry.key);
                Navigator.of(context).pop();
                SnackbarUtils.showSuccessSnackBar(
                  context, 
                  'Template alterado para: ${entry.value}'
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _getTemplateDescription(String template) {
    switch (template) {
      case 'fortsmart_padrao':
        return 'Template oficial FortSmart com design completo';
      case 'minimalista':
        return 'Design limpo e focado nas métricas principais';
      case 'detalhado':
        return 'Relatório completo com tabelas e gráficos';
      case 'executivo':
        return 'Formato executivo para apresentações';
      default:
        return 'Template personalizado';
    }
  }

  Future<void> _mostrarGerenciadorCache() async {
    final stats = _pdfService.obterEstatisticasCache();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerenciador de Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Estatísticas do Cache:'),
            const SizedBox(height: 8),
            Text('• Itens em cache: ${stats['total_itens']}'),
            Text('• Template atual: ${stats['template_atual']}'),
            Text('• Duração: ${stats['duracao_cache_horas']} horas'),
            const SizedBox(height: 16),
            const Text('💡 O cache acelera a geração de PDFs já criados.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pdfService.limparCache();
              Navigator.of(context).pop();
              SnackbarUtils.showSuccessSnackBar(
                context, 
                'Cache limpo com sucesso!'
              );
            },
            child: const Text('Limpar Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
