import 'package:flutter/material.dart';
import '../../../../../models/planting_cv_model.dart';

/// Widget para exibir o resultado do cálculo de CV%
class CVResultCard extends StatelessWidget {
  final PlantingCVModel resultado;

  const CVResultCard({
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
                        'CV%: ${resultado.coeficienteVariacao.toStringAsFixed(2)}%',
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
              childAspectRatio: 2.8, // Aumentado de 2.2 para 2.8 para evitar overflow
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  context,
                  'Média do Espaçamento',
                  '${resultado.mediaEspacamento.toStringAsFixed(1)} cm',
                  Icons.straighten,
                  Colors.blue,
                ),
                _buildMetricCard(
                  context,
                  'Desvio-Padrão',
                  '${resultado.desvioPadrao.toStringAsFixed(1)} cm',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildMetricCard(
                  context,
                  'Plantas por Metro',
                  '${resultado.plantasPorMetro.toStringAsFixed(1)}',
                  Icons.eco,
                  Colors.green,
                ),
                _buildMetricCard(
                  context,
                  'População/ha',
                  '${resultado.populacaoEstimadaPorHectare.toStringAsFixed(0)}',
                  Icons.grid_view,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações adicionais
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
                        'Informações da Amostragem',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Comprimento da linha', '${resultado.comprimentoLinhaAmostrada.toStringAsFixed(1)} m'),
                  _buildInfoRow('Espaçamento entre linhas', '${resultado.espacamentoEntreLinhas.toStringAsFixed(2)} m'),
                  _buildInfoRow('Número de medições', '${resultado.distanciasEntreSementes.length}'),
                  _buildInfoRow('Data do plantio', '${resultado.dataPlantio.day}/${resultado.dataPlantio.month}/${resultado.dataPlantio.year}'),
                ],
              ),
            ),
            
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
      padding: const EdgeInsets.all(8), // Reduzido de 10 para 8
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mudado de center para spaceBetween
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10, // Reduzido de 11 para 10
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Reduzido de 6 para 4
          Text(
            value,
            style: TextStyle(
              fontSize: 13, // Reduzido de 14 para 13
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
  IconData _getIconForClassification(CVClassification classification) {
    switch (classification) {
      case CVClassification.excelente:
        return Icons.check_circle;
      case CVClassification.bom:
        return Icons.warning;
      case CVClassification.moderado:
        return Icons.info;
      case CVClassification.ruim:
        return Icons.error;
    }
  }
}
