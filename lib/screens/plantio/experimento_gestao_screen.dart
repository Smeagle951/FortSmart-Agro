import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/experimento_model.dart';
import '../../database/models/tratamento_model.dart';
import '../../database/models/parcela_model.dart';
import 'experimento_form_screen.dart';
import 'experimento_delineamento_screen.dart';
import 'experimento_parcelas_screen.dart';

/// Tela principal de gestão de experimentos
class ExperimentoGestaoScreen extends StatefulWidget {
  const ExperimentoGestaoScreen({Key? key}) : super(key: key);

  @override
  State<ExperimentoGestaoScreen> createState() => _ExperimentoGestaoScreenState();
}

class _ExperimentoGestaoScreenState extends State<ExperimentoGestaoScreen> {
  List<ExperimentoModel> _experimentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperimentos();
  }
  Future<void> _loadExperimentos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento real do banco
      // Lista vazia para dados reais
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _experimentos = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar experimentos: $e');
    }
  }

  Future<void> _addNovoExperimento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExperimentoFormScreen(),
      ),
    );

    if (result != null) {
      await _loadExperimentos();
      SnackbarUtils.showSuccessSnackBar(context, 'Experimento criado com sucesso!');
    }
  }

  Future<void> _editExperimento(ExperimentoModel experimento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentoFormScreen(experimento: experimento),
      ),
    );

    if (result != null) {
      await _loadExperimentos();
      SnackbarUtils.showSuccessSnackBar(context, 'Experimento atualizado com sucesso!');
    }
  }

  Future<void> _openDelineamento(ExperimentoModel experimento) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentoDelineamentoScreen(experimento: experimento),
      ),
    );
  }

  Future<void> _openParcelas(ExperimentoModel experimento) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentoParcelasScreen(experimento: experimento),
      ),
    );
  }

  Future<void> _deleteExperimento(ExperimentoModel experimento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o experimento "${experimento.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implementar exclusão real do banco
        setState(() {
          _experimentos.remove(experimento);
        });
        SnackbarUtils.showSuccessSnackBar(context, 'Experimento excluído com sucesso!');
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir experimento: $e');
      }
    }
  }

  Widget _buildExperimentoCard(ExperimentoModel experimento) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experimento.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        experimento.cultura,
                        style: TextStyle(
                          color: FortSmartTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(experimento.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações principais
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.science,
                    'Delineamento',
                    experimento.delineamento.replaceAll('_', ' ').toUpperCase(),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.repeat,
                    'Repetições',
                    '${experimento.numeroRepeticoes}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.grid_view,
                    'Tratamentos',
                    '${experimento.numeroTratamentos}',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            Text(
              experimento.descricao,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Data e responsável
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Início: ${DateFormat('dd/MM/yyyy').format(experimento.dataInicio)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  experimento.responsavelTecnico,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDelineamento(experimento),
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Delineamento'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FortSmartTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openParcelas(experimento),
                    icon: const Icon(Icons.grid_view, size: 16),
                    label: const Text('Parcelas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editExperimento(experimento);
                        break;
                      case 'delete':
                        _deleteExperimento(experimento);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Excluir'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'planejado':
        color = Colors.blue;
        label = 'PLANEJADO';
        break;
      case 'em_andamento':
        color = Colors.green;
        label = 'EM ANDAMENTO';
        break;
      case 'finalizado':
        color = Colors.orange;
        label = 'FINALIZADO';
        break;
      case 'cancelado':
        color = Colors.red;
        label = 'CANCELADO';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: FortSmartTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Experimentos'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNovoExperimento,
            tooltip: 'Novo Experimento',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _experimentos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.science,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum experimento cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para criar o primeiro experimento',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumo estatístico
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FortSmartTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FortSmartTheme.primaryColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Resumo dos Experimentos',
                            style: FortSmartTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: FortSmartTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Total', '${_experimentos.length}'),
                              _buildStatItem('Em Andamento', '${_experimentos.where((e) => e.status == 'em_andamento').length}'),
                              _buildStatItem('Finalizados', '${_experimentos.where((e) => e.status == 'finalizado').length}'),
                              _buildStatItem('Planejados', '${_experimentos.where((e) => e.status == 'planejado').length}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de experimentos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _experimentos.length,
                        itemBuilder: (context, index) {
                          return _buildExperimentoCard(_experimentos[index]);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNovoExperimento,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Novo Experimento',
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
