import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../models/cultura_model.dart';

/// Widget popup para exibir informações do talhão
class TalhaoPopupWidget extends StatelessWidget {
  final TalhaoModel talhao;
  final List<CulturaModel> cultures;
  final Function(TalhaoModel) onEdit;
  final Function(String) onDelete;
  final VoidCallback onClose;

  const TalhaoPopupWidget({
    Key? key,
    required this.talhao,
    required this.cultures,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cultura = cultures.firstWhere(
      (c) => c.id == talhao.culturaId,
      orElse: () => CulturaModel(id: '', name: 'Desconhecida', color: Colors.green),
    );

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  cultura.name,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talhao.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cultura.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações do talhão
            _buildInfoRow('Safra', talhao.safraAtual?.safra ?? 'N/A'),
            _buildInfoRow('Área', '${_formatArea(talhao.area)} ha'),
            _buildInfoRow('Perímetro', '${_formatDistance(talhao.poligonos.isNotEmpty ? talhao.poligonos.first.perimetro : 0.0)}'),
            _buildInfoRow('Pontos', '${talhao.points.length}'),
            
            if (talhao.observacoes != null && talhao.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Observações', talhao.observacoes!),
            ],
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onEdit(talhao),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o talhão "${talhao.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(talhao.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatArea(double hectares) {
    return hectares.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
    }
  }
}
