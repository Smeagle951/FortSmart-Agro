import 'package:flutter/material.dart';

/// Widget para exibir progresso de download
class DownloadProgressWidget extends StatelessWidget {
  final double progress;
  final int downloadedTiles;
  final int totalTiles;
  final String? message;

  const DownloadProgressWidget({
    super.key,
    required this.progress,
    required this.downloadedTiles,
    required this.totalTiles,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progresso
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Informações do progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baixando tiles...',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$downloadedTiles / $totalTiles',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          
          // Mensagem adicional (se houver)
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
