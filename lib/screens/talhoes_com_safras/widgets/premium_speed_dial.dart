import 'package:flutter/material.dart';

/// Widget premium para speed dial com funcionalidades de talhão
class PremiumSpeedDial extends StatefulWidget {
  final VoidCallback? onDesenhoManual;
  final VoidCallback? onCaminhadaGps;
  final VoidCallback? onImportarArquivo;
  final VoidCallback? onCentralizarGps;
  final VoidCallback? onApagarDesenho;
  final VoidCallback? onSalvarTalhao;
  final bool podeSalvar;
  final bool mostrarBotaoSalvar;
  final bool isDrawing;
  final bool isGpsRecording;
  final double? area;
  final double? distance;
  final Duration? gpsDuration;

  const PremiumSpeedDial({
    Key? key,
    this.onDesenhoManual,
    this.onCaminhadaGps,
    this.onImportarArquivo,
    this.onCentralizarGps,
    this.onApagarDesenho,
    this.onSalvarTalhao,
    this.podeSalvar = false,
    this.mostrarBotaoSalvar = false,
    this.isDrawing = false,
    this.isGpsRecording = false,
    this.area,
    this.distance,
    this.gpsDuration,
  }) : super(key: key);

  @override
  State<PremiumSpeedDial> createState() => _PremiumSpeedDialState();
}

class _PremiumSpeedDialState extends State<PremiumSpeedDial>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Informações de status
        if (widget.isDrawing || widget.isGpsRecording)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
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
                if (widget.isDrawing) ...[
                  const Text(
                    '✏️ Modo Desenho Manual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  if (widget.area != null)
                    Text(
                      'Área: ${widget.area!.toStringAsFixed(2)} ha',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
                if (widget.isGpsRecording) ...[
                  const Text(
                    '🚶‍♂️ Gravando GPS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                  if (widget.distance != null)
                    Text(
                      'Distância: ${widget.distance!.toStringAsFixed(1)} m',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (widget.gpsDuration != null)
                    Text(
                      'Tempo: ${_formatDuration(widget.gpsDuration!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (widget.area != null)
                    Text(
                      'Área: ${widget.area!.toStringAsFixed(2)} ha',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
        
        // Speed dial expandido
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: _isExpanded ? _buildExpandedButtons() : const SizedBox.shrink(),
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Botão principal
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: const Color(0xFF3BAA57),
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão Salvar (se aplicável)
        if (widget.mostrarBotaoSalvar && widget.podeSalvar)
          _buildSpeedDialButton(
            icon: Icons.save,
            label: 'Salvar Talhão',
            backgroundColor: const Color(0xFF34A853),
            onPressed: widget.onSalvarTalhao,
          ),
        
        // Botão Desenho Manual
        _buildSpeedDialButton(
          icon: Icons.edit,
          label: 'Desenhar Manual',
          backgroundColor: const Color(0xFF4CAF50),
          onPressed: widget.onDesenhoManual,
        ),
        
        // Botão Caminhada GPS
        _buildSpeedDialButton(
          icon: Icons.directions_walk,
          label: 'Caminhada (GPS)',
          backgroundColor: const Color(0xFF42A5F5),
          onPressed: widget.onCaminhadaGps,
        ),
        
        // Botão Importar Arquivo
        _buildSpeedDialButton(
          icon: Icons.folder_open,
          label: 'Importar Arquivo',
          backgroundColor: const Color(0xFF7E57C2),
          onPressed: widget.onImportarArquivo,
        ),
        
        // Botão Centralizar GPS
        _buildSpeedDialButton(
          icon: Icons.gps_fixed,
          label: 'Centralizar GPS',
          backgroundColor: const Color(0xFF29B6F6),
          onPressed: widget.onCentralizarGps,
        ),
        
        // Botão Apagar Desenho
        _buildSpeedDialButton(
          icon: Icons.delete,
          label: 'Apagar Desenho',
          backgroundColor: const Color(0xFFE53935),
          onPressed: widget.onApagarDesenho,
        ),
      ],
    );
  }

  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botão
          FloatingActionButton(
            mini: true,
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 