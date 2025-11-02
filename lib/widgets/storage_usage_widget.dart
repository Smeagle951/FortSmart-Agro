import 'package:flutter/material.dart';

/// Widget para exibir uso de armazenamento
class StorageUsageWidget extends StatelessWidget {
  final Map<String, dynamic> storageStats;
  final VoidCallback? onCleanup;

  const StorageUsageWidget({
    Key? key,
    required this.storageStats,
    this.onCleanup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  'Uso de Armazenamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (onCleanup != null)
                  TextButton.icon(
                    onPressed: onCleanup,
                    icon: const Icon(Icons.cleaning_services, size: 16),
                    label: const Text('Limpar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[600],
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
                      'Espaço usado',
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
                
                const SizedBox(height: 8),
                
                Text(
                  '${usagePercentage.toStringAsFixed(1)}% usado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estatísticas detalhadas
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Arquivos',
                    '${storageStats['fileCount'] ?? 0}',
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cache',
                    '${_formatSize(storageStats['cacheSizeMB'] ?? 0)}',
                    Icons.cached,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Mapas',
                    '${storageStats['mapCount'] ?? 0}',
                    Icons.map,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            if (usagePercentage > 80) ...[
              const SizedBox(height: 16),
              
              // Aviso de espaço baixo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Espaço de armazenamento baixo. Considere limpar o cache.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Item de estatística
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
