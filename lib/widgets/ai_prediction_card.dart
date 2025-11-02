import 'package:flutter/material.dart';
import '../services/ai_service.dart';

/// Widget para exibir predições de IA
class AIPredictionCard extends StatefulWidget {
  final String talhaoId;
  final String cultura;
  final double areaHa;
  final double? temperatura;
  final double? umidade;
  final double? precipitacao7d;
  final double? latitude;
  final double? longitude;

  const AIPredictionCard({
    super.key,
    required this.talhaoId,
    required this.cultura,
    required this.areaHa,
    this.temperatura,
    this.umidade,
    this.precipitacao7d,
    this.latitude,
    this.longitude,
  });

  @override
  State<AIPredictionCard> createState() => _AIPredictionCardState();
}

class _AIPredictionCardState extends State<AIPredictionCard> {
  final AIService _aiService = AIService();
  Map<String, dynamic>? _prediction;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prediction = await _aiService.predictInfestationRisk(
        talhaoId: widget.talhaoId,
        cultura: widget.cultura,
        areaHa: widget.areaHa,
        temperatura: widget.temperatura,
        umidade: widget.umidade,
        precipitacao7d: widget.precipitacao7d,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Alto':
        return Colors.red;
      case 'Médio':
        return Colors.orange;
      case 'Baixo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'Alto':
        return Icons.warning;
      case 'Médio':
        return Icons.info;
      case 'Baixo':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Predição de IA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPrediction,
                    tooltip: 'Atualizar predição',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Conteúdo da predição
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildErrorWidget()
            else if (_prediction != null)
              _buildPredictionContent()
            else
              _buildEmptyWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro na predição',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? 'Erro desconhecido',
            style: TextStyle(color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadPrediction,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            color: Colors.grey.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma predição disponível',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em "Atualizar" para obter uma predição',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionContent() {
    final riskLevel = _prediction!['risk_level'] ?? 'Desconhecido';
    final riskScore = _prediction!['risk_score'] ?? 0.0;
    final recommendations = _prediction!['recommendations'] as List<dynamic>? ?? [];
    final source = _prediction!['source'] ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nível de risco
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getRiskColor(riskLevel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getRiskColor(riskLevel).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getRiskIcon(riskLevel),
                color: _getRiskColor(riskLevel),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risco de Infestação: $riskLevel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(riskLevel),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${(riskScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getRiskColor(riskLevel).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Recomendações
        if (recommendations.isNotEmpty) ...[
          Text(
            'Recomendações:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
        
        const SizedBox(height: 16),
        
        // Fonte da predição
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                source == 'local_tflite' ? Icons.phone_android : 
                source == 'remote_api' ? Icons.cloud : Icons.rule,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                source == 'local_tflite' ? 'IA Local' :
                source == 'remote_api' ? 'IA Remota' : 'Regras',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
