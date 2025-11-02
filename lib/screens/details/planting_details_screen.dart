import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/planting.dart';
import '../../models/planting_progress.dart';
import '../../repositories/planting_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_dialog.dart';

class PlantingDetailsScreen extends StatefulWidget {
  final String plantingId;
  
  const PlantingDetailsScreen({
    Key? key,
    required this.plantingId,
  }) : super(key: key);

  @override
  _PlantingDetailsScreenState createState() => _PlantingDetailsScreenState();
}

class _PlantingDetailsScreenState extends State<PlantingDetailsScreen> {
  final PlantingRepository _plantingRepository = PlantingRepository();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Planting? _planting;
  List<PlantingProgress> _progressHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadPlantingDetails();
  }
  
  Future<void> _loadPlantingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Carregar dados do plantio
      final planting = await _plantingRepository.getPlantingById(widget.plantingId);
      
      // Carregar histórico de progresso (DAE)
      final progressHistory = await _plantingRepository.getPlantingProgressHistory(widget.plantingId);
      
      setState(() {
        _planting = planting;
        _progressHistory = progressHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do plantio: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Plantio'),
        backgroundColor: const Color(0xFF2A4F3D),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? LoadingIndicator(message: 'Carregando detalhes do plantio...')
          : _errorMessage.isNotEmpty
              ? ErrorDialog(
                  message: _errorMessage,
                  onRetry: _loadPlantingDetails,
                )
              : _buildPlantingDetails(),
    );
  }
  
  Widget _buildPlantingDetails() {
    if (_planting == null) {
      return Center(
        child: Text(
          'Plantio não encontrado',
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
            _buildPlantingHeader(),
            
            // Detalhes do plantio
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 16),
                  _buildProgressCard(),
                  SizedBox(height: 16),
                  _buildDAEChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlantingHeader() {
    // Calcular status do DAE
    final currentDAE = _planting!.currentDAE ?? 0;
    final idealDAE = _planting!.idealDAE ?? 90;  // Valor padrão se não estiver definido
    final progress = (currentDAE / idealDAE * 100).clamp(0.0, 100.0);
    
    Color statusColor;
    String statusText;
    
    if (progress >= 90) {
      statusColor = Colors.green;
      statusText = 'Ciclo Quase Completo';
    } else if (progress >= 50) {
      statusColor = Colors.orange;
      statusText = 'Meia Estação';
    } else {
      statusColor = Colors.blue;
      statusText = 'Início do Ciclo';
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
                'DAE: $currentDAE dias',
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
            _planting!.cropType,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Variedade: ${_planting!.cropVariety}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Talhão: ${_planting!.plotName}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return _buildGlassmorphicCard(
      title: 'Informações do Plantio',
      child: Column(
        children: [
          _buildInfoRow('Cultura', _planting!.cropType),
          Divider(color: Colors.white24),
          _buildInfoRow('Variedade', _planting!.cropVariety),
          Divider(color: Colors.white24),
          _buildInfoRow('Talhão', _planting!.plotName),
          Divider(color: Colors.white24),
          _buildInfoRow('Data de Plantio', 
              DateFormat('dd/MM/yyyy').format(_planting!.plantingDate)),
          Divider(color: Colors.white24),
          _buildInfoRow('Área Plantada', '${_planting!.area.toStringAsFixed(2)} hectares'),
          if (_planting!.harvestDate != null) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Previsão de Colheita', 
                DateFormat('dd/MM/yyyy').format(_planting!.harvestDate!)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
    final currentDAE = _planting!.currentDAE ?? 0;
    final idealDAE = _planting!.idealDAE ?? 90;  // Valor padrão se não estiver definido
    final progress = (currentDAE / idealDAE * 100).clamp(0.0, 100.0);
    
    return _buildGlassmorphicCard(
      title: 'Progresso do Ciclo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dia Atual: $currentDAE',
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
              // backgroundColor: Colors.white24, // backgroundColor não é suportado em flutter_map 5.0.0
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF00FF66),
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
            'Informações de Crescimento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildGrowthStageItem(
                icon: Icons.grass,
                title: 'Vegetativo',
                isActive: currentDAE <= idealDAE * 0.3,
              ),
              SizedBox(width: 8),
              _buildGrowthStageItem(
                icon: Icons.spa,
                title: 'Floração',
                isActive: currentDAE > idealDAE * 0.3 && currentDAE <= idealDAE * 0.6,
              ),
              SizedBox(width: 8),
              _buildGrowthStageItem(
                icon: Icons.grain,
                title: 'Enchimento',
                isActive: currentDAE > idealDAE * 0.6 && currentDAE <= idealDAE * 0.9,
              ),
              SizedBox(width: 8),
              _buildGrowthStageItem(
                icon: Icons.agriculture,
                title: 'Maturação',
                isActive: currentDAE > idealDAE * 0.9,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGrowthStageItem({
    required IconData icon,
    required String title,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive 
              ? Color(0xFF00FF66).withOpacity(0.3) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? Color(0xFF00FF66) 
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF00FF66) : Colors.white38,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDAEChart() {
    // Se não tivermos histórico suficiente, mostrar mensagem
    if (_progressHistory.length < 2) {
      return _buildGlassmorphicCard(
        title: 'Evolução do DAE',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Histórico insuficiente para gerar gráfico',
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
    
    // Ordenar histórico por data
    _progressHistory.sort((a, b) => a.date.compareTo(b.date));
    
    return _buildGlassmorphicCard(
      title: 'Evolução do DAE',
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
                    if (value.toInt() >= 0 && value.toInt() < _progressHistory.length) {
                      final date = _progressHistory[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('dd/MM').format(date),
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
            maxX: (_progressHistory.length - 1).toDouble(),
            minY: 0,
            maxY: _progressHistory.map((p) => p.dae).reduce((a, b) => a > b ? a : b).toDouble() + 5,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(_progressHistory.length, (index) {
                  return FlSpot(index.toDouble(), _progressHistory[index].dae.toDouble());
                }),
                isCurved: true,
                color: Color(0xFF00FF66),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Color(0xFF00FF66),
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Color(0xFF00FF66).withOpacity(0.2),
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
