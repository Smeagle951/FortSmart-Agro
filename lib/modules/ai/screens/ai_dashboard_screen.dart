import 'package:flutter/material.dart';
import '../services/ai_diagnosis_service.dart';
import '../services/organism_prediction_service.dart';
import '../repositories/ai_organism_repository.dart';
import '../widgets/ai_status_widget.dart';
import '../../../utils/logger.dart';

class AIDashboardScreen extends StatefulWidget {
  const AIDashboardScreen({super.key});

  @override
  State<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen> {
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final OrganismPredictionService _predictionService = OrganismPredictionService();
  final AIOrganismRepository _organismRepository = AIOrganismRepository();

  Map<String, dynamic> _diagnosisStats = {};
  Map<String, dynamic> _organismStats = {};
  Map<String, dynamic> _predictionStats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carregar dados em paralelo
      final futures = await Future.wait([
        _diagnosisService.getDiagnosisStats(),
        _organismRepository.getStats(),
        _getPredictionStats(),
      ]);

      setState(() {
        _diagnosisStats = futures[0];
        _organismStats = futures[1];
        _predictionStats = futures[2];
        _isLoading = false;
      });

    } catch (e) {
      Logger.error('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getPredictionStats() async {
    // Simula dados de predição
    return {
      'totalPredictions': 45,
      'accuracyRate': 0.87,
      'activeAlerts': 3,
      'predictedOutbreaks': 2,
      'optimalApplications': 8,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Dashboard IA'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorMessage()
              : _buildDashboardContent(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            // Card de status do Sistema FortSmart
            const AIStatusCard(
              showDetails: true,
              showMonitorButton: true,
            ),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildAIInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo ao IA FortSmart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema inteligente para diagnóstico e predição agrícola',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Primeira linha
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Organismos',
                '${_organismStats['totalOrganisms'] ?? 0}',
                Icons.bug_report,
                Colors.orange,
                'Pragas e doenças cadastradas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Diagnósticos',
                '${_diagnosisStats['totalDiagnoses'] ?? 0}',
                Icons.medical_services,
                Colors.blue,
                'Análises realizadas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segunda linha
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Predições',
                '${_predictionStats['totalPredictions'] ?? 0}',
                Icons.trending_up,
                Colors.purple,
                'Previsões geradas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Precisão',
                '${((_predictionStats['accuracyRate'] ?? 0.0) * 100).toInt()}%',
                Icons.analytics,
                Colors.green,
                'Taxa de acerto',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return SizedBox(
      height: 120, // Altura fixa para evitar overflow
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Expanded( // Usa Expanded em vez de Flexible para melhor controle
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Diagnóstico',
                Icons.search,
                Colors.blue,
                'Identificar pragas e doenças',
                () => _navigateToDiagnosis(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Predições',
                Icons.trending_up,
                Colors.purple,
                'Ver previsões climáticas',
                () => _navigateToPredictions(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Catálogo',
                Icons.library_books,
                Colors.orange,
                'Explorar organismos',
                () => _navigateToCatalog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Relatórios',
                Icons.assessment,
                Colors.green,
                'Ver estatísticas',
                () => _navigateToReports(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, String description, VoidCallback onTap) {
    return SizedBox(
      height: 100, // Altura fixa para evitar overflow
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Diagnóstico realizado',
                'Lagarta da Soja identificada',
                '2 horas atrás',
                Icons.search,
                Colors.blue,
              ),
              const Divider(),
              _buildActivityItem(
                'Predição gerada',
                'Risco alto para Ferrugem Asiática',
                '5 horas atrás',
                Icons.trending_up,
                Colors.orange,
              ),
              const Divider(),
              _buildActivityItem(
                'Organismo adicionado',
                'Nova praga cadastrada',
                '1 dia atrás',
                Icons.add_circle,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights da IA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.green[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recomendações Inteligentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInsightItem(
                'Monitoramento intensivo recomendado para Soja',
                'Baseado nas condições climáticas atuais',
              ),
              const SizedBox(height: 8),
              _buildInsightItem(
                'Aplicação preventiva de fungicidas',
                'Risco de Ferrugem Asiática detectado',
              ),
              const SizedBox(height: 8),
              _buildInsightItem(
                'Período ideal para aplicação: próxima semana',
                'Condições climáticas favoráveis previstas',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 16, color: Colors.green)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToDiagnosis() {
    // TODO: Implementar navegação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegação para diagnóstico em desenvolvimento')),
    );
  }

  void _navigateToPredictions() {
    // TODO: Implementar navegação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegação para predições em desenvolvimento')),
    );
  }

  void _navigateToCatalog() {
    // TODO: Implementar navegação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegação para catálogo em desenvolvimento')),
    );
  }

  void _navigateToReports() {
    // TODO: Implementar navegação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegação para relatórios em desenvolvimento')),
    );
  }
}
