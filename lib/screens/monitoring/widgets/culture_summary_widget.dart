import 'package:flutter/material.dart';

/// Widget responsável por exibir o resumo da cultura selecionada
class CultureSummaryWidget extends StatelessWidget {
  final String cropName;
  final int pestCount;
  final int diseaseCount;
  final int weedCount;
  final VoidCallback? onTap;

  const CultureSummaryWidget({
    Key? key,
    required this.cropName,
    required this.pestCount,
    required this.diseaseCount,
    required this.weedCount,
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
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.green.shade200,
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
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.agriculture,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cultura Selecionada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    cropName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildCountChip('$pestCount pragas', Colors.red.shade100, Colors.red.shade700),
                      const SizedBox(width: 8.0),
                      _buildCountChip('$diseaseCount doenças', Colors.orange.shade100, Colors.orange.shade700),
                      const SizedBox(width: 8.0),
                      _buildCountChip('$weedCount daninhas', Colors.purple.shade100, Colors.purple.shade700),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.green.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
