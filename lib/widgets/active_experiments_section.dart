import 'package:flutter/material.dart';
import '../models/experiment.dart';
import 'package:intl/intl.dart';

class ActiveExperimentsSection extends StatelessWidget {
  final List<Experiment> experiments;
  final Function(String) onViewExperimentDetails;
  final bool isLoading;

  const ActiveExperimentsSection({
    Key? key,
    required this.experiments,
    required this.onViewExperimentDetails,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(
                Icons.science,
                color: Color(0xFF2A4F3D),
              ),
              const SizedBox(width: 8),
              const Text(
                'Experimentos Ativos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A4F3D),
                ),
              ),
              const Spacer(),
              if (experiments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A4F3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${experiments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (experiments.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      color: Colors.grey,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sem experimentos ativos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crie um novo experimento para monitorar seus resultados',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              ...experiments.map((experiment) => _buildExperimentCard(context, experiment)),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Navegar para a tela de todos os experimentos
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Ver todos os experimentos'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2A4F3D),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExperimentCard(BuildContext context, Experiment experiment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDate = experiment.startDate != null 
        ? dateFormat.format(DateTime.parse(experiment.startDate!))
        : 'Data desconhecida';
    
    final endDate = experiment.endDate != null 
        ? dateFormat.format(DateTime.parse(experiment.endDate!))
        : 'Em andamento';
    
    // Calcular o progresso do experimento
    double progress = 0.0;
    String progressText = "0%";
    
    if (experiment.startDate != null) {
      final start = DateTime.parse(experiment.startDate!);
      final end = experiment.endDate != null 
          ? DateTime.parse(experiment.endDate!) 
          : DateTime.now().add(const Duration(days: 1));
      final current = DateTime.now();
      
      if (current.isAfter(start) && current.isBefore(end)) {
        final totalDuration = end.difference(start).inDays;
        final elapsedDuration = current.difference(start).inDays;
        progress = totalDuration > 0 ? elapsedDuration / totalDuration : 0;
        progressText = "${(progress * 100).toStringAsFixed(0)}%";
      } else if (current.isAfter(end)) {
        progress = 1.0;
        progressText = "100%";
      }
    }

    // Cores para cada tipo de experimento
    final Map<String, Color> experimentTypeColors = {
      'fertilizante': Colors.green,
      'variedade': Colors.purple,
      'defensivo': Colors.blue,
      'densidade': Colors.orange,
      'irrigação': Colors.cyan,
    };

    final Color experimentColor = experimentTypeColors[experiment.type?.toLowerCase()] ?? Colors.teal;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // onTap: () => onViewExperimentDetails(experiment.id ?? ''), // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: experimentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: experimentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experiment.name ?? 'Experimento sem nome',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: experimentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                experiment.type?.toUpperCase() ?? 'GERAL',
                                style: TextStyle(
                                  color: experimentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Talhão: ${experiment.plotName ?? 'Não especificado'}',
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Início: $startDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Fim: $endDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        // backgroundColor: Colors.grey[200], // backgroundColor não é suportado em flutter_map 5.0.0
                        valueColor: AlwaysStoppedAnimation<Color>(experimentColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: experimentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                experiment.description ?? 'Sem descrição disponível',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              if (experiment.results != null && experiment.results!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Resultados parciais: ${experiment.results}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Experimentos Ativos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A4F3D),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF2A4F3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Carregando experimentos...'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
