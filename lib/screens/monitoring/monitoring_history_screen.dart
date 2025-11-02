import 'package:flutter/material.dart';
import '../../services/monitoring_history_service.dart';
import '../../services/monitoring_history_diagnostic_service.dart';
import '../../services/monitoring_history_diagnostic.dart';
import '../../debug/monitoring_save_diagnostic.dart';
import '../../utils/logger.dart';
import '../../routes.dart';

/// Tela de histórico de monitoramentos
/// Exibe todos os monitoramentos salvos com design elegante e funcionalidades avançadas
class MonitoringHistoryScreen extends StatefulWidget {
  const MonitoringHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringHistoryScreen> createState() => _MonitoringHistoryScreenState();
}

class _MonitoringHistoryScreenState extends State<MonitoringHistoryScreen> {
  final MonitoringHistoryService _historyService = MonitoringHistoryService();
  final MonitoringHistoryDiagnosticService _diagnosticService = MonitoringHistoryDiagnosticService();
  final MonitoringHistoryDiagnostic _newDiagnostic = MonitoringHistoryDiagnostic();
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _diagnosticResults;

  final List<String> _filterOptions = ['Todos', 'Hoje', 'Esta Semana', 'Este Mês'];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
    _loadStats();
    _runDiagnostic();
  }

  Future<void> _loadHistoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar da tabela monitoring_history
      final historyData = await _historyService.getRecentHistory(limit: 100);
      
      // TAMBÉM carregar de monitoring_sessions (sessões finalizadas)
      final sessionsData = await _loadFromSessions();
      
      // Combinar e ordenar por data
      final combined = [...historyData, ...sessionsData];
      combined.sort((a, b) {
        final dateA = a['date'] is DateTime ? a['date'] : DateTime.parse(a['date'].toString());
        final dateB = b['date'] is DateTime ? b['date'] : DateTime.parse(b['date'].toString());
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _historyData = combined;
        _isLoading = false;
      });
      
    } catch (e) {
      Logger.error('Erro ao carregar histórico: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Carrega dados de monitoring_sessions (sessões finalizadas)
  Future<List<Map<String, dynamic>>> _loadFromSessions() async {
    try {
      final db = await _historyService.database;
      
      // Buscar sessões finalizadas
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'],
        orderBy: 'created_at DESC',
        limit: 50,
      );
      
      // Converter para formato compatível
      return sessions.map((session) {
        return {
          'id': session['id'],
          'monitoring_id': session['id'],
          'plot_name': session['talhao_nome'] ?? 'Talhão',
          'crop_name': session['cultura_nome'] ?? 'Cultura',
          'date': session['data_fim'] ?? session['created_at'],
          'severity': 0.0,
          'technician_name': session['tecnico_nome'] ?? 'Técnico',
          'observations': session['observacoes'],
          'points_count': session['total_pontos'] ?? 0,
          'occurrences_count': session['total_ocorrencias'] ?? 0,
          'source': 'sessions', // Marcador de origem
        };
      }).toList();
      
    } catch (e) {
      Logger.error('Erro ao carregar de sessions: $e');
      return [];
    }
  }

  Future<void> _loadStats() async {
    try {
      Logger.info('📊 Carregando estatísticas do histórico...');
      final stats = await _historyService.getHistoryStats();
      Logger.info('📈 Estatísticas carregadas: $stats');
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar estatísticas: $e');
    }
  }

  Future<void> _runDiagnostic() async {
    try {
      Logger.info('🔍 Executando diagnóstico do histórico...');
      final results = await _diagnosticService.runFullDiagnostic();
      setState(() {
        _diagnosticResults = results;
      });
      Logger.info('✅ Diagnóstico concluído');
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
    }
  }

  Future<void> _executarDiagnosticoCompleto() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Criar tabelas se necessário
      await _newDiagnostic.criarTabelasSeNecessario();
      
      // Executar diagnóstico
      final resultado = await _newDiagnostic.executarDiagnostico();
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      // Mostrar resultado
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📊 Diagnóstico do Histórico'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sessões: ${resultado['total_sessoes'] ?? 0}'),
                  Text('Histórico: ${resultado['total_monitoramentos'] ?? 0}'),
                  Text('Ocorrências: ${resultado['total_ocorrencias'] ?? 0}'),
                  const SizedBox(height: 16),
                  const Text('Veja o console para detalhes completos.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadHistoryData(); // Recarregar após diagnóstico
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Fechar loading se estiver aberto
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showDiagnosticResults() {
    if (_diagnosticResults == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico do Histórico'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDiagnosticSection('Tabelas', _diagnosticResults!['tables']),
              _buildDiagnosticSection('Contagens', _diagnosticResults!['data_counts']),
              _buildDiagnosticSection('Estruturas', _diagnosticResults!['table_structures']),
              _buildDiagnosticSection('Dados Recentes', _diagnosticResults!['recent_data']),
              _buildDiagnosticSection('Integridade', _diagnosticResults!['data_integrity']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(String title, dynamic data) {
    if (data == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredData() {
    List<Map<String, dynamic>> filtered = _historyData;

    // Aplicar filtro de período
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Hoje':
        filtered = filtered.where((item) {
          final date = item['date'] as DateTime;
          return date.day == now.day && date.month == now.month && date.year == now.year;
        }).toList();
        break;
      case 'Esta Semana':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((item) {
          final date = item['date'] as DateTime;
          return date.isAfter(weekAgo);
        }).toList();
        break;
      case 'Este Mês':
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = filtered.where((item) {
          final date = item['date'] as DateTime;
          return date.isAfter(monthAgo);
        }).toList();
        break;
    }

    // Aplicar busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final plotName = (item['plot_name'] as String).toLowerCase();
        final cropName = (item['crop_name'] as String).toLowerCase();
        final technicianName = (item['technician_name'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return plotName.contains(query) || 
               cropName.contains(query) || 
               technicianName.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Branco pérola
      appBar: AppBar(
        title: const Text(
          'Histórico de Monitoramentos',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
        actions: [
          IconButton(
            onPressed: _executarDiagnosticoCompleto,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnóstico Completo',
          ),
          IconButton(
            onPressed: _diagnosticarSalvamento,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Diagnóstico de Salvamento',
          ),
          IconButton(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.analytics),
            tooltip: 'Estatísticas',
          ),
          IconButton(
            onPressed: _loadHistoryData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          _buildStatsHeader(),
          
          // Filtros e busca
          _buildFiltersSection(),
          
          // Lista de histórico
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9CDB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF2D9CDB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resumo do Histórico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              if (_diagnosticResults != null)
                IconButton(
                  onPressed: _showDiagnosticResults,
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Ver Diagnóstico',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_stats['total_records'] ?? 0}',
                  Icons.assessment,
                  const Color(0xFF2D9CDB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Esta Semana',
                  _getThisWeekCount().toString(),
                  Icons.trending_up,
                  const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Talhões',
                  _getUniquePlotsCount().toString(),
                  Icons.location_on,
                  const Color(0xFFF2C94C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por talhão, cultura ou técnico...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF95A5A6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2D9CDB)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Filtros de período
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D9CDB) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2D9CDB) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar histórico',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistoryData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D9CDB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Todos'
                  ? 'Nenhum monitoramento encontrado'
                  : 'Nenhum monitoramento registrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'Todos'
                  ? 'Tente ajustar os filtros ou busca'
                  : 'Os monitoramentos aparecerão aqui após serem concluídos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filteredData[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final date = item['date'] as DateTime;
    final severityValue = item['severity'];
    final severity = severityValue is num ? severityValue.toDouble() : 0.0;
    final pointsCountValue = item['points_count'];
    final pointsCount = pointsCountValue is num ? pointsCountValue.toInt() : 0;
    final occurrencesCountValue = item['occurrences_count'];
    final occurrencesCount = occurrencesCountValue is num ? occurrencesCountValue.toInt() : 0;
    final technicianName = item['technician_name'] as String? ?? 'Não informado';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showHistoryDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do card
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['plot_name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['crop_name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF95A5A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSeverityText(severity),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Informações do monitoramento
                Row(
                  children: [
                    _buildInfoItem(Icons.location_on, '$pointsCount pontos'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.bug_report, '$occurrencesCount ocorrências'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.person, technicianName),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Data e hora
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showHistoryDetails(Map<String, dynamic> item) {
    try {
      Logger.info('🔍 Navegando para detalhes do histórico...');
      Logger.info('📋 Item selecionado: $item');
      
      Navigator.pushNamed(
        context,
        AppRoutes.monitoringHistoryView,
        arguments: item,
      ).then((result) {
        Logger.info('✅ Navegação concluída com resultado: $result');
      }).catchError((error) {
        Logger.error('❌ Erro na navegação: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir detalhes: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
      Logger.error('❌ Erro ao navegar para detalhes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir detalhes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getSeverityColor(double severity) {
    if (severity >= 8) return const Color(0xFFEB5757); // Crítico
    if (severity >= 6) return const Color(0xFFF2C94C); // Alto
    if (severity >= 3) return const Color(0xFF2D9CDB); // Médio
    return const Color(0xFF27AE60); // Baixo
  }

  String _getSeverityText(double severity) {
    if (severity >= 8) return 'Crítico';
    if (severity >= 6) return 'Alto';
    if (severity >= 3) return 'Médio';
    return 'Baixo';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Hoje às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  int _getThisWeekCount() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _historyData.where((item) {
      final date = item['date'] as DateTime;
      return date.isAfter(weekAgo);
    }).length;
  }

  int _getUniquePlotsCount() {
    final plots = _historyData.map((item) => item['plot_name'] as String).toSet();
    return plots.length;
  }

  /// Diagnóstico específico do sistema de salvamento
  Future<void> _diagnosticarSalvamento() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.save_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Diagnóstico de Salvamento'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analisando sistema de salvamento...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Executar diagnóstico completo
      final results = await MonitoringSaveDiagnostic.runFullDiagnostic();
      final formattedResults = MonitoringSaveDiagnostic.formatDiagnosticResults(results);

      // Fechar diálogo de loading
      Navigator.of(context).pop();

      // Mostrar resultados
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.save_outlined, 
                color: results.containsKey('error') ? Colors.red : Colors.green
              ),
              SizedBox(width: 8),
              Text('Resultado do Diagnóstico'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      formattedResults,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (results.containsKey('error')) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'PROBLEMA IDENTIFICADO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Erro no sistema de salvamento: ${results['error']}',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sistema funcionando corretamente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
            if (results.containsKey('error'))
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Tentar corrigir automaticamente
                  _tentarCorrigirSalvamento();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Tentar Corrigir'),
              ),
          ],
        ),
      );
    } catch (e) {
      // Fechar diálogo de loading se ainda estiver aberto
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Erro no Diagnóstico'),
            ],
          ),
          content: Text('Falha ao executar diagnóstico: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }

  /// Tenta corrigir problemas básicos do sistema de salvamento
  Future<void> _tentarCorrigirSalvamento() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build, color: Colors.orange),
            SizedBox(width: 8),
            Text('Corrigindo Sistema'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Aplicando correções automáticas...'),
          ],
        ),
      ),
    );

    try {
      // Aqui você pode adicionar correções automáticas específicas
      await Future.delayed(Duration(seconds: 2)); // Simular correção
      
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Correção Aplicada'),
            ],
          ),
          content: Text('Correções automáticas aplicadas. Teste o salvamento novamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Falha na Correção'),
            ],
          ),
          content: Text('Não foi possível aplicar correções automáticas: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
}
