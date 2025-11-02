import 'package:flutter/material.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';

/// Widget para exibir informações de uma ocorrência (praga, doença ou planta daninha)
class OccurrenceCard extends StatelessWidget {
  final Occurrence occurrence;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const OccurrenceCard({
    Key? key,
    required this.occurrence,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar a cor com base no tipo de ocorrência
    Color cardColor;
    IconData typeIcon;
    
    switch (occurrence.type) {
      case OccurrenceType.pest:
        cardColor = Colors.orange.shade100;
        typeIcon = Icons.bug_report;
        break;
      case OccurrenceType.disease:
        cardColor = Colors.red.shade100;
        typeIcon = Icons.coronavirus;
        break;
      case OccurrenceType.weed:
        cardColor = Colors.green.shade100;
        typeIcon = Icons.grass;
        break;
      default:
        cardColor = Colors.grey.shade100;
        typeIcon = Icons.help_outline;
    }

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com tipo e ações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tipo de ocorrência
                Row(
                  children: [
                    Icon(typeIcon, color: Colors.grey.shade800),
                    const SizedBox(width: 8),
                    Text(
                      _getOccurrenceTypeText(occurrence.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                // Botões de ação
                if (showActions)
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: onEdit,
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 16),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context);
                          },
                          tooltip: 'Excluir',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
              ],
            ),
            
            const Divider(),
            
            // Nome da ocorrência
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                occurrence.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Índice de infestação
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Índice de infestação:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildInfestationIndicator(occurrence.infestationIndex),
                ],
              ),
            ),
            
            // Seções afetadas
            if (occurrence.affectedSections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seções afetadas:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildAffectedSections(occurrence.affectedSections),
                  ],
                ),
              ),
            
            // Observações
            if (occurrence.notes != null && occurrence.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      occurrence.notes!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Data de registro
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Registrado em: ${_formatDate(occurrence.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói o indicador visual do índice de infestação
  Widget _buildInfestationIndicator(double value) {
    // Determina cor com base no valor
    Color color;
    if (value < 33) {
      color = Colors.green;
    } else if (value < 66) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: value / 100, // Normaliza para 0.0-1.0
            // backgroundColor: Colors.grey.shade200, // backgroundColor não é suportado em flutter_map 5.0.0
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toInt()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Constrói as seções afetadas
  Widget _buildAffectedSections(List<PlantSection> sections) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: sections.map((section) {
        String sectionName;
        switch (section) {
          case PlantSection.upper:
            sectionName = 'Superior';
            break;
          case PlantSection.middle:
            sectionName = 'Médio';
            break;
          case PlantSection.lower:
            sectionName = 'Inferior';
            break;
          default:
            sectionName = section.toString().split('.').last;
        }
        
        return Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          label: Text(sectionName),
          // backgroundColor: Colors.grey.shade200, // backgroundColor não é suportado em flutter_map 5.0.0
          labelStyle: const TextStyle(fontSize: 12),
          padding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  // Formata a data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Retorna o texto do tipo de ocorrência
  String _getOccurrenceTypeText(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      default:
        return 'Desconhecido';
    }
  }

  // Exibe um diálogo de confirmação antes de excluir
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a ocorrência "${occurrence.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onDelete != null) {
                onDelete!();
              }
            },
            child: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
