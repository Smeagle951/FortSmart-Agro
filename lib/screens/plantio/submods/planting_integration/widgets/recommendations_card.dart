import 'package:flutter/material.dart';
import '../../../../models/planting_integration_model.dart';

/// Widget para exibir as recomendações da IA
class RecommendationsCard extends StatelessWidget {
  final List<String> recomendacoes;
  final PriorityLevel nivelPrioridade;

  const RecommendationsCard({
    Key? key,
    required this.recomendacoes,
    required this.nivelPrioridade,
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendações da IA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'Ações sugeridas baseadas na análise',
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
            
            // Nível de prioridade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getPriorityColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPriorityIcon(),
                    color: _getPriorityColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prioridade: ${_getPriorityText()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPriorityDescription(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de recomendações
            ...recomendacoes.asMap().entries.map((entry) {
              final index = entry.key;
              final recomendacao = entry.value;
              final isHighPriority = _isHighPriorityRecommendation(recomendacao);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHighPriority ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighPriority ? Colors.red[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isHighPriority ? Colors.red[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isHighPriority ? Colors.red[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recomendacao,
                            style: TextStyle(
                              color: isHighPriority ? Colors.red[700] : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isHighPriority) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ALTA PRIORIDADE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Informações adicionais
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As recomendações são baseadas em dados científicos e melhores práticas agrícolas. '
                      'Consulte sempre um agrônomo para validação das ações sugeridas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                        fontStyle: FontStyle.italic,
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

  /// Verifica se a recomendação é de alta prioridade
  bool _isHighPriorityRecommendation(String recomendacao) {
    final highPriorityKeywords = [
      'imediatamente',
      'urgente',
      'crítico',
      'replantio',
      'verificar imediatamente',
      'ação imediata',
      'atenção necessária',
    ];
    
    return highPriorityKeywords.any((keyword) => 
        recomendacao.toLowerCase().contains(keyword));
  }

  /// Retorna a cor da prioridade
  Color _getPriorityColor() {
    switch (nivelPrioridade) {
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
  IconData _getPriorityIcon() {
    switch (nivelPrioridade) {
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
  String _getPriorityText() {
    switch (nivelPrioridade) {
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

  /// Retorna a descrição da prioridade
  String _getPriorityDescription() {
    switch (nivelPrioridade) {
      case PriorityLevel.baixa:
        return 'Manter práticas';
      case PriorityLevel.media:
        return 'Monitorar';
      case PriorityLevel.alta:
        return 'Ação necessária';
      case PriorityLevel.critica:
        return 'Ação urgente';
    }
  }
}
