import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../database/database_performance_monitor.dart';
import '../../widgets/safe_text.dart';
import 'dart:async';

/// Tela para visualizar estatísticas de desempenho do banco de dados
class DatabasePerformanceScreen extends StatefulWidget {
  const DatabasePerformanceScreen({Key? key}) : super(key: key);

  @override
  _DatabasePerformanceScreenState createState() => _DatabasePerformanceScreenState();
}

class _DatabasePerformanceScreenState extends State<DatabasePerformanceScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late TabController _tabController;
  Map<String, dynamic> _performanceStats = {};
  Timer? _refreshTimer;
  bool _autoRefresh = false;
  int _refreshInterval = 5; // segundos
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPerformanceStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  /// Carrega as estatísticas de desempenho do banco de dados
  Future<void> _loadPerformanceStats() async {
    final stats = _databaseHelper.getDatabasePerformanceStats();
    
    setState(() {
      _performanceStats = stats;
    });
  }
  
  /// Inicia ou para o timer de atualização automática
  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      
      if (_autoRefresh) {
        _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
          _loadPerformanceStats();
        });
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }
  
  /// Limpa as estatísticas de desempenho
  void _resetStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar estatísticas'),
        content: const Text('Tem certeza que deseja limpar todas as estatísticas de desempenho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _databaseHelper.resetPerformanceStats();
              _loadPerformanceStats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Estatísticas resetadas com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desempenho do Banco de Dados'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            tooltip: _autoRefresh ? 'Pausar atualização' : 'Atualização automática',
            onPressed: _toggleAutoRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar agora',
            onPressed: _loadPerformanceStats,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Limpar estatísticas',
            onPressed: _resetStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Consultas Lentas'),
            Tab(text: 'Mais Frequentes'),
            Tab(text: 'Erros'),
            Tab(text: 'Lentas Recentes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralStatsTab(),
          _buildSlowestQueriesTab(),
          _buildMostFrequentQueriesTab(),
          _buildErrorProneQueriesTab(),
          _buildRecentSlowQueriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildSettingsDialog(),
          );
        },
        tooltip: 'Configurações',
        child: const Icon(Icons.settings),
      ),
    );
  }
  
  /// Constrói a aba de estatísticas gerais
  Widget _buildGeneralStatsTab() {
    final generalStats = _performanceStats['general'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas Gerais',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Consultas',
            stats: [
              {'label': 'Total de consultas', 'value': '${generalStats['totalQueries'] ?? 0}'},
              {'label': 'Consultas por segundo', 'value': '${(generalStats['queriesPerSecond'] ?? 0).toStringAsFixed(2)}/s'},
              {'label': 'Tempo de monitoramento', 'value': '${generalStats['monitoringTime'] ?? '0:00:00'}'},
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Desempenho',
            stats: [
              {'label': 'Consultas lentas', 'value': '${generalStats['totalSlowQueries'] ?? 0}'},
              {'label': 'Taxa de consultas lentas', 'value': '${((generalStats['slowQueryRate'] ?? 0) * 100).toStringAsFixed(2)}%'},
              {'label': 'Última consulta', 'value': '${generalStats['lastQueryTime'] ?? 'N/A'}'},
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Erros',
            stats: [
              {'label': 'Total de erros', 'value': '${generalStats['totalErrors'] ?? 0}'},
              {'label': 'Taxa de erros', 'value': '${((generalStats['errorRate'] ?? 0) * 100).toStringAsFixed(2)}%'},
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Transações',
            stats: [
              {'label': 'Total de transações', 'value': '${generalStats['totalTransactions'] ?? 0}'},
              {'label': 'Erros em transações', 'value': '${generalStats['totalTransactionErrors'] ?? 0}'},
              {'label': 'Taxa de erros em transações', 'value': '${((generalStats['transactionErrorRate'] ?? 0) * 100).toStringAsFixed(2)}%'},
            ],
          ),
        ],
      ),
    );
  }
  
  /// Constrói a aba de consultas mais lentas
  Widget _buildSlowestQueriesTab() {
    final slowestQueries = _performanceStats['slowestQueries'] as List<dynamic>? ?? [];
    
    return _buildQueryListView(
      title: 'Consultas Mais Lentas',
      queries: slowestQueries,
      emptyMessage: 'Nenhuma consulta lenta registrada',
      valueLabel: 'Tempo médio',
      valueFormatter: (query) => '${(query['avgDurationMs'] ?? 0).toStringAsFixed(2)}ms',
      secondaryValueLabel: 'Tempo máximo',
      secondaryValueFormatter: (query) => '${query['maxDurationMs'] ?? 0}ms',
    );
  }
  
  /// Constrói a aba de consultas mais frequentes
  Widget _buildMostFrequentQueriesTab() {
    final mostFrequentQueries = _performanceStats['mostFrequentQueries'] as List<dynamic>? ?? [];
    
    return _buildQueryListView(
      title: 'Consultas Mais Frequentes',
      queries: mostFrequentQueries,
      emptyMessage: 'Nenhuma consulta registrada',
      valueLabel: 'Contagem',
      valueFormatter: (query) => '${query['count'] ?? 0}',
      secondaryValueLabel: 'Tempo médio',
      secondaryValueFormatter: (query) => '${(query['avgDurationMs'] ?? 0).toStringAsFixed(2)}ms',
    );
  }
  
  /// Constrói a aba de consultas com mais erros
  Widget _buildErrorProneQueriesTab() {
    final errorProneQueries = _performanceStats['errorProneQueries'] as List<dynamic>? ?? [];
    
    return _buildQueryListView(
      title: 'Consultas com Mais Erros',
      queries: errorProneQueries,
      emptyMessage: 'Nenhum erro registrado',
      valueLabel: 'Erros',
      valueFormatter: (query) => '${query['errorCount'] ?? 0}',
      secondaryValueLabel: 'Taxa de erros',
      secondaryValueFormatter: (query) => '${((query['errorRate'] ?? 0) * 100).toStringAsFixed(2)}%',
    );
  }
  
  /// Constrói a aba de consultas lentas recentes
  Widget _buildRecentSlowQueriesTab() {
    final recentSlowQueries = _performanceStats['recentSlowQueries'] as List<dynamic>? ?? [];
    
    return _buildQueryListView(
      title: 'Consultas Lentas Recentes',
      queries: recentSlowQueries,
      emptyMessage: 'Nenhuma consulta lenta recente',
      valueLabel: 'Duração',
      valueFormatter: (query) => '${query['durationMs'] ?? 0}ms',
      secondaryValueLabel: 'Timestamp',
      secondaryValueFormatter: (query) => '${query['timestamp'] ?? 'N/A'}',
      showParams: true,
    );
  }
  
  /// Constrói uma visualização de lista de consultas
  Widget _buildQueryListView({
    required String title,
    required List<dynamic> queries,
    required String emptyMessage,
    required String valueLabel,
    required String Function(dynamic) valueFormatter,
    required String secondaryValueLabel,
    required String Function(dynamic) secondaryValueFormatter,
    bool showParams = false,
  }) {
    return queries.isEmpty
        ? Center(child: Text(emptyMessage, style: const TextStyle(fontSize: 16)))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: queries.length + 1, // +1 para o título
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }
              
              final query = queries[index - 1];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  title: SafeText(
                    query['query'] ?? 'Consulta desconhecida',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$valueLabel: ${valueFormatter(query)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$secondaryValueLabel: ${secondaryValueFormatter(query)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consulta completa:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: SafeText(
                              query['query'] ?? 'Consulta desconhecida',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          if (showParams && query['params'] != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Parâmetros:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: SafeText(
                                query['params'].toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                          if (query['error'] != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Erro:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: SafeText(
                                query['error'].toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
  
  /// Constrói um card de estatísticas
  Widget _buildStatCard({
    required String title,
    required List<Map<String, String>> stats,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stats.map((stat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stat['label']!),
                  Text(
                    stat['value']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  /// Constrói o diálogo de configurações
  Widget _buildSettingsDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Configurações de Monitoramento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Monitoramento ativo'),
                subtitle: const Text('Ativar/desativar coleta de estatísticas'),
                value: _databaseHelper.getDatabasePerformanceStats()['performanceMonitoringEnabled'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _databaseHelper.setPerformanceMonitoring(value);
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Limite para consultas lentas'),
                subtitle: const Text('Em milissegundos'),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 'ms',
                    ),
                    controller: TextEditingController(
                      text: '${_databaseHelper.getDatabasePerformanceStats()['slowQueryThresholdMs'] ?? 100}',
                    ),
                    onChanged: (value) {
                      final threshold = int.tryParse(value);
                      if (threshold != null && threshold > 0) {
                        _databaseHelper.setSlowQueryThreshold(threshold);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Intervalo de atualização'),
                subtitle: const Text('Em segundos'),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 's',
                    ),
                    controller: TextEditingController(text: '$_refreshInterval'),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null && interval > 0) {
                        setState(() {
                          _refreshInterval = interval;
                          
                          // Atualiza o timer se estiver ativo
                          if (_autoRefresh) {
                            _refreshTimer?.cancel();
                            _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
                              _loadPerformanceStats();
                            });
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
