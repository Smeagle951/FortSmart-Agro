import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget para exibir estatísticas de estoque em formato de card
class InventoryStatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> stats;
  final Color? color;
  final VoidCallback? onTap;
  final bool showTrend;

  const InventoryStatsCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.stats,
    this.color,
    this.onTap,
    this.showTrend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).primaryColor;
    final textColor = _getTextColor(cardColor);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: textColor.withOpacity(0.8),
                    size: 28,
                  ),
                  if (showTrend && stats.containsKey('trend'))
                    _buildTrendIndicator(stats['trend'], textColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildMainStat(context, textColor),
              const SizedBox(height: 12),
              _buildDetailStats(context, textColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o indicador de tendência (seta para cima ou para baixo)
  Widget _buildTrendIndicator(double trend, Color textColor) {
    final isPositive = trend >= 0;
    final trendAbs = trend.abs();
    final trendText = '${trendAbs.toStringAsFixed(1)}%';
    
    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPositive ? Colors.green[100] : Colors.red[100],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          trendText,
          style: TextStyle(
            color: isPositive ? Colors.green[100] : Colors.red[100],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Constrói a estatística principal do card
  Widget _buildMainStat(BuildContext context, Color textColor) {
    final mainValue = stats['mainValue'] ?? 0;
    final mainUnit = stats['mainUnit'] as String? ?? '';
    
    // Formatar valor numérico
    String formattedValue;
    if (mainValue is int) {
      formattedValue = NumberFormat('#,###').format(mainValue);
    } else if (mainValue is double) {
      formattedValue = NumberFormat('#,##0.00').format(mainValue);
    } else {
      formattedValue = mainValue.toString();
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedValue,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (mainUnit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              mainUnit,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói as estatísticas detalhadas do card
  Widget _buildDetailStats(BuildContext context, Color textColor) {
    final detailStats = stats['details'] as Map<String, dynamic>? ?? {};
    
    if (detailStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: detailStats.entries.map((entry) {
        final label = entry.key;
        final value = entry.value;
        
        // Formatar valor numérico
        String formattedValue;
        if (value is int) {
          formattedValue = NumberFormat('#,###').format(value);
        } else if (value is double) {
          formattedValue = NumberFormat('#,##0.00').format(value);
        } else {
          formattedValue = value.toString();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedValue,
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Determina a cor do texto com base na cor de fundo do card
  Color _getTextColor(Color backgroundColor) {
    // Calcular a luminosidade da cor de fundo
    final luminance = backgroundColor.computeLuminance();
    
    // Se a cor de fundo for escura, usar texto claro
    return luminance < 0.5 ? Colors.white : Colors.black;
  }
}

/// Widget para exibir um conjunto de cards de estatísticas
class InventoryStatsCardGrid extends StatelessWidget {
  final List<InventoryStatsCard> cards;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const InventoryStatsCardGrid({
    Key? key,
    required this.cards,
    this.crossAxisCount = 2,
    this.spacing = 16.0,
    this.childAspectRatio = 1.4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}
