import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';

/// Widget para gráfico de pizza da distribuição de compactação
class SoilCompactionPieChart extends StatelessWidget {
  final Map<String, int> distribuicaoNiveis;
  final double size;
  final bool showLegend;
  final bool showCenterText;

  const SoilCompactionPieChart({
    Key? key,
    required this.distribuicaoNiveis,
    this.size = 200,
    this.showLegend = true,
    this.showCenterText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = distribuicaoNiveis.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: const Center(
          child: Text(
            'Sem dados',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gráfico de pizza
        SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: showCenterText ? size * 0.3 : 0,
              sections: _getSections(),
            ),
          ),
        ),
        
        if (showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ],
    );
  }

  List<PieChartSectionData> _getSections() {
    final total = distribuicaoNiveis.values.fold(0, (sum, count) => sum + count);
    final sections = <PieChartSectionData>[];

    // Ordem das cores: Verde -> Amarelo -> Laranja -> Vermelho
    final cores = [
      Colors.green,
      Colors.yellow[700]!,
      Colors.orange,
      Colors.red,
    ];

    final labels = [
      'Solo Solto',
      'Moderado',
      'Alto',
      'Crítico',
    ];

    int index = 0;
    distribuicaoNiveis.forEach((nivel, quantidade) {
      if (quantidade > 0) {
        final porcentagem = (quantidade / total) * 100;
        
        sections.add(
          PieChartSectionData(
            color: cores[index % cores.length],
            value: quantidade.toDouble(),
            title: '${porcentagem.toStringAsFixed(1)}%',
            radius: size * 0.4,
            titleStyle: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.6,
          ),
        );
        index++;
      }
    });

    return sections;
  }

  Widget _buildLegend() {
    final cores = [
      Colors.green,
      Colors.yellow[700]!,
      Colors.orange,
      Colors.red,
    ];

    final labels = [
      'Solo Solto',
      'Moderado',
      'Alto',
      'Crítico',
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(4, (index) {
        final nivel = labels[index];
        final quantidade = distribuicaoNiveis[nivel] ?? 0;
        
        if (quantidade == 0) return const SizedBox.shrink();
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: cores[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$nivel ($quantidade)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}

/// Widget para gráfico de barras da evolução temporal
class SoilCompactionBarChart extends StatelessWidget {
  final Map<String, double> dadosEvolucao;
  final double height;
  final bool showValues;

  const SoilCompactionBarChart({
    Key? key,
    required this.dadosEvolucao,
    this.height = 200,
    this.showValues = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dadosEvolucao.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Sem dados de evolução',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: BarChart(
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
                  final index = value.toInt();
                  if (index >= 0 && index < dadosEvolucao.keys.length) {
                    return Text(
                      dadosEvolucao.keys.elementAt(index),
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
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return dadosEvolucao.entries.map((entry) {
      final index = dadosEvolucao.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _getColorForValue(entry.value),
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

  double _getMaxValue() {
    return dadosEvolucao.values.fold(0.0, (max, value) => value > max ? value : max);
  }

  Color _getColorForValue(double value) {
    if (value < 1.5) return Colors.green;
    if (value < 2.0) return Colors.yellow[700]!;
    if (value < 2.5) return Colors.orange;
    return Colors.red;
  }
}

/// Widget para gráfico de linha da evolução temporal
class SoilCompactionLineChart extends StatelessWidget {
  final Map<String, double> dadosEvolucao;
  final double height;
  final bool showPoints;
  final bool showGrid;

  const SoilCompactionLineChart({
    Key? key,
    required this.dadosEvolucao,
    this.height = 200,
    this.showPoints = true,
    this.showGrid = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dadosEvolucao.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Sem dados de evolução',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: showGrid,
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
                  final index = value.toInt();
                  if (index >= 0 && index < dadosEvolucao.keys.length) {
                    return Text(
                      dadosEvolucao.keys.elementAt(index),
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
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots(),
              isCurved: true,
              color: AppColors.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showPoints,
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
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return dadosEvolucao.entries.map((entry) {
      final index = dadosEvolucao.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value);
    }).toList();
  }
}
