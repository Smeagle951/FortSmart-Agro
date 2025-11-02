import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/planting_quality_report_model.dart';
import '../../../../utils/fortsmart_theme.dart';

/// Widget para exibir relatório de qualidade de plantio
class PlantingQualityReportWidget extends StatelessWidget {
  final PlantingQualityReportModel relatorio;
  final bool showFullReport;
  final VoidCallback? onTap;

  const PlantingQualityReportWidget({
    Key? key,
    required this.relatorio,
    this.showFullReport = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              _buildCabecalho(),
              
              const SizedBox(height: 16),
              
              // Métricas principais
              _buildMetricasPrincipais(),
              
              if (showFullReport) ...[
                const SizedBox(height: 16),
                
                // Análise automática
                _buildAnaliseAutomatica(),
                
                const SizedBox(height: 16),
                
                // Gráficos
                _buildGraficos(),
              ],
              
              const SizedBox(height: 16),
              
              // Rodapé
              _buildRodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FortSmartTheme.primaryColor,
            FortSmartTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Relatório FortSmart – Qualidade de Plantio',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '🌱 ${relatorio.talhaoNome}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${relatorio.emojiStatusGeral} ${relatorio.statusGeral}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasPrincipais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Qualidade de Plantio',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // CV%
        _buildMetricaRow(
          'CV – Coeficiente de Variação',
          '${relatorio.coeficienteVariacao.toStringAsFixed(2)}%',
          relatorio.emojiCV,
          relatorio.classificacaoCV,
          Color(int.parse(relatorio.corCV.replaceAll('#', '0xFF'))),
        ),
        
        const SizedBox(height: 8),
        
        // Singulação
        _buildMetricaRow(
          'Singulação',
          '${relatorio.singulacao.toStringAsFixed(2)}%',
          relatorio.singulacao >= 95 ? '✅' : '⚠️',
          relatorio.singulacao >= 95 ? 'Excelente' : 'Boa',
          Color(int.parse(relatorio.corSingulacao.replaceAll('#', '0xFF'))),
        ),
        
        const SizedBox(height: 8),
        
        // Plantas por hectare
        _buildMetricaRow(
          'Plantas por hectare',
          '${NumberFormat('#,###').format(relatorio.populacaoEstimadaPorHectare)} plantas/ha',
          '🌱',
          'População estimada',
          Colors.green,
        ),
        
        const SizedBox(height: 8),
        
        // Plantas por metro
        _buildMetricaRow(
          'Plantas por metro',
          '${relatorio.plantasPorMetro.toStringAsFixed(1)} plantas/m',
          '📏',
          'Densidade linear',
          Colors.blue,
        ),
        
        const SizedBox(height: 8),
        
        // Plantas duplas
        _buildMetricaRow(
          '% Plantas duplas',
          '${relatorio.plantasDuplas.toStringAsFixed(2)}%',
          relatorio.plantasDuplas <= 3 ? '✅' : '⚠️',
          relatorio.plantasDuplas <= 3 ? 'Aceitável' : 'Atenção',
          relatorio.plantasDuplas <= 3 ? Colors.green : Colors.orange,
        ),
        
        const SizedBox(height: 8),
        
        // Plantas falhadas
        _buildMetricaRow(
          '% Plantas falhadas',
          '${relatorio.plantasFalhadas.toStringAsFixed(2)}%',
          relatorio.plantasFalhadas <= 3 ? '✅' : '⚠️',
          relatorio.plantasFalhadas <= 3 ? 'Aceitável' : 'Atenção',
          relatorio.plantasFalhadas <= 3 ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricaRow(String titulo, String valor, String emoji, String status, Color cor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnaliseAutomatica() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber[700], size: 16),
              const SizedBox(width: 8),
              Text(
                '📌 Análise Automática FortSmart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            relatorio.analiseAutomatica,
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Gráficos de Análise',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Gráfico de pizza simplificado
        _buildGraficoPizzaSimples(),
        
        const SizedBox(height: 12),
        
        // Gráfico de barras simplificado
        _buildGraficoBarrasSimples(),
      ],
    );
  }

  Widget _buildGraficoPizzaSimples() {
    final correto = 100 - relatorio.plantasDuplas - relatorio.plantasFalhadas;
    
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Colors.green,
                Colors.green,
                Colors.orange,
                Colors.orange,
                Colors.red,
                Colors.red,
                Colors.green,
              ],
              stops: [
                0.0,
                correto / 100,
                correto / 100,
                (correto + relatorio.plantasDuplas) / 100,
                (correto + relatorio.plantasDuplas) / 100,
                1.0,
                1.0,
              ],
            ),
          ),
          child: Center(
            child: Text(
              '${correto.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendaItem('Correto', correto, Colors.green),
              _buildLegendaItem('Duplas', relatorio.plantasDuplas, Colors.orange),
              _buildLegendaItem('Falhas', relatorio.plantasFalhadas, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendaItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${value.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarrasSimples() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                'Alvo',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 40,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    '${(relatorio.populacaoAlvo / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Real',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: (relatorio.populacaoReal / relatorio.populacaoAlvo) * 40,
                width: 30,
                decoration: BoxDecoration(
                  color: Color(int.parse(relatorio.corStatusPopulacao.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    '${(relatorio.populacaoReal / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Dados registrados via FortSmart App',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Coleta em: ${DateFormat('dd/MM/yyyy – HH:mm').format(relatorio.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
