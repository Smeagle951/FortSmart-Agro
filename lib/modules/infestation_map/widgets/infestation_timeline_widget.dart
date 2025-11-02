import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/infestation_timeline_model.dart';
import '../services/infestation_timeline_service.dart';
import '../../../utils/logger.dart';

/// Widget para exibir timeline de infestação com gráfico
class InfestationTimelineWidget extends StatefulWidget {
  final String talhaoId;
  final String organismoId;
  final InfestationTimelineService timelineService;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  const InfestationTimelineWidget({
    Key? key,
    required this.talhaoId,
    required this.organismoId,
    required this.timelineService,
    this.dataInicio,
    this.dataFim,
  }) : super(key: key);

  @override
  State<InfestationTimelineWidget> createState() => _InfestationTimelineWidgetState();
}

class _InfestationTimelineWidgetState extends State<InfestationTimelineWidget> {
  List<InfestationTimelineModel> _timelineData = [];
  TendencyAnalysisResult? _tendencyAnalysis;
  TimelineChartData? _chartData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar dados da timeline
      final timelineData = await widget.timelineService.getTimeline(
        widget.talhaoId,
        widget.organismoId,
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
      );

      // Analisar tendência
      final tendencyAnalysis = await widget.timelineService.analyzeTendency(timelineData);

      // Gerar dados do gráfico
      final chartData = await widget.timelineService.generateChartData(timelineData);

      if (mounted) {
        setState(() {
          _timelineData = timelineData;
          _tendencyAnalysis = tendencyAnalysis;
          _chartData = chartData;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados da timeline: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar timeline',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTimelineData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_timelineData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timeline,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum dado disponível',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Não há registros de infestação para este talhão e organismo no período selecionado.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTendencyCard(),
          const SizedBox(height: 16),
          _buildChartCard(),
          const SizedBox(height: 16),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Timeline de Infestação',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Talhão: ${widget.talhaoId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Organismo: ${widget.organismoId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Período: ${_formatDateRange()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Total de registros: ${_timelineData.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendencyCard() {
    if (_tendencyAnalysis == null) return const SizedBox.shrink();

    final analysis = _tendencyAnalysis!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTendencyIcon(analysis.tendencia),
                  color: _getTendencyColor(analysis.tendencia),
                ),
                const SizedBox(width: 8),
                Text(
                  'Análise de Tendência',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTendencyInfo('Tendência', _formatTendency(analysis.tendencia)),
            _buildTendencyInfo('Confiabilidade', analysis.confiabilidade),
            _buildTendencyInfo('R²', '${(analysis.rQuadrado * 100).toStringAsFixed(1)}%'),
            _buildTendencyInfo('Período', '${analysis.periodoDias.toStringAsFixed(0)} dias'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recomendação:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.recomendacao,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendencyInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    if (_chartData == null || _chartData!.datas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Evolução Temporal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _chartData!.datas.length) {
                            final date = _chartData!.datas[value.toInt()];
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData!.datas.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.percentual);
                      }).toList(),
                      isCurved: true,
                      color: Color(int.parse(_chartData!.corTendencia.replaceAll('#', '0xFF'))),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(int.parse(_chartData!.corTendencia.replaceAll('#', '0xFF')))
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Dados Detalhados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Quantidade')),
                  DataColumn(label: Text('Nível')),
                  DataColumn(label: Text('Percentual')),
                ],
                rows: _timelineData.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(entry.dataOcorrencia))),
                      DataCell(Text('${entry.quantidade}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(int.parse(entry.nivelColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(int.parse(entry.nivelColor.replaceAll('#', '0xFF'))),
                            ),
                          ),
                          child: Text(
                            entry.nivel,
                            style: TextStyle(
                              color: Color(int.parse(entry.nivelColor.replaceAll('#', '0xFF'))),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${entry.percentual.toStringAsFixed(1)}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (_timelineData.isEmpty) return 'N/A';
    
    final datas = _timelineData.map((e) => e.dataOcorrencia).toList();
    datas.sort();
    
    final inicio = datas.first;
    final fim = datas.last;
    
    return '${_formatDate(inicio)} - ${_formatDate(fim)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTendency(String tendencia) {
    switch (tendencia) {
      case 'CRESCENTE_FORTE':
        return 'Crescimento Forte';
      case 'CRESCENTE_SUAVE':
        return 'Crescimento Suave';
      case 'DECRESCENTE_FORTE':
        return 'Redução Forte';
      case 'DECRESCENTE_SUAVE':
        return 'Redução Suave';
      case 'ESTAVEL':
        return 'Estável';
      case 'INSUFICIENTE_DADOS':
        return 'Dados Insuficientes';
      default:
        return tendencia;
    }
  }

  IconData _getTendencyIcon(String tendencia) {
    switch (tendencia) {
      case 'CRESCENTE_FORTE':
      case 'CRESCENTE_SUAVE':
        return Icons.trending_up;
      case 'DECRESCENTE_FORTE':
      case 'DECRESCENTE_SUAVE':
        return Icons.trending_down;
      case 'ESTAVEL':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTendencyColor(String tendencia) {
    switch (tendencia) {
      case 'CRESCENTE_FORTE':
        return Colors.red;
      case 'CRESCENTE_SUAVE':
        return Colors.orange;
      case 'DECRESCENTE_FORTE':
        return Colors.green;
      case 'DECRESCENTE_SUAVE':
        return Colors.lightGreen;
      case 'ESTAVEL':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
