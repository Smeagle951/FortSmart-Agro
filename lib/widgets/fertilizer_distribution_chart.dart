import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fertilizer_calibration.dart';

/// Widget para exibir o gráfico de distribuição de fertilizantes
class FertilizerDistributionChart extends StatelessWidget {
  final FertilizerCalibration calibration;
  final double height;
  final bool showLegend;

  const FertilizerDistributionChart({
    super.key,
    required this.calibration,
    this.height = 300,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    if (calibration.weights.isEmpty) {
          return SizedBox(
      height: height,
      child: const Center(
        child: Text(
          'Nenhum dado disponível para o gráfico',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (showLegend) _buildLegend(),
          const SizedBox(height: 16),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  /// Constrói a legenda do gráfico
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem('Dentro da Faixa', const Color(0xFF4CAF50)),
          _buildLegendItem('Fora da Faixa', const Color(0xFFF44336)),
          _buildLegendItem('Média', const Color(0xFF2E7D32)),
          _buildLegendItem('Limite 50%', const Color(0xFFFF9800)),
          _buildLegendItem('Taxa Desejada', const Color(0xFF1976D2)),
        ],
      ),
    );
  }

  /// Constrói um item da legenda
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Constrói o gráfico
  Widget _buildChart() {
    final barGroups = _createBarGroups();
    final averageLine = _createAverageLine();
    final limitLine = _createLimitLine();
    final desiredRateLine = _createDesiredRateLine();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        minY: 0,
        groupsSpace: 12, // Espaçamento aumentado entre barras
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.95),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final weight = calibration.weights[group.x.toInt()];
              final trayNumber = group.x.toInt() + 1;
              final isInRange = calibration.effectiveRangeIndices.contains(group.x.toInt());
              final desiredRateGrams = _convertDesiredRateToGrams();
              final deviation = desiredRateGrams > 0 ? ((weight - desiredRateGrams) / desiredRateGrams * 100) : 0.0;
              
              return BarTooltipItem(
                'Bandeja $trayNumber\n${weight.toStringAsFixed(1)} g\n${isInRange ? "Dentro da faixa" : "Fora da faixa"}\nDesvio: ${deviation.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Mostrar apenas algumas bandejas para não sobrecarregar
                if (value.toInt() % 2 == 0 || value.toInt() == calibration.weights.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt() + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 35,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 45,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          horizontalInterval: _getGridInterval(),
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [averageLine, limitLine, desiredRateLine],
        ),
      ),
    );
  }

  /// Cria os grupos de barras
  List<BarChartGroupData> _createBarGroups() {
    final centerAvg = _getCenterAverage();
    final limit = centerAvg * 0.5;

    return calibration.weights.asMap().entries.map((entry) {
      final index = entry.key;
      final weight = entry.value;
      final isInEffectiveRange = calibration.effectiveRangeIndices.contains(index);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weight,
            color: isInEffectiveRange 
                ? const Color(0xFF4CAF50) // Verde profissional para dentro da faixa
                : const Color(0xFFF44336), // Vermelho profissional para fora da faixa
            width: 16, // Largura aumentada para melhor visualização
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: centerAvg,
              color: Colors.grey[50]!,
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Cria a linha da média central
  HorizontalLine _createAverageLine() {
    final centerAvg = _getCenterAverage();
    
    return HorizontalLine(
      y: centerAvg,
      color: const Color(0xFF2E7D32), // Verde mais profissional
      strokeWidth: 3,
      dashArray: [5, 5], // Linha tracejada
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(right: 8, top: 4),
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        labelResolver: (line) => 'Média: ${centerAvg.toStringAsFixed(1)}g',
      ),
    );
  }

  /// Cria a linha do limite de 50%
  HorizontalLine _createLimitLine() {
    final centerAvg = _getCenterAverage();
    final limit = centerAvg * 0.5;
    
    return HorizontalLine(
      y: limit,
      color: const Color(0xFFFF9800), // Laranja mais profissional
      strokeWidth: 2,
      dashArray: [8, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 8, top: 4),
        style: const TextStyle(
          color: Color(0xFFFF9800),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        labelResolver: (line) => 'Limite: ${limit.toStringAsFixed(1)}g',
      ),
    );
  }

  /// Cria a linha da taxa desejada (convertida para gramas)
  HorizontalLine _createDesiredRateLine() {
    // Converter taxa desejada (kg/ha) para gramas por bandeja
    final desiredRateGrams = _convertDesiredRateToGrams();
    
    return HorizontalLine(
      y: desiredRateGrams,
      color: const Color(0xFF1976D2), // Azul profissional
      strokeWidth: 3,
      dashArray: [10, 5],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 4),
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        labelResolver: (line) => 'Desejada: ${desiredRateGrams.toStringAsFixed(1)}g',
      ),
    );
  }

  /// Converte taxa desejada (kg/ha) para gramas por bandeja
  double _convertDesiredRateToGrams() {
    if (calibration.distanceTraveled == null || calibration.distanceTraveled! <= 0) {
      return 0.0;
    }
    
    // Fórmula inversa: Taxa (kg/ha) = (Massa Total (g) × 10) / (N × Largura Bandeja (m) × Distância (m))
    // Massa por bandeja = (Taxa (kg/ha) × N × Largura Bandeja (m) × Distância (m)) / (10 × N)
    final bandejaWidth = 0.5; // m
    final numBandejas = calibration.weights.length;
    
    final massaPorBandeja = (calibration.desiredRate * bandejaWidth * calibration.distanceTraveled!) / 10.0;
    
    return massaPorBandeja;
  }

  /// Calcula a média central (3 bandejas do centro)
  double _getCenterAverage() {
    if (calibration.weights.length < 3) return 0.0;
    
    final center = calibration.weights.length ~/ 2;
    return (calibration.weights[center - 1] + 
            calibration.weights[center] + 
            calibration.weights[center + 1]) / 3;
  }

  /// Calcula o valor máximo do eixo Y
  double _getMaxY() {
    if (calibration.weights.isEmpty) return 100;
    
    final maxWeight = calibration.weights.reduce((a, b) => a > b ? a : b);
    final centerAvg = _getCenterAverage();
    final maxValue = maxWeight > centerAvg * 1.5 ? maxWeight : centerAvg * 1.5;
    
    return (maxValue * 1.1).ceilToDouble(); // 10% de margem
  }

  /// Calcula o intervalo da grade
  double _getGridInterval() {
    final maxY = _getMaxY();
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    return 100;
  }
} 