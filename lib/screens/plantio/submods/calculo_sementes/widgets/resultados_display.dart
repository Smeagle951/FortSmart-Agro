import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../models/seed_calc_result.dart';
import '../models/calculo_sementes_state.dart';

/// Widget para exibição dos resultados
class ResultadosDisplay extends StatelessWidget {
  final SeedCalcResult? resultado;
  final ModoCalculo modoCalculo;

  const ResultadosDisplay({
    Key? key,
    this.resultado,
    required this.modoCalculo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0.00", "pt_BR");
    final numberFormatInt = NumberFormat("#,##0", "pt_BR");
    
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 Resultados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FortSmartTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Cálculo Neutro (sem correção)\n'
                      'Sementes/ha = (Sementes/m × 10.000) / Espaçamento\n'
                      'Kg/ha = Sementes/ha × PMS (g/semente) / 1000\n'
                      '⚠️ Germinação e Vigor são apenas informativos',
                  child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            if (resultado != null) ...[
              // Resultados principais
              Text(
                'Cálculos por Hectare',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildResultadoItem('⚖️ PMS (g/1000)', numberFormat.format(resultado!.pms_g_per_1000)),
              _buildResultadoItem('🌱 Sementes/ha', numberFormatInt.format(resultado!.seedsPerHa)),
              _buildResultadoItem('⚖️ Kg/ha', numberFormat.format(resultado!.kgPerHa)),
              _buildResultadoItem('📏 Hectares cobertos', numberFormat.format(resultado!.hectaresCovered)),
              
              // Cálculos para área específica (sempre visível)
              const Divider(),
              Text(
                'Necessidade para Área Informada',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              if (resultado!.totalKgForN > 0) ...[
                _buildResultadoItemDestaque('📦 Kg necessários', numberFormat.format(resultado!.totalKgForN), Colors.green),
                _buildResultadoItemDestaque('🌱 Sementes necessárias', numberFormatInt.format(resultado!.totalSeedsForN), Colors.green),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Marque "Calcular para área específica" e informe a área para calcular a necessidade de sementes',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FortSmartTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FortSmartTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Resumo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FortSmartTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Com os parâmetros informados, você cobre ${numberFormat.format(resultado!.hectaresCovered)} hectares.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (resultado!.totalKgForN > 0)
                      Text(
                        'Para a área desejada, você precisa de ${numberFormat.format(resultado!.totalKgForN)} kg de sementes.',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Clique em "Calcular" para ver os resultados',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultadoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FortSmartTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoItemDestaque(String label, String value, Color cor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
