import 'package:flutter/material.dart';
import '../services/calibracao_fertilizante_service.dart';

/// Widget do gráfico de barras para visualizar os pesos das bandejas
class CalibracaoFertilizanteGrafico extends StatelessWidget {
  final List<double> pesos;
  final double espacamento;

  const CalibracaoFertilizanteGrafico({
    Key? key,
    required this.pesos,
    required this.espacamento,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pesos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Nenhum dado para exibir'),
          ),
        ),
      );
    }

    final media = CalibracaoFertilizanteService.calcularMedia(pesos);
    final maxPeso = pesos.reduce((a, b) => a > b ? a : b);
    final minPeso = pesos.reduce((a, b) => a < b ? a : b);
    final limite = media * 0.5; // Limite de 50% da média

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Gráfico de Distribuição',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Gráfico
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(pesos.length, (index) {
                  final peso = pesos[index];
                  final altura = peso / maxPeso;
                  final isAcimaLimite = peso >= limite;
                  final isAcimaMedia = peso >= media;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Column(
                        children: [
                          // Barra
                          Expanded(
                            child: Container(
                              width: 14,
                              decoration: BoxDecoration(
                                color: _getBarColor(peso, media, limite),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.bottomCenter,
                                heightFactor: altura,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getBarColor(peso, media, limite),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Valor
                          Text(
                            peso.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getBarColor(peso, media, limite),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Número da bandeja
                          Text(
                            'B${index + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legenda
            _buildLegenda(media, limite),
            
            const SizedBox(height: 16),
            
            // Linhas de referência
            _buildLinhasReferencia(media, limite, maxPeso),
          ],
        ),
      ),
    );
  }

  Widget _buildLegenda(double media, double limite) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legenda',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildLegendaItem(
                'Acima da média',
                Colors.green,
                Icons.trending_up,
              ),
            ),
            Expanded(
              child: _buildLegendaItem(
                'Abaixo da média',
                Colors.orange,
                Icons.trending_down,
              ),
            ),
            Expanded(
              child: _buildLegendaItem(
                'Abaixo do limite',
                Colors.red,
                Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendaItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinhasReferencia(double media, double limite, double maxPeso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linhas de Referência',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildReferenciaItem(
                'Média',
                '${media.toStringAsFixed(1)} g',
                Colors.green,
                Icons.horizontal_rule,
              ),
            ),
            Expanded(
              child: _buildReferenciaItem(
                'Limite 50%',
                '${limite.toStringAsFixed(1)} g',
                Colors.orange,
                Icons.horizontal_rule,
              ),
            ),
            Expanded(
              child: _buildReferenciaItem(
                'Máximo',
                '${maxPeso.toStringAsFixed(1)} g',
                Colors.blue,
                Icons.horizontal_rule,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReferenciaItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBarColor(double peso, double media, double limite) {
    if (peso >= media) {
      return Colors.green;
    } else if (peso >= limite) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
