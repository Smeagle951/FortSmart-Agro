import 'package:flutter/material.dart';

/// Widget para analytics de mapas offline
class OfflineMapAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> cacheStats;
  final Map<String, dynamic> storageStats;
  final Map<String, dynamic> integrationStats;

  const OfflineMapAnalyticsWidget({
    Key? key,
    required this.cacheStats,
    required this.storageStats,
    required this.integrationStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estatísticas de cache
        _buildCacheAnalytics(),
        
        const SizedBox(height: 20),
        
        // Estatísticas de armazenamento
        _buildStorageAnalytics(),
        
        const SizedBox(height: 20),
        
        // Estatísticas de integração
        _buildIntegrationAnalytics(),
        
        const SizedBox(height: 20),
        
        // Gráficos e métricas
        _buildChartsSection(),
      ],
    );
  }
  
  /// Analytics de cache
  Widget _buildCacheAnalytics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Analytics de Cache',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Tiles em Cache',
                    '${cacheStats['totalTiles'] ?? 0}',
                    Icons.map,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Taxa de Hit',
                    '${cacheStats['hitRate'] ?? 0}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Tempo Médio',
                    '${cacheStats['avgLoadTime'] ?? 0}ms',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Analytics de armazenamento
  Widget _buildStorageAnalytics() {
    final totalSize = storageStats['totalSizeMB'] ?? 0;
    final maxSize = storageStats['maxSizeMB'] ?? 1000;
    final usagePercentage = (totalSize / maxSize * 100).clamp(0, 100);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Analytics de Armazenamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barra de progresso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uso de Armazenamento',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_formatSize(totalSize)} / ${_formatSize(maxSize)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getUsageColor(usagePercentage),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                LinearProgressIndicator(
                  value: usagePercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getUsageColor(usagePercentage),
                  ),
                  minHeight: 8,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Arquivos',
                    '${storageStats['fileCount'] ?? 0}',
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Mapas',
                    '${storageStats['mapCount'] ?? 0}',
                    Icons.map,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Cache',
                    '${_formatSize(storageStats['cacheSizeMB'] ?? 0)}',
                    Icons.cached,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Analytics de integração
  Widget _buildIntegrationAnalytics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.integration_instructions, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Analytics de Integração',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Módulos Ativos',
                    '${integrationStats['activeModules'] ?? 0}',
                    Icons.widgets,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Sincronizações',
                    '${integrationStats['syncCount'] ?? 0}',
                    Icons.sync,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Taxa de Sucesso',
                    '${integrationStats['successRate'] ?? 0}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Seção de gráficos
  Widget _buildChartsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.purple[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Métricas e Tendências',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Placeholder para gráficos
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gráficos em desenvolvimento',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Item de analytics
  Widget _buildAnalyticsItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Formata tamanho
  String _formatSize(double sizeMB) {
    if (sizeMB < 1) {
      return '${(sizeMB * 1024).toStringAsFixed(0)} KB';
    } else if (sizeMB < 1024) {
      return '${sizeMB.toStringAsFixed(1)} MB';
    } else {
      return '${(sizeMB / 1024).toStringAsFixed(1)} GB';
    }
  }
  
  /// Obtém cor baseada no uso
  Color _getUsageColor(double percentage) {
    if (percentage < 50) {
      return Colors.green;
    } else if (percentage < 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
