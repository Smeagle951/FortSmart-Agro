import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Widget de marcador de coleta de chuva
/// Ícone de gota de água clicável para registrar dados de chuva
class RainCollectionMarker extends StatefulWidget {
  final LatLng position;
  final String? rainStationId;
  final String? stationName;
  final double? lastRainfall;
  final DateTime? lastUpdate;
  final VoidCallback? onTap;
  final bool isActive;

  const RainCollectionMarker({
    Key? key,
    required this.position,
    this.rainStationId,
    this.stationName,
    this.lastRainfall,
    this.lastUpdate,
    this.onTap,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<RainCollectionMarker> createState() => _RainCollectionMarkerState();
}

class _RainCollectionMarkerState extends State<RainCollectionMarker>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Iniciar animações se estiver ativo
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPressed = true;
        });
        
        // Feedback tátil
        HapticFeedback.lightImpact();
        
        // Chamar callback após delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (widget.onTap != null) {
            widget.onTap!();
          }
        });
        
        // Resetar estado de pressionado
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isPressed = false;
            });
          }
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Efeito de ondulação
              if (widget.isActive)
                Transform.scale(
                  scale: _rippleAnimation.value * 2.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(
                        (1.0 - _rippleAnimation.value) * 0.3,
                      ),
                    ),
                  ),
                ),
              
              // Ícone principal
              Transform.scale(
                scale: _isPressed ? 0.9 : (_pulseAnimation.value * (widget.isActive ? 1.0 : 0.8)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getMarkerColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getMarkerColor().withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '🌧',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              
              // Indicador de dados recentes
              if (widget.lastUpdate != null && 
                  DateTime.now().difference(widget.lastUpdate!).inHours < 24)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getMarkerColor() {
    if (!widget.isActive) return Colors.grey;
    
    if (widget.lastRainfall == null) return Colors.blue;
    
    // Cores baseadas na quantidade de chuva
    if (widget.lastRainfall! > 20) return Colors.red; // Chuva forte
    if (widget.lastRainfall! > 10) return Colors.orange; // Chuva moderada
    if (widget.lastRainfall! > 5) return Colors.yellow; // Chuva leve
    return Colors.blue; // Pouca ou nenhuma chuva
  }
}

/// Widget de popup de informações da estação de chuva
class RainStationPopup extends StatelessWidget {
  final String? stationName;
  final double? lastRainfall;
  final DateTime? lastUpdate;
  final VoidCallback? onRegisterRain;
  final VoidCallback? onViewHistory;

  const RainStationPopup({
    Key? key,
    this.stationName,
    this.lastRainfall,
    this.lastUpdate,
    this.onRegisterRain,
    this.onViewHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName ?? 'Estação de Chuva',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Ponto de Coleta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dados de chuva
          if (lastRainfall != null) ...[
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Última Chuva: ${lastRainfall!.toStringAsFixed(1)}mm',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Data da última atualização
          if (lastUpdate != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Atualizado: ${_formatDateTime(lastUpdate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRegisterRain,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Registrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewHistory,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Histórico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}
