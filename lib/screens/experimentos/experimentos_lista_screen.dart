import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/experiment.dart';
import '../../services/experiment_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_button.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_empty_state.dart';
import '../../widgets/fortsmart_filter_chip.dart';
import '../../widgets/fortsmart_loading.dart';
import '../../widgets/fortsmart_search_bar.dart';
import '../../utils/fortsmart_theme.dart';
import 'experimento_detalhes_screen.dart';
import 'criar_experimento_screen.dart';

/// Tela de listagem de experimentos com filtros avançados
/// Segue o padrão visual do FortSmart Agro
class ExperimentosListaScreen extends StatefulWidget {
  final String? talhaoId;
  final String? talhaoNome;

  const ExperimentosListaScreen({
    super.key,
    this.talhaoId,
    this.talhaoNome,
  });

  @override
  State<ExperimentosListaScreen> createState() => _ExperimentosListaScreenState();
}

class _ExperimentosListaScreenState extends State<ExperimentosListaScreen>
    with TickerProviderStateMixin {
  
  // Constantes
  static const Duration _snackBarDuration = Duration(seconds: 3);
  
  // Serviços
  final ExperimentService _experimentService = ExperimentService();
  
  // Estados
  List<Experiment> _experimentos = [];
  List<Experiment> _experimentosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _filtroStatus = 'todos';
  String _filtroCultura = 'todos';
  DateTimeRange? _filtroPeriodo;
  
  // UI Controllers
  late TabController _tabController;
  bool _showFilters = false;
  
  // Estatísticas
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Carrega dados dos experimentos
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _experimentService.initialize();
      
      List<Experiment> experimentos;
      if (widget.talhaoId != null) {
        // Filtrar por talhão específico
        experimentos = await _experimentService.getExperimentsByPlotId(widget.talhaoId!);
      } else {
        // Carregar todos os experimentos
        experimentos = await _experimentService.getAllExperiments();
      }
      
      final stats = await _experimentService.getExperimentStats();
      
      setState(() {
        _experimentos = experimentos;
        _experimentosFiltrados = experimentos;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar experimentos: $e';
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros aos experimentos
  void _aplicarFiltros() {
    setState(() {
      _experimentosFiltrados = _experimentos.where((experimento) {
        // Filtro por texto de busca
        if (_searchController.text.isNotEmpty) {
          final searchText = _searchController.text.toLowerCase();
          if (!experimento.variety.toLowerCase().contains(searchText) &&
              !experimento.description.toLowerCase().contains(searchText) &&
              !experimento.plotName.toLowerCase().contains(searchText)) {
            return false;
          }
        }
        
        // Filtro por status
        if (_filtroStatus != 'todos' && experimento.status != _filtroStatus) {
          return false;
        }
        
        // Filtro por cultura
        if (_filtroCultura != 'todos' && experimento.cropType != _filtroCultura) {
          return false;
        }
        
        // Filtro por período
        if (_filtroPeriodo != null) {
          if (experimento.startDate.isBefore(_filtroPeriodo!.start) ||
              experimento.startDate.isAfter(_filtroPeriodo!.end)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  /// Callback para mudanças na busca
  void _onSearchChanged() {
    _aplicarFiltros();
  }

  /// Navega para criar novo experimento
  void _criarNovoExperimento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CriarExperimentoScreen(
          talhaoId: widget.talhaoId,
          talhaoNome: widget.talhaoNome,
        ),
      ),
    );

    if (result == true) {
      await _carregarDados();
      _mostrarMensagem('Experimento criado com sucesso!', isError: false);
    }
  }

  /// Navega para detalhes do experimento
  void _verDetalhesExperimento(Experiment experimento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentoDetalhesScreen(experimento: experimento),
      ),
    );
  }

  /// Exclui um experimento
  Future<void> _excluirExperimento(Experiment experimento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o experimento "${experimento.variety}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _experimentService.deleteExperiment(experimento.id!);
        await _carregarDados();
        _mostrarMensagem('Experimento excluído com sucesso!', isError: false);
      } catch (e) {
        _mostrarMensagem('Erro ao excluir experimento: $e', isError: true);
      }
    }
  }

  /// Mostra mensagem de feedback
  void _mostrarMensagem(String mensagem, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: _snackBarDuration,
      ),
    );
  }

  /// Constrói o cabeçalho com estatísticas
  Widget _buildHeader() {
    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: FortsmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Experimentos Agrícolas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.talhaoNome != null) ...[
              const SizedBox(height: 8),
              Text(
                'Talhão: ${widget.talhaoNome}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FortsmartTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total', '${_experimentos.length}', Icons.science),
                const SizedBox(width: 16),
                _buildStatCard('Ativos', '${_stats['active'] ?? 0}', Icons.play_arrow),
                const SizedBox(width: 16),
                _buildStatCard('Concluídos', '${_stats['completed'] ?? 0}', Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FortsmartTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: FortsmartTheme.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: FortsmartTheme.primaryColor,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói barra de busca e filtros
  Widget _buildSearchAndFilters() {
    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de busca
            FortsmartSearchBar(
              controller: _searchController,
              hintText: 'Buscar por variedade, descrição ou talhão...',
              onChanged: (value) => _aplicarFiltros(),
            ),
            const SizedBox(height: 16),
            
            // Filtros
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'active', child: Text('Ativo')),
                      DropdownMenuItem(value: 'completed', child: Text('Concluído')),
                      DropdownMenuItem(value: 'canceled', child: Text('Cancelado')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroStatus = value!;
                        _aplicarFiltros();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroCultura,
                    decoration: const InputDecoration(
                      labelText: 'Cultura',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'todos', child: Text('Todas')),
                      ..._experimentos.map((e) => e.cropType).toSet().map((cultura) =>
                        DropdownMenuItem(value: cultura, child: Text(cultura)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroCultura = value!;
                        _aplicarFiltros();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói lista de experimentos
  Widget _buildExperimentosList() {
    if (_experimentosFiltrados.isEmpty) {
      return FortsmartEmptyState(
        icon: Icons.science,
        title: 'Nenhum experimento encontrado',
        subtitle: _experimentos.isEmpty 
            ? 'Comece criando seu primeiro experimento'
            : 'Nenhum experimento corresponde aos filtros aplicados',
        actionText: _experimentos.isEmpty ? 'Criar Experimento' : 'Limpar Filtros',
        onAction: _experimentos.isEmpty ? _criarNovoExperimento : () {
          setState(() {
            _searchController.clear();
            _filtroStatus = 'todos';
            _filtroCultura = 'todos';
            _filtroPeriodo = null;
            _aplicarFiltros();
          });
        },
      );
    }

    return ListView.builder(
      itemCount: _experimentosFiltrados.length,
      itemBuilder: (context, index) {
        final experimento = _experimentosFiltrados[index];
        return _buildExperimentoCard(experimento);
      },
    );
  }

  /// Constrói card de experimento
  Widget _buildExperimentoCard(Experiment experimento) {
    return FortsmartCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _verDetalhesExperimento(experimento),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(experimento.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: _getStatusColor(experimento.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experimento.variety,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          experimento.plotName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(experimento.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações do experimento
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.eco,
                      'Cultura',
                      experimento.cropType,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Início',
                      DateFormat('dd/MM/yyyy').format(experimento.startDate),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.timeline,
                      'DAE',
                      '${experimento.dae} dias',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.description,
                      'Descrição',
                      experimento.description.isNotEmpty 
                          ? experimento.description 
                          : 'Sem descrição',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ações
              Row(
                children: [
                  Expanded(
                    child: FortsmartButton(
                      text: 'Ver Detalhes',
                      onPressed: () => _verDetalhesExperimento(experimento),
                      variant: FortsmartButtonVariant.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _excluirExperimento(experimento),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói item de informação
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói chip de status
  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Obtém cor do status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtém texto do status
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'completed':
        return 'Concluído';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FortsmartAppBar(
        title: 'Experimentos',
        actions: [
          IconButton(
            onPressed: _criarNovoExperimento,
            icon: const Icon(Icons.add),
            tooltip: 'Criar Experimento',
          ),
        ],
      ),
      body: _isLoading
          ? const FortsmartLoading()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FortsmartButton(
                        text: 'Tentar Novamente',
                        onPressed: _carregarDados,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildSearchAndFilters(),
                            const SizedBox(height: 16),
                            _buildExperimentosList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _criarNovoExperimento,
        backgroundColor: FortsmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
