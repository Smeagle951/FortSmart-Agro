import 'package:flutter/material.dart';

/// Widget responsável pela legenda do mapa
class MapLegendWidget extends StatelessWidget {
  final VoidCallback? onFullMapTap;
  final VoidCallback? onLegendTap;

  const MapLegendWidget({
    Key? key,
    this.onFullMapTap,
    this.onLegendTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Legenda do Mapa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onFullMapTap != null)
                  ElevatedButton.icon(
                    onPressed: onFullMapTap,
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Mapa Completo', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Tipos de ponto
            _buildLegendSection(
              'Tipos de Ponto',
              [
                _buildLegendItem(Icons.location_on, 'Ponto Atual', Colors.red.shade600),
                _buildLegendItem(Icons.navigation, 'Próximo Ponto', Colors.green.shade600),
                _buildLegendItem(Icons.warning, 'Alerta Histórico', Colors.orange.shade600),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Tipos de ocorrência
            _buildLegendSection(
              'Tipos de Ocorrência',
              [
                _buildLegendItem(Icons.bug_report, 'Praga', Colors.orange.shade600),
                _buildLegendItem(Icons.healing, 'Doença', Colors.red.shade600),
                _buildLegendItem(Icons.local_florist, 'Planta Daninha', Colors.purple.shade600),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Níveis de severidade
            _buildLegendSection(
              'Níveis de Severidade',
              [
                _buildLegendItem(Icons.circle, 'Baixa (0-25%)', Colors.green.shade600),
                _buildLegendItem(Icons.circle, 'Média (26-50%)', Colors.yellow.shade600),
                _buildLegendItem(Icons.circle, 'Alta (51-75%)', Colors.orange.shade600),
                _buildLegendItem(Icons.circle, 'Crítica (76-100%)', Colors.red.shade600),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Rota
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timeline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Linha azul tracejada = Rota entre pontos',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
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

  Widget _buildLegendSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 8.0),
        ...items,
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
