import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../widgets/ai_prediction_card.dart';
import '../widgets/ai_models_status.dart';
import '../widgets/ai_recommendations_panel.dart';

/// Dashboard de IA para o FortSmart Agro
class AIDashboardScreen extends StatefulWidget {
  const AIDashboardScreen({super.key});

  @override
  State<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen> {
  final AIService _aiService = AIService();
  bool _isLoading = false;
  Map<String, dynamic>? _dashboardData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simular carregamento de dados do dashboard
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _dashboardData = {
          'total_predictions': 45,
          'accuracy_rate': 87.5,
          'models_status': {
            'pest_detection': 'active',
            'germination_analysis': 'active',
            'weather_prediction': 'training'
          },
          'recent_predictions': [
            {
              'talhao_id': 'T001',
              'cultura': 'Soja',
              'risk_level': 'Médio',
              'confidence': 0.82,
              'timestamp': DateTime.now().subtract(const Duration(hours: 2))
            },
            {
              'talhao_id': 'T002', 
              'cultura': 'Milho',
              'risk_level': 'Baixo',
              'confidence': 0.91,
              'timestamp': DateTime.now().subtract(const Duration(hours: 4))
            }
          ]
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de IA'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Erro desconhecido',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo geral
          _buildSummaryCards(),
          
          const SizedBox(height: 24),
          
          // Status dos modelos
          AIModelsStatusWidget(
            modelsStatus: _dashboardData?['models_status'] ?? {},
          ),
          
          const SizedBox(height: 24),
          
          // Predições recentes
          _buildRecentPredictions(),
          
          const SizedBox(height: 24),
          
          // Recomendações
          AIRecommendationsPanel(
            recommendations: [
              'Monitorar talhão T001 - risco médio detectado',
              'Aplicar tratamento preventivo em T003',
              'Verificar condições climáticas para próxima semana',
              'Re-treinar modelo de germinação com novos dados'
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ações rápidas
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Predições Hoje',
            value: '${_dashboardData?['total_predictions'] ?? 0}',
            icon: Icons.psychology,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Precisão',
            value: '${_dashboardData?['accuracy_rate'] ?? 0}%',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPredictions() {
    final predictions = _dashboardData?['recent_predictions'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Predições Recentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (predictions.isEmpty)
              const Text('Nenhuma predição recente')
            else
              ...predictions.map((pred) => _buildPredictionItem(pred)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(Map<String, dynamic> prediction) {
    final riskLevel = prediction['risk_level'] ?? 'Desconhecido';
    final confidence = prediction['confidence'] ?? 0.0;
    final talhaoId = prediction['talhao_id'] ?? 'N/A';
    final cultura = prediction['cultura'] ?? 'N/A';
    final timestamp = prediction['timestamp'] as DateTime?;
    
    Color riskColor = _getRiskColor(riskLevel);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talhão $talhaoId - $cultura',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Risco: $riskLevel (${(confidence * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  label: 'Nova Predição',
                  icon: Icons.add,
                  onTap: () => _showNewPredictionDialog(),
                ),
                _buildActionChip(
                  label: 'Re-treinar Modelos',
                  icon: Icons.refresh,
                  onTap: () => _retrainModels(),
                ),
                _buildActionChip(
                  label: 'Exportar Dados',
                  icon: Icons.download,
                  onTap: () => _exportData(),
                ),
                _buildActionChip(
                  label: 'Configurações',
                  icon: Icons.settings,
                  onTap: () => _showSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
    );
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 1) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours}h';
    } else {
      return 'Há ${difference.inDays} dias';
    }
  }

  void _showNewPredictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Predição'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _retrainModels() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Re-treinamento iniciado em background'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSettings() {
    Navigator.pushNamed(context, '/ai_settings');
  }
}
