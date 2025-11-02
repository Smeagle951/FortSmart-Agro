import 'package:flutter/material.dart';

/// Widget para status em tempo real
class RealTimeStatusWidget extends StatefulWidget {
  final Map<String, dynamic> statusData;
  final bool showDetails;
  final VoidCallback? onRefresh;

  const RealTimeStatusWidget({
    Key? key,
    required this.statusData,
    this.showDetails = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<RealTimeStatusWidget> createState() => _RealTimeStatusWidgetState();
}

class _RealTimeStatusWidgetState extends State<RealTimeStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.statusData['isOnline'] ?? false;
    final isDownloading = widget.statusData['isDownloading'] ?? false;
    final hasError = widget.statusData['hasError'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildStatusIndicator(isOnline, isDownloading, hasError),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status em Tempo Real',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _getStatusText(isOnline, isDownloading, hasError),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar',
                  ),
              ],
            ),

            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              _buildDetailsSection(),
            ],
          ],
        ),
      ),
    );
  }

  /// Indicador de status
  Widget _buildStatusIndicator(bool isOnline, bool isDownloading, bool hasError) {
    Color color;
    IconData icon;

    if (hasError) {
      color = Colors.red;
      icon = Icons.error;
    } else if (isDownloading) {
      color = Colors.blue;
      icon = Icons.download;
    } else if (isOnline) {
      color = Colors.green;
      icon = Icons.cloud_done;
    } else {
      color = Colors.orange;
      icon = Icons.cloud_off;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  /// Texto de status
  String _getStatusText(bool isOnline, bool isDownloading, bool hasError) {
    if (hasError) {
      return 'Erro detectado';
    } else if (isDownloading) {
      return 'Download em andamento';
    } else if (isOnline) {
      return 'Sistema online';
    } else {
      return 'Modo offline';
    }
  }

  /// Seção de detalhes
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Conexão', widget.statusData['connectionType'] ?? 'N/A'),
        _buildDetailRow('Velocidade', widget.statusData['connectionSpeed'] ?? 'N/A'),
        _buildDetailRow('Latência', '${widget.statusData['latency'] ?? 0}ms'),
        _buildDetailRow('Última Sincronização', _formatTimestamp(widget.statusData['lastSync'])),
        if (widget.statusData['activeDownloads'] != null)
          _buildDetailRow('Downloads Ativos', '${widget.statusData['activeDownloads']}'),
        if (widget.statusData['queueSize'] != null)
          _buildDetailRow('Fila de Download', '${widget.statusData['queueSize']}'),
      ],
    );
  }

  /// Linha de detalhe
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formata timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      return 'N/A';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
