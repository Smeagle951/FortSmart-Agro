import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/experiment.dart';
import '../../models/planting.dart';
import '../../repositories/experiment_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_dialog.dart';

class ExperimentDetailsScreen extends StatefulWidget {
  final String experimentId;
  
  const ExperimentDetailsScreen({
    Key? key,
    required this.experimentId,
  }) : super(key: key);

  @override
  _ExperimentDetailsScreenState createState() => _ExperimentDetailsScreenState();
}

class _ExperimentDetailsScreenState extends State<ExperimentDetailsScreen> {
  final ExperimentRepository _experimentRepository = ExperimentRepository();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Experiment? _experiment;
  List<dynamic> _results = [];
  
  @override
  void initState() {
    super.initState();
    _loadExperimentDetails();
  }
  
  Future<void> _loadExperimentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Carregar dados do experimento
      final experiment = await _experimentRepository.getExperimentById(widget.experimentId);
      
      // Carregar resultados parciais/finais
      final results = await _experimentRepository.getExperimentResults(widget.experimentId);
      
      setState(() {
        _experiment = experiment;
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do experimento: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Experimento'),
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? LoadingIndicator(message: 'Carregando detalhes do experimento...')
          : _errorMessage.isNotEmpty
              ? ErrorDialog(
                  message: _errorMessage,
                  onRetry: _loadExperimentDetails,
                )
              : _buildExperimentDetails(),
    );
  }
  
  Widget _buildExperimentDetails() {
    if (_experiment == null) {
      return Center(
        child: Text(
          'Experimento não encontrado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A4F3D).withOpacity(0.8),
            const Color(0xFF1A2A20).withOpacity(0.9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            _buildExperimentHeader(),
            
            // Detalhes do experimento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 16),
                  _buildProgressCard(),
                  SizedBox(height: 16),
                  _buildResultsCard(),
                  SizedBox(height: 16),
                  _buildComparisonChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExperimentHeader() {
    // Calcular status
    final startDate = _experiment!.startDate;
    final endDate = _experiment!.endDate;
    final now = DateTime.now();
    
    Color statusColor;
    String statusText;
    double progress = 0.0;
    
    if (now.isBefore(startDate)) {
      statusColor = Colors.blue;
      statusText = 'Planejado';
      progress = 0.0;
    } else if (now.isAfter(endDate)) {
      statusColor = Colors.green;
      statusText = 'Concluído';
      progress = 1.0;
    } else {
      statusColor = Colors.orange;
      statusText = 'Em Andamento';
      
      // Calcular progresso
      final totalDuration = endDate.difference(startDate).inDays;
      final elapsedDuration = now.difference(startDate).inDays;
      progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 76,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Text(
                'DAE: ${_experiment!.dae} dias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _experiment!.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cultura: ${_experiment!.cropType} - Variedade: ${_experiment!.cropVariety}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% concluído',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return _buildGlassmorphicCard(
      title: 'Informações do Experimento',
      child: Column(
        children: [
          _buildInfoRow('Nome', _experiment!.name),
          Divider(color: Colors.white24),
          _buildInfoRow('Cultura', _experiment!.cropType),
          Divider(color: Colors.white24),
          _buildInfoRow('Variedade', _experiment!.cropVariety),
          Divider(color: Colors.white24),
          _buildInfoRow('Talhão', _experiment!.plotName),
          Divider(color: Colors.white24),
          _buildInfoRow('Área', '${_experiment!.area.toStringAsFixed(2)} hectares'),
          Divider(color: Colors.white24),
          _buildInfoRow('Data de Início', DateFormat('dd/MM/yyyy').format(_experiment!.startDate)),
          Divider(color: Colors.white24),
          _buildInfoRow('Data de Término', DateFormat('dd/MM/yyyy').format(_experiment!.endDate)),
          if (_experiment!.description != null && _experiment!.description!.isNotEmpty) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Descrição', _experiment!.description!),
          ],
          if (_experiment!.treatments != null && _experiment!.treatments!.isNotEmpty) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Tratamentos', _experiment!.treatments!.join(', ')),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressCard() {
    final currentDAE = _experiment!.dae;
    final idealDAE = _experiment!.idealDAE ?? 90;  // Valor padrão se não estiver definido
    final progress = (currentDAE / idealDAE * 100).clamp(0.0, 100.0);
    
    return _buildGlassmorphicCard(
      title: 'Progresso do Experimento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAE Atual: $currentDAE dias',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                'Ciclo Total: $idealDAE dias',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF9C27B0),
              ),
              minHeight: 10,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${progress.toStringAsFixed(1)}% do ciclo completo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Linha do Tempo do Experimento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          _buildTimeline(),
        ],
      ),
    );
  }
  
  Widget _buildTimeline() {
    final startDate = _experiment!.startDate;
    final endDate = _experiment!.endDate;
    final now = DateTime.now();
    
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays.clamp(0, totalDuration);
    final progress = elapsedDuration / totalDuration;
    
    // Criar marcadores de tempo
    final quarter = totalDuration ~/ 4;
    final timeMarkers = [
      startDate,
      startDate.add(Duration(days: quarter)),
      startDate.add(Duration(days: quarter * 2)),
      startDate.add(Duration(days: quarter * 3)),
      endDate,
    ];
    
    return Column(
      children: [
        // Linha do tempo
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.7 * progress,
                decoration: BoxDecoration(
                  color: Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        
        // Marcadores
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: timeMarkers.map((date) {
              return Text(
                DateFormat('dd/MM').format(date),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              );
            }).toList(),
          ),
        ),
        
        // Etapas principais
        SizedBox(height: 16),
        Row(
          children: [
            _buildTimelineStage(
              title: 'Início',
              description: 'Plantio e preparação',
              isDone: elapsedDuration >= 1,
              isActive: elapsedDuration < quarter,
            ),
            _buildTimelineStage(
              title: 'Estágio 1',
              description: 'Desenvolvimento inicial',
              isDone: elapsedDuration >= quarter,
              isActive: elapsedDuration >= quarter && elapsedDuration < quarter * 2,
            ),
            _buildTimelineStage(
              title: 'Estágio 2',
              description: 'Crescimento',
              isDone: elapsedDuration >= quarter * 2,
              isActive: elapsedDuration >= quarter * 2 && elapsedDuration < quarter * 3,
            ),
            _buildTimelineStage(
              title: 'Estágio 3',
              description: 'Maturação',
              isDone: elapsedDuration >= quarter * 3,
              isActive: elapsedDuration >= quarter * 3 && elapsedDuration < totalDuration,
            ),
            _buildTimelineStage(
              title: 'Conclusão',
              description: 'Colheita e análise',
              isDone: elapsedDuration >= totalDuration,
              isActive: elapsedDuration >= totalDuration,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTimelineStage({
    required String title,
    required String description,
    required bool isDone,
    required bool isActive,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone
                  ? Color(0xFF9C27B0)
                  : isActive
                      ? Color(0xFF9C27B0).withOpacity(0.3)
                      : Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone || isActive ? Color(0xFF9C27B0) : Colors.white24,
                width: 2,
              ),
            ),
            child: isDone
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDone || isActive ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsCard() {
    if (_results.isEmpty) {
      return _buildGlassmorphicCard(
        title: 'Resultados Parciais',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum resultado registrado ainda',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return _buildGlassmorphicCard(
      title: 'Resultados Parciais',
      child: Column(
        children: List.generate(_results.length, (index) {
          final result = _results[index];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0)
                Divider(color: Colors.white24),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  result['title'] ?? 'Resultado ${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result['date'] != null)
                      Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(result['date']))}',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      result['description'] ?? 'Sem descrição',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                trailing: result['value'] != null
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF9C27B0).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFF9C27B0).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          result['value'].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildComparisonChart() {
    // Se não tivermos resultados suficientes, mostrar mensagem
    if (_results.length < 2) {
      return _buildGlassmorphicCard(
        title: 'Comparação de Tratamentos',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Dados insuficientes para comparação',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Extrair tratamentos para comparação
    final treatments = _experiment!.treatments ?? ['Controle', 'Tratamento'];
    
    // Dados simulados para o gráfico
    final controlData = [4.5, 5.2, 7.8, 9.2, 10.5];
    final treatmentData = [4.2, 6.1, 8.5, 11.0, 13.2];
    
    return _buildGlassmorphicCard(
      title: 'Comparação de Tratamentos',
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white24,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < 5) {
                      final labels = ['10 DAE', '20 DAE', '30 DAE', '40 DAE', '50 DAE'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
                left: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            minX: 0,
            maxX: 4,
            minY: 0,
            maxY: 15,
            lineBarsData: [
              // Linha para o controle
              LineChartBarData(
                spots: List.generate(5, (index) {
                  return FlSpot(index.toDouble(), controlData[index]);
                }),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              
              // Linha para o tratamento
              LineChartBarData(
                spots: List.generate(5, (index) {
                  return FlSpot(index.toDouble(), treatmentData[index]);
                }),
                isCurved: true,
                color: Color(0xFF9C27B0),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Color(0xFF9C27B0),
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Color(0xFF9C27B0).withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassmorphicCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
