import 'package:flutter/material.dart';
import '../../../models/occurrence.dart';
import '../../../utils/enums.dart';

/// Widget responsável por exibir ocorrências em cartões organizados
class OccurrenceCardWidget extends StatelessWidget {
  final Occurrence occurrence;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;
  final bool showActions;

  const OccurrenceCardWidget({
    Key? key,
    required this.occurrence,
    this.onRemove,
    this.onEdit,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ícone da ocorrência
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _getOccurrenceTypeColor(occurrence.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                _getOccurrenceTypeIcon(occurrence.type),
                color: _getOccurrenceTypeColor(occurrence.type),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16.0),
            
            // Informações da ocorrência
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getOccurrenceTypeColor(occurrence.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          _getOccurrenceTypeName(occurrence.type),
                          style: TextStyle(
                            color: _getOccurrenceTypeColor(occurrence.type),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(occurrence.infestationIndex).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          '${occurrence.infestationIndex.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getSeverityColor(occurrence.infestationIndex),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  Text(
                    occurrence.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (occurrence.affectedSections.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: occurrence.affectedSections.map((section) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _getPlantSectionName(section),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 10.0,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  if (occurrence.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      occurrence.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Ações
            if (showActions) ...[
              const SizedBox(width: 8.0),
              Column(
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      tooltip: 'Editar',
                    ),
                  if (onRemove != null)
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      tooltip: 'Remover',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Utilitários para cores e ícones
  Color _getOccurrenceTypeColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.orange.shade600;
      case OccurrenceType.disease:
        return Colors.red.shade600;
      case OccurrenceType.weed:
        return Colors.purple.shade600;
      case OccurrenceType.deficiency:
        return Colors.orange.shade600;
      case OccurrenceType.other:
        return Colors.grey.shade600;
    }
  }

  IconData _getOccurrenceTypeIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.healing;
      case OccurrenceType.weed:
        return Icons.local_florist;
      case OccurrenceType.deficiency:
        return Icons.warning;
      case OccurrenceType.other:
        return Icons.info;
    }
  }

  String _getOccurrenceTypeName(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência';
      case OccurrenceType.other:
        return 'Outro';
    }
  }

  Color _getSeverityColor(double index) {
    if (index < 25) return Colors.green.shade600;
    if (index < 50) return Colors.yellow.shade600;
    if (index < 75) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getPlantSectionName(PlantSection section) {
    switch (section) {
      case PlantSection.upper:
        return 'Superior';
      case PlantSection.middle:
        return 'Médio';
      case PlantSection.lower:
        return 'Inferior';
      case PlantSection.leaf:
        return 'Folha';
      case PlantSection.stem:
        return 'Caule';
      case PlantSection.root:
        return 'Raiz';
      case PlantSection.flower:
        return 'Flor';
      case PlantSection.fruit:
        return 'Fruto';
      case PlantSection.seed:
        return 'Semente';
    }
  }
}

/// Widget para lista de ocorrências
class OccurrencesListWidget extends StatelessWidget {
  final List<Occurrence> occurrences;
  final Function(Occurrence)? onRemove;
  final Function(Occurrence)? onEdit;
  final String emptyMessage;

  const OccurrencesListWidget({
    Key? key,
    required this.occurrences,
    this.onRemove,
    this.onEdit,
    this.emptyMessage = 'Nenhuma ocorrência registrada',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16.0),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ocorrências registradas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        ...occurrences.map((occurrence) => OccurrenceCardWidget(
          occurrence: occurrence,
          onRemove: onRemove != null ? () => onRemove!(occurrence) : null,
          onEdit: onEdit != null ? () => onEdit!(occurrence) : null,
        )),
      ],
    );
  }
}
