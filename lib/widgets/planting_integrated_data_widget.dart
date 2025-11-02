import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/planting_cv_model.dart';
import '../models/planting_stand_model.dart';
import '../models/planting_integration_model.dart';
import '../services/planting_unified_data_service.dart';
import '../services/planting_cv_persistence_service.dart';
import '../services/planting_integrated_analysis_service.dart';
import '../enums/integration_analysis_enum.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

/// Widget para exibir dados integrados de plantio e estande
/// Pode ser usado em ambas as telas (Novo Estande e Cálculo de Plantio + Estande)
class PlantingIntegratedDataWidget extends StatefulWidget {
  final String talhaoId;
  final String culturaId;
  final String talhaoNome;
  final String culturaNome;
  final bool showFullAnalysis;
  final VoidCallback? onDataUpdated;

  const PlantingIntegratedDataWidget({
    Key? key,
    required this.talhaoId,
    required this.culturaId,
    required this.talhaoNome,
    required this.culturaNome,
    this.showFullAnalysis = false,
    this.onDataUpdated,
  }) : super(key: key);

  @override
  _PlantingIntegratedDataWidgetState createState() => _PlantingIntegratedDataWidgetState();
}

class _PlantingIntegratedDataWidgetState extends State<PlantingIntegratedDataWidget> {
  final PlantingUnifiedDataService _unifiedDataService = PlantingUnifiedDataService();
  final PlantingCVPersistenceService _cvPersistenceService = PlantingCVPersistenceService();
  final PlantingIntegratedAnalysisService _integratedAnalysisService = PlantingIntegratedAnalysisService();
  
  Map<String, dynamic>? _completeData;
  Map<String, dynamic>? _executiveSummary;
  PlantingCVModel? _ultimoCv;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Buscar último CV% do histórico
      final ultimoCv = await _cvPersistenceService.obterUltimoCv(widget.talhaoId);
      
      if (ultimoCv != null) {
        // Criar resumo executivo com dados persistentes
        final executiveSummary = await _integratedAnalysisService.obterResumoExecutivo(
          talhaoId: widget.talhaoId,
          talhaoNome: widget.talhaoNome,
          culturaId: widget.culturaId,
          culturaNome: widget.culturaNome,
        );

        setState(() {
          _ultimoCv = ultimoCv;
          _executiveSummary = executiveSummary;
          _completeData = {
            'talhaoId': widget.talhaoId,
            'talhaoNome': widget.talhaoNome,
            'culturaId': widget.culturaId,
            'culturaNome': widget.culturaNome,
            'cvData': [ultimoCv],
            'hasCompleteData': true,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
          _isLoading = false;
        });
      } else {
        // Tentar método antigo se não houver CV% persistido
        final completeData = await _unifiedDataService.getTalhaoCompleteData(
          talhaoId: widget.talhaoId,
          culturaId: widget.culturaId,
          talhaoNome: widget.talhaoNome,
          culturaNome: widget.culturaNome,
        );

        final executiveSummary = await _unifiedDataService.getTalhaoExecutiveSummary(
          talhaoId: widget.talhaoId,
          culturaId: widget.culturaId,
          talhaoNome: widget.talhaoNome,
          culturaNome: widget.culturaNome,
        );

        setState(() {
          _completeData = completeData;
          _executiveSummary = executiveSummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_completeData == null || _executiveSummary == null) {
      return _buildNoDataWidget();
    }

    return _buildDataWidget();
  }

  Widget _buildErrorWidget() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text('Erro ao carregar dados integrados', style: TextStyles.body),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyles.smallText),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.analytics, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text('Análise Integrada de Plantio', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: Sem dados', style: TextStyles.smallText.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Para ver a análise completa:', style: TextStyles.smallText),
            const SizedBox(height: 4),
            Text('1. Calcule o CV% do plantio', style: TextStyles.smallText),
            Text('2. Registre o estande de plantas', style: TextStyles.smallText),
            Text('3. Os dados serão integrados automaticamente', style: TextStyles.smallText),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A análise integrada combina CV% com estande para fornecer recomendações agronômicas precisas.',
                      style: TextStyles.smallText.copyWith(color: Colors.blue[700]),
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

  Widget _buildDataWidget() {
    final hasCompleteData = _completeData!['hasCompleteData'] as bool;
    final status = _executiveSummary!['status'] as String? ?? '';
    final alerts = _executiveSummary!['alertas'] as List<String>? ?? [];
    final recomendacoes = _executiveSummary!['recomendacoes'] as dynamic;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(status, hasCompleteData),
            const SizedBox(height: 16),
            if (hasCompleteData) ...[
              _buildCompleteDataSection(),
              const SizedBox(height: 16),
            ],
            if (_ultimoCv != null) ...[
              _buildCvDataSection(),
              const SizedBox(height: 16),
            ],
            _buildSummarySection(),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAlertsSection(alerts),
            ],
            if (recomendacoes != null && recomendacoes.toString().isNotEmpty && recomendacoes.toString() != 'Dados insuficientes para análise') ...[
              const SizedBox(height: 16),
              _buildRecommendationsSection(recomendacoes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String status, bool hasCompleteData) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'excelente':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'bom (compensado)':
        statusColor = Colors.lightGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'atenção (germinação/solo)':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'crítico (plantio irregular)':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Análise Integrada de Plantio', style: TextStyles.subtitle),
              Text('Status: $status', style: TextStyles.body.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (hasCompleteData)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Dados Completos', style: TextStyles.smallText.copyWith(color: Colors.blue.shade800)),
          ),
      ],
    );
  }

  Widget _buildCompleteDataSection() {
    final cvData = _completeData!['cvData'] as List<PlantingCVModel>? ?? [];
    final standData = _completeData!['standData'] as List<PlantingStandModel>? ?? [];
    final integrationAnalysis = _completeData!['integrationAnalysis'] as PlantingIntegrationModel?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dados Completos Disponíveis', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDataItem(
                  'CV% do Plantio',
                  cvData.isNotEmpty ? '${cvData.first.coeficienteVariacao.toStringAsFixed(1)}%' : 'N/A',
                  cvData.isNotEmpty ? cvData.first.classificacaoTexto : 'N/A',
                  _getCvColor(cvData.isNotEmpty ? cvData.first.classificacao : null),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDataItem(
                  'Estande de Plantas',
                  standData.isNotEmpty ? '${standData.first.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha' : 'N/A',
                  standData.isNotEmpty ? standData.first.classificacaoTexto : 'N/A',
                  _getStandColor(standData.isNotEmpty ? standData.first.classificacao : null),
                ),
              ),
            ],
          ),
          if (integrationAnalysis != null) ...[
            const SizedBox(height: 8),
            _buildDataItem(
              'Análise da IA',
              _getProblemTypeText(integrationAnalysis.analiseIntegracao ?? IntegrationAnalysis.dadosIncompletos),
              'Diagnóstico integrado',
              _getProblemTypeColor(integrationAnalysis.analiseIntegracao ?? IntegrationAnalysis.dadosIncompletos),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final ultimoCv = (_executiveSummary!['ultimoCv'] as num?)?.toDouble();
    final ultimoStand = (_executiveSummary!['ultimoStand'] as num?)?.toDouble();
    final classificacaoCv = _executiveSummary!['classificacaoCv'] as String? ?? '';
    final classificacaoStand = _executiveSummary!['classificacaoStand'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumo dos Dados', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (ultimoCv != null)
          _buildSummaryItem('Último CV%', '${ultimoCv.toStringAsFixed(1)}% ($classificacaoCv)'),
        if (ultimoStand != null)
          _buildSummaryItem('Último Estande', '${ultimoStand.toStringAsFixed(0)} plantas/ha ($classificacaoStand)'),
        if (ultimoCv == null && ultimoStand == null)
          Text('Nenhum dado disponível', style: TextStyles.smallText.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAlertsSection(List<String> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 8),
        ...alerts.map((alert) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(alert, style: TextStyles.smallText)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRecommendationsSection(dynamic recomendacoes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recomendações da IA', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            recomendacoes is List<String> 
              ? recomendacoes.join('\n') 
              : recomendacoes.toString(), 
            style: TextStyles.smallText
          ),
        ),
      ],
    );
  }

  Widget _buildDataItem(String label, String value, String classification, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.smallText.copyWith(fontWeight: FontWeight.bold)),
        Text(value, style: TextStyles.body.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(classification, style: TextStyles.smallText.copyWith(color: color)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyles.smallText),
          Text(value, style: TextStyles.smallText.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getCvColor(CVClassification? classification) {
    switch (classification) {
      case CVClassification.excelente:
        return Colors.green;
      case CVClassification.bom:
        return Colors.orange;
      case CVClassification.ruim:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStandColor(StandClassification? classification) {
    switch (classification) {
      case StandClassification.excelente:
        return Colors.green;
      case StandClassification.bom:
        return Colors.lightGreen;
      case StandClassification.regular:
        return Colors.orange;
      case StandClassification.ruim:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getProblemTypeColor(IntegrationAnalysis type) {
    switch (type) {
      case IntegrationAnalysis.excelencia:
        return Colors.green;
      case IntegrationAnalysis.compensacaoGerminacao:
        return Colors.lightGreen;
      case IntegrationAnalysis.germinacaoBaixa:
        return Colors.orange;
      case IntegrationAnalysis.plantioIrregular:
        return Colors.red;
      case IntegrationAnalysis.dadosIncompletos:
        return Colors.grey;
    }
  }

  String _getProblemTypeText(IntegrationAnalysis type) {
    switch (type) {
      case IntegrationAnalysis.excelencia:
        return 'Nível de Excelência';
      case IntegrationAnalysis.compensacaoGerminacao:
        return 'Plantio Irregular Compensado';
      case IntegrationAnalysis.germinacaoBaixa:
        return 'Problema de Germinação/Solo';
      case IntegrationAnalysis.plantioIrregular:
        return 'Problema de Plantio Irregular';
      case IntegrationAnalysis.dadosIncompletos:
        return 'Dados Incompletos';
    }
  }

  Widget _buildCvDataSection() {
    if (_ultimoCv == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text('Dados de CV% Salvos', style: TextStyles.body.copyWith(fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCvMetric('CV%', '${_ultimoCv!.coeficienteVariacao.toStringAsFixed(1)}%', _ultimoCv!.classificacaoTexto),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCvMetric('População/ha', '${_ultimoCv!.populacaoEstimadaPorHectare.toStringAsFixed(0)}', 'plantas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCvMetric('Plantas/m', '${_ultimoCv!.plantasPorMetro.toStringAsFixed(1)}', 'plantas'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCvMetric('Data', DateFormat('dd/MM/yyyy').format(_ultimoCv!.dataPlantio), ''),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _ultimoCv!.classificacao == CVClassification.excelente ? Colors.green.shade100 :
                     _ultimoCv!.classificacao == CVClassification.bom ? Colors.blue.shade100 :
                     _ultimoCv!.classificacao == CVClassification.moderado ? Colors.orange.shade100 :
                     Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _ultimoCv!.classificacao == CVClassification.excelente ? Icons.check_circle :
                  _ultimoCv!.classificacao == CVClassification.bom ? Icons.thumb_up :
                  _ultimoCv!.classificacao == CVClassification.moderado ? Icons.warning :
                  Icons.error,
                  color: _ultimoCv!.classificacao == CVClassification.excelente ? Colors.green[700] :
                         _ultimoCv!.classificacao == CVClassification.bom ? Colors.blue[700] :
                         _ultimoCv!.classificacao == CVClassification.moderado ? Colors.orange[700] :
                         Colors.red[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Classificação: ${_ultimoCv!.classificacaoTexto}',
                    style: TextStyles.smallText.copyWith(
                      color: _ultimoCv!.classificacao == CVClassification.excelente ? Colors.green[700] :
                             _ultimoCv!.classificacao == CVClassification.bom ? Colors.blue[700] :
                             _ultimoCv!.classificacao == CVClassification.moderado ? Colors.orange[700] :
                             Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Exibir sugestões se disponíveis
          if (_ultimoCv!.sugestoes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Sugestões do Card de Resultado:',
                        style: TextStyles.smallText.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._ultimoCv!.sugestoes.map((sugestao) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Text(
                      '• $sugestao',
                      style: TextStyles.smallText.copyWith(color: Colors.blue[700]),
                    ),
                  )),
                ],
              ),
            ),
          ],
          // Exibir motivo do resultado se disponível
          if (_ultimoCv!.motivoResultado.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ultimoCv!.motivoResultado,
                      style: TextStyles.smallText.copyWith(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCvMetric(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.smallText.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: TextStyles.smallText.copyWith(color: Colors.grey[600])),
            ],
          ],
        ),
      ],
    );
  }
}
