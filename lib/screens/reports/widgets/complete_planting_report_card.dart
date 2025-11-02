import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 📋 Card Completo de Plantio para Relatórios
/// 
/// Exibe todas as informações de um plantio em um card clicável:
/// - Dados básicos (talhão, cultura, variedade, data)
/// - População real (do estande)
/// - Eficiência e CV%
/// - Status fenológico
/// - Qualidade dos dados

class CompletePlantingReportCard extends StatelessWidget {
  final Map<String, dynamic> plantioData;
  final VoidCallback? onTap;
  
  const CompletePlantingReportCard({
    Key? key,
    required this.plantioData,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final talhaoNome = plantioData['talhao_nome'] ?? 'Talhão não identificado';
    final culturaId = plantioData['cultura_id'] ?? 'Cultura não identificada';
    final variedadeId = plantioData['variedade_id'] ?? 'Variedade não definida';
    final dataPlantio = DateTime.parse(plantioData['data_plantio']);
    final diasPlantio = plantioData['dias_apos_plantio'] ?? 0;
    
    // Dados do estande
    final estande = plantioData['estande'] as Map<String, dynamic>? ?? {};
    final temEstande = estande['tem_dados'] == true;
    
    // Dados de CV%
    final cv = plantioData['cv_uniformidade'] as Map<String, dynamic>? ?? {};
    final temCV = cv['tem_dados'] == true;
    
    // Dados fenológicos
    final fenologia = plantioData['evolucao_fenologica'] as Map<String, dynamic>? ?? {};
    final temFenologia = fenologia['tem_dados'] == true;
    
    // Qualidade dos dados
    final metricas = plantioData['metricas_calculadas'] as Map<String, dynamic>? ?? {};
    final completude = metricas['completude_dados_percentual'] ?? 0;
    final populacaoFinal = metricas['populacao_final'] ?? 0;
    final populacaoTipo = metricas['populacao_tipo'] ?? 'DESCONHECIDO';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getCompletudeBorderColor(completude),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Talhão e Cultura
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talhaoNome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          culturaId,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de qualidade
                  _buildQualidadeBadge(completude),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informações principais
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.eco,
                      label: 'Variedade',
                      value: variedadeId,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: DateFormat('dd/MM/yy').format(dataPlantio),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'DAP',
                      value: '$diasPlantio dias',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // População
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: populacaoTipo == 'REAL_ESTANDE' 
                      ? Colors.green.shade50 
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: populacaoTipo == 'REAL_ESTANDE' 
                        ? Colors.green.shade300 
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      populacaoTipo == 'REAL_ESTANDE' 
                          ? Icons.check_circle 
                          : Icons.warning,
                      color: populacaoTipo == 'REAL_ESTANDE' 
                          ? Colors.green.shade700 
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            populacaoTipo == 'REAL_ESTANDE' 
                                ? 'População Real (Estande)' 
                                : 'População Planejada',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: populacaoTipo == 'REAL_ESTANDE' 
                                  ? Colors.green.shade700 
                                  : Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatPopulation(populacaoFinal)} plantas/ha',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: populacaoTipo == 'REAL_ESTANDE' 
                                  ? Colors.green.shade900 
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (temEstande && estande['eficiencia_percentual'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEficienciaColor(estande['eficiencia_percentual']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${estande['eficiencia_percentual'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Indicadores de dados disponíveis
              Row(
                children: [
                  _buildIndicadorDado(
                    'Estande',
                    temEstande,
                    Icons.straighten,
                  ),
                  const SizedBox(width: 8),
                  _buildIndicadorDado(
                    'CV%',
                    temCV,
                    Icons.analytics,
                  ),
                  const SizedBox(width: 8),
                  _buildIndicadorDado(
                    'Fenologia',
                    temFenologia,
                    Icons.nature,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildQualidadeBadge(int completude) {
    final color = _getCompletudeBorderColor(completude);
    final label = completude >= 80 
        ? 'Completo' 
        : completude >= 50 
            ? 'Parcial' 
            : 'Básico';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.data_usage, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicadorDado(String label, bool disponivel, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: disponivel ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: disponivel ? Colors.green.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: disponivel ? Colors.green.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCompletudeBorderColor(int completude) {
    if (completude >= 80) return Colors.green;
    if (completude >= 50) return Colors.orange;
    return Colors.grey;
  }
  
  Color _getEficienciaColor(double eficiencia) {
    if (eficiencia >= 90) return Colors.green;
    if (eficiencia >= 75) return Colors.lightGreen;
    if (eficiencia >= 60) return Colors.orange;
    return Colors.red;
  }
  
  String _formatPopulation(num population) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}k';
    }
    return population.toStringAsFixed(0);
  }
}

