import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../../database/app_database.dart';
import '../../models/infestacao_model.dart';
import '../../services/monitoring_infestation_integration_service.dart';
import '../../services/advanced_infestation_metrics_service.dart';
import '../../utils/logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tela melhorada para gestão de dados de monitoramento com UX otimizada para o campo
class EnhancedMonitoringDataScreen extends StatefulWidget {
  const EnhancedMonitoringDataScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedMonitoringDataScreen> createState() => _EnhancedMonitoringDataScreenState();
}

class _EnhancedMonitoringDataScreenState extends State<EnhancedMonitoringDataScreen> {
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  final AdvancedInfestationMetricsService _metricsService = 
      AdvancedInfestationMetricsService();
  
  // Estado da tela
  bool _isLoading = true;
  String? _error;
  List<InfestacaoModel> _allOccurrences = [];
  List<InfestacaoModel> _filteredOccurrences = [];
  List<InfestacaoModel> _selectedOccurrences = [];
  
  // Filtros com chips coloridos
  String? _selectedType;
  String? _selectedOrganism;
  String? _selectedLevel;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyUnsynced = true;
  
  // Estatísticas
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _metrics = {};
  
  // Controles de seleção
  bool _selectAll = false;
  
  // Mapa compacto
  bool _showMap = false;
  List<Marker> _mapMarkers = [];
  
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
      await _metricsService.initialize();
      await _loadMonitoringData();
      await _loadStats();
      await _loadMetrics();
      
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
        _updateMapMarkers();
      });
      
      Logger.info('✅ [ENHANCED] ${_allOccurrences.length} ocorrências carregadas');
    } catch (e) {
      Logger.error('❌ [ENHANCED] Erro ao carregar dados: $e');
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
      Logger.error('❌ [ENHANCED] Erro ao carregar estatísticas: $e');
    }
  }
  
  Future<void> _loadMetrics() async {
    try {
      final metrics = await _metricsService.calculateTalhaoAggregatedMetrics();
      setState(() {
        _metrics = metrics;
      });
    } catch (e) {
      Logger.error('❌ [ENHANCED] Erro ao carregar métricas: $e');
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredOccurrences = _allOccurrences.where((occurrence) {
        // Filtro por tipo
        if (_selectedType != null && occurrence.tipo != _selectedType) {
          return false;
        }
        
        // Filtro por organismo
        if (_selectedOrganism != null && occurrence.subtipo != _selectedOrganism) {
          return false;
        }
        
        // Filtro por nível
        if (_selectedLevel != null && occurrence.nivel != _selectedLevel) {
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
    
    _updateMapMarkers();
  }
  
  void _updateMapMarkers() {
    final markers = <Marker>[];
    
    for (final occurrence in _filteredOccurrences) {
      if (occurrence.latitude != null && occurrence.longitude != null) {
        final color = occurrence.sincronizado 
            ? const Color(0xFF27AE60) // Verde para sincronizado
            : const Color(0xFFF2C94C); // Laranja para pendente
        
        markers.add(Marker(
          point: LatLng(occurrence.latitude!, occurrence.longitude!),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getTypeIcon(occurrence.tipo),
              color: Colors.white,
              size: 16,
            ),
          ),
        ));
      }
    }
    
    setState(() {
      _mapMarkers = markers;
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
          // Estatísticas compactas
          _buildCompactStats(),
          
          // Filtros com chips coloridos
          _buildColorfulFilters(),
          
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
        'Monitoramento · Talhão 12',
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
          onPressed: () => setState(() => _showMap = !_showMap),
          icon: Icon(_showMap ? Icons.list : Icons.map),
          tooltip: _showMap ? 'Mostrar Lista' : 'Mostrar Mapa',
        ),
        IconButton(
          onPressed: _showExportDialog,
          icon: const Icon(Icons.download),
          tooltip: 'Exportar Dados',
        ),
      ],
    );
  }
  
  Widget _buildCompactStats() {
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              '${_stats['total_sent'] ?? 0}',
              Icons.analytics,
              const Color(0xFF2D9CDB),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: _buildStatItem(
              'Pendentes',
              '${_stats['pending'] ?? 0}',
              Icons.pending,
              const Color(0xFFF2C94C),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: _buildStatItem(
              'Filtrados',
              '${_filteredOccurrences.length}',
              Icons.filter_list,
              const Color(0xFF27AE60),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
        ),
      ],
    );
  }
  
  Widget _buildColorfulFilters() {
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
          const Text(
            'Filtros Rápidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
          
          // Chips de tipo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip('Praga', '🐛', const Color(0xFF27AE60), 'praga'),
              _buildTypeChip('Doença', '🦠', const Color(0xFFF2C94C), 'doença'),
              _buildTypeChip('Daninha', '🌿', const Color(0xFF2D9CDB), 'daninha'),
              _buildTypeChip('Outro', '📋', const Color(0xFF9B59B6), 'outro'),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filtro de sincronização
          Row(
            children: [
              _buildSyncChip('Todos', null),
              const SizedBox(width: 8),
              _buildSyncChip('Não Sincronizados', true),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeChip(String label, String icon, Color color, String value) {
    final isSelected = _selectedType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? null : value;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncChip(String label, bool? value) {
    final isSelected = _showOnlyUnsynced == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showOnlyUnsynced = value ?? false;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D9CDB) : const Color(0xFF2D9CDB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2D9CDB).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF2D9CDB),
          ),
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
          
          // Lista ou mapa
          Expanded(
            child: _showMap ? _buildCompactMap() : _buildOccurrencesListContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOccurrencesListContent() {
    if (_filteredOccurrences.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      itemCount: _filteredOccurrences.length,
      itemBuilder: (context, index) {
        final occurrence = _filteredOccurrences[index];
        return _buildCompactOccurrenceCard(occurrence);
      },
    );
  }
  
  Widget _buildCompactOccurrenceCard(InfestacaoModel occurrence) {
    final isSelected = _selectedOccurrences.contains(occurrence);
    final typeColor = _getTypeColor(occurrence.tipo);
    final levelColor = _getLevelColor(occurrence.nivel);
    final syncColor = occurrence.sincronizado 
        ? const Color(0xFF27AE60) 
        : const Color(0xFFF2C94C);
    
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
        title: Row(
          children: [
            Text(
              _getTypeIcon(occurrence.tipo),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                occurrence.subtipo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: syncColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                occurrence.sincronizado ? Icons.cloud_done : Icons.pending,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              '${occurrence.percentual} ind.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
            Text(
              _formatDate(occurrence.dataHora),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () => _showOccurrenceDetails(occurrence),
      ),
    );
  }
  
  Widget _buildCompactMap() {
    if (_mapMarkers.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum ponto para exibir no mapa',
          style: TextStyle(
            color: Color(0xFF95A5A6),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: _mapMarkers.first.point,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        MarkerLayer(markers: _mapMarkers),
      ],
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
  
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha o formato de exportação:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('geojson'),
                    icon: const Icon(Icons.map),
                    label: const Text('GeoJSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9CDB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportData(String format) async {
    try {
      Navigator.of(context).pop();
      
      final file = await _metricsService.exportIntegrationData(
        format: format,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dados exportados: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  
  String _getTypeIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      case 'outro':
        return '📋';
      default:
        return '❓';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
