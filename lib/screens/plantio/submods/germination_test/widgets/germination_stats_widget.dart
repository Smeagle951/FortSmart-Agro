/// 🌱 Widget de Estatísticas de Germinação
/// 
/// Exibe estatísticas elegantes dos testes de germinação
/// seguindo o padrão visual FortSmart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../providers/germination_test_provider.dart';

class GerminationStatsWidget extends StatelessWidget {
  const GerminationStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GerminationTestProvider>(
      builder: (context, provider, child) {
        // Verificar se está carregando
        if (provider.isLoading) {
          return _buildLoadingCard();
        }
        
        final stats = provider.statistics;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: FortSmartTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Estatísticas Gerais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatsGrid(stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total de Testes',
          '${stats['totalTests'] ?? 0}',
          Icons.science,
          FortSmartTheme.primaryColor,
        ),
        _buildStatCard(
          'Testes Ativos',
          '${stats['activeTests'] ?? 0}',
          Icons.play_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Completos',
          '${stats['completedTests'] ?? 0}',
          Icons.check_circle,
          Colors.blue,
        ),
        _buildStatCard(
          'Cancelados',
          '${stats['cancelledTests'] ?? 0}',
          Icons.cancel,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20), // Reduzido de 24 para 20
          const SizedBox(height: 4), // Reduzido de 6 para 4
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Reduzido de 18 para 16
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1), // Reduzido de 2 para 1
          Text(
            title,
            style: TextStyle(
              fontSize: 10, // Reduzido de 11 para 10
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estatísticas Gerais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Carregando estatísticas...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
