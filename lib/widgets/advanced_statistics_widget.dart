import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fertilizer_calibration.dart';

/// Widget para análise estatística avançada
class AdvancedStatisticsWidget extends StatelessWidget {
  final FertilizerCalibration calibration;

  const AdvancedStatisticsWidget({
    super.key,
    required this.calibration,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateAdvancedStatistics();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Análise Estatística Avançada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Métricas principais
            _buildMetricsGrid(stats),
            const SizedBox(height: 20),
            
            // Intervalos de confiança
            _buildConfidenceIntervals(stats),
            const SizedBox(height: 20),
            
            // Análise de outliers
            _buildOutliersAnalysis(stats),
            const SizedBox(height: 20),
            
            // Teste de normalidade
            _buildNormalityTest(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(AdvancedStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas Principais',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard(
              'Média',
              '${stats.mean.toStringAsFixed(2)} g',
              Icons.bar_chart,
              Colors.blue,
            ),
            _buildMetricCard(
              'Mediana',
              '${stats.median.toStringAsFixed(2)} g',
              Icons.center_focus_strong,
              Colors.green,
            ),
            _buildMetricCard(
              'Desvio Padrão',
              '${stats.standardDeviation.toStringAsFixed(2)} g',
              Icons.trending_flat,
              Colors.orange,
            ),
            _buildMetricCard(
              'Coeficiente de Variação',
              '${stats.coefficientOfVariation.toStringAsFixed(2)}%',
              Icons.speed,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIntervals(AdvancedStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intervalos de Confiança',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIntervalCard(
                '95%',
                '${stats.confidenceInterval95.lower.toStringAsFixed(2)} - ${stats.confidenceInterval95.upper.toStringAsFixed(2)} g',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIntervalCard(
                '99%',
                '${stats.confidenceInterval99.lower.toStringAsFixed(2)} - ${stats.confidenceInterval99.upper.toStringAsFixed(2)} g',
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalCard(String level, String range, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IC $level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            range,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutliersAnalysis(AdvancedStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análise de Outliers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stats.outliers.isEmpty 
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: stats.outliers.isEmpty 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                stats.outliers.isEmpty ? Icons.check_circle : Icons.warning,
                color: stats.outliers.isEmpty ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.outliers.isEmpty 
                          ? 'Nenhum outlier detectado'
                          : '${stats.outliers.length} outlier(s) detectado(s)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: stats.outliers.isEmpty ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (stats.outliers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Bandejas: ${stats.outliers.map((i) => i + 1).join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNormalityTest(AdvancedStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teste de Normalidade',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stats.isNormal 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: stats.isNormal 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                stats.isNormal ? Icons.check_circle : Icons.error,
                color: stats.isNormal ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.isNormal 
                          ? 'Distribuição normal'
                          : 'Distribuição não normal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: stats.isNormal ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'p-valor: ${stats.normalityPValue.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  AdvancedStatistics _calculateAdvancedStatistics() {
    final weights = calibration.weights;
    final n = weights.length;
    
    // Estatísticas básicas
    final mean = weights.reduce((a, b) => a + b) / n;
    final sortedWeights = List<double>.from(weights)..sort();
    final median = n % 2 == 0
        ? (sortedWeights[n ~/ 2 - 1] + sortedWeights[n ~/ 2]) / 2
        : sortedWeights[n ~/ 2];
    
    // Desvio padrão
    final variance = weights.map((w) => pow(w - mean, 2)).reduce((a, b) => a + b) / (n - 1);
    final standardDeviation = sqrt(variance);
    final coefficientOfVariation = (standardDeviation / mean) * 100;
    
    // Intervalos de confiança (t-student)
    final t95 = _getTValue(n - 1, 0.05);
    final t99 = _getTValue(n - 1, 0.01);
    final se = standardDeviation / sqrt(n);
    
    final confidenceInterval95 = ConfidenceInterval(
      lower: mean - t95 * se,
      upper: mean + t95 * se,
    );
    
    final confidenceInterval99 = ConfidenceInterval(
      lower: mean - t99 * se,
      upper: mean + t99 * se,
    );
    
    // Detecção de outliers (IQR method)
    final q1 = sortedWeights[n ~/ 4];
    final q3 = sortedWeights[3 * n ~/ 4];
    final iqr = q3 - q1;
    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;
    
    final outliers = <int>[];
    for (int i = 0; i < weights.length; i++) {
      if (weights[i] < lowerBound || weights[i] > upperBound) {
        outliers.add(i);
      }
    }
    
    // Teste de normalidade simplificado (Shapiro-Wilk aproximado)
    final isNormal = _testNormality(weights);
    final normalityPValue = _calculateNormalityPValue(weights);
    
    return AdvancedStatistics(
      mean: mean,
      median: median,
      standardDeviation: standardDeviation,
      coefficientOfVariation: coefficientOfVariation,
      confidenceInterval95: confidenceInterval95,
      confidenceInterval99: confidenceInterval99,
      outliers: outliers,
      isNormal: isNormal,
      normalityPValue: normalityPValue,
    );
  }

  double _getTValue(int df, double alpha) {
    // Valores aproximados da distribuição t-student
    final tValues = {
      1: {'0.05': 12.706, '0.01': 63.657},
      2: {'0.05': 4.303, '0.01': 9.925},
      3: {'0.05': 3.182, '0.01': 5.841},
      4: {'0.05': 2.776, '0.01': 4.604},
      5: {'0.05': 2.571, '0.01': 4.032},
      10: {'0.05': 2.228, '0.01': 3.169},
      20: {'0.05': 2.086, '0.01': 2.845},
      30: {'0.05': 2.042, '0.01': 2.750},
    };
    
    final alphaKey = alpha.toString();
    if (tValues.containsKey(df) && tValues[df]!.containsKey(alphaKey)) {
      return tValues[df]![alphaKey]!;
    }
    
    // Para df > 30, usar distribuição normal
    return alpha == 0.05 ? 1.96 : 2.576;
  }

  bool _testNormality(List<double> data) {
    // Teste simplificado de normalidade
    final n = data.length;
    if (n < 3) return true;
    
    final mean = data.reduce((a, b) => a + b) / n;
    final variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / (n - 1);
    final stdDev = sqrt(variance);
    
    // Verificar se os dados estão dentro de 2 desvios padrão
    final within2Std = data.where((x) => (x - mean).abs() <= 2 * stdDev).length;
    final percentage = within2Std / n;
    
    return percentage >= 0.95; // 95% dos dados dentro de 2σ
  }

  double _calculateNormalityPValue(List<double> data) {
    // Cálculo aproximado do p-valor
    final n = data.length;
    if (n < 3) return 1.0;
    
    final mean = data.reduce((a, b) => a + b) / n;
    final variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / (n - 1);
    final stdDev = sqrt(variance);
    
    final within2Std = data.where((x) => (x - mean).abs() <= 2 * stdDev).length;
    final percentage = within2Std / n;
    
    // Converter para p-valor aproximado
    return (1.0 - percentage).clamp(0.0, 1.0);
  }
}

/// Classe para armazenar estatísticas avançadas
class AdvancedStatistics {
  final double mean;
  final double median;
  final double standardDeviation;
  final double coefficientOfVariation;
  final ConfidenceInterval confidenceInterval95;
  final ConfidenceInterval confidenceInterval99;
  final List<int> outliers;
  final bool isNormal;
  final double normalityPValue;

  AdvancedStatistics({
    required this.mean,
    required this.median,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.confidenceInterval95,
    required this.confidenceInterval99,
    required this.outliers,
    required this.isNormal,
    required this.normalityPValue,
  });
}

/// Classe para intervalo de confiança
class ConfidenceInterval {
  final double lower;
  final double upper;

  ConfidenceInterval({
    required this.lower,
    required this.upper,
  });
}
