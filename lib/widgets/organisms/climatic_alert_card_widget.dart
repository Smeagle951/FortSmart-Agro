import 'package:flutter/material.dart';
import '../../models/organism_catalog_v3.dart';
import '../../services/fortsmart_ai_v3_integration.dart';

/// Widget para exibir card de alerta climático usando dados v3.0
class ClimaticAlertCardWidget extends StatelessWidget {
  final OrganismCatalogV3 organismo;
  final double temperaturaAtual;
  final double umidadeAtual;
  final VoidCallback? onTap;

  const ClimaticAlertCardWidget({
    Key? key,
    required this.organismo,
    required this.temperaturaAtual,
    required this.umidadeAtual,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (organismo.climaticConditions == null) {
      return const SizedBox.shrink();
    }

    final alerta = FortSmartAIV3Integration.gerarAlertaClimatico(
      organismo: organismo,
      temperaturaAtual: temperaturaAtual,
      umidadeAtual: umidadeAtual,
      cultura: organismo.cropName,
    );

    final risco = alerta['risco'] as double;
    
    // Mostrar apenas se risco >= 0.4
    if (risco < 0.4) {
      return const SizedBox.shrink();
    }

    Color corNivel;
    IconData icone;
    
    if (risco >= 0.7) {
      corNivel = Colors.red;
      icone = Icons.warning;
    } else {
      corNivel = Colors.orange;
      icone = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone de alerta
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: corNivel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: corNivel, size: 24),
              ),
              
              const SizedBox(width: 12),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organismo.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerta['nivel'] as String,
                      style: TextStyle(
                        color: corNivel,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risco: ${(risco * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Condições atuais
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${temperaturaAtual.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${umidadeAtual.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
}

