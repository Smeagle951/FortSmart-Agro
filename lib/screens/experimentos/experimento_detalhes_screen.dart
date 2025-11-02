import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/experiment.dart';
import '../../services/experiment_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_button.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_loading.dart';
import '../../utils/fortsmart_theme.dart';
import 'editar_experimento_screen.dart';

/// Tela de detalhes do experimento
/// Segue o padrão visual do FortSmart Agro
class ExperimentoDetalhesScreen extends StatefulWidget {
  final Experiment experimento;

  const ExperimentoDetalhesScreen({
    super.key,
    required this.experimento,
  });

  @override
  State<ExperimentoDetalhesScreen> createState() => _ExperimentoDetalhesScreenState();
}

class _ExperimentoDetalhesScreenState extends State<ExperimentoDetalhesScreen>
    with TickerProviderStateMixin {
  
  // Constantes
  static const Duration _snackBarDuration = Duration(seconds: 3);
  
  // Serviços
  final ExperimentService _experimentService = ExperimentService();
  
  // Estados
  Experiment? _experimento;
  bool _isLoading = true;
  String? _errorMessage;
  
  // UI Controllers
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega dados do experimento
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _experimentService.initialize();
      
      final experimento = await _experimentService.getExperimentById(widget.experimento.id!);
      
      setState(() {
        _experimento = experimento;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar experimento: $e';
        _isLoading = false;
      });
    }
  }

  /// Navega para editar experimento
  void _editarExperimento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarExperimentoScreen(experimento: _experimento!),
      ),
    );

    if (result == true) {
      await _carregarDados();
      _mostrarMensagem('Experimento atualizado com sucesso!', isError: false);
    }
  }

  /// Exclui o experimento
  Future<void> _excluirExperimento() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o experimento "${_experimento!.variety}"?'),
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
        await _experimentService.deleteExperiment(_experimento!.id!);
        Navigator.pop(context, true);
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

  /// Constrói cabeçalho com informações principais
  Widget _buildHeader() {
    if (_experimento == null) return const SizedBox.shrink();

    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_experimento!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science,
                    color: _getStatusColor(_experimento!.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _experimento!.variety,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _experimento!.plotName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(_experimento!.status),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações principais
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    Icons.eco,
                    'Cultura',
                    _experimento!.cropType,
                    FortsmartTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    Icons.calendar_today,
                    'Data Início',
                    DateFormat('dd/MM/yyyy').format(_experimento!.startDate),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    Icons.timeline,
                    'DAE',
                    '${_experimento!.dae} dias',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    Icons.flag,
                    'Status',
                    _getStatusText(_experimento!.status),
                    _getStatusColor(_experimento!.status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de informação
  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
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
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói chip de status
  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Constrói aba de informações gerais
  Widget _buildInformacoesTab() {
    if (_experimento == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Descrição
          FortsmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: FortsmartTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Descrição',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _experimento!.description.isNotEmpty 
                        ? _experimento!.description 
                        : 'Nenhuma descrição fornecida',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Datas
          FortsmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: FortsmartTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Cronograma',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDateInfo(
                    'Data de Início',
                    DateFormat('dd/MM/yyyy HH:mm').format(_experimento!.startDate),
                    Icons.play_arrow,
                    Colors.green,
                  ),
                  if (_experimento!.endDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDateInfo(
                      'Data de Fim',
                      DateFormat('dd/MM/yyyy HH:mm').format(_experimento!.endDate!),
                      Icons.stop,
                      Colors.red,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDateInfo(
                    'Criado em',
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      DateTime.parse(_experimento!.createdAt ?? DateTime.now().toIso8601String())
                    ),
                    Icons.add_circle,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói informação de data
  Widget _buildDateInfo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói aba de resultados
  Widget _buildResultadosTab() {
    if (_experimento == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          FortsmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: FortsmartTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Resultados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_experimento!.results.isNotEmpty) ...[
                    ..._experimento!.results.entries.map((entry) => 
                      _buildResultItem(entry.key, entry.value.toString())
                    ),
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Nenhum resultado registrado'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói item de resultado
  Widget _buildResultItem(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FortsmartTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói aba de ações
  Widget _buildAcoesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          FortsmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: FortsmartTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Ações',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FortsmartButton(
                    text: 'Editar Experimento',
                    onPressed: _editarExperimento,
                    icon: Icons.edit,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  FortsmartButton(
                    text: 'Excluir Experimento',
                    onPressed: _excluirExperimento,
                    icon: Icons.delete,
                    variant: FortsmartButtonVariant.outline,
                    fullWidth: true,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        title: 'Detalhes do Experimento',
        actions: [
          IconButton(
            onPressed: _editarExperimento,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
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
                    _buildHeader(),
                    Expanded(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'Informações', icon: Icon(Icons.info)),
                                Tab(text: 'Resultados', icon: Icon(Icons.analytics)),
                                Tab(text: 'Ações', icon: Icon(Icons.settings)),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildInformacoesTab(),
                                  _buildResultadosTab(),
                                  _buildAcoesTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
