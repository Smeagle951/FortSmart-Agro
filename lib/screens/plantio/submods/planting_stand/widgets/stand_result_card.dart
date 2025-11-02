import 'package:flutter/material.dart';
import '../../../../models/planting_stand_model.dart';

/// Widget para exibir o resultado do cálculo de estande
class StandResultCard extends StatelessWidget {
  final PlantingStandModel resultado;

  const StandResultCard({
    Key? key,
    required this.resultado,
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
            // Cabeçalho com classificação
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForClassification(resultado.classificacao),
                    color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resultado.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                        ),
                      ),
                      Text(
                        resultado.classificacaoTexto,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Descrição da classificação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resultado.classificacaoDescricao,
                      style: TextStyle(
                        color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Métricas principais
            Text(
              'Métricas Calculadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Grid de métricas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  context,
                  'Plantas por Metro',
                  '${resultado.plantasPorMetro.toStringAsFixed(2)}',
                  Icons.straighten,
                  Colors.blue,
                ),
                _buildMetricCard(
                  context,
                  'População Real/ha',
                  '${resultado.populacaoRealPorHectare.toStringAsFixed(0)}',
                  Icons.grid_view,
                  Colors.green,
                ),
                if (resultado.percentualAtingidoPopulacaoAlvo != null)
                  _buildMetricCard(
                    context,
                    '% Atingido do Alvo',
                    '${resultado.percentualAtingidoPopulacaoAlvo!.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                if (resultado.percentualGerminacaoTeorica != null)
                  _buildMetricCard(
                    context,
                    '% Germinação Teórica',
                    '${resultado.percentualGerminacaoTeorica!.toStringAsFixed(1)}%',
                    Icons.eco,
                    Colors.purple,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações da avaliação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Informações da Avaliação',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Comprimento da linha', '${resultado.comprimentoLinhaAvaliado.toStringAsFixed(1)} m'),
                  _buildInfoRow('Número de linhas', '${resultado.numeroLinhasAvaliadas}'),
                  _buildInfoRow('Espaçamento entre linhas', '${resultado.espacamentoEntreLinhas.toStringAsFixed(2)} m'),
                  _buildInfoRow('Plantas contadas', '${resultado.plantasContadas}'),
                  _buildInfoRow('Data da avaliação', '${resultado.dataAvaliacao.day}/${resultado.dataAvaliacao.month}/${resultado.dataAvaliacao.year}'),
                ],
              ),
            ),
            
            // População alvo se definida
            if (resultado.populacaoAlvo != null) ...[
              const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Icon(Icons.flag, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'População Alvo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resultado.populacaoAlvo!.toStringAsFixed(0)} plantas/ha',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    if (resultado.percentualAtingidoPopulacaoAlvo != null) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: resultado.percentualAtingidoPopulacaoAlvo! / 100,
                        backgroundColor: Colors.blue[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          resultado.percentualAtingidoPopulacaoAlvo! >= 90
                              ? Colors.green
                              : resultado.percentualAtingidoPopulacaoAlvo! >= 75
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resultado.percentualAtingidoPopulacaoAlvo!.toStringAsFixed(1)}% do alvo atingido',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Observações se houver
            if (resultado.observacoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Observações',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultado.observacoes,
                      style: TextStyle(color: Colors.amber[700]),
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

  /// Constrói um card de métrica
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String value) {
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna o ícone apropriado para a classificação
  IconData _getIconForClassification(StandClassification classification) {
    switch (classification) {
      case StandClassification.excelente:
        return Icons.check_circle;
      case StandClassification.bom:
        return Icons.warning;
      case StandClassification.regular:
        return Icons.warning_amber;
      case StandClassification.ruim:
        return Icons.error;
      case StandClassification.naoAvaliado:
        return Icons.help_outline;
    }
  }
}
