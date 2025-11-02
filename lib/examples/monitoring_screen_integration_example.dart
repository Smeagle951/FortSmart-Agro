import 'package:flutter/material.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../widgets/monitoring_integration_widget.dart';

/// Exemplo de como integrar o widget de integração em uma tela de monitoramento
/// Demonstra como usar o MonitoringIntegrationWidget em uma tela existente
class MonitoringScreenIntegrationExample extends StatefulWidget {
  const MonitoringScreenIntegrationExample({Key? key}) : super(key: key);

  @override
  State<MonitoringScreenIntegrationExample> createState() => _MonitoringScreenIntegrationExampleState();
}

class _MonitoringScreenIntegrationExampleState extends State<MonitoringScreenIntegrationExample> {
  Monitoring? _currentMonitoring;
  bool _showIntegrationWidget = true;

  @override
  void initState() {
    super.initState();
    _createExampleMonitoring();
  }

  /// Cria um monitoramento de exemplo
  void _createExampleMonitoring() {
    final points = [
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -15.7801,
        longitude: -47.9292,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Lagarta-da-soja',
            infestationIndex: 15.0,
            affectedSections: [PlantSection.upper, PlantSection.middle],
            notes: 'Infestação moderada no terço superior',
          ),
          Occurrence(
            type: OccurrenceType.disease,
            name: 'Ferrugem-asiática',
            infestationIndex: 8.0,
            affectedSections: [PlantSection.middle],
            notes: 'Manchas nas folhas do terço médio',
          ),
        ],
      ),
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -15.7802,
        longitude: -47.9293,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Percevejo-marrom',
            infestationIndex: 25.0,
            affectedSections: [PlantSection.upper],
            notes: 'Alta infestação de percevejos',
          ),
        ],
      ),
    ];

    _currentMonitoring = Monitoring(
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão 1',
      cropId: 1,
      cropName: 'Soja',
      route: [],
      points: points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo de Integração de Monitoramento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showIntegrationWidget ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showIntegrationWidget = !_showIntegrationWidget;
              });
            },
            tooltip: _showIntegrationWidget ? 'Ocultar integração' : 'Mostrar integração',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Widget de integração
            if (_showIntegrationWidget)
              MonitoringIntegrationWidget(
                monitoring: _currentMonitoring,
                showDetails: true,
                onIntegrationComplete: () {
                  _showSuccessMessage('Integração concluída com sucesso!');
                },
              ),
            
            // Informações do monitoramento
            _buildMonitoringInfo(),
            
            // Pontos de monitoramento
            _buildMonitoringPoints(),
            
            // Ações
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Constrói informações do monitoramento
  Widget _buildMonitoringInfo() {
    if (_currentMonitoring == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum monitoramento disponível'),
        ),
      );
    }

    final monitoring = _currentMonitoring!;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Monitoramento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', monitoring.id),
            _buildInfoRow('Talhão', monitoring.plotName),
            _buildInfoRow('Cultura', monitoring.cropName),
            _buildInfoRow('Data', monitoring.date.toString().split(' ')[0]),
            _buildInfoRow('Total de Pontos', monitoring.points.length.toString()),
            _buildInfoRow('Total de Ocorrências', 
              monitoring.points.fold(0, (sum, point) => sum + point.occurrences.length).toString()),
          ],
        ),
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Constrói pontos de monitoramento
  Widget _buildMonitoringPoints() {
    if (_currentMonitoring == null || _currentMonitoring!.points.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pontos de Monitoramento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._currentMonitoring!.points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ponto ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Latitude', point.latitude.toStringAsFixed(6)),
                    _buildInfoRow('Longitude', point.longitude.toStringAsFixed(6)),
                    _buildInfoRow('Ocorrências', point.occurrences.length.toString()),
                    if (point.occurrences.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Ocorrências:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      ...point.occurrences.map((occurrence) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            Icon(
                              _getOccurrenceIcon(occurrence.type),
                              size: 16,
                              color: _getOccurrenceColor(occurrence.type),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${occurrence.name} (${occurrence.infestationIndex.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói ações
  Widget _buildActions() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createNewMonitoring,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Monitoramento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showMonitoringDetails,
                    icon: const Icon(Icons.info),
                    label: const Text('Detalhes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém ícone da ocorrência
  IconData _getOccurrenceIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.medical_services;
      case OccurrenceType.weed:
        return Icons.local_florist;
      case OccurrenceType.deficiency:
        return Icons.warning;
    }
  }

  /// Obtém cor da ocorrência
  Color _getOccurrenceColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.red;
      case OccurrenceType.disease:
        return Colors.orange;
      case OccurrenceType.weed:
        return Colors.green;
      case OccurrenceType.deficiency:
        return Colors.blue;
    }
  }

  /// Cria novo monitoramento
  void _createNewMonitoring() {
    _createExampleMonitoring();
    setState(() {});
    _showSuccessMessage('Novo monitoramento criado!');
  }

  /// Mostra detalhes do monitoramento
  void _showMonitoringDetails() {
    if (_currentMonitoring == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Monitoramento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('ID', _currentMonitoring!.id),
              _buildInfoRow('Talhão', _currentMonitoring!.plotName),
              _buildInfoRow('Cultura', _currentMonitoring!.cropName),
              _buildInfoRow('Data', _currentMonitoring!.date.toString()),
              _buildInfoRow('Pontos', _currentMonitoring!.points.length.toString()),
              _buildInfoRow('Ocorrências', 
                _currentMonitoring!.points.fold(0, (sum, point) => sum + point.occurrences.length).toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
