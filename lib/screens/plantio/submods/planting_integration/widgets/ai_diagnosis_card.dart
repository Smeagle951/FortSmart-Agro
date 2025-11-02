import 'package:flutter/material.dart';
import '../../../../models/planting_integration_model.dart';

/// Widget para exibir o diagnóstico da IA
class AIDiagnosisCard extends StatelessWidget {
  final String diagnostico;
  final IntegrationAnalysis analise;

  const AIDiagnosisCard({
    Key? key,
    required this.diagnostico,
    required this.analise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnóstico da IA Agronômica',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                      Text(
                        'Análise inteligente baseada nos dados coletados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Diagnóstico
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.purple[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Análise Inteligente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    diagnostico,
                    style: TextStyle(
                      color: Colors.purple[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Indicadores de confiança
            _buildConfidenceIndicators(),
          ],
        ),
      ),
    );
  }

  /// Constrói indicadores de confiança
  Widget _buildConfidenceIndicators() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicadores de Confiança',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildConfidenceItem(
                  'Qualidade dos Dados',
                  _getDataQualityScore(),
                  _getDataQualityColor(),
                  Icons.analytics,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildConfidenceItem(
                  'Precisão da Análise',
                  _getAnalysisAccuracyScore(),
                  _getAnalysisAccuracyColor(),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói item de confiança
  Widget _buildConfidenceItem(
    String label,
    int score,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '$score%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Calcula score de qualidade dos dados
  int _getDataQualityScore() {
    switch (analise) {
      case IntegrationAnalysis.excelencia:
      case IntegrationAnalysis.plantioIrregular:
      case IntegrationAnalysis.germinacaoBaixa:
      case IntegrationAnalysis.compensacaoGerminacao:
        return 95; // Dados completos
      case IntegrationAnalysis.dadosIncompletos:
        return 60; // Dados incompletos
    }
  }

  /// Calcula score de precisão da análise
  int _getAnalysisAccuracyScore() {
    switch (analise) {
      case IntegrationAnalysis.excelencia:
        return 98; // Análise muito precisa
      case IntegrationAnalysis.plantioIrregular:
        return 95; // Análise precisa
      case IntegrationAnalysis.germinacaoBaixa:
        return 90; // Análise boa
      case IntegrationAnalysis.compensacaoGerminacao:
        return 85; // Análise boa
      case IntegrationAnalysis.dadosIncompletos:
        return 70; // Análise limitada
    }
  }

  /// Retorna cor da qualidade dos dados
  Color _getDataQualityColor() {
    final score = _getDataQualityScore();
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Retorna cor da precisão da análise
  Color _getAnalysisAccuracyColor() {
    final score = _getAnalysisAccuracyScore();
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
