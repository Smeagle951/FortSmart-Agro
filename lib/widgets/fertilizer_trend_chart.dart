import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fertilizer_calibration.dart';

/// Widget para gráfico de tendência temporal de calibrações
class FertilizerTrendChart extends StatelessWidget {
  final List<FertilizerCalibration> calibrations;
  final double height;
  final bool showCVTrend;
  final bool showRateTrend;

  const FertilizerTrendChart({
    super.key,
    required this.calibrations,
    this.height = 300,
    this.showCVTrend = true,
    this.showRateTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    if (calibrations.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Nenhum histórico disponível',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Realize mais calibrações para ver a tendência',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.timeline,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tendência Temporal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${calibrations.length} calibração(ões) registrada(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        if (showRateTrend) ...[
          _buildLegendItem('Taxa Real', const Color(0xFF1976D2)),
          const SizedBox(width: 16),
        ],
        if (showCVTrend) ...[
          _buildLegendItem('CV%', const Color(0xFF4CAF50)),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: _getGridInterval(),
          verticalInterval: 1,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
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
                final index = value.toInt();
                if (index >= 0 && index < calibrations.length) {
                  final date = calibrations[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        lineBarsData: _createLineBarsData(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.95),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < calibrations.length) {
                  final calibration = calibrations[index];
                  final date = calibration.date;
                  
                  return LineTooltipItem(
                    '${date.day}/${date.month}/${date.year}\n'
                    'Taxa: ${calibration.realApplicationRate.toStringAsFixed(1)} kg/ha\n'
                    'CV: ${calibration.coefficientOfVariation.toStringAsFixed(1)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
        minX: 0,
        maxX: (calibrations.length - 1).toDouble(),
        minY: _getMinY(),
        maxY: _getMaxY(),
      ),
    );
  }

  List<LineChartBarData> _createLineBarsData() {
    final List<LineChartBarData> lineBars = [];

    if (showRateTrend) {
      lineBars.add(
        LineChartBarData(
          spots: _createRateSpots(),
          isCurved: true,
          color: const Color(0xFF1976D2),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF1976D2),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF1976D2).withOpacity(0.1),
          ),
        ),
      );
    }

    if (showCVTrend) {
      lineBars.add(
        LineChartBarData(
          spots: _createCVSpots(),
          isCurved: true,
          color: const Color(0xFF4CAF50),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF4CAF50),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF4CAF50).withOpacity(0.1),
          ),
        ),
      );
    }

    return lineBars;
  }

  List<FlSpot> _createRateSpots() {
    return calibrations.asMap().entries.map((entry) {
      final index = entry.key;
      final calibration = entry.value;
      return FlSpot(index.toDouble(), calibration.realApplicationRate);
    }).toList();
  }

  List<FlSpot> _createCVSpots() {
    return calibrations.asMap().entries.map((entry) {
      final index = entry.key;
      final calibration = entry.value;
      return FlSpot(index.toDouble(), calibration.coefficientOfVariation);
    }).toList();
  }

  double _getMinY() {
    if (calibrations.isEmpty) return 0;
    
    double minRate = calibrations.map((c) => c.realApplicationRate).reduce((a, b) => a < b ? a : b);
    double minCV = calibrations.map((c) => c.coefficientOfVariation).reduce((a, b) => a < b ? a : b);
    
    final minValue = showRateTrend && showCVTrend 
        ? (minRate < minCV ? minRate : minCV)
        : showRateTrend ? minRate : minCV;
    
    return (minValue * 0.8).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (calibrations.isEmpty) return 100;
    
    double maxRate = calibrations.map((c) => c.realApplicationRate).reduce((a, b) => a > b ? a : b);
    double maxCV = calibrations.map((c) => c.coefficientOfVariation).reduce((a, b) => a > b ? a : b);
    
    final maxValue = showRateTrend && showCVTrend 
        ? (maxRate > maxCV ? maxRate : maxCV)
        : showRateTrend ? maxRate : maxCV;
    
    return (maxValue * 1.2).ceilToDouble();
  }

  double _getGridInterval() {
    final maxY = _getMaxY();
    if (maxY <= 10) return 1;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    if (maxY <= 200) return 20;
    return 50;
  }
}

/// Widget para gráfico de tendência com múltiplas métricas
class MultiMetricTrendChart extends StatelessWidget {
  final List<FertilizerCalibration> calibrations;
  final double height;
  final List<TrendMetric> metrics;

  const MultiMetricTrendChart({
    super.key,
    required this.calibrations,
    required this.metrics,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (calibrations.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Nenhum histórico disponível',
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
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Análise Multimétrica',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      children: metrics.map((metric) => _buildLegendItem(metric.name, metric.color)).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          verticalInterval: 1,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < calibrations.length) {
                  final date = calibrations[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        lineBarsData: _createLineBarsData(),
        minX: 0,
        maxX: (calibrations.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
      ),
    );
  }

  List<LineChartBarData> _createLineBarsData() {
    return metrics.map((metric) {
      return LineChartBarData(
        spots: _createSpots(metric),
        isCurved: true,
        color: metric.color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: metric.color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      );
    }).toList();
  }

  List<FlSpot> _createSpots(TrendMetric metric) {
    return calibrations.asMap().entries.map((entry) {
      final index = entry.key;
      final calibration = entry.value;
      final value = metric.getValue(calibration);
      return FlSpot(index.toDouble(), value);
    }).toList();
  }
}

/// Classe para definir métricas de tendência
class TrendMetric {
  final String name;
  final Color color;
  final double Function(FertilizerCalibration) getValue;

  TrendMetric({
    required this.name,
    required this.color,
    required this.getValue,
  });
}

/// Métricas pré-definidas
class TrendMetrics {
  static final TrendMetric realRate = TrendMetric(
    name: 'Taxa Real',
    color: const Color(0xFF1976D2),
    getValue: (calibration) => calibration.realApplicationRate,
  );

  static final TrendMetric cv = TrendMetric(
    name: 'CV%',
    color: const Color(0xFF4CAF50),
    getValue: (calibration) => calibration.coefficientOfVariation,
  );

  static final TrendMetric error = TrendMetric(
    name: 'Erro %',
    color: const Color(0xFFF44336),
    getValue: (calibration) => calibration.errorPercentage.abs(),
  );

  static final TrendMetric realWidth = TrendMetric(
    name: 'Faixa Real',
    color: const Color(0xFFFF9800),
    getValue: (calibration) => calibration.realWidth,
  );
}
