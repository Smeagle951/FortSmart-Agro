import 'package:flutter/material.dart';
import '../../../services/agricultural_machine_data_service.dart';

/// Card para exibir dados de máquina importados
class MachineDataImportCard extends StatelessWidget {
  final MachineWorkData machineData;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MachineDataImportCard({
    Key? key,
    required this.machineData,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ícone da máquina
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getMachineColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: _getMachineColor(),
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Informações da máquina
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machineData.machineModel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getMachineColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getMachineTypeName(machineData.machineType),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getMachineColor(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${machineData.workPoints.length} pontos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Botão de ação
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showActionMenu(context),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Estatísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      Icons.crop_square,
                      'Área',
                      '${machineData.statistics.totalArea.toStringAsFixed(2)} ha',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      Icons.scale,
                      'Total',
                      '${machineData.statistics.totalApplied.toStringAsFixed(1)} kg',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      Icons.speed,
                      'Vel. Média',
                      '${machineData.statistics.averageSpeed.toStringAsFixed(1)} km/h',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      Icons.analytics,
                      'Eficiência',
                      '${machineData.statistics.efficiency.toStringAsFixed(1)}%',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Data e operador
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(machineData.workDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    machineData.operatorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói chip de estatística
  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém cor da máquina
  Color _getMachineColor() {
    switch (machineData.machineType) {
      case MachineType.jactoNPK:
        return Colors.green;
      case MachineType.staraPlantio:
      case MachineType.staraColheita:
      case MachineType.staraAplicacao:
        return Colors.blue;
      case MachineType.johnDeerePlantio:
      case MachineType.johnDeereColheita:
      case MachineType.johnDeereAplicacao:
        return Colors.orange;
      case MachineType.casePlantio:
      case MachineType.caseColheita:
        return Colors.red;
      case MachineType.newHolland:
        return Colors.purple;
      case MachineType.masseyFerguson:
        return Colors.brown;
      case MachineType.valtra:
        return Colors.cyan;
      case MachineType.fendt:
        return Colors.indigo;
      case MachineType.desconhecido:
        return Colors.grey;
    }
  }

  /// Obtém nome do tipo de máquina
  String _getMachineTypeName(MachineType type) {
    switch (type) {
      case MachineType.jactoNPK:
        return 'JACTO';
      case MachineType.staraPlantio:
        return 'STARA';
      case MachineType.staraColheita:
        return 'STARA';
      case MachineType.staraAplicacao:
        return 'STARA';
      case MachineType.johnDeerePlantio:
        return 'JOHN DEERE';
      case MachineType.johnDeereColheita:
        return 'JOHN DEERE';
      case MachineType.johnDeereAplicacao:
        return 'JOHN DEERE';
      case MachineType.casePlantio:
        return 'CASE';
      case MachineType.caseColheita:
        return 'CASE';
      case MachineType.newHolland:
        return 'NEW HOLLAND';
      case MachineType.masseyFerguson:
        return 'MASSEY FERGUSON';
      case MachineType.valtra:
        return 'VALTRA';
      case MachineType.fendt:
        return 'FENDT';
      case MachineType.desconhecido:
        return 'DESCONHECIDO';
    }
  }

  /// Formata data
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  /// Mostra menu de ações
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Visualizar'),
              onTap: () {
                Navigator.pop(context);
                onTap?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise Térmica'),
              onTap: () {
                Navigator.pop(context);
                onTap?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exportar'),
              onTap: () {
                Navigator.pop(context);
                _exportData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(context);
                _shareData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Exporta dados
  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de exportação em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Compartilha dados
  void _shareData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Confirma exclusão
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir os dados de "${machineData.machineModel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
