import 'package:flutter/material.dart';
import '../../../models/machine.dart';

class MachineDetailsCard extends StatelessWidget {
  final Machine machine;
  final VoidCallback? onSelect;

  const MachineDetailsCard({
    Key? key,
    required this.machine,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com nome e modelo
              Row(
                children: [
                  _buildMachineIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${machine.brand} ${machine.model}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onSelect != null)
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF228B22),
                    ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Especificações técnicas
              _buildSpecificationRow('Tipo', _getMachineTypeText()),
              _buildSpecificationRow('Ano', machine.year?.toString() ?? 'Não informado'),
              _buildSpecificationRow('Potência', machine.power != null ? '${machine.power} HP' : 'Não informado'),
              
              // Especificações técnicas
              if (machine.type == MachineType.tractor || machine.type == MachineType.harvester) ...[  
                _buildSpecificationRow('Potência', '${machine.power ?? "Não informado"} ${machine.power != null ? "HP" : ""}'),
                _buildSpecificationRow('Tração', machine.traction ?? 'Não informado'),
              ],
              if (machine.type == MachineType.planter || machine.type == MachineType.seeder) ...[  
                _buildSpecificationRow('Linhas', '${machine.lines ?? "Não informado"}'),
                _buildSpecificationRow('Espaçamento', '${machine.spacing != null ? "${machine.spacing} cm" : "Não informado"}'),
              ],
              
              const SizedBox(height: 16),
              
              // Status e manutenção
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(),
                ],
              ),
              
              const Divider(),
              _buildSpecificationRow(
                'Última Manutenção',
                machine.lastMaintenance != null
                    ? _formatDate(machine.lastMaintenance!)
                    : 'Não registrada',
              ),
              
              if (machine.notes != null && machine.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Observações: ${machine.notes}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (machine.type) {
      case MachineType.tractor:
        iconData = Icons.agriculture;
        iconColor = Colors.green;
        break;
      case MachineType.harvester:
        iconData = Icons.agriculture;
        iconColor = Colors.amber;
        break;
      case MachineType.planter:
        iconData = Icons.grass;
        iconColor = Colors.green;
        break;
      case MachineType.sprayer:
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.agriculture;
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    
    if (machine.status == MachineStatus.operational) {
      chipColor = Colors.green;
      statusText = 'Operacional';
    } else if (machine.status == MachineStatus.maintenance) {
      chipColor = Colors.amber;
      statusText = 'Em Manutenção';
    } else if (machine.status == MachineStatus.broken) {
      chipColor = Colors.red;
      statusText = 'Quebrado';
    } else if (machine.status == MachineStatus.inactive) {
      chipColor = Colors.grey;
      statusText = 'Inativo';
    } else {
      chipColor = Colors.grey;
      statusText = 'Não definido';
    }
    
    return Chip(
      backgroundColor: chipColor.withOpacity(0.1),
      side: BorderSide(color: chipColor),
      label: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getMachineTypeText() {
    switch (machine.type) {
      case MachineType.tractor:
        return 'Trator';
      case MachineType.harvester:
        return 'Colheitadeira';
      case MachineType.planter:
        return 'Plantadeira';
      case MachineType.sprayer:
        return 'Pulverizador';
      default:
        return 'Outro';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
