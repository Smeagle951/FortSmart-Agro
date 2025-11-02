import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:intl/intl.dart';

/// Widget para exibir gráficos relacionados ao estoque
class InventoryChart extends StatelessWidget {
  final List<InventoryMovement> movements;
  final double currentStock;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final ChartType chartType;

  const InventoryChart({
    Key? key,
    required this.movements,
    required this.currentStock,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.chartType = ChartType.stockLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case ChartType.stockLevel:
        return _buildStockLevelChart(context);
      case ChartType.movementsByType:
        return _buildMovementsByTypeChart(context);
      case ChartType.movementsByPurpose:
        return _buildMovementsByPurposeChart(context);
    }
  }

  /// Constrói um gráfico de linha mostrando o nível de estoque ao longo do tempo
  Widget _buildStockLevelChart(BuildContext context) {
    // Ordenar movimentos por data
    final sortedMovements = List<InventoryMovement>.from(movements)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calcular pontos do gráfico
    double runningTotal = currentStock;
    final List<FlSpot> spots = [];
    
    // Adicionar último ponto (estoque atual)
    final now = DateTime.now();
    spots.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), runningTotal));
    
    // Adicionar pontos históricos (retrocedendo no tempo)
    for (int i = sortedMovements.length - 1; i >= 0; i--) {
      final movement = sortedMovements[i];
      if (movement.type == MovementType.entry) {
        runningTotal -= movement.quantity;
      } else {
        runningTotal += movement.quantity;
      }
      spots.add(FlSpot(
        movement.date.millisecondsSinceEpoch.toDouble(),
        runningTotal,
      ));
    }
    
    // Inverter lista para mostrar do mais antigo para o mais recente
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Encontrar valores mínimos e máximos para o eixo Y
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (var spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    
    // Adicionar margem ao eixo Y
    minY = minY > 0 ? 0 : minY * 1.1;
    maxY = maxY * 1.1;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução do Estoque',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY - minY) / 5,
                    verticalInterval: 1,
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
                        reservedSize: 30,
                        interval: (endDate.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch) / 5,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxY - minY) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d)),
                  ),
                  minX: startDate.millisecondsSinceEpoch.toDouble(),
                  maxX: endDate.millisecondsSinceEpoch.toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: spots.length < 15, // Mostrar pontos apenas se houver poucos
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estoque atual: ${currentStock.toStringAsFixed(2)} $unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um gráfico de pizza mostrando a distribuição de movimentos por tipo (entrada/saída)
  Widget _buildMovementsByTypeChart(BuildContext context) {
    // Calcular totais
    double totalEntries = 0;
    double totalExits = 0;

    for (var movement in movements) {
      if (movement.type == MovementType.entry) {
        totalEntries += movement.quantity;
      } else {
        totalExits += movement.quantity;
      }
    }

    final total = totalEntries + totalExits;
    final entryPercentage = total > 0 ? (totalEntries / total * 100) : 0;
    final exitPercentage = total > 0 ? (totalExits / total * 100) : 0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimentações por Tipo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: totalEntries,
                            title: '${entryPercentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: totalExits,
                            title: '${exitPercentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        context, 
                        'Entradas', 
                        Colors.green, 
                        '${totalEntries.toStringAsFixed(2)} $unit'
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        context, 
                        'Saídas', 
                        Colors.red, 
                        '${totalExits.toStringAsFixed(2)} $unit'
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total movimentado: ${total.toStringAsFixed(2)} $unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um gráfico de barras mostrando a distribuição de movimentos por finalidade
  Widget _buildMovementsByPurposeChart(BuildContext context) {
    // Agrupar movimentos por finalidade
    final Map<String, double> purposeTotals = {};
    
    for (var movement in movements) {
      final purpose = movement.purpose.isEmpty ? 'Sem finalidade' : movement.purpose;
      purposeTotals[purpose] = (purposeTotals[purpose] ?? 0) + movement.quantity;
    }
    
    // Ordenar finalidades por valor total (decrescente)
    final sortedPurposes = purposeTotals.keys.toList()
      ..sort((a, b) => purposeTotals[b]!.compareTo(purposeTotals[a]!));
    
    // Limitar a 5 finalidades mais usadas para não sobrecarregar o gráfico
    final topPurposes = sortedPurposes.take(5).toList();
    
    // Cores para as barras
    final List<Color> barColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimentações por Finalidade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  // alignment: BarChartAlignment.spaceAround, // alignment não é suportado em Marker no flutter_map 5.0.0
                  maxY: purposeTotals.values.isEmpty 
                      ? 10 
                      : purposeTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey[800]!,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${topPurposes[groupIndex]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toStringAsFixed(2)} $unit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                          if (value >= 0 && value < topPurposes.length) {
                            // Abreviar texto se for muito longo
                            final purpose = topPurposes[value.toInt()];
                            final displayText = purpose.length > 10
                                ? '${purpose.substring(0, 8)}...'
                                : purpose;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: topPurposes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final purpose = entry.value;
                    final value = purposeTotals[purpose]!;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: barColors[index % barColors.length],
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um item de legenda para o gráfico
  Widget _buildLegendItem(BuildContext context, String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Enum para definir os tipos de gráfico disponíveis
enum ChartType {
  /// Gráfico de linha mostrando o nível de estoque ao longo do tempo
  stockLevel,
  
  /// Gráfico de pizza mostrando a distribuição de movimentos por tipo (entrada/saída)
  movementsByType,
  
  /// Gráfico de barras mostrando a distribuição de movimentos por finalidade
  movementsByPurpose,
}

