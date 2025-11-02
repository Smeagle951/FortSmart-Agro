import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/planting_complete_report_service.dart';
import '../../utils/snackbar_utils.dart';

/// 📊 TELA DE DETALHES COMPLETOS DE UM PLANTIO
/// 
/// Exibe TODAS as informações de um plantio específico:
/// - Dados básicos (talhão, cultura, variedade, data)
/// - População real do estande
/// - Eficiência e CV%
/// - Evolução fenológica
/// - Histórico completo

class CompletePlantingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantioData;
  
  const CompletePlantingDetailScreen({
    Key? key,
    required this.plantioData,
  }) : super(key: key);

  @override
  State<CompletePlantingDetailScreen> createState() => _CompletePlantingDetailScreenState();
}

class _CompletePlantingDetailScreenState extends State<CompletePlantingDetailScreen> {
  final PlantingCompleteReportService _reportService = PlantingCompleteReportService();
  bool _isExporting = false;
  bool _isSharing = false;
  
  @override
  Widget build(BuildContext context) {
    final plantioData = widget.plantioData;
    final talhaoNome = plantioData['talhao_nome'] ?? 'Talhão não identificado';
    final culturaId = plantioData['cultura_id'] ?? 'Cultura não identificada';
    final variedadeId = plantioData['variedade_id'] ?? 'Não definida';
    final dataPlantio = DateTime.parse(plantioData['data_plantio']);
    final diasPlantio = plantioData['dias_apos_plantio'] ?? 0;
    
    // Dados do plantio base
    final plantioBase = plantioData['plantio'] as Map<String, dynamic>? ?? {};
    
    // Dados do estande
    final estande = plantioData['estande'] as Map<String, dynamic>? ?? {};
    final temEstande = estande['tem_dados'] == true;
    
    // Dados de CV%
    final cv = plantioData['cv_uniformidade'] as Map<String, dynamic>? ?? {};
    final temCV = cv['tem_dados'] == true;
    
    // Dados fenológicos
    final fenologia = plantioData['evolucao_fenologica'] as Map<String, dynamic>? ?? {};
    final temFenologia = fenologia['tem_dados'] == true;
    
    // Métricas calculadas
    final metricas = plantioData['metricas_calculadas'] as Map<String, dynamic>? ?? {};
    final populacaoFinal = metricas['populacao_final'] ?? 0;
    final populacaoTipo = metricas['populacao_tipo'] ?? 'DESCONHECIDO';
    final completude = metricas['completude_dados_percentual'] ?? 0;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detalhes do Plantio',
        actions: [
          IconButton(
            icon: _isSharing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : _compartilharViaWhatsApp,
            tooltip: 'Compartilhar via WhatsApp',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
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
            // Header - Talhão e Cultura
            _buildHeader(talhaoNome, culturaId, completude),
            
            const SizedBox(height: 24),
            
            // Dados Básicos
            _buildSecaoCard(
              'Dados Básicos do Plantio',
              Icons.info_outline,
              Colors.blue,
              [
                _buildInfoRow('Variedade', variedadeId, Icons.eco),
                _buildInfoRow('Data de Plantio', DateFormat('dd/MM/yyyy').format(dataPlantio), Icons.calendar_today),
                _buildInfoRow('Dias Após Plantio (DAP)', '$diasPlantio dias', Icons.access_time),
                if (plantioBase['espacamento_cm'] != null && plantioBase['espacamento_cm'] > 0)
                  _buildInfoRow('Espaçamento Planejado', '${plantioBase['espacamento_cm']} cm', Icons.straighten),
                if (plantioBase['profundidade_cm'] != null && plantioBase['profundidade_cm'] > 0)
                  _buildInfoRow('Profundidade', '${plantioBase['profundidade_cm']} cm', Icons.vertical_align_bottom),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Observações (com imagem clicável)
            if (plantioBase['observacoes'] != null && plantioBase['observacoes'].toString().isNotEmpty)
              _buildObservacoesCard(plantioBase['observacoes'], variedadeId, context),
            
            const SizedBox(height: 16),
            
            // População
            _buildPopulacaoCard(populacaoFinal, populacaoTipo, estande, temEstande),
            
            const SizedBox(height: 16),
            
            // Estande (se disponível)
            if (temEstande)
              _buildEstandeCard(estande),
            
            if (temEstande)
              const SizedBox(height: 16),
            
            // CV% (se disponível)
            if (temCV)
              _buildCVCard(cv),
            
            if (temCV)
              const SizedBox(height: 16),
            
            // Fenologia (se disponível)
            if (temFenologia)
              _buildFenologiaCard(fenologia),
            
            if (!temEstande || !temCV || !temFenologia) ...[
              const SizedBox(height: 16),
              _buildDadosIncompletos(temEstande, temCV, temFenologia),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(String talhao, String cultura, int completude) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    talhao,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completude%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.grass, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  cultura,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecaoCard(String titulo, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopulacaoCard(num populacao, String tipo, Map<String, dynamic> estande, bool temEstande) {
    final cor = tipo == 'REAL_ESTANDE' ? Colors.green : Colors.orange;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cor.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  tipo == 'REAL_ESTANDE' ? Icons.check_circle : Icons.warning,
                  color: cor.shade700,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo == 'REAL_ESTANDE' ? 'População Real (Medida em Campo)' : 'População Planejada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cor.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatPopulation(populacao)} plantas/ha',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cor.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (temEstande && estande['eficiencia_percentual'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricaSimples(
                      'Eficiência',
                      '${estande['eficiencia_percentual'].toStringAsFixed(1)}%',
                      Icons.trending_up,
                      _getEficienciaColor(estande['eficiencia_percentual']),
                    ),
                    if (estande['plantas_por_metro'] != null)
                      _buildMetricaSimples(
                        'Plantas/Metro',
                        estande['plantas_por_metro'].toStringAsFixed(1),
                        Icons.straighten,
                        Colors.blue,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEstandeCard(Map<String, dynamic> estande) {
    return _buildSecaoCard(
      'Dados do Estande',
      Icons.analytics,
      Colors.green,
      [
        if (estande['data_avaliacao'] != null)
          _buildInfoRow('Data de Avaliação', DateFormat('dd/MM/yyyy').format(DateTime.parse(estande['data_avaliacao'])), Icons.calendar_today),
        if (estande['dias_apos_emergencia'] != null)
          _buildInfoRow('Dias Após Emergência (DAE)', '${estande['dias_apos_emergencia']} dias', Icons.access_time),
        if (estande['plantas_contadas'] != null)
          _buildInfoRow('Plantas Contadas', '${estande['plantas_contadas']} plantas', Icons.filter_9_plus),
        if (estande['metros_lineares_medidos'] != null)
          _buildInfoRow('Metros Lineares Medidos', '${estande['metros_lineares_medidos']} m', Icons.straighten),
        if (estande['populacao_ideal'] != null)
          _buildInfoRow('População Ideal', '${_formatPopulation(estande['populacao_ideal'])} plantas/ha', Icons.flag),
      ],
    );
  }
  
  Widget _buildCVCard(Map<String, dynamic> cv) {
    final cvValor = cv['coeficiente_variacao'] ?? 0;
    final classificacao = cv['classificacao'] ?? 'Não calculado';
    
    return _buildSecaoCard(
      'Coeficiente de Variação (CV%)',
      Icons.show_chart,
      Colors.purple,
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricaGrande(
              'CV%',
              '${cvValor.toStringAsFixed(2)}%',
              Icons.percent,
              _getCVColor(cvValor),
            ),
            _buildMetricaGrande(
              'Classificação',
              classificacao,
              Icons.star,
              _getCVColor(cvValor),
            ),
          ],
        ),
        if (cv['media_espacamento'] != null)
          _buildInfoRow('Média de Espaçamento', '${cv['media_espacamento'].toStringAsFixed(1)} cm', Icons.straighten),
        if (cv['desvio_padrao'] != null)
          _buildInfoRow('Desvio Padrão', cv['desvio_padrao'].toStringAsFixed(2), Icons.analytics),
      ],
    );
  }
  
  Widget _buildFenologiaCard(Map<String, dynamic> fenologia) {
    final ultimoRegistro = fenologia['ultimo_registro'] as Map<String, dynamic>?;
    final totalRegistros = fenologia['total_registros'] ?? 0;
    
    return _buildSecaoCard(
      'Evolução Fenológica',
      Icons.nature,
      Colors.teal,
      [
        _buildInfoRow('Total de Registros', '$totalRegistros avaliações', Icons.list),
        if (ultimoRegistro != null) ...[
          const Divider(height: 24),
          Text(
            'Último Registro:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (ultimoRegistro['data_registro'] != null)
            _buildInfoRow('Data', DateFormat('dd/MM/yyyy').format(DateTime.parse(ultimoRegistro['data_registro'])), Icons.calendar_today),
          if (ultimoRegistro['estagio_fenologico'] != null)
            _buildInfoRow('Estágio', ultimoRegistro['estagio_fenologico'], Icons.eco),
          if (ultimoRegistro['dias_apos_emergencia'] != null)
            _buildInfoRow('DAE', '${ultimoRegistro['dias_apos_emergencia']} dias', Icons.access_time),
          if (ultimoRegistro['altura_cm'] != null)
            _buildInfoRow('Altura', '${ultimoRegistro['altura_cm']} cm', Icons.height),
          if (ultimoRegistro['numero_folhas'] != null)
            _buildInfoRow('Número de Folhas', '${ultimoRegistro['numero_folhas']}', Icons.filter_vintage),
        ],
      ],
    );
  }
  
  Widget _buildDadosIncompletos(bool temEstande, bool temCV, bool temFenologia) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Dados Incompletos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!temEstande)
              _buildDadoFaltante('Estande de Plantas não registrado'),
            if (!temCV)
              _buildDadoFaltante('CV% não calculado'),
            if (!temFenologia)
              _buildDadoFaltante('Evolução Fenológica não iniciada'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDadoFaltante(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Text(texto),
        ],
      ),
    );
  }
  
  Widget _buildMetricaSimples(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
  
  Widget _buildMetricaGrande(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  String _formatPopulation(num population) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}k';
    }
    return population.toStringAsFixed(0);
  }
  
  Color _getEficienciaColor(double eficiencia) {
    if (eficiencia >= 90) return Colors.green;
    if (eficiencia >= 75) return Colors.lightGreen;
    if (eficiencia >= 60) return Colors.orange;
    return Colors.red;
  }
  
  Color _getCVColor(double cv) {
    if (cv <= 10) return Colors.green;
    if (cv <= 20) return Colors.lightGreen;
    if (cv <= 30) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildObservacoesCard(String observacoes, String variedadeId, BuildContext context) {
    // Parse das observações para extrair informações
    final Map<String, dynamic> dadosExtraidos = _parseObservacoes(observacoes);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.indigo.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Variedades selecionadas
            if (dadosExtraidos['variedades'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Variedades Selecionadas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...((dadosExtraidos['variedades'] as List<Map<String, dynamic>>).map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 28),
                            Text(
                              '• ${v['nome']}:',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${v['hectares']} ha',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Imagem (clicável)
            if (dadosExtraidos['imagem'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Foto Anexada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _mostrarPreviewImagem(context, dadosExtraidos['imagem']),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: File(dadosExtraidos['imagem']).existsSync()
                              ? Image.file(
                                  File(dadosExtraidos['imagem']),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Imagem não encontrada',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Toque para ampliar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Observações adicionais (se houver texto não estruturado)
            if (dadosExtraidos['textoLivre'] != null && dadosExtraidos['textoLivre'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                dadosExtraidos['textoLivre'],
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Map<String, dynamic> _parseObservacoes(String observacoes) {
    final Map<String, dynamic> resultado = {};
    
    // Extrair variedades: "Variedades selecionadas: NEO 711 (163.0 ha)"
    final regexVariedades = RegExp(r'Variedades selecionadas:\s*([^|]+)');
    final matchVariedades = regexVariedades.firstMatch(observacoes);
    
    if (matchVariedades != null) {
      final variedadesStr = matchVariedades.group(1)?.trim();
      if (variedadesStr != null) {
        final List<Map<String, dynamic>> variedades = [];
        
        // Parse: "NEO 711 (163.0 ha), BÁLSAMO (50.0 ha)"
        final regexVariedade = RegExp(r'([A-Za-z0-9\s]+)\s*\((\d+\.?\d*)\s*ha\)');
        final matchesVariedades = regexVariedade.allMatches(variedadesStr);
        
        for (final match in matchesVariedades) {
          variedades.add({
            'nome': match.group(1)?.trim(),
            'hectares': match.group(2)?.trim(),
          });
        }
        
        if (variedades.isNotEmpty) {
          resultado['variedades'] = variedades;
        }
      }
    }
    
    // Extrair imagem: "Foto: /data/user/0/..."
    final regexImagem = RegExp(r'Foto:\s*(.+?)(?:\||$)');
    final matchImagem = regexImagem.firstMatch(observacoes);
    
    if (matchImagem != null) {
      final caminhoImagem = matchImagem.group(1)?.trim();
      if (caminhoImagem != null && caminhoImagem.isNotEmpty) {
        resultado['imagem'] = caminhoImagem;
      }
    }
    
    // Texto livre (remover partes já parseadas)
    String textoLivre = observacoes;
    if (matchVariedades != null) {
      textoLivre = textoLivre.replaceAll(matchVariedades.group(0)!, '');
    }
    if (matchImagem != null) {
      textoLivre = textoLivre.replaceAll(matchImagem.group(0)!, '');
    }
    textoLivre = textoLivre.replaceAll('|', '').trim();
    
    if (textoLivre.isNotEmpty) {
      resultado['textoLivre'] = textoLivre;
    }
    
    return resultado;
  }
  
  void _mostrarPreviewImagem(BuildContext context, String caminhoImagem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: File(caminhoImagem).existsSync()
                    ? Image.file(File(caminhoImagem))
                    : const Center(
                        child: Text(
                          'Imagem não encontrada',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Compartilhar via WhatsApp
  void _compartilharViaWhatsApp() async {
    setState(() => _isSharing = true);

    try {
      await _reportService.compartilharViaWhatsApp(widget.plantioData);
      
      if (mounted) {
        SnackbarUtils.showSuccessSnackBar(
          context,
          '✅ WhatsApp aberto com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context,
          'Erro ao compartilhar: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
  
  /// Exportar PDF
  void _exportarPDF() async {
    setState(() => _isExporting = true);

    try {
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Gerando relatório PDF...')),
            ],
          ),
        ),
      );

      final pdfFile = await _reportService.gerarPDFCompleto(widget.plantioData);
      
      if (mounted) {
        Navigator.of(context).pop(); // Fechar diálogo de progresso
        
        // Perguntar se quer compartilhar ou apenas visualizar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('PDF Gerado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('O relatório foi gerado com sucesso.'),
                const SizedBox(height: 8),
                Text(
                  'Local: ${pdfFile.path}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _reportService.compartilharPDFViaWhatsApp(widget.plantioData);
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
        
        SnackbarUtils.showSuccessSnackBar(
          context,
          '✅ PDF gerado com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar diálogo de progresso
        
        SnackbarUtils.showErrorSnackBar(
          context,
          'Erro ao gerar PDF: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

