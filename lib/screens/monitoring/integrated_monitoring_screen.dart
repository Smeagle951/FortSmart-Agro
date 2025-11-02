import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/occurrence_input_widget.dart';
import '../../widgets/thermal_infestation_map.dart';
import '../../services/integrated_monitoring_service.dart';
import '../../utils/logger.dart';

/// Tela integrada de monitoramento que combina entrada de ocorrências e mapa de infestação
class IntegratedMonitoringScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;
  final String cropName;
  final List<LatLng> fieldPolygon;

  const IntegratedMonitoringScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
    required this.cropName,
    required this.fieldPolygon,
  }) : super(key: key);

  @override
  _IntegratedMonitoringScreenState createState() => _IntegratedMonitoringScreenState();
}

class _IntegratedMonitoringScreenState extends State<IntegratedMonitoringScreen> {
  final IntegratedMonitoringService _monitoringService = IntegratedMonitoringService();
  
  List<IntegratedMonitoringService.ProcessedOccurrence> _occurrences = [];
  List<Map<String, dynamic>> _historicalAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
    _listenToUpdates();
  }

  @override
  void dispose() {
    _monitoringService.dispose();
    super.dispose();
  }

  /// Carrega dados históricos
  Future<void> _loadHistoricalData() async {
    try {
      setState(() => _isLoading = true);
      
      // Carregar alertas históricos
      final alerts = await _monitoringService.generateHistoricalAlerts(widget.fieldId);
      
      setState(() {
        _historicalAlerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar dados históricos: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Escuta atualizações em tempo real
  void _listenToUpdates() {
    _monitoringService.updateStream.listen((update) {
      if (update.type == 'occurrence_added') {
        setState(() {
          // Atualizar lista de ocorrências se necessário
        });
      } else if (update.type == 'map_updated') {
        // Atualizar mapa se necessário
        setState(() {});
      }
    });
  }

  /// Callback quando uma ocorrência é adicionada
  void _onOccurrenceAdded(IntegratedMonitoringService.ProcessedOccurrence occurrence) {
    setState(() {
      _occurrences.add(occurrence);
    });
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(occurrence.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${occurrence.organismName} registrado: ${occurrence.normalizedPercentage.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        backgroundColor: _getAlertColor(occurrence.alertLevel),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Obtém cor do alerta
  Color _getAlertColor(String alertLevel) {
    switch (alertLevel) {
      case 'baixo':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      case 'critico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoramento - ${widget.fieldName}'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistoricalData,
            tooltip: 'Atualizar dados',
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showInfoDialog,
            tooltip: 'Informações',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Carregando dados de monitoramento...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Mapa de infestação
                  ThermalInfestationMap(
                    fieldId: widget.fieldId,
                    fieldPolygon: widget.fieldPolygon,
                    fieldName: widget.fieldName,
                    cropName: widget.cropName,
                    mapHeight: 300,
                    showLegend: true,
                    onOrganismTap: (organismId) {
                      _showOrganismDetails(organismId);
                    },
                  ),

                  // Widget de entrada de ocorrências
                  OccurrenceInputWidget(
                    cropName: widget.cropName,
                    fieldId: widget.fieldId,
                    historicalAlerts: _historicalAlerts,
                    onOccurrenceAdded: _onOccurrenceAdded,
                  ),

                  // Lista de ocorrências registradas nesta sessão
                  if (_occurrences.isNotEmpty)
                    _buildOccurrencesList(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Lista de ocorrências registradas
  Widget _buildOccurrencesList() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Ocorrências Registradas (${_occurrences.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _occurrences.length,
            itemBuilder: (context, index) {
              final occurrence = _occurrences[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getAlertColor(occurrence.alertLevel).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      occurrence.icon,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                title: Text(
                  occurrence.organismName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${occurrence.organismType} • ${occurrence.rawQuantity} ${occurrence.unit}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${occurrence.normalizedPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getAlertColor(occurrence.alertLevel),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getAlertColor(occurrence.alertLevel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        occurrence.alertLevel.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mostra detalhes de um organismo
  void _showOrganismDetails(String organismId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Organismo'),
        content: Text('Detalhes do organismo $organismId serão exibidos aqui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Mostra informações sobre o sistema
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Sistema Integrado de Monitoramento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como funciona:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• Digite o nome do organismo (ex: "bicudo")'),
            Text('• Informe a quantidade encontrada (ex: 20)'),
            Text('• O sistema identifica automaticamente no catálogo'),
            Text('• Calcula a porcentagem baseada nos limiares'),
            Text('• Atualiza o mapa de infestação em tempo real'),
            const SizedBox(height: 16),
            Text(
              'Cores do mapa:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text('Baixo (0-25%)'),
              ],
            ),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Médio (26-50%)'),
              ],
            ),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text('Alto (51-75%)'),
              ],
            ),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text('Crítico (76-100%)'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
