import 'package:flutter/material.dart';
import '../models/calibracao_fertilizante_model.dart';
import '../services/calibracao_fertilizante_service.dart';

/// Widget para exibir os resultados da calibração de fertilizantes
class CalibracaoFertilizanteResultado extends StatelessWidget {
  final CalibracaoFertilizanteModel calibracao;

  const CalibracaoFertilizanteResultado({
    Key? key,
    required this.calibracao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resultados da Calibração',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Resultados principais
            _buildResultadosPrincipais(),
            
            const SizedBox(height: 16),
            
            // Análise estatística
            _buildAnaliseEstatistica(),
            
            const SizedBox(height: 16),
            
            // Comparação com taxa desejada
            if (calibracao.taxaDesejada != null) ...[
              _buildComparacaoTaxa(),
              const SizedBox(height: 16),
            ],
            
            // Recomendações
            _buildRecomendacoes(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosPrincipais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados Principais',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'Taxa Real',
                '${calibracao.taxaRealKgHa.toStringAsFixed(1)} kg/ha',
                Icons.speed,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResultCard(
                'Coeficiente de Variação',
                '${calibracao.coeficienteVariacao.toStringAsFixed(2)}%',
                Icons.trending_up,
                _getCVColor(calibracao.coeficienteVariacao),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'Faixa Real',
                '${calibracao.faixaReal.toStringAsFixed(1)} m',
                Icons.straighten,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResultCard(
                'Classificação',
                calibracao.classificacaoCV,
                Icons.assessment,
                _getClassificacaoColor(calibracao.classificacaoCV),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnaliseEstatistica() {
    final estatisticas = CalibracaoFertilizanteService.calcularEstatisticas(calibracao.pesos);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise Estatística',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Média',
                '${estatisticas['media']} g',
                Icons.bar_chart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Desvio Padrão',
                '${estatisticas['desvio_padrao']} g',
                Icons.science,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Mínimo',
                '${estatisticas['minimo']} g',
                Icons.keyboard_arrow_down,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Máximo',
                '${estatisticas['maximo']} g',
                Icons.keyboard_arrow_up,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Amplitude',
                '${estatisticas['amplitude']} g',
                Icons.compare_arrows,
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Peso Total',
                '${CalibracaoFertilizanteService.calcularPesoTotalKg(calibracao.pesos).toStringAsFixed(2)} kg',
                Icons.scale,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparacaoTaxa() {
    final eficiencia = CalibracaoFertilizanteService.calcularEficiencia(
      calibracao.taxaRealKgHa, 
      calibracao.taxaDesejada!
    );
    
    final diferenca = calibracao.taxaRealKgHa - calibracao.taxaDesejada!;
    final percentualDiferenca = (diferenca / calibracao.taxaDesejada!) * 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparação com Taxa Desejada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'Taxa Desejada',
                '${calibracao.taxaDesejada!.toStringAsFixed(1)} kg/ha',
                Icons.track_changes,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResultCard(
                'Eficiência',
                '${eficiencia}%',
                Icons.percent,
                _getEficienciaColor(eficiencia),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'Diferença',
                '${diferenca.toStringAsFixed(1)} kg/ha',
                Icons.difference,
                diferenca >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResultCard(
                '% Diferença',
                '${percentualDiferenca.toStringAsFixed(1)}%',
                Icons.trending_up,
                percentualDiferenca.abs() <= 5 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecomendacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendações',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        _buildRecomendacaoItem(
          calibracao.coeficienteVariacao <= 10.0,
          'Distribuição uniforme - Calibração adequada',
          'Distribuição não uniforme - Verificar ajustes',
          Icons.check_circle,
          Icons.warning,
          Colors.green,
          Colors.orange,
        ),
        
        if (calibracao.taxaDesejada != null) ...[
          const SizedBox(height: 8),
          _buildRecomendacaoItem(
            _isTaxaAceitavel(),
            'Taxa dentro da faixa aceitável (±5%)',
            'Taxa fora da faixa aceitável - Ajustar configuração',
            Icons.check_circle,
            Icons.settings,
            Colors.green,
            Colors.red,
          ),
        ],
        
        if (calibracao.faixaEsperada != null) ...[
          const SizedBox(height: 8),
          _buildRecomendacaoItem(
            _isFaixaAceitavel(),
            'Faixa de aplicação adequada',
            'Faixa de aplicação diferente do esperado',
            Icons.check_circle,
            Icons.straighten,
            Colors.green,
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacaoItem(
    bool isAceitavel,
    String mensagemPositiva,
    String mensagemNegativa,
    IconData iconPositivo,
    IconData iconNegativo,
    Color corPositiva,
    Color corNegativa,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isAceitavel ? corPositiva : corNegativa).withOpacity(0.1),
        border: Border.all(
          color: (isAceitavel ? corPositiva : corNegativa).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isAceitavel ? iconPositivo : iconNegativo,
            color: isAceitavel ? corPositiva : corNegativa,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAceitavel ? mensagemPositiva : mensagemNegativa,
              style: TextStyle(
                color: isAceitavel ? corPositiva : corNegativa,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCVColor(double cv) {
    if (cv <= 10.0) return Colors.green;
    if (cv <= 15.0) return Colors.orange;
    return Colors.red;
  }

  Color _getClassificacaoColor(String classificacao) {
    switch (classificacao.toLowerCase()) {
      case 'bom':
        return Colors.green;
      case 'moderado':
        return Colors.orange;
      case 'crítico':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEficienciaColor(double eficiencia) {
    if (eficiencia >= 95.0 && eficiencia <= 105.0) return Colors.green;
    if (eficiencia >= 90.0 && eficiencia <= 110.0) return Colors.orange;
    return Colors.red;
  }

  bool _isTaxaAceitavel() {
    if (calibracao.taxaDesejada == null) return false;
    final eficiencia = CalibracaoFertilizanteService.calcularEficiencia(
      calibracao.taxaRealKgHa, 
      calibracao.taxaDesejada!
    );
    return eficiencia >= 95.0 && eficiencia <= 105.0;
  }

  bool _isFaixaAceitavel() {
    if (calibracao.faixaEsperada == null) return false;
    final diferenca = (calibracao.faixaReal - calibracao.faixaEsperada!).abs();
    final percentualDiferenca = (diferenca / calibracao.faixaEsperada!) * 100;
    return percentualDiferenca <= 10.0; // Aceita até 10% de diferença
  }
}
