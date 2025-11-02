import 'package:flutter/material.dart';
import '../../models/organism_catalog_v3.dart';
import '../../services/fortsmart_ai_v3_integration.dart';

/// Widget para exibir análise de risco de resistência
class ResistanceAnalysisWidget extends StatelessWidget {
  final OrganismCatalogV3 organismo;
  final List<String> produtosUsados;

  const ResistanceAnalysisWidget({
    Key? key,
    required this.organismo,
    required this.produtosUsados,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (organismo.resistanceRotation == null) {
      return const SizedBox.shrink();
    }

    final analise = FortSmartAIV3Integration.analisarRiscoResistencia(
      organismo: organismo,
      produtosUsados: produtosUsados,
    );

    final risco = analise['risco'] as double;
    final gruposUsados = analise['grupos_usados'] as List<String>;
    final estrategias = analise['estrategias'] as List<String>;
    final recomendacao = analise['recomendacao'] as String;

    Color corRisco;
    if (risco >= 0.7) {
      corRisco = Colors.red;
    } else if (risco >= 0.4) {
      corRisco = Colors.orange;
    } else {
      corRisco = Colors.green;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: corRisco),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Resistência',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Risco
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Risco de Resistência:'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: corRisco.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(risco * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: corRisco,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (gruposUsados.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Grupos IRAC já utilizados:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: gruposUsados.map((grupo) {
                  return Chip(
                    label: Text('IRAC $grupo'),
                    backgroundColor: Colors.orange[100],
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 12),
            Text(
              recomendacao,
              style: TextStyle(
                color: corRisco,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            if (estrategias.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Estratégias recomendadas:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...estrategias.map((estrategia) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        estrategia,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

