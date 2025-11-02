import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/penetrometro_reading_model.dart';
import '../constants/app_colors.dart';

/// Widget de gráfico para leituras do penetrômetro
class PenetrometroChartWidget extends StatefulWidget {
  final List<PenetrometroReading> readings;
  final bool showRealTime;
  final double height;
  final ChartType chartType;

  const PenetrometroChartWidget({
    Key? key,
    required this.readings,
    this.showRealTime = false,
    this.height = 300,
    this.chartType = ChartType.line,
  }) : super(key: key);

  @override
  State<PenetrometroChartWidget> createState() => _PenetrometroChartWidgetState();
}

enum ChartType { line, bar, scatter }

class _PenetrometroChartWidgetState extends State<PenetrometroChartWidget> {
  int _selectedChartType = 0;
  bool _showResistencia = true;
  bool _showProfundidade = false;

  @override
  Widget build(BuildContext context) {
    if (widget.readings.isEmpty) {
      return _buildEmptyChart();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildChartControls(),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: _buildChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        height: widget.height,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhuma leitura disponível',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Conecte o penetrômetro para ver os dados',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Row(
      children: [
        // Seletor de tipo de gráfico
        Expanded(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Linha')),
              ButtonSegment(value: 1, label: Text('Barras')),
              ButtonSegment(value: 2, label: Text('Pontos')),
            ],
            selected: {_selectedChartType},
            onSelectionChanged: (Set<int> selection) {
              setState(() {
                _selectedChartType = selection.first;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        
        // Checkboxes para dados
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _showResistencia,
                onChanged: (value) {
                  setState(() {
                    _showResistencia = value ?? false;
                  });
                },
              ),
              const Text('Resistência'),
              const SizedBox(width: 16),
              Checkbox(
                value: _showProfundidade,
                onChanged: (value) {
                  setState(() {
                    _showProfundidade = value ?? false;
                  });
                },
              ),
              const Text('Profundidade'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    switch (_selectedChartType) {
      case 0:
        return _buildLineChart();
      case 1:
        return _buildBarChart();
      case 2:
        return _buildScatterChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.readings.length) {
                  return Text(
                    '${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10),
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
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        lineBarsData: _getLineBarsData(),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue() * 1.2,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.readings.length) {
                  return Text(
                    '${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10),
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
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildScatterChart() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: _getScatterSpots(),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.5,
          verticalInterval: 0.5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<LineChartBarData> _getLineBarsData() {
    final lineBars = <LineChartBarData>[];

    if (_showResistencia) {
      lineBars.add(
        LineChartBarData(
          spots: widget.readings.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.resistenciaMpa);
          }).toList(),
          isCurved: true,
          color: AppColors.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
        ),
      );
    }

    if (_showProfundidade) {
      lineBars.add(
        LineChartBarData(
          spots: widget.readings.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.profundidadeCm);
          }).toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      );
    }

    return lineBars;
  }

  List<BarChartGroupData> _getBarGroups() {
    return widget.readings.asMap().entries.map((entry) {
      final index = entry.key;
      final reading = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          if (_showResistencia)
            BarChartRodData(
              toY: reading.resistenciaMpa,
              color: AppColors.primaryColor,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          if (_showProfundidade)
            BarChartRodData(
              toY: reading.profundidadeCm,
              color: Colors.orange,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
        ],
      );
    }).toList();
  }

  List<ScatterSpot> _getScatterSpots() {
    return widget.readings.asMap().entries.map((entry) {
      final index = entry.key;
      final reading = entry.value;
      
      return ScatterSpot(
        reading.resistenciaMpa,
        reading.profundidadeCm,
      );
    }).toList();
  }

  double _getMaxValue() {
    double max = 0;
    for (final reading in widget.readings) {
      if (_showResistencia) {
        max = max > reading.resistenciaMpa ? max : reading.resistenciaMpa;
      }
      if (_showProfundidade) {
        max = max > reading.profundidadeCm ? max : reading.profundidadeCm;
      }
    }
    return max;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_showResistencia) ...[
          Container(
            width: 16,
            height: 16,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Resistência (MPa)'),
          const SizedBox(width: 16),
        ],
        if (_showProfundidade) ...[
          Container(
            width: 16,
            height: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          const Text('Profundidade (cm)'),
        ],
      ],
    );
  }
}
