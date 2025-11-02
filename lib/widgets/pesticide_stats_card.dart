import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fortsmart_agro/models/pesticide_application.dart';

/// Widget para exibir estatísticas de aplicação de defensivos
class PesticideStatsCard extends StatelessWidget {
  final String title;
  final List<PesticideApplicationStat> stats;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onViewMore;

  const PesticideStatsCard({
    Key? key,
    required this.title,
    required this.stats,
    required this.startDate,
    required this.endDate,
    this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildChart(context),
            const SizedBox(height: 16),
            _buildStatsList(context),
            if (onViewMore != null) ...[
              const SizedBox(height: 8),
              _buildViewMoreButton(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do card
  Widget _buildHeader(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodText = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Período: $periodText',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Constrói o gráfico de estatísticas
  Widget _buildChart(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _generatePieSections(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Implementar interatividade se necessário
            },
          ),
        ),
      ),
    );
  }

  /// Gera as seções do gráfico de pizza
  List<PieChartSectionData> _generatePieSections() {
    // Ordenar por valor para melhor visualização
    final sortedStats = List<PesticideApplicationStat>.from(stats)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limitar a 5 itens para não sobrecarregar o gráfico
    final displayStats = sortedStats.take(5).toList();
    
    // Calcular o total para percentuais
    final total = displayStats.fold(0.0, (sum, stat) => sum + stat.value);
    
    // Cores para o gráfico
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    return displayStats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final percentage = total > 0 ? (stat.value / total) * 100 : 0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: stat.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// Constrói a lista de estatísticas
  Widget _buildStatsList(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox();
    }
    
    // Ordenar por valor (decrescente)
    final sortedStats = List<PesticideApplicationStat>.from(stats)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calcular o total para percentuais
    final total = sortedStats.fold(0.0, (sum, stat) => sum + stat.value);
    
    // Cores para os indicadores
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalhamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final percentage = total > 0 ? (stat.value / total) * 100 : 0;
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatValue(stat),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTotal(total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o botão para ver mais
  Widget _buildViewMoreButton(BuildContext context) {
    return Align(
      // alignment: Alignment.centerRight, // alignment não é suportado em Marker no flutter_map 5.0.0
      child: TextButton(
        onPressed: onViewMore,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ver mais'),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }

  /// Formata o valor da estatística com base no tipo
  String _formatValue(PesticideApplicationStat stat) {
    switch (stat.type) {
      case StatType.area:
        return '${stat.value.toStringAsFixed(2)} ha';
      case StatType.quantity:
        return '${stat.value.toStringAsFixed(2)} ${stat.unit}';
      case StatType.count:
        return '${stat.value.toStringAsFixed(0)}';
      case StatType.cost:
        return 'R\$ ${stat.value.toStringAsFixed(2)}';
    }
  }

  /// Formata o valor total com base no tipo de estatística
  String _formatTotal(double total) {
    if (stats.isEmpty) return '0';
    
    // Usar o tipo do primeiro item para determinar a formatação
    final firstStat = stats.first;
    
    switch (firstStat.type) {
      case StatType.area:
        return '${total.toStringAsFixed(2)} ha';
      case StatType.quantity:
        return '${total.toStringAsFixed(2)} ${firstStat.unit}';
      case StatType.count:
        return '${total.toStringAsFixed(0)}';
      case StatType.cost:
        return 'R\$ ${total.toStringAsFixed(2)}';
    }
  }
}

/// Widget para exibir estatísticas de aplicação por categoria
class PesticideCategoryStatsCard extends StatelessWidget {
  final Map<String, double> categoryStats;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onViewMore;

  const PesticideCategoryStatsCard({
    Key? key,
    required this.categoryStats,
    required this.startDate,
    required this.endDate,
    this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = categoryStats.entries
        .map((e) => PesticideApplicationStat(
              label: e.key,
              value: e.value,
              type: StatType.quantity,
              unit: 'L/kg',
            ))
        .toList();
    
    return PesticideStatsCard(
      title: 'Aplicação por Categoria',
      stats: stats,
      startDate: startDate,
      endDate: endDate,
      onViewMore: onViewMore,
    );
  }
}

/// Widget para exibir estatísticas de aplicação por cultura
class PesticideCropStatsCard extends StatelessWidget {
  final Map<String, double> cropStats;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onViewMore;

  const PesticideCropStatsCard({
    Key? key,
    required this.cropStats,
    required this.startDate,
    required this.endDate,
    this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = cropStats.entries
        .map((e) => PesticideApplicationStat(
              label: e.key,
              value: e.value,
              type: StatType.area,
              unit: 'ha',
            ))
        .toList();
    
    return PesticideStatsCard(
      title: 'Área Tratada por Cultura',
      stats: stats,
      startDate: startDate,
      endDate: endDate,
      onViewMore: onViewMore,
    );
  }
}

/// Widget para exibir estatísticas de custo de aplicação
class PesticideCostStatsCard extends StatelessWidget {
  final Map<String, double> costStats;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onViewMore;

  const PesticideCostStatsCard({
    Key? key,
    required this.costStats,
    required this.startDate,
    required this.endDate,
    this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = costStats.entries
        .map((e) => PesticideApplicationStat(
              label: e.key,
              value: e.value,
              type: StatType.cost,
              unit: 'R\$',
            ))
        .toList();
    
    return PesticideStatsCard(
      title: 'Custo de Aplicação por Produto',
      stats: stats,
      startDate: startDate,
      endDate: endDate,
      onViewMore: onViewMore,
    );
  }
}

/// Classe para armazenar dados de estatística de aplicação
class PesticideApplicationStat {
  final String label;
  final double value;
  final StatType type;
  final String unit;
  
  PesticideApplicationStat({
    required this.label,
    required this.value,
    required this.type,
    this.unit = '',
  });
}

/// Enum que define os tipos de estatística
enum StatType {
  area,
  quantity,
  count,
  cost,
}

