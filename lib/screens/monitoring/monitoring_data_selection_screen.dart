import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';
import '../../models/infestacao_model.dart';
import '../../services/monitoring_infestation_integration_service.dart';
import '../../utils/logger.dart';

/// Tela para seleção e envio de dados de monitoramento para o mapa de infestação
class MonitoringDataSelectionScreen extends StatefulWidget {
  const MonitoringDataSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringDataSelectionScreen> createState() => _MonitoringDataSelectionScreenState();
}

class _MonitoringDataSelectionScreenState extends State<MonitoringDataSelectionScreen> {
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  
  // Estado da tela
  bool _isLoading = true;
  String? _error;
  List<InfestacaoModel> _allOccurrences = [];
  List<InfestacaoModel> _filteredOccurrences = [];
  List<InfestacaoModel> _selectedOccurrences = [];
  
  // Filtros
  String _selectedTalhao = 'Todos';
  String _selectedOrganism = 'Todos';
  String _selectedLevel = 'Todos';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyUnsynced = true;
  
  // Estatísticas
  Map<String, dynamic> _stats = {};
  
  // Controles de seleção
  bool _selectAll = false;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await _integrationService.initialize();
      await _loadMonitoringData();
      await _loadStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  Future<void> _loadMonitoringData() async {
    try {
      final database = await AppDatabase().database;
      final results = await database.query(
        'infestacao',
        orderBy: 'dataHora DESC',
      );
      
      setState(() {
        _allOccurrences = results.map((row) => InfestacaoModel.fromMap(row)).toList();
        _applyFilters();
      });
      
      Logger.info('✅ [SELECTION] ${_allOccurrences.length} ocorrências carregadas');
    } catch (e) {
      Logger.error('❌ [SELECTION] Erro ao carregar dados: $e');
      throw e;
    }
  }
  
  Future<void> _loadStats() async {
    try {
      final stats = await _integrationService.getIntegrationStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      Logger.error('❌ [SELECTION] Erro ao carregar estatísticas: $e');
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredOccurrences = _allOccurrences.where((occurrence) {
        // Filtro por talhão
        if (_selectedTalhao != 'Todos' && 
            occurrence.talhaoId.toString() != _selectedTalhao) {
          return false;
        }
        
        // Filtro por organismo
        if (_selectedOrganism != 'Todos' && 
            occurrence.subtipo != _selectedOrganism) {
          return false;
        }
        
        // Filtro por nível
        if (_selectedLevel != 'Todos' && 
            occurrence.nivel != _selectedLevel) {
          return false;
        }
        
        // Filtro por data
        if (_startDate != null && occurrence.dataHora.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && occurrence.dataHora.isAfter(_endDate!)) {
          return false;
        }
        
        // Filtro por sincronização
        if (_showOnlyUnsynced && occurrence.sincronizado) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D9CDB),
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9CDB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Estatísticas
          _buildStatsCard(),
          
          // Filtros
          _buildFiltersCard(),
          
          // Lista de ocorrências
          Expanded(
            child: _buildOccurrencesList(),
          ),
          
          // Rodapé com ações
          _buildFooter(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Dados de Monitoramento',
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
          onPressed: _showSyncAllDialog,
          icon: const Icon(Icons.sync),
          tooltip: 'Sincronizar Todos',
        ),
        IconButton(
          onPressed: _showCleanDuplicatesDialog,
          icon: const Icon(Icons.cleaning_services),
          tooltip: 'Limpar Duplicados',
        ),
      ],
    );
  }
  
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas de Integração',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Enviados',
                  '${_stats['total_sent'] ?? 0}',
                  Icons.cloud_done,
                  const Color(0xFF27AE60),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Pendentes',
                  '${_stats['pending'] ?? 0}',
                  Icons.pending,
                  const Color(0xFFF2C94C),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Filtrados',
                  '${_filteredOccurrences.length}',
                  Icons.filter_list,
                  const Color(0xFF2D9CDB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFiltersCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: Color(0xFF2D9CDB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filtros em linha
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Talhão', _selectedTalhao, _showTalhaoFilter),
              _buildFilterChip('Organismo', _selectedOrganism, _showOrganismFilter),
              _buildFilterChip('Nível', _selectedLevel, _showLevelFilter),
              _buildFilterChip('Período', _getDateRangeText(), _showDateFilter),
              _buildFilterChip(
                'Sincronização', 
                _showOnlyUnsynced ? 'Não Sincronizados' : 'Todos', 
                _toggleSyncFilter
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D9CDB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D9CDB).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2D9CDB),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Color(0xFF2D9CDB),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOccurrencesList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da lista
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      if (_selectAll) {
                        _selectedOccurrences = List.from(_filteredOccurrences);
                      } else {
                        _selectedOccurrences.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_filteredOccurrences.length} ocorrências encontradas',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                if (_selectedOccurrences.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D9CDB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedOccurrences.length} selecionadas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista
          Expanded(
            child: _filteredOccurrences.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredOccurrences.length,
                    itemBuilder: (context, index) {
                      final occurrence = _filteredOccurrences[index];
                      return _buildOccurrenceItem(occurrence);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma ocorrência encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros para encontrar dados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOccurrenceItem(InfestacaoModel occurrence) {
    final isSelected = _selectedOccurrences.contains(occurrence);
    final typeColor = _getTypeColor(occurrence.tipo);
    final levelColor = _getLevelColor(occurrence.nivel);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2D9CDB).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF2D9CDB) : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value ?? false) {
                _selectedOccurrences.add(occurrence);
              } else {
                _selectedOccurrences.remove(occurrence);
              }
              _selectAll = _selectedOccurrences.length == _filteredOccurrences.length;
            });
          },
        ),
        title: Text(
          occurrence.subtipo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    occurrence.tipo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: levelColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    occurrence.nivel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: levelColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (occurrence.sincronizado)
                  const Icon(
                    Icons.cloud_done,
                    size: 16,
                    color: Color(0xFF27AE60),
                  )
                else
                  const Icon(
                    Icons.pending,
                    size: 16,
                    color: Color(0xFFF2C94C),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Talhão: ${occurrence.talhaoId} • ${occurrence.percentual} indivíduos • ${_formatDate(occurrence.dataHora)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showOccurrenceDetails(occurrence),
          icon: const Icon(Icons.info_outline),
          color: const Color(0xFF2D9CDB),
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectedOccurrences.isEmpty ? null : _sendSelectedData,
              icon: const Icon(Icons.send, size: 16),
              label: Text('Enviar (${_selectedOccurrences.length})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D9CDB),
                side: const BorderSide(color: Color(0xFF2D9CDB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _syncAllPending,
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Sincronizar Todos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Métodos de filtro
  void _showTalhaoFilter() {
    // Implementar seletor de talhão
  }
  
  void _showOrganismFilter() {
    // Implementar seletor de organismo
  }
  
  void _showLevelFilter() {
    // Implementar seletor de nível
  }
  
  void _showDateFilter() {
    // Implementar seletor de data
  }
  
  void _toggleSyncFilter() {
    setState(() {
      _showOnlyUnsynced = !_showOnlyUnsynced;
      _applyFilters();
    });
  }
  
  void _clearFilters() {
    setState(() {
      _selectedTalhao = 'Todos';
      _selectedOrganism = 'Todos';
      _selectedLevel = 'Todos';
      _startDate = null;
      _endDate = null;
      _showOnlyUnsynced = true;
      _applyFilters();
    });
  }
  
  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) return 'Todos';
    if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    }
    if (_startDate != null) return 'A partir de ${_formatDate(_startDate!)}';
    return 'Até ${_formatDate(_endDate!)}';
  }
  
  // Métodos de ação
  Future<void> _sendSelectedData() async {
    if (_selectedOccurrences.isEmpty) return;
    
    try {
      final results = await _integrationService.sendMultipleMonitoringData(
        occurrences: _selectedOccurrences,
        preventDuplicates: true,
      );
      
      final successCount = results.values.where((success) => success).length;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount/${_selectedOccurrences.length} ocorrências enviadas com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadMonitoringData();
      await _loadStats();
      
      setState(() {
        _selectedOccurrences.clear();
        _selectAll = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _syncAllPending() async {
    try {
      final result = await _integrationService.syncAllPendingData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
      
      await _loadMonitoringData();
      await _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na sincronização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showOccurrenceDetails(InfestacaoModel occurrence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(occurrence.subtipo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', occurrence.tipo),
            _buildDetailRow('Nível', occurrence.nivel),
            _buildDetailRow('Quantidade', '${occurrence.percentual} indivíduos'),
            _buildDetailRow('Talhão', occurrence.talhaoId.toString()),
            _buildDetailRow('Data', _formatDate(occurrence.dataHora)),
            _buildDetailRow('Sincronizado', occurrence.sincronizado ? 'Sim' : 'Não'),
            if (occurrence.observacao != null)
              _buildDetailRow('Observação', occurrence.observacao!),
          ],
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
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSyncAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar Todos'),
        content: const Text('Deseja sincronizar todos os dados pendentes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _syncAllPending();
            },
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
  }
  
  void _showCleanDuplicatesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Duplicados'),
        content: const Text('Deseja remover registros duplicados do mapa de infestação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final count = await _integrationService.cleanDuplicateData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count registros duplicados removidos'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              await _loadStats();
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
  
  // Métodos auxiliares
  Color _getTypeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return const Color(0xFF27AE60);
      case 'doença':
        return const Color(0xFFF2C94C);
      case 'daninha':
        return const Color(0xFF2D9CDB);
      case 'outro':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF95A5A6);
    }
  }
  
  Color _getLevelColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'crítico':
        return const Color(0xFFEB5757);
      case 'alto':
        return const Color(0xFFF2C94C);
      case 'médio':
        return const Color(0xFF2D9CDB);
      case 'baixo':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
