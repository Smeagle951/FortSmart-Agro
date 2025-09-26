import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_tracking_service.dart';

/// Widget para controle do rastreamento GPS
class GpsTrackingWidget extends StatefulWidget {
  final GpsTrackingService trackingService;
  final Function(List<LatLng>) onPointsUpdated;
  final VoidCallback? onSave;

  const GpsTrackingWidget({
    Key? key,
    required this.trackingService,
    required this.onPointsUpdated,
    this.onSave,
  }) : super(key: key);

  @override
  State<GpsTrackingWidget> createState() => _GpsTrackingWidgetState();
}

class _GpsTrackingWidgetState extends State<GpsTrackingWidget> {
  @override
  void initState() {
    super.initState();
    widget.trackingService.addListener(_onTrackingChanged);
  }

  @override
  void dispose() {
    widget.trackingService.removeListener(_onTrackingChanged);
    super.dispose();
  }

  void _onTrackingChanged() {
    setState(() {});
    widget.onPointsUpdated(widget.trackingService.trackedPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: _getStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informações do rastreamento
          if (widget.trackingService.hasPoints) ...[
            _buildInfoRow('Pontos', '${widget.trackingService.trackedPoints.length}'),
            _buildInfoRow('Distância', widget.trackingService.formatDistance(widget.trackingService.totalDistance)),
            _buildInfoRow('Duração', widget.trackingService.formatDuration(widget.trackingService.totalDuration)),
            if (widget.trackingService.trackedPoints.length >= 3) ...[
              _buildInfoRow('Área', '${widget.trackingService.calculateArea().toStringAsFixed(2)} ha'),
              _buildInfoRow('Perímetro', '${widget.trackingService.calculatePerimeter().toStringAsFixed(1)} m'),
            ],
            const SizedBox(height: 16),
          ],
          
          // Controles
          Row(
            children: [
              // Botão Iniciar/Pausar/Retomar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleStartPauseResume,
                  icon: Icon(_getStartPauseIcon()),
                  label: Text(_getStartPauseText()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStartPauseColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botão Salvar (só aparece quando há pontos)
              if (widget.trackingService.hasPoints)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Botão Reset (só aparece quando há pontos)
          if (widget.trackingService.hasPoints)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reiniciar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        return Colors.grey;
      case GpsTrackingState.recording:
        return Colors.green;
      case GpsTrackingState.paused:
        return Colors.orange;
      case GpsTrackingState.finalized:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        return 'Pronto para iniciar';
      case GpsTrackingState.recording:
        return 'Gravando...';
      case GpsTrackingState.paused:
        return 'Pausado';
      case GpsTrackingState.finalized:
        return 'Finalizado';
    }
  }

  IconData _getStartPauseIcon() {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        return Icons.play_arrow;
      case GpsTrackingState.recording:
        return Icons.pause;
      case GpsTrackingState.paused:
        return Icons.play_arrow;
      case GpsTrackingState.finalized:
        return Icons.play_arrow;
    }
  }

  String _getStartPauseText() {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        return 'Iniciar';
      case GpsTrackingState.recording:
        return 'Pausar';
      case GpsTrackingState.paused:
        return 'Retomar';
      case GpsTrackingState.finalized:
        return 'Novo';
    }
  }

  Color _getStartPauseColor() {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        return Colors.blue;
      case GpsTrackingState.recording:
        return Colors.orange;
      case GpsTrackingState.paused:
        return Colors.green;
      case GpsTrackingState.finalized:
        return Colors.blue;
    }
  }

  Future<void> _handleStartPauseResume() async {
    switch (widget.trackingService.state) {
      case GpsTrackingState.idle:
        final success = await widget.trackingService.startTracking();
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao iniciar rastreamento GPS. Verifique as permissões de localização.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case GpsTrackingState.recording:
        widget.trackingService.pauseTracking();
        break;
      case GpsTrackingState.paused:
        final success = await widget.trackingService.resumeTracking();
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao retomar rastreamento GPS.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case GpsTrackingState.finalized:
        widget.trackingService.resetTracking();
        final success = await widget.trackingService.startTracking();
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao iniciar novo rastreamento GPS.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  void _handleSave() {
    if (widget.trackingService.trackedPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário pelo menos 3 pontos para salvar o talhão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.trackingService.finalizeTracking();
    widget.onSave?.call();
  }

  void _handleReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Rastreamento'),
        content: const Text('Tem certeza que deseja reiniciar o rastreamento? Todos os pontos serão perdidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.trackingService.resetTracking();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
} 