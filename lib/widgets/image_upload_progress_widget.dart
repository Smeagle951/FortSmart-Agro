import 'package:flutter/material.dart';
import '../models/sync/image_upload_progress.dart';

/// Widget para exibir o progresso de upload de imagens durante a sincronização
class ImageUploadProgressWidget extends StatefulWidget {
  final ImageUploadProgress? progress;
  final VoidCallback? onCancel;
  
  const ImageUploadProgressWidget({
    Key? key,
    this.progress,
    this.onCancel,
  }) : super(key: key);

  @override
  _ImageUploadProgressWidgetState createState() => _ImageUploadProgressWidgetState();
}

class _ImageUploadProgressWidgetState extends State<ImageUploadProgressWidget> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.progress == null) {
      return const SizedBox.shrink();
    }
    
    final progress = widget.progress!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progresso de Upload de Imagens',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(progress),
          if (widget.onCancel != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancelar'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildProgressItem(ImageUploadProgress progress) {
    // Definir cor com base no status
    Color statusColor;
    IconData statusIcon;
    
    switch (progress.status) {
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'uploading':
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_upload;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'cancelled':
        statusColor = Colors.orange;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFileName(progress.fileName),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.percentComplete.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentComplete / 100,
              // backgroundColor: Colors.grey.shade200, // backgroundColor não é suportado em flutter_map 5.0.0
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          if (progress.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                progress.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text(
            _getStatusText(progress),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFileName(String fullPath) {
    // Extrair apenas o nome do arquivo do caminho completo
    final parts = fullPath.split('/');
    return parts.last;
  }
  
  String _getStatusText(ImageUploadProgress progress) {
    final sizeKB = progress.totalBytes ~/ 1024;
    final uploadedKB = progress.bytesUploaded ~/ 1024;
    
    switch (progress.status) {
      case 'pending':
        return 'Aguardando para iniciar (${sizeKB}KB)';
      case 'uploading':
        final remainingTime = progress.estimatedTimeRemaining;
        if (remainingTime > 0) {
          return 'Enviando ${uploadedKB}KB de ${sizeKB}KB (${_formatTime(remainingTime)} restantes)';
        } else {
          return 'Enviando ${uploadedKB}KB de ${sizeKB}KB';
        }
      case 'completed':
        return 'Upload concluído (${sizeKB}KB)';
      case 'failed':
        return 'Falha no upload: ${progress.error ?? "Erro desconhecido"}';
      case 'cancelled':
        return 'Upload cancelado';
      default:
        return 'Status desconhecido';
    }
  }
  
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds seg';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes min ${remainingSeconds > 0 ? "$remainingSeconds seg" : ""}'.trim();
    } else {
      final hours = (seconds / 3600).floor();
      final remainingMinutes = ((seconds % 3600) / 60).floor();
      return '$hours h ${remainingMinutes > 0 ? "$remainingMinutes min" : ""}'.trim();
    }
  }
}
