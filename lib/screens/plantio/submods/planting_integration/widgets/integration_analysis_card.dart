import 'package:flutter/material.dart';
import '../../../../models/planting_integration_model.dart';

/// Widget para exibir a análise de integração CV% + Estande
class IntegrationAnalysisCard extends StatelessWidget {
  final PlantingIntegrationModel integracao;

  const IntegrationAnalysisCard({
    Key? key,
    required this.integracao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com análise
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForAnalysis(integracao.analiseIntegracao),
                    color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integracao.analiseTexto,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))),
                        ),
                      ),
                      Text(
                        'Análise Integrada CV% + Estande',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Descrição da análise
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      integracao.analiseDescricao,
                      style: TextStyle(
                        color: Color(int.parse(integracao.corIndicador.replaceAll('#', '0xFF'))),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dados do CV% se disponível
            if (integracao.cvPlantio != null) ...[
              _buildDataSection(
                context,
                'CV% do Plantio',
                Icons.straighten,
                Colors.blue,
                [
                  _buildDataRow('CV%', '${integracao.cvPlantio!.coeficienteVariacao.toStringAsFixed(1)}%'),
                  _buildDataRow('Classificação', integracao.cvPlantio!.classificacaoTexto),
                  _buildDataRow('Plantas/m', '${integracao.cvPlantio!.plantasPorMetro.toStringAsFixed(1)}'),
                  _buildDataRow('População estimada/ha', '${integracao.cvPlantio!.populacaoEstimadaPorHectare.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Dados do Estande se disponível
            if (integracao.estandePlantas != null) ...[
              _buildDataSection(
                context,
                'Estande de Plantas',
                Icons.eco,
                Colors.green,
                [
                  _buildDataRow('População real/ha', '${integracao.estandePlantas!.populacaoRealPorHectare.toStringAsFixed(0)}'),
                  _buildDataRow('Classificação', integracao.estandePlantas!.classificacaoTexto),
                  _buildDataRow('Plantas/m', '${integracao.estandePlantas!.plantasPorMetro.toStringAsFixed(1)}'),
                  if (integracao.estandePlantas!.percentualAtingidoPopulacaoAlvo != null)
                    _buildDataRow('% Atingido do alvo', '${integracao.estandePlantas!.percentualAtingidoPopulacaoAlvo!.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Nível de prioridade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPriorityColor(integracao.nivelPrioridade).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPriorityColor(integracao.nivelPrioridade).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPriorityIcon(integracao.nivelPrioridade),
                    color: _getPriorityColor(integracao.nivelPrioridade),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nível de Prioridade: ${_getPriorityText(integracao.nivelPrioridade)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(integracao.nivelPrioridade),
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

  /// Constrói seção de dados
  Widget _buildDataSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> dataRows,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...dataRows,
        ],
      ),
    );
  }

  /// Constrói linha de dados
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna o ícone apropriado para a análise
  IconData _getIconForAnalysis(IntegrationAnalysis analysis) {
    switch (analysis) {
      case IntegrationAnalysis.excelencia:
        return Icons.check_circle;
      case IntegrationAnalysis.plantioIrregular:
        return Icons.error;
      case IntegrationAnalysis.germinacaoBaixa:
        return Icons.warning;
      case IntegrationAnalysis.compensacaoGerminacao:
        return Icons.warning_amber;
      case IntegrationAnalysis.dadosIncompletos:
        return Icons.help_outline;
    }
  }

  /// Retorna a cor da prioridade
  Color _getPriorityColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.baixa:
        return Colors.green;
      case PriorityLevel.media:
        return Colors.orange;
      case PriorityLevel.alta:
        return Colors.red;
      case PriorityLevel.critica:
        return Colors.purple;
    }
  }

  /// Retorna o ícone da prioridade
  IconData _getPriorityIcon(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.baixa:
        return Icons.check_circle;
      case PriorityLevel.media:
        return Icons.warning;
      case PriorityLevel.alta:
        return Icons.error;
      case PriorityLevel.critica:
        return Icons.priority_high;
    }
  }

  /// Retorna o texto da prioridade
  String _getPriorityText(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.baixa:
        return 'Baixa';
      case PriorityLevel.media:
        return 'Média';
      case PriorityLevel.alta:
        return 'Alta';
      case PriorityLevel.critica:
        return 'Crítica';
    }
  }
}
