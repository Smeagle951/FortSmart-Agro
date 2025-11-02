import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de gráfico de distribuição de fertilizantes melhorado
/// Mostra barras coloridas com faixas de qualidade
class FertilizerDistributionChart extends StatelessWidget {
  final List<double> weights;
  final double averageWeight;
  final double standardDeviation;
  
  const FertilizerDistributionChart({
    Key? key,
    required this.weights,
    required this.averageWeight,
    required this.standardDeviation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum dado para exibir',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Título e legenda
          _buildHeader(),
          const SizedBox(height: 16),
          
          // Gráfico de barras
          _buildBarChart(),
          const SizedBox(height: 16),
          
          // Linha de referência e faixas
          _buildReferenceLines(),
        ],
      ),
    );
  }
  
  /// Constrói o cabeçalho com título e legenda
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Distribuição por Ponto de Coleta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildLegend(),
      ],
    );
  }
  
  /// Constrói a legenda
  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem('Excelente', Colors.green, 10),
        const SizedBox(width: 8),
        _buildLegendItem('Moderado', Colors.orange, 15),
        const SizedBox(width: 8),
        _buildLegendItem('Ruim', Colors.red, 20),
      ],
    );
  }
  
  /// Constrói um item da legenda
  Widget _buildLegendItem(String label, Color color, double maxValue) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// Constrói o gráfico de barras
  Widget _buildBarChart() {
    final maxWeight = weights.reduce(math.max);
    final minWeight = weights.reduce(math.min);
    final range = maxWeight - minWeight;
    final chartHeight = 120.0;
    
    return Container(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weights.asMap().entries.map((entry) {
          final index = entry.key;
          final weight = entry.value;
          final height = range > 0 ? (weight - minWeight) / range * chartHeight : chartHeight;
          final color = _getBarColor(weight);
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Valor no topo da barra
              Text(
                '${weight.toStringAsFixed(0)}g',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              
              // Barra
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              
              // Número do ponto
              Text(
                'P${index + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  /// Constrói as linhas de referência e faixas
  Widget _buildReferenceLines() {
    final maxWeight = weights.reduce(math.max);
    final minWeight = weights.reduce(math.min);
    final range = maxWeight - minWeight;
    final chartHeight = 120.0;
    
    // Calcular posições das linhas de referência
    final averagePosition = range > 0 ? (averageWeight - minWeight) / range * chartHeight : chartHeight / 2;
    final plus10Percent = averageWeight * 1.1;
    final minus10Percent = averageWeight * 0.9;
    final plus15Percent = averageWeight * 1.15;
    final minus15Percent = averageWeight * 0.85;
    
    final plus10Position = range > 0 ? (plus10Percent - minWeight) / range * chartHeight : averagePosition;
    final minus10Position = range > 0 ? (minus10Percent - minWeight) / range * chartHeight : averagePosition;
    final plus15Position = range > 0 ? (plus15Percent - minWeight) / range * chartHeight : averagePosition;
    final minus15Position = range > 0 ? (minus15Percent - minWeight) / range * chartHeight : averagePosition;
    
    return Container(
      height: chartHeight,
      child: Stack(
        children: [
          // Faixa vermelha (ruim)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: chartHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.05),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // Faixa amarela (moderado)
          Positioned(
            top: math.min(plus15Position, minus15Position),
            left: 0,
            right: 0,
            child: Container(
              height: (plus15Position - minus15Position).abs(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          
          // Faixa verde (excelente)
          Positioned(
            top: math.min(plus10Position, minus10Position),
            left: 0,
            right: 0,
            child: Container(
              height: (plus10Position - minus10Position).abs(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          
          // Linha da média
          Positioned(
            top: chartHeight - averagePosition,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          // Linhas de referência
          Positioned(
            top: chartHeight - plus10Position,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          Positioned(
            top: chartHeight - minus10Position,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          Positioned(
            top: chartHeight - plus15Position,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          Positioned(
            top: chartHeight - minus15Position,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Obtém a cor da barra baseada no desvio da média
  Color _getBarColor(double weight) {
    final deviation = (weight - averageWeight).abs();
    final deviationPercent = (deviation / averageWeight) * 100;
    
    if (deviationPercent <= 10) {
      return Colors.green;
    } else if (deviationPercent <= 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
