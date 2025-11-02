import 'package:flutter/material.dart';
import '../../../models/ponto_monitoramento_model.dart';

class PointMonitoringFooter extends StatelessWidget {
  final PontoMonitoramentoModel? currentPoint;
  final PontoMonitoramentoModel? nextPoint;
  final bool hasArrived;
  final double? distanceToPoint;
  final bool isLastPoint;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onNewOccurrence;
  final VoidCallback onFinish;
  final VoidCallback? onSaveAndContinue;

  const PointMonitoringFooter({
    Key? key,
    this.currentPoint,
    this.nextPoint,
    this.hasArrived = false,
    this.distanceToPoint,
    this.isLastPoint = false,
    required this.onPrevious,
    required this.onNext,
    required this.onNewOccurrence,
    required this.onFinish,
    this.onSaveAndContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canNavigateNext = hasArrived && (distanceToPoint == null || distanceToPoint! <= 5.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Linha de status da distância
              _buildDistanceStatus(),
              const SizedBox(height: 16),
              
              // Botões principais
              Row(
                children: [
                  // Botão Nova Ocorrência
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('🔥 BOTÃO NOVA OCORRÊNCIA PRESSIONADO!');
                        print('🔥 Callback: $onNewOccurrence');
                        onNewOccurrence();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nova Ocorrência'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D9CDB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botões de navegação
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Botão Anterior
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _canGoPrevious() ? onPrevious : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            label: const Text('Anterior'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2C2C2C),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Botão Salvar & Avançar ou Próximo/Finalizar
                        Expanded(
                          child: isLastPoint
                              ? ElevatedButton.icon(
                                  onPressed: onFinish,
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Finalizar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27AE60),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: canNavigateNext ? (onSaveAndContinue ?? onNext) : null,
                                  icon: const Icon(Icons.save_alt, size: 16),
                                  label: const Text('Salvar & Avançar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canNavigateNext 
                                        ? const Color(0xFF27AE60)
                                        : const Color(0xFF95A5A6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceStatus() {
    if (distanceToPoint == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.gps_not_fixed,
              color: Color(0xFF95A5A6),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Aguardando localização GPS...',
              style: TextStyle(
                color: Color(0xFF95A5A6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final distanceText = 'Distância: ${distanceToPoint!.toStringAsFixed(1)} m';
    final statusColor = _getDistanceStatusColor(distanceToPoint!);
    final statusIcon = _getDistanceStatusIcon(distanceToPoint!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            distanceText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasArrived) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'CHEGOU!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDistanceStatusColor(double distance) {
    if (distance <= 5.0) {
      return const Color(0xFF27AE60); // Verde
    } else if (distance <= 20.0) {
      return const Color(0xFFF2C94C); // Amarelo
    } else {
      return const Color(0xFFEB5757); // Vermelho
    }
  }

  IconData _getDistanceStatusIcon(double distance) {
    if (distance <= 5.0) {
      return Icons.location_on;
    } else if (distance <= 20.0) {
      return Icons.near_me;
    } else {
      return Icons.location_searching;
    }
  }

  bool _canGoPrevious() {
    // Verificar se existe ponto anterior
    return currentPoint != null && currentPoint!.ordem > 1;
  }
}
