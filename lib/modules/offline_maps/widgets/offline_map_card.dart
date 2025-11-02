import 'package:flutter/material.dart';
import '../models/offline_map_model.dart';
import '../models/offline_map_status.dart';
import 'download_progress_widget.dart';

/// Card para exibir informações de um mapa offline
class OfflineMapCard extends StatelessWidget {
  final OfflineMapModel offlineMap;
  final VoidCallback? onDownload;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;

  const OfflineMapCard({
    super.key,
    required this.offlineMap,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome e status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offlineMap.talhaoName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (offlineMap.fazendaName != null)
                        Text(
                          offlineMap.fazendaName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações do mapa
            _buildMapInfo(context),
            
            const SizedBox(height: 12),
            
            // Progresso do download (se aplicável)
            if (offlineMap.status == OfflineMapStatus.downloading)
              DownloadProgressWidget(
                progress: offlineMap.downloadProgress,
                downloadedTiles: offlineMap.downloadedTiles ?? 0,
                totalTiles: offlineMap.totalTiles ?? 0,
              ),
            
            // Mensagem de erro (se houver)
            if (offlineMap.status == OfflineMapStatus.error && offlineMap.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offlineMap.errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Botões de ação
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (offlineMap.status) {
      case OfflineMapStatus.downloaded:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        break;
      case OfflineMapStatus.downloading:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.download;
        break;
      case OfflineMapStatus.paused:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pause_circle;
        break;
      case OfflineMapStatus.error:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.error;
        break;
      case OfflineMapStatus.updateAvailable:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        icon = Icons.update;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            offlineMap.status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            context,
            Icons.area_chart,
            'Área',
            '${offlineMap.area.toStringAsFixed(1)} ha',
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            context,
            Icons.zoom_in,
            'Zoom',
            '${offlineMap.zoomMin}-${offlineMap.zoomMax}',
          ),
        ),
        if (offlineMap.totalTiles != null)
          Expanded(
            child: _buildInfoItem(
              context,
              Icons.grid_on,
              'Tiles',
              '${offlineMap.totalTiles}',
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Botão principal baseado no status
        Expanded(
          child: _buildPrimaryButton(context),
        ),
        const SizedBox(width: 8),
        // Botão secundário
        _buildSecondaryButton(context),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    switch (offlineMap.status) {
      case OfflineMapStatus.notDownloaded:
        return ElevatedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Baixar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case OfflineMapStatus.downloading:
        return ElevatedButton.icon(
          onPressed: onPause,
          icon: const Icon(Icons.pause, size: 18),
          label: const Text('Pausar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case OfflineMapStatus.paused:
        return ElevatedButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Retomar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case OfflineMapStatus.downloaded:
        return ElevatedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Atualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case OfflineMapStatus.error:
        return ElevatedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Tentar Novamente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case OfflineMapStatus.updateAvailable:
        return ElevatedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.update, size: 18),
          label: const Text('Atualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
      color: Colors.red[600],
      tooltip: 'Remover',
    );
  }
}
