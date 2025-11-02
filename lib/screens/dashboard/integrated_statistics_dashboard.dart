import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/plantio_integration_service.dart';
import '../../services/safra_validation_service.dart';
import '../../services/fortsmart_notification_service.dart';
import '../../widgets/fortsmart_notification_widget.dart';
import '../../utils/app_theme.dart';

/// Dashboard de Estatísticas Integradas do FortSmart Agro
/// Visão consolidada de todos os módulos com gráficos interativos
class IntegratedStatisticsDashboard extends StatefulWidget {
  const IntegratedStatisticsDashboard({super.key});

  @override
  State<IntegratedStatisticsDashboard> createState() => _IntegratedStatisticsDashboardState();
}

class _IntegratedStatisticsDashboardState extends State<IntegratedStatisticsDashboard>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final PlantioIntegrationService _plantioService = PlantioIntegrationService();
  final SafraValidationService _safraService = SafraValidationService();
  final FortSmartNotificationService _notificationService = FortSmartNotificationService();

  // Dados do dashboard
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _comparativoSafras;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Inicializa o dashboard
  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);
    
    try {
      // Inicializar serviço de notificações
      await _notificationService.initialize();
      
      // Carregar dados do dashboard
      await _loadDashboardData();
      
      // Carregar comparativo de safras
      await _loadSafraComparison();
      
    } catch (e) {
      print('❌ DASHBOARD: Erro ao inicializar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega dados do dashboard
  Future<void> _loadDashboardData() async {
    try {
      final plantios = await _plantioService.buscarPlantiosIntegrados();
      final relatorioSafra = await _safraService.gerarRelatorioValidacaoSafra(
        dataInicio: DateTime.now().subtract(const Duration(days: 365)),
        dataFim: DateTime.now(),
      );

      setState(() {
        _dashboardData = {
          'plantios': plantios,
          'relatorio_safra': relatorioSafra,
          'resumo': _generateDashboardSummary(plantios, relatorioSafra),
        };
      });
    } catch (e) {
      print('❌ DASHBOARD: Erro ao carregar dados: $e');
    }
  }

  /// Carrega comparativo de safras
  Future<void> _loadSafraComparison() async {
    try {
      // Safra atual (últimos 12 meses)
      final safraAtual = await _safraService.gerarRelatorioValidacaoSafra(
        dataInicio: DateTime.now().subtract(const Duration(days: 365)),
        dataFim: DateTime.now(),
      );

      // Safra anterior (12-24 meses atrás)
      final safraAnterior = await _safraService.gerarRelatorioValidacaoSafra(
        dataInicio: DateTime.now().subtract(const Duration(days: 730)),
        dataFim: DateTime.now().subtract(const Duration(days: 365)),
      );

      setState(() {
        _comparativoSafras = {
          'atual': safraAtual,
          'anterior': safraAnterior,
          'comparacao': _generateSafraComparison(safraAtual, safraAnterior),
        };
      });
    } catch (e) {
      print('❌ DASHBOARD: Erro ao carregar comparativo: $e');
    }
  }

  /// Gera resumo do dashboard
  Map<String, dynamic> _generateDashboardSummary(List<PlantioIntegrado> plantios, Map<String, dynamic> relatorio) {
    final stats = relatorio['estatisticas_gerais'] as Map<String, dynamic>? ?? {};
    final qualidade = relatorio['qualidade_dados'] as Map<String, dynamic>? ?? {};
    
    return {
      'total_plantios': plantios.length,
      'culturas_ativas': (stats['culturas'] as Map<String, dynamic>? ?? {}).length,
      'talhoes_utilizados': (stats['talhoes'] as Map<String, dynamic>? ?? {}).length,
      'score_qualidade': qualidade['score'] ?? 0,
      'nivel_qualidade': qualidade['nivel'] ?? 'BAIXO',
      'plantios_por_fonte': _groupPlantiosBySource(plantios),
      'culturas_distribuicao': stats['culturas'] ?? {},
      'tendencia_mensal': _calculateMonthlyTrend(plantios),
    };
  }

  /// Agrupa plantios por fonte
  Map<String, int> _groupPlantiosBySource(List<PlantioIntegrado> plantios) {
    final grouped = <String, int>{};
    for (final plantio in plantios) {
      grouped[plantio.fonte] = (grouped[plantio.fonte] ?? 0) + 1;
    }
    return grouped;
  }

  /// Calcula tendência mensal
  List<Map<String, dynamic>> _calculateMonthlyTrend(List<PlantioIntegrado> plantios) {
    final monthlyData = <String, int>{};
    
    for (final plantio in plantios) {
      final monthKey = '${plantio.dataPlantio.year}-${plantio.dataPlantio.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }
    
    return monthlyData.entries.map((entry) => {
      'mes': entry.key,
      'plantios': entry.value,
    }).toList()..sort((a, b) => (a['mes'] as String).compareTo(b['mes'] as String));
  }

  /// Gera comparação entre safras
  Map<String, dynamic> _generateSafraComparison(Map<String, dynamic> atual, Map<String, dynamic> anterior) {
    final statsAtual = atual['estatisticas_gerais'] as Map<String, dynamic>? ?? {};
    final statsAnterior = anterior['estatisticas_gerais'] as Map<String, dynamic>? ?? {};
    
    final plantiosAtual = statsAtual['total_plantios'] ?? 0;
    final plantiosAnterior = statsAnterior['total_plantios'] ?? 0;
    
    final culturasAtual = (statsAtual['culturas'] as Map<String, dynamic>? ?? {}).length;
    final culturasAnterior = (statsAnterior['culturas'] as Map<String, dynamic>? ?? {}).length;
    
    return {
      'plantios': {
        'atual': plantiosAtual,
        'anterior': plantiosAnterior,
        'variacao': plantiosAnterior > 0 ? ((plantiosAtual - plantiosAnterior) / plantiosAnterior * 100) : 0,
      },
      'culturas': {
        'atual': culturasAtual,
        'anterior': culturasAnterior,
        'variacao': culturasAnterior > 0 ? ((culturasAtual - culturasAnterior) / culturasAnterior * 100) : 0,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Integrado - FortSmart Agro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Comparativo'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _initializeDashboard(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisaoGeral(),
                _buildTendencias(),
                _buildComparativo(),
              ],
            ),
    );
  }

  /// Constrói aba de visão geral
  Widget _buildVisaoGeral() {
    if (_dashboardData == null) {
      return const Center(child: Text('Carregando dados...'));
    }

    final resumo = _dashboardData!['resumo'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget de notificações
          const FortSmartNotificationWidget(),
          
          const SizedBox(height: 16),
          
          // Cards de métricas principais
          _buildMetricsCards(resumo),
          
          const SizedBox(height: 24),
          
          // Gráfico de distribuição por fonte
          _buildSourceDistributionChart(resumo['plantios_por_fonte'] as Map<String, int>),
          
          const SizedBox(height: 24),
          
          // Gráfico de culturas
          _buildCulturesChart(resumo['culturas_distribuicao'] as Map<String, dynamic>),
        ],
      ),
    );
  }

  /// Constrói cards de métricas
  Widget _buildMetricsCards(Map<String, dynamic> resumo) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total de Plantios',
          resumo['total_plantios'].toString(),
          Icons.agriculture,
          Colors.green,
        ),
        _buildMetricCard(
          'Culturas Ativas',
          resumo['culturas_ativas'].toString(),
          Icons.grass,
          Colors.blue,
        ),
        _buildMetricCard(
          'Talhões Utilizados',
          resumo['talhoes_utilizados'].toString(),
          Icons.location_on,
          Colors.orange,
        ),
        _buildMetricCard(
          'Qualidade dos Dados',
          '${resumo['score_qualidade']}%',
          Icons.assessment,
          _getQualityColor(resumo['score_qualidade']),
        ),
      ],
    );
  }

  /// Constrói card de métrica
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói gráfico de distribuição por fonte
  Widget _buildSourceDistributionChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição por Fonte de Dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    final color = _getSourceColor(entry.key);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      color: color,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.entries.map((entry) {
                final color = _getSourceColor(entry.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSourceLabel(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói gráfico de culturas
  Widget _buildCulturesChart(Map<String, dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição por Cultura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...data.entries.take(5).map((entry) {
              final total = data.values.fold<int>(0, (sum, value) => sum + (value as int));
              final percentage = total > 0 ? (entry.value / total * 100) : 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCultureColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói aba de tendências
  Widget _buildTendencias() {
    if (_dashboardData == null) return const Center(child: Text('Carregando...'));

    final resumo = _dashboardData!['resumo'] as Map<String, dynamic>;
    final tendencia = resumo['tendencia_mensal'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tendência de Plantios por Mês',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < tendencia.length) {
                              final data = tendencia[value.toInt()];
                              final mes = data['mes'] as String;
                              return Text(
                                mes.substring(5), // Mostrar apenas MM
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: tendencia.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            (entry.value['plantios'] as int).toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói aba de comparativo
  Widget _buildComparativo() {
    if (_comparativoSafras == null) return const Center(child: Text('Carregando...'));

    final comparacao = _comparativoSafras!['comparacao'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativo entre Safras',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildComparisonCard(
            'Total de Plantios',
            comparacao['plantios'],
            Icons.agriculture,
          ),
          
          const SizedBox(height: 16),
          
          _buildComparisonCard(
            'Número de Culturas',
            comparacao['culturas'],
            Icons.grass,
          ),
        ],
      ),
    );
  }

  /// Constrói card de comparação
  Widget _buildComparisonCard(String title, Map<String, dynamic> data, IconData icon) {
    final atual = data['atual'] ?? 0;
    final anterior = data['anterior'] ?? 0;
    final variacao = data['variacao'] ?? 0.0;
    
    final isPositive = variacao >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safra Atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        atual.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safra Anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        anterior.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${variacao.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers para cores
  Color _getQualityColor(int score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'principal': return Colors.blue;
      case 'submodulo': return Colors.green;
      case 'historico': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'principal': return 'Principal';
      case 'submodulo': return 'Submódulo';
      case 'historico': return 'Histórico';
      default: return 'Outro';
    }
  }

  Color _getCultureColor(String culture) {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    return colors[culture.hashCode % colors.length];
  }
}
