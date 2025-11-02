import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/experimento_model.dart';
import '../../database/models/tratamento_model.dart';
import 'tratamento_form_screen.dart';

/// Tela para gerenciar delineamento experimental e tratamentos
class ExperimentoDelineamentoScreen extends StatefulWidget {
  final ExperimentoModel experimento;

  const ExperimentoDelineamentoScreen({
    Key? key,
    required this.experimento,
  }) : super(key: key);

  @override
  State<ExperimentoDelineamentoScreen> createState() => _ExperimentoDelineamentoScreenState();
}

class _ExperimentoDelineamentoScreenState extends State<ExperimentoDelineamentoScreen> {
  List<TratamentoModel> _tratamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTratamentos();
  }

  Future<void> _loadTratamentos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento real do banco
      // Lista vazia para dados reais
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _tratamentos = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar tratamentos: $e');
    }
  }

  Future<void> _addNovoTratamento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TratamentoFormScreen(
          experimento: widget.experimento,
          tratamento: null,
        ),
      ),
    );

    if (result != null) {
      await _loadTratamentos();
      SnackbarUtils.showSuccessSnackBar(context, 'Tratamento adicionado com sucesso!');
    }
  }

  Future<void> _editTratamento(TratamentoModel tratamento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TratamentoFormScreen(
          experimento: widget.experimento,
          tratamento: tratamento,
        ),
      ),
    );

    if (result != null) {
      await _loadTratamentos();
      SnackbarUtils.showSuccessSnackBar(context, 'Tratamento atualizado com sucesso!');
    }
  }

  Future<void> _deleteTratamento(TratamentoModel tratamento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o tratamento "${tratamento.nome}"?'),
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
          _tratamentos.remove(tratamento);
        });
        SnackbarUtils.showSuccessSnackBar(context, 'Tratamento excluído com sucesso!');
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir tratamento: $e');
      }
    }
  }

  Widget _buildTratamentoCard(TratamentoModel tratamento) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(tratamento.tipo),
          child: Text(
            tratamento.codigo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          tratamento.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tratamento.descricao),
            const SizedBox(height: 4),
            _buildParametros(tratamento.parametros),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editTratamento(tratamento);
                break;
              case 'delete':
                _deleteTratamento(tratamento);
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
      ),
    );
  }

  Widget _buildParametros(Map<String, dynamic> parametros) {
    if (parametros.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: parametros.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'testemunha':
        return Colors.grey;
      case 'fertilizante':
        return Colors.green;
      case 'defensivo':
        return Colors.orange;
      case 'semente':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  Widget _buildDelineamentoInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FortSmartTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FortSmartTheme.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Delineamento',
            style: FortSmartTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: FortSmartTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Tipo',
                  widget.experimento.delineamento.replaceAll('_', ' ').toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Tratamentos',
                  '${widget.experimento.numeroTratamentos}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Repetições',
                  '${widget.experimento.numeroRepeticoes}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Total Parcelas',
                  '${widget.experimento.totalParcelas}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delineamento - ${widget.experimento.nome}'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNovoTratamento,
            tooltip: 'Novo Tratamento',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Informações do delineamento
                _buildDelineamentoInfo(),
                
                // Lista de tratamentos
                Expanded(
                  child: _tratamentos.isEmpty
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
                                'Nenhum tratamento cadastrado',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque no + para adicionar o primeiro tratamento',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tratamentos.length,
                          itemBuilder: (context, index) {
                            return _buildTratamentoCard(_tratamentos[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNovoTratamento,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Novo Tratamento',
      ),
    );
  }
}
