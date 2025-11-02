import 'package:flutter/material.dart';

/// Widget responsável por exibir a distância ao ponto de monitoramento
class DistanceBannerWidget extends StatelessWidget {
  final String distance;
  final bool isNearPoint;
  final VoidCallback? onTap;

  const DistanceBannerWidget({
    Key? key,
    required this.distance,
    required this.isNearPoint,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isNearPoint ? Colors.green.shade300 : Colors.blue.shade200,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isNearPoint ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                isNearPoint ? Icons.check_circle : Icons.location_on,
                color: isNearPoint ? Colors.green.shade700 : Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distância ao ponto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    distance,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isNearPoint ? Colors.green.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isNearPoint)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'PRÓXIMO',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
